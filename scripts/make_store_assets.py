#!/usr/bin/env python3
"""Build the Play Store graphics and launcher icons from the approved 3D art.

Inputs:  assets/images/pets/*_cutout.png (via tool/pet_art.json),
         assets/art/<pet>_happy.webp, store-assets/screenshots/raw/<pet>.png
         (1080x2400 emulator captures from a TP_STORE_SHOTS build).
Outputs: store-assets/icon-512.png, store-assets/feature-graphic-1024x500.png,
         store-assets/captioned/{en,ur}/NN_<pet>.png (1080x1920),
         android launcher icons (legacy mipmaps + adaptive foregrounds).

    python3 scripts/make_store_assets.py
"""
import json
import pathlib

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
STORE = ROOT / "store-assets"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
BOLD = str(ROOT / "assets" / "fonts" / "Quicksand-Bold.ttf")
URDU = "/usr/share/fonts/truetype/noto/NotoNastaliqUrdu-Bold.ttf"
ICON_BG = (0xFF, 0xC4, 0x5E)

# (pet, English caption, Urdu caption, band colours top->bottom)
SHOTS = [
    ("cat", "Cuddle Mimi\nthe kitten!", "ممی بلی کو پیار کریں!", ((255, 138, 101), (240, 98, 146))),
    ("parrot", "Kiwi repeats\nwhat you say!", "کیوی آپ کی بات دہراتا ہے!", ((102, 187, 106), (38, 166, 154))),
    ("rooster", "Doodle crows\non the farm!", "ڈوڈل مرغا بانگ دیتا ہے!", ((255, 167, 38), (239, 83, 80))),
    ("puppy", "NEW: Biscuit\nthe puppy!", "نیا دوست: پپی بسکٹ!", ((66, 165, 245), (126, 87, 194))),
    ("elephant", "NEW: Peanut\nthe elephant!", "نیا دوست: ہاتھی پی نٹ!", ((255, 202, 40), (255, 112, 67))),
]


def gradient(size, top, bottom):
    w, h = size
    g = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        g.putpixel((0, y), tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    return g.resize(size)


def shadowed_text(img, xy, text, font, fill=(255, 255, 255), anchor="mm", **kw):
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((xy[0] + 4, xy[1] + 6), text, font=font, fill=(0, 0, 0, 110), anchor=anchor, align="center", **kw)
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))
    ImageDraw.Draw(img).text(xy, text, font=font, fill=fill, anchor=anchor, align="center", **kw)


def cat_face():
    """The happy 3D cat's head and shoulders, high-res, transparent."""
    job = json.loads((ROOT / "tool" / "pet_art.json").read_text())["cat"]["happy"]
    im = Image.open(ROOT / "assets" / "images" / "pets" / f"{job}_cutout.png").convert("RGBA")
    l, t, r, b = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    side = r - l
    return im.crop((l, t - side * 0.04, r, t + side * 0.96))


def icons():
    face = cat_face()
    # Store icon: full square, face fills most of it.
    icon = Image.new("RGBA", (512, 512), ICON_BG + (255,))
    f = face.resize((470, 470), Image.LANCZOS)
    icon.alpha_composite(f, (21, 40))
    icon.convert("RGB").save(STORE / "icon-512.png")
    # Adaptive foreground: keep the face inside the 66/108 safe zone.
    for dpi, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        fg = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        s = int(px * 0.68)
        fg.alpha_composite(face.resize((s, s), Image.LANCZOS), ((px - s) // 2, int(px * 0.18)))
        fg.save(RES / f"drawable-{dpi}" / "ic_launcher_foreground.png")
    # Legacy launcher icons (pre-Android 8): round-cornered square.
    for dpi, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        big = icon.resize((px, px), Image.LANCZOS)
        mask = Image.new("L", (px, px), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, px - 1, px - 1), radius=px // 5, fill=255)
        out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        out.paste(big, (0, 0), mask)
        out.save(RES / f"mipmap-{dpi}" / "ic_launcher.png")


def feature_graphic():
    W, H = 1024, 500
    fg = gradient((W, H), (255, 214, 140), (255, 150, 120)).convert("RGBA")
    bubbles = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(bubbles)
    for x, y, r in ((90, 70, 60), (930, 90, 80), (820, 30, 40), (200, 150, 30)):
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, 60))
    fg.alpha_composite(bubbles)
    shadowed_text(fg, (W // 2, 78), "TalkyPals", ImageFont.truetype(BOLD, 104))
    shadowed_text(fg, (W // 2, 160), "Talking 3D pets for little ones!", ImageFont.truetype(BOLD, 40))
    pets = ["parrot", "cat", "elephant", "puppy", "rooster"]
    sizes = {"cat": 300, "elephant": 300, "puppy": 290, "parrot": 260, "rooster": 270}
    xs = [110, 300, 512, 724, 914]
    for pet, x in zip(pets, xs):
        p = Image.open(ROOT / "assets" / "art" / f"{pet}_happy.webp").convert("RGBA")
        s = sizes[pet]
        p = p.resize((s, s), Image.LANCZOS)
        fg.alpha_composite(p, (x - s // 2, H - s + 8))
    fg.convert("RGB").save(STORE / "feature-graphic-1024x500.png")


def screenshots():
    W, H, BAND = 1080, 1920, 330
    raw = STORE / "screenshots" / "raw"
    for lang, font, size in (("en", BOLD, 92), ("ur", URDU, 76)):
        out_dir = STORE / "captioned" / lang
        out_dir.mkdir(parents=True, exist_ok=True)
        for i, (pet, en, ur, (c1, c2)) in enumerate(SHOTS, 1):
            shot = Image.open(raw / f"{pet}.png").convert("RGB")
            # Keep the pet, its scene and the pet switcher; drop the top buttons.
            crop = shot.crop((0, shot.height - (H - BAND), W, shot.height))
            img = Image.new("RGBA", (W, H))
            img.paste(crop, (0, BAND))
            img.paste(gradient((W, BAND), c1, c2), (0, 0))
            # Soft wave edge between caption band and screenshot.
            d = ImageDraw.Draw(img)
            for k in range(0, W + 90, 90):
                d.ellipse((k - 60, BAND - 30, k + 60, BAND + 30), fill=c2)
            f = ImageFont.truetype(font, size)
            if lang == "en":
                shadowed_text(img, (W // 2, BAND // 2 - 4), en, f, spacing=8)
            else:
                shadowed_text(img, (W // 2, BAND // 2 - 10), ur, f, direction="rtl", language="ur")
            img.convert("RGB").save(out_dir / f"{i:02d}_{pet}.png")


if __name__ == "__main__":
    icons()
    feature_graphic()
    screenshots()
    print("store assets written to", STORE)
