import '../core/pets.dart';
import 'cat_painter.dart';
import 'parrot_painter.dart';
import 'rooster_painter.dart';
import 'toon.dart';

PetPainter painterFor(PetKind kind, PetPose pose) => switch (kind) {
      PetKind.cat => CatPainter(pose),
      PetKind.parrot => ParrotPainter(pose),
      PetKind.rooster => RoosterPainter(pose),
    };
