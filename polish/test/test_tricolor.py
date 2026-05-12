"""Smoke tests for polish.common.tricolor — palette + gradient functions."""
from polish.common import tricolor


def test_primary_palette_in_rgb_range():
    """All primary colors should be valid 8-bit RGB tuples."""
    for color in (tricolor.RED, tricolor.GOLD, tricolor.GREEN, tricolor.BLACK, tricolor.WHITE):
        assert len(color) == 3
        for c in color:
            assert 0 <= c <= 255


def test_lerp_endpoints():
    """Linear interpolation at t=0 returns c1; at t=1 returns c2."""
    c1 = (10, 20, 30)
    c2 = (200, 100, 50)
    assert tricolor.lerp_rgb(c1, c2, 0.0) == c1
    assert tricolor.lerp_rgb(c1, c2, 1.0) == c2


def test_lerp_midpoint():
    """Midpoint between (0,0,0) and (100,100,100) should be (50,50,50)."""
    assert tricolor.lerp_rgb((0, 0, 0), (100, 100, 100), 0.5) == (50, 50, 50)


def test_lerp_clamps_t():
    """Out-of-range t should clamp to [0, 1]."""
    c1 = (10, 20, 30)
    c2 = (200, 100, 50)
    assert tricolor.lerp_rgb(c1, c2, -1.0) == c1
    assert tricolor.lerp_rgb(c1, c2, 2.0) == c2


def test_vertical_tricolor_endpoints():
    """y=0 returns red-band start; y=1 returns green-band end."""
    top = tricolor.vertical_tricolor(0.0)
    bottom = tricolor.vertical_tricolor(1.0)
    # Top should be close to RED; bottom close to GREEN
    assert top == tricolor.RED
    assert bottom == tricolor.GREEN


def test_vertical_tricolor_middle_is_gold():
    """y=0.5 (midpoint) should equal GOLD per the red→gold→green construction."""
    mid = tricolor.vertical_tricolor(0.5)
    assert mid == tricolor.GOLD


def test_metallic_tricolor_returns_valid_rgb():
    """Sweep y_norm across [0,1]; every output should be valid RGB."""
    for i in range(11):
        y = i / 10.0
        c = tricolor.metallic_tricolor(y)
        assert len(c) == 3
        for v in c:
            assert 0 <= v <= 255


def test_rgb_to_bgra_alpha_is_ff():
    """BGRA conversion should have 0xFF alpha (opaque) in high byte."""
    bgra = tricolor.rgb_to_bgra((100, 150, 200))
    assert (bgra >> 24) & 0xFF == 0xFF
    # R = 100 in second-highest byte
    assert (bgra >> 16) & 0xFF == 100
    # G = 150 in middle byte
    assert (bgra >> 8) & 0xFF == 150
    # B = 200 in low byte
    assert bgra & 0xFF == 200
