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

## Test IDs (default)

Google's public sample IDs are used unless real ones are passed at build time:

| | ID |
|---|---|
| App ID | `ca-app-pub-3940256099942544~3347511713` |
| Adaptive banner | `ca-app-pub-3940256099942544/9214589741` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |

## Switching to real ads

1. In AdMob, create the app (Android, package `com.homilabs.talkypals`) and three ad units (banner, interstitial, rewarded). Under the app's settings mark it **directed to children** / "Designed for families".
2. Build with your IDs (no code change):
   ```
   flutter build appbundle --release \
     --dart-define=TP_REAL_ADS=true \
     --dart-define=TP_BANNER_ID=ca-app-pub-XXXX/BBBB \
     --dart-define=TP_INTERSTITIAL_ID=ca-app-pub-XXXX/IIII \
     --dart-define=TP_REWARDED_ID=ca-app-pub-XXXX/RRRR \
     --android-project-arg=admobAppId=ca-app-pub-XXXX~AAAA
   ```
   The Ad test lab then says "Real ad units". Never click your own real ads; add your phone's hashed ID (logcat prints it) to `AdConfig.testDeviceIds` to get test ads on it.
3. Link the Play listing in AdMob once the app is published, and add `app-ads.txt` to the developer website listed on Play.
4. In Play Console → App content → **Ads: Yes**; the target audience is under 5, so only Families-certified SDKs may be used (AdMob is).

## Mediation / other networks

Add the adapter packages, then check they are on Google's Families self-certified list before shipping to a children's audience.
