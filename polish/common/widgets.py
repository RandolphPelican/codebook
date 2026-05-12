"""Polish-layer UI primitives.

PyGame/PIL-agnostic primitives that return rendering data (rectangles, pixel lists)
the caller can blit onto either a PyGame Surface or a PIL Image. Keeps the rendering
backend decoupled so widgets reuse across live apps (PyGame) and frame export (PIL).

D4.1 (polish-vs-credential): these widgets are showroom-only. Substrate has its own
auryn render primitives in boot/auryn.asm (gold-on-black, 8x8 font, native UEFI GOP).
"""

from dataclasses import dataclass
from typing import Tuple, List, Sequence

from .tricolor import GOLD, BLACK, WHITE, RED, GREEN


@dataclass
class Cell:
    """Bordered cell for Bastian home-screen mock + mythology icon slots."""
    x: int
    y: int
    width: int
    height: int
    border_color: Tuple[int, int, int] = GOLD
    fill_color: Tuple[int, int, int] = BLACK
    border_thickness: int = 2

    def border_rects(self) -> List[Tuple[int, int, int, int, Tuple[int, int, int]]]:
        """Return list of (x, y, w, h, rgb) rectangles for the cell border."""
        t = self.border_thickness
        c = self.border_color
        return [
            (self.x, self.y, self.width, t, c),                                # top
            (self.x, self.y + self.height - t, self.width, t, c),              # bottom
            (self.x, self.y, t, self.height, c),                               # left
            (self.x + self.width - t, self.y, t, self.height, c),              # right
        ]

    def fill_rect(self) -> Tuple[int, int, int, int, Tuple[int, int, int]]:
        """Interior fill rect (within the border)."""
        t = self.border_thickness
        return (self.x + t, self.y + t,
                self.width - 2 * t, self.height - 2 * t,
                self.fill_color)


@dataclass
class Banner:
    """Top banner for Bastian home-screen mock or boot animation title cards.

    Spans full width at top of frame; renders centered text in given color.
    """
    width: int
    height: int = 40
    text: str = ""
    text_color: Tuple[int, int, int] = GOLD
    bg_color: Tuple[int, int, int] = BLACK
    y_offset: int = 0


@dataclass
class IconStub:
    """8x8 pixel-art mythology icon placeholder.

    Subclasses or callers provide the 8x8 bitmap data. Default is a frame icon
    (square with corners) suitable as a "TODO icon" placeholder.
    """
    x: int
    y: int
    scale: int = 4   # 8x8 → 32x32 displayed
    bitmap: Sequence[int] = (0xFF, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xFF)
    color: Tuple[int, int, int] = GOLD

    def pixels(self) -> List[Tuple[int, int, Tuple[int, int, int]]]:
        """Return list of (px, py, rgb) for on-pixels of the scaled icon."""
        out = []
        for gy in range(8):
            row = self.bitmap[gy]
            for gx in range(8):
                if (row >> (7 - gx)) & 1:
                    for dy in range(self.scale):
                        for dx in range(self.scale):
                            out.append((self.x + gx * self.scale + dx,
                                        self.y + gy * self.scale + dy,
                                        self.color))
        return out


@dataclass
class ScrollFrame:
    """Scrolling-text frame for About demo.

    Holds positions of text lines; caller advances y_offset per frame to scroll.
    """
    x: int
    y: int
    width: int
    height: int
    bg_color: Tuple[int, int, int] = BLACK
    text_color: Tuple[int, int, int] = GOLD
    line_spacing: int = 4
    y_offset: int = 0   # scroll offset; advance per frame


# Mythology icon bitmaps (8x8; hand-tooled placeholders for V1.0 SHIP)
# Each entry: 8 bytes; bit-7 = left edge; bit-0 = right edge.
MYTHOLOGY_ICONS = {
    'bastian': [0x18, 0x3C, 0x7E, 0xFF, 0xFF, 0x7E, 0x3C, 0x18],   # diamond crown
    'gmork':   [0xC3, 0x66, 0x3C, 0x18, 0x18, 0x3C, 0x66, 0xC3],   # X / wolf eyes
    'auryn':   [0x3C, 0x66, 0xC3, 0xC3, 0xC3, 0xC3, 0x66, 0x3C],   # oval / amulet
    'falkor':  [0x3C, 0x7E, 0xDB, 0xFF, 0xFF, 0xDB, 0x7E, 0x3C],   # dragon scale
    'atreyu':  [0x18, 0x18, 0x3C, 0x7E, 0xFF, 0x7E, 0x3C, 0x18],   # arrow / quest
    'rockbiter': [0xFF, 0xC3, 0xC3, 0xFF, 0xFF, 0xC3, 0xC3, 0xFF], # boulder / lattice
    'empress': [0x18, 0x3C, 0x66, 0xC3, 0xC3, 0x66, 0x3C, 0x18],   # ornate / circle
    'koreander': [0xFF, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xFF], # book / frame
    'southern_oracle': [0x3C, 0x42, 0xA5, 0x99, 0x99, 0xA5, 0x42, 0x3C],  # eye / oracle
    'artax':   [0x66, 0xFF, 0x99, 0xFF, 0xFF, 0x99, 0xFF, 0x66],   # horse / friend
    'demo':    [0x7E, 0x81, 0xBD, 0xA5, 0xA5, 0xBD, 0x81, 0x7E],   # info / about
    'morla':   [0x3C, 0x42, 0x81, 0xA5, 0xA5, 0x81, 0x42, 0x3C],   # turtle / shell
}


def mythology_icon(name: str, x: int, y: int, scale: int = 4,
                   color: Tuple[int, int, int] = GOLD) -> IconStub:
    """Look up mythology icon by name; return IconStub for rendering."""
    bitmap = MYTHOLOGY_ICONS.get(name.lower(), MYTHOLOGY_ICONS['demo'])
    return IconStub(x=x, y=y, scale=scale, bitmap=bitmap, color=color)
