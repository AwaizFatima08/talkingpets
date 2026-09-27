#!/usr/bin/env python3
"""Synthesise TalkyPals' animal sounds into assets/sfx/*.wav (22.05 kHz, mono, 16-bit).

Nothing is downloaded: every sound is built from a harmonic "voice" whose
spectrum is shaped by moving formants (like a tiny vocal tract), plus
filtered noise for breath, hiss and feathers.

    python3 scripts/make_sfx.py
"""
import pathlib
import wave

import numpy as np
from scipy import signal

SR = 22050
OUT = pathlib.Path(__file__).resolve().parent.parent / "assets" / "sfx"
rng = np.random.default_rng(7)

# Vowel formants (F1, F2, F3) in Hz, roughly a small creature's vocal tract.
VOWELS = {
    "m": (300, 1100, 2600),
    "i": (420, 2500, 3400),
    "e": (600, 2100, 3100),
    "a": (950, 1600, 3000),
    "o": (650, 1050, 2900),
    "u": (380, 850, 2500),
    "r": (520, 1250, 1800),
}


def curve(points, n):
    """Piecewise-linear curve through (time_fraction, value) points, n samples."""
    xs, ys = zip(*points)
    return np.interp(np.linspace(0, 1, n), xs, ys)


def vowel_track(seq, n):
    """seq: list of (time_fraction, vowel) -> three formant-frequency arrays."""
    return [curve([(t, VOWELS[v][k]) for t, v in seq], n) for k in range(3)]


def voice(dur, f0_points, vowels, *, jitter=0.01, rough=0.0, rough_hz=40, breath=0.02,
          bw=(90, 130, 200), gains=(1.0, 0.7, 0.3), tilt=1.0, vibrato=(0, 0)):
    """Harmonic source with formant-weighted harmonics (additive source-filter)."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f0 = curve(f0_points, n)
    if vibrato[0]:
        f0 = f0 * (1 + vibrato[1] * np.sin(2 * np.pi * vibrato[0] * t))
    wobble = signal.lfilter([0.02], [1, -0.98], rng.standard_normal(n))
    f0 = f0 * (1 + jitter * wobble / (np.abs(wobble).max() + 1e-9))
    phase = 2 * np.pi * np.cumsum(f0) / SR
    formants = vowel_track(vowels, n)
    y = np.zeros(n)
    for k in range(1, 60):
        fk = k * f0
        live = fk < SR * 0.45
        if not live.any():
            break
        amp = np.zeros(n)
        for F, B, G in zip(formants, bw, gains):
            amp += G / (1 + ((fk - F) / B) ** 2)
        amp *= k ** -0.5 * tilt ** k
        y += np.where(live, amp * np.sin(k * phase), 0)
    if rough:
        y *= 1 - rough * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * rough_hz * t)))
    if breath:
        y += breath * np.abs(y).max() * bandpass(rng.standard_normal(n), 1500, 6000)
    return y


def bandpass(x, lo, hi, order=4):
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lowpass(x, hi, order=4):
    return signal.sosfilt(signal.butter(order, hi, fs=SR, output="sos"), x)


def env(n, attack=0.02, release=0.08, hold_curve=None):
    t = np.arange(n) / SR
    a = np.minimum(1, t / max(attack, 1e-4))
    r = np.minimum(1, (n / SR - t) / max(release, 1e-4))
    e = a * np.clip(r, 0, 1)
    if hold_curve is not None:
        e *= curve(hold_curve, n)
    return e


def shaped(y, attack=0.02, release=0.08, hold=None):
    return y * env(len(y), attack, release, hold)


def noise(dur):
    return rng.standard_normal(int(dur * SR))


def silence(dur):
    return np.zeros(int(dur * SR))


def seq(*parts):
    return np.concatenate(parts)


def mix(total, parts):
    y = np.zeros(int(total * SR))
    for start, sig in parts:
        i = int(start * SR)
        seg = sig[: len(y) - i]
        y[i : i + len(seg)] += seg
    return y


def norm(y, peak):
    return y / (np.abs(y).max() + 1e-9) * peak


def save(name, y, peak=0.8):
    y = norm(np.asarray(y, dtype=float), peak)
    fade = int(0.008 * SR)
    y[-fade:] *= np.linspace(1, 0, fade)
    y[:fade] *= np.linspace(0, 1, fade)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((y * 32767).astype(np.int16).tobytes())
    print(f"  {name:14s} {len(y) / SR:5.2f}s")


def sweep(f_points, dur, partials=((1, 1.0),)):
    n = int(dur * SR)
    f = curve(f_points, n)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return sum(a * np.sin(m * ph) for m, a in partials)


# ---------------------------------------------------------------- cat

def cat_sounds():
    # Meow: m -> i -> a -> u (the mouth opening and closing) with a pitch arch.
    meow = voice(0.85, [(0, 480), (0.3, 720), (0.7, 620), (1, 430)],
                 [(0, "m"), (0.12, "i"), (0.45, "a"), (0.8, "o"), (1, "u")], jitter=0.015)
    save("cat_meow", shaped(meow, 0.04, 0.18, [(0, 0.5), (0.2, 1), (0.8, 0.9), (1, 0.4)]))

    mew = voice(0.38, [(0, 750), (0.4, 980), (1, 820)], [(0, "i"), (0.5, "e"), (1, "u")])
    save("cat_mew", shaped(mew, 0.02, 0.1))

    # Mrrrp: rolling trill that rises (tummy rub).
    trill = voice(0.5, [(0, 380), (1, 620)], [(0, "m"), (0.3, "r"), (1, "a")], rough=0.8, rough_hz=28)
    save("cat_trill", shaped(trill, 0.02, 0.1))

    # Purr: low rumbling pulses, breathing in and out.
    dur = 2.2
    n = int(dur * SR)
    t = np.arange(n) / SR
    pulses = (0.5 + 0.5 * np.sin(2 * np.pi * 26 * t)) ** 4
    body = lowpass(noise(dur), 350) * 3 + 0.6 * np.sin(2 * np.pi * 52 * t)
    breathe = 0.55 + 0.45 * np.abs(np.sin(np.pi * t / 1.1))
    save("cat_purr", shaped(body * pulses * breathe, 0.15, 0.3), 0.75)

    # Hiss (tail): a soft, silly "pfffft" rather than a scary hiss.
    h = bandpass(noise(0.55), 2500, 7500) * env(int(0.55 * SR), 0.03, 0.25)
    pf = bandpass(noise(0.06), 200, 1500) * 2
    save("cat_hiss", seq(pf, h), 0.55)

    # Sneeze (nose): "ah... ah... CHOO!"
    ah1 = shaped(voice(0.22, [(0, 520), (1, 640)], [(0, "a"), (1, "a")]), 0.05, 0.06)
    ah2 = shaped(voice(0.26, [(0, 600), (1, 780)], [(0, "a"), (1, "a")]), 0.05, 0.06)
    choo_n = bandpass(noise(0.12), 1800, 6000) * env(int(0.12 * SR), 0.003, 0.08) * 2.5
    choo_v = shaped(voice(0.32, [(0, 900), (1, 560)], [(0, "i"), (0.3, "u"), (1, "u")]), 0.005, 0.2)
    choo = mix(0.34, [(0, choo_n), (0.02, choo_v)])
    save("cat_sneeze", seq(ah1, silence(0.12), ah2, silence(0.08), choo))

    # Happy "mrow?" question (ears).
    mrow = voice(0.5, [(0, 420), (0.6, 460), (1, 760)], [(0, "m"), (0.3, "a"), (1, "o")])
    save("cat_mrow", shaped(mrow, 0.03, 0.08))


# ---------------------------------------------------------------- parrot

def parrot_sounds():
    sq = voice(0.5, [(0, 820), (0.25, 1050), (1, 700)], [(0, "a"), (0.5, "e"), (1, "a")],
               jitter=0.06, rough=0.55, rough_hz=70, breath=0.25, bw=(160, 200, 300), tilt=0.99)
    save("parrot_squawk", shaped(sq, 0.01, 0.1))

    # Wolf whistle (head).
    w1 = sweep([(0, 1300), (1, 2900)], 0.28, ((1, 1), (2, 0.08)))
    w2 = sweep([(0, 1300), (0.35, 2800), (1, 1100)], 0.55, ((1, 1), (2, 0.08)))
    save("parrot_whistle", seq(shaped(w1, 0.02, 0.05), silence(0.12), shaped(w2, 0.02, 0.12)), 0.6)

    # Giggly chirps (tummy).
    chirps = mix(0.9, [(i * 0.13, shaped(sweep([(0, 2100 + 150 * i), (1, 3600 + 200 * i)], 0.08), 0.005, 0.03))
                       for i in range(6)])
    save("parrot_chirps", chirps, 0.6)

    # Feathers flapping (wings).
    dur = 0.75
    t = np.arange(int(dur * SR)) / SR
    flaps = np.clip(np.sin(2 * np.pi * 9 * t), 0, 1) ** 2
    save("wing_flap", bandpass(noise(dur), 350, 1800) * flaps * env(len(t), 0.02, 0.15), 0.7)

    # Beak clacks (beak).
    click = bandpass(noise(0.03), 1500, 5000) * env(int(0.03 * SR), 0.001, 0.02)
    tone = shaped(sweep([(0, 1800), (1, 1500)], 0.03), 0.001, 0.02) * 0.6
    c = click + tone
    save("beak_clack", mix(0.45, [(0, c), (0.12, c), (0.24, c * 1.2)]), 0.7)

    # Rising "brrrd?" (feet).
    br = voice(0.45, [(0, 900), (1, 1500)], [(0, "r"), (1, "i")], rough=0.7, rough_hz=32, jitter=0.03)
    save("parrot_brrd", shaped(br, 0.02, 0.08))


# ---------------------------------------------------------------- rooster

def rooster_sounds():
    rasp = dict(jitter=0.035, rough=0.35, rough_hz=45, breath=0.12, tilt=0.995)
    notes = [  # cock - a - doo - dle - doooooo
        (0.13, [(0, 520), (1, 560)], [(0, "o"), (1, "a")]),
        (0.09, [(0, 600), (1, 620)], [(0, "a"), (1, "a")]),
        (0.20, [(0, 700), (1, 760)], [(0, "u"), (1, "o")]),
        (0.14, [(0, 680), (1, 660)], [(0, "e"), (1, "e")]),
        (0.95, [(0, 760), (0.3, 820), (0.75, 760), (1, 520)], [(0, "u"), (0.3, "o"), (0.8, "o"), (1, "u")]),
    ]
    parts = []
    for i, (d, f0, v) in enumerate(notes):
        parts.append(shaped(voice(d, f0, v, **rasp), 0.012, 0.03 if i < 4 else 0.3))
        parts.append(silence(0.025))
    save("rooster_crow", seq(*parts))

    bok = lambda f=340: shaped(voice(0.1, [(0, f + 40), (1, f - 30)], [(0, "o"), (1, "u")], **rasp), 0.004, 0.05)
    save("hen_cluck", mix(0.62, [(0, bok()), (0.17, bok(330)), (0.34, bok(360))]))

    bawk = shaped(voice(0.42, [(0, 480), (0.3, 690), (1, 420)], [(0, "o"), (0.3, "a"), (1, "o")], **rasp), 0.01, 0.1)
    save("rooster_bawk", seq(bok(350), silence(0.07), bok(350), silence(0.07), bawk))

    # Peck peck (feet): woody taps.
    tap = lambda: bandpass(noise(0.025), 600, 2500) * env(int(0.025 * SR), 0.001, 0.02)
    save("peck", mix(0.5, [(0, tap()), (0.15, tap()), (0.3, tap())]), 0.7)

    # Surprised "b-KAWK?" rising (tail).
    kawk = shaped(voice(0.35, [(0, 500), (1, 900)], [(0, "a"), (1, "e")], **rasp), 0.005, 0.08)
    save("rooster_kawk", kawk)


# ---------------------------------------------------------------- shared

def shared_sounds():
    # Boing: springy wobble going up.
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    f = 180 + 240 * t / t[-1] + 60 * np.sin(2 * np.pi * 14 * t) * np.exp(-t / 0.2)
    ph = 2 * np.pi * np.cumsum(f) / SR
    save("boing", (np.sin(ph) + 0.3 * np.sin(2 * ph)) * env(n, 0.005, 0.2), 0.6)

    # Giggle: "hee hee hee".
    hee = lambda f: shaped(voice(0.09, [(0, f), (1, f * 0.85)], [(0, "i"), (1, "e")], breath=0.2), 0.005, 0.04)
    save("giggle", mix(0.7, [(i * 0.13, hee(1000 - 60 * i)) for i in range(5)]), 0.6)

    # Pop (tap feedback).
    n = int(0.1 * SR)
    t = np.arange(n) / SR
    f = 500 + 800 * np.exp(-t / 0.018)
    save("pop", np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.002, 0.05), 0.5)

    # Whoosh (switching pets).
    n = int(0.45 * SR)
    x = noise(0.45)
    lo = bandpass(x, 300, 900)
    hi = bandpass(x, 1500, 4000)
    mixc = np.linspace(0, 1, n)
    save("whoosh", (lo * (1 - mixc) + hi * mixc) * np.sin(np.pi * np.linspace(0, 1, n)) ** 2, 0.45)

    # Sparkle (a gift unlocked).
    bell = lambda fq: shaped(sweep([(0, fq), (1, fq)], 0.5, ((1, 1), (2, 0.2), (3, 0.05))), 0.004, 0.45)
    save("sparkle", mix(1.1, [(i * 0.08, bell(1046.5 * 2 ** (i * 4 / 12))) for i in range(6)]), 0.45)

    # Yawn (sleepy, when nobody plays for a while).
    y = voice(1.3, [(0, 420), (0.3, 520), (1, 300)], [(0, "a"), (0.5, "a"), (0.9, "o"), (1, "m")], breath=0.4)
    save("yawn", shaped(y, 0.2, 0.3), 0.6)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print(f"Writing to {OUT}")
    cat_sounds()
    parrot_sounds()
    rooster_sounds()
    shared_sounds()


if __name__ == "__main__":
    main()
