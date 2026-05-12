"""Output-existence + duration + frame-sampling smoke tests for the V1.0 SHIP demo video.

Tier 2 verification per D4.8 (polish-layer verification discipline):
existence + format-sanity + duration ± tolerance + sampled-frames decode.
Not byte-exact (polish artifacts don't ship byte-exact; substrate canaries do).
"""
import os
import shutil
import subprocess

import pytest

DEMO_VIDEO = os.path.abspath(os.path.join(
    os.path.dirname(__file__), '..', 'dist', 'codebookos_v1.0_demo.mp4'
))

EXPECTED_DURATION = 90.0
DURATION_TOLERANCE = 0.1   # seconds
MIN_SIZE = 1_000_000       # 1 MB lower bound
MAX_SIZE = 20_000_000      # 20 MB upper bound (target band 5-15MB per architect)


def _ffprobe():
    return shutil.which('ffprobe') or os.path.expanduser('~/.local/bin/ffprobe')


def _ffmpeg():
    return shutil.which('ffmpeg') or os.path.expanduser('~/.local/bin/ffmpeg')


@pytest.fixture(scope='module')
def demo_video_path():
    """Return the demo video path; skip module if not present."""
    if not os.path.exists(DEMO_VIDEO):
        pytest.skip(f"demo video not built at {DEMO_VIDEO}; run polish/build_demo_video.py first")
    return DEMO_VIDEO


def test_demo_video_exists_and_reasonable_size(demo_video_path):
    """Output file exists and falls within target size band."""
    sz = os.path.getsize(demo_video_path)
    assert sz >= MIN_SIZE, f"demo video too small: {sz} bytes (min {MIN_SIZE})"
    assert sz <= MAX_SIZE, f"demo video too large: {sz} bytes (max {MAX_SIZE})"


def test_demo_video_duration_exact(demo_video_path):
    """Duration matches 90s ± 0.1s via ffprobe."""
    ffprobe = _ffprobe()
    if not os.path.exists(ffprobe):
        pytest.skip("ffprobe not available")
    result = subprocess.run(
        [ffprobe, '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'default=noprint_wrappers=1:nokey=1', demo_video_path],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, f"ffprobe failed: {result.stderr}"
    duration = float(result.stdout.strip())
    assert abs(duration - EXPECTED_DURATION) <= DURATION_TOLERANCE, \
        f"duration={duration}s expected={EXPECTED_DURATION}s ± {DURATION_TOLERANCE}s"


def test_demo_video_codec_h264_yuv420p(demo_video_path):
    """Video codec = h264; pixel format = yuv420p (universal compatibility)."""
    ffprobe = _ffprobe()
    if not os.path.exists(ffprobe):
        pytest.skip("ffprobe not available")
    result = subprocess.run(
        [ffprobe, '-v', 'error', '-select_streams', 'v:0',
         '-show_entries', 'stream=codec_name,pix_fmt',
         '-of', 'default=noprint_wrappers=1', demo_video_path],
        capture_output=True, text=True,
    )
    assert result.returncode == 0
    assert 'codec_name=h264' in result.stdout
    assert 'pix_fmt=yuv420p' in result.stdout


def test_demo_video_resolution_1280x720(demo_video_path):
    """Resolution is 1280x720."""
    ffprobe = _ffprobe()
    if not os.path.exists(ffprobe):
        pytest.skip("ffprobe not available")
    result = subprocess.run(
        [ffprobe, '-v', 'error', '-select_streams', 'v:0',
         '-show_entries', 'stream=width,height',
         '-of', 'default=noprint_wrappers=1', demo_video_path],
        capture_output=True, text=True,
    )
    assert 'width=1280' in result.stdout
    assert 'height=720' in result.stdout


@pytest.mark.parametrize('seek_seconds', [0, 45, 85])
def test_demo_video_frame_decodes(demo_video_path, seek_seconds, tmp_path):
    """Sampled frames at 0s, 45s, 85s decode without error."""
    ffmpeg = _ffmpeg()
    if not os.path.exists(ffmpeg):
        pytest.skip("ffmpeg not available")
    out = tmp_path / f"frame_{seek_seconds}.png"
    result = subprocess.run(
        [ffmpeg, '-y', '-ss', str(seek_seconds), '-i', demo_video_path,
         '-frames:v', '1', '-loglevel', 'error', str(out)],
        capture_output=True, text=True,
    )
    assert result.returncode == 0, f"frame at {seek_seconds}s failed to decode: {result.stderr}"
    assert out.exists(), f"frame at {seek_seconds}s not written"
    assert out.stat().st_size > 1000, f"frame at {seek_seconds}s too small"
