// Renders every pet in several moods to build/preview/*.png so the drawings
// can be checked without a device:   flutter test tool/preview_pets_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkypals/core/pets.dart';
import 'package:talkypals/pets/pet_painters.dart';
import 'package:talkypals/pets/toon.dart';

const poses = <String, PetPose>{
  'neutral': PetPose(),
  'happy': PetPose(mood: Mood.happy),
  'talking': PetPose(mood: Mood.happy, mouth: 0.8),
  'laugh': PetPose(mood: Mood.laugh, wing: 1, tail: 1),
  'surprised': PetPose(mood: Mood.surprised, crest: 1, puff: 1),
  'love': PetPose(mood: Mood.love, tilt: 0.12, accessory: Accessory.crown),
  'dizzy': PetPose(mood: Mood.dizzy, accessory: Accessory.partyHat),
  'grumpy': PetPose(mood: Mood.grumpy, accessory: Accessory.glasses),
  'sleepy': PetPose(mood: Mood.sleepy, accessory: Accessory.bow),
};

void main() {
  test('render pet previews', () async {
    const cell = 360.0;
    for (final kind in PetKind.values) {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      final cols = 3;
      final rows = (poses.length / cols).ceil();
      c.drawRect(Rect.fromLTWH(0, 0, cell * cols, cell * rows), Paint()..color = const Color(0xFFBFE6FF));
      var i = 0;
      for (final pose in poses.values) {
        c.save();
        c.translate((i % cols) * cell, (i ~/ cols) * cell);
        painterFor(kind, pose).paint(c, const Size(cell, cell));
        c.restore();
        i++;
      }
      final img = await rec.endRecording().toImage((cell * cols).toInt(), (cell * rows).toInt());
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/preview/${kind.name}.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    }
  });
}
