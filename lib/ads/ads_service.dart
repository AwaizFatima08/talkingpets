import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Owns consent, SDK start-up and the full-screen ads. Every request is
/// tagged child-directed with a G rating (Google Play Families policy).
class AdsService extends ChangeNotifier {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool initialized = false;
  bool canRequestAds = false;
  ConsentStatus consent = ConsentStatus.unknown;
  bool privacyOptionsRequired = false;
  AdPacing pacing = AdPacing();

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false, _loadingRewarded = false;
  bool fullScreenShowing = false;

  /// Called when a full-screen ad opens (true) and closes (false), so the
  /// app can pause the microphone and sounds.
  void Function(bool showing)? onFullScreen;

  /// Recent ad events, newest first (shown in the grown-ups Ad test lab).
  final List<String> log = [];

  bool get interstitialReady => _interstitial != null;
  bool get rewardedReady => _rewarded != null;

  void _log(String msg) {
    final t = DateTime.now();
    final stamp = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    log.insert(0, '$stamp  $msg');
    if (log.length > 60) log.removeLast();
    debugPrint('[ads] $msg');
    notifyListeners();
  }

  static final request = const AdRequest();

  Future<void> init() async {
    if (initialized) return;
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(tagForUnderAgeOfConsent: true),
      () async {
        _log('consent info updated');
        await ConsentForm.loadAndShowConsentFormIfRequired((err) {
          if (err != null) _log('consent form error: ${err.message}');
        });
        if (!done.isCompleted) done.complete();
      },
      (err) {
        _log('consent update failed: ${err.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () => _log('consent timed out'));
    await refreshConsent();

    await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      // Child treatment = COPPA child-directed + GDPR under age of consent.
      ageRestrictedTreatment: AgeRestrictedTreatment.child,
      maxAdContentRating: MaxAdContentRating.g,
      testDeviceIds: AdConfig.testDeviceIds,
    ));
    // Consent may be unobtainable offline; the SDK still initialises and
    // serves non-personalised, child-directed ads where allowed.
    final status = await MobileAds.instance.initialize();
    initialized = true;
    _log('SDK ready (${status.adapterStatuses.length} adapters) · ${AdConfig.realAds ? 'REAL' : 'TEST'} units');
    loadInterstitial();
    loadRewarded();
  }

  Future<void> refreshConsent() async {
    canRequestAds = await ConsentInformation.instance.canRequestAds();
    consent = await ConsentInformation.instance.getConsentStatus();
    privacyOptionsRequired = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    notifyListeners();
  }

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((err) {
      if (err != null) _log('privacy options error: ${err.message}');
    });
    await refreshConsent();
  }

  /// Testing only: forget consent so the flow can be re-run.
  Future<void> resetConsent() async {
    await ConsentInformation.instance.reset();
    _log('consent reset');
    await refreshConsent();
  }

  void loadInterstitial() {
    if (!AdConfig.interstitials || !initialized || _interstitial != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitial = ad;
          _log('interstitial loaded');
        },
        onAdFailedToLoad: (e) {
          _loadingInterstitial = false;
          _log('interstitial failed: ${e.code} ${e.message}');
          Future.delayed(const Duration(seconds: 45), loadInterstitial);
        },
      ),
    );
  }

  void loadRewarded() {
    if (!initialized || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewarded = ad;
          _log('rewarded loaded');
        },
        onAdFailedToLoad: (e) {
          _loadingRewarded = false;
          _log('rewarded failed: ${e.code} ${e.message}');
          Future.delayed(const Duration(seconds: 45), loadRewarded);
        },
      ),
    );
  }

  FullScreenContentCallback<T> _callbacks<T extends Ad>(String name, void Function() reload, Completer<void> closed) =>
      FullScreenContentCallback<T>(
        onAdShowedFullScreenContent: (_) {
          fullScreenShowing = true;
          onFullScreen?.call(true);
          _log('$name shown');
        },
        onAdImpression: (_) => _log('$name impression'),
        onAdClicked: (_) => _log('$name clicked'),
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          fullScreenShowing = false;
          onFullScreen?.call(false);
          _log('$name closed');
          reload();
          if (!closed.isCompleted) closed.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, e) {
          ad.dispose();
          fullScreenShowing = false;
          onFullScreen?.call(false);
          _log('$name failed to show: ${e.message}');
          reload();
          if (!closed.isCompleted) closed.complete();
        },
      );

  /// Called on a pet switch; shows an interstitial if pacing allows.
  Future<void> onNaturalBreak() async {
    if (pacing.onSwitch() && _interstitial != null) {
      await showInterstitial();
    } else {
      loadInterstitial();
    }
  }

  /// Shows the interstitial now (if loaded) and completes when it closes.
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _log('interstitial not ready');
      loadInterstitial();
      return false;
    }
    _interstitial = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = _callbacks<InterstitialAd>('interstitial', loadInterstitial, closed);
    pacing.markShown();
    await ad.show();
    await closed.future;
    return true;
  }

  /// Shows the rewarded ad; returns true if the reward was earned.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _log('rewarded not ready');
      loadRewarded();
      return false;
    }
    _rewarded = null;
    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = _callbacks<RewardedAd>('rewarded', loadRewarded, closed);
    await ad.show(onUserEarnedReward: (_, reward) {
      earned = true;
      _log('reward earned: ${reward.amount} ${reward.type}');
    });
    await closed.future;
    return earned;
  }

  void logBanner(String msg) => _log('banner $msg');

  void openAdInspector() {
    MobileAds.instance.openAdInspector((err) {
      if (err != null) _log('ad inspector: ${err.message}');
    });
  }
}
