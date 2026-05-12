"""Pod 4.0.G — Demo video composition pipeline.

Composes the 90-second V1.0 SHIP demo video at polish/dist/codebookos_v1.0_demo.mp4
from 9 segments:

  00:00-00:10  polish_boot_anim.mp4  (pre-rendered; 4.0.D)
  00:10-00:20  polish_about.mp4 trimmed to first 10s
  00:20-00:30  B53 fib energy PNG + Ken Burns + "Every opcode declares its cost"
  00:30-00:40  B58 drift anchor PNG + KB + "Byte-exact f32 determinism"
  00:40-00:50  B55 vector composer PNG + KB + "Cross-doctrine composition"
  00:50-01:00  B54 similarity browser PNG + KB + "Maid V1.0 — semantic substrate"
  01:00-01:10  B57 press-X PNG + KB + "Capability-tokenized I/O"
  01:10-01:20  B56 cap lifecycle PNG + KB + "Federation accounting"
  01:20-01:30  Outro card (rendered): "CodebookOS V1.0" + tagline + github URL

Architect ratified static PNGs with Ken Burns for the credential-demo segments
(skip QEMU motion capture; R12 risk outweighs credibility delta). PNGs are real
artifacts from real canary runs against real substrate.

Run:
  python3 polish/build_demo_video.py                              # render to polish/dist/codebookos_v1.0_demo.mp4
  python3 polish/build_demo_video.py <output.mp4>                 # custom output path
"""

import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from polish.common import tricolor, scaled_font, frames   # noqa: E402

# Resolution + framerate (match boot_anim + about for consistent concat)
FPS = 30
WIDTH, HEIGHT = 1280, 720
RESOLUTION = (WIDTH, HEIGHT)
SEGMENT_SECONDS = 10
SEGMENT_FRAMES = FPS * SEGMENT_SECONDS

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
POLISH_DIST = os.path.join(REPO_ROOT, 'polish', 'dist')
BUILD_DIR = os.path.join(REPO_ROOT, 'build')

# Pre-rendered MP4 inputs (4.0.D + 4.0.E)
BOOT_ANIM_MP4 = os.path.join(POLISH_DIST, 'polish_boot_anim.mp4')
ABOUT_MP4 = os.path.join(POLISH_DIST, 'polish_about.mp4')

# Canary PNGs (4.0.F real CBS demos)
CANARY_PNGS = {
    'b53': os.path.join(BUILD_DIR, 'pod40f_b53_fib_energy.png'),
    'b58': os.path.join(BUILD_DIR, 'pod40f_b58_drift_anchor.png'),
    'b55': os.path.join(BUILD_DIR, 'pod40f_b55_vector_composer.png'),
    'b54': os.path.join(BUILD_DIR, 'pod40f_b54_similarity_browser.png'),
    'b57': os.path.join(BUILD_DIR, 'pod40f_b57_press_x.png'),
    'b56': os.path.join(BUILD_DIR, 'pod40f_b56_cap_lifecycle.png'),
}

# Segment definitions: (segment_id, png_key, subtitle)
PNG_SEGMENTS = [
    ('seg_b53', 'b53', 'EVERY OPCODE DECLARES ITS COST'),
    ('seg_b58', 'b58', 'BYTE-EXACT F32 DETERMINISM'),
    ('seg_b55', 'b55', 'CROSS-DOCTRINE COMPOSITION'),
    ('seg_b54', 'b54', 'MAID V1.0 - SEMANTIC SUBSTRATE'),
    ('seg_b57', 'b57', 'CAPABILITY-TOKENIZED I/O'),
    ('seg_b56', 'b56', 'FEDERATION ACCOUNTING'),
]


def _ease_in_out(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return 3 * t * t - 2 * t * t * t


def _ffmpeg_path() -> str:
    p = shutil.which('ffmpeg')
    if p:
        return p
    user_p = os.path.expanduser('~/.local/bin/ffmpeg')
    if os.path.exists(user_p):
        return user_p
    raise RuntimeError("ffmpeg not on PATH and not at ~/.local/bin/ffmpeg")


def _ffprobe_path() -> str:
    p = shutil.which('ffprobe')
    if p:
        return p
    user_p = os.path.expanduser('~/.local/bin/ffprobe')
    if os.path.exists(user_p):
        return user_p
    raise RuntimeError("ffprobe not on PATH and not at ~/.local/bin/ffprobe")


def _draw_text(img: Image.Image, text: str, x: int, y: int, scale: int,
               color, alpha: float = 1.0) -> None:
    """Draw text on img at (x,y); alpha-blend with existing pixels."""
    pixels = scaled_font.render_text_scaled(
        text, scale,
        color_fn=lambda y_norm: color,
        spacing=max(1, scale // 4),
    )
    img_pixels = img.load()
    a = max(0.0, min(1.0, alpha))
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            if a >= 1.0:
                img_pixels[dx, dy] = rgb
            else:
                ex = img_pixels[dx, dy]
                img_pixels[dx, dy] = (
                    int(ex[0] * (1 - a) + rgb[0] * a),
                    int(ex[1] * (1 - a) + rgb[1] * a),
                    int(ex[2] * (1 - a) + rgb[2] * a),
                )


def _draw_metallic_title(img: Image.Image, text: str, x: int, y: int,
                          scale: int, alpha: float = 1.0) -> None:
    pixels = scaled_font.render_text_scaled(
        text, scale, color_fn=tricolor.metallic_tricolor,
        spacing=max(2, scale // 3),
    )
    img_pixels = img.load()
    a = max(0.0, min(1.0, alpha))
    for px, py, rgb in pixels:
        dx, dy = x + px, y + py
        if 0 <= dx < img.width and 0 <= dy < img.height:
            if a >= 1.0:
                img_pixels[dx, dy] = rgb
            else:
                ex = img_pixels[dx, dy]
                img_pixels[dx, dy] = (
                    int(ex[0] * (1 - a) + rgb[0] * a),
                    int(ex[1] * (1 - a) + rgb[1] * a),
                    int(ex[2] * (1 - a) + rgb[2] * a),
                )


class KenBurnsSegment:
    """Ken Burns segment: slow zoom + pan over static PNG + subtitle fade.

    Zoom: starts at full image visible (zoom=1.0); ends at 1.2× zoom panning
    toward center-bottom (where canary final stats typically render).

    Subtitle: gold-on-black-bg bar near bottom; fades in 1s + holds 7s + fades out 2s.
    """
    fps = FPS
    total_frames = SEGMENT_FRAMES
    resolution = RESOLUTION

    def __init__(self, png_path: str, subtitle: str):
        self.png_path = png_path
        self.subtitle = subtitle
        self._source = Image.open(png_path).convert('RGB')
        # Pre-resize source to output resolution if needed
        if self._source.size != RESOLUTION:
            self._source = self._source.resize(RESOLUTION, Image.LANCZOS)

    def render_frame(self, frame_idx: int) -> Image.Image:
        t_norm = frame_idx / max(self.total_frames - 1, 1)
        eased = _ease_in_out(t_norm)

        # Ken Burns: zoom from 1.0 → 1.2; pan center → center-bottom
        zoom = 1.0 + 0.2 * eased
        crop_w = int(WIDTH / zoom)
        crop_h = int(HEIGHT / zoom)
        # Pan: x stays centered; y moves from center to slightly below center
        pan_y_offset = int((HEIGHT - crop_h) * (0.5 + 0.3 * eased))
        pan_x_offset = int((WIDTH - crop_w) * 0.5)

        cropped = self._source.crop((
            pan_x_offset, pan_y_offset,
            pan_x_offset + crop_w, pan_y_offset + crop_h,
        ))
        frame = cropped.resize(RESOLUTION, Image.LANCZOS)

        # Subtitle fade: 0-1s fade in, 1-8s hold, 8-10s fade out
        t_seconds = frame_idx / self.fps
        if t_seconds < 1.0:
            sub_alpha = _ease_in_out(t_seconds)
        elif t_seconds < 8.0:
            sub_alpha = 1.0
        else:
            sub_alpha = _ease_in_out((10.0 - t_seconds) / 2.0)

        if sub_alpha > 0:
            self._draw_subtitle_bar(frame, sub_alpha)

        return frame

    def _draw_subtitle_bar(self, img: Image.Image, alpha: float) -> None:
        # Black bar background (semi-transparent overlay) at bottom
        bar_h = 80
        bar_y = HEIGHT - bar_h - 20
        # Draw a semi-transparent black band
        from PIL import ImageDraw
        overlay = Image.new('RGBA', (WIDTH, bar_h), (0, 0, 0, int(180 * alpha)))
        img.paste(overlay, (0, bar_y), overlay)
        # Render subtitle text in gold with fade
        scale = 3
        text_w = scaled_font.text_width(self.subtitle, scale, spacing=2)
        text_x = (WIDTH - text_w) // 2
        text_y = bar_y + (bar_h - scaled_font.GLYPH_PIX * scale) // 2
        _draw_text(img, self.subtitle, text_x, text_y, scale,
                    color=tricolor.GOLD_HIGHLIGHT, alpha=alpha)


class OutroCard:
    """Outro card: metallic-tricolor 'CodebookOS V1.0' + tagline + github URL.

    10s; fade in 1.5s; hold; fade out last 1s.
    """
    fps = FPS
    total_frames = SEGMENT_FRAMES
    resolution = RESOLUTION

    def render_frame(self, frame_idx: int) -> Image.Image:
        t = frame_idx / self.fps
        img = Image.new('RGB', RESOLUTION, tricolor.BLACK)

        if t < 1.5:
            alpha = _ease_in_out(t / 1.5)
        elif t > 9.0:
            alpha = _ease_in_out((10.0 - t) / 1.0)
        else:
            alpha = 1.0

        # Main title — "CODEBOOKOS V1.0" metallic tricolor
        title = "CODEBOOKOS"
        title_scale = 10
        title_w = scaled_font.text_width(title, title_scale, spacing=4)
        title_x = (WIDTH - title_w) // 2
        title_y = 140
        _draw_metallic_title(img, title, title_x, title_y, title_scale, alpha=alpha)

        # V1.0
        v_scale = 5
        v = "V1.0"
        v_w = scaled_font.text_width(v, v_scale, spacing=3)
        _draw_text(img, v,
                    (WIDTH - v_w) // 2,
                    title_y + scaled_font.GLYPH_PIX * title_scale + 30,
                    v_scale, color=tricolor.GOLD_HIGHLIGHT, alpha=alpha)

        # Stats lines (gold)
        stats = [
            "25.4 KB OF HAND-CRAFTED NASM",
            "CUSTOM CBS PROGRAMMING LANGUAGE",
            "44 CODIFIED ARCHITECTURAL DOCTRINES",
            "AUDITABLE IN A FORTNIGHT",
        ]
        stats_scale = 2
        y_cursor = title_y + scaled_font.GLYPH_PIX * title_scale + 30 + scaled_font.GLYPH_PIX * v_scale + 50
        for line in stats:
            w = scaled_font.text_width(line, stats_scale, spacing=1)
            _draw_text(img, line, (WIDTH - w) // 2, y_cursor, stats_scale,
                        color=tricolor.GOLD, alpha=alpha * 0.9)
            y_cursor += scaled_font.GLYPH_PIX * stats_scale + 14

        # GitHub URL
        url = "GITHUB.COM/RANDOLPHPELICAN/CODEBOOK"
        url_scale = 3
        url_w = scaled_font.text_width(url, url_scale, spacing=2)
        _draw_text(img, url,
                    (WIDTH - url_w) // 2,
                    HEIGHT - 90,
                    url_scale, color=tricolor.GREEN_HIGHLIGHT, alpha=alpha)

        return img


def _trim_mp4(src: str, dst: str, duration_s: float) -> int:
    """Trim src MP4 to duration_s seconds; write to dst. Returns 0 on success."""
    ffmpeg = _ffmpeg_path()
    cmd = [
        ffmpeg, '-y',
        '-i', src,
        '-t', f'{duration_s:.6f}',
        '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
        '-pix_fmt', 'yuv420p',
        '-an',                              # strip audio (silent V1.0 SHIP)
        '-loglevel', 'error',
        dst,
    ]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"FAIL: trim {src} -> {dst}: {r.stderr[:300]}", file=sys.stderr)
        return r.returncode
    return 0


def _concat_mp4s(segment_paths, output_path: str) -> int:
    """Concat MP4s in order via FFmpeg concat demuxer; write to output_path."""
    ffmpeg = _ffmpeg_path()
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        for p in segment_paths:
            f.write(f"file '{os.path.abspath(p)}'\n")
        list_path = f.name
    try:
        cmd = [
            ffmpeg, '-y',
            '-f', 'concat', '-safe', '0',
            '-i', list_path,
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
            '-pix_fmt', 'yuv420p',
            '-an',
            '-loglevel', 'error',
            output_path,
        ]
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            print(f"FAIL: concat: {r.stderr[:500]}", file=sys.stderr)
            return r.returncode
    finally:
        if os.path.exists(list_path):
            os.unlink(list_path)
    return 0


def _verify_mp4(path: str, expected_duration: float, tolerance: float = 0.05) -> bool:
    """Verify MP4 exists + decodes + duration matches expectation."""
    if not os.path.exists(path):
        print(f"FAIL: {path} missing", file=sys.stderr)
        return False
    ffprobe = _ffprobe_path()
    r = subprocess.run(
        [ffprobe, '-v', 'error', '-show_entries', 'format=duration',
         '-of', 'default=noprint_wrappers=1:nokey=1', path],
        capture_output=True, text=True,
    )
    if r.returncode != 0:
        print(f"FAIL: ffprobe {path}: {r.stderr[:200]}", file=sys.stderr)
        return False
    duration = float(r.stdout.strip())
    if abs(duration - expected_duration) > tolerance:
        print(f"FAIL: {path} duration={duration:.3f}s expected={expected_duration:.3f}s "
              f"(tolerance={tolerance:.3f}s)", file=sys.stderr)
        return False
    return True


def build_demo_video(output_path: str) -> int:
    """Build the 90-second master demo video. Returns 0 on success."""
    # Sanity check input artifacts
    inputs = [BOOT_ANIM_MP4, ABOUT_MP4]
    for png in CANARY_PNGS.values():
        inputs.append(png)
    for p in inputs:
        if not os.path.exists(p):
            print(f"FAIL: required input missing: {p}", file=sys.stderr)
            return 1

    os.makedirs(os.path.dirname(output_path) or '.', exist_ok=True)

    with tempfile.TemporaryDirectory() as tmpdir:
        segment_paths = []

        # Segment 1: boot animation (full 10s; copy as-is or re-encode for codec consistency)
        seg1 = os.path.join(tmpdir, 'seg1_boot.mp4')
        print("  [1/9] boot animation (10s)...")
        if _trim_mp4(BOOT_ANIM_MP4, seg1, 10.0) != 0:
            return 1
        segment_paths.append(seg1)

        # Segment 2: about demo first 10s
        seg2 = os.path.join(tmpdir, 'seg2_about.mp4')
        print("  [2/9] about demo trimmed to 10s...")
        if _trim_mp4(ABOUT_MP4, seg2, 10.0) != 0:
            return 1
        segment_paths.append(seg2)

        # Segments 3-8: Ken Burns on each canary PNG
        for i, (seg_id, png_key, subtitle) in enumerate(PNG_SEGMENTS, start=3):
            seg_path = os.path.join(tmpdir, f'{seg_id}.mp4')
            print(f"  [{i}/9] {seg_id} Ken Burns + subtitle '{subtitle}'...")
            anim = KenBurnsSegment(CANARY_PNGS[png_key], subtitle)
            r = frames.export_mp4(anim, seg_path)
            if r != 0:
                return r
            segment_paths.append(seg_path)

        # Segment 9: outro card
        seg9 = os.path.join(tmpdir, 'seg9_outro.mp4')
        print("  [9/9] outro card...")
        outro = OutroCard()
        r = frames.export_mp4(outro, seg9)
        if r != 0:
            return r
        segment_paths.append(seg9)

        # Concat all 9 segments
        print(f"  concat 9 segments -> {output_path}")
        if _concat_mp4s(segment_paths, output_path) != 0:
            return 1

    # Verify final output
    if not _verify_mp4(output_path, expected_duration=90.0, tolerance=0.1):
        return 1

    sz = os.path.getsize(output_path)
    print(f"PASS: demo video at {output_path}")
    print(f"      size={sz} bytes; duration=90s (verified)")
    return 0


def main() -> int:
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(POLISH_DIST, 'codebookos_v1.0_demo.mp4')
    return build_demo_video(out)


if __name__ == '__main__':
    sys.exit(main())
