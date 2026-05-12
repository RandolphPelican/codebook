"""Smoke tests for polish.common.frames — animation harness."""
from PIL import Image

from polish.common import frames


class _StubAnimation:
    fps = 30
    total_frames = 5
    resolution = (320, 240)

    def render_frame(self, frame_idx: int) -> Image.Image:
        return Image.new('RGB', self.resolution, (frame_idx * 50, 0, 0))


def test_t_seconds_basic():
    anim = _StubAnimation()
    assert frames.t_seconds(anim, 0) == 0.0
    assert frames.t_seconds(anim, 30) == 1.0
    assert frames.t_seconds(anim, 15) == 0.5


def test_stub_animation_renders_distinct_frames():
    anim = _StubAnimation()
    # Spot-check that distinct frame indices return distinct pixel data
    img0 = anim.render_frame(0)
    img2 = anim.render_frame(2)
    assert img0.getpixel((0, 0)) != img2.getpixel((0, 0))


def test_animation_protocol_attrs():
    """Animation must expose fps, total_frames, resolution attrs."""
    anim = _StubAnimation()
    assert isinstance(anim.fps, int)
    assert isinstance(anim.total_frames, int)
    assert isinstance(anim.resolution, tuple) and len(anim.resolution) == 2
    assert anim.fps > 0
    assert anim.total_frames > 0
