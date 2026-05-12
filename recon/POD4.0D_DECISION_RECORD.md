# Pod 4.0.D Decision Record — Boot animation + About demo (Python)

**Chunk:** 4.0.D — two parallel polish-layer Python apps; both runnable as standalone PyGame windows AND renderable to MP4 frames via Pillow + FFmpeg for the 4.0.G demo video pipeline.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** 262ffc2b8f092f64a967b39c0790a446597c702d (Pod 4.0.C — wrapper tooling spike)
**V1.0 SEAL substrate contract (load-bearing reference):** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED — D4.1 byte-lock holds; only polish/ additions in this chunk)

> Pod 4.0.D delivers the two narrative polish apps: a 10-second boot animation (searchlights → "RANDOLPH PELICAN III" tricolor title → "CODEBOOKOS" tricolor title with fade-to-black) and a 45-second About demo (architectural-truth scroll with 6 sections + metallic-tricolor section headers). Both apps share a common rendering harness (`polish/common/frames.py`) defining the Animation protocol + dual runners (PyGame live; FFmpeg MP4 export). Both MP4s hit timing budgets to the millisecond (boot_anim 10.000s exact; about 45.000s exact). One new doctrine entry lands: **D4.3 Boot animation discipline** — timing budgets, tricolor palette application, transition shape, fade-curve discipline, and the dual-mode (live + export) rendering pattern. pytest harness expands from 24 to 33 tests; 33/33 PASS.

---

## D4.3 — Boot animation discipline

**The doctrine.** Boot animations (and any narrative polish app with a strict timing budget) follow a discipline that ensures:

1. **Timing budgets are byte-exact** — MP4 export duration matches stated budget to the millisecond (verified via ffprobe). For demo video composition at 4.0.G, every clip's runtime is predictable; the 90-second master timeline composes without slack.
2. **Tricolor palette application is canonical** — Pelican III red/gold/green metallic gradient renders via `polish.common.tricolor.metallic_tricolor`. Per-letter vertical bands (red top → gold middle → green bottom) + metallic shimmer (5-step gradient within each band) produces the "polished metal" feel. The substrate aesthetic anchor (gold-on-black) extends with tricolor for title cards only; non-title text stays gold or dim gold per D3.6 substrate aesthetic.
3. **Transition shape uses ease-in-out** — `3t² - 2t³` smoothstep for scene-to-scene transitions; fade-in / fade-out curves use the same easing. Linear transitions feel mechanical; smoothstep is the cinematic default.
4. **Dual-mode rendering** — every animation provides both live PyGame display AND MP4 export from the same `render_frame(frame_idx) -> PIL.Image` method. Single source of pixel truth; no live-vs-exported divergence. Verified per D4.8 polish-layer verification tier 1 (pytest smoke tests) + tier 3 (spike script + MP4 ffprobe duration check).
5. **Scene structure is declarative** — animations decompose into named scenes with time boundaries; section dispatch by `_section_for_t(t)` returns `(name, t_within_section, scene_dur)`. New scenes / boundary edits are local changes; no temporal re-coupling across scenes.

### Boot animation as exemplar (10-second sequence)

| Scene | Time | Visual |
|---|---|---|
| 1 — Searchlights | 0.0–4.0s | Starfield (120 stars, subtle twinkle) + 3 searchlight beams sweeping with smoothstep convergence; beam pivots off-screen below; angular Gaussian falloff via numpy meshgrid |
| 2 — PELICAN III | 4.0–7.0s | Metallic-tricolor "RANDOLPH PELICAN III" at scale 6 (48-pixel tall glyphs); "PRESENTS..." gold subtitle at scale 3; 1.0s fade-in + 1.5s hold + 0.5s fade-out |
| 3 — CodebookOS | 7.0–10.0s | Metallic-tricolor "CODEBOOKOS" at scale 10 (80-pixel tall glyphs); 1.0s fade-in + 1.0s hold + 1.0s fade-to-black (transition signal for demo video next clip — QEMU substrate boot) |

### About demo as exemplar (45-second narrative)

Six sections, ~7.5s each, each with metallic-tricolor section header + gold body text:

| Scene | Time | Section |
|---|---|---|
| 1 | 0–8s | Header: "CODEBOOKOS V1.0" + tagline "EVERY OPCODE DECLARES ITS COST" |
| 2 | 8–15s | Accomplishment: 30 hrs / 25.4 KB NASM / CBS language / 44 doctrines |
| 3 | 15–23s | Typed Primitives: Sign / Cap / Outcome / Energy / Embedding with one-liners |
| 4 | 23–30s | Future: trinity + surface ecology + hormonal substrate + federated organism |
| 5 | 30–37s | Advantages: auditable / byte-exact / energy-accounted / cap-typed / no app stores / mythology-coherent |
| 6 | 37–45s | Invitation: github.com URL + "AUDIT - EXTEND - TRUST LINE BY LINE" + "HELP US BUILD IT" |

**Voice ratification**: architectural-truth-over-marketing-pitch per architect framing. Substrate facts lead; contributor invitation closes; aspirational tone for future development; no overpromising. The specific anchors (30 hours / 25.4 KB / 44 doctrines / auditable in a fortnight) are *empirical* — measured at Pod 3.12 V1.0 SEAL closeout. Voice draft from POD4.0_RECON_NOTES.md adapted with section-renderer structure.

### Doctrine forward-applicability

D4.3 applies to **any polish app with a strict timing budget**:
- Demo video pipeline (4.0.G) — 90-second master timeline composes from clips that each declare their duration
- Hypothetical V2.0 reveal animations — same discipline (timing budgets exact + dual-mode + ease-in-out + tricolor + declarative scenes)
- Marketing-tier polish (Gumroad video, social-media clips) — inherits the framework

The discipline doesn't apply to:
- Substrate code (D4.1 separation; substrate has its own timing discipline via energy accounting)
- Untimed Python utilities (build tools; test harnesses; etc.)

---

## Files landed at Pod 4.0.D

```
polish/common/frames.py            +193 lines — Animation protocol + run_live + export_mp4 + cli_main
polish/boot_anim.py                +260 lines — BootAnimation class + 3-scene renderer + numpy beam math
polish/about_codebookos.py         +280 lines — AboutAnimation class + 6-section narrative renderer
polish/test/test_frames.py          +35 lines — Animation protocol smoke tests
polish/test/test_apps.py            +50 lines — boot_anim + about smoke tests
polish/dist/polish_boot_anim.mp4   280 KB     — 10.000s exact at 1280x720 (rendered artifact; git-tracked at SEAL)
polish/dist/polish_about.mp4       453 KB     — 45.000s exact at 1280x720 (rendered artifact)
recon/POD4.0D_DECISION_RECORD.md   this file
```

---

## Verification at Pod 4.0.D SEAL

### Pillow + numpy + FFmpeg pipeline

| Test | Result |
|---|---|
| pytest smoke tests | **33/33 PASS** (24 prior + 3 frames + 6 apps) |
| Boot anim MP4 export | PASS; **duration=10.000000s** (ffprobe-verified); 1280×720; 279,718 bytes; libx264 + yuv420p |
| About demo MP4 export | PASS; **duration=45.000000s** (ffprobe-verified); 1280×720; 453,209 bytes; libx264 + yuv420p |
| Visual spot-check | PASS — boot anim scene 1 (3 searchlight beams + starfield); scene 2 (tricolor PELICAN III + PRESENTS); scene 3 (tricolor CODEBOOKOS); About header (CODEBOOKOS V1.0 + tagline); primitives section (5-row list); etc. PNGs saved to /tmp for review. |

### Substrate state

- BOOTX64.EFI sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (UNCHANGED from V1.0 SEAL contract; D4.1 byte-lock holds)
- Two-build determinism: preserved (no substrate edits at 4.0.D)
- 36/36 prior-pod canaries + B52: not re-run at 4.0.D (substrate sha unchanged → deductive equivalence from 4.0.B SEAL applies; D4.1 polish-vs-credential separation guarantees zero substrate ripple)

### Catch profile

- **Build-time catches**: 0
- **Substrate-catches**: 0 (substrate untouched per D4.1)
- **Polish-tier catches**: 0
- **Architect-framing-corrections**: 0

D3.44 catch-surface-migration prediction holds: Pod 4.0.D is inheritance-tier-equivalent (Python rendering inheritance from 4.0.C foundation); catches absent at all tiers.

---

## Pod 4.0.D close-criteria review

| Criterion (per architect) | Result |
|---|---|
| Both apps runnable as PyGame windows (live demo) | ✓ `python3 polish/boot_anim.py` + `python3 polish/about_codebookos.py` launch via `polish.common.frames.run_live`; headless SDL dummy fallback for WSL without display |
| Both apps renderable to MP4 (export pipeline) | ✓ `--mp4 [path]` flag; both produce H.264 yuv420p MP4s |
| Timing budgets hit exactly | ✓ Boot anim 10.000s; About 45.000s (ffprobe-verified to 6 decimals) |
| D4.3 doctrine landed | ✓ (this document) |
| pytest harness for any new shared utilities | ✓ test_frames.py + test_apps.py; 9 new tests; **33/33 PASS** |
| Substrate sha unchanged | ✓ `c9923b8c…` (V1.0 SEAL contract preserved) |

---

## Implementation notes worth surfacing

1. **Performance**: Boot anim renders ~30s offline for 300 frames (numpy beam math dominates ~50ms/frame for scene 1; text rendering ~20ms/frame for scenes 2/3). About anim renders ~120s for 1350 frames (per-pixel PIL alpha blending dominates; could optimize via numpy if it ever becomes a bottleneck — currently ships).

2. **Live mode performance**: At 30fps, frame budget is 33ms. Boot anim scene 1 (numpy beam compute ~50ms) misses the budget in live mode — frames render slightly slower than the wall clock. Acceptable for spike-tier validation; if architect wants smoother live demo, options include pre-rendering frame stack at startup (~30s warmup) or dropping to 15fps for live mode. **Recommendation**: keep current shape; live mode is for local-machine review, not credential demonstration; MP4 export is the credential artifact and runs at correct framerate by construction.

3. **About demo per-pixel rendering**: each frame's text uses PIL `image.load()` + per-pixel write — slow but correct. Optimization candidates: cache rendered text overlay images per (text, scale, alpha) tuple (animation re-renders identical text per frame). Defer until 4.0.G if demo video render time becomes a constraint; current 120s export is acceptable.

4. **Font extent**: `polish.common.scaled_font` ships 38 glyphs (A-Z, 0-9, space + `.:/`-). About demo + boot anim use ASCII uppercase + period + space; no missing characters. If future polish apps need lowercase / extended ASCII, the font module accepts new entries trivially (each glyph is 8 bytes).

5. **Dual-mode rendering design proven**: every animation provides one `render_frame(frame_idx)` method; both live (PyGame) and export (PIL→FFmpeg) consume it. No code path bifurcates. D4.3 codifies this as the canonical pattern; future polish apps (in-fiction mocks at 4.0.E, About flourish-frames if architect wants them, etc.) inherit.

6. **The metallic-tricolor effect at scale 10** (used for CODEBOOKOS title) produces 80-pixel-tall glyphs with visible vertical color bands (red→gold→green) + metallic shimmer within each band. The chunky pixel-art aesthetic IS on-brand for a 64KB-class bare-metal OS — looks intentional, not lazy. Matches the substrate's auryn render aesthetic (8x8 font + gold-on-black + chunky text).

---

## Pod 4.0.D exit state

- **Substrate**: unchanged at V1.0 SEAL contract `c9923b8c…`
- **polish/ scope**: boot animation + About demo both production-quality + MP4-exportable
- **Doctrine corpus**: D4.1 + D4.3 + D4.8 landed; D4.2 (OP_READ_KEY) defers to 4.0.F; D4.4-D4.7 to later chunks
- **pytest harness**: 33/33 PASS (24 → 33 since 4.0.C; +9 tests across frames + apps)
- **MP4 artifacts**: 2 production-quality clips ready for 4.0.G demo video composition pipeline
- **Demo video timeline anchors**:
  - 00:00–00:10  Boot animation (Python; rendered MP4 at polish/dist/polish_boot_anim.mp4)
  - 00:25–01:10  About demo (Python; rendered MP4 at polish/dist/polish_about.mp4) — note this is 45s; demo video master timeline at 4.0.G will trim or accelerate per architect's "00:25-00:35 About demo" framing

Pod 4.0.E (in-fiction surface mocks: Falkor browser / Atreyu editor / Rockbiter scheduler) begins next. The shared rendering harness (`polish.common.frames`) and visual primitives (`polish.common.widgets`) make the surface mocks lightweight to build.
