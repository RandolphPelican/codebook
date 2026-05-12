"""Pelican III tricolor palette + metallic gradient functions.

Rastafari red/gold/green with metallic shading. Used by boot animation title cards,
About demo accents, and demo video subtitle styling.

D4.1 (polish-vs-credential): these colors are showroom decoration. Substrate has its
own gold-on-black aesthetic anchor (auryn render); polish layer extends with tricolor.
"""

from typing import Tuple

# Primary tricolor — Pelican III brand palette
RED   = (220, 30, 30)    # Rastafari red; slightly desaturated for metallic look
GOLD  = (255, 200, 60)   # Warm gold; not pure yellow
GREEN = (30, 160, 60)    # Forest green; pulled darker for metallic depth

# Tricolor variants for metallic shading
RED_HIGHLIGHT   = (255, 80, 80)
RED_SHADOW      = (140, 10, 10)
GOLD_HIGHLIGHT  = (255, 230, 130)
GOLD_SHADOW     = (180, 130, 20)
GREEN_HIGHLIGHT = (80, 200, 110)
GREEN_SHADOW    = (15, 90, 30)

# Background anchor — gold-on-black from substrate
BLACK = (0, 0, 0)
WHITE = (240, 240, 240)


def lerp_rgb(c1: Tuple[int, int, int], c2: Tuple[int, int, int], t: float) -> Tuple[int, int, int]:
    """Linear interpolation between two RGB colors. t in [0, 1]."""
    t = max(0.0, min(1.0, t))
    return (
        int(c1[0] + (c2[0] - c1[0]) * t),
        int(c1[1] + (c2[1] - c1[1]) * t),
        int(c1[2] + (c2[2] - c1[2]) * t),
    )


def vertical_tricolor(y_norm: float) -> Tuple[int, int, int]:
    """Vertical tricolor gradient: red (top) → gold (middle) → green (bottom).

    y_norm in [0, 1]; y=0 is top. Returns RGB tuple.
    """
    if y_norm < 0.5:
        return lerp_rgb(RED, GOLD, y_norm * 2.0)
    return lerp_rgb(GOLD, GREEN, (y_norm - 0.5) * 2.0)


def metallic_band(y_norm: float, base: Tuple[int, int, int],
                  highlight: Tuple[int, int, int], shadow: Tuple[int, int, int]) -> Tuple[int, int, int]:
    """Metallic shimmer band: shadow → base → highlight → base → shadow vertical sweep.

    Produces the "polished metal" gradient effect across a glyph's vertical extent.
    y_norm in [0, 1].
    """
    # Five-band: shadow at 0.0, base at 0.25, highlight at 0.5, base at 0.75, shadow at 1.0
    if y_norm < 0.25:
        return lerp_rgb(shadow, base, y_norm * 4.0)
    if y_norm < 0.5:
        return lerp_rgb(base, highlight, (y_norm - 0.25) * 4.0)
    if y_norm < 0.75:
        return lerp_rgb(highlight, base, (y_norm - 0.5) * 4.0)
    return lerp_rgb(base, shadow, (y_norm - 0.75) * 4.0)


def metallic_tricolor(y_norm: float) -> Tuple[int, int, int]:
    """Per-pixel metallic tricolor for title-card glyphs.

    Combines vertical_tricolor (broad color band by vertical position) with
    metallic_band shimmer (5-step gradient for "polished metal" depth).

    y_norm in [0, 1]; returns RGB tuple.
    """
    # Determine which color band we're in
    if y_norm < 0.33:
        # Red band; shimmer within
        local_y = y_norm / 0.33
        return metallic_band(local_y, RED, RED_HIGHLIGHT, RED_SHADOW)
    if y_norm < 0.66:
        local_y = (y_norm - 0.33) / 0.33
        return metallic_band(local_y, GOLD, GOLD_HIGHLIGHT, GOLD_SHADOW)
    local_y = (y_norm - 0.66) / 0.34
    return metallic_band(local_y, GREEN, GREEN_HIGHLIGHT, GREEN_SHADOW)


def rgb_to_bgra(rgb: Tuple[int, int, int]) -> int:
    """Convert RGB tuple to BGRA u32 (substrate framebuffer convention)."""
    r, g, b = rgb
    return (0xFF << 24) | (r << 16) | (g << 8) | b
