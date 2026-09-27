// Renders TalkyPals' launcher icons and Play Store graphics from the same
// code-drawn pets the app uses.
//
//   flutter test tool/make_graphics_test.dart
//
// Writes:
//   android/app/src/main/res/drawable-*/ic_launcher_foreground.png  adaptive icon layer
//   android/app/src/main/res/mipmap-*/ic_launcher.png               legacy icons
//   store-assets/icon-512.png                                       Play icon
//   store-assets/feature-graphic-1024x500.png                       Play feature graphic
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkypals/core/pets.dart';
import 'package:talkypals/pets/cat_painter.dart';
import 'package:talkypals/pets/pet_painters.dart';
import 'package:talkypals/pets/toon.dart';

const res = 'android/app/src/main/res';
const warm = [Color(0xFFFFE27A), Color(0xFFFFA24C)];

Future<void> save(String path, int w, int h, void Function(Canvas c, Size s) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec), Size(w.toDouble(), h.toDouble()));
  final img = await rec.endRecording().toImage(w, h);
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void warmBackground(Canvas c, Size s) {
  c.drawRect(
    Offset.zero & s,
    Paint()..shader = ui.Gradient.radial(Offset(s.width * 0.5, s.height * 0.4), s.longestSide * 0.75, warm),
  );
}

/// The cat's head (with a speech bubble) filling [fraction] of the square.
void catHead(Canvas c, Size s, double fraction) {
  final v = s.width * fraction / 0.54; // head is ~540 of 1000 units wide
  c.save();
  c.translate(s.width * 0.5 - v * 0.5, s.height * 0.5 - v * 0.38);
  CatPainter(const PetPose(mood: Mood.happy, mouth: 0.75), headOnly: true).paint(c, Size(v, v));
  c.restore();
}

Future<void> loadFont() async {
  final loader = FontLoader('Quicksand')..addFont(File('assets/fonts/Quicksand-Bold.ttf').readAsBytes().then((b) => ByteData.view(b.buffer)));
  await loader.load();
}

void main() {
  test('make graphics', () async {
    await loadFont();
    // Adaptive foreground: 108dp canvas, pet inside the 66dp safe zone.
    const fg = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432};
    for (final e in fg.entries) {
      await save('$res/drawable-${e.key}/ic_launcher_foreground.png', e.value, e.value, (c, s) => catHead(c, s, 0.58));
    }
    const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in legacy.entries) {
      await save('$res/mipmap-${e.key}/ic_launcher.png', e.value, e.value, (c, s) {
        c.clipRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.width * 0.22)));
        warmBackground(c, s);
        catHead(c, s, 0.72);
      });
    }
    await save('store-assets/icon-512.png', 512, 512, (c, s) {
      warmBackground(c, s);
      catHead(c, s, 0.7);
    });

    await save('store-assets/feature-graphic-1024x500.png', 1024, 500, (c, s) {
      c.drawRect(Offset.zero & s, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), const [Color(0xFF7FD7FF), Color(0xFFE6F8FF)]));
      c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.5, s.height * 1.02), width: s.width * 1.4, height: s.height * 0.5), Paint()..color = const Color(0xFF8BD66E));
      final kinds = [PetKind.parrot, PetKind.cat, PetKind.rooster];
      final moods = [Mood.happy, Mood.laugh, Mood.happy];
      for (var i = 0; i < 3; i++) {
        final size = i == 1 ? 310.0 : 250.0;
        c.save();
        c.translate(640 + i * 150 - size / 2, s.height - size - 4 + (i == 1 ? 0 : 8));
        painterFor(kinds[i], PetPose(mood: moods[i], mouth: i == 1 ? 0.8 : 0.5, wing: i == 0 ? 0.6 : 0)).paint(c, Size(size, size));
        c.restore();
      }
      final title = TextPainter(
        text: const TextSpan(
          text: 'TalkyPals',
          style: TextStyle(fontFamily: 'Quicksand', fontSize: 96, fontWeight: FontWeight.w700, color: Color(0xFFFF7A3D), letterSpacing: -1,
              shadows: [Shadow(color: Colors.white, offset: Offset(4, 4)), Shadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 6))]),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      title.paint(c, const Offset(40, 120));
      final sub = TextPainter(
        text: const TextSpan(text: 'Say something...\nthey say it back, funny!', style: TextStyle(fontFamily: 'Quicksand', fontSize: 36, fontWeight: FontWeight.w700, color: Color(0xFF3A2618), height: 1.25)),
        textDirection: TextDirection.ltr,
      )..layout();
      sub.paint(c, const Offset(48, 250));
    });
  });
}
