import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/pets.dart';
import 'toon.dart';

class Particle {
  Particle(this.kind, this.pos, this.vel, {required this.life, required this.size, required this.color, this.spin = 0});

  final Fx kind;
  Offset pos; // canvas units (1000 box)
  Offset vel; // units per second
  final double life; // seconds
  final double size;
  final Color color;
  final double spin;
  double age = 0;
  double rot = 0;

  double get t => (age / life).clamp(0, 1);
  bool get dead => age >= life;
}

/// Spawns and moves the little bursts (hearts, notes, stars...).
class ParticleSystem {
  final _rng = math.Random();
  final List<Particle> items = [];

  static const _noteColors = [Color(0xFF7C5CFF), Color(0xFFFF5A8A), Color(0xFF2FB4FF), Color(0xFFFFA928)];
  static const _featherColors = [Color(0xFF52C46C), Color(0xFFFF5A4E), Color(0xFF3E8EF7), Color(0xFFFFA23A)];

  double _r(double a, double b) => a + _rng.nextDouble() * (b - a);

  void burst(Fx fx, Offset at, {int? count, List<Color>? palette}) {
    final n = count ?? switch (fx) { Fx.hearts => 6, Fx.notes => 5, Fx.stars => 7, Fx.sneeze => 12, Fx.feathers => 8, Fx.zzz => 1, Fx.sparkles => 14, Fx.bubbles => 9 };
    for (var i = 0; i < n; i++) {
      switch (fx) {
        case Fx.hearts:
          items.add(Particle(fx, at + Offset(_r(-120, 120), _r(-30, 30)), Offset(_r(-60, 60), _r(-260, -160)),
              life: _r(1.2, 1.8), size: _r(28, 46), color: const Color(0xFFFF4F7B)));
        case Fx.notes:
          items.add(Particle(fx, at + Offset(_r(-140, 140), _r(-30, 30)), Offset(_r(-90, 90), _r(-230, -150)),
              life: _r(1.2, 1.8), size: _r(34, 48), color: _noteColors[_rng.nextInt(_noteColors.length)], spin: _r(-1, 1)));
        case Fx.stars:
          final a = i / n * 2 * math.pi;
          items.add(Particle(fx, at, Offset(math.cos(a), math.sin(a) * 0.5) * _r(180, 260),
              life: 0.9, size: _r(22, 34), color: const Color(0xFFFFD23F), spin: 4));
        case Fx.sneeze:
          items.add(Particle(fx, at + Offset(0, 20), Offset(_r(-320, 320), _r(-120, 180)),
              life: _r(0.5, 0.9), size: _r(8, 18), color: const Color(0xFF9FDDFF)));
        case Fx.feathers:
          final p = palette ?? _featherColors;
          items.add(Particle(fx, at + Offset(_r(-220, 220), _r(-60, 60)), Offset(_r(-120, 120), _r(-220, -60)),
              life: _r(1.6, 2.4), size: _r(24, 36), color: p[_rng.nextInt(p.length)], spin: _r(-3, 3)));
        case Fx.zzz:
          items.add(Particle(fx, at, const Offset(60, -110), life: 2.2, size: _r(40, 56), color: const Color(0xFF5B6BD6)));
        case Fx.sparkles:
          items.add(Particle(fx, at + Offset(_r(-300, 300), _r(-300, 200)), Offset(0, _r(-60, -20)),
              life: _r(0.8, 1.4), size: _r(14, 28), color: [const Color(0xFFFFD23F), Colors.white, const Color(0xFFFF9BD2)][i % 3], spin: 2));
        case Fx.bubbles:
          items.add(Particle(fx, at + Offset(_r(-150, 150), _r(-20, 40)), Offset(_r(-40, 40), _r(-220, -120)),
              life: _r(1.4, 2.0), size: _r(18, 34), color: const Color(0xFF8FD8FF)));
      }
    }
  }

  void update(double dt) {
    for (final p in items) {
      p.age += dt;
      p.rot += p.spin * dt;
      final wobble = p.kind == Fx.feathers ? Offset(math.sin(p.age * 5) * 60, 0) : Offset.zero;
      final gravity = switch (p.kind) { Fx.sneeze => 500.0, Fx.feathers => 140.0, Fx.stars => 0.0, _ => -10.0 };
      p.vel = Offset(p.vel.dx * (1 - dt * 0.8), p.vel.dy + gravity * dt);
      p.pos += (p.vel + wobble) * dt;
    }
    items.removeWhere((p) => p.dead);
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter(this.system, {this.listening = 0, this.listenAt = const Offset(760, 230)});

  final ParticleSystem system;

  /// 0..1 strength of the "I'm listening" sound waves (0 = hidden).
  final double listening;
  final Offset listenAt;

  @override
  void paint(Canvas canvas, Size size) {
    final s = PetPainter.scaleFor(size);
    canvas.save();
    canvas.translate((size.width - 1000 * s) / 2, (size.height - 1000 * s) / 2);
    canvas.scale(s);
    if (listening > 0) _listenWaves(canvas);
    for (final p in system.items) {
      final fade = p.t < 0.75 ? 1.0 : (1 - p.t) / 0.25;
      final grow = p.kind == Fx.stars ? 1.0 : math.min(1.0, p.age / 0.15);
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rot);
      canvas.scale(grow);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      final line = outline(5)..color = ink.withValues(alpha: fade * 0.9);
      switch (p.kind) {
        case Fx.hearts:
          final h = heartPath(Offset.zero, p.size);
          canvas.drawPath(h, paint);
          canvas.drawPath(h, line);
        case Fx.notes:
          final head = Rect.fromCenter(center: Offset(0, p.size * 0.4), width: p.size * 0.8, height: p.size * 0.6);
          canvas.drawOval(head, paint);
          canvas.drawLine(Offset(p.size * 0.36, p.size * 0.35), Offset(p.size * 0.36, -p.size * 0.7), Paint()..color = paint.color..strokeWidth = 8..strokeCap = StrokeCap.round);
          canvas.drawLine(Offset(p.size * 0.36, -p.size * 0.7), Offset(p.size * 0.8, -p.size * 0.45), Paint()..color = paint.color..strokeWidth = 8..strokeCap = StrokeCap.round);
        case Fx.stars || Fx.sparkles:
          final st = starPath(Offset.zero, p.size, points: p.kind == Fx.stars ? 5 : 4, inner: p.kind == Fx.stars ? 0.45 : 0.3);
          canvas.drawPath(st, paint);
          if (p.kind == Fx.stars) canvas.drawPath(st, line);
        case Fx.sneeze || Fx.bubbles:
          canvas.drawCircle(Offset.zero, p.size, paint..color = p.color.withValues(alpha: fade * 0.7));
          canvas.drawCircle(Offset(-p.size * 0.3, -p.size * 0.3), p.size * 0.25, Paint()..color = Colors.white.withValues(alpha: fade));
          if (p.kind == Fx.bubbles) canvas.drawCircle(Offset.zero, p.size, outline(3)..color = Colors.white.withValues(alpha: fade * 0.8));
        case Fx.feathers:
          final f = Path()
            ..moveTo(0, -p.size)
            ..quadraticBezierTo(p.size * 0.55, 0, 0, p.size)
            ..quadraticBezierTo(-p.size * 0.55, 0, 0, -p.size)
            ..close();
          canvas.drawPath(f, paint);
          canvas.drawPath(f, outline(4)..color = ink.withValues(alpha: fade * 0.7));
          canvas.drawLine(Offset(0, -p.size), Offset(0, p.size * 1.2), outline(3)..color = ink.withValues(alpha: fade * 0.6));
        case Fx.zzz:
          final tp = TextPainter(
            text: TextSpan(text: 'Z', style: TextStyle(fontSize: p.size, fontWeight: FontWeight.w900, color: p.color.withValues(alpha: fade))),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      }
      canvas.restore();
    }
    canvas.restore();
  }

  void _listenWaves(Canvas c) {
    // Three arcs beside the head, like sound going into an ear.
    for (var i = 0; i < 3; i++) {
      final r = 40.0 + i * 34;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2FB4FF).withValues(alpha: (0.35 + 0.65 * listening) * (1 - i * 0.22));
      c.drawArc(Rect.fromCircle(center: listenAt, radius: r), -0.9, 1.8, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) => true;
}
