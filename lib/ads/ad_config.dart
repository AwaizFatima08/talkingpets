/// AdMob configuration.
///
/// By default the app uses Google's public TEST ad units, which always serve
/// labelled test ads and are safe to click. For a monetised build pass the real
/// units at build time (see docs/ads.md):
///
///   flutter build appbundle --dart-define=TP_REAL_ADS=true \
///     --dart-define=TP_BANNER_ID=ca-app-pub-xxx/yyy \
///     --dart-define=TP_INTERSTITIAL_ID=ca-app-pub-xxx/yyy \
///     --dart-define=TP_REWARDED_ID=ca-app-pub-xxx/yyy \
///     -PadmobAppId=ca-app-pub-xxx~zzz
class AdConfig {
  static const realAds = bool.fromEnvironment('TP_REAL_ADS');

  static const bannerId = realAds ? String.fromEnvironment('TP_BANNER_ID') : 'ca-app-pub-3940256099942544/9214589741';
  static const interstitialId =
      realAds ? String.fromEnvironment('TP_INTERSTITIAL_ID') : 'ca-app-pub-3940256099942544/1033173712';
  static const rewardedId = realAds ? String.fromEnvironment('TP_REWARDED_ID') : 'ca-app-pub-3940256099942544/5224354917';

  /// Hashed device IDs that always get test ads even with real units
  /// (printed in logcat by the Ads SDK as "Use RequestConfiguration...").
  static const testDeviceIds = <String>[];
}

/// When an interstitial may interrupt play. Kept gentle for toddlers:
/// never in the first minute, at most every two minutes, and only on a
/// natural break (switching pets), every third switch.
class AdPacing {
  AdPacing({
    this.firstAfter = const Duration(seconds: 60),
    this.minGap = const Duration(seconds: 120),
    this.switchesPerAd = 3,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _sessionStart = _clock();
  }

  final Duration firstAfter;
  final Duration minGap;
  final int switchesPerAd;
  final DateTime Function() _clock;
  late DateTime _sessionStart;
  DateTime? _lastShown;
  int _switches = 0;

  /// Call on every pet switch; true when an interstitial should show now.
  bool onSwitch() {
    _switches++;
    final now = _clock();
    if (now.difference(_sessionStart) < firstAfter) return false;
    if (_lastShown != null && now.difference(_lastShown!) < minGap) return false;
    return _switches >= switchesPerAd;
  }

  void markShown() {
    _lastShown = _clock();
    _switches = 0;
  }
}
