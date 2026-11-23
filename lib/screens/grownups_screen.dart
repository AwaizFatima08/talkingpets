import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ad_config.dart';
import '../ads/ads_service.dart';
import '../core/app_info.dart';
import '../core/more_apps.dart';
import '../core/settings.dart';
import 'privacy_screen.dart';

/// Behind the parent gate: listening settings, privacy, rating and more HomiLabs apps,
/// and the ad test lab.
class GrownupsScreen extends StatefulWidget {
  const GrownupsScreen({super.key});

  @override
  State<GrownupsScreen> createState() => _GrownupsScreenState();
}

class _GrownupsScreenState extends State<GrownupsScreen> {
  final settings = Settings.instance;
  final ads = AdsService.instance;
  PermissionStatus? _mic;

  @override
  void initState() {
    super.initState();
    settings.addListener(_changed);
    ads.addListener(_changed);
    ads.refreshConsent();
    Permission.microphone.status.then((s) => setState(() => _mic = s));
  }

  @override
  void dispose() {
    settings.removeListener(_changed);
    ads.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _requestMic() async {
    final s = await Permission.microphone.request();
    if (s.isPermanentlyDenied) await openAppSettings();
    final now = await Permission.microphone.status;
    setState(() => _mic = now);
  }

  Future<void> _openStore(String package) =>
      launchUrl(Uri.parse(playLink(package)), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(t, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Grown-ups')),
      body: ListView(children: [
        header('Listening'),
        SwitchListTile(
          key: const Key('mic-switch'),
          title: const Text('Pets repeat what they hear'),
          subtitle: const Text('Uses the microphone while the app is open. Nothing is saved or sent.'),
          value: settings.micOn,
          onChanged: (v) => settings.micOn = v,
        ),
        if (_mic != null && !_mic!.isGranted)
          ListTile(
            leading: const Icon(Icons.mic_off),
            title: const Text('Microphone permission is off'),
            subtitle: Text(_mic!.isPermanentlyDenied ? 'Tap to open Android settings' : 'Tap to allow'),
            onTap: _requestMic,
          ),
        ListTile(
          title: const Text('Listening sensitivity'),
          subtitle: Slider(
            key: const Key('sensitivity'),
            value: settings.sensitivity,
            divisions: 10,
            label: settings.sensitivity < 0.35 ? 'Loud voices only' : settings.sensitivity > 0.75 ? 'Whispers too' : 'Normal',
            onChanged: (v) => settings.sensitivity = v,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Lower it in a noisy room if the pets keep repeating background sounds.', style: TextStyle(color: Colors.black54)),
        ),
        header('Privacy'),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
        ),
        if (ads.privacyOptionsRequired)
          ListTile(
            key: const Key('privacy-options'),
            leading: const Icon(Icons.tune),
            title: const Text('Ad privacy choices'),
            onTap: ads.showPrivacyOptions,
          ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Contact us'),
          subtitle: const Text(AppInfo.contactEmail),
          onTap: () => launchUrl(Uri.parse('mailto:${AppInfo.contactEmail}?subject=${AppInfo.name}')),
        ),
        header('Rate & more apps'),
        ListTile(
          key: const Key('rate-app'),
          leading: const Icon(Icons.star_outline),
          title: const Text('Rate this app on Google Play'),
          onTap: () => _openStore(ownPackage),
        ),
        header('More from HomiLabs'),
        for (final app in moreApps)
          ListTile(
            title: Text(app.name),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openStore(app.package),
          ),
        header('Ad test lab'),
        _AdLab(ads: ads),
        const SizedBox(height: 16),
        Center(child: Text('${AppInfo.name} ${AppInfo.version} · ${AppInfo.developer}', style: const TextStyle(color: Colors.black45))),
        const Center(child: Text('Some sounds: Powered by Stability AI', style: TextStyle(color: Colors.black45))),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _AdLab extends StatelessWidget {
  const _AdLab({required this.ads});

  final AdsService ads;

  @override
  Widget build(BuildContext context) {
    final mode = AdConfig.realAds ? 'Real ad units' : 'Google test ad units';
    Widget chip(String label, bool ok) => Chip(
          avatar: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: ok ? Colors.green : Colors.grey),
          label: Text(label),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$mode · child-directed · max rating G', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          chip('SDK ready', ads.initialized),
          chip('Can request ads', ads.canRequestAds),
          chip('Consent: ${ads.consent.name}', ads.consent != ConsentStatus.unknown),
          chip('Interstitial loaded', ads.interstitialReady),
          chip('Rewarded loaded', ads.rewardedReady),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonal(key: const Key('lab-interstitial'), onPressed: ads.showInterstitial, child: const Text('Show interstitial')),
          FilledButton.tonal(key: const Key('lab-rewarded'), onPressed: ads.showRewarded, child: const Text('Show rewarded')),
          OutlinedButton(onPressed: ads.initialized ? ads.openAdInspector : null, child: const Text('Ad inspector')),
          OutlinedButton(onPressed: ads.resetConsent, child: const Text('Reset consent')),
        ]),
        const SizedBox(height: 12),
        Container(
          key: const Key('ad-log'),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFF3F0FA), borderRadius: BorderRadius.circular(12)),
          child: Text(ads.log.isEmpty ? 'No ad events yet.' : ads.log.take(20).join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
      ]),
    );
  }
}
