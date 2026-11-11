import 'audio.dart';

enum PetKind { cat, parrot, rooster, puppy, elephant }

/// Touchable parts. Each pet uses the subset that it has.
enum BodyPart { head, ears, eyes, nose, beak, crest, comb, wattle, cheeks, belly, tail, wings, paws, feet, trunk }

/// Facial expression.
enum Mood { neutral, happy, laugh, surprised, dizzy, sleepy, grumpy, love, listening }

/// Whole-body animation played with a reaction.
enum Motion { bounce, squash, wiggle, jump, shake, flap, tall, wag, puff, nod }

/// Particles that burst out with a reaction.
enum Fx { hearts, notes, stars, sneeze, feathers, zzz, sparkles, bubbles }

class Reaction {
  const Reaction({this.sound, this.say, required this.mood, required this.motion, this.fx, this.rate = 1});

  /// Sound effect in assets/sfx (without .wav).
  final String? sound;

  /// Words spoken with text-to-speech (parrot); [sound] is the fallback.
  final String? say;
  final Mood mood;
  final Motion motion;
  final Fx? fx;

  /// Playback rate of [sound]; small random variation is added on top.
  final double rate;
}

/// Voice options the child can cycle through with the tone button.
enum Tone { pet, squeaky, deep, wobbly }

extension ToneInfo on Tone {
  String get emoji => switch (this) {
        Tone.pet => '',
        Tone.squeaky => '🐭',
        Tone.deep => '🐻',
        Tone.wobbly => '🌀',
      };

  String get label => switch (this) {
        Tone.pet => 'Pet voice',
        Tone.squeaky => 'Squeaky',
        Tone.deep => 'Big and deep',
        Tone.wobbly => 'Wobbly',
      };
}

class PetSpec {
  const PetSpec({
    required this.kind,
    required this.name,
    required this.emoji,
    required this.voice,
    required this.greeting,
    required this.reactions,
  });

  final PetKind kind;
  final String name;
  final String emoji;

  /// The pet's own voice for the echo.
  final VoiceSpec voice;

  /// Played when the pet appears.
  final Reaction greeting;
  final Map<BodyPart, List<Reaction>> reactions;

  Set<BodyPart> get parts => reactions.keys.toSet();

  VoiceSpec voiceFor(Tone tone) => switch (tone) {
        Tone.pet => voice,
        Tone.squeaky => const VoiceSpec(pitch: 2.1, vibratoHz: 6, vibratoDepth: 0.02),
        Tone.deep => const VoiceSpec(pitch: 0.72, vibratoHz: 3, vibratoDepth: 0.02),
        Tone.wobbly => const VoiceSpec(pitch: 1.35, vibratoHz: 5, vibratoDepth: 0.14),
      };
}

const cat = PetSpec(
  kind: PetKind.cat,
  name: 'Mimi',
  emoji: '🐱',
  voice: VoiceSpec(pitch: 1.55, vibratoHz: 5, vibratoDepth: 0.025),
  greeting: Reaction(sound: 'cat_meow', mood: Mood.happy, motion: Motion.bounce, fx: Fx.hearts),
  reactions: {
    BodyPart.head: [
      Reaction(sound: 'cat_purr', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
      Reaction(sound: 'cat_meow', mood: Mood.happy, motion: Motion.bounce, fx: Fx.hearts),
    ],
    BodyPart.ears: [
      Reaction(sound: 'cat_mrow', mood: Mood.surprised, motion: Motion.wiggle),
      Reaction(sound: 'cat_mew', mood: Mood.happy, motion: Motion.shake, rate: 1.1),
    ],
    BodyPart.eyes: [
      Reaction(sound: 'cat_mew', mood: Mood.dizzy, motion: Motion.wiggle, fx: Fx.stars),
    ],
    BodyPart.nose: [
      Reaction(sound: 'cat_sneeze', mood: Mood.surprised, motion: Motion.jump, fx: Fx.sneeze),
      Reaction(sound: 'boing', mood: Mood.laugh, motion: Motion.squash),
    ],
    BodyPart.cheeks: [
      Reaction(sound: 'cat_purr', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
    ],
    BodyPart.belly: [
      Reaction(sound: 'giggle', mood: Mood.laugh, motion: Motion.wiggle, fx: Fx.notes, rate: 1.2),
      Reaction(sound: 'cat_trill', mood: Mood.laugh, motion: Motion.squash, fx: Fx.bubbles),
    ],
    BodyPart.tail: [
      Reaction(sound: 'cat_hiss', mood: Mood.grumpy, motion: Motion.puff),
      Reaction(sound: 'cat_mrow', mood: Mood.surprised, motion: Motion.jump, rate: 1.2),
    ],
    BodyPart.paws: [
      Reaction(sound: 'cat_mew', mood: Mood.happy, motion: Motion.wag),
      Reaction(sound: 'boing', mood: Mood.laugh, motion: Motion.jump),
    ],
  },
);

const parrot = PetSpec(
  kind: PetKind.parrot,
  name: 'Kiwi',
  emoji: '🦜',
  voice: VoiceSpec(pitch: 1.8, vibratoHz: 9, vibratoDepth: 0.04, tremoloHz: 16, tremoloDepth: 0.25),
  greeting: Reaction(say: 'Hello!', sound: 'parrot_whistle', mood: Mood.happy, motion: Motion.flap, fx: Fx.notes),
  reactions: {
    BodyPart.crest: [
      Reaction(sound: 'parrot_whistle', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
      Reaction(sound: 'parrot_squawk', mood: Mood.surprised, motion: Motion.jump),
    ],
    BodyPart.head: [
      Reaction(say: 'Pretty bird!', sound: 'parrot_whistle', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
      Reaction(say: 'Peekaboo!', sound: 'parrot_chirps', mood: Mood.happy, motion: Motion.bounce),
    ],
    BodyPart.eyes: [
      Reaction(sound: 'parrot_squawk', mood: Mood.dizzy, motion: Motion.wiggle, fx: Fx.stars),
    ],
    BodyPart.beak: [
      Reaction(say: 'Hello!', sound: 'beak_clack', mood: Mood.happy, motion: Motion.nod),
      Reaction(say: 'Cracker please!', sound: 'beak_clack', mood: Mood.laugh, motion: Motion.bounce),
      Reaction(sound: 'beak_clack', mood: Mood.grumpy, motion: Motion.shake),
    ],
    BodyPart.belly: [
      Reaction(sound: 'parrot_chirps', mood: Mood.laugh, motion: Motion.wiggle, fx: Fx.notes),
      Reaction(sound: 'giggle', mood: Mood.laugh, motion: Motion.squash, rate: 1.4),
    ],
    BodyPart.wings: [
      Reaction(sound: 'wing_flap', mood: Mood.happy, motion: Motion.flap, fx: Fx.feathers),
      Reaction(sound: 'parrot_squawk', mood: Mood.surprised, motion: Motion.flap, fx: Fx.feathers),
    ],
    BodyPart.tail: [
      Reaction(sound: 'parrot_squawk', mood: Mood.surprised, motion: Motion.jump, fx: Fx.feathers),
    ],
    BodyPart.feet: [
      Reaction(sound: 'parrot_brrd', mood: Mood.happy, motion: Motion.jump),
      Reaction(say: 'I love you!', sound: 'parrot_chirps', mood: Mood.love, motion: Motion.bounce, fx: Fx.hearts),
    ],
  },
);

const rooster = PetSpec(
  kind: PetKind.rooster,
  name: 'Doodle',
  emoji: '🐓',
  voice: VoiceSpec(pitch: 1.3, vibratoHz: 7, vibratoDepth: 0.07),
  greeting: Reaction(sound: 'rooster_crow', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
  reactions: {
    BodyPart.comb: [
      Reaction(sound: 'rooster_crow', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
      Reaction(sound: 'rooster_kawk', mood: Mood.surprised, motion: Motion.jump),
    ],
    BodyPart.head: [
      Reaction(sound: 'hen_cluck', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
      Reaction(sound: 'rooster_crow', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
    ],
    BodyPart.eyes: [
      Reaction(sound: 'rooster_kawk', mood: Mood.dizzy, motion: Motion.wiggle, fx: Fx.stars),
    ],
    BodyPart.beak: [
      Reaction(sound: 'peck', mood: Mood.happy, motion: Motion.nod),
      Reaction(sound: 'hen_cluck', mood: Mood.grumpy, motion: Motion.shake),
    ],
    BodyPart.wattle: [
      Reaction(sound: 'rooster_bawk', mood: Mood.laugh, motion: Motion.wiggle),
    ],
    BodyPart.belly: [
      Reaction(sound: 'hen_cluck', mood: Mood.laugh, motion: Motion.wiggle, fx: Fx.notes, rate: 1.25),
      Reaction(sound: 'giggle', mood: Mood.laugh, motion: Motion.squash, rate: 0.9),
    ],
    BodyPart.wings: [
      Reaction(sound: 'wing_flap', mood: Mood.happy, motion: Motion.flap, fx: Fx.feathers, rate: 0.85),
      Reaction(sound: 'rooster_bawk', mood: Mood.surprised, motion: Motion.flap, fx: Fx.feathers),
    ],
    BodyPart.tail: [
      Reaction(sound: 'rooster_kawk', mood: Mood.surprised, motion: Motion.jump, fx: Fx.feathers),
    ],
    BodyPart.feet: [
      Reaction(sound: 'peck', mood: Mood.happy, motion: Motion.wag, rate: 0.8),
      Reaction(sound: 'boing', mood: Mood.laugh, motion: Motion.jump),
    ],
  },
);

const puppy = PetSpec(
  kind: PetKind.puppy,
  name: 'Biscuit',
  emoji: '🐶',
  voice: VoiceSpec(pitch: 1.45, vibratoHz: 8, vibratoDepth: 0.05),
  greeting: Reaction(sound: 'dog_woof', mood: Mood.happy, motion: Motion.wag, fx: Fx.hearts),
  reactions: {
    BodyPart.head: [
      Reaction(sound: 'dog_pant', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
      Reaction(sound: 'dog_woof', mood: Mood.happy, motion: Motion.bounce),
    ],
    BodyPart.ears: [
      Reaction(sound: 'dog_yip', mood: Mood.happy, motion: Motion.shake),
      Reaction(sound: 'dog_whimper', mood: Mood.surprised, motion: Motion.wiggle),
    ],
    BodyPart.eyes: [
      Reaction(sound: 'dog_yip', mood: Mood.dizzy, motion: Motion.wiggle, fx: Fx.stars),
    ],
    BodyPart.nose: [
      Reaction(sound: 'cat_sneeze', mood: Mood.surprised, motion: Motion.jump, fx: Fx.sneeze, rate: 0.85),
      Reaction(sound: 'boing', mood: Mood.laugh, motion: Motion.squash),
    ],
    BodyPart.cheeks: [
      Reaction(sound: 'dog_pant', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
    ],
    BodyPart.belly: [
      Reaction(sound: 'giggle', mood: Mood.laugh, motion: Motion.wiggle, fx: Fx.notes, rate: 1.1),
      Reaction(sound: 'dog_pant', mood: Mood.laugh, motion: Motion.squash, fx: Fx.bubbles),
    ],
    BodyPart.tail: [
      Reaction(sound: 'dog_woof', mood: Mood.happy, motion: Motion.wag, fx: Fx.hearts),
      Reaction(sound: 'dog_yip', mood: Mood.surprised, motion: Motion.jump),
    ],
    BodyPart.paws: [
      Reaction(sound: 'dog_woof', mood: Mood.happy, motion: Motion.wag),
      Reaction(sound: 'boing', mood: Mood.laugh, motion: Motion.jump),
    ],
  },
);

const elephant = PetSpec(
  kind: PetKind.elephant,
  name: 'Peanut',
  emoji: '🐘',
  voice: VoiceSpec(pitch: 0.82, vibratoHz: 5, vibratoDepth: 0.06),
  greeting: Reaction(sound: 'elephant_trumpet', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
  reactions: {
    BodyPart.trunk: [
      Reaction(sound: 'elephant_trumpet', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
      Reaction(sound: 'elephant_spray', mood: Mood.laugh, motion: Motion.shake, fx: Fx.sneeze),
    ],
    BodyPart.ears: [
      Reaction(sound: 'wing_flap', mood: Mood.happy, motion: Motion.flap, rate: 0.6),
      Reaction(sound: 'elephant_toot', mood: Mood.surprised, motion: Motion.flap),
    ],
    BodyPart.head: [
      Reaction(sound: 'elephant_rumble', mood: Mood.love, motion: Motion.nod, fx: Fx.hearts),
      Reaction(sound: 'elephant_trumpet', mood: Mood.happy, motion: Motion.tall, fx: Fx.notes),
    ],
    BodyPart.eyes: [
      Reaction(sound: 'elephant_toot', mood: Mood.dizzy, motion: Motion.wiggle, fx: Fx.stars),
    ],
    BodyPart.belly: [
      Reaction(sound: 'giggle', mood: Mood.laugh, motion: Motion.wiggle, fx: Fx.notes, rate: 0.8),
      Reaction(sound: 'elephant_rumble', mood: Mood.laugh, motion: Motion.squash, fx: Fx.bubbles),
    ],
    BodyPart.feet: [
      Reaction(sound: 'stomp', mood: Mood.happy, motion: Motion.jump),
      Reaction(sound: 'stomp', mood: Mood.laugh, motion: Motion.bounce, rate: 1.2),
    ],
    BodyPart.tail: [
      Reaction(sound: 'elephant_toot', mood: Mood.surprised, motion: Motion.jump),
    ],
  },
);

const allPets = [cat, parrot, rooster, puppy, elephant];

PetSpec petOf(PetKind kind) => allPets.firstWhere((p) => p.kind == kind);

/// Every sound effect the app uses (preloaded at start-up).
List<String> allSfxNames() {
  final names = <String>{'pop', 'whoosh', 'sparkle', 'yawn', 'boing', 'giggle'};
  for (final p in allPets) {
    if (p.greeting.sound != null) names.add(p.greeting.sound!);
    for (final list in p.reactions.values) {
      for (final r in list) {
        if (r.sound != null) names.add(r.sound!);
      }
    }
  }
  return names.toList()..sort();
}
