"""Boot animation: searchlights → RANDOLPH PELICAN III → CodebookOS title card.

10-second sequence; 30fps; 1280x720. Three scenes:

  0.0–4.0s   Starfield + 3 searchlight beams sweeping across night sky;
             beams converge to center frame at ~3.5s
  4.0–7.0s   RANDOLPH PELICAN III metallic-tricolor title fade-in + "presents..."
             subtitle in smaller scale; 2s hold
  7.0–10.0s  Fade out PELICAN III; fade in CodebookOS metallic-tricolor title;
             1s hold; fade-to-black (transition signal for demo video)

D4.3 (boot animation discipline) lands at Pod 4.0.D SEAL based on this implementation.

Run:
  python3 polish/boot_anim.py                            # live PyGame (or dummy if no display)
  python3 polish/boot_anim.py --mp4 build/boot_anim.mp4  # render to MP4
"""

import math
import os
import random
import sys
from typing import Tuple

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from polish.common import tricolor, scaled_font, frames   # noqa: E402


# Animation parameters
FPS = 30
TOTAL_SECONDS = 10
TOTAL_FRAMES = FPS * TOTAL_SECONDS
WIDTH, HEIGHT = 1280, 720
RESOLUTION = (WIDTH, HEIGHT)

# Scene boundaries (in seconds)
SCENE1_END = 4.0   # searchlight sweep + converge
SCENE2_END = 7.0   # PELICAN III title fade-in + hold
SCENE3_END = 10.0  # CodebookOS title + fade-to-black

# Starfield: 120 stars; fixed seed for reproducibility
NUM_STARS = 120
STAR_SEED = 42


def _make_starfield():
    """Generate (x, y, base_brightness, twinkle_phase) tuples for all stars."""
    rng = random.Random(STAR_SEED)
    stars = []
    for _ in range(NUM_STARS):
        x = rng.randint(0, WIDTH - 1)
        y = rng.randint(0, HEIGHT - 1)
        base = rng.uniform(0.4, 1.0)
        phase = rng.uniform(0.0, 2 * math.pi)
        stars.append((x, y, base, phase))
    return stars


_STARS = _make_starfield()


def _render_starfield(t: float) -> np.ndarray:
    """Render starfield as HxWx3 uint8 RGB array."""
    img = np.zeros((HEIGHT, WIDTH, 3), dtype=np.uint8)
    for x, y, base, phase in _STARS:
        # Subtle twinkle: sin wave on brightness
        twinkle = 1.0 + 0.3 * math.sin(2 * math.pi * 0.5 * t + phase)
        brightness = int(255 * base * twinkle)
        brightness = max(0, min(255, brightness))
        img[y, x] = (brightness, brightness, brightness)
        # Small halo: 4 neighbor pixels at half brightness
        half = brightness // 3
        if x > 0:
            img[y, x - 1] = (half, half, half)
        if x < WIDTH - 1:
            img[y, x + 1] = (half, half, half)
        if y > 0:
            img[y - 1, x] = (half, half, half)
        if y < HEIGHT - 1:
            img[y + 1, x] = (half, half, half)
    return img


# Searchlight beam config: (pivot_x, pivot_y, start_angle_deg, end_angle_deg, color)
# 3 beams; pivots below-frame; sweep arcs across the sky and converge to center
BEAMS = [
    # Left beam: pivot bottom-left; sweep from left-side-up to center
    (200, HEIGHT + 100, -120.0, -90.0, (255, 240, 200)),
    # Center beam: pivot bottom-center; sweep slight arc
    (WIDTH // 2, HEIGHT + 100, -85.0, -95.0, (255, 245, 210)),
    # Right beam: pivot bottom-right; sweep from right-side-up to center
    (WIDTH - 200, HEIGHT + 100, -60.0, -90.0, (255, 240, 200)),
]


def _beam_mask(pivot_x, pivot_y, angle_rad,
               angular_sigma=0.05, length=1400, intensity=1.0):
    """Return HxW float32 array of beam brightness ∈ [0, 1]."""
    yy, xx = np.mgrid[0:HEIGHT, 0:WIDTH].astype(np.float32)
    dx = xx - pivot_x
    dy = yy - pivot_y
    dist = np.sqrt(dx * dx + dy * dy)
    pixel_angle = np.arctan2(dy, dx)
    da = (pixel_angle - angle_rad + np.pi) % (2 * np.pi) - np.pi
    angular_brightness = np.exp(-0.5 * (da / angular_sigma) ** 2)
    radial_brightness = np.clip(1.0 - dist / length, 0.0, 1.0)
    return (intensity * angular_brightness * radial_brightness).astype(np.float32)


def _render_searchlights(t: float, base_img: np.ndarray) -> np.ndarray:
    """Compose searchlights additively onto base_img. t in seconds within scene 1."""
    # Convergence: at t=0, beams at start angles; at t=SCENE1_END, all converge to ~-90°
    t_norm = min(t / SCENE1_END, 1.0)
    # Easing: smoothstep (3t^2 - 2t^3) for choreographed convergence
    ease = 3 * t_norm * t_norm - 2 * t_norm * t_norm * t_norm

    accum = base_img.astype(np.float32)
    for (px, py, start_deg, end_deg, color) in BEAMS:
        angle_deg = start_deg + (end_deg - start_deg) * ease
        angle_rad = math.radians(angle_deg)
        # Beam intensity: builds in over 0.5s, holds, then dims at end (preparing for title)
        intensity = 1.0
        if t < 0.5:
            intensity = t / 0.5
        elif t > SCENE1_END - 0.5:
            intensity = max(0.0, (SCENE1_END - t) / 0.5)
        mask = _beam_mask(px, py, angle_rad, angular_sigma=0.04, length=1500,
                          intensity=intensity)
        # Add color * mask to each channel
        for c in range(3):
            accum[:, :, c] += color[c] * mask
    return np.clip(accum, 0, 255).astype(np.uint8)


def _render_metallic_title(text: str, scale: int,
                            alpha: float = 1.0) -> Image.Image:
    """Render text in metallic-tricolor on transparent background. Returns RGBA PIL.Image."""
    width_px = scaled_font.text_width(text, scale, spacing=4)
    height_px = scaled_font.GLYPH_PIX * scale
    img = Image.new('RGBA', (width_px, height_px), (0, 0, 0, 0))
    pixels = img.load()
    text_pixels = scaled_font.render_text_scaled(
        text, scale, color_fn=tricolor.metallic_tricolor, spacing=4,
    )
    for px, py, rgb in text_pixels:
        a = int(255 * alpha)
        pixels[px, py] = (rgb[0], rgb[1], rgb[2], a)
    return img


def _render_subtitle(text: str, scale: int, alpha: float = 1.0) -> Image.Image:
    """Render text in soft gold on transparent background."""
    width_px = scaled_font.text_width(text, scale, spacing=2)
    height_px = scaled_font.GLYPH_PIX * scale
    img = Image.new('RGBA', (width_px, height_px), (0, 0, 0, 0))
    pixels = img.load()
    text_pixels = scaled_font.render_text_scaled(
        text, scale,
        color_fn=lambda y_norm: tricolor.GOLD,
        spacing=2,
    )
    for px, py, rgb in text_pixels:
        a = int(200 * alpha)
        pixels[px, py] = (rgb[0], rgb[1], rgb[2], a)
    return img


def _blit_centered(canvas: Image.Image, overlay: Image.Image, y: int) -> None:
    """Blit overlay onto canvas centered horizontally at y."""
    x = (canvas.width - overlay.width) // 2
    canvas.paste(overlay, (x, y), overlay)


def _ease_in_out(t: float) -> float:
    """Smoothstep easing: t in [0,1] → [0,1] with soft start and end."""
    t = max(0.0, min(1.0, t))
    return 3 * t * t - 2 * t * t * t


class BootAnimation:
    """Boot animation per D4.3 discipline."""
    fps = FPS
    total_frames = TOTAL_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps

        if t < SCENE1_END:
            # Scene 1: starfield + searchlights
            base = _render_starfield(t)
            composed = _render_searchlights(t, base)
            return Image.fromarray(composed, 'RGB')

        if t < SCENE2_END:
            # Scene 2: RANDOLPH PELICAN III + presents...
            base = _render_starfield(t)
            canvas = Image.fromarray(base, 'RGB')
            local_t = (t - SCENE1_END) / (SCENE2_END - SCENE1_END)   # 0..1 within scene

            # Title fade-in over first 1.0s, hold to 2.5s, fade-out over last 0.5s
            scene_dur = SCENE2_END - SCENE1_END
            scene_t = t - SCENE1_END
            if scene_t < 1.0:
                alpha = _ease_in_out(scene_t)
            elif scene_t > scene_dur - 0.5:
                alpha = _ease_in_out((scene_dur - scene_t) / 0.5)
            else:
                alpha = 1.0

            title = _render_metallic_title("RANDOLPH PELICAN III", scale=6, alpha=alpha)
            subtitle = _render_subtitle("PRESENTS...", scale=3, alpha=alpha * 0.85)

            _blit_centered(canvas, title, HEIGHT // 2 - title.height - 20)
            _blit_centered(canvas, subtitle, HEIGHT // 2 + 40)
            return canvas

        # Scene 3: CodebookOS title + fade-to-black
        base = _render_starfield(t)
        canvas = Image.fromarray(base, 'RGB')
        scene_dur = SCENE3_END - SCENE2_END
        scene_t = t - SCENE2_END

        # Title fade-in over first 1.0s, hold to scene_dur-1.0, fade-to-black last 1s
        if scene_t < 1.0:
            title_alpha = _ease_in_out(scene_t)
            black_alpha = 0.0
        elif scene_t > scene_dur - 1.0:
            title_alpha = 1.0 - _ease_in_out((scene_t - (scene_dur - 1.0)) / 1.0)
            black_alpha = _ease_in_out((scene_t - (scene_dur - 1.0)) / 1.0)
        else:
            title_alpha = 1.0
            black_alpha = 0.0

        title = _render_metallic_title("CODEBOOKOS", scale=10, alpha=title_alpha)
        _blit_centered(canvas, title, (HEIGHT - title.height) // 2)

        if black_alpha > 0:
            black = Image.new('RGBA', canvas.size, (0, 0, 0, int(255 * black_alpha)))
            canvas = Image.alpha_composite(canvas.convert('RGBA'), black).convert('RGB')

        return canvas


def main() -> int:
    anim = BootAnimation()
    default_mp4 = os.path.join(
        os.path.dirname(__file__), 'dist', 'polish_boot_anim.mp4'
    )
    return frames.cli_main(anim, default_mp4)


if __name__ == '__main__':
    sys.exit(main())
