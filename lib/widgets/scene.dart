import 'dart:math' as math;
import 'dart:ui' as ui;


import 'package:flutter/material.dart';

import '../core/pets.dart';
import '../pets/toon.dart';

/// Each pet's home, drawn behind it. [t] is seconds, for drifting clouds.
/// [groundY] (0..1 of the height) is where the pet's feet stand.
class ScenePainter extends CustomPainter {
  ScenePainter(this.kind, this.t, {this.groundY = 0.74, this.image});

  /// A 3D scene picture; when set it replaces the drawn scene (cover fit).
  final ui.Image? image;

  final PetKind kind;
  final double t;
  final double groundY;

  @override
  void paint(Canvas c, Size s) {
    final img = image;
    if (img != null) {
      final src = Size(img.width.toDouble(), img.height.toDouble());
      final fit = applyBoxFit(BoxFit.cover, src, s);
      final srcRect = Alignment.center.inscribe(fit.source, Offset.zero & src);
      c.drawImageRect(img, srcRect, Offset.zero & s, Paint()..filterQuality = FilterQuality.medium);
      return;
    }
    switch (kind) {
      case PetKind.cat:
        _room(c, s);
      case PetKind.parrot:
        _jungle(c, s);
      case PetKind.rooster:
        _farm(c, s);
      case PetKind.puppy:
        _yard(c, s);
      case PetKind.elephant:
        _savanna(c, s);
    }
  }

  void _sky(Canvas c, Size s, Color top, Color bottom) {
    c.drawRect(Offset.zero & s, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), [top, bottom]));
  }

  void _cloud(Canvas c, Offset o, double r, [double alpha = 0.95]) {
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    c.drawCircle(o, r, p);
    c.drawCircle(o + Offset(r * 0.9, r * 0.2), r * 0.75, p);
    c.drawCircle(o + Offset(-r * 0.9, r * 0.25), r * 0.7, p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(o.dx - r * 1.5, o.dy, o.dx + r * 1.6, o.dy + r * 0.85), Radius.circular(r * 0.4)), p);
  }

  void _clouds(Canvas c, Size s, double y, double speed) {
    for (var i = 0; i < 3; i++) {
      final x = ((t * speed + i * s.width * 0.45) % (s.width * 1.4)) - s.width * 0.2;
      _cloud(c, Offset(x, y + i * 26.0 * (i.isEven ? 1 : -1)), 20 + i * 5.0);
    }
  }

  void _room(Canvas c, Size s) {
    final floor = s.height * groundY;
    _sky(c, s, const Color(0xFFFFE3C7), const Color(0xFFFFCFA8));
    // Wallpaper dots.
    final dot = Paint()..color = const Color(0x22FF8A5B);
    for (var y = 20.0; y < floor; y += 46) {
      for (var x = (y ~/ 46).isEven ? 10.0 : 33.0; x < s.width; x += 46) {
        c.drawCircle(Offset(x, y), 5, dot);
      }
    }
    // Window with sky.
    final win = Rect.fromLTWH(s.width * 0.08, s.height * 0.12, s.width * 0.34, s.height * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(8), const Radius.circular(18)), solid(const Color(0xFFFFFFFF)));
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(win, const Radius.circular(12)));
    _sky(c, s, const Color(0xFF8FD3FF), const Color(0xFFD2F0FF));
    _clouds(c, s, win.top + win.height * 0.4, 8);
    c.restore();
    c.drawLine(win.topCenter, win.bottomCenter, Paint()..color = Colors.white..strokeWidth = 6);
    c.drawLine(win.centerLeft, win.centerRight, Paint()..color = Colors.white..strokeWidth = 6);
    // Picture frame with a fish.
    final pic = Rect.fromLTWH(s.width * 0.64, s.height * 0.14, s.width * 0.24, s.height * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(pic.inflate(7), const Radius.circular(8)), solid(const Color(0xFFB9784A)));
    c.drawRect(pic, solid(const Color(0xFFE9F7FF)));
    final fish = Path()..addOval(Rect.fromCenter(center: pic.center, width: pic.width * 0.45, height: pic.height * 0.4));
    c.drawPath(fish, solid(const Color(0xFFFF9F43)));
    final tailP = Path()
      ..moveTo(pic.center.dx + pic.width * 0.2, pic.center.dy)
      ..lineTo(pic.center.dx + pic.width * 0.36, pic.center.dy - pic.height * 0.2)
      ..lineTo(pic.center.dx + pic.width * 0.36, pic.center.dy + pic.height * 0.2)
      ..close();
    c.drawPath(tailP, solid(const Color(0xFFFF9F43)));
    // Wooden floor and rug.
    c.drawRect(Rect.fromLTRB(0, floor - s.height * 0.08, s.width, s.height), solid(const Color(0xFFD99A62)));
    for (var i = 0; i < 6; i++) {
      final y = floor - s.height * 0.08 + i * s.height * 0.06;
      c.drawLine(Offset(0, y), Offset(s.width, y), Paint()..color = const Color(0x33000000)..strokeWidth = 2);
    }
    c.drawRect(Rect.fromLTRB(0, floor - s.height * 0.08 - 10, s.width, floor - s.height * 0.08), solid(const Color(0xFFB9784A)));
    final rug = Rect.fromCenter(center: Offset(s.width / 2, floor + 4), width: s.width * 0.86, height: s.height * 0.11);
    c.drawOval(rug, solid(const Color(0xFF8C7CFF)));
    c.drawOval(rug.deflate(12), Paint()..style = PaintingStyle.stroke..strokeWidth = 6..color = const Color(0xFFC6BEFF));
    // Yarn ball.
    final yarn = Offset(s.width * 0.86, floor + s.height * 0.07);
    c.drawCircle(yarn, 20, solid(const Color(0xFFFF6B9A)));
    c.drawArc(Rect.fromCircle(center: yarn, radius: 14), 0.5, 2.5, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFFFB3CB));
  }

  void _leaf(Canvas c, Offset base, double angle, double len, Color color) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle + math.sin(t * 0.9 + base.dx) * 0.04);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -len * 0.32, len, 0)
      ..quadraticBezierTo(len * 0.5, len * 0.32, 0, 0)
      ..close();
    c.drawPath(p, solid(color));
    c.drawLine(Offset.zero, Offset(len * 0.95, 0), Paint()..color = darken(color, 0.25)..strokeWidth = 3);
    c.restore();
  }

  void _jungle(Canvas c, Size s) {
    final ground = s.height * groundY;
    _sky(c, s, const Color(0xFF7FD7FF), const Color(0xFFD9FFE8));
    c.drawCircle(Offset(s.width * 0.8, s.height * 0.12), 38, solid(const Color(0xFFFFE066)));
    _clouds(c, s, s.height * 0.1, 10);
    // Far trees.
    for (var i = 0; i < 7; i++) {
      final x = s.width * (i / 6);
      c.drawCircle(Offset(x, ground - s.height * 0.12), s.width * 0.16, solid(const Color(0xFF7ACB8A)));
    }
    c.drawRect(Rect.fromLTRB(0, ground - s.height * 0.12, s.width, s.height), solid(const Color(0xFF63B875)));
    c.drawRect(Rect.fromLTRB(0, ground + s.height * 0.06, s.width, s.height), solid(const Color(0xFF4FA563)));
    // Hanging vines.
    for (final x in [0.12, 0.3, 0.88]) {
      final vine = Path()..moveTo(s.width * x, 0);
      for (var y = 0.0; y < s.height * 0.35; y += 20) {
        vine.lineTo(s.width * x + math.sin(y / 30 + t) * 6, y);
      }
      c.drawPath(vine, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0xFF3F9B55));
      for (var y = 30.0; y < s.height * 0.35; y += 48) {
        _leaf(c, Offset(s.width * x, y), 0.6, 26, const Color(0xFF5CC56F));
      }
    }
    // Big leaves in the corners.
    for (var i = 0; i < 5; i++) {
      _leaf(c, Offset(-10, s.height * (0.55 + i * 0.07)), -0.5 + i * 0.2, s.width * 0.3, i.isEven ? const Color(0xFF2E9E52) : const Color(0xFF3BB763));
      _leaf(c, Offset(s.width + 10, s.height * (0.58 + i * 0.07)), math.pi + 0.5 - i * 0.2, s.width * 0.28, i.isEven ? const Color(0xFF3BB763) : const Color(0xFF2E9E52));
    }
    // Flowers.
    for (final (x, y, col) in [(0.2, 0.9, const Color(0xFFFF6B9A)), (0.78, 0.93, const Color(0xFFFFB02E)), (0.5, 0.97, const Color(0xFFB07CFF))]) {
      final o = Offset(s.width * x, s.height * y);
      for (var k = 0; k < 5; k++) {
        final a = k / 5 * 2 * math.pi;
        c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * 9, 8, solid(col));
      }
      c.drawCircle(o, 6, solid(const Color(0xFFFFF176)));
    }
  }

  void _yard(Canvas c, Size s) {
    final ground = s.height * groundY;
    _sky(c, s, const Color(0xFF8ED8FF), const Color(0xFFE8F8FF));
    c.drawCircle(Offset(s.width * 0.15, s.height * 0.1), 34, solid(const Color(0xFFFFE066)));
    _clouds(c, s, s.height * 0.12, 9);
    // Hedge and white picket fence.
    for (var i = 0; i < 8; i++) {
      c.drawCircle(Offset(s.width * i / 7, ground - s.height * 0.13), s.width * 0.11, solid(const Color(0xFF5DBB63)));
    }
    final picket = solid(Colors.white);
    final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFB8C4CC);
    for (var x = 4.0; x < s.width; x += s.width / 11) {
      final p = Path()
        ..moveTo(x, ground - s.height * 0.08)
        ..lineTo(x, ground - s.height * 0.17)
        ..lineTo(x + 9, ground - s.height * 0.19)
        ..lineTo(x + 18, ground - s.height * 0.17)
        ..lineTo(x + 18, ground - s.height * 0.08)
        ..close();
      c.drawPath(p, picket);
      c.drawPath(p, edge);
    }
    c.drawRect(Rect.fromLTWH(0, ground - s.height * 0.15, s.width, 8), picket);
    c.drawRect(Rect.fromLTRB(0, ground - s.height * 0.08, s.width, s.height), solid(const Color(0xFF7BCB55)));
    // Doghouse on the left.
    final house = Rect.fromLTWH(s.width * 0.02, ground - s.height * 0.2, s.width * 0.22, s.height * 0.13);
    c.drawRect(house, solid(const Color(0xFFE07A3F)));
    c.drawPath(Path()
      ..moveTo(house.left - 8, house.top)
      ..lineTo(house.center.dx, house.top - s.height * 0.06)
      ..lineTo(house.right + 8, house.top)
      ..close(), solid(const Color(0xFF8E3B22)));
    c.drawOval(Rect.fromCenter(center: Offset(house.center.dx, house.bottom - house.height * 0.3), width: house.width * 0.45, height: house.height * 0.6),
        solid(const Color(0xFF3B2416)));
    // Ball and bone.
    final ball = Offset(s.width * 0.86, ground + s.height * 0.08);
    c.drawCircle(ball, 18, solid(const Color(0xFFFF4F6D)));
    c.drawArc(Rect.fromCircle(center: ball, radius: 18), -0.3, 2.4, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.white);
    final bone = Offset(s.width * 0.14, ground + s.height * 0.12);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: bone, width: 44, height: 12), const Radius.circular(6)), solid(const Color(0xFFFFF4E4)));
    for (final dx in [-22.0, 22.0]) {
      for (final dy in [-6.0, 6.0]) {
        c.drawCircle(bone + Offset(dx, dy), 8, solid(const Color(0xFFFFF4E4)));
      }
    }
  }

  void _savanna(Canvas c, Size s) {
    final ground = s.height * groundY;
    _sky(c, s, const Color(0xFFFFC37A), const Color(0xFFFFEBC2));
    c.drawCircle(Offset(s.width * 0.75, s.height * 0.16), 60, solid(const Color(0xFFFFE08A).withValues(alpha: 0.9)));
    _clouds(c, s, s.height * 0.08, 6);
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.5, ground - s.height * 0.06), width: s.width * 1.6, height: s.height * 0.22), solid(const Color(0xFFE8C46A)));
    // Acacia trees.
    void acacia(Offset base, double sz) {
      c.drawLine(base, base + Offset(0, -sz), Paint()..color = const Color(0xFF6B4A2B)..strokeWidth = sz * 0.08..strokeCap = StrokeCap.round);
      c.drawOval(Rect.fromCenter(center: base + Offset(0, -sz), width: sz * 1.6, height: sz * 0.4), solid(const Color(0xFF6E9A3E)));
    }
    acacia(Offset(s.width * 0.12, ground - s.height * 0.1), s.width * 0.22);
    acacia(Offset(s.width * 0.88, ground - s.height * 0.12), s.width * 0.16);
    c.drawRect(Rect.fromLTRB(0, ground - s.height * 0.08, s.width, s.height), solid(const Color(0xFFD9B455)));
    // Waterhole and grass tufts.
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.82, ground + s.height * 0.1), width: s.width * 0.34, height: s.height * 0.05), solid(const Color(0xFF6CC3E8)));
    final blade = Paint()..color = const Color(0xFFB08A2E)..strokeWidth = 3..strokeCap = StrokeCap.round;
    final rng = math.Random(5);
    for (var i = 0; i < 24; i++) {
      final o = Offset(rng.nextDouble() * s.width, ground - s.height * 0.04 + rng.nextDouble() * s.height * 0.28);
      c.drawLine(o, o + const Offset(-4, -14), blade);
      c.drawLine(o, o + const Offset(4, -15), blade);
    }
  }

  void _farm(Canvas c, Size s) {
    final ground = s.height * groundY;
    _sky(c, s, const Color(0xFF6CCBFF), const Color(0xFFE6F8FF));
    // Sun with slowly turning rays.
    final sun = Offset(s.width * 0.82, s.height * 0.11);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * 2 * math.pi + t * 0.15;
      c.drawLine(sun + Offset(math.cos(a), math.sin(a)) * 44, sun + Offset(math.cos(a), math.sin(a)) * 62,
          Paint()..color = const Color(0xFFFFD23F)..strokeWidth = 8..strokeCap = StrokeCap.round);
    }
    c.drawCircle(sun, 36, solid(const Color(0xFFFFD23F)));
    _clouds(c, s, s.height * 0.09, 12);
    // Hills.
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.2, ground - s.height * 0.06), width: s.width * 1.1, height: s.height * 0.3), solid(const Color(0xFF9BDB7A)));
    c.drawOval(Rect.fromCenter(center: Offset(s.width * 0.9, ground - s.height * 0.04), width: s.width * 1.0, height: s.height * 0.26), solid(const Color(0xFF86CF68)));
    // Barn.
    final barn = Rect.fromLTWH(s.width * 0.05, ground - s.height * 0.24, s.width * 0.26, s.height * 0.16);
    final roof = Path()
      ..moveTo(barn.left - 10, barn.top)
      ..lineTo(barn.center.dx, barn.top - s.height * 0.07)
      ..lineTo(barn.right + 10, barn.top)
      ..close();
    c.drawRect(barn, solid(const Color(0xFFE5483F)));
    c.drawPath(roof, solid(const Color(0xFF9E3A2F)));
    final door = Rect.fromCenter(center: Offset(barn.center.dx, barn.bottom - barn.height * 0.3), width: barn.width * 0.4, height: barn.height * 0.6);
    c.drawRect(door, solid(Colors.white));
    c.drawRect(door.deflate(5), solid(const Color(0xFFC0392B)));
    c.drawLine(door.deflate(5).topLeft, door.deflate(5).bottomRight, Paint()..color = Colors.white..strokeWidth = 4);
    c.drawLine(door.deflate(5).topRight, door.deflate(5).bottomLeft, Paint()..color = Colors.white..strokeWidth = 4);
    // Grass and fence.
    c.drawRect(Rect.fromLTRB(0, ground - s.height * 0.08, s.width, s.height), solid(const Color(0xFF6CC24A)));
    final wood = solid(const Color(0xFFF4D6A0));
    final edge = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFFB88A4A);
    for (var x = 0.0; x < s.width + 40; x += s.width / 7) {
      final post = RRect.fromRectAndRadius(Rect.fromLTWH(x, ground - s.height * 0.16, 16, s.height * 0.1), const Radius.circular(4));
      c.drawRRect(post, wood);
      c.drawRRect(post, edge);
    }
    for (final y in [0.14, 0.1]) {
      final rail = Rect.fromLTWH(0, ground - s.height * y, s.width, 10);
      c.drawRect(rail, wood);
      c.drawRect(rail, edge);
    }
    // Grass tufts.
    final blade = Paint()..color = const Color(0xFF4FA83A)..strokeWidth = 4..strokeCap = StrokeCap.round;
    final rng = math.Random(3);
    for (var i = 0; i < 26; i++) {
      final o = Offset(rng.nextDouble() * s.width, ground - s.height * 0.04 + rng.nextDouble() * s.height * 0.3);
      c.drawLine(o, o + const Offset(-5, -14), blade);
      c.drawLine(o, o + const Offset(4, -16), blade);
    }
    // Corn kernels for pecking.
    for (var i = 0; i < 6; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(s.width * (0.25 + i * 0.1), ground + s.height * 0.1 + (i % 2) * 8), width: 10, height: 13), solid(const Color(0xFFFFD23F)));
    }
  }

  @override
  bool shouldRepaint(covariant ScenePainter old) => old.kind != kind || old.image != image || (image == null && old.t != t);
}
