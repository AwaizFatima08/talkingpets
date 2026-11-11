import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/pets.dart';
import 'toon.dart';

/// The 3D pictures a pet can switch between (made on homidev, prepared by
/// scripts/prep_art.py into `assets/art/<pet>_<pose>.webp`).
enum ArtPose { idle, talk, happy, surprised }

/// Where things are on a pet's 3D picture, in the same 1000x1000 canvas the
/// drawn pets use (the picture fills the canvas, feet at the bottom).
class ArtSpec {
  const ArtSpec({required this.feet, required this.anchors, required this.regions, this.sceneGroundY = 0.8});

  final Offset feet;
  final HeadAnchors anchors;

  /// Touch regions in priority order (small parts first).
  final List<(BodyPart, List<(Offset, double, double)>)> regions;

  /// Where the pet stands on its 3D scene (fraction of the screen height).
  final double sceneGroundY;
}

/// Pets that have approved 3D art. A pet missing here (or whose pictures fail
/// to load) keeps its drawn version.
const artSpecs = <PetKind, ArtSpec>{
  PetKind.cat: ArtSpec(
    feet: Offset(470, 975),
    anchors: HeadAnchors(top: Offset(450, 120), eyeLeft: Offset(355, 295), eyeRight: Offset(575, 295), eyeRadius: 50, width: 520),
    regions: [
      (BodyPart.nose, [(Offset(470, 355), 42, 34)]),
      (BodyPart.eyes, [(Offset(355, 295), 60, 60), (Offset(575, 295), 60, 60)]),
      (BodyPart.ears, [(Offset(230, 120), 85, 95), (Offset(660, 120), 85, 95)]),
      (BodyPart.cheeks, [(Offset(290, 420), 75, 60), (Offset(650, 420), 75, 60)]),
      (BodyPart.head, [(Offset(470, 310), 275, 230)]),
      (BodyPart.paws, [(Offset(310, 945), 70, 50), (Offset(420, 950), 60, 45), (Offset(580, 950), 60, 45), (Offset(680, 945), 70, 50)]),
      (BodyPart.tail, [(Offset(800, 790), 90, 110)]),
      (BodyPart.belly, [(Offset(470, 720), 230, 230)]),
    ],
  ),
};

/// Decoded pictures, loaded once at start-up.
class ArtCache {
  ArtCache._();
  static final instance = ArtCache._();

  final _poses = <PetKind, Map<ArtPose, ui.Image>>{};
  final _scenes = <PetKind, ui.Image>{};

  Map<ArtPose, ui.Image>? posesFor(PetKind kind) => _poses[kind];
  ui.Image? sceneFor(PetKind kind) => _scenes[kind];

  Future<void> load() async {
    for (final kind in artSpecs.keys) {
      try {
        final poses = <ArtPose, ui.Image>{};
        for (final pose in ArtPose.values) {
          poses[pose] = await _decode('assets/art/${kind.name}_${pose.name}.webp');
        }
        _poses[kind] = poses;
        _scenes[kind] = await _decode('assets/art/${kind.name}_scene.webp');
      } catch (e) {
        debugPrint('[art] ${kind.name}: $e (keeping the drawn pet)');
        _poses.remove(kind);
      }
    }
  }

  static Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }
}

/// Paints a pet from its 3D pictures, picking the picture from the mood and
/// mouth, with the same bounce/squash/lean as the drawn pets.
class ArtPetPainter extends PetPainter {
  ArtPetPainter(super.pose, this.spec, this.images);

  final ArtSpec spec;
  final Map<ArtPose, ui.Image> images;

  @override
  Offset get feet => spec.feet;

  @override
  HeadAnchors get anchors => spec.anchors;

  ArtPose get artPose {
    if (pose.mouth > 0.3) return ArtPose.talk;
    return switch (pose.mood) {
      Mood.happy || Mood.laugh || Mood.love || Mood.sleepy => ArtPose.happy,
      Mood.surprised || Mood.dizzy => ArtPose.surprised,
      _ => ArtPose.idle,
    };
  }

  @override
  void draw(Canvas c) {
    final img = images[artPose]!;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    withHead(c, Offset(spec.feet.dx, 620), () {
      c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          const Rect.fromLTWH(0, 0, 1000, 1000), paint);
      drawAccessory(c, pose.accessory, anchors);
    });
  }

  @override
  List<(BodyPart, Path)> get hitRegions => [
        for (final (part, ovals) in spec.regions)
          (part, unionOf([for (final (c, rx, ry) in ovals) ovalPath(c, rx, ry)])),
      ];
}
