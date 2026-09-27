# Play Console listing kit: TalkyPals

Copy-paste material for creating the app in Play Console. Everything here matches what v1.0.0 does.

## Upload

| Item | File |
|---|---|
| App bundle (signed with the upload key) | `releases/v1.0.0-1/talkypals-1.0.0-1.aab` (checksums in `SHA256SUMS`) |
| App icon 512×512 | `store-assets/icon-512.png` |
| Feature graphic 1024×500 | `store-assets/feature-graphic-1024x500.png` |
| Phone screenshots (720×1440) | `store-assets/screenshots/phone/` (5) |
| Privacy policy URL | https://tools.homilabs.org/talkypals/privacy.html (Hostinger `tools.homilabs.org/public_html/talkypals/`; mirror: GitHub Pages https://awaizfatima08.github.io/talkingpets/privacy.html) |

Package `com.homilabs.talkypals` (never change it after the first upload) · version 1.0.0 (versionCode 1) · minSdk 24 · targetSdk 36.
Use **Play App Signing** (the default). `.secrets/talkypals-upload.keystore` is the upload key; credentials in `.secrets/talkypals-upload-keystore-credentials.txt`. Upload-key SHA-256: `2A:4D:F7:1A:6B:33:A4:26:1B:79:73:55:0A:57:AD:C2:1B:96:B0:F2:22:7B:B3:C5:98:48:F8:DF:0A:3E:D2:C2`.

**Privacy policy hosting:** in GitHub → talkingpets → Settings → Pages, choose *Deploy from a branch*, `main`, folder `/docs`. The policy is also shown in the app (Grown-ups → Privacy policy), so it works offline.

**Before a monetised release:** this bundle serves **Google test ads**. Build with real AdMob IDs first (see `docs/ads.md`). A test-ads build is fine for internal testing.

## Main store listing

**App name** (30 max): `TalkyPals: Funny Talking Pets` (29)

**Short description** (80 max):
`Say something and the cat, parrot and rooster repeat it in a silly voice!` (73)

**Full description**:
```
Say "hello" and TalkyPals says it back… in a funny voice!

Meet three cartoon friends for little ones:
• MIMI the cat repeats your words in a squeaky, purry voice.
• KIWI the parrot copies you with a wobbly bird trill, and even says "Hello!" and "Pretty bird!"
• DOODLE the rooster answers in a warbly cock-a-doodle voice.

TOUCH AND GIGGLE
Every body part does something different. Boop Mimi's nose and she sneezes. Poke an eye and stars spin. Tickle a tummy for giggles and bubbles, pull a tail for a grumpy "pfft!", tap Kiwi's wings to make feathers fly, or press Doodle's comb for a big crow. Rub a head and the pet falls in love. Leave them alone and they yawn and nod off.

SILLY VOICES
One tap switches the echo voice: pet voice, squeaky mouse, big deep bear or wobbly jelly.

DRESS-UP
Party hats, a crown, a bow and funny glasses (a grown-up can unlock them with a short video).

MADE FOR TODDLERS
• Big, bright, easy to play: no reading needed.
• No sign-in, no account, no chat.
• Grown-up areas are behind a simple maths question.

PRIVATE BY DESIGN
The microphone is used only while the app is open. Your child's voice is played back straight away and is never saved or sent anywhere.

TalkyPals is free and shows ads suitable for children (child-directed, non-personalised, rated G).
```

**App category**: Entertainment (or Education) · **Tags**: Kids, Casual, Simulation/Pets
**Contact email**: `homilabs.smc@gmail.com` · **Website**: https://tools.homilabs.org/talkypals/

## App content

| Section | Answer |
|---|---|
| Privacy policy | https://tools.homilabs.org/talkypals/privacy.html |
| Ads | **Yes, my app contains ads** |
| App access | All functionality is available without special access |
| Content rating (IARC) | Category *Game* or *All other app types*. No violence, sexuality, language, controlled substances, gambling. User interaction: No. Shares location: No. Digital purchases: No. Expected: Everyone / PEGI 3 |
| Target audience | **Ages 5 and under** (optionally also 6–8). This enrolls the app in the **Families** program; accept the Families Policy |
| News / Government / Financial / Health | No / No / None / None |
| Advertising ID | **No**, the app does not use the advertising ID (the `AD_ID` and `ACCESS_ADSERVICES_*` permissions are removed from the manifest) |
| Data safety | See below |
| Permissions | `RECORD_AUDIO` (core feature: the pets repeat the child's voice; only while open), `INTERNET` + `ACCESS_NETWORK_STATE` (ads) |

### Families Policy checklist (v1.0.0)
- Ads SDK: Google Mobile Ads (AdMob), which is Families self-certified. All requests child-directed (`AgeRestrictedTreatment.child`, i.e. COPPA + under-age-of-consent) with max rating **G**; UMP consent with `tagForUnderAgeOfConsent`.
- No advertising ID, no analytics, no crash reporting SDKs, no accounts, no data leaving the device from the app itself.
- Interstitials only at a natural break (switching pets), never in the first minute, at most every 2 minutes. Always closable.
- Rewarded video offered only after a parent gate, with a clear offer dialog.
- Grown-up areas and any link out (email, settings) are behind the parent gate.
- Banner kept at the top with extra spacing from the play buttons.

## Data safety form

**Does your app collect or share any of the required user data types?**

- The app itself collects nothing. The AdMob SDK collects some data to serve ads. Declare what Google documents for the Mobile Ads SDK (see "Google Mobile Ads SDK data disclosure" in AdMob help). Typically:

| Data type | Collected | Shared | Purpose | Notes |
|---|---|---|---|---|
| App info and performance → Crash logs / Diagnostics | Yes (by Ads SDK) | Yes (Google) | Advertising, analytics (ad measurement), fraud prevention | |
| Device or other IDs | Yes (by Ads SDK; app-set ID, not the advertising ID) | Yes (Google) | Advertising, fraud prevention | Advertising ID is not used |
| App activity → App interactions (ad interactions) | Yes (by Ads SDK) | Yes | Advertising, analytics | |
| Location → Approximate (IP) | Yes (by Ads SDK) | Yes | Advertising, fraud prevention | Coarse, from IP |
| Audio | **No** | No | – | Processed only in memory on the device and discarded (not "collected" under Google's definition) |

- Encrypted in transit: **Yes** (the Ads SDK uses TLS).
- Users can request deletion: the app stores nothing off-device; say **No** to "provide a way to request deletion" unless required, and point to Google's controls.
- Committed to the Families Policy: **Yes**.

Check the current Google Mobile Ads SDK disclosure page before submitting; it is the source of truth for the ad-SDK rows.

## Before production

1. Create an **Internal testing** release and upload the AAB. Check the pre-launch report (crashes, accessibility). The robot can pass the parent gate only by chance, which is expected.
2. **Personal developer accounts created after Nov 2023** need a closed test with 12+ opted-in testers for 14 days before production. Organisation accounts are exempt.
3. Do the manual real-voice check in `docs/testing.md` with a child's voice.
4. Switch to real AdMob IDs (`docs/ads.md`) for the monetised release; bump `version:` in `pubspec.yaml` for every new upload.
