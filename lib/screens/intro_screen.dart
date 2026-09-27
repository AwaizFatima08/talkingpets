import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/pets.dart';
import '../core/settings.dart';
import '../pets/pet_painters.dart';
import '../pets/toon.dart';
import 'play_screen.dart';

/// First launch: a short note for the grown-up, then the microphone prompt.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  Future<void> _start(BuildContext context) async {
    await Permission.microphone.request();
    Settings.instance.introSeen = true;
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PlayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(
                  height: 120,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final p in allPets)
                      Expanded(child: CustomPaint(painter: painterFor(p.kind, const PetPose(mood: Mood.happy)))),
                  ]),
                ),
                const SizedBox(height: 16),
                Text('TalkyPals', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFFFF7A3D))),
                const SizedBox(height: 16),
                Text('Talk to Mimi, Kiwi and Doodle and they repeat it in a funny voice! Tap their ears, noses, tummies and tails for silly sounds.',
                    textAlign: TextAlign.center, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [
                    Icon(Icons.lock_outline, color: Color(0xFF6B5B95)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'For grown-ups: the microphone is used only while the app is open. Sounds are played back straight away and never saved or sent. The app is free and shows ads suitable for children.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton.icon(
                    key: const Key('start'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF7A3D), textStyle: const TextStyle(fontFamily: 'Quicksand', fontSize: 20, fontWeight: FontWeight.w700)),
                    onPressed: () => _start(context),
                    icon: const Icon(Icons.mic),
                    label: const Text("Let's play!"),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
