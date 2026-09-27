#!/usr/bin/env python3
"""On-device touch test: taps every body part of every pet on a connected
phone (adb) and saves a contact sheet of the reactions.

    python3 tool/device_touch_test.py [out.png]

Assumes the play screen is open. Stage geometry mirrors PlayScreen.build.
"""
import subprocess, sys, time, io
from PIL import Image

PARTS = {
    "cat": [("nose", 500, 450), ("eyes", 412, 388), ("ears", 300, 200), ("head", 500, 250), ("cheeks", 320, 480),
            ("belly", 500, 780), ("tail", 835, 740), ("paws", 440, 905)],
    "parrot": [("beak", 500, 410), ("eyes", 568, 318), ("crest", 500, 90), ("head", 380, 250), ("wings", 330, 700),
               ("belly", 500, 700), ("feet", 455, 872), ("tail", 500, 960)],
    "rooster": [("comb", 500, 220), ("beak", 500, 415), ("wattle", 500, 490), ("eyes", 447, 345), ("head", 370, 330),
                ("wings", 300, 700), ("belly", 500, 700), ("feet", 455, 900), ("tail", 850, 340)],
}
PICKERS = {"cat": 0, "parrot": 1, "rooster": 2}


def sh(*a):
    return subprocess.run(["adb", "shell", *a], capture_output=True, text=True).stdout


def geometry():
    w_px, h_px = map(int, sh("wm", "size").split(":")[-1].split("x"))
    dens = int(sh("wm", "density").strip().split(":")[-1]) / 160
    w, h = w_px / dens, h_px / dens
    pad = 45 / dens  # display cutout inset seen in screenshots
    top = pad + 60 + 64
    stage = min(w * 0.96, (h * 0.74 - top) / 0.9)
    left, stage_top = (w - stage) / 2, h * 0.74 - stage * 0.935
    return dens, w, h, left, stage_top, stage


def shot():
    png = subprocess.run(["adb", "exec-out", "screencap", "-p"], capture_output=True).stdout
    return Image.open(io.BytesIO(png)).convert("RGB")


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "touch_sheet.png"
    dens, w, h, left, top, stage = geometry()
    s = stage / 1000
    to_px = lambda x, y: (int((left + x * s) * dens), int((top + y * s) * dens))
    tiles = []
    for pet, parts in PARTS.items():
        # Pet switcher: three buttons centred along the bottom.
        bx = int((w / 2 + (PICKERS[pet] - 1) * 96) * dens)
        by = int((h - 10 - 44) * dens)
        subprocess.run(["adb", "shell", "input", "tap", str(bx), str(by)])
        time.sleep(3.5)
        for name, x, y in parts:
            px, py = to_px(x, y)
            subprocess.run(["adb", "shell", "input", "tap", str(px), str(py)])
            time.sleep(0.35)
            im = shot()
            crop = im.crop((0, int((top - 40) * dens), int(w * dens), int((top + stage) * dens)))
            crop = crop.resize((crop.width // 3, crop.height // 3))
            tiles.append((f"{pet}:{name}", crop))
            time.sleep(1.4)
    cols = 8
    tw, th = tiles[0][1].size
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw, rows * (th + 16)), "white")
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    for i, (label, t) in enumerate(tiles):
        x, y = (i % cols) * tw, (i // cols) * (th + 16)
        sheet.paste(t, (x, y + 16))
        d.text((x + 4, y + 2), label, fill="black")
    sheet.save(out)
    print(f"saved {out} ({len(tiles)} taps)")


if __name__ == "__main__":
    main()
