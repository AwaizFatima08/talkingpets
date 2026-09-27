import 'package:flutter/material.dart';

import '../core/app_info.dart';

/// The privacy policy, readable offline. Same text as docs/privacy.html.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const sections = <(String, String)>[
    (
      'In short',
      '${AppInfo.name} is a play app for young children. There is no sign-in, no account and no server of our own. '
          'We do not collect names, photos, contacts or location.'
    ),
    (
      'Microphone',
      'While the app is open, the pets listen for a voice so they can repeat it in a funny tone. The sound is kept in the '
          'phone\'s memory only for the few seconds it takes to play it back, then it is thrown away. Recordings are never '
          'saved to storage and never sent anywhere. Grown-ups can switch listening off in the Grown-ups area.'
    ),
    (
      'Settings on the device',
      'The app remembers a few choices on the phone (which pet was last used, voice style, dress-up hat, listening '
          'sensitivity). They are not sent anywhere and are removed when the app is uninstalled.'
    ),
    (
      'Ads',
      'The app shows ads from Google AdMob to stay free. Every ad request is marked as directed to children '
          '(COPPA and GDPR under-age treatment) with a "G" content rating, so ads are not personalised and the advertising '
          'ID is not used. Google may process limited technical data (such as IP address and device model) to deliver and '
          'measure ads and prevent fraud. See Google\'s policy: https://policies.google.com/technologies/ads. Rewarded videos '
          '(to unlock dress-up hats) are only offered behind a grown-up check.'
    ),
    (
      'Children',
      'The app is designed for children under 5 and follows the Google Play Families policy. Areas for grown-ups, '
          'links out of the app and optional videos are behind a simple maths check.'
    ),
    (
      'Contact',
      'Questions or requests: ${AppInfo.contactEmail}. Developer: ${AppInfo.developer}. '
          'Online version of this policy: ${AppInfo.privacyUrl}'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final (title, body) in sections) ...[
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 18),
        ],
        const Text('Last updated: 27 September 2026', style: TextStyle(color: Colors.black45)),
      ]),
    );
  }
}
