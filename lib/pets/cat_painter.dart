import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

/// Mimi: a chubby orange tabby, sitting and facing the child.
class CatPainter extends PetPainter {
  CatPainter(super.pose, {this.headOnly = false});

  /// Skips the tail (launcher icons).
  final bool headOnly;

  static const fur = Color(0xFFFFA64D);
  static const furDark = Color(0xFFE7812F);
  static const cream = Color(0xFFFFF0DA);
  static const pink = Color(0xFFFF93A8);

  static const eyeL = Offset(412, 388), eyeR = Offset(588, 388);
  static const neck = Offset(500, 570);

  @override
  HeadAnchors get anchors => const HeadAnchors(top: Offset(500, 200), eyeLeft: eyeL, eyeRight: eyeR, eyeRadius: 52, width: 480);

  static final Path _head = Path()
    ..moveTo(500, 188)
    ..cubicTo(645, 188, 735, 262, 742, 372)
    ..cubicTo(746, 415, 775, 435, 766, 462)
    ..cubicTo(752, 482, 752, 500, 724, 522)
    ..cubicTo(672, 578, 592, 594, 500, 594)
    ..cubicTo(408, 594, 328, 578, 276, 522)
    ..cubicTo(248, 500, 248, 482, 234, 462)
    ..cubicTo(225, 435, 254, 415, 258, 372)
    ..cubicTo(265, 262, 355, 188, 500, 188)
    ..close();

  static final Path _body = Path()
    ..moveTo(500, 548)
    ..cubicTo(610, 548, 692, 690, 694, 818)
    ..cubicTo(696, 900, 622, 938, 500, 938)
    ..cubicTo(378, 938, 304, 900, 306, 818)
    ..cubicTo(308, 690, 390, 548, 500, 548)
    ..close();

  static Path _ear(bool left) {
    final d = left ? -1.0 : 1.0;
    return Path()
      ..moveTo(500 + d * 225, 345)
      ..quadraticBezierTo(500 + d * 222, 215, 500 + d * 205, 150)
      ..quadraticBezierTo(500 + d * 198, 128, 500 + d * 178, 140)
      ..quadraticBezierTo(500 + d * 120, 170, 500 + d * 70, 205)
      ..close();
  }

  static Path _innerEar(bool left) {
    final d = left ? -1.0 : 1.0;
    return Path()
      ..moveTo(500 + d * 200, 300)
      ..quadraticBezierTo(500 + d * 198, 225, 500 + d * 190, 180)
      ..quadraticBezierTo(500 + d * 140, 205, 500 + d * 105, 225)
      ..close();
  }

  Path _tail() {
    final wag = pose.tail * 0.35;
    final tip = Offset(860 + 60 * math.sin(wag), 600 - 40 * math.cos(wag) + 40);
    return Path()
      ..moveTo(640, 895)
      ..cubicTo(800, 905, 870, 800, 830, 710)
      ..cubicTo(805, 650, tip.dx - 30, tip.dy + 10, tip.dx, tip.dy);
  }

  @override
  void draw(Canvas c) {
    // Tail behind the body.
    final tailW = 58 + 40 * pose.puff;
    if (!headOnly) _drawTail(c, tailW);
    _drawBody(c);
    _drawHead(c);
  }

  void _drawTail(Canvas c, double tailW) {
    tube(c, _tail(), tailW, fur);
    final t = _tail().computeMetrics().first;
    final tipPos = t.getTangentForOffset(t.length)!.position;
    c.drawCircle(tipPos, tailW * 0.52, solid(furDark));
    for (final f in [0.45, 0.62, 0.8]) {
      final tan = t.getTangentForOffset(t.length * f)!;
      final n = Offset(-tan.vector.dy, tan.vector.dx) * (tailW * 0.45);
      c.drawLine(tan.position - n, tan.position + n, outline(12)..color = furDark);
    }
  }

  void _drawBody(Canvas c) {
    // Body, belly and feet.
    blob(c, _body, fur);
    oval(c, const Offset(500, 810), 112, 118, cream, stroke: false, shade: 0.06);
    for (final (x, y) in [(385.0, 915.0), (615.0, 915.0)]) {
      oval(c, Offset(x, y), 70, 36, fur);
    }
    // Front paws; the right one waves when [wing] is up.
    oval(c, const Offset(440, 905), 50, 38, cream);
    final raise = pose.wing;
    final paw = Offset.lerp(const Offset(560, 905), const Offset(650, 700), raise)!;
    if (raise > 0.05) {
      tube(c, Path()..moveTo(575, 760)..lineTo(paw.dx, paw.dy + 20), 70, fur);
    }
    oval(c, paw, 50, 38, cream);
    for (final p in [const Offset(440, 905), paw]) {
      for (final dx in [-16.0, 16.0]) {
        c.drawLine(p + Offset(dx, 10), p + Offset(dx, 30), outline(6));
      }
    }
  }

  void _drawHead(Canvas c) {
    withHead(c, neck, () {
      // Ears wiggle a little with the tilt.
      for (final left in [true, false]) {
        blob(c, _ear(left), fur);
        c.drawPath(_innerEar(left), solid(pink));
      }
      blob(c, _head, fur, shade: 0.12);
      // Tabby stripes on the forehead.
      for (final (x, w, h) in [(500.0, 22.0, 70.0), (452.0, 16.0, 48.0), (548.0, 16.0, 48.0)]) {
        final s = Path()
          ..moveTo(x - w, 196)
          ..quadraticBezierTo(x, 196 + h * 1.4, x + w, 196)
          ..close();
        c.drawPath(s, solid(furDark));
      }
      for (final d in [-1.0, 1.0]) {
        c.drawLine(Offset(500 + d * 235, 405), Offset(500 + d * 205, 412), outline(10)..color = furDark);
        c.drawLine(Offset(500 + d * 240, 440), Offset(500 + d * 210, 440), outline(10)..color = furDark);
      }

      drawEye(c, eyeL, 52, 64, pose, left: true, skin: fur);
      drawEye(c, eyeR, 52, 64, pose, left: false, skin: fur);
      blush(c, const Offset(352, 480), 38, 22);
      blush(c, const Offset(648, 480), 38, 22);

      // Muzzle.
      oval(c, const Offset(462, 478), 56, 44, cream, stroke: false, shade: 0.04);
      oval(c, const Offset(538, 478), 56, 44, cream, stroke: false, shade: 0.04);
      _mouth(c);
      // Nose.
      final nose = Path()
        ..moveTo(476, 440)
        ..quadraticBezierTo(500, 432, 524, 440)
        ..quadraticBezierTo(520, 460, 500, 466)
        ..quadraticBezierTo(480, 460, 476, 440)
        ..close();
      blob(c, nose, pink, line: 6);
      glint(c, const Offset(490, 443), 5);

      // Whiskers.
      final w = outline(5)..color = ink.withValues(alpha: 0.8);
      for (final d in [-1.0, 1.0]) {
        c.drawLine(Offset(500 + d * 105, 470), Offset(500 + d * 215, 452), w);
        c.drawLine(Offset(500 + d * 108, 486), Offset(500 + d * 220, 492), w);
      }
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  void _mouth(Canvas c) {
    final open = switch (pose.mood) {
      Mood.laugh => math.max(pose.mouth, 0.75),
      Mood.surprised => math.max(pose.mouth, 0.35),
      Mood.grumpy => math.max(pose.mouth, 0.5),
      _ => pose.mouth,
    };
    if (open > 0.06) {
      final h = 20 + 70 * open;
      final w = pose.mood == Mood.surprised ? 22 + 20 * open : 36 + 22 * open;
      final r = Rect.fromLTWH(500 - w, 470, w * 2, h);
      final m = pose.mood == Mood.laugh
          ? (Path()
            ..moveTo(r.left, r.top)
            ..quadraticBezierTo(500, r.top + 12, r.right, r.top)
            ..quadraticBezierTo(r.right, r.bottom, 500, r.bottom)
            ..quadraticBezierTo(r.left, r.bottom, r.left, r.top)
            ..close())
          : (Path()..addOval(r));
      c.drawPath(m, solid(const Color(0xFF8A2A35)));
      c.save();
      c.clipPath(m);
      c.drawOval(Rect.fromCenter(center: Offset(500, r.bottom), width: w * 1.3, height: h * 0.9), solid(const Color(0xFFFF7D92)));
      if (pose.mood == Mood.grumpy) {
        // Two tiny fangs.
        for (final d in [-1.0, 1.0]) {
          final f = Path()
            ..moveTo(500 + d * (w * 0.55) - 8, r.top)
            ..lineTo(500 + d * (w * 0.55) + 8, r.top)
            ..lineTo(500 + d * (w * 0.55), r.top + 18)
            ..close();
          c.drawPath(f, solid(Colors.white));
        }
      }
      c.restore();
      c.drawPath(m, outline(7));
    } else {
      // Little "w" mouth.
      final p = Path()
        ..moveTo(500, 462)
        ..lineTo(500, 478)
        ..moveTo(458, 478)
        ..quadraticBezierTo(478, 500, 500, 478)
        ..quadraticBezierTo(522, 500, 542, 478);
      c.drawPath(p, outline(7));
    }
  }

  @override
  List<(BodyPart, Path)> get hitRegions => [
        (BodyPart.nose, ovalPath(const Offset(500, 452), 42, 34)),
        (BodyPart.eyes, ovalPath(eyeL, 62, 70)..addOval(Rect.fromCenter(center: eyeR, width: 124, height: 140))),
        (BodyPart.cheeks, ovalPath(const Offset(330, 480), 62, 55)..addOval(Rect.fromCenter(center: const Offset(670, 480), width: 124, height: 110))),
        (BodyPart.ears, unionOf([_ear(true), _ear(false)])),
        (BodyPart.head, _head),
        (BodyPart.paws, ovalPath(const Offset(440, 900), 70, 55)..addOval(Rect.fromCenter(center: const Offset(560, 900), width: 140, height: 110))
          ..addOval(Rect.fromCenter(center: const Offset(370, 915), width: 150, height: 80))
          ..addOval(Rect.fromCenter(center: const Offset(630, 915), width: 150, height: 80))),
        (BodyPart.tail, circlesAlong(const [Offset(700, 890), Offset(790, 870), Offset(840, 790), Offset(830, 710), Offset(850, 640), Offset(870, 590)], 55)),
        (BodyPart.belly, _body),
      ];
}
