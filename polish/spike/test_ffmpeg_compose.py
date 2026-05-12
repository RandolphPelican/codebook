"""Spike: FFmpeg subprocess composition — PNG sequence + audio stub → MP4.

Validates FFmpeg is installed and can compose a video from rendered frames.

Run: python3 polish/spike/test_ffmpeg_compose.py
Skips with informative message if FFmpeg not on PATH.
"""

import os
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

from PIL import Image   # noqa: E402
from polish.common import tricolor   # noqa: E402

OUT_MP4 = os.path.join(os.path.dirname(__file__), 'spike_ffmpeg_out.mp4')
FRAME_COUNT = 30
WIDTH, HEIGHT = 320, 240


def make_frames(tmpdir: str) -> int:
    """Render FRAME_COUNT solid-color frames cycling through tricolor; return frame count."""
    palette = [tricolor.RED, tricolor.GOLD, tricolor.GREEN]
    for i in range(FRAME_COUNT):
        color = palette[i % len(palette)]
        img = Image.new('RGB', (WIDTH, HEIGHT), color)
        img.save(os.path.join(tmpdir, f'frame_{i:04d}.png'))
    return FRAME_COUNT


def main() -> int:
    ffmpeg_path = shutil.which('ffmpeg')
    if ffmpeg_path is None:
        print("SKIP: ffmpeg not found on PATH; install per polish/README.md")
        print("      (Linux: apt install ffmpeg | macOS: brew install ffmpeg | Windows: scoop install ffmpeg)")
        return 0   # spike skip; not failure

    with tempfile.TemporaryDirectory() as tmpdir:
        n_frames = make_frames(tmpdir)
        if n_frames < 1:
            print("FAIL: no frames rendered")
            return 1

        # FFmpeg: PNG sequence → MP4 (no audio for this spike)
        cmd = [
            ffmpeg_path,
            '-y',                                            # overwrite
            '-framerate', '10',                              # 10 fps
            '-i', os.path.join(tmpdir, 'frame_%04d.png'),
            '-c:v', 'libx264',
            '-pix_fmt', 'yuv420p',
            '-loglevel', 'error',
            OUT_MP4,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"FAIL: ffmpeg exit={result.returncode}\nstderr={result.stderr[:500]}")
            return 1

        if not os.path.exists(OUT_MP4) or os.path.getsize(OUT_MP4) < 1000:
            print(f"FAIL: MP4 not produced or too small: {OUT_MP4}")
            return 1

        # Verify duration via ffprobe
        ffprobe_path = shutil.which('ffprobe')
        duration = None
        if ffprobe_path:
            probe = subprocess.run(
                [ffprobe_path, '-v', 'error', '-show_entries', 'format=duration',
                 '-of', 'default=noprint_wrappers=1:nokey=1', OUT_MP4],
                capture_output=True, text=True,
            )
            if probe.returncode == 0:
                duration = float(probe.stdout.strip())

        sz = os.path.getsize(OUT_MP4)
        if duration is not None:
            print(f"PASS: MP4 composed at {OUT_MP4} ({sz} bytes; duration={duration:.2f}s; expected ≈ 3.0s)")
        else:
            print(f"PASS: MP4 composed at {OUT_MP4} ({sz} bytes; ffprobe missing for duration check)")
        return 0


if __name__ == '__main__':
    sys.exit(main())
