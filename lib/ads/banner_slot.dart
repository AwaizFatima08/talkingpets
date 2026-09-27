import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ads_service.dart';

/// Anchored adaptive banner. Reserves its height so nothing jumps when it loads.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key});

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  int? _width;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (!mounted || !AdsService.instance.initialized || _ad != null) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    _width = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(Orientation.portrait, width) ??
        AdSize.banner;
    if (!mounted || _ad != null) return;
    _size = size;
    _ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: AdsService.request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          AdsService.instance.logBanner('loaded (${size.width}x${size.height})');
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, e) {
          AdsService.instance.logBanner('failed: ${e.code} ${e.message}');
          ad.dispose();
          _ad = null;
          Future.delayed(const Duration(seconds: 60), _maybeLoad);
        },
        onAdImpression: (_) => AdsService.instance.logBanner('impression'),
        onAdClicked: (_) => AdsService.instance.logBanner('clicked'),
      ),
    )..load();
    setState(() {});
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = (_size?.height ?? 56).toDouble();
    return SizedBox(
      key: const Key('banner-slot'),
      width: (_width ?? MediaQuery.sizeOf(context).width).toDouble(),
      height: h,
      child: _loaded && _ad != null ? AdWidget(ad: _ad!) : const SizedBox.shrink(),
    );
  }
}
