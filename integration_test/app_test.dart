// On-device regression suite. Grant the mic first, and push the test clip:
//
//   adb shell pm grant com.homilabs.talkypals android.permission.RECORD_AUDIO
//   adb push tool/testdata/hello_kitty.wav /sdcard/Android/data/com.homilabs.talkypals/files/
//   flutter test integration_test/app_test.dart -d <device>
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkypals/ads/ad_config.dart';
import 'package:talkypals/ads/ads_service.dart';
import 'package:talkypals/core/audio.dart';
import 'package:talkypals/core/pets.dart';
import 'package:talkypals/core/settings.dart';
import 'package:talkypals/main.dart' as app;
import 'package:talkypals/pets/pet_view.dart';
import 'package:talkypals/pets/toon.dart';
import 'package:talkypals/screens/grownups_screen.dart';
import 'package:talkypals/screens/play_screen.dart';

const clip = '/sdcard/Android/data/com.homilabs.talkypals/files/hello_kitty.wav';

/// Pumps until [cond] holds (animations never settle, so no pumpAndSettle).
Future<void> pumpUntil(WidgetTester t, bool Function() cond, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('condition not met', timeout);
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> pumpFor(WidgetTester t, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

PetViewState petState(WidgetTester t) => t.state<PetViewState>(find.byType(PetView).last);

/// Taps a pet at canvas coordinates (1000-unit box, see PetPainter).
Future<void> tapPet(WidgetTester t, Offset canvas) async {
  final box = t.renderObject<RenderBox>(find.byType(PetView).last);
  final size = box.size;
  final s = PetPainter.scaleFor(size);
  final local = Offset((size.width - 1000 * s) / 2 + canvas.dx * s, (size.height - 1000 * s) / 2 + canvas.dy * s);
  await t.tapAt(box.localToGlobal(local));
  await t.pump(const Duration(milliseconds: 300));
}

Future<void> passGate(WidgetTester t, {bool correct = true}) async {
  await pumpUntil(t, () => find.byKey(const Key('gate-question')).evaluate().isNotEmpty);
  final q = t.widget<Text>(find.byKey(const Key('gate-question'))).data!;
  final m = RegExp(r'(\d+) \+ (\d+)').firstMatch(q)!;
  final answer = int.parse(m[1]!) + int.parse(m[2]!);
  final keys = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('gate-') && (w.key as ValueKey<String>).value != 'gate-question');
  final options = keys.evaluate().map((e) => int.parse((e.widget.key as ValueKey<String>).value.substring(5))).toList();
  final pick = correct ? answer : options.firstWhere((o) => o != answer);
  await t.tap(find.byKey(Key('gate-$pick')));
  await pumpFor(t, const Duration(milliseconds: 800));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TalkyPals end to end', (t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Full-screen ads would cover the app mid-test; pacing has its own unit test.
    AdsService.instance.pacing = AdPacing(firstAfter: const Duration(days: 1));
    app.main();
    await pumpUntil(t, () => find.byKey(const Key('start')).evaluate().isNotEmpty, timeout: const Duration(seconds: 60));

    // Intro -> play (mic already granted by adb).
    await t.tap(find.byKey(const Key('start')));
    await pumpUntil(t, () => find.byType(PlayScreen).evaluate().isNotEmpty);
    expect(Settings.instance.introSeen, isTrue);
    await pumpUntil(t, () => PetAudio.instance.current == EchoState.listening, timeout: const Duration(seconds: 15));

    // Every body part of every pet reacts.
    const spots = {
      PetKind.cat: {BodyPart.nose: Offset(500, 450), BodyPart.eyes: Offset(412, 388), BodyPart.ears: Offset(300, 200),
        BodyPart.head: Offset(500, 250), BodyPart.cheeks: Offset(320, 480), BodyPart.belly: Offset(500, 780),
        BodyPart.tail: Offset(835, 740), BodyPart.paws: Offset(440, 905)},
      PetKind.parrot: {BodyPart.beak: Offset(500, 410), BodyPart.eyes: Offset(568, 318), BodyPart.crest: Offset(500, 90),
        BodyPart.head: Offset(380, 250), BodyPart.wings: Offset(330, 700), BodyPart.belly: Offset(500, 700),
        BodyPart.feet: Offset(455, 872), BodyPart.tail: Offset(500, 960)},
      PetKind.rooster: {BodyPart.comb: Offset(500, 220), BodyPart.beak: Offset(500, 415), BodyPart.wattle: Offset(500, 490),
        BodyPart.eyes: Offset(447, 345), BodyPart.head: Offset(370, 330), BodyPart.wings: Offset(300, 700),
        BodyPart.belly: Offset(500, 700), BodyPart.feet: Offset(455, 900), BodyPart.tail: Offset(850, 340)},
    };
    for (final e in spots.entries) {
      await t.tap(find.byKey(Key('pick-${e.key.name}')));
      await pumpFor(t, const Duration(milliseconds: 2500));
      expect(petState(t).widget.pet.kind, e.key);
      for (final part in e.value.entries) {
        await tapPet(t, part.value);
        await pumpUntil(t, () => petState(t).activePart == part.key, timeout: const Duration(seconds: 3));
        final r = petState(t).activeReaction!;
        expect(petOf(e.key).reactions[part.key], contains(r), reason: '${e.key.name}/${part.key.name}');
        await pumpFor(t, const Duration(milliseconds: 1200));
      }
    }

    // The native voice pipeline: hear -> talk -> listen again, for each pet voice.
    for (final kind in PetKind.values) {
      await t.tap(find.byKey(Key('pick-${kind.name}')));
      await pumpFor(t, const Duration(milliseconds: 4000)); // let the greeting finish
      final seen = <EchoState>[];
      final sub = PetAudio.instance.states.listen(seen.add);
      await pumpUntil(t, () => PetAudio.instance.current == EchoState.listening);
      expect(await PetAudio.instance.simulateUtterance(clip), isTrue, reason: 'push $clip first');
      try {
        await pumpUntil(t, () => seen.contains(EchoState.talking) && PetAudio.instance.current == EchoState.listening);
      } on TimeoutException {
        fail('${kind.name}: states seen $seen, now ${PetAudio.instance.current}');
      }
      await sub.cancel();
      expect(seen.indexOf(EchoState.hearing), lessThan(seen.indexOf(EchoState.talking)), reason: kind.name);
    }

    // Tone button cycles and persists.
    final before = Settings.instance.tone;
    await t.tap(find.byKey(const Key('tone')));
    await t.pump(const Duration(milliseconds: 300));
    expect(Settings.instance.tone, isNot(before));

    // Parent gate: a wrong answer keeps grown-ups out, the right one lets them in.
    await t.tap(find.byKey(const Key('grownups')));
    await passGate(t, correct: false);
    expect(find.byType(GrownupsScreen), findsNothing);
    await t.tap(find.byKey(const Key('grownups')));
    await passGate(t);
    await pumpUntil(t, () => find.byType(GrownupsScreen).evaluate().isNotEmpty);

    // Listening can be switched off (mic released) and back on.
    await t.tap(find.byKey(const Key('mic-switch')));
    await pumpFor(t, const Duration(milliseconds: 500));
    expect(Settings.instance.micOn, isFalse);
    await t.tap(find.byKey(const Key('mic-switch')));
    await pumpFor(t, const Duration(milliseconds: 300));
    expect(Settings.instance.micOn, isTrue);
    await t.pageBack();
    await pumpUntil(t, () => PetAudio.instance.current == EchoState.listening, timeout: const Duration(seconds: 10));

    // The ads SDK starts and preloads both full-screen formats (needs network).
    final ads = AdsService.instance;
    await pumpUntil(t, () => ads.initialized && ads.interstitialReady && ads.rewardedReady, timeout: const Duration(seconds: 60));
    expect(find.byKey(const Key('banner-slot')), findsOneWidget);
    expect(Settings.instance.accessory, Accessory.none);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
