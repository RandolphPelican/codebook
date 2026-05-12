"""Falkor browser mock — capability-addressed networking preview.

15-second sequence; 1280x720 @ 30fps. Mock-as-narrative per D4.4: no underlying
network code; pure framebuffer painting. Honest in-fiction content; honest
"V2.0" deferral annotation at end.

Layout:
  - Top: browser chrome (back/forward, URL bar with auryn://, refresh)
  - Tab strip: single tab "Falkor Codex"
  - Main pane: in-fiction "Falkor Codex" entry on capability-addressed networking
  - Subtle animations: URL bar cursor blink, page-scroll indicator, loading pulse
  - Last 2s: dim overlay + "FALKOR WALKS THE WEB - V2.0"

Run:
  python3 polish/falkor_browser.py
  python3 polish/falkor_browser.py --mp4 polish/dist/polish_falkor_browser.mp4
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

# Browser chrome colors
CHROME_BG    = (26, 24, 36)         # dark indigo
TAB_BG       = (40, 36, 56)
TAB_ACTIVE   = (60, 50, 80)
PAGE_BG      = (250, 245, 230)      # parchment cream
PAGE_TEXT    = (40, 30, 50)
URL_BAR_BG   = (60, 56, 78)
URL_BAR_TEXT = (220, 215, 200)


URL = "AURYN://RANDOLPHPELICAN.III/CODEX/REALM-TRAVERSAL"
TAB_LABEL = "FALKOR CODEX"

PAGE_HEADER = "FALKOR CODEX  REALM-TRAVERSAL"
PAGE_BODY = [
    "",
    "FALKOR WALKS THE WEB BY CAPABILITY-ADDRESSED",
    "TRAVERSAL  EACH HOP DECLARES ITS ENERGY COST",
    "AND CARRIES A CAP THAT PROVES ITS AUTHORITY.",
    "",
    "TRUST-ENGINE SEMANTICS:",
    "",
    "  -  CAPABILITIES INSTEAD OF URLS",
    "  -  MAC-PROTECTED PRIMITIVES BETWEEN REALMS",
    "  -  ENERGY ACCOUNTING ACROSS HOPS",
    "  -  NO APP STORES  NO GATEKEEPERS  NO ADS",
    "",
    "CAPABILITY-ADDRESSED NETWORKING:",
    "",
    "  AURYN URIS ARE CAP HANDLES.  EACH HOP IS A",
    "  CAP-CHECK BEFORE A CAP-ACTIVATE  THE WEB",
    "  KNOWS WHAT IT IS PAYING IN JOULES.",
    "",
    "POST-SURVEILLANCE BY DESIGN:",
    "",
    "  THE OS CANNOT BE FORCED TO ATTEST WHAT IT",
    "  REFUSES TO LOG.  THE CAP-GRAPH IS THE ONLY",
    "  AUDIT TRAIL.  COMPLIANCE BY ABSENCE.",
    "",
]


def _draw_word(img: Image.Image, word: str, x: int, y: int, scale: int,
               color: Tuple[int, int, int], alpha: float = 1.0) -> int:
    """Draw word; return width advanced."""
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


def _draw_chrome(img: Image.Image, t: float, cursor_visible: bool,
                  loading_progress: float) -> None:
    """Browser chrome: back/forward, URL bar, refresh, tab strip."""
    draw = ImageDraw.Draw(img)

    # Top chrome strip (80px)
    draw.rectangle([0, 0, WIDTH, 80], fill=CHROME_BG)

    # Back / forward / refresh buttons (left side)
    btn_y = 24
    for i, label in enumerate(['<', '>', 'R']):
        x = 16 + i * 48
        draw.rectangle([x, btn_y, x + 32, btn_y + 32], outline=(120, 110, 140), width=2)
        _draw_word(img, label, x + 10, btn_y + 8, 2, (200, 195, 210))

    # URL bar
    url_x0 = 180
    url_x1 = WIDTH - 24
    draw.rectangle([url_x0, btn_y, url_x1, btn_y + 32], fill=URL_BAR_BG, outline=(100, 90, 130), width=1)
    _draw_word(img, URL, url_x0 + 12, btn_y + 9, 2, URL_BAR_TEXT)

    # Cursor blink in URL bar
    if cursor_visible:
        cursor_x = url_x0 + 12 + scaled_font.text_width(URL, 2, spacing=1) + 4
        if cursor_x < url_x1 - 8:
            draw.rectangle([cursor_x, btn_y + 6, cursor_x + 2, btn_y + 28],
                            fill=tricolor.GOLD)

    # Tab strip (40px)
    draw.rectangle([0, 80, WIDTH, 120], fill=TAB_BG)
    # Active tab
    draw.rectangle([16, 88, 280, 120], fill=TAB_ACTIVE,
                    outline=(100, 90, 130), width=1)
    _draw_word(img, TAB_LABEL, 32, 96, 2, tricolor.GOLD_HIGHLIGHT)
    # New-tab "+"
    _draw_word(img, "+", 300, 96, 2, (160, 155, 175))

    # Loading bar at top of page (animates first 1.5s)
    if loading_progress > 0:
        load_w = int((WIDTH - 32) * loading_progress)
        draw.rectangle([16, 118, 16 + load_w, 120], fill=tricolor.GOLD)


def _draw_page(img: Image.Image, t: float, scroll_offset: int = 0) -> None:
    """Render the parchment page content."""
    draw = ImageDraw.Draw(img)
    page_top = 132
    page_bottom = HEIGHT - 36
    # Page background
    draw.rectangle([16, page_top, WIDTH - 16, page_bottom], fill=PAGE_BG)

    # Header
    head_scale = 3
    head_y = page_top + 24 - scroll_offset
    if 60 < head_y < page_bottom:
        _draw_word(img, PAGE_HEADER, 48, head_y, head_scale, PAGE_TEXT)

    # Body lines
    body_scale = 2
    body_y_start = page_top + 80 - scroll_offset
    line_height = scaled_font.GLYPH_PIX * body_scale + 6
    for i, line in enumerate(PAGE_BODY):
        y = body_y_start + i * line_height
        if y < page_top - 20 or y > page_bottom - 10:
            continue
        if line.strip().startswith('-'):
            color = tricolor.GREEN_SHADOW
        elif line.endswith(':'):
            color = tricolor.RED_SHADOW
        else:
            color = PAGE_TEXT
        _draw_word(img, line, 64, y, body_scale, color)


def _draw_status_bar(img: Image.Image, t: float, page_scroll_t: float) -> None:
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, HEIGHT - 36, WIDTH, HEIGHT], fill=CHROME_BG)
    _draw_word(img, "FALKOR WALKS THE WEB", 16, HEIGHT - 24, 2, tricolor.GREEN_HIGHLIGHT)
    # Scroll indicator on right
    pct = int(min(1.0, max(0.0, page_scroll_t)) * 100)
    pct_label = f"{pct}%"
    pw = scaled_font.text_width(pct_label, 2, spacing=1)
    _draw_word(img, pct_label, WIDTH - pw - 16, HEIGHT - 24, 2, (180, 170, 200))


def _draw_overlay(img: Image.Image, alpha: float) -> Image.Image:
    if alpha <= 0:
        return img
    overlay = Image.new('RGBA', img.size, (0, 0, 0, int(200 * alpha)))
    canvas = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    canvas_pixels = canvas.load()

    text = "FALKOR WALKS THE WEB"
    sub = "V2.0"
    scale_main = 5
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


class FalkorBrowser:
    """Browser mock — in-fiction surface per D4.4."""
    fps = FPS
    total_frames = TOTAL_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps
        img = Image.new('RGB', RESOLUTION, CHROME_BG)

        # URL cursor blink (1Hz)
        cursor_visible = (frame_idx // (self.fps // 2)) % 2 == 0

        # Loading bar pulses during first 1.5s, then disappears
        loading_progress = 0.0
        if t < 1.5:
            loading_progress = t / 1.5
        elif t < 1.8:
            loading_progress = 1.0 - (t - 1.5) / 0.3

        # Page scroll: subtle scroll over middle 8 seconds (3s → 11s)
        if t < 3.0:
            scroll_offset = 0
            page_scroll_t = 0.0
        elif t > 11.0:
            scroll_offset = 80
            page_scroll_t = 1.0
        else:
            page_scroll_t = (t - 3.0) / 8.0
            scroll_offset = int(80 * page_scroll_t)

        _draw_page(img, t, scroll_offset=scroll_offset)
        _draw_chrome(img, t, cursor_visible, loading_progress)
        _draw_status_bar(img, t, page_scroll_t)

        # End annotation fade-in last 2s
        if t > TOTAL_SECONDS - 2.0:
            alpha = min(1.0, (t - (TOTAL_SECONDS - 2.0)) / 1.5)
            img = _draw_overlay(img, alpha)

        return img


def main() -> int:
    anim = FalkorBrowser()
    default_mp4 = os.path.join(
        os.path.dirname(__file__), 'dist', 'polish_falkor_browser.mp4'
    )
    return frames.cli_main(anim, default_mp4)


if __name__ == '__main__':
    sys.exit(main())
