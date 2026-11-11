# Ads in TalkyPals

TalkyPals is the in-app ads test bed. Everything ad-related lives in `lib/ads/`.

## What is integrated

| Format | Where | Rules |
|---|---|---|
| Anchored adaptive **banner** | Top of the play screen (`BannerSlot`) | Space is reserved so nothing jumps; reloads after 60 s on failure |
| **Interstitial** | On a pet switch (`AdsService.onNaturalBreak`) | `AdPacing`: never in the first 60 s, at least 120 s apart, every 3rd switch |
| **Rewarded** | 🎁 button → parent gate → offer dialog → video | Reward = dress-up hats unlocked for good (`Settings.dressUpUnlocked`) |
| UMP consent | App start (`AdsService.init`) | `tagForUnderAgeOfConsent: true`; privacy-options entry appears in Grown-ups when required |

Every request uses `RequestConfiguration(ageRestrictedTreatment: child, maxAdContentRating: G)`; the manifest removes `com.google.android.gms.permission.AD_ID`. The mic is stopped while a full-screen ad shows and restarted after (`AdsService.onFullScreen`).

## Ad test lab (Grown-ups → Ad test lab)

Status chips (SDK ready, can request ads, consent status, interstitial/rewarded loaded), buttons to **show an interstitial or rewarded ad now**, open the **Ad Inspector**, **reset consent**, and a live **event log** (loads, failures with codes, impressions, clicks, closes, rewards).

## Ad units (HomiLabs AdMob account, publisher pub-2087846699268567)

Created 11 Nov 2026 on homilabs.smc@gmail.com, app "TalkyPals: Funny Talking Pets" (linked to Google Play).

| | Real (release builds) | Google test (debug/profile builds) |
|---|---|---|
| App ID | `ca-app-pub-2087846699268567~7871177075` | `ca-app-pub-3940256099942544~3347511713` |
| Banner | `ca-app-pub-2087846699268567/3020185971` | `ca-app-pub-3940256099942544/9214589741` |
| Interstitial | `ca-app-pub-2087846699268567/6276904702` | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded ("TalkyPals Rewarded Hats") | `ca-app-pub-2087846699268567/2255713305` | `ca-app-pub-3940256099942544/5224354917` |

- `AdConfig.realAds` defaults to `kReleaseMode`; force with `--dart-define=TP_REAL_ADS=true|false`. The app ID is set per build type in `android/app/build.gradle.kts` (release = real) and must match.
- `AdConfig.testDeviceIds` lists your own phones (hashed ID from logcat "Use RequestConfiguration…"), so they get test ads even in release builds. Add every phone you test on; **never click real ads on your own devices**.
- `app-ads.txt` is served at https://tools.homilabs.org/app-ads.txt and https://homilabs.org/app-ads.txt (`google.com, pub-2087846699268567, DIRECT, f08c47fec0942fa0`).
- AdMob review of the app started 11 Nov 2026 (2–3 days, limited ad serving until then). New units can take up to an hour to fill.
- The Ad test lab shows "Real ad units" or "Google test ad units".

## Mediation / other networks

Add the adapter packages, then check they are on Google's Families self-certified list before shipping to a children's audience.
