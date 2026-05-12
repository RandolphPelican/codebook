"""Spike: Pillow frame stack → animated GIF + MP4-via-PIL-NotImplemented (defer to FFmpeg).

Validates PIL can render the tricolor palette + scaled font, and export an animated
GIF (built-in). True MP4 export goes through FFmpeg (spike: test_ffmpeg_compose.py).

Run: python3 polish/spike/test_pillow_export.py
"""

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from PIL import Image   # noqa: E402
from polish.common import tricolor, scaled_font   # noqa: E402

WIDTH, HEIGHT = 800, 240
FRAMES = 16
OUT_GIF = os.path.join(os.path.dirname(__file__), 'spike_pillow_anim.gif')


def render_frame(t_norm: float) -> Image.Image:
    """Render a single frame at time t_norm in [0, 1]; tricolor sweeps vertically."""
    img = Image.new('RGB', (WIDTH, HEIGHT), tricolor.BLACK)
    pixels = img.load()

    # "CODEBOOKOS" with tricolor shifted by t_norm
    text = "CODEBOOKOS"
    scale = 8
    width_px = scaled_font.text_width(text, scale, spacing=4)
    x0 = (WIDTH - width_px) // 2
    y0 = (HEIGHT - scaled_font.GLYPH_PIX * scale) // 2

    def color_fn(y_norm):
        # Animate by adding t_norm to y_norm (modulo 1.0) — band slides
        shifted = (y_norm + t_norm) % 1.0
        return tricolor.metallic_tricolor(shifted)

    text_pixels = scaled_font.render_text_scaled(
        text, scale, color_fn=color_fn, spacing=4,
    )
    for px, py, rgb in text_pixels:
        pixels[x0 + px, y0 + py] = rgb

    return img


def main() -> int:
    frames = [render_frame(i / FRAMES) for i in range(FRAMES)]
    frames[0].save(
        OUT_GIF,
        save_all=True,
        append_images=frames[1:],
        duration=80,   # ms per frame
        loop=0,
    )

    if not os.path.exists(OUT_GIF) or os.path.getsize(OUT_GIF) < 1000:
        print(f"FAIL: GIF not exported or too small: {OUT_GIF}")
        return 1
    print(f"PASS: animated GIF saved to {OUT_GIF} ({os.path.getsize(OUT_GIF)} bytes)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
