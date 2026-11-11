#!/usr/bin/env python3
"""Turn approved homidev pet art into small app assets.

Reads tool/pet_art.json, takes each pet's cut-outs from assets/images/pets/,
crops all poses with ONE shared box (so the poses stay aligned and frame swaps
don't jump), and writes assets/art/<pet>_<pose>.webp (512 px wide) plus
assets/art/<pet>_scene.webp (1024 px). The big raw PNGs are not shipped.

    python3 scripts/prep_art.py
"""
import json
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
PETS = ROOT / "assets" / "images" / "pets"
SCENES = ROOT / "assets" / "images" / "scenes"
OUT = ROOT / "assets" / "art"
POSES = ("idle", "talk", "happy", "surprised")


def main():
    spec = json.loads((ROOT / "tool" / "pet_art.json").read_text())
    OUT.mkdir(parents=True, exist_ok=True)
    for pet, jobs in spec.items():
        if pet.startswith("_"):
            continue
        cuts = {p: Image.open(PETS / f"{jobs[p]}_cutout.png").convert("RGBA") for p in POSES if p in jobs}
        if cuts:
            boxes = [im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox() for im in cuts.values()]
            l = min(b[0] for b in boxes); t = min(b[1] for b in boxes)
            r = max(b[2] for b in boxes); b_ = max(b[3] for b in boxes)
            # Square box around the union, feet at the bottom, centred.
            side = max(r - l, b_ - t) + 16
            cx = (l + r) / 2
            box = (int(cx - side / 2), int(b_ + 8 - side), int(cx + side / 2), int(b_ + 8))
            for pose, im in cuts.items():
                out = im.crop(box).resize((512, 512), Image.LANCZOS)
                out.save(OUT / f"{pet}_{pose}.webp", "WEBP", quality=88, method=6)
                print(f"  {pet}_{pose}.webp  {(OUT / f'{pet}_{pose}.webp').stat().st_size // 1024} KB")
        if "scene" in jobs:
            sc = Image.open(SCENES / f"{jobs['scene']}_raw.png").convert("RGB").resize((1024, 1024), Image.LANCZOS)
            sc.save(OUT / f"{pet}_scene.webp", "WEBP", quality=85, method=6)
            print(f"  {pet}_scene.webp  {(OUT / f'{pet}_scene.webp').stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
