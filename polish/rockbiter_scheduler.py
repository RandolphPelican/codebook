"""Rockbiter scheduler mock — process monitor with energy budgets.

15-second sequence; 1280x720 @ 30fps. Mock-as-narrative per D4.4: no underlying
scheduler; pure framebuffer painting. Honest content (current Gmork session +
in-fiction queued surfaces with deferred-V2.0 status); honest deferral
annotation at end.

Layout:
  - Top banner: "ROCKBITER SCHEDULER  V1.0"
  - Column headers: PROCESS | ENERGY | STATUS
  - Process rows: each with name + animated energy bar + status text
  - Energy budget bars animate downward across the 15s budget
  - Last 2s: dim overlay + "ROCKBITER HOLDS THEM WITH GRIEF - V2.0"

The metabolic discipline is made visually load-bearing: substrate's
per-opcode energy accounting (D3.17) becomes a process-monitor metaphor.

Run:
  python3 polish/rockbiter_scheduler.py
  python3 polish/rockbiter_scheduler.py --mp4 polish/dist/polish_rockbiter_scheduler.mp4
"""

import os
import sys
from typing import List, Tuple

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from polish.common import tricolor, scaled_font, frames   # noqa: E402

FPS = 30
TOTAL_SECONDS = 15
TOTAL_FRAMES = FPS * TOTAL_SECONDS
WIDTH, HEIGHT = 1280, 720
RESOLUTION = (WIDTH, HEIGHT)

# Scheduler chrome
CHROME_BG  = (16, 18, 22)
ROW_BG     = (26, 28, 32)
ROW_ALT_BG = (32, 34, 40)
HEADER_BG  = (40, 44, 50)
TEXT_DIM   = (180, 180, 190)
TEXT_BRIGHT = (240, 240, 250)


# Process table — (name, initial_joules, drain_per_sec, status, status_color)
PROCESSES = [
    # Active processes (energy depletes)
    ("GMORK SESSION",        1_000_000,  3_000,  "RUNNING",    tricolor.GOLD_HIGHLIGHT),
    ("FIB_ENERGY.CBS",         100_000, 14_217,  "RUNNING",    tricolor.GREEN_HIGHLIGHT),
    ("MAID HOUSEKEEPER",       500_000,    800,  "WAITING",    tricolor.GOLD),
    # Future / deferred surfaces (static; status = deferred)
    ("FALKOR BROWSER",               0,      0,  "DEFERRED V2.0", (140, 140, 160)),
    ("ATREYU EDITOR",                0,      0,  "DEFERRED V2.0", (140, 140, 160)),
    ("EMPRESS SETTINGS",             0,      0,  "DEFERRED V2.0", (140, 140, 160)),
    ("KOREANDER LIBRARY",            0,      0,  "DEFERRED V2.0", (140, 140, 160)),
    ("SOUTHERN ORACLE SEARCH",       0,      0,  "DEFERRED V2.0", (140, 140, 160)),
    ("ARTAX COMPANION",              0,      0,  "QUEUED",        tricolor.GREEN_SHADOW),
]


def _draw_word(img: Image.Image, word: str, x: int, y: int, scale: int,
               color: Tuple[int, int, int], alpha: float = 1.0) -> int:
    pixels = scaled_font.render_text_scaled(
        word, scale,
        color_fn=lambda y_norm: color,
        spacing=max(1, scale // 4),
    )
    img_pixels = img.load()
    a = max(0.0, min(1.0, alpha))
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            if a >= 1.0:
                img_pixels[dx, dy] = rgb
            else:
                existing = img_pixels[dx, dy]
                img_pixels[dx, dy] = (
                    int(existing[0] * (1 - a) + rgb[0] * a),
                    int(existing[1] * (1 - a) + rgb[1] * a),
                    int(existing[2] * (1 - a) + rgb[2] * a),
                )
    return scaled_font.text_width(word, scale, spacing=max(1, scale // 4))


def _draw_banner(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, WIDTH, 64], fill=HEADER_BG)
    title = "ROCKBITER SCHEDULER"
    sub = "V1.0"
    title_w = scaled_font.text_width(title, 4, spacing=3)
    title_x = (WIDTH - title_w) // 2
    _draw_word(img, title, title_x, 16, 4, tricolor.GOLD_HIGHLIGHT)
    _draw_word(img, sub, title_x + title_w + 16, 20, 3, tricolor.GREEN_HIGHLIGHT)


def _draw_column_headers(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 80, WIDTH, 116], fill=HEADER_BG)
    _draw_word(img, "PROCESS",    32,    92, 2, TEXT_BRIGHT)
    _draw_word(img, "ENERGY",     520,   92, 2, TEXT_BRIGHT)
    _draw_word(img, "STATUS",     980,   92, 2, TEXT_BRIGHT)


def _format_joules(j: int) -> str:
    """Format joules with K/M suffix for compact display."""
    if j >= 1_000_000:
        return f"{j // 1000}K J"
    if j >= 10_000:
        return f"{j // 1000}K J"
    if j == 0:
        return "0 J"
    return f"{j} J"


def _draw_energy_bar(img: Image.Image, x: int, y: int,
                      current: int, initial: int,
                      color: Tuple[int, int, int]) -> None:
    """Draw a horizontal energy bar from x,y; width 300px."""
    draw = ImageDraw.Draw(img)
    bar_w = 300
    bar_h = 14
    # Border / frame
    draw.rectangle([x, y, x + bar_w, y + bar_h], outline=(80, 80, 90), width=1)
    # Fill proportional to remaining energy
    if initial > 0:
        pct = max(0.0, current / initial)
    else:
        pct = 0.0
    fill_w = int(bar_w * pct)
    if fill_w > 0:
        # Bar color shifts: green (>50%), gold (20-50%), red (<20%)
        if pct > 0.5:
            bar_color = tricolor.GREEN_HIGHLIGHT
        elif pct > 0.2:
            bar_color = tricolor.GOLD_HIGHLIGHT
        else:
            bar_color = tricolor.RED_HIGHLIGHT
        draw.rectangle([x + 1, y + 1, x + fill_w, y + bar_h - 1], fill=bar_color)


def _draw_row(img: Image.Image, row_idx: int, t: float, y: int,
               name: str, initial: int, drain: float,
               status: str, status_color: Tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(img)
    bg = ROW_BG if row_idx % 2 == 0 else ROW_ALT_BG
    draw.rectangle([0, y, WIDTH, y + 52], fill=bg)

    # Process name
    _draw_word(img, name, 32, y + 18, 2, TEXT_BRIGHT)

    # Energy (numeric + bar)
    current_j = max(0, initial - int(drain * t))
    label = _format_joules(current_j)
    label_x = 520
    _draw_word(img, label, label_x, y + 18, 2, TEXT_DIM)
    if initial > 0:
        _draw_energy_bar(img, label_x + 130, y + 18, current_j, initial, status_color)

    # Status
    _draw_word(img, status, 980, y + 18, 2, status_color)

    # Special case: if energy reaches 0, append "DEPLETED" indicator
    if initial > 0 and current_j == 0:
        _draw_word(img, "* DEPLETED *", 1100, y + 32, 1, tricolor.RED_HIGHLIGHT)


def _draw_tagline(img: Image.Image) -> None:
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, HEIGHT - 40, WIDTH, HEIGHT], fill=HEADER_BG)
    tag = "EVERY OPCODE DECLARES ITS COST"
    tw = scaled_font.text_width(tag, 2, spacing=1)
    _draw_word(img, tag, (WIDTH - tw) // 2, HEIGHT - 28, 2, tricolor.GOLD)


def _draw_overlay(img: Image.Image, alpha: float) -> Image.Image:
    if alpha <= 0:
        return img
    overlay = Image.new('RGBA', img.size, (0, 0, 0, int(200 * alpha)))
    canvas = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    canvas_pixels = canvas.load()

    text = "ROCKBITER HOLDS THEM WITH GRIEF"
    sub = "V2.0"
    scale_main = 4
    scale_sub = 3
    main_w = scaled_font.text_width(text, scale_main, spacing=3)
    sub_w = scaled_font.text_width(sub, scale_sub, spacing=2)
    main_x = (WIDTH - main_w) // 2
    main_y = HEIGHT // 2 - 40

    pixels = scaled_font.render_text_scaled(text, scale_main,
                                             color_fn=tricolor.metallic_tricolor, spacing=3)
    for px, py, rgb in pixels:
        dx, dy = main_x + px, main_y + py
        if 0 <= dx < WIDTH and 0 <= dy < HEIGHT:
            existing = canvas_pixels[dx, dy]
            canvas_pixels[dx, dy] = (
                int(existing[0] * (1 - alpha) + rgb[0] * alpha),
                int(existing[1] * (1 - alpha) + rgb[1] * alpha),
                int(existing[2] * (1 - alpha) + rgb[2] * alpha),
            )

    sub_x = (WIDTH - sub_w) // 2
    sub_y = main_y + scaled_font.GLYPH_PIX * scale_main + 30
    sub_pixels = scaled_font.render_text_scaled(sub, scale_sub,
                                                 color_fn=lambda y_norm: tricolor.GOLD_HIGHLIGHT,
                                                 spacing=2)
    for px, py, rgb in sub_pixels:
        dx, dy = sub_x + px, sub_y + py
        if 0 <= dx < WIDTH and 0 <= dy < HEIGHT:
            existing = canvas_pixels[dx, dy]
            canvas_pixels[dx, dy] = (
                int(existing[0] * (1 - alpha) + rgb[0] * alpha),
                int(existing[1] * (1 - alpha) + rgb[1] * alpha),
                int(existing[2] * (1 - alpha) + rgb[2] * alpha),
            )

    return canvas


class RockbiterScheduler:
    """Process monitor mock — in-fiction surface per D4.4."""
    fps = FPS
    total_frames = TOTAL_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps
        img = Image.new('RGB', RESOLUTION, CHROME_BG)

        _draw_banner(img)
        _draw_column_headers(img)

        # Render process rows
        row_height = 52
        y_start = 124
        for i, (name, initial, drain, status, status_color) in enumerate(PROCESSES):
            y = y_start + i * row_height
            if y + row_height > HEIGHT - 40:
                break
            _draw_row(img, i, t, y, name, initial, drain, status, status_color)

        _draw_tagline(img)

        # End annotation fade-in last 2s
        if t > TOTAL_SECONDS - 2.0:
            alpha = min(1.0, (t - (TOTAL_SECONDS - 2.0)) / 1.5)
            img = _draw_overlay(img, alpha)

        return img


def main() -> int:
    anim = RockbiterScheduler()
    default_mp4 = os.path.join(
        os.path.dirname(__file__), 'dist', 'polish_rockbiter_scheduler.mp4'
    )
    return frames.cli_main(anim, default_mp4)


if __name__ == '__main__':
    sys.exit(main())
