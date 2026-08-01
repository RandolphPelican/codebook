# polish/ — CodebookOS V1.0 SHIP showroom layer

This directory is the **polish/showroom layer** of CodebookOS V1.0. It is separate from the substrate (`boot/`, `surfaces/`, `tools/`) per **D4.1 — polish-vs-credential separation**.

> **The substrate is the credential.** Pure x86_64 NASM UEFI. ~25 KB of hand-crafted assembly. Auditable in a fortnight. Lives in `boot/`, `surfaces/`, and `tools/atreyu_x86.py` (build-tool compiler).
>
> **The polish is the showroom.** Python apps (PyGame + Pillow + FFmpeg + pandoc). Boot animation, About demo, in-fiction surface mocks, demo video pipeline, manifesto PDF. Lives here in `polish/`.
>
> Both layers ship together as V1.0 SHIP; both are honest about what they are.

## Setup (fresh checkout)

### Python (3.11+ recommended; 3.12 tested)

```bash
cd polish
pip install -r requirements.txt
```

On Windows 11 + WSL2 Ubuntu (John's dev env), use `pip3 install --break-system-packages --user -r requirements.txt`.

### Binary system dependencies (NOT pip-installable)

**FFmpeg** — required for demo video composition and QEMU screen capture.

| OS | Install command |
|---|---|
| Linux (Debian/Ubuntu) | `sudo apt install ffmpeg` |
| macOS | `brew install ffmpeg` |
| Windows | `scoop install ffmpeg` or `choco install ffmpeg` |
| WSL2 Ubuntu | `sudo apt install ffmpeg` (within WSL) |

Verify: `ffmpeg -version` should print version info.

**Alternative if sudo unavailable** (e.g., WSL without sudoers config): static FFmpeg binaries from `johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz` extract a single `ffmpeg` + `ffprobe` binary to `~/.local/bin/` (no system install required). Add `~/.local/bin` to PATH.

**pandoc** — required for manifesto PDF generation.

| OS | Install command |
|---|---|
| Linux | `sudo apt install pandoc` |
| macOS | `brew install pandoc` |
| Windows | `choco install pandoc` |
| WSL2 Ubuntu | `sudo apt install pandoc` (within WSL) |

Pandoc PDF output also needs a PDF engine. Options:
- LaTeX: `sudo apt install texlive-luatex texlive-latex-extra` (heavy; full quality)
- wkhtmltopdf: `sudo apt install wkhtmltopdf` (lighter; HTML→PDF via WebKit)
- weasyprint: `pip install weasyprint` (pip-installable; HTML+CSS→PDF)
- Static pandoc fallback: `github.com/jgm/pandoc/releases` for `~/.local/bin/` install (no sudo).

Verify: `pandoc --version` should print version info.

## Directory layout

```
polish/
├── README.md                  This file
├── requirements.txt           Pinned Python deps
├── common/                    Shared utilities (production)
│   ├── __init__.py
│   ├── tricolor.py            Pelican III red/gold/green metallic palette + gradients
│   ├── scaled_font.py         8x8 bitmap font at 4x/8x scale; mirrors substrate aesthetic
│   └── widgets.py             UI primitives (Cell, Banner, IconStub, ScrollFrame)
├── spike/                     Disposable validation scripts (delete after 4.0.C SEAL)
│   ├── test_pygame_window.py  PyGame window + tricolor text + PNG export
│   ├── test_pillow_export.py  PIL frame stack + animated GIF export
│   ├── test_ffmpeg_compose.py FFmpeg subprocess: PNG sequence → MP4
│   ├── test_pandoc_pdf.py     pandoc subprocess: Markdown → PDF
│   └── test_qemu_capture.py   QEMU launch + FFmpeg screen-capture pipeline validation
└── test/                      pytest harness (production)
    ├── conftest.py            sys.path setup + SDL headless default
    ├── test_tricolor.py       Palette + gradient smoke tests
    ├── test_scaled_font.py    Font renderer smoke tests
    └── test_widgets.py        UI primitive smoke tests
```

## Running

### Spike validation (4.0.C close-criteria)

Run each spike to validate the stack component:

```bash
python3 polish/spike/test_pygame_window.py     # → spike_pygame_frame.png
python3 polish/spike/test_pillow_export.py     # → spike_pillow_anim.gif
python3 polish/spike/test_ffmpeg_compose.py    # → spike_ffmpeg_out.mp4 (or SKIP if no ffmpeg)
python3 polish/spike/test_pandoc_pdf.py        # → spike_pandoc_out.pdf (or SKIP if no pandoc)
python3 polish/spike/test_qemu_capture.py      # → validates QEMU+FFmpeg capture pipeline
```

Each emits `PASS` / `FAIL` / `SKIP` to stdout.

### pytest harness (D4.8 polish-layer verification discipline)

```bash
cd polish
pytest test/ -v
```

Smoke tests verify shared utility correctness (palette returns expected RGB, font renderer produces expected pixel counts, widgets create proper rectangles).

### Headless mode (CI / WSL without X11)

PyGame defaults to `SDL_VIDEODRIVER=dummy` in spike scripts and pytest harness for headless operation. To override (e.g., John's desktop with display):

```bash
SDL_VIDEODRIVER=x11 python3 polish/spike/test_pygame_window.py   # Linux/WSLg
unset SDL_VIDEODRIVER && python3 polish/spike/test_pygame_window.py   # Windows native
```

## Doctrine references

- **D4.1** — Polish-vs-credential separation (the rule enacted by this dir structure)
- **D4.3** — Boot animation discipline (when 4.0.D lands)
- **D4.4** — In-fiction surface discipline (when 4.0.E lands)
- **D4.5** — Demo-program discipline (CBS-pure for credential demos)
- **D4.6** — Release-artifact discipline (demo video + manifesto PDF + USB image)
- **D4.7** — Public-repo-flip discipline (pre-flip checklist; explicit authorization)
- **D4.8** — Polish-layer verification discipline (pytest for Python; output-existence checks for artifacts)

See `recon/POD4.0_RECON_NOTES.md` for HALT 1 architectural calls and the full Pod 4.0 chunk plan (4.0.A through 4.0.J → V1.0 SHIP).

## V1.0 SEAL contract reference

The substrate at V1.0 SEAL is byte-locked at `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`. The polish layer here adds nothing to that contract — substrate stays unchanged through V1.0 SHIP except for OP_READ_KEY addition at Pod 4.0.F (per D4.2). V1.1 reseals the substrate at `58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a` (Pod 5 metabolic enforcement — a credential-tier change, outside the polish layer).

V1.0 SHIP tag (`v1.0-ship`) will mark the full release at Pod 4.0.J — substrate + polish + release artifacts + public repo flip.

---

*Polish makes the credential visible. The credential is the substrate.*
