"""Spike: PyGame window + tricolor text + frame capture to PNG.

Validates pygame can render the tricolor palette and export a frame. Disposable
after 4.0.C SEAL — production rendering happens in polish/<app>.py files.

Run: SDL_VIDEODRIVER=dummy python3 polish/spike/test_pygame_window.py
(dummy driver for headless WSL; remove for windowed run on John's desktop)
"""

import os
import sys

# Headless-friendly default for CI / WSL
os.environ.setdefault('SDL_VIDEODRIVER', 'dummy')

import pygame   # noqa: E402

# Import polish.common via absolute path manipulation
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))
from polish.common import tricolor, scaled_font   # noqa: E402

WIDTH, HEIGHT = 800, 240
OUT_PATH = os.path.join(os.path.dirname(__file__), 'spike_pygame_frame.png')


def main() -> int:
    pygame.init()
    surface = pygame.display.set_mode((WIDTH, HEIGHT))
    surface.fill(tricolor.BLACK)

    # Render "CODEBOOKOS" centered with metallic tricolor gradient
    text = "CODEBOOKOS"
    scale = 8
    width_px = scaled_font.text_width(text, scale, spacing=4)
    x0 = (WIDTH - width_px) // 2
    y0 = (HEIGHT - scaled_font.GLYPH_PIX * scale) // 2

    pixels = scaled_font.render_text_scaled(
        text, scale,
        color_fn=tricolor.metallic_tricolor,
        spacing=4,
    )
    for px, py, rgb in pixels:
        surface.set_at((x0 + px, y0 + py), rgb)

    pygame.image.save(surface, OUT_PATH)
    pygame.quit()

    if os.path.getsize(OUT_PATH) < 100:
        print(f"FAIL: output file too small: {OUT_PATH}")
        return 1
    print(f"PASS: pygame frame saved to {OUT_PATH} ({os.path.getsize(OUT_PATH)} bytes)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
