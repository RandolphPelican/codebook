"""Smoke tests for polish.common.scaled_font — bitmap font rendering."""
from polish.common import scaled_font


def test_glyph_dimensions_consistent():
    """All FONT_8X8 entries must be 8 rows of 8-bit bytes."""
    for ch, rows in scaled_font.FONT_8X8.items():
        assert len(rows) == 8, f"glyph {ch!r} has {len(rows)} rows; expected 8"
        for row in rows:
            assert 0 <= row <= 0xFF, f"glyph {ch!r} row out of byte range: {row:#x}"


def test_glyph_pixels_returns_8x8():
    """glyph_pixels should return 8 rows of 8 bits each."""
    px = scaled_font.glyph_pixels('A')
    assert len(px) == 8
    for row in px:
        assert len(row) == 8
        for bit in row:
            assert bit in (0, 1)


def test_unknown_char_maps_to_space():
    """Unknown char should map to space (all zeros)."""
    px = scaled_font.glyph_pixels('\x01')
    for row in px:
        assert all(bit == 0 for bit in row)


def test_render_glyph_scaled_produces_pixels():
    """Rendering 'A' at scale 4 should produce some foreground pixels."""
    pixels = scaled_font.render_glyph_scaled('A', scale=4)
    assert len(pixels) > 0
    # Each pixel: (x, y, (r, g, b))
    for px, py, rgb in pixels:
        assert isinstance(px, int) and px >= 0
        assert isinstance(py, int) and py >= 0
        assert len(rgb) == 3


def test_render_glyph_scaled_uses_color_fn():
    """color_fn callback should drive pixel color."""
    pixels = scaled_font.render_glyph_scaled(
        'A', scale=2,
        color_fn=lambda y_norm: (255, 0, 0),  # always red
    )
    for px, py, rgb in pixels:
        assert rgb == (255, 0, 0)


def test_text_width_zero_for_empty():
    """Empty string has zero width."""
    assert scaled_font.text_width('', scale=4) == 0


def test_text_width_scales_with_chars():
    """Width should grow linearly with char count."""
    w1 = scaled_font.text_width('A', scale=4, spacing=1)
    w2 = scaled_font.text_width('AB', scale=4, spacing=1)
    w3 = scaled_font.text_width('ABC', scale=4, spacing=1)
    # 8*4 = 32 px per glyph + 1 px spacing between
    assert w1 == 32
    assert w2 == 32 + 1 + 32
    assert w3 == 32 + 1 + 32 + 1 + 32


def test_render_text_scaled_offsets_glyphs():
    """Each glyph in 'AA' should be rendered at proper x offsets."""
    pixels = scaled_font.render_text_scaled('AA', scale=2, spacing=1)
    xs = sorted({px for px, py, _ in pixels})
    # First 'A' x ∈ [0, 16); second 'A' x ∈ [17, 33)
    assert min(xs) >= 0
    assert max(xs) < 33
