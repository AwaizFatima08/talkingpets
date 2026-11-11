import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What the talk-back engine is doing right now.
enum EchoState { idle, listening, hearing, talking, error }

/// Dart side of the native audio (android/.../MainActivity.kt):
/// the voice echo engine, animal sound effects and the parrot's speech.
class PetAudio {
  PetAudio._();
  static final PetAudio instance = PetAudio._();

  static const _method = MethodChannel('talkypals/audio');
  static const _events = EventChannel('talkypals/audio_events');

  final _state = StreamController<EchoState>.broadcast();
  final _level = StreamController<({EchoState phase, double value})>.broadcast();
  final _speaking = StreamController<bool>.broadcast();
  StreamSubscription<dynamic>? _sub;
  EchoState current = EchoState.idle;

  Stream<EchoState> get states => _state.stream;
  Stream<({EchoState phase, double value})> get levels => _level.stream;
  Stream<bool> get speaking => _speaking.stream;

  void _ensureListening() {
    _sub ??= _events.receiveBroadcastStream().listen((e) {
      final m = e as Map;
      switch (m['type']) {
        case 'state':
          current = EchoState.values.firstWhere((s) => s.name == m['state'], orElse: () => EchoState.idle);
          if (kDebugMode) debugPrint('[echo] ${current.name}');
          _state.add(current);
        case 'level':
          final phase = m['phase'] == 'talking' ? EchoState.talking : EchoState.hearing;
          _level.add((phase: phase, value: (m['value'] as num).toDouble()));
        case 'speaking':
          _speaking.add(m['value'] == true);
      }
    });
  }

  /// name -> alternative sound files; [play] picks one at random.
  Map<String, List<String>> variants = const {};
  final _rng = math.Random();

  Future<void> init(List<String> sfxNames, {Map<String, List<String>> variants = const {}}) async {
    this.variants = variants;
    _ensureListening();
    await _invoke('preloadSfx', {'names': sfxNames});
    await _invoke('warmUpSpeech');
  }

  Future<void> startListening() => _invoke('startListening');
  Future<void> stopListening() => _invoke('stopListening');

  Future<void> setVoice(VoiceSpec v) => _invoke('setVoice', v.toMap());
  Future<void> setSensitivity(double value) => _invoke('setSensitivity', {'value': value});

  /// Plays a sound and returns its duration (0 if unavailable).
  Future<Duration> play(String name, {double rate = 1, double volume = 1}) async {
    final options = variants[name];
    if (options != null && options.isNotEmpty) name = options[_rng.nextInt(options.length)];
    final ms = await _invoke<int>('playSfx', {'name': name, 'rate': rate, 'volume': volume});
    return Duration(milliseconds: ms ?? 0);
  }

  /// Speaks [text]; returns false when the device has no text-to-speech voice.
  Future<bool> speak(String text, {double pitch = 1.8, double rate = 1.1}) async =>
      await _invoke<bool>('speak', {'text': text, 'pitch': pitch, 'rate': rate}) ?? false;

  Future<void> stopAllSounds() => _invoke('stopAllSounds');

  /// Media volume 0..1, or null when unknown.
  Future<double?> mediaVolume() => _invoke<double>('mediaVolume');

  /// Shows Android's volume slider (the pets are silent at volume 0).
  Future<void> showVolumeControl() => _invoke('showVolumeControl');

  /// Test hook: feeds a WAV file through the listening pipeline.
  Future<bool> simulateUtterance(String path) async =>
      await _invoke<bool>('simulateUtterance', {'path': path}) ?? false;

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _method.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null; // host tests
    } on PlatformException {
      return null;
    }
  }
}

/// How the echoed voice is transformed. See TalkEngine.Voice.
class VoiceSpec {
  const VoiceSpec({required this.pitch, this.vibratoHz = 0, this.vibratoDepth = 0, this.tremoloHz = 0, this.tremoloDepth = 0});

  final double pitch;
  final double vibratoHz;
  final double vibratoDepth;
  final double tremoloHz;
  final double tremoloDepth;

  Map<String, Object?> toMap() => {
        'pitch': pitch,
        'vibratoHz': vibratoHz,
        'vibratoDepth': vibratoDepth,
        'tremoloHz': tremoloHz,
        'tremoloDepth': tremoloDepth,
      };
}
