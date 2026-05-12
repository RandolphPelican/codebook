"""Smoke tests for polish.common.widgets — UI primitives."""
from polish.common import widgets, tricolor


def test_cell_border_rects():
    """Bordered cell should produce 4 border rects (top/bottom/left/right)."""
    cell = widgets.Cell(x=10, y=20, width=100, height=50)
    borders = cell.border_rects()
    assert len(borders) == 4
    for rect in borders:
        assert len(rect) == 5  # (x, y, w, h, rgb)
        x, y, w, h, rgb = rect
        assert w > 0 and h > 0
        assert len(rgb) == 3


def test_cell_fill_rect_inside_border():
    """Fill rect should be smaller than cell extents (inset by border thickness)."""
    cell = widgets.Cell(x=10, y=20, width=100, height=50, border_thickness=3)
    fx, fy, fw, fh, _ = cell.fill_rect()
    assert fx == 13   # x + 3
    assert fy == 23   # y + 3
    assert fw == 94   # width - 2*3
    assert fh == 44   # height - 2*3


def test_iconstub_default_pixels():
    """Default IconStub (frame icon) at scale 1 should produce non-zero pixel count."""
    icon = widgets.IconStub(x=0, y=0, scale=1)
    pixels = icon.pixels()
    assert len(pixels) > 0
    # Frame icon has full top + bottom (16 px each on edges)
    # plus side pixels for middle rows — total = some bounded count
    assert len(pixels) < 8 * 8  # not all pixels are on


def test_iconstub_scales_pixel_count():
    """Doubling scale should quadruple pixel count."""
    icon1 = widgets.IconStub(x=0, y=0, scale=1)
    icon2 = widgets.IconStub(x=0, y=0, scale=2)
    assert len(icon2.pixels()) == 4 * len(icon1.pixels())


def test_mythology_icon_lookup():
    """Known mythology names should return distinct icons."""
    falkor = widgets.mythology_icon('falkor', x=0, y=0)
    atreyu = widgets.mythology_icon('atreyu', x=0, y=0)
    assert falkor.bitmap != atreyu.bitmap


def test_mythology_icon_unknown_falls_back():
    """Unknown name should fall back to 'demo' icon (not crash)."""
    icon = widgets.mythology_icon('nonexistent_surface_name', x=0, y=0)
    assert icon.bitmap == widgets.MYTHOLOGY_ICONS['demo']


def test_banner_defaults_sensible():
    """Banner with defaults should have sane field values."""
    b = widgets.Banner(width=800, text='CodebookOS V1.0')
    assert b.width == 800
    assert b.height == 40
    assert b.text == 'CodebookOS V1.0'
    assert b.text_color == tricolor.GOLD


def test_scrollframe_y_offset_advanceable():
    """ScrollFrame y_offset should be mutable for per-frame scrolling."""
    f = widgets.ScrollFrame(x=0, y=0, width=800, height=600)
    initial = f.y_offset
    f.y_offset += 1
    assert f.y_offset == initial + 1
