"""Shared rendering harness for polish-layer animated apps.

Defines the Animation protocol: an animation provides total_frames, fps, resolution,
and render_frame(frame_idx) -> PIL.Image. Two runners consume it:

  run_live(animation)        PyGame display loop; refresh at animation.fps
  export_mp4(animation, out) Render frames to disk, FFmpeg concat to MP4

Both modes use the same render_frame() — single source of pixel truth per D4.8
(polish-layer verification discipline). Animation correctness verified once;
delivered both as live demo and as video clip.

D4.3 (boot animation discipline) calls into this harness. Future Pod 4.0 chunks
(About demo, in-fiction surface mocks at 4.0.E) inherit the same pattern.
"""

import os
import shutil
import subprocess
import sys
import tempfile
from typing import Protocol, Tuple

from PIL import Image


class Animation(Protocol):
    """Protocol for renderable animations."""
    fps: int
    total_frames: int
    resolution: Tuple[int, int]

    def render_frame(self, frame_idx: int) -> Image.Image:
        """Render frame frame_idx ∈ [0, total_frames); return PIL.Image (RGB)."""
        ...


def t_seconds(animation: Animation, frame_idx: int) -> float:
    """Convert frame index to elapsed seconds."""
    return frame_idx / animation.fps


def run_live(animation: Animation, caption: str = "CodebookOS polish") -> int:
    """Run animation in a live PyGame window. Press ESC or close window to exit.

    Returns 0 on normal exit, 1 on import/init failure.
    """
    os.environ.setdefault('SDL_VIDEODRIVER', 'dummy')   # falls back to dummy if no display
    try:
        import pygame
    except ImportError as exc:
        print(f"FAIL: pygame not installed: {exc}", file=sys.stderr)
        return 1

    pygame.init()
    try:
        screen = pygame.display.set_mode(animation.resolution)
        pygame.display.set_caption(caption)
    except pygame.error as exc:
        # Headless WSL without display — still useful for spike validation
        print(f"INFO: pygame display unavailable ({exc}); ran in dummy mode.")
        pygame.quit()
        return 0

    clock = pygame.time.Clock()
    frame_idx = 0
    running = True

    while running and frame_idx < animation.total_frames:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                running = False

        img = animation.render_frame(frame_idx)
        surf = pygame.image.fromstring(img.tobytes(), img.size, img.mode)
        screen.blit(surf, (0, 0))
        pygame.display.flip()
        clock.tick(animation.fps)
        frame_idx += 1

    pygame.quit()
    return 0


def export_mp4(animation: Animation, output_path: str,
               crf: int = 18, preset: str = 'medium') -> int:
    """Render all frames and compose to MP4 via FFmpeg.

    crf: H.264 quality (18=visually lossless, 23=default, higher=lower quality)
    preset: encoder speed/compression tradeoff
    Returns 0 on success, 1 on failure.
    """
    ffmpeg = shutil.which('ffmpeg')
    if ffmpeg is None:
        ffmpeg = os.path.expanduser('~/.local/bin/ffmpeg')
        if not os.path.exists(ffmpeg):
            print("FAIL: ffmpeg not on PATH and not at ~/.local/bin/ffmpeg", file=sys.stderr)
            print("      Install per polish/README.md", file=sys.stderr)
            return 1

    output_path = os.path.abspath(output_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        # Render frames to PNGs
        for i in range(animation.total_frames):
            img = animation.render_frame(i)
            img.save(os.path.join(tmpdir, f'frame_{i:06d}.png'))
            if i % max(1, animation.total_frames // 10) == 0:
                pct = 100.0 * (i + 1) / animation.total_frames
                print(f"  rendering: {i + 1}/{animation.total_frames} ({pct:.0f}%)",
                      flush=True)

        # FFmpeg compose
        cmd = [
            ffmpeg, '-y',
            '-framerate', str(animation.fps),
            '-i', os.path.join(tmpdir, 'frame_%06d.png'),
            '-c:v', 'libx264',
            '-preset', preset,
            '-crf', str(crf),
            '-pix_fmt', 'yuv420p',
            '-loglevel', 'error',
            output_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"FAIL: ffmpeg exit={result.returncode}\nstderr={result.stderr[:500]}",
                  file=sys.stderr)
            return 1

    if not os.path.exists(output_path) or os.path.getsize(output_path) < 1000:
        print(f"FAIL: output MP4 missing or too small: {output_path}", file=sys.stderr)
        return 1

    sz = os.path.getsize(output_path)
    duration_expected = animation.total_frames / animation.fps
    print(f"PASS: MP4 exported to {output_path}")
    print(f"      size={sz} bytes; expected duration={duration_expected:.2f}s")
    return 0


def cli_main(animation: Animation, default_output: str) -> int:
    """Standard CLI dispatch for polish apps.

    Usage:
      python3 polish/<app>.py             # live PyGame mode (headless OK; SDL dummy)
      python3 polish/<app>.py --mp4 [path]    # export to MP4
    """
    if '--mp4' in sys.argv:
        idx = sys.argv.index('--mp4')
        out = sys.argv[idx + 1] if len(sys.argv) > idx + 1 else default_output
        return export_mp4(animation, out)
    return run_live(animation)
