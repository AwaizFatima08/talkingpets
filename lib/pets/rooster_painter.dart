import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

/// Doodle: a plump farmyard rooster with a big red comb and a shiny tail.
class RoosterPainter extends PetPainter {
  RoosterPainter(super.pose);

  static const feathers = Color(0xFFFFF7E8);
  static const hackle = Color(0xFFFFA23A);
  static const wingCol = Color(0xFFE0823A);
  static const comb = Color(0xFFFF4040);
  static const beak = Color(0xFFFFC233);
  static const legs = Color(0xFFFFB21F);
  static const teal = Color(0xFF1FA383);
  static const bottle = Color(0xFF19675A);
  static const rust = Color(0xFFC84A2E);

  static const eyeL = Offset(447, 345), eyeR = Offset(553, 345);
  static const neck = Offset(500, 540);

  @override
  HeadAnchors get anchors => const HeadAnchors(top: Offset(500, 185), eyeLeft: eyeL, eyeRight: eyeR, eyeRadius: 38, width: 300);

  static final Path _body = Path()..addOval(Rect.fromCenter(center: const Offset(500, 690), width: 410, height: 370));

  static Path _wing(bool left) {
    final d = left ? -1.0 : 1.0;
    return Path()
      ..moveTo(500 + d * 120, 585)
      ..cubicTo(500 + d * 215, 575, 500 + d * 250, 690, 500 + d * 225, 790)
      ..cubicTo(500 + d * 205, 830, 500 + d * 150, 825, 500 + d * 120, 780)
      ..cubicTo(500 + d * 95, 720, 500 + d * 95, 620, 500 + d * 120, 585)
      ..close();
  }

  static List<(Path, Color, double)> _tail() => [
        (
          Path()
            ..moveTo(600, 650)
            ..cubicTo(690, 560, 720, 380, 800, 330)
            ..cubicTo(850, 300, 885, 340, 870, 390),
          rust,
          46.0
        ),
        (
          Path()
            ..moveTo(610, 665)
            ..cubicTo(720, 600, 790, 450, 880, 440)
            ..cubicTo(930, 436, 945, 480, 915, 515),
          teal,
          50.0
        ),
        (
          Path()
            ..moveTo(615, 690)
            ..cubicTo(730, 660, 820, 590, 890, 610)
            ..cubicTo(935, 625, 930, 670, 895, 680),
          bottle,
          44.0
        ),
      ];

  static final Path _comb = Path.combine(
    PathOperation.union,
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(432, 250), radius: 40))
      ..addOval(Rect.fromCircle(center: const Offset(474, 215), radius: 48)),
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(526, 208), radius: 50))
      ..addOval(Rect.fromCircle(center: const Offset(572, 240), radius: 42))
      ..addRect(const Rect.fromLTRB(430, 225, 575, 275)),
  );

  static final Path _hackle = unionOf([
    for (var i = 0; i <= 6; i++)
      Path()..addOval(Rect.fromCircle(center: Offset(372 + i * 42.7, 520 + 18 * math.sin(i / 6 * math.pi)), radius: 46)),
  ]);

  @override
  void draw(Canvas c) {
    // Tail fan behind the body.
    c.save();
    c.translate(605, 660);
    c.rotate(pose.tail * 0.18 - pose.puff * 0.1);
    c.translate(-605, -660);
    for (final (path, color, w) in _tail()) {
      tube(c, path, w * (1 + 0.3 * pose.puff), color);
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.18
        ..strokeCap = StrokeCap.round
        ..color = lighten(color, 0.35).withValues(alpha: 0.6));
    }
    c.restore();

    // Legs and toes.
    for (final x in [455.0, 545.0]) {
      tube(c, Path()..moveTo(x, 840)..lineTo(x, 925), 22, legs, line: 7);
      for (final dx in [-42.0, 0.0, 42.0]) {
        tube(c, Path()..moveTo(x, 925)..lineTo(x + dx, 940), 18, legs, line: 7);
      }
    }

    blob(c, _body, feathers, shade: 0.1);
    final fluff = outline(5)..color = darken(feathers, 0.16);
    for (final (x, y) in [(460.0, 760.0), (540.0, 760.0), (500.0, 810.0), (420.0, 700.0), (580.0, 700.0)]) {
      c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 50, height: 32), 0.3, math.pi - 0.6, false, fluff);
    }

    for (final left in [true, false]) {
      final shoulder = Offset(left ? 385 : 615, 600);
      c.save();
      c.translate(shoulder.dx, shoulder.dy);
      c.rotate((left ? 1 : -1) * pose.wing * 1.1);
      c.translate(-shoulder.dx, -shoulder.dy);
      final w = _wing(left);
      blob(c, w, wingCol);
      final d = left ? -1.0 : 1.0;
      for (final f in [0.0, 1.0, 2.0]) {
        c.drawArc(Rect.fromCenter(center: Offset(500 + d * (150 + f * 22), 740 + f * 22), width: 60, height: 40), 0.2, math.pi - 0.4, false,
            outline(5)..color = darken(wingCol, 0.25));
      }
      c.restore();
    }

    // Orange neck feathers.
    blob(c, _hackle, hackle, line: 8);

    withHead(c, neck, () {
      c.save();
      final s = 1 + 0.3 * pose.crest;
      c.translate(500, 270);
      c.scale(s, s);
      c.translate(-500, -270);
      blob(c, _comb, comb, line: 8, shade: 0.2);
      c.restore();

      oval(c, const Offset(500, 365), 150, 148, feathers, shade: 0.08);
      drawEye(c, eyeL, 36, 44, pose, left: true, skin: feathers);
      drawEye(c, eyeR, 36, 44, pose, left: false, skin: feathers);
      blush(c, const Offset(405, 418), 34, 20);
      blush(c, const Offset(595, 418), 34, 20);

      // Wattle wobbles with the lean.
      final wob = Offset(pose.lean * 120, 0);
      oval(c, const Offset(484, 482) + wob, 22, 36, comb, line: 7);
      oval(c, const Offset(516, 482) + wob, 22, 36, comb, line: 7);
      _beak(c);
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  void _beak(Canvas c) {
    final open = switch (pose.mood) {
      Mood.laugh => math.max(pose.mouth, 0.7),
      Mood.surprised => math.max(pose.mouth, 0.45),
      _ => pose.mouth,
    };
    final drop = open * 58;
    if (open > 0.05) {
      final inside = Path()
        ..moveTo(466, 410)
        ..lineTo(534, 410)
        ..lineTo(500, 430 + drop)
        ..close();
      c.drawPath(inside, solid(const Color(0xFF7A2430)));
      final lower = Path()
        ..moveTo(472, 418 + drop * 0.6)
        ..lineTo(528, 418 + drop * 0.6)
        ..lineTo(500, 452 + drop)
        ..close();
      blob(c, lower, darken(beak, 0.08), line: 7);
    }
    final upper = Path()
      ..moveTo(458, 398)
      ..quadraticBezierTo(500, 380, 542, 398)
      ..quadraticBezierTo(530, 430, 500, 452 - open * 8)
      ..quadraticBezierTo(470, 430, 458, 398)
      ..close();
    blob(c, upper, beak, line: 8, shade: 0.2);
    c.drawCircle(const Offset(484, 400), 4.5, solid(ink));
    c.drawCircle(const Offset(516, 400), 4.5, solid(ink));
  }

  @override
  List<(BodyPart, Path)> get hitRegions => [
        (BodyPart.beak, ovalPath(const Offset(500, 418), 48, 42)),
        (BodyPart.wattle, ovalPath(const Offset(500, 488), 52, 44)),
        (BodyPart.eyes, ovalPath(eyeL, 52, 56)..addOval(Rect.fromCenter(center: eyeR, width: 104, height: 112))),
        (BodyPart.comb, ovalPath(const Offset(502, 230), 120, 70)),
        (BodyPart.head, ovalPath(const Offset(500, 365), 158, 156)),
        (BodyPart.feet, Path()..addRect(const Rect.fromLTRB(395, 855, 605, 960))),
        (BodyPart.wings, unionOf([_wing(true), _wing(false)])),
        (BodyPart.tail, circlesAlong(const [Offset(700, 560), Offset(770, 420), Offset(850, 340), Offset(880, 450), Offset(900, 520), Offset(860, 610), Offset(920, 650), Offset(760, 630)], 55)),
        (BodyPart.belly, unionOf([_body, _hackle])),
      ];
}
