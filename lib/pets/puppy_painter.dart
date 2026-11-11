import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

/// Biscuit: a round caramel puppy with floppy ears and a waggy tail.
class PuppyPainter extends PetPainter {
  PuppyPainter(super.pose);

  static const fur = Color(0xFFD9A066);
  static const furDark = Color(0xFF9A6233);
  static const cream = Color(0xFFFFF4E4);
  static const nose = Color(0xFF3A2A22);
  static const tongue = Color(0xFFFF7D92);

  static const eyeL = Offset(420, 372), eyeR = Offset(580, 372);
  static const neck = Offset(500, 575);

  @override
  HeadAnchors get anchors => const HeadAnchors(top: Offset(500, 196), eyeLeft: eyeL, eyeRight: eyeR, eyeRadius: 48, width: 440);

  static final Path _head = Path()
    ..moveTo(500, 190)
    ..cubicTo(640, 190, 720, 280, 718, 390)
    ..cubicTo(716, 500, 630, 590, 500, 590)
    ..cubicTo(370, 590, 284, 500, 282, 390)
    ..cubicTo(280, 280, 360, 190, 500, 190)
    ..close();

  static final Path _body = Path()
    ..moveTo(500, 545)
    ..cubicTo(615, 545, 690, 690, 690, 815)
    ..cubicTo(690, 900, 620, 938, 500, 938)
    ..cubicTo(380, 938, 310, 900, 310, 815)
    ..cubicTo(310, 690, 385, 545, 500, 545)
    ..close();

  /// Floppy ear hanging from the side of the head; [flop] lifts it.
  Path _ear(bool left, double flop) {
    final d = left ? -1.0 : 1.0;
    final lift = flop * 90;
    return Path()
      ..moveTo(500 + d * 150, 225)
      ..cubicTo(500 + d * 260, 210, 500 + d * 300, 330 - lift, 500 + d * 290, 470 - lift * 1.5)
      ..cubicTo(500 + d * 285, 540 - lift * 1.5, 500 + d * 225, 545 - lift * 1.4, 500 + d * 210, 480 - lift)
      ..cubicTo(500 + d * 200, 400, 500 + d * 175, 300, 500 + d * 150, 225)
      ..close();
  }

  Path _tail() {
    final w = pose.tail * 0.6;
    final tip = Offset(700 + 90 * math.sin(w), 640 - 30 * math.cos(w));
    return Path()
      ..moveTo(640, 870)
      ..quadraticBezierTo(740, 820, tip.dx, tip.dy);
  }

  @override
  void draw(Canvas c) {
    tube(c, _tail(), 46 + 20 * pose.puff, fur);

    blob(c, _body, fur);
    oval(c, const Offset(500, 790), 110, 125, cream, stroke: false, shade: 0.05);
    for (final x in [385.0, 615.0]) {
      oval(c, Offset(x, 915), 72, 36, fur);
    }
    oval(c, const Offset(440, 905), 50, 38, cream);
    final raise = pose.wing;
    final paw = Offset.lerp(const Offset(560, 905), const Offset(650, 700), raise)!;
    if (raise > 0.05) tube(c, Path()..moveTo(575, 760)..lineTo(paw.dx, paw.dy + 20), 70, fur);
    oval(c, paw, 50, 38, cream);
    for (final p in [const Offset(440, 905), paw]) {
      for (final dx in [-16.0, 16.0]) {
        c.drawLine(p + Offset(dx, 10), p + Offset(dx, 30), outline(6));
      }
    }

    withHead(c, neck, () {
      blob(c, _head, fur, shade: 0.12);
      // A brown patch around one eye, beagle style.
      c.save();
      c.clipPath(_head);
      c.drawOval(Rect.fromCenter(center: const Offset(600, 350), width: 170, height: 150), solid(furDark.withValues(alpha: 0.55)));
      c.restore();
      c.drawPath(_head, outline(9));

      final flop = pose.mood == Mood.surprised ? 0.6 : (pose.mood == Mood.listening ? 0.35 : 0.0);
      for (final left in [true, false]) {
        blob(c, _ear(left, flop), furDark);
      }

      drawEye(c, eyeL, 48, 56, pose, left: true, skin: fur);
      drawEye(c, eyeR, 48, 56, pose, left: false, skin: lighten(furDark, 0.3));
      blush(c, const Offset(355, 470), 36, 20);
      blush(c, const Offset(645, 470), 36, 20);

      oval(c, const Offset(500, 470), 115, 82, cream, stroke: false, shade: 0.04);
      _mouth(c);
      final n = Path()
        ..moveTo(458, 428)
        ..quadraticBezierTo(500, 412, 542, 428)
        ..quadraticBezierTo(535, 468, 500, 476)
        ..quadraticBezierTo(465, 468, 458, 428)
        ..close();
      blob(c, n, nose, line: 6, shade: 0.3);
      glint(c, const Offset(482, 432), 9, 0.7);
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  void _mouth(Canvas c) {
    final open = switch (pose.mood) {
      Mood.laugh => math.max(pose.mouth, 0.75),
      Mood.happy || Mood.love => math.max(pose.mouth, 0.35),
      Mood.surprised => math.max(pose.mouth, 0.35),
      _ => pose.mouth,
    };
    if (open > 0.06) {
      final h = 25 + 75 * open;
      final w = 40 + 25 * open;
      final r = Rect.fromLTWH(500 - w, 488, w * 2, h);
      final m = Path()..addOval(r);
      c.drawPath(m, solid(const Color(0xFF8A2A35)));
      c.save();
      c.clipPath(m);
      c.drawOval(Rect.fromCenter(center: Offset(500, r.bottom), width: w * 1.2, height: h), solid(tongue));
      c.restore();
      c.drawPath(m, outline(7));
    } else {
      final p = Path()
        ..moveTo(500, 476)
        ..lineTo(500, 496)
        ..moveTo(452, 494)
        ..quadraticBezierTo(476, 520, 500, 496)
        ..quadraticBezierTo(524, 520, 548, 494);
      c.drawPath(p, outline(7));
    }
  }

  @override
  List<(BodyPart, Path)> get hitRegions => [
        (BodyPart.nose, ovalPath(const Offset(500, 445), 50, 38)),
        (BodyPart.eyes, ovalPath(eyeL, 58, 64)..addOval(Rect.fromCenter(center: eyeR, width: 116, height: 128))),
        (BodyPart.ears, unionOf([_ear(true, 0), _ear(false, 0)])),
        (BodyPart.cheeks, ovalPath(const Offset(500, 490), 115, 70)),
        (BodyPart.head, _head),
        (BodyPart.paws, unionOf([ovalPath(const Offset(440, 900), 70, 55), ovalPath(const Offset(560, 900), 70, 55),
          ovalPath(const Offset(370, 915), 75, 40), ovalPath(const Offset(630, 915), 75, 40)])),
        (BodyPart.tail, circlesAlong(const [Offset(680, 850), Offset(720, 760), Offset(710, 680), Offset(700, 620)], 55)),
        (BodyPart.belly, _body),
      ];
}
