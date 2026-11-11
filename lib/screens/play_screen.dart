import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../ads/ads_service.dart';
import '../ads/banner_slot.dart';
import '../core/audio.dart';
import '../core/pets.dart';
import '../core/settings.dart';
import '../pets/pet_art.dart';
import '../pets/pet_painters.dart';
import '../pets/pet_view.dart';
import '../pets/toon.dart';
import '../widgets/parent_gate.dart';
import '../widgets/scene.dart';
import 'grownups_screen.dart';

/// `--dart-define=TP_STORE_SHOTS=true`: hides the ad and the volume hint for store screenshots.
const _storeShots = bool.fromEnvironment('TP_STORE_SHOTS');

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, this.showBanner = !_storeShots});

  /// Off in widget tests (no ads SDK on the host).
  final bool showBanner;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final settings = Settings.instance;
  final audio = PetAudio.instance;
  final ads = AdsService.instance;
  late PetKind _pet = settings.pet;
  bool _micGranted = false;
  bool _resumed = true;
  EchoState _echo = EchoState.idle;
  StreamSubscription<EchoState>? _stateSub;
  late final Ticker _sceneTicker;
  final _sceneTime = ValueNotifier<double>(0);
  final _petCtl = PetController();
  String? _toast;
  Timer? _toastTimer;
  Timer? _volumeTimer;
  bool _muted = false;

  PetSpec get pet => petOf(_pet);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _sceneTicker = createTicker((e) => _sceneTime.value = e.inMilliseconds / 1000)..start();
    _stateSub = audio.states.listen((s) => setState(() => _echo = s));
    ads.onFullScreen = (showing) => showing ? _stopEcho() : _syncEcho();
    settings.addListener(_onSettings);
    _applyVoice();
    _checkMic();
    _checkVolume();
    _volumeTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkVolume());
  }

  Future<void> _checkVolume() async {
    final v = await audio.mediaVolume();
    final muted = v != null && v <= 0 && !_storeShots;
    if (mounted && muted != _muted) setState(() => _muted = muted);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _sceneTicker.dispose();
    _stateSub?.cancel();
    _toastTimer?.cancel();
    _volumeTimer?.cancel();
    settings.removeListener(_onSettings);
    ads.onFullScreen = null;
    audio.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      _checkMic();
    } else {
      _stopEcho();
      audio.stopAllSounds();
    }
  }

  void _onSettings() {
    audio.setSensitivity(settings.sensitivity);
    _syncEcho();
    if (mounted) setState(() {});
  }

  Future<void> _checkMic() async {
    final granted = await Permission.microphone.isGranted;
    if (!mounted) return;
    setState(() => _micGranted = granted);
    _syncEcho();
  }

  void _syncEcho() {
    final want = _micGranted && settings.micOn && _resumed && !ads.fullScreenShowing;
    if (want) {
      audio.setSensitivity(settings.sensitivity);
      audio.startListening();
    } else {
      _stopEcho();
    }
  }

  void _stopEcho() => audio.stopListening();

  void _applyVoice() => audio.setVoice(pet.voiceFor(settings.tone));

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  Future<void> _switchPet(PetKind kind) async {
    if (kind == _pet) {
      _petCtl.react(pet.greeting);
      return;
    }
    audio.play('whoosh');
    setState(() => _pet = kind);
    settings.pet = kind;
    _applyVoice();
    await ads.onNaturalBreak();
  }

  void _cycleTone() {
    _petCtl.wake();
    final next = Tone.values[(settings.tone.index + 1) % Tone.values.length];
    settings.tone = next;
    _applyVoice();
    audio.play('pop', rate: 0.8 + next.index * 0.25);
    _showToast(next == Tone.pet ? pet.emoji : next.emoji);
  }

  Future<void> _gift() async {
    _petCtl.wake();
    if (settings.dressUpUnlocked) {
      final next = Accessory.values[(settings.accessory.index + 1) % Accessory.values.length];
      settings.accessory = next;
      audio.play(next == Accessory.none ? 'pop' : 'sparkle');
      _petCtl.burst(Fx.sparkles, const Offset(500, 250));
      return;
    }
    if (!await showParentGate(context, reason: 'Unlock dress-up hats')) return;
    if (!mounted) return;
    final watch = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Dress-up hats 🎩'),
        content: const Text('Watch a short video ad to unlock party hats, a crown, a bow and funny glasses for all pets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')),
          FilledButton(key: const Key('watch-ad'), onPressed: () => Navigator.pop(c, true), child: const Text('Watch video')),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    if (!ads.rewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No video is ready yet. Please try again in a minute.')));
      ads.loadRewarded();
      return;
    }
    final earned = await ads.showRewarded();
    if (!earned || !mounted) return;
    settings.dressUpUnlocked = true;
    settings.accessory = Accessory.partyHat;
    audio.play('sparkle');
    _petCtl.burst(Fx.sparkles, const Offset(500, 300));
  }

  Future<void> _grownups() async {
    if (!await showParentGate(context)) return;
    if (!mounted) return;
    _stopEcho();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GrownupsScreen()));
    _checkMic();
  }

  Future<void> _micTapped() async {
    if (_micGranted && settings.micOn) {
      _showToast('👂');
      return;
    }
    if (!await showParentGate(context, reason: 'Turn on listening')) return;
    settings.micOn = true;
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) await openAppSettings();
    _checkMic();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final sceneImage = ArtCache.instance.sceneFor(_pet);
        final groundY = sceneImage != null ? (artSpecs[_pet]?.sceneGroundY ?? 0.74) : 0.74;
        final top = mq.padding.top + (widget.showBanner ? 60 : 0) + 76;
        final stage = math.min(w * 0.96, (h * groundY - top) / 0.9);
        final stageTop = h * groundY - stage * 0.935;
        return Stack(children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: _sceneTime,
                builder: (_, t, _) => CustomPaint(painter: ScenePainter(_pet, t, groundY: groundY, image: sceneImage)),
              ),
            ),
          ),
          Positioned(
            left: (w - stage) / 2,
            top: stageTop,
            width: stage,
            height: stage,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: PetView(
                key: ValueKey(_pet),
                pet: pet,
                controller: _petCtl,
                accessory: settings.dressUpUnlocked ? settings.accessory : Accessory.none,
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              if (widget.showBanner) const Center(child: BannerSlot()),
              // Keep little fingers' targets well away from the ad.
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  _RoundButton(key: const Key('grownups'), onTap: _grownups, color: Colors.white70, child: const Icon(Icons.settings, color: Color(0xFF6B5B95))),
                  const Spacer(),
                  if (_muted) ...[
                    _RoundButton(
                      key: const Key('muted'),
                      onTap: audio.showVolumeControl,
                      color: const Color(0xFFFF5A5A),
                      child: const Icon(Icons.volume_off_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _MicBadge(key: const Key('mic'), state: _echo, enabled: _micGranted && settings.micOn, onTap: _micTapped),
                  const Spacer(),
                  _RoundButton(
                    key: const Key('tone'),
                    onTap: _cycleTone,
                    color: const Color(0xFFFFE066),
                    child: Text(settings.tone == Tone.pet ? pet.emoji : settings.tone.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 10),
                  _RoundButton(
                    key: const Key('gift'),
                    onTap: _gift,
                    color: const Color(0xFFFFB3D1),
                    child: Text(settings.dressUpUnlocked ? '👑' : '🎁', style: const TextStyle(fontSize: 26)),
                  ),
                ]),
              ),
              const Spacer(),
              _PetSwitcher(current: _pet, onPick: _switchPet),
              const SizedBox(height: 10),
            ]),
          ),
          if (_toast != null)
            Positioned(
              top: mq.padding.top + (widget.showBanner ? 60 : 0) + 88,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(30)),
                    child: Text(_toast!, style: const TextStyle(fontSize: 40)),
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.onTap, required this.child, required this.color});

  final VoidCallback onTap;
  final Widget child;
  final Color color;
  static const size = 54.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 3)),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
    );
  }
}

class _MicBadge extends StatelessWidget {
  const _MicBadge({super.key, required this.state, required this.enabled, required this.onTap});

  final EchoState state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = !enabled
        ? (Colors.grey, Icons.mic_off_rounded)
        : switch (state) {
            EchoState.hearing => (const Color(0xFFFF5A8A), Icons.hearing_rounded),
            EchoState.talking => (const Color(0xFF7C5CFF), Icons.record_voice_over_rounded),
            EchoState.listening => (const Color(0xFF2FB4FF), Icons.mic_rounded),
            _ => (Colors.grey, Icons.mic_none_rounded),
          };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(state == EchoState.hearing ? 14 : 10),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: state == EchoState.hearing ? 18 : 6)],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _PetSwitcher extends StatelessWidget {
  const _PetSwitcher({required this.current, required this.onPick});

  final PetKind current;
  final void Function(PetKind) onPick;

  @override
  Widget build(BuildContext context) {
    // Five pets must fit a 320 dp phone: size the buttons from the width.
    final w = MediaQuery.sizeOf(context).width;
    final slot = ((w - 16) / allPets.length).clamp(48.0, 96.0);
    final small = slot - 12, big = slot - 2;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final p in allPets)
        SizedBox(
          width: slot,
          child: Center(
            child: GestureDetector(
              key: Key('pick-${p.kind.name}'),
              onTap: () => onPick(p.kind),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: p.kind == current ? big : small,
                height: p.kind == current ? big : small,
                decoration: BoxDecoration(
                  color: p.kind == current ? Colors.white : Colors.white70,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.kind == current ? const Color(0xFFFFB02E) : Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.55,
                    alignment: const Alignment(0, -0.55),
                    child: CustomPaint(painter: painterFor(p.kind, const PetPose(mood: Mood.happy))),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
