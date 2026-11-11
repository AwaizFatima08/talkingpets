import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

/// Peanut: a chubby baby elephant with big flappy ears and a curly trunk.
class ElephantPainter extends PetPainter {
  ElephantPainter(super.pose);

  static const skin = Color(0xFF9DB3C8);
  static const skinDark = Color(0xFF7D93AA);
  static const earInner = Color(0xFFF6B8C6);
  static const nail = Color(0xFFFFF4E4);

  static const eyeL = Offset(440, 345), eyeR = Offset(560, 345);
  static const neck = Offset(500, 545);

  @override
  HeadAnchors get anchors => const HeadAnchors(top: Offset(500, 196), eyeLeft: eyeL, eyeRight: eyeR, eyeRadius: 40, width: 340);

  static final Path _body = Path()..addOval(Rect.fromCenter(center: const Offset(500, 700), width: 430, height: 400));

  /// Big ear; [flap] swings it outwards.
  Path _ear(bool left) {
    final d = left ? -1.0 : 1.0;
    final spread = 1 + 0.35 * pose.wing;
    final cx = 500 + d * (165 + 40 * pose.wing);
    return Path()..addOval(Rect.fromCenter(center: Offset(cx, 380), width: 270 * spread, height: 330));
  }

  /// Trunk from the face down and curled up; [crest] raises it to trumpet.
  Path _trunk() {
    final up = pose.crest;
    final end = Offset.lerp(const Offset(590, 610), const Offset(600, 210), up)!;
    final c1 = Offset.lerp(const Offset(490, 520), const Offset(520, 390), up)!;
    final c2 = Offset.lerp(const Offset(520, 640), const Offset(640, 300), up)!;
    return Path()
      ..moveTo(500, 420)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  @override
  void draw(Canvas c) {
    // Tail with a little tuft.
    final wag = pose.tail * 0.4;
    final tip = Offset(745 + 30 * math.sin(wag), 790);
    tube(c, Path()..moveTo(690, 700)..quadraticBezierTo(740, 720, tip.dx, tip.dy), 14, skinDark, line: 7);
    oval(c, tip + const Offset(0, 14), 14, 22, darken(skinDark, 0.3), line: 6);

    blob(c, _body, skin, shade: 0.12);
    oval(c, const Offset(500, 760), 120, 125, lighten(skin, 0.25), stroke: false, shade: 0.04);
    for (final x in [400.0, 600.0]) {
      final leg = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 880), width: 120, height: 120), const Radius.circular(40));
      final p = Path()..addRRect(leg);
      blob(c, p, skin);
      for (final dx in [-30.0, 0.0, 30.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, 925), width: 24, height: 16), solid(nail));
      }
    }

    withHead(c, neck, () {
      for (final left in [true, false]) {
        final e = _ear(left);
        blob(c, e, skin, shade: 0.1);
        final b = e.getBounds();
        c.drawOval(b.deflate(38), solid(earInner.withValues(alpha: 0.85)));
      }
      oval(c, const Offset(500, 360), 165, 160, skin, shade: 0.1);
      drawEye(c, eyeL, 38, 46, pose, left: true, skin: skin);
      drawEye(c, eyeR, 38, 46, pose, left: false, skin: skin);
      blush(c, const Offset(400, 420), 34, 20);
      blush(c, const Offset(600, 420), 34, 20);
      _mouth(c);
      tube(c, _trunk(), 64 - 10 * pose.crest, skin);
      final t = _trunk().computeMetrics().first;
      for (final f in [0.35, 0.55, 0.75]) {
        final tan = t.getTangentForOffset(t.length * f)!;
        final n = Offset(-tan.vector.dy, tan.vector.dx) * 26;
        c.drawLine(tan.position - n, tan.position + n, outline(5)..color = skinDark);
      }
      final end = t.getTangentForOffset(t.length)!.position;
      c.drawOval(Rect.fromCenter(center: end, width: 44, height: 30), solid(darken(skinDark, 0.2)));
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  void _mouth(Canvas c) {
    final open = switch (pose.mood) {
      Mood.laugh => math.max(pose.mouth, 0.75),
      Mood.surprised => math.max(pose.mouth, 0.4),
      _ => pose.mouth,
    };
    if (open > 0.06) {
      final r = Rect.fromCenter(center: Offset(500, 478 + 20 * open), width: 150, height: 30 + 70 * open);
      c.drawOval(r, solid(const Color(0xFF8A2A35)));
      c.drawOval(Rect.fromCenter(center: Offset(500, r.bottom - 14), width: 80, height: 24), solid(const Color(0xFFFF7D92)));
      c.drawOval(r, outline(7));
    } else {
      final p = Path()
        ..moveTo(430, 470)
        ..quadraticBezierTo(500, 520, 570, 470);
      c.drawPath(p, outline(7));
    }
  }

  @override
  List<(BodyPart, Path)> get hitRegions {
    final t = _trunk().computeMetrics().first;
    final pts = [for (var i = 0; i <= 8; i++) t.getTangentForOffset(t.length * i / 8)!.position];
    return [
      (BodyPart.trunk, circlesAlong(pts, 48)),
      (BodyPart.eyes, ovalPath(eyeL, 54, 58)..addOval(Rect.fromCenter(center: eyeR, width: 108, height: 116))),
      (BodyPart.head, ovalPath(const Offset(500, 360), 170, 165)),
      (BodyPart.ears, unionOf([_ear(true), _ear(false)])),
      (BodyPart.feet, unionOf([ovalPath(const Offset(400, 885), 75, 70), ovalPath(const Offset(600, 885), 75, 70)])),
      (BodyPart.tail, circlesAlong(const [Offset(720, 720), Offset(745, 780)], 45)),
      (BodyPart.belly, _body),
    ];
  }
}
