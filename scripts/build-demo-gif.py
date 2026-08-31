#!/usr/bin/env python3
"""Build README demo GIF: laptop animation + branding outro (logo, name, tagline)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "docs" / "assets"
SOURCE_GIF = ASSETS / "magsafe-guard-source.gif"
OUTPUT_GIF = ASSETS / "magsafe-guard.gif"
LOGO = ASSETS / "logo-256.png"
WORK = ROOT / ".build" / "demo-gif"

WIDTH = 960
HEIGHT = 540
OUTRO_SECONDS = 2.5
FPS = 12


def _font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def render_outro_frame() -> Path:
    WORK.mkdir(parents=True, exist_ok=True)
    out = WORK / "outro-frame.png"

    canvas = Image.new("RGB", (WIDTH, HEIGHT), "white")
    logo = Image.open(LOGO).convert("RGB")
    logo_size = 160
    logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)

    x = (WIDTH - logo_size) // 2
    y = 110
    canvas.paste(logo, (x, y))

    draw = ImageDraw.Draw(canvas)
    title_font = _font(46, bold=True)
    sub_font = _font(26)

    title = "MagSafe Guard"
    subtitle = "Your Mac's Security Guardian"
    title_color = "#2d3748"
    sub_color = "#718096"

    title_box = draw.textbbox((0, 0), title, font=title_font)
    title_w = title_box[2] - title_box[0]
    draw.text(((WIDTH - title_w) // 2, y + logo_size + 28), title, fill=title_color, font=title_font)

    sub_box = draw.textbbox((0, 0), subtitle, font=sub_font)
    sub_w = sub_box[2] - sub_box[0]
    draw.text(((WIDTH - sub_w) // 2, y + logo_size + 88), subtitle, fill=sub_color, font=sub_font)

    canvas.save(out)
    return out


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True)


def main() -> int:
    if not SOURCE_GIF.exists():
        print("Extracting source GIF from git (afe8eff)...", file=sys.stderr)
        ASSETS.mkdir(parents=True, exist_ok=True)
        with SOURCE_GIF.open("wb") as handle:
            subprocess.run(
                ["git", "show", "afe8eff:docs/assets/magsafe-guard.gif"],
                check=True,
                stdout=handle,
                cwd=ROOT,
            )
    if not LOGO.exists():
        print(f"Missing logo: {LOGO}", file=sys.stderr)
        return 1

    WORK.mkdir(parents=True, exist_ok=True)
    main_gif = WORK / "main.gif"
    outro_gif = WORK / "outro.gif"
    outro_png = render_outro_frame()

    # Trim upstream title cards (Mac App Store frames at start/end).
    run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(SOURCE_GIF),
            "-vf",
            "select='between(n,10,145)',setpts=N/FRAME_RATE/TB,"
            f"scale={WIDTH}:-1:flags=lanczos,fps={FPS},"
            "split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer",
            str(main_gif),
        ]
    )

    run(
        [
            "ffmpeg",
            "-y",
            "-loop",
            "1",
            "-framerate",
            str(FPS),
            "-t",
            str(OUTRO_SECONDS),
            "-i",
            str(outro_png),
            "-vf",
            "split[s0][s1];[s0]palettegen=stats_mode=full:max_colors=256[p];"
            "[s1][p]paletteuse=dither=none",
            str(outro_gif),
        ]
    )

    run(
        [
            "ffmpeg",
            "-y",
            "-i",
            str(main_gif),
            "-i",
            str(outro_gif),
            "-filter_complex",
            "[0:v][1:v]concat=n=2:v=1:a=0,split[s0][s1];"
            "[s0]palettegen=stats_mode=full:max_colors=256[p];"
            "[s1][p]paletteuse=dither=none",
            "-loop",
            "0",
            str(OUTPUT_GIF),
        ]
    )

    print(f"Wrote {OUTPUT_GIF}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
