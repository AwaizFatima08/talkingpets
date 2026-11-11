import '../core/pets.dart';
import 'cat_painter.dart';
import 'elephant_painter.dart';
import 'parrot_painter.dart';
import 'pet_art.dart';
import 'puppy_painter.dart';
import 'rooster_painter.dart';
import 'toon.dart';

/// The 3D picture painter when the pet's art is loaded, otherwise the drawn pet.
PetPainter painterFor(PetKind kind, PetPose pose) {
  final art = ArtCache.instance.posesFor(kind);
  final spec = artSpecs[kind];
  if (art != null && spec != null) return ArtPetPainter(pose, spec, art);
  return drawnPainterFor(kind, pose);
}

PetPainter drawnPainterFor(PetKind kind, PetPose pose) => switch (kind) {
      PetKind.cat => CatPainter(pose),
      PetKind.parrot => ParrotPainter(pose),
      PetKind.rooster => RoosterPainter(pose),
      PetKind.puppy => PuppyPainter(pose),
      PetKind.elephant => ElephantPainter(pose),
    };
