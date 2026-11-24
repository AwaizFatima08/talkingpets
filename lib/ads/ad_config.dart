import 'package:flutter/foundation.dart';

/// AdMob configuration (HomiLabs account pub-2087846699268567, app
/// "TalkyPals: Funny Talking Pets").
///
/// Release builds use the real ad units; debug and profile builds use Google's
/// public TEST units, which serve labelled test ads that are safe to click.
/// Override either way with --dart-define=TP_REAL_ADS=true|false.
/// The matching app ID is set per build type in android/app/build.gradle.kts.
class AdConfig {
  static const realAds = bool.fromEnvironment('TP_REAL_ADS', defaultValue: kReleaseMode);

  static const bannerId = realAds ? 'ca-app-pub-2087846699268567/3020185971' : 'ca-app-pub-3940256099942544/9214589741';
  static const interstitialId =
      realAds ? 'ca-app-pub-2087846699268567/6276904702' : 'ca-app-pub-3940256099942544/1033173712';
  /// Full-screen interstitials on pet switches. Off since v1.1.1+6: Play
  /// rejected build 5 under Families "Ad Content", so toddlers only see the
  /// banner (and rewarded ads a grown-up chooses behind the parent gate).
  static const interstitials = bool.fromEnvironment('TP_INTERSTITIALS', defaultValue: false);

  static const rewardedId = realAds ? 'ca-app-pub-2087846699268567/2255713305' : 'ca-app-pub-3940256099942544/5224354917';

  /// Hashed device IDs that always get test ads, even with the real units
  /// (the Ads SDK prints them in logcat as "Use RequestConfiguration...").
  /// Never click real ads on your own devices: add every test phone here.
  static const testDeviceIds = <String>[
    '612A06FA5424E5773B59912587C83AB9', // Samsung Galaxy A12 (SM-A125F)
  ];
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
