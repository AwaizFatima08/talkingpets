# TalkyPals

Toddler app: five 3D pets (cat Mimi, parrot Kiwi, rooster Doodle, puppy Biscuit, elephant Peanut; code-drawn versions kept as fallback) repeat what the child says in funny voices and react per body part to touch. Also the owner's platform for testing in-app ads. No login, no backend.

## Locked
- Flutter, Android only, portrait, English. Package `com.homilabs.talkypals`: never change after the first Play upload. Developer name HomiLabs, contact homilabs.smc@gmail.com.
- Audio is native Kotlin (`TalkEngine`, `SfxPlayer`, `Speaker`) behind `talkypals/audio` + `talkypals/audio_events`. Voice stays in memory, never stored or sent.
- Ads: Google Mobile Ads, always child-directed (`AgeRestrictedTreatment.child`, rating G), AD_ID + ACCESS_ADSERVICES_* permissions removed. Test IDs by default; real IDs only via build flags (`docs/ads.md`). Rewarded and grown-up areas behind the parent gate.
- Sounds are synthesized by `scripts/make_sfx.py` (no downloads), plus 12 homidev `sfx-ui-basic` OGGs in `assets/audio/sfx/` (`hd_*` names in `sfxVariants`, random version per tap). These need "Powered by Stability AI" (Grown-ups screen) — never remove it.
- 3D art: homidev cut-outs in `assets/images/` → `python3 scripts/prep_art.py` (map in `tool/pet_art.json`) → `assets/art/*.webp`; touch regions in `lib/pets/pet_art.dart`. Raw PNGs are declared in pubspec so `release-check.sh` passes (Homi's choice, 13 Nov 2026). Font: Quicksand (OFL, from Debian `fonts-quicksand`), in `assets/fonts/`.

## Status (2026-09-27)
v1.0.0 (versionCode 1) built, signed and tested on a Galaxy A12 (see `docs/testing.md`). Artifacts in `releases/v1.0.0-1/` (gitignored; in local + Drive backups). Play app created 2026-09-27 on the Homilabs organisation account (app id 4975335359315327554): v1.0.0 (versionCode 1) submitted to **production** review on 2026-09-27 (177 countries, full rollout, managed publishing off, so it goes live on approval). Teacher Approved: opted out for now. Privacy policy: https://tools.homilabs.org/talkypals/privacy.html (Hostinger, `public_html/talkypals/`; after editing `docs/privacy.html` re-upload there), mirrored on GitHub Pages. Release builds use the real HomiLabs AdMob units (`docs/ads.md`); debug builds use test IDs.

v1.1.0 (versionCode 4, 2026-11-13): 3D art for all 5 pets, puppy + elephant, homidev sounds, 3D cat launcher icon, parrot TTS lines removed, real ads. AAB in `releases/v1.1.0-4/` (build 3 superseded); store graphics via `python3 scripts/make_store_assets.py`, listing text + release notes in `docs/store-listing-v1.1.0.md`, release-check PASS, handed to Homi for upload. (v1.0.1-2 was built but never uploaded.)

## Commands
- Tests: `flutter test test/`; device: `bash tool/run_device_tests.sh`; drawings: `flutter test tool/preview_pets_test.dart`; icons/feature graphic: `flutter test tool/make_graphics_test.dart`; SFX: `python3 scripts/make_sfx.py`.
- Store screenshots: build with `--dart-define=TP_STORE_SHOTS=true` (hides banner and volume hint). Rebuild normally afterwards!
- Release: `flutter build appbundle --release` (signs via `android/key.properties` → `.secrets/talkypals-upload.keystore`). Bump `version:` in pubspec for each upload.
- Backup: `bash scripts/backup.sh` (commit first; the GitHub layer refuses untracked/uncommitted files).

## Locations
- Local backup: `/mnt/storage/project_backups/talkingpets_backup/`
- Google Drive: folder `1BVGVdeXUd9AMlhqu4mqYCSbMxgQXB7YI` (rclone remote `gdrive`)
- GitHub (**public**): https://github.com/AwaizFatima08/talkingpets. `.secrets/`, `android/key.properties`, `releases/` are gitignored.

## Machine notes
- Test phone: Samsung SM-A125F (Android 12, 720×1600, density 340, font scale 1.3); its media volume is usually 0.
- Gradle release builds sometimes stall/fail once; rerun. Wait ~2 s after `adb install` before `am start`.
- `debuggerd` needs root and JDWP attach fails here; use logcat (`-s TalkEngine` in debug builds) and the Ad test lab log.
