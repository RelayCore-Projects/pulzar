#!/usr/bin/env python3
"""Pulzar alkalmazásikon generálása (ADR-008, „C” változat: piros szív EKG-vonallal, sötét háttéren).

Futtatás a repó gyökeréből:  python3 tool/generate_icons.py   (Pillow kell hozzá)
Kimenet:
  assets/branding/pulzar-icon-1024.png                 – forráskép / áttekintés
  android/app/src/main/res/mipmap-*/ic_launcher.png    – régi stílusú (kerek) ikon
  android/app/src/main/res/mipmap-*/ic_launcher_foreground.png – adaptív ikon előtere
  android/app/src/main/res/mipmap-*/ic_launcher_monochrome.png – Android 13+ témázott ikon
  android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
  android/app/src/main/res/values/ic_launcher_background.xml
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw

BACKGROUND = (32, 26, 30)      # #201A1E
HEART = (214, 48, 66)          # #D63042
LINE = (255, 255, 255)
SS = 4                         # túlmintavételezés az élsimításhoz

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}


def heart_points(cx, cy, scale, steps=720):
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * scale, cy - y * scale))
    return pts


def ecg_points(x0, x1, y, amp):
    rel = [(0, 0), (0.30, 0), (0.36, -0.15), (0.42, 0), (0.47, 0), (0.52, 0.45),
           (0.58, -1.0), (0.64, 0.35), (0.69, 0), (0.76, 0), (0.82, -0.22), (0.88, 0), (1, 0)]
    w = x1 - x0
    return [(x0 + w * a, y + amp * b) for a, b in rel]


def stroke(draw, pts, width, fill):
    draw.line(pts, fill=fill, width=int(width), joint="curve")
    r = width / 2
    for x, y in (pts[0], pts[-1]):
        draw.ellipse((x - r, y - r, x + r, y + r), fill=fill)


def symbol(size, heart_width_ratio, heart_fill, line_fill, background=None):
    """A szív + EKG szimbólum egy size×size képen; a szív szélessége = size × heart_width_ratio."""
    s = size * SS
    img = Image.new("RGBA", (s, s), background + (255,) if background else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    scale = s * heart_width_ratio / 32
    cx = s / 2
    cy = s / 2 - 2.5 * scale          # a szív függőleges közepe a kép közepén
    d.polygon(heart_points(cx, cy, scale), fill=heart_fill)
    half = 13.3 * scale
    stroke(d, ecg_points(cx - half, cx + half, cy - 0.8 * scale, 5.95 * scale), 1.68 * scale, line_fill)
    return img.resize((size, size), Image.LANCZOS)


def circle_mask(img):
    s = img.size[0]
    m = Image.new("L", (s * SS, s * SS), 0)
    ImageDraw.Draw(m).ellipse((0, 0, s * SS - 1, s * SS - 1), fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), m.resize(img.size, Image.LANCZOS))
    return out


def main():
    (ROOT / "assets/branding").mkdir(parents=True, exist_ok=True)
    symbol(1024, 0.58, HEART, LINE, BACKGROUND).save(ROOT / "assets/branding/pulzar-icon-1024.png")

    for name, k in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        # régi stílusú ikon: 48 dp, kerek
        circle_mask(symbol(round(48 * k), 0.58, HEART, LINE, BACKGROUND)).save(folder / "ic_launcher.png")
        # adaptív előtér: 108 dp vászon, a szimbólum a 66 dp-s biztonságos zónán belül
        symbol(round(108 * k), 0.40, HEART, LINE).save(folder / "ic_launcher_foreground.png")
        # témázott (egyszínű) ikon: fehér szív, az EKG-vonal kivágva
        symbol(round(108 * k), 0.40, (255, 255, 255, 255), (0, 0, 0, 0)).save(folder / "ic_launcher_monochrome.png")

    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(exist_ok=True)
    (anydpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
        '</adaptive-icon>\n', encoding="utf-8")
    (RES / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">#201A1E</color>\n'
        '</resources>\n', encoding="utf-8")
    print("Ikonok elkészültek.")


if __name__ == "__main__":
    main()
