import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/pets.dart';

/// Things the pets can wear (unlocked by the gift / rewarded ad).
enum Accessory { none, partyHat, crown, bow, glasses }

/// Everything that animates on a pet, in one immutable snapshot.
class PetPose {
  const PetPose({
    this.breath = 0,
    this.blink = 0,
    this.mouth = 0,
    this.mood = Mood.neutral,
    this.lookX = 0,
    this.lookY = 0,
    this.tilt = 0,
    this.bodyDy = 0,
    this.squash = 1,
    this.lean = 0,
    this.tail = 0,
    this.wing = 0,
    this.puff = 0,
    this.crest = 0,
    this.accessory = Accessory.none,
  });

  /// 0..1, slow breathing cycle.
  final double breath;

  /// 0 = open, 1 = closed.
  final double blink;

  /// 0..1 mouth / beak opening.
  final double mouth;
  final Mood mood;

  /// -1..1 where the eyes look.
  final double lookX, lookY;

  /// Head rotation (radians).
  final double tilt;

  /// Vertical body offset in canvas units (negative = up).
  final double bodyDy;

  /// 1 = normal, < 1 squashed, > 1 stretched.
  final double squash;

  /// Whole-body rotation (radians) around the feet.
  final double lean;

  /// -1..1 tail swing.
  final double tail;

  /// 0..1 wings raised (or a paw lifted).
  final double wing;

  /// 0..1 fur/feathers puffed.
  final double puff;

  /// 0..1 crest/comb raised.
  final double crest;
  final Accessory accessory;
}

/// Toon palette helpers.
const ink = Color(0xFF3A2618);
const eyeInk = Color(0xFF2A1A10);
const blushPink = Color(0xFFFF7FA0);

Color lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;

Paint outline(double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = ink;

Paint solid(Color c) => Paint()..color = c;

/// Fills [path] with a soft top-lit gradient and a toon outline.
void blob(Canvas c, Path path, Color color, {double line = 9, double shade = 0.14, bool stroke = true}) {
  final b = path.getBounds();
  c.drawPath(
    path,
    Paint()
      ..shader = ui.Gradient.linear(
        b.topCenter,
        b.bottomCenter,
        [lighten(color, shade), color, darken(color, shade * 0.8)],
        [0, 0.55, 1],
      ),
  );
  if (stroke) c.drawPath(path, outline(line));
}

void oval(Canvas c, Offset center, double rx, double ry, Color color, {double line = 9, double shade = 0.14, bool stroke = true}) {
  blob(c, Path()..addOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2)), color,
      line: line, shade: shade, stroke: stroke);
}

/// Thick outlined stroke (tails, legs, whiskers).
void tube(Canvas c, Path path, double width, Color color, {double line = 9}) {
  c.drawPath(path, outline(width + line * 2));
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );
}

void glint(Canvas c, Offset center, double r, [double alpha = 0.9]) {
  c.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: alpha));
}

void blush(Canvas c, Offset center, double rx, double ry, [double alpha = 0.45]) {
  c.drawOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()..color = blushPink.withValues(alpha: alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
}

Path heartPath(Offset center, double size) {
  final s = size;
  final x = center.dx, y = center.dy;
  return Path()
    ..moveTo(x, y + s * 0.35)
    ..cubicTo(x - s * 1.1, y - s * 0.35, x - s * 0.45, y - s * 1.05, x, y - s * 0.4)
    ..cubicTo(x + s * 0.45, y - s * 1.05, x + s * 1.1, y - s * 0.35, x, y + s * 0.35)
    ..close();
}

Path starPath(Offset center, double r, {int points = 5, double inner = 0.45}) {
  final p = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = -math.pi / 2 + i * math.pi / points;
    final rr = i.isEven ? r : r * inner;
    final pt = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Draws one eye according to the mood. [skin] colours the eyelids.
void drawEye(Canvas c, Offset center, double rx, double ry, PetPose pose, {required bool left, required Color skin}) {
  final lw = rx * 0.2;
  final look = Offset(pose.lookX * rx * 0.18, pose.lookY * ry * 0.15);
  switch (pose.mood) {
    case Mood.happy || Mood.laugh:
      final p = Path()
        ..moveTo(center.dx - rx * 0.85, center.dy + ry * 0.2)
        ..quadraticBezierTo(center.dx, center.dy - ry * 0.95, center.dx + rx * 0.85, center.dy + ry * 0.2);
      c.drawPath(p, outline(lw * 1.4)..color = eyeInk);
      return;
    case Mood.love:
      final h = heartPath(center + const Offset(0, 6), rx * 0.95);
      c.drawPath(h, solid(const Color(0xFFFF4F7B)));
      c.drawPath(h, outline(lw * 0.7));
      glint(c, center + Offset(-rx * 0.35, -ry * 0.3), rx * 0.18);
      return;
    case Mood.dizzy:
      final p = Path();
      for (var i = 0; i <= 60; i++) {
        final t = i / 60;
        final a = t * math.pi * 5 * (left ? 1 : -1);
        final r = rx * 0.9 * t;
        final pt = center + Offset(math.cos(a) * r, math.sin(a) * r * ry / rx);
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      c.drawPath(p, outline(lw)..color = eyeInk);
      return;
    case Mood.surprised:
      final r = Rect.fromCenter(center: center, width: rx * 2.3, height: ry * 2.3);
      c.drawOval(r, solid(Colors.white));
      c.drawOval(r, outline(lw * 0.8));
      c.drawCircle(center + look, rx * 0.45, solid(eyeInk));
      glint(c, center + look + Offset(rx * 0.15, -rx * 0.18), rx * 0.14);
      return;
    default:
  }

  // Open eye: big shiny dark oval, closed by [blink] and by the mood's lids.
  final sleepy = pose.mood == Mood.sleepy;
  final closed = sleepy ? math.max(pose.blink, 0.62) : pose.blink;
  if (closed > 0.92) {
    final p = Path()
      ..moveTo(center.dx - rx * 0.9, center.dy)
      ..quadraticBezierTo(center.dx, center.dy + ry * 0.45, center.dx + rx * 0.9, center.dy);
    c.drawPath(p, outline(lw * 1.2)..color = eyeInk);
    return;
  }
  final eye = Rect.fromCenter(center: center + look, width: rx * 2, height: ry * 2);
  c.save();
  c.clipPath(Path()..addOval(eye.inflate(1)));
  c.drawOval(eye, Paint()..shader = ui.Gradient.radial(eye.center, ry, [const Color(0xFF4A3020), eyeInk], [0, 1]));
  glint(c, eye.center + Offset(rx * 0.3, -ry * 0.35), rx * 0.34);
  glint(c, eye.center + Offset(-rx * 0.35, ry * 0.4), rx * 0.14, 0.7);
  if (pose.mood == Mood.listening) glint(c, eye.center + Offset(-rx * 0.1, -ry * 0.5), rx * 0.12);
  // Eyelid coming down from the top.
  if (closed > 0.01) {
    final lidY = center.dy - ry * 1.15 + ry * 2.3 * closed;
    final lid = Rect.fromLTRB(center.dx - rx * 1.2, center.dy - ry * 1.3, center.dx + rx * 1.2, lidY);
    c.drawRect(lid, solid(skin));
    c.drawLine(Offset(lid.left, lidY), Offset(lid.right, lidY), outline(lw));
  }
  if (pose.mood == Mood.grumpy) {
    // Silly cross lid slanting down to the middle.
    final inner = left ? 1.0 : -1.0;
    final lid = Path()
      ..moveTo(center.dx - rx * 1.3, center.dy - ry * 1.3)
      ..lineTo(center.dx + rx * 1.3, center.dy - ry * 1.3)
      ..lineTo(center.dx + rx * 1.3, center.dy - ry * (inner > 0 ? 0.05 : 0.75))
      ..lineTo(center.dx - rx * 1.3, center.dy - ry * (inner > 0 ? 0.75 : 0.05))
      ..close();
    c.drawPath(lid, solid(skin));
    c.drawLine(Offset(center.dx - rx * 1.1, center.dy - ry * (inner > 0 ? 0.7 : 0.1)),
        Offset(center.dx + rx * 1.1, center.dy - ry * (inner > 0 ? 0.1 : 0.7)), outline(lw * 1.1));
  }
  c.restore();
}

/// Where a pet's accessories go.
class HeadAnchors {
  const HeadAnchors({required this.top, required this.eyeLeft, required this.eyeRight, required this.eyeRadius, required this.width});

  /// Top centre of the head, where hats sit.
  final Offset top;
  final Offset eyeLeft, eyeRight;
  final double eyeRadius;

  /// Head width.
  final double width;
}

void drawAccessory(Canvas c, Accessory a, HeadAnchors h) {
  switch (a) {
    case Accessory.none:
      return;
    case Accessory.partyHat:
      final base = h.top + const Offset(20, 30);
      final hat = Path()
        ..moveTo(base.dx - 85, base.dy)
        ..lineTo(base.dx + 30, base.dy - 190)
        ..lineTo(base.dx + 85, base.dy + 10)
        ..close();
      c.save();
      c.clipPath(hat);
      c.drawPath(hat, solid(const Color(0xFF7C5CFF)));
      for (var i = -3; i < 6; i++) {
        final y = base.dy - 190 + i * 45.0;
        c.drawLine(Offset(base.dx - 120, y + 60), Offset(base.dx + 120, y - 20), Paint()..color = const Color(0xFFFFD84D)..strokeWidth = 16);
      }
      c.restore();
      c.drawPath(hat, outline(8));
      c.drawCircle(Offset(base.dx + 30, base.dy - 195), 26, solid(const Color(0xFFFF5A8A)));
      c.drawCircle(Offset(base.dx + 30, base.dy - 195), 26, outline(7));
    case Accessory.crown:
      final b = h.top + const Offset(0, 20);
      final w = 105.0;
      final crown = Path()
        ..moveTo(b.dx - w, b.dy)
        ..lineTo(b.dx - w - 10, b.dy - 95)
        ..lineTo(b.dx - w / 2, b.dy - 45)
        ..lineTo(b.dx, b.dy - 120)
        ..lineTo(b.dx + w / 2, b.dy - 45)
        ..lineTo(b.dx + w + 10, b.dy - 95)
        ..lineTo(b.dx + w, b.dy)
        ..close();
      blob(c, crown, const Color(0xFFFFC928), line: 8, shade: 0.25);
      for (final (dx, col) in [(-55.0, const Color(0xFFFF4F6D)), (0.0, const Color(0xFF3EA8FF)), (55.0, const Color(0xFF3EDC8A))]) {
        c.drawCircle(Offset(b.dx + dx, b.dy - 25), 13, solid(col));
        c.drawCircle(Offset(b.dx + dx, b.dy - 25), 13, outline(5));
      }
    case Accessory.bow:
      final b = h.top + Offset(h.width * 0.28, 25);
      Path wing(double dir) => Path()
        ..moveTo(b.dx, b.dy)
        ..cubicTo(b.dx + dir * 40, b.dy - 90, b.dx + dir * 120, b.dy - 60, b.dx + dir * 110, b.dy)
        ..cubicTo(b.dx + dir * 120, b.dy + 60, b.dx + dir * 40, b.dy + 90, b.dx, b.dy)
        ..close();
      blob(c, wing(-1), const Color(0xFFFF5A9A), line: 8);
      blob(c, wing(1), const Color(0xFFFF5A9A), line: 8);
      oval(c, b, 26, 30, const Color(0xFFFF3D7F), line: 7);
    case Accessory.glasses:
      final r = h.eyeRadius * 1.35;
      for (final e in [h.eyeLeft, h.eyeRight]) {
        c.drawCircle(e, r, Paint()..color = const Color(0x5542C8FF));
        c.drawCircle(e, r, outline(12)..color = const Color(0xFFFF3D5A));
        glint(c, e + Offset(-r * 0.4, -r * 0.45), r * 0.18, 0.8);
      }
      c.drawLine(h.eyeLeft + Offset(r, -r * 0.2), h.eyeRight - Offset(r, r * 0.2), outline(12)..color = const Color(0xFFFF3D5A));
  }
}

/// Base class: applies the body animation, then lets the pet draw itself.
abstract class PetPainter extends CustomPainter {
  PetPainter(this.pose);

  final PetPose pose;

  /// Ground contact point in canvas units (pivot for squash and lean).
  Offset get feet => const Offset(500, 935);

  HeadAnchors get anchors;

  /// Draws the pet on a 1000x1000 canvas.
  void draw(Canvas c);

  /// Touch regions in priority order (small parts first), in rest pose.
  List<(BodyPart, Path)> get hitRegions;

  static double scaleFor(Size size) => math.min(size.width, size.height) / 1000;

  static Offset toCanvas(Offset local, Size size) {
    final s = scaleFor(size);
    final ox = (size.width - 1000 * s) / 2, oy = (size.height - 1000 * s) / 2;
    return Offset((local.dx - ox) / s, (local.dy - oy) / s);
  }

  BodyPart? hitTestPart(Offset local, Size size) {
    final p = toCanvas(local, size);
    for (final (part, path) in hitRegions) {
      if (path.contains(p)) return part;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = scaleFor(size);
    canvas.save();
    canvas.translate((size.width - 1000 * s) / 2, (size.height - 1000 * s) / 2);
    canvas.scale(s);
    // Ground shadow shrinks when the pet jumps.
    final lift = (-pose.bodyDy).clamp(0, 200) / 200;
    canvas.drawOval(
      Rect.fromCenter(center: feet + const Offset(0, 8), width: 420 * (1 - lift * 0.4), height: 60 * (1 - lift * 0.4)),
      Paint()..color = Colors.black.withValues(alpha: 0.16 * (1 - lift * 0.5))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final breath = 1 + 0.018 * math.sin(pose.breath * 2 * math.pi);
    final sy = pose.squash * breath;
    final sx = 1 / math.sqrt(pose.squash) / math.sqrt(breath);
    canvas.translate(feet.dx, feet.dy + pose.bodyDy);
    canvas.rotate(pose.lean);
    canvas.scale(sx, sy);
    canvas.translate(-feet.dx, -feet.dy);
    draw(canvas);
    canvas.restore();
  }

  /// Rotates the head around [neck] by the pose's tilt while [body] runs.
  void withHead(Canvas c, Offset neck, void Function() body) {
    c.save();
    c.translate(neck.dx, neck.dy);
    c.rotate(pose.tilt);
    c.translate(-neck.dx, -neck.dy);
    body();
    c.restore();
  }

  @override
  bool shouldRepaint(covariant PetPainter old) => true;
}

Path ovalPath(Offset c, double rx, double ry) => Path()..addOval(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2));

/// Union of shapes (safe for hit testing, whatever each path's winding).
Path unionOf(List<Path> parts) => parts.reduce((a, b) => Path.combine(PathOperation.union, a, b));

Path circlesAlong(List<Offset> pts, double r) {
  final p = Path();
  for (final o in pts) {
    p.addOval(Rect.fromCircle(center: o, radius: r));
  }
  return p;
}
