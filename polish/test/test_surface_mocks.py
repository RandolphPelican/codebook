"""Smoke tests for Pod 4.0.E in-fiction surface mocks.

Tier 1 pytest discipline per D4.8: verifies each mock instantiates cleanly,
renders frames at scene boundaries without crash, and produces PIL.Image of
expected resolution. Per D4.4 mock-as-narrative — these tests verify the
*rendering pipeline*, not the underlying systems (which intentionally do
not exist at V1.0).
"""
from PIL import Image

from polish.atreyu_editor import AtreyuEditor
from polish.falkor_browser import FalkorBrowser
from polish.rockbiter_scheduler import RockbiterScheduler


def test_atreyu_metadata():
    a = AtreyuEditor()
    assert a.fps == 30
    assert a.total_frames == 450   # 15s × 30fps
    assert a.resolution == (1280, 720)


def test_atreyu_renders_scene_boundaries():
    a = AtreyuEditor()
    for t in (0.5, 6.5, 13.5):
        idx = int(t * a.fps)
        img = a.render_frame(idx)
        assert isinstance(img, Image.Image)
        assert img.size == a.resolution


def test_falkor_metadata():
    a = FalkorBrowser()
    assert a.fps == 30
    assert a.total_frames == 450
    assert a.resolution == (1280, 720)


def test_falkor_renders_scene_boundaries():
    a = FalkorBrowser()
    for t in (0.5, 2.0, 9.0, 13.5):
        idx = int(t * a.fps)
        img = a.render_frame(idx)
        assert isinstance(img, Image.Image)
        assert img.size == a.resolution


def test_rockbiter_metadata():
    a = RockbiterScheduler()
    assert a.fps == 30
    assert a.total_frames == 450
    assert a.resolution == (1280, 720)


def test_rockbiter_renders_scene_boundaries():
    a = RockbiterScheduler()
    for t in (0.5, 8.0, 13.5):
        idx = int(t * a.fps)
        img = a.render_frame(idx)
        assert isinstance(img, Image.Image)
        assert img.size == a.resolution


def test_all_three_mocks_15s_budget():
    """All three in-fiction mocks share the 15-second timing budget per architect spec."""
    for cls in (AtreyuEditor, FalkorBrowser, RockbiterScheduler):
        anim = cls()
        assert anim.total_frames == anim.fps * 15
