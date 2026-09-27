import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/audio.dart';
import '../core/pets.dart';
import 'particles.dart';
import 'pet_painters.dart';
import 'toon.dart';

/// Sounds during which the pet's mouth stays shut.
const _mouthClosedSounds = {'wing_flap', 'beak_clack', 'peck', 'boing', 'pop', 'whoosh', 'sparkle', 'cat_purr'};

/// Lets the screen poke the pet that is currently on stage. During a switch
/// animation two PetViews exist; the newest one owns the controller.
class PetController {
  PetViewState? _view;

  void react(Reaction r) => _view?.react(r);
  void burst(Fx fx, Offset at) => _view?.particles.burst(fx, at);

  /// Any touch in the app wakes a dozing pet.
  void wake() => _view?._wake();
}

/// A living pet: idles, reacts to touch, listens and talks back.
class PetView extends StatefulWidget {
  const PetView({super.key, required this.pet, this.accessory = Accessory.none, this.onReaction, this.greet = true, this.controller});

  final PetSpec pet;
  final PetController? controller;
  final Accessory accessory;
  final bool greet;

  /// Called with the touched part after every reaction starts.
  final void Function(BodyPart part)? onReaction;

  @override
  State<PetView> createState() => PetViewState();
}

class _Active {
  _Active(this.reaction, this.start, this.duration, {this.part});
  final Reaction reaction;
  final Duration start;
  final Duration duration;
  final BodyPart? part;
}

class PetViewState extends State<PetView> with SingleTickerProviderStateMixin {
  final _rng = math.Random();
  final particles = ParticleSystem();
  late final Ticker _ticker;
  final _clock = ValueNotifier<Duration>(Duration.zero);
  Duration _last = Duration.zero;

  _Active? _active;
  final Map<BodyPart, int> _lastPick = {};

  // Blinking and gaze.
  double _nextBlink = 2;
  double _blinkStart = -1;
  Offset _look = Offset.zero, _lookTarget = Offset.zero;
  double _nextGlance = 1.5;

  // Echo engine feedback.
  EchoState _echo = EchoState.idle;
  double _level = 0, _levelSmooth = 0;
  bool _speaking = false;
  double _noteTimer = 0;
  final List<StreamSubscription<dynamic>> _subs = [];

  // Sleepiness.
  double _lastActivity = 0;
  bool _yawned = false;

  // Petting (rubbing the head).
  double _rubDistance = 0;

  double get _now => _clock.value.inMicroseconds / 1e6;

  /// The reaction playing now (for tests).
  @visibleForTesting
  Reaction? get activeReaction => _active?.reaction;

  /// The part that was touched last (for tests).
  @visibleForTesting
  BodyPart? get activePart => _active?.part;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    widget.controller?._view = this;
    final audio = PetAudio.instance;
    _echo = audio.current;
    _subs.add(audio.states.listen((s) {
      _echo = s;
      if (s == EchoState.hearing || s == EchoState.talking) _wake();
    }));
    _subs.add(audio.levels.listen((l) => _level = l.value));
    _subs.add(audio.speaking.listen((v) => _speaking = v));
    if (widget.greet) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) react(widget.pet.greeting);
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller?._view == this) widget.controller?._view = null;
    for (final s in _subs) {
      s.cancel();
    }
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    particles.update(dt);
    _levelSmooth += (_level - _levelSmooth) * math.min(1, dt * 18);
    final t = elapsed.inMicroseconds / 1e6;
    if (_echo == EchoState.talking) {
      _noteTimer -= dt;
      if (_noteTimer <= 0 && _levelSmooth > 0.25) {
        particles.burst(Fx.notes, const Offset(640, 300), count: 1);
        _noteTimer = 0.45;
      }
    }
    final idle = t - _lastActivity;
    if (idle > 45 && !_yawned) {
      _yawned = true;
      PetAudio.instance.play('yawn');
    }
    if (idle > 55 && ((t * 10).floor() % 22 == 0) && particles.items.where((p) => p.kind == Fx.zzz).isEmpty) {
      particles.burst(Fx.zzz, const Offset(650, 220));
    }
    _clock.value = elapsed;
  }

  void _wake() {
    _lastActivity = _now;
    _yawned = false;
  }

  /// Plays [r] (sound, mood, motion and particles). The animation starts at
  /// once; its length is fitted to the sound when the platform reports it.
  Future<void> react(Reaction r, {BodyPart? part}) async {
    _wake();
    final start = _clock.value;
    final active = _Active(r, start, const Duration(milliseconds: 1100), part: part);
    _active = active;
    if (r.fx != null) particles.burst(r.fx!, _fxOrigin(r.fx!, part));
    final rate = r.rate * (0.94 + _rng.nextDouble() * 0.14);
    var duration = Duration.zero;
    var spoke = false;
    if (r.say != null) spoke = await PetAudio.instance.speak(r.say!, pitch: 1.9, rate: 1.05);
    if (!spoke && r.sound != null) duration = await PetAudio.instance.play(r.sound!, rate: rate);
    if (spoke) duration = Duration(milliseconds: 350 + 90 * r.say!.length);
    if (!mounted || _active != active) return;
    final d = Duration(milliseconds: math.max(900, duration.inMilliseconds + 150));
    _active = _Active(r, start, d, part: part);
  }

  Offset _fxOrigin(Fx fx, BodyPart? part) => switch (fx) {
        Fx.sneeze => const Offset(500, 470),
        Fx.stars => const Offset(500, 200),
        Fx.feathers => const Offset(500, 650),
        Fx.bubbles => const Offset(500, 600),
        _ => const Offset(500, 250),
      };

  void _onTap(Offset local, Size size) {
    final part = painterFor(widget.pet.kind, const PetPose()).hitTestPart(local, size);
    if (part == null) return;
    final options = widget.pet.reactions[part];
    if (options == null || options.isEmpty) return;
    // Cycle through the options, but not strictly in order.
    var i = _rng.nextInt(options.length);
    if (options.length > 1 && i == _lastPick[part]) i = (i + 1) % options.length;
    _lastPick[part] = i;
    react(options[i], part: part);
    widget.onReaction?.call(part);
  }

  void _onRub(Offset local, Offset delta, Size size) {
    final part = painterFor(widget.pet.kind, const PetPose()).hitTestPart(local, size);
    if (part != BodyPart.head && part != BodyPart.cheeks && part != BodyPart.belly) return;
    _rubDistance += delta.distance;
    if (_rubDistance > 260 && _active == null) {
      _rubDistance = 0;
      final loving = widget.pet.reactions[BodyPart.head]!.firstWhere((r) => r.mood == Mood.love);
      react(loving, part: BodyPart.head);
    }
  }

  PetPose _pose() {
    final t = _now;
    // Blink every few seconds (sometimes twice).
    if (t > _nextBlink) {
      _blinkStart = t;
      _nextBlink = t + (_rng.nextDouble() < 0.2 ? 0.35 : 2.2 + _rng.nextDouble() * 3);
    }
    final bt = (t - _blinkStart) / 0.16;
    var blink = bt >= 0 && bt <= 1 ? math.sin(bt * math.pi) : 0.0;
    // Glance around.
    if (t > _nextGlance) {
      _lookTarget = _rng.nextDouble() < 0.4 ? Offset.zero : Offset(_rng.nextDouble() * 2 - 1, _rng.nextDouble() * 1.2 - 0.6);
      _nextGlance = t + 1.2 + _rng.nextDouble() * 2.5;
    }
    _look += (_lookTarget - _look) * 0.12;

    var mood = Mood.neutral;
    var mouth = 0.0, tilt = 0.0, bodyDy = 0.0, squash = 1.0, lean = 0.0, tail = 0.0, wing = 0.0, puff = 0.0, crest = 0.0;
    var look = _look;
    // Idle sway and a lazy tail.
    tail = math.sin(t * 1.6) * 0.35;
    tilt = math.sin(t * 0.7) * 0.03;

    final idle = t - _lastActivity;
    if (idle > 40) mood = Mood.sleepy;
    if (idle > 55) blink = 1;

    // Echo: listening pose, then talking with the voice level.
    if (_echo == EchoState.hearing) {
      mood = Mood.listening;
      tilt = 0.13;
      look = const Offset(0.8, -0.5);
      bodyDy = -6 * _levelSmooth;
      blink = 0;
    } else if (_echo == EchoState.talking) {
      mouth = (_levelSmooth * 1.25).clamp(0.0, 1.0);
      bodyDy = -22 * _levelSmooth;
      squash = 1 + 0.05 * _levelSmooth;
      tilt = math.sin(t * 9) * 0.05 * _levelSmooth;
      wing = widget.pet.kind == PetKind.cat ? 0 : 0.25 * _levelSmooth;
      mood = Mood.happy;
      if (_levelSmooth > 0.05) mood = Mood.neutral;
      blink = 0;
    }
    if (_speaking) {
      mouth = 0.35 + 0.35 * math.sin(t * 22).abs();
      mood = Mood.happy;
    }

    final a = _active;
    if (a != null) {
      final p = ((_clock.value - a.start).inMicroseconds / a.duration.inMicroseconds).clamp(0.0, 1.0);
      if (p >= 1) {
        _active = null;
      } else {
        final r = a.reaction;
        mood = r.mood;
        blink = 0;
        final fadeOut = 1 - p;
        final vocal = r.sound != null && !_mouthClosedSounds.contains(r.sound) || r.say != null;
        if (vocal && !_speaking) mouth = math.max(mouth, 0.7 * math.sin(math.min(1, p * 1.25) * math.pi) * (0.75 + 0.25 * math.sin(p * 40)));
        switch (r.motion) {
          case Motion.bounce:
            bodyDy = -70 * (math.sin(p * math.pi * 3)).abs() * fadeOut;
            squash = 1 + 0.06 * math.sin(p * math.pi * 6) * fadeOut;
          case Motion.squash:
            squash = 1 - 0.22 * math.sin(p * math.pi * 4) * fadeOut;
          case Motion.wiggle:
            lean = 0.12 * math.sin(p * math.pi * 10) * fadeOut;
            squash = 1 - 0.05 * math.sin(p * math.pi * 10).abs();
          case Motion.jump:
            final j = math.min(1.0, p * 1.6);
            bodyDy = -170 * math.sin(j * math.pi);
            squash = j < 1 ? 1.08 : 1 - 0.15 * math.sin((p - 0.625) / 0.375 * math.pi);
          case Motion.shake:
            tilt = 0.22 * math.sin(p * math.pi * 12) * fadeOut;
          case Motion.flap:
            wing = (math.sin(p * math.pi * 8)).abs() * math.min(1, fadeOut * 3);
            bodyDy = -60 * math.sin(p * math.pi);
          case Motion.tall:
            final s = math.sin(p * math.pi);
            squash = 1 + 0.14 * s;
            crest = s;
            tilt = -0.08 * s;
            wing = 0.3 * s;
          case Motion.wag:
            tail = math.sin(p * math.pi * 8);
            wing = math.sin(math.min(1, p * 1.2) * math.pi) * (0.8 + 0.2 * math.sin(p * math.pi * 10));
            tilt = 0.08 * math.sin(p * math.pi * 4);
          case Motion.puff:
            final s = math.sin(math.min(1, p * 1.3) * math.pi);
            puff = s;
            squash = 1 + 0.06 * s;
            lean = 0.03 * math.sin(p * 60) * s;
          case Motion.nod:
            tilt = 0.16 * math.sin(p * math.pi * 4) * fadeOut;
            bodyDy = -12 * math.sin(p * math.pi * 4).abs();
        }
        if (r.mood == Mood.surprised) crest = math.max(crest, math.sin(p * math.pi));
      }
    }

    return PetPose(
      breath: (t / 3.2) % 1,
      blink: blink,
      mouth: mouth,
      mood: mood,
      lookX: look.dx,
      lookY: look.dy,
      tilt: tilt,
      bodyDy: bodyDy,
      squash: squash,
      lean: lean,
      tail: tail,
      wing: wing,
      puff: puff,
      crest: crest,
      accessory: widget.accessory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTap(d.localPosition, size),
        onPanUpdate: (d) => _onRub(d.localPosition, d.delta, size),
        onPanEnd: (_) => _rubDistance = 0,
        child: ValueListenableBuilder<Duration>(
          valueListenable: _clock,
          builder: (context, _, _) {
            final pose = _pose();
            return Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: painterFor(widget.pet.kind, pose)),
              CustomPaint(
                painter: ParticlePainter(
                  particles,
                  listening: _echo == EchoState.hearing ? 0.3 + 0.7 * _levelSmooth : 0,
                  listenAt: Offset(widget.pet.kind == PetKind.cat ? 790 : 720, 330),
                ),
              ),
            ]);
          },
        ),
      );
    });
  }
}
