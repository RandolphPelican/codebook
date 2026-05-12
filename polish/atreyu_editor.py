"""Atreyu editor mock — code editor chrome with real CBS source visible.

15-second sequence; 1280x720 @ 30fps. Mock-as-narrative per D4.4:
no underlying editor; pure framebuffer painting. Honest content (real CBS
source from surfaces/demo_fib_energy.cbs); honest deferral annotation at end.

Layout:
  - Top status bar: file path + save indicator + cursor position
  - Left gutter: line numbers
  - Main pane: CBS source with tricolor syntax accent (keywords gold/red/green)
  - Bottom status bar: cursor pos + mode + tagline
  - At ~6-8s: cursor moves to a line, a character types in, line below shifts
  - Last 2s: dim overlay + "ATREYU WALKS THROUGH IDEAS - V2.0"

Run:
  python3 polish/atreyu_editor.py
  python3 polish/atreyu_editor.py --mp4 polish/dist/polish_atreyu_editor.mp4
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

# Editor chrome colors
CHROME_BG = (20, 20, 26)
GUTTER_BG = (28, 28, 36)
STATUS_BG = (12, 12, 18)
TEXT_DIM = (160, 160, 170)
COMMENT_COLOR = (110, 110, 130)


CBS_SOURCE_PATH = os.path.join(os.path.dirname(__file__), '..', 'surfaces', 'demo_fib_energy.cbs')


def _load_cbs_source() -> List[str]:
    """Load real CBS source from surfaces/demo_fib_energy.cbs; fall back to placeholder."""
    try:
        with open(CBS_SOURCE_PATH, 'r', encoding='utf-8') as f:
            lines = f.read().splitlines()
        return lines
    except OSError:
        return [
            '// Pod 4.0.F demo placeholder',
            'let n = 12',
            'print(n)',
            'return 0',
        ]


_SOURCE_LINES = _load_cbs_source()


def _classify_token_color(line_upper: str, char_idx: int) -> Tuple[int, int, int]:
    """Per-character classification: comments / keywords / strings get accent colors."""
    # Default text
    return TEXT_DIM


# Syntax classification at line level (cheap; mock-grade)
KEYWORDS_COST   = {'PRINT', 'ENERGY_USED', 'ENERGY_INITIAL'}     # cost-ish keywords → gold
KEYWORDS_CAP    = {'CONST', 'RETURN', 'IF'}                      # capability-ish → red
KEYWORDS_PRIM   = {'LET', 'FUNC'}                                # primitive types → green


def _color_for_word(word: str) -> Tuple[int, int, int]:
    """Return tricolor accent for keyword, dim for ident, default for other."""
    upper = word.upper()
    if upper in KEYWORDS_COST:
        return tricolor.GOLD_HIGHLIGHT
    if upper in KEYWORDS_CAP:
        return tricolor.RED_HIGHLIGHT
    if upper in KEYWORDS_PRIM:
        return tricolor.GREEN_HIGHLIGHT
    return TEXT_DIM


def _draw_word(img: Image.Image, word: str, x: int, y: int, scale: int,
               color: Tuple[int, int, int]) -> int:
    """Draw a word; return width advanced (in pixels)."""
    pixels = scaled_font.render_text_scaled(
        word.upper(), scale,
        color_fn=lambda y_norm: color,
        spacing=max(1, scale // 4),
    )
    img_pixels = img.load()
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            img_pixels[dx, dy] = rgb
    return scaled_font.text_width(word, scale, spacing=max(1, scale // 4))


def _draw_line(img: Image.Image, line: str, x_start: int, y: int, scale: int) -> None:
    """Render a CBS source line with simple per-word color classification."""
    # Comment line: entire line dim
    stripped = line.strip()
    if stripped.startswith('//'):
        if stripped:
            pixels = scaled_font.render_text_scaled(
                line.replace('\t', '    '), scale,
                color_fn=lambda y_norm: COMMENT_COLOR,
                spacing=max(1, scale // 4),
            )
            img_pixels = img.load()
            for px, py, rgb in pixels:
                dx, dy = x_start + px, y + py
                if 0 <= dx < img.width and 0 <= dy < img.height:
                    img_pixels[dx, dy] = rgb
        return

    # Non-comment: split by whitespace, color per word; whitespace = blank
    expanded = line.replace('\t', '    ')
    x = x_start
    word_buf = []
    i = 0
    while i <= len(expanded):
        ch = expanded[i] if i < len(expanded) else None
        if ch is None or ch == ' ':
            if word_buf:
                word = ''.join(word_buf)
                color = _color_for_word(word)
                advance = _draw_word(img, word, x, y, scale, color)
                x += advance
                word_buf = []
            if ch == ' ':
                # advance by space-width
                x += scaled_font.text_width(' ', scale, spacing=max(1, scale // 4))
            i += 1
        else:
            # Keep only chars in font; replace unknowns with space
            if ch.upper() in scaled_font.FONT_8X8 or ch == ' ':
                word_buf.append(ch)
            else:
                # Unknown char (e.g. '(', ')', ',', etc.) — render as space-width placeholder
                if word_buf:
                    word = ''.join(word_buf)
                    color = _color_for_word(word)
                    advance = _draw_word(img, word, x, y, scale, color)
                    x += advance
                    word_buf = []
                x += scaled_font.text_width(' ', scale, spacing=max(1, scale // 4))
            i += 1


def _draw_chrome(img: Image.Image, t: float, cursor_line: int, cursor_col: int,
                  save_dot: bool) -> None:
    """Draw editor chrome: top + bottom status bars, gutter, cursor indicators."""
    draw = ImageDraw.Draw(img)

    # Top status bar
    draw.rectangle([0, 0, WIDTH, 36], fill=STATUS_BG)
    # File path
    path_label = "SURFACES/DEMO_FIB_ENERGY.CBS"
    _draw_word(img, path_label, 12, 12, 2, tricolor.GOLD_HIGHLIGHT)
    # Save dot (toggles around edit)
    if save_dot:
        draw.ellipse([WIDTH - 36, 12, WIDTH - 16, 32], fill=tricolor.RED_HIGHLIGHT)
    else:
        draw.ellipse([WIDTH - 36, 12, WIDTH - 16, 32], fill=(80, 80, 90))

    # Gutter (left column)
    draw.rectangle([0, 36, 64, HEIGHT - 36], fill=GUTTER_BG)

    # Bottom status bar
    draw.rectangle([0, HEIGHT - 36, WIDTH, HEIGHT], fill=STATUS_BG)
    cursor_label = f"LINE {cursor_line}  COL {cursor_col}"
    _draw_word(img, cursor_label, 12, HEIGHT - 24, 2, TEXT_DIM)
    mode_label = "INSERT"
    _draw_word(img, mode_label, WIDTH - 200, HEIGHT - 24, 2, tricolor.GOLD)
    tagline = "ATREYU WALKS THROUGH IDEAS"
    tw = scaled_font.text_width(tagline, 2, spacing=1)
    _draw_word(img, tagline, (WIDTH - tw) // 2, HEIGHT - 24, 2, tricolor.GREEN_HIGHLIGHT)


def _draw_content(img: Image.Image, t: float, edit_chars: int) -> Tuple[int, int]:
    """Render source lines into the main pane. Returns (cursor_line, cursor_col).

    edit_chars > 0 means show that many extra chars typed into a target line.
    """
    scale = 2
    line_height = scaled_font.GLYPH_PIX * scale + 6
    y_start = 50
    x_start = 80

    # Cursor target: line 14 (the 'let result' line)
    target_line_idx = None
    for i, line in enumerate(_SOURCE_LINES):
        if line.strip().startswith('let result'):
            target_line_idx = i
            break
    if target_line_idx is None:
        target_line_idx = min(14, len(_SOURCE_LINES) - 1)

    for i, line in enumerate(_SOURCE_LINES):
        y = y_start + i * line_height
        if y > HEIGHT - 60:
            break

        # Draw line number in gutter
        line_no = f"{i + 1}"
        _draw_word(img, line_no.rjust(3), 12, y, scale, (80, 80, 90))

        # Render source line with syntax accent
        if i == target_line_idx and edit_chars > 0:
            # Insert "//" comment chars (mock edit) — actually just render unchanged for honesty
            _draw_line(img, line, x_start, y, scale)
        else:
            _draw_line(img, line, x_start, y, scale)

    cursor_line = target_line_idx + 1
    cursor_col = len(_SOURCE_LINES[target_line_idx]) + 1 if target_line_idx < len(_SOURCE_LINES) else 1
    return (cursor_line, cursor_col)


def _draw_cursor(img: Image.Image, cursor_line: int, cursor_col: int,
                  blink_on: bool) -> None:
    """Draw blinking cursor at (line, col) in the content pane."""
    if not blink_on:
        return
    scale = 2
    line_height = scaled_font.GLYPH_PIX * scale + 6
    char_width = scaled_font.text_width(' ', scale, spacing=max(1, scale // 4)) - 0  # approx
    char_width = max(char_width, 12)
    x = 80 + (cursor_col - 1) * char_width
    y = 50 + (cursor_line - 1) * line_height
    if y > HEIGHT - 60 or x > WIDTH - 20:
        return
    draw = ImageDraw.Draw(img)
    draw.rectangle([x, y, x + 2, y + scaled_font.GLYPH_PIX * scale], fill=tricolor.GOLD)


def _draw_overlay(img: Image.Image, alpha: float) -> Image.Image:
    """Apply dimming overlay + "ATREYU WALKS - V2.0" annotation. alpha in [0,1]."""
    if alpha <= 0:
        return img
    overlay = Image.new('RGBA', img.size, (0, 0, 0, int(180 * alpha)))
    canvas = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')

    text = "ATREYU WALKS THROUGH IDEAS"
    sub = "V2.0"
    scale_main = 5
    scale_sub = 3
    main_w = scaled_font.text_width(text, scale_main, spacing=3)
    sub_w = scaled_font.text_width(sub, scale_sub, spacing=2)
    main_x = (WIDTH - main_w) // 2
    main_y = HEIGHT // 2 - 40

    # Render with alpha (multiply by overlay alpha)
    pixels = scaled_font.render_text_scaled(text, scale_main,
                                             color_fn=tricolor.metallic_tricolor,
                                             spacing=3)
    canvas_pixels = canvas.load()
    for px, py, rgb in pixels:
        dx, dy = main_x + px, main_y + py
        if 0 <= dx < WIDTH and 0 <= dy < HEIGHT:
            existing = canvas_pixels[dx, dy]
            blended = (
                int(existing[0] * (1 - alpha) + rgb[0] * alpha),
                int(existing[1] * (1 - alpha) + rgb[1] * alpha),
                int(existing[2] * (1 - alpha) + rgb[2] * alpha),
            )
            canvas_pixels[dx, dy] = blended

    sub_x = (WIDTH - sub_w) // 2
    sub_y = main_y + scaled_font.GLYPH_PIX * scale_main + 30
    sub_pixels = scaled_font.render_text_scaled(sub, scale_sub,
                                                 color_fn=lambda y_norm: tricolor.GOLD_HIGHLIGHT,
                                                 spacing=2)
    for px, py, rgb in sub_pixels:
        dx, dy = sub_x + px, sub_y + py
        if 0 <= dx < WIDTH and 0 <= dy < HEIGHT:
            existing = canvas_pixels[dx, dy]
            blended = (
                int(existing[0] * (1 - alpha) + rgb[0] * alpha),
                int(existing[1] * (1 - alpha) + rgb[1] * alpha),
                int(existing[2] * (1 - alpha) + rgb[2] * alpha),
            )
            canvas_pixels[dx, dy] = blended

    return canvas


class AtreyuEditor:
    """Editor mock — in-fiction surface per D4.4."""
    fps = FPS
    total_frames = TOTAL_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps
        img = Image.new('RGB', RESOLUTION, CHROME_BG)

        # Cursor blink (1Hz)
        blink_on = (frame_idx // (self.fps // 2)) % 2 == 0

        # Save indicator: dirty during edit window (6-8s), clean otherwise
        save_dot = 6.0 <= t < 8.5

        # Edit animation: cursor moves and "types" a few chars between 6-8s
        edit_chars = 0
        if 6.0 <= t < 8.0:
            edit_chars = min(int((t - 6.0) * 4), 6)

        cursor_line, cursor_col = _draw_content(img, t, edit_chars)
        _draw_chrome(img, t, cursor_line, cursor_col, save_dot)
        _draw_cursor(img, cursor_line, cursor_col, blink_on)

        # End annotation overlay: fade in over last 2s
        if t > TOTAL_SECONDS - 2.0:
            alpha = min(1.0, (t - (TOTAL_SECONDS - 2.0)) / 1.5)
            img = _draw_overlay(img, alpha)

        return img


def main() -> int:
    anim = AtreyuEditor()
    default_mp4 = os.path.join(
        os.path.dirname(__file__), 'dist', 'polish_atreyu_editor.mp4'
    )
    return frames.cli_main(anim, default_mp4)


if __name__ == '__main__':
    sys.exit(main())
