# TalkyPals

Toddler app: three code-drawn toon pets (cat Mimi, parrot Kiwi, rooster Doodle) repeat what the child says in funny voices and react per body part to touch. Also the owner's platform for testing in-app ads. No login, no backend.

## Locked
- Flutter, Android only, portrait, English. Package `com.homilabs.talkypals`: never change after the first Play upload. Developer name HomiLabs, contact homilabs.smc@gmail.com.
- Audio is native Kotlin (`TalkEngine`, `SfxPlayer`, `Speaker`) behind `talkypals/audio` + `talkypals/audio_events`. Voice stays in memory, never stored or sent.
- Ads: Google Mobile Ads, always child-directed (`AgeRestrictedTreatment.child`, rating G), AD_ID + ACCESS_ADSERVICES_* permissions removed. Test IDs by default; real IDs only via build flags (`docs/ads.md`). Rewarded and grown-up areas behind the parent gate.
- Sounds are synthesized by `scripts/make_sfx.py` (no downloads). Font: Quicksand (OFL, from Debian `fonts-quicksand`), in `assets/fonts/`.

## Status (2026-09-27)
v1.0.0 (versionCode 1) built, signed and tested on a Galaxy A12 (see `docs/testing.md`). Artifacts in `releases/v1.0.0-1/` (gitignored; in local + Drive backups). Not yet uploaded to Play. Still to do by the owner: enable GitHub Pages (`main` `/docs`) for the privacy URL, create the Play app, and switch to real AdMob IDs for a monetised release.

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
