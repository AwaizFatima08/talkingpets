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
  PetKind.parrot: ArtSpec(
    feet: Offset(530, 970),
    anchors: HeadAnchors(top: Offset(530, 150), eyeLeft: Offset(420, 320), eyeRight: Offset(690, 310), eyeRadius: 50, width: 460),
    regions: [
      (BodyPart.crest, [(Offset(530, 75), 85, 70)]),
      (BodyPart.beak, [(Offset(570, 370), 65, 70)]),
      (BodyPart.eyes, [(Offset(420, 320), 55, 55), (Offset(690, 310), 50, 55)]),
      (BodyPart.feet, [(Offset(420, 940), 60, 45), (Offset(650, 930), 65, 45)]),
      (BodyPart.tail, [(Offset(230, 860), 70, 50)]),
      (BodyPart.wings, [(Offset(295, 670), 80, 140), (Offset(785, 650), 40, 120)]),
      (BodyPart.head, [(Offset(530, 320), 250, 220)]),
      (BodyPart.belly, [(Offset(530, 730), 220, 200)]),
    ],
  ),
  PetKind.rooster: ArtSpec(
    feet: Offset(600, 975),
    anchors: HeadAnchors(top: Offset(650, 170), eyeLeft: Offset(620, 300), eyeRight: Offset(750, 300), eyeRadius: 40, width: 360),
    regions: [
      (BodyPart.comb, [(Offset(620, 100), 110, 85)]),
      (BodyPart.beak, [(Offset(690, 355), 65, 50)]),
      (BodyPart.wattle, [(Offset(695, 460), 80, 60)]),
      (BodyPart.eyes, [(Offset(620, 305), 45, 45), (Offset(750, 300), 40, 45)]),
      (BodyPart.feet, [(Offset(500, 940), 75, 45), (Offset(700, 935), 85, 45)]),
      (BodyPart.tail, [(Offset(260, 480), 140, 170)]),
      (BodyPart.wings, [(Offset(370, 640), 90, 90)]),
      (BodyPart.head, [(Offset(650, 310), 200, 170)]),
      (BodyPart.belly, [(Offset(630, 720), 230, 190)]),
    ],
  ),
  PetKind.puppy: ArtSpec(
    feet: Offset(520, 980),
    anchors: HeadAnchors(top: Offset(530, 90), eyeLeft: Offset(420, 265), eyeRight: Offset(645, 260), eyeRadius: 50, width: 460),
    regions: [
      (BodyPart.nose, [(Offset(550, 345), 70, 50)]),
      (BodyPart.eyes, [(Offset(420, 265), 55, 50), (Offset(645, 260), 55, 50)]),
      (BodyPart.ears, [(Offset(200, 320), 90, 190), (Offset(830, 300), 80, 190)]),
      (BodyPart.cheeks, [(Offset(360, 410), 60, 50), (Offset(700, 410), 60, 50)]),
      (BodyPart.paws, [(Offset(300, 925), 65, 45), (Offset(440, 950), 65, 40), (Offset(630, 950), 65, 40), (Offset(725, 915), 55, 45)]),
      (BodyPart.tail, [(Offset(165, 760), 60, 110)]),
      (BodyPart.head, [(Offset(530, 300), 240, 230)]),
      (BodyPart.belly, [(Offset(530, 720), 200, 180)]),
    ],
  ),
  PetKind.elephant: ArtSpec(
    feet: Offset(520, 985),
    anchors: HeadAnchors(top: Offset(510, 215), eyeLeft: Offset(420, 445), eyeRight: Offset(645, 445), eyeRadius: 45, width: 420),
    regions: [
      (BodyPart.trunk, [(Offset(530, 560), 55, 55), (Offset(555, 640), 50, 50), (Offset(595, 715), 50, 50), (Offset(620, 760), 45, 45)]),
      (BodyPart.eyes, [(Offset(420, 445), 45, 45), (Offset(645, 445), 45, 45)]),
      (BodyPart.ears, [(Offset(160, 410), 150, 200), (Offset(850, 420), 140, 200)]),
      (BodyPart.feet, [(Offset(255, 895), 80, 90), (Offset(780, 895), 80, 90), (Offset(445, 960), 80, 35), (Offset(605, 960), 80, 35)]),
      (BodyPart.head, [(Offset(510, 390), 210, 190)]),
      (BodyPart.belly, [(Offset(510, 800), 170, 140)]),
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
