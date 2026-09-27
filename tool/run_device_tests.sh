#!/usr/bin/env bash
# Runs integration_test/app_test.dart on the connected phone.
# Grants the microphone and pushes the synthetic voice clip right after the
# test APK is installed (a reinstall resets both).
set -euo pipefail
cd "$(dirname "$0")/.."
PKG=com.homilabs.talkypals
DEV=${1:-$(adb devices | awk 'NR==2{print $1}')}
flutter build apk --debug --target integration_test/app_test.dart
(
  for _ in $(seq 1 180); do
    if adb -s "$DEV" shell pm path $PKG >/dev/null 2>&1; then
      adb -s "$DEV" shell pm grant $PKG android.permission.RECORD_AUDIO 2>/dev/null || true
      adb -s "$DEV" shell mkdir -p /sdcard/Android/data/$PKG/files 2>/dev/null || true
      adb -s "$DEV" push tool/testdata/hello_kitty.wav /sdcard/Android/data/$PKG/files/ >/dev/null 2>&1 || true
    fi
    sleep 1
  done
) &
HELPER=$!
adb -s "$DEV" shell input keyevent KEYCODE_WAKEUP
flutter drive --driver test_driver/integration_test.dart --target integration_test/app_test.dart \
  --use-application-binary build/app/outputs/flutter-apk/app-debug.apk -d "$DEV"
STATUS=$?
kill $HELPER 2>/dev/null || true
exit $STATUS
