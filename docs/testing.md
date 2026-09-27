# Testing TalkyPals

## Automated

| Suite | Command | What it proves |
|---|---|---|
| Static analysis | `flutter analyze` | No issues |
| Host unit tests (10) | `flutter test test/` | Every reaction sound exists; each pet has 7+ touchable parts; hit-testing maps canvas points to the right body part for all 3 pets (and every region has a reaction); voices are distinct; parent-gate questions have exactly one right answer; interstitial pacing (first minute, 2-minute gap, every 3rd switch); test ad units by default |
| On-device end to end | `bash tool/run_device_tests.sh [serial]` | Real app + real native audio on a phone: intro → play; all 25 body parts on 3 pets react; the native voice pipeline hear → talk → listen for all 3 pet voices (synthetic clip injected into the live mic stream); tone button; parent gate wrong/right; listening switch off/on; Ads SDK starts and preloads interstitial + rewarded; banner slot present |
| Touch contact sheet | `python3 tool/device_touch_test.py out.png` | Taps every body part on the phone and saves a picture of each reaction |
| Stress | `adb shell monkey -p com.homilabs.talkypals --pct-syskeys 0 --pct-appswitch 0 --throttle 100 -v 3000` | A toddler mashing the screen |
| Drawings | `flutter test tool/preview_pets_test.dart` | Renders every pet in 9 moods to `build/preview/` |

Debug builds only: `adb shell am broadcast -a com.homilabs.talkypals.SIMULATE --es path <44.1 kHz mono WAV>` injects a clip into the mic stream; add `--es mode acoustic` to play it through the phone's speaker so the **real microphone** hears it (needs media volume up). Detector logs: `adb logcat -s TalkEngine`.

## Results for v1.0.0 (27 Sep 2026, Samsung Galaxy A12 SM-A125F, Android 12, font scale 1.3)

- `flutter analyze`: no issues. Host tests 10/10. Device suite: passed (3 hear→talk cycles, 25 reactions).
- Real microphone: the phone's own speaker → mic path triggered and echoed a phrase (−22.7 dBFS vs −29 dB threshold in a room with a steady −38 dB fan/hum), and steady room noise alone never triggers.
- Release build by hand: cold start 4.6 s; mic denied → touch play still works and the mic badge asks a grown-up; re-grant through the gate; interstitial on the 3rd switch after 60 s (mic stops during the ad and resumes after); rewarded video → reward → hats unlocked instantly; wrong gate answer refused; Home → mic released at once ("No active record clients"), back → resumes; banner click opens the browser, Back returns to a working app.
- Monkey: 3,000 + 2,500 events on the release build: no crashes, no ANRs. Memory ~225 MB PSS.
- Release APK permissions: `RECORD_AUDIO`, `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` (the last two from Play-services/WorkManager). Advertising ID and ad-services permissions removed.

### Bugs found and fixed during device testing
- Noise floor stuck at the start value, so a fan or TV made the pet capture and replay 8 s of noise in a loop → percentile floor over the last 3 s, 0.5 s calibration, steady-noise rejection, 6 s cap.
- Parrot ignored the child for ~4 s after each spoken word (a long mute could not be shortened) → explicit "speaking" flag.
- Interrupted TTS (app paused) left "speaking" on: mouth kept moving and the mic stayed deaf → handle `onStop`, clear on `stop()`.
- Start/stop race could leave the mic off after an ad → engine control serialized on one thread.
- Wing hit regions cancelled out (opposite path winding) → path unions.
- Intro pets invisible on narrow phones; buttons didn't wake a sleeping pet; reaction animation waited for TTS → fixed.
- The phone's media volume was 0 (no sound at all) → a red 🔇 badge now shows and opens the volume slider.

### Notes
- `flutter test integration_test/...` reinstalls the app and resets the mic permission; use `tool/run_device_tests.sh`, which grants it and pushes the clip.
- Gradle on this machine occasionally stalls or fails a release build for no reason; rerun the same command.
- After `adb install`, wait ~2 s before `am start` (Samsung sometimes removes the new task).

## Manual real-voice check (10 minutes, needs a child or grown-up voice and a real phone)

| # | Do this | Expect |
|---|---|---|
| 1 | Media volume up; stay quiet 10 s with a fan/TV on | Pet idles; no echo of background noise |
| 2 | Say "hello kitty" 30–50 cm from the phone | Ear badge turns pink, pet tilts its head; ~0.7 s after you stop, it repeats in a high, funny voice while its mouth moves |
| 3 | Whisper; then shout | Whisper may be ignored at default sensitivity (raise it in Grown-ups); shout is repeated, not distorted too badly |
| 4 | Tone button (top right): 🐭, 🐻, 🌀 | Squeaky, deep and slow, wobbly voices |
| 5 | Switch to Kiwi and Doodle and talk | Parrot trill voice; rooster warbly voice |
| 6 | Tap Kiwi's beak | Speaks "Hello!" etc.; does not echo its own words |
| 7 | Tap every body part | A different sound + face each time; nothing is heard back as an echo |
| 8 | Talk while an interstitial is up | Nothing is recorded; after closing, the pet listens again |
| 9 | Leave it 1 minute | Pet yawns, dozes (Z); talking or a tap wakes it |
