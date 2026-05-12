"""Smoke tests for polish apps (boot_anim, about_codebookos).

Verifies: each app instantiates cleanly; render_frame() returns a PIL.Image
of expected resolution; spot frames at scene boundaries don't crash.
"""
from PIL import Image

from polish.boot_anim import BootAnimation
from polish.about_codebookos import AboutAnimation


def test_boot_animation_metadata():
    anim = BootAnimation()
    assert anim.fps == 30
    assert anim.total_frames == 300   # 10s × 30fps
    assert anim.resolution == (1280, 720)


def test_boot_animation_renders_first_frame():
    anim = BootAnimation()
    img = anim.render_frame(0)
    assert isinstance(img, Image.Image)
    assert img.size == anim.resolution


def test_boot_animation_renders_scene_boundaries():
    """Render frames at each scene boundary; must not crash."""
    anim = BootAnimation()
    for t in (0.0, 4.0, 7.0, 9.99):
        idx = min(int(t * anim.fps), anim.total_frames - 1)
        img = anim.render_frame(idx)
        assert img.size == anim.resolution


def test_about_animation_metadata():
    anim = AboutAnimation()
    assert anim.fps == 30
    assert anim.total_frames == 1350   # 45s × 30fps
    assert anim.resolution == (1280, 720)


def test_about_animation_renders_first_frame():
    anim = AboutAnimation()
    img = anim.render_frame(0)
    assert isinstance(img, Image.Image)
    assert img.size == anim.resolution


def test_about_animation_renders_all_sections():
    """Render frames in each section; must not crash."""
    anim = AboutAnimation()
    for t in (4.0, 11.0, 19.0, 26.0, 33.0, 41.0):
        idx = int(t * anim.fps)
        img = anim.render_frame(idx)
        assert img.size == anim.resolution
