import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

/// Kiwi: a round green parrot with a red crest, sitting on a branch.
class ParrotPainter extends PetPainter {
  ParrotPainter(super.pose);

  static const green = Color(0xFF52C46C);
  static const greenDark = Color(0xFF2F9A50);
  static const belly = Color(0xFFFFDA55);
  static const red = Color(0xFFFF5A4E);
  static const orange = Color(0xFFFF9D3C);
  static const blue = Color(0xFF3E8EF7);
  static const face = Color(0xFFFFFDF7);
  static const beakTop = Color(0xFFFFC24F);
  static const beakBottom = Color(0xFFF09E2E);
  static const toes = Color(0xFF9FA5AD);
  static const bark = Color(0xFF9A6A3F);

  static const eyeL = Offset(432, 318), eyeR = Offset(568, 318);
  static const neck = Offset(500, 490);

  @override
  Offset get feet => const Offset(500, 880);

  @override
  HeadAnchors get anchors => const HeadAnchors(top: Offset(500, 178), eyeLeft: eyeL, eyeRight: eyeR, eyeRadius: 44, width: 344);

  static final Path _body = Path()
    ..moveTo(500, 470)
    ..cubicTo(600, 470, 660, 580, 658, 690)
    ..cubicTo(656, 800, 590, 868, 500, 868)
    ..cubicTo(410, 868, 344, 800, 342, 690)
    ..cubicTo(340, 580, 400, 470, 500, 470)
    ..close();

  static Path _wing(bool left) {
    final d = left ? -1.0 : 1.0;
    return Path()
      ..moveTo(500 + d * 128, 545)
      ..cubicTo(500 + d * 205, 580, 500 + d * 225, 720, 500 + d * 180, 845)
      ..cubicTo(500 + d * 150, 800, 500 + d * 95, 700, 500 + d * 92, 610)
      ..cubicTo(500 + d * 92, 575, 500 + d * 105, 552, 500 + d * 128, 545)
      ..close();
  }

  static Path feather(Offset base, Offset tip, double width) {
    final dir = tip - base;
    final len = dir.distance;
    final n = Offset(-dir.dy / len, dir.dx / len) * (width / 2);
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx + dir.dx * 0.25 + n.dx * 1.3, base.dy + dir.dy * 0.25 + n.dy * 1.3,
          base.dx + dir.dx * 0.85 + n.dx * 0.8, base.dy + dir.dy * 0.85 + n.dy * 0.8, tip.dx, tip.dy)
      ..cubicTo(base.dx + dir.dx * 0.85 - n.dx * 0.8, base.dy + dir.dy * 0.85 - n.dy * 0.8,
          base.dx + dir.dx * 0.25 - n.dx * 1.3, base.dy + dir.dy * 0.25 - n.dy * 1.3, base.dx, base.dy)
      ..close();
  }

  @override
  void draw(Canvas c) {
    // Tail feathers hang behind the branch.
    c.save();
    c.translate(500, 790);
    c.rotate(pose.tail * 0.22);
    c.translate(-500, -790);
    blob(c, feather(const Offset(470, 780), const Offset(405, 995), 62), red);
    blob(c, feather(const Offset(530, 780), const Offset(595, 995), 62), belly);
    blob(c, feather(const Offset(500, 780), const Offset(500, 1010), 72), blue);
    c.restore();

    // Branch.
    final branch = RRect.fromLTRBR(140, 858, 860, 904, const Radius.circular(23));
    c.drawRRect(branch, solid(bark));
    c.drawRRect(branch, outline(8));
    for (final x in [260.0, 700.0, 790.0]) {
      c.drawLine(Offset(x, 872), Offset(x + 40, 872), outline(5)..color = darken(bark, 0.3));
    }
    final leaf = feather(const Offset(150, 870), const Offset(70, 800), 50);
    blob(c, leaf, const Color(0xFF6BD06F), line: 7);
    final leaf2 = feather(const Offset(850, 870), const Offset(940, 820), 46);
    blob(c, leaf2, const Color(0xFF6BD06F), line: 7);

    // Body and belly.
    blob(c, _body, green);
    oval(c, const Offset(500, 718), 102, 128, belly, stroke: false, shade: 0.1);
    final scallop = outline(5)..color = darken(belly, 0.18);
    for (final (x, y) in [(470.0, 660.0), (530.0, 660.0), (500.0, 715.0), (450.0, 770.0), (550.0, 770.0), (500.0, 812.0)]) {
      c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 44, height: 30), 0.3, math.pi - 0.6, false, scallop);
    }

    // Wings flap outwards around the shoulders.
    for (final left in [true, false]) {
      final shoulder = Offset(left ? 372 : 628, 555);
      c.save();
      c.translate(shoulder.dx, shoulder.dy);
      c.rotate((left ? 1 : -1) * pose.wing * 1.15);
      c.translate(-shoulder.dx, -shoulder.dy);
      final w = _wing(left);
      blob(c, w, greenDark, stroke: false);
      c.save();
      c.clipPath(w);
      c.drawRect(const Rect.fromLTRB(0, 730, 1000, 900), solid(blue));
      c.drawCircle(Offset(left ? 385 : 615, 575), 42, solid(red));
      c.restore();
      c.drawPath(w, outline(9));
      c.restore();
    }

    // Toes wrap over the branch.
    for (final x in [455.0, 545.0]) {
      for (final dx in [-16.0, 16.0]) {
        oval(c, Offset(x + dx, 870), 15, 24, toes, line: 6);
      }
    }

    withHead(c, neck, () {
      // Crest.
      final lift = 1 + 0.45 * pose.crest;
      Offset tip(Offset base, Offset t) => base + (t - base) * lift;
      blob(c, feather(const Offset(470, 190), tip(const Offset(470, 190), const Offset(405, 80)), 46), orange, line: 7);
      blob(c, feather(const Offset(530, 190), tip(const Offset(530, 190), const Offset(595, 80)), 46), orange, line: 7);
      blob(c, feather(const Offset(500, 185), tip(const Offset(500, 185), const Offset(500, 50)), 56), red, line: 7);

      oval(c, const Offset(500, 330), 172, 168, green, shade: 0.12);
      oval(c, const Offset(432, 322), 70, 68, face, stroke: false, shade: 0.03);
      oval(c, const Offset(568, 322), 70, 68, face, stroke: false, shade: 0.03);
      drawEye(c, eyeL, 40, 48, pose, left: true, skin: face);
      drawEye(c, eyeR, 40, 48, pose, left: false, skin: face);
      blush(c, const Offset(398, 402), 34, 20);
      blush(c, const Offset(602, 402), 34, 20);
      _beak(c);
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  void _beak(Canvas c) {
    final open = switch (pose.mood) {
      Mood.laugh => math.max(pose.mouth, 0.7),
      Mood.surprised => math.max(pose.mouth, 0.45),
      Mood.grumpy => math.max(pose.mouth, 0.3),
      _ => pose.mouth,
    };
    final drop = open * 75;
    // Mouth inside and tongue.
    if (open > 0.05) {
      final inside = Rect.fromLTRB(462, 415, 538, 452 + drop);
      c.drawOval(inside, solid(const Color(0xFF7A2430)));
      c.drawOval(Rect.fromCenter(center: Offset(500, inside.bottom - 14), width: 44, height: 22), solid(const Color(0xFFFF7D92)));
      c.drawOval(inside, outline(6));
    }
    oval(c, Offset(500, 440 + drop), 42, 26, beakBottom, line: 7);
    final upper = Path()
      ..moveTo(440, 382)
      ..cubicTo(442, 345, 558, 345, 560, 382)
      ..cubicTo(562, 420, 532, 450, 500, 470 - open * 12)
      ..cubicTo(468, 450, 438, 420, 440, 382)
      ..close();
    blob(c, upper, beakTop, line: 8, shade: 0.22);
    c.drawCircle(const Offset(478, 372), 6, solid(ink));
    c.drawCircle(const Offset(522, 372), 6, solid(ink));
    glint(c, const Offset(470, 395), 8, 0.6);
  }

  @override
  List<(BodyPart, Path)> get hitRegions => [
        (BodyPart.beak, ovalPath(const Offset(500, 415), 72, 70)),
        (BodyPart.eyes, ovalPath(eyeL, 58, 62)..addOval(Rect.fromCenter(center: eyeR, width: 116, height: 124))),
        (BodyPart.crest, ovalPath(const Offset(500, 115), 125, 85)),
        (BodyPart.head, ovalPath(const Offset(500, 330), 180, 176)),
        (BodyPart.feet, Path()..addRect(const Rect.fromLTRB(410, 845, 590, 910))),
        (BodyPart.wings, unionOf([_wing(true), _wing(false), ovalPath(const Offset(310, 700), 55, 130), ovalPath(const Offset(690, 700), 55, 130)])),
        (BodyPart.tail, Path()..addRect(const Rect.fromLTRB(390, 905, 610, 1000))),
        (BodyPart.belly, _body),
      ];
}
