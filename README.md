# TalkyPals

Funny talking pets for toddlers (Android, Flutter). Say something and **Mimi the cat**, **Kiwi the parrot** or **Doodle the rooster** repeats it in a silly voice. Every body part reacts differently to touch (sounds, faces, motion and little bursts of hearts, stars or feathers). Free with child-directed AdMob ads; the project doubles as a test bed for in-app ads.

- No login, no backend. Voice is kept in memory for one reply and never saved or sent.
- Characters are drawn in code; all sounds are synthesized (`scripts/make_sfx.py`), no downloaded assets.
- Package `com.homilabs.talkypals`, developer HomiLabs.

## Build
```
flutter pub get
flutter test test/                       # host tests
bash tool/run_device_tests.sh            # on-device suite (phone connected)
flutter build appbundle --release        # Play upload (signed via android/key.properties)
```
Real ads: see `docs/ads.md`. Store listing: `docs/play-console-listing-kit.md`. Testing: `docs/testing.md`.

## Layout
- `android/app/src/main/kotlin/.../TalkEngine.kt`: voice detection (adaptive noise floor), capture, pitch/vibrato/tremolo playback with a level stream for lip-sync. `SfxPlayer.kt` (SoundPool), `Speaker.kt` (parrot TTS), `MainActivity.kt` (channels).
- `lib/core/`: `audio.dart` (bridge), `pets.dart` (pets, voices, body part → reactions), `settings.dart`.
- `lib/pets/`: `toon.dart` (pose, eyes, accessories, base painter), one painter per pet, `pet_view.dart` (life, reactions, touch), `particles.dart`.
- `lib/ads/`: config and pacing, service (consent, interstitial, rewarded, event log), banner.
- `lib/screens/`: intro, play, grown-ups (settings + Ad test lab), privacy.
- `docs/`: developer docs plus the public site (`index.html`, `privacy.html`) for GitHub Pages.

## Backup
`bash scripts/backup.sh`: local copy, Google Drive (rclone `gdrive`), GitHub.
