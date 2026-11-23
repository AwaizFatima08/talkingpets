/// Related HomiLabs apps on the Grown-ups screen (behind the parent gate).
/// Names are store titles, so they are not translated.
const moreApps = [
  (name: 'Tiny Tunes Studio: Kids Music', package: 'com.homilabs.tinytunes'),
  (name: 'Bumper Buddies: Kids Pinball', package: 'com.homilabs.bumperbuddies'),
  (name: 'Rainbow Keys: Toddler Piano', package: 'com.homilabs.rainbowkeys'),
];

/// This app's own Play listing (the "Rate this app" link).
const ownPackage = 'com.homilabs.talkypals';

/// A Play link tagged so Play Console reports installs that came from this app.
String playLink(String package) =>
    'https://play.google.com/store/apps/details?id=$package'
    '&referrer=utm_source%3Dtalkypals%26utm_medium%3Dapp%26utm_campaign%3Dcrosspromo';
