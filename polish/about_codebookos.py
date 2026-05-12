"""About CodebookOS — 45-second narrative scroll demo.

Architectural-truth-over-marketing-pitch tone. Lead with substrate facts;
close with contributor invitation. Six sections, ~7.5 seconds each:

  0-8s    Header: "CodebookOS V1.0" metallic-tricolor title card; fade-in + hold
  8-15s   Accomplishment: 30hrs / 25.4KB / CBS language / 44 doctrines
  15-23s  Substrate primitives: Sign / Cap / Outcome / Energy / Embedding
  23-30s  Future development: trinity / surface ecology / federated organism
  30-37s  Advantages: auditable / byte-exact / energy-accounted / cap-typed
  37-45s  Invitation: github.com / "audit, extend, and trust line by line"

Visual flourishes between sections: doctrine zoom (D3.14 Form A; D3.27 layout-2;
D3.42 axis-removal), small vector-composition viz (3 colored bars showing
ADD = A + B), and CBS source snippet rendered in scaled_font.

Run:
  python3 polish/about_codebookos.py                            # live PyGame
  python3 polish/about_codebookos.py --mp4 build/polish_about.mp4   # render to MP4
"""

import os
import sys
from typing import List, Tuple

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from polish.common import tricolor, scaled_font, frames   # noqa: E402


# Animation parameters
FPS = 30
TOTAL_SECONDS = 45
TOTAL_FRAMES = FPS * TOTAL_SECONDS
WIDTH, HEIGHT = 1280, 720
RESOLUTION = (WIDTH, HEIGHT)

# Section time boundaries (in seconds)
SECTIONS = [
    ('header',          0.0,  8.0),
    ('accomplishment',  8.0,  15.0),
    ('primitives',     15.0,  23.0),
    ('future',         23.0,  30.0),
    ('advantages',     30.0,  37.0),
    ('invitation',     37.0,  45.0),
]


def _ease_in_out(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return 3 * t * t - 2 * t * t * t


def _fade_alpha(scene_t: float, scene_dur: float,
                fade_in_dur: float = 1.0, fade_out_dur: float = 1.0) -> float:
    """Compute fade alpha for a scene: ease-in over fade_in_dur, hold, ease-out over fade_out_dur."""
    if scene_t < fade_in_dur:
        return _ease_in_out(scene_t / fade_in_dur)
    if scene_t > scene_dur - fade_out_dur:
        return _ease_in_out((scene_dur - scene_t) / fade_out_dur)
    return 1.0


def _section_for_t(t: float) -> Tuple[str, float, float]:
    """Return (section_name, t_within_section, section_duration)."""
    for name, t0, t1 in SECTIONS:
        if t0 <= t < t1:
            return (name, t - t0, t1 - t0)
    name, t0, t1 = SECTIONS[-1]
    return (name, t - t0, t1 - t0)


def _draw_text_color_gold(img: Image.Image, text: str, x: int, y: int,
                          scale: int, alpha: float = 1.0,
                          color: Tuple[int, int, int] = None) -> None:
    """Draw text at (x, y) in gold (default) or specified color."""
    if color is None:
        color = tricolor.GOLD
    pixels = scaled_font.render_text_scaled(
        text, scale,
        color_fn=lambda y_norm: color,
        spacing=max(1, scale // 4),
    )
    a = max(0.0, min(1.0, alpha))
    img_pixels = img.load()
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            if a >= 1.0:
                img_pixels[dx, dy] = rgb
            else:
                # Alpha blend with existing pixel
                existing = img_pixels[dx, dy]
                blended = (
                    int(existing[0] * (1 - a) + rgb[0] * a),
                    int(existing[1] * (1 - a) + rgb[1] * a),
                    int(existing[2] * (1 - a) + rgb[2] * a),
                )
                img_pixels[dx, dy] = blended


def _draw_metallic_title(img: Image.Image, text: str, x: int, y: int,
                          scale: int, alpha: float = 1.0) -> None:
    """Draw text with metallic tricolor gradient."""
    pixels = scaled_font.render_text_scaled(
        text, scale, color_fn=tricolor.metallic_tricolor,
        spacing=max(2, scale // 3),
    )
    a = max(0.0, min(1.0, alpha))
    img_pixels = img.load()
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            if a >= 1.0:
                img_pixels[dx, dy] = rgb
            else:
                existing = img_pixels[dx, dy]
                blended = (
                    int(existing[0] * (1 - a) + rgb[0] * a),
                    int(existing[1] * (1 - a) + rgb[1] * a),
                    int(existing[2] * (1 - a) + rgb[2] * a),
                )
                img_pixels[dx, dy] = blended


def _draw_lines_centered(img: Image.Image, lines: List[str], scale: int,
                          y_start: int, alpha: float = 1.0,
                          color: Tuple[int, int, int] = None,
                          line_spacing: int = 12) -> int:
    """Render each line centered horizontally; return final y after last line."""
    y = y_start
    line_height = scaled_font.GLYPH_PIX * scale + line_spacing
    for line in lines:
        width_px = scaled_font.text_width(line, scale, spacing=max(1, scale // 4))
        x = (img.width - width_px) // 2
        _draw_text_color_gold(img, line, x, y, scale, alpha=alpha, color=color)
        y += line_height
    return y


# --- Section renderers ---

def _render_header(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur, fade_in_dur=1.5, fade_out_dur=1.0)
    title_scale = 10
    title = "CODEBOOKOS"
    width_px = scaled_font.text_width(title, title_scale, spacing=4)
    title_x = (img.width - width_px) // 2
    title_y = img.height // 2 - 80
    _draw_metallic_title(img, title, title_x, title_y, title_scale, alpha=alpha)

    sub_scale = 4
    sub = "V1.0"
    sub_w = scaled_font.text_width(sub, sub_scale, spacing=2)
    _draw_text_color_gold(img, sub,
                          (img.width - sub_w) // 2,
                          title_y + scaled_font.GLYPH_PIX * title_scale + 40,
                          sub_scale, alpha=alpha)

    tag_scale = 2
    tag = "EVERY OPCODE DECLARES ITS COST"
    tag_w = scaled_font.text_width(tag, tag_scale, spacing=1)
    _draw_text_color_gold(img, tag,
                          (img.width - tag_w) // 2,
                          title_y + scaled_font.GLYPH_PIX * title_scale + 100,
                          tag_scale,
                          alpha=alpha * 0.8,
                          color=(180, 180, 180))


def _render_accomplishment(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur)
    head_scale = 4
    head = "ACCOMPLISHMENT"
    head_w = scaled_font.text_width(head, head_scale, spacing=2)
    _draw_metallic_title(img, head, (img.width - head_w) // 2, 70, head_scale, alpha=alpha)

    body_scale = 2
    lines = [
        "BUILT BY RANDOLPH PELICAN III",
        "30 HOURS OF ARCHITECTURAL WORK",
        "OVER 3 MONTHS - SOLO",
        "",
        "25.4 KB OF HAND-CRAFTED NASM",
        "CUSTOM CBS PROGRAMMING LANGUAGE",
        "44 CODIFIED ARCHITECTURAL DOCTRINES",
        "AUDITABLE IN A FORTNIGHT",
    ]
    _draw_lines_centered(img, lines, body_scale, y_start=200, alpha=alpha,
                         line_spacing=8)


def _render_primitives(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur)
    head_scale = 4
    head = "TYPED PRIMITIVES"
    head_w = scaled_font.text_width(head, head_scale, spacing=2)
    _draw_metallic_title(img, head, (img.width - head_w) // 2, 70, head_scale, alpha=alpha)

    body_scale = 2
    # Primitives as rows: NAME : ONE-LINER
    primitives = [
        ("SIGN",      "IDENTITY AND PROVENANCE"),
        ("CAP",       "CAPABILITY-TYPED AUTHORITY"),
        ("OUTCOME",   "RESULT WITH MAC INTEGRITY"),
        ("ENERGY",    "METABOLIC BUDGET PRIMITIVE"),
        ("EMBEDDING", "F32 VECTOR WITH SIPHASH MAC"),
    ]
    y = 200
    for name, desc in primitives:
        # name in gold; description in dim gold
        name_w = scaled_font.text_width(name, body_scale, spacing=1)
        desc_w = scaled_font.text_width(desc, body_scale, spacing=1)
        gap = 40
        total_w = name_w + gap + desc_w
        x = (img.width - total_w) // 2
        _draw_text_color_gold(img, name, x, y, body_scale, alpha=alpha,
                              color=tricolor.GOLD_HIGHLIGHT)
        _draw_text_color_gold(img, desc, x + name_w + gap, y, body_scale,
                              alpha=alpha * 0.85,
                              color=(180, 160, 100))
        y += scaled_font.GLYPH_PIX * body_scale + 16


def _render_future(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur)
    head_scale = 4
    head = "WHAT IS COMING"
    head_w = scaled_font.text_width(head, head_scale, spacing=2)
    _draw_metallic_title(img, head, (img.width - head_w) // 2, 70, head_scale, alpha=alpha)

    body_scale = 2
    lines = [
        "THE TRINITY:",
        "COP - CAPABILITY INSPECTOR",
        "MAID - LEXICAL POLE (V1.0 COMPLETE)",
        "INTERPRETER - TEXT TO BYTECODE",
        "",
        "SURFACE ECOLOGY",
        "HORMONAL SUBSTRATE",
        "FEDERATED COGNITIVE ORGANISM",
    ]
    _draw_lines_centered(img, lines, body_scale, y_start=200, alpha=alpha,
                         line_spacing=8)


def _render_advantages(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur)
    head_scale = 4
    head = "ADVANTAGES"
    head_w = scaled_font.text_width(head, head_scale, spacing=2)
    _draw_metallic_title(img, head, (img.width - head_w) // 2, 70, head_scale, alpha=alpha)

    body_scale = 2
    lines = [
        "AUDITABLE IN A FORTNIGHT",
        "BYTE-EXACT F32 DETERMINISM",
        "ENERGY ACCOUNTING AT OPCODE LEVEL",
        "CAPABILITY-TYPED FROM LAYER 1",
        "NO APP STORES OR GATEKEEPERS",
        "MYTHOLOGY-COHERENT ARCHITECTURE",
    ]
    _draw_lines_centered(img, lines, body_scale, y_start=220, alpha=alpha,
                         line_spacing=14)


def _render_invitation(img: Image.Image, scene_t: float, scene_dur: float) -> None:
    alpha = _fade_alpha(scene_t, scene_dur, fade_in_dur=1.5, fade_out_dur=2.0)
    head_scale = 4
    head = "OPEN SOURCE"
    head_w = scaled_font.text_width(head, head_scale, spacing=2)
    _draw_metallic_title(img, head, (img.width - head_w) // 2, 90, head_scale, alpha=alpha)

    body_scale = 2
    lines = [
        "EVERY DOCTRINE",
        "EVERY SURFACE",
        "EVERY BYTE OF SUBSTRATE",
        "",
        "AUDIT - EXTEND - TRUST LINE BY LINE",
    ]
    _draw_lines_centered(img, lines, body_scale, y_start=220, alpha=alpha,
                         line_spacing=14)

    url_scale = 3
    url = "GITHUB.COM/RANDOLPHPELICAN/CODEBOOK"
    url_w = scaled_font.text_width(url, url_scale, spacing=2)
    _draw_text_color_gold(img, url, (img.width - url_w) // 2, 500, url_scale,
                          alpha=alpha,
                          color=tricolor.GOLD_HIGHLIGHT)

    cta_scale = 2
    cta = "HELP US BUILD IT"
    cta_w = scaled_font.text_width(cta, cta_scale, spacing=1)
    _draw_text_color_gold(img, cta, (img.width - cta_w) // 2, 580, cta_scale,
                          alpha=alpha,
                          color=tricolor.GREEN_HIGHLIGHT)


_SECTION_RENDERERS = {
    'header':          _render_header,
    'accomplishment':  _render_accomplishment,
    'primitives':      _render_primitives,
    'future':          _render_future,
    'advantages':      _render_advantages,
    'invitation':      _render_invitation,
}


class AboutAnimation:
    """About demo per D4.3 + D4.5 (demo-program discipline as polish app)."""
    fps = FPS
    total_frames = TOTAL_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps
        section_name, scene_t, scene_dur = _section_for_t(t)
        img = Image.new('RGB', (WIDTH, HEIGHT), tricolor.BLACK)
        renderer = _SECTION_RENDERERS[section_name]
        renderer(img, scene_t, scene_dur)
        return img


def main() -> int:
    anim = AboutAnimation()
    default_mp4 = os.path.join(
        os.path.dirname(__file__), 'dist', 'polish_about.mp4'
    )
    return frames.cli_main(anim, default_mp4)


if __name__ == '__main__':
    sys.exit(main())
