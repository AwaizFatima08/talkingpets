import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkypals/ads/ad_config.dart';
import 'package:talkypals/core/pets.dart';
import 'package:talkypals/pets/pet_painters.dart';
import 'package:talkypals/pets/toon.dart';
import 'package:talkypals/widgets/parent_gate.dart';
import 'dart:io';

void main() {
  group('pets', () {
    test('every reaction sound exists as an asset', () {
      for (final name in allSfxNames()) {
        expect(File('assets/sfx/$name.wav').existsSync(), isTrue, reason: name);
      }
    });

    test('each pet has at least 7 touchable parts with reactions', () {
      for (final p in allPets) {
        expect(p.parts.length, greaterThanOrEqualTo(7), reason: p.name);
        for (final list in p.reactions.values) {
          expect(list, isNotEmpty);
          for (final r in list) {
            expect(r.sound != null || r.say != null, isTrue);
          }
        }
      }
    });

    test('rubbing needs a loving head reaction on every pet', () {
      for (final p in allPets) {
        expect(p.reactions[BodyPart.head]!.any((r) => r.mood == Mood.love), isTrue, reason: p.name);
      }
    });

    test('voices are distinct and sensible', () {
      final pitches = allPets.map((p) => p.voice.pitch).toSet();
      expect(pitches.length, allPets.length);
      for (final p in allPets) {
        for (final t in Tone.values) {
          final v = p.voiceFor(t);
          expect(v.pitch, inInclusiveRange(0.5, 2.5));
        }
      }
    });
  });

  group('hit testing', () {
    const size = Size(400, 400);
    Offset at(double x, double y) {
      final s = PetPainter.scaleFor(size);
      return Offset((size.width - 1000 * s) / 2 + x * s, (size.height - 1000 * s) / 2 + y * s);
    }

    final expectations = <PetKind, Map<BodyPart, Offset>>{
      PetKind.cat: {
        BodyPart.nose: const Offset(500, 450),
        BodyPart.eyes: const Offset(412, 388),
        BodyPart.ears: const Offset(300, 200),
        BodyPart.head: const Offset(500, 250),
        BodyPart.cheeks: const Offset(320, 480),
        BodyPart.belly: const Offset(500, 780),
        BodyPart.tail: const Offset(835, 740),
        BodyPart.paws: const Offset(440, 905),
      },
      PetKind.parrot: {
        BodyPart.beak: const Offset(500, 410),
        BodyPart.eyes: const Offset(568, 318),
        BodyPart.crest: const Offset(500, 90),
        BodyPart.head: const Offset(380, 250),
        BodyPart.wings: const Offset(330, 700),
        BodyPart.belly: const Offset(500, 700),
        BodyPart.feet: const Offset(455, 872),
        BodyPart.tail: const Offset(500, 960),
      },
      PetKind.rooster: {
        BodyPart.comb: const Offset(500, 220),
        BodyPart.beak: const Offset(500, 415),
        BodyPart.wattle: const Offset(500, 490),
        BodyPart.eyes: const Offset(447, 345),
        BodyPart.head: const Offset(370, 330),
        BodyPart.wings: const Offset(300, 700),
        BodyPart.belly: const Offset(500, 700),
        BodyPart.feet: const Offset(455, 900),
        BodyPart.tail: const Offset(850, 340),
      },
    };

    for (final e in expectations.entries) {
      test('${e.key.name} parts', () {
        final painter = painterFor(e.key, const PetPose());
        for (final part in e.value.entries) {
          expect(painter.hitTestPart(at(part.value.dx, part.value.dy), size), part.key,
              reason: '${e.key.name} ${part.key.name}');
        }
        // Every touchable part has a reaction.
        for (final (part, _) in painter.hitRegions) {
          expect(petOf(e.key).reactions.containsKey(part), isTrue, reason: '${e.key.name} ${part.name}');
        }
        expect(painter.hitTestPart(at(30, 30), size), isNull);
      });
    }
  });

  group('parent gate', () {
    test('questions have exactly one right answer among 4 options', () {
      final rng = math.Random(1);
      for (var i = 0; i < 200; i++) {
        final q = GateQuestion.random(rng);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options.where((o) => o == q.answer).length, 1);
        expect(q.answer, greaterThanOrEqualTo(6));
      }
    });
  });

  group('ad pacing', () {
    test('no interstitial in the first minute, then every 3rd switch, 2 minutes apart', () {
      var now = DateTime(2026, 1, 1, 12);
      final p = AdPacing(clock: () => now);
      for (var i = 0; i < 5; i++) {
        expect(p.onSwitch(), isFalse);
      }
      now = now.add(const Duration(seconds: 61));
      expect(p.onSwitch(), isTrue); // 6 switches so far
      p.markShown();
      now = now.add(const Duration(seconds: 30));
      for (var i = 0; i < 5; i++) {
        expect(p.onSwitch(), isFalse); // gap not reached
      }
      now = now.add(const Duration(seconds: 100));
      expect(p.onSwitch(), isTrue);
      p.markShown();
      now = now.add(const Duration(seconds: 200));
      expect(p.onSwitch(), isFalse);
      expect(p.onSwitch(), isFalse);
      expect(p.onSwitch(), isTrue);
    });
  });

  test('test ad units are Google samples unless real ads are requested', () {
    expect(AdConfig.realAds, isFalse);
    expect(AdConfig.bannerId, startsWith('ca-app-pub-3940256099942544/'));
    expect(AdConfig.interstitialId, startsWith('ca-app-pub-3940256099942544/'));
    expect(AdConfig.rewardedId, startsWith('ca-app-pub-3940256099942544/'));
  });
}
