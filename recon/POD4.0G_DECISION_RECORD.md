# Pod 4.0.G Decision Record — Demo video composition pipeline

**Chunk:** Pod 4.0.G — 90-second V1.0 SHIP demo video at `polish/dist/codebookos_v1.0_demo.mp4`. FFmpeg orchestration over 6 canary PNGs + 5 polish MP4s.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** c4bdfc08e6abc32c651ba18958f274982fe36d54 (Pod 4.0.F SEAL)
**V1.0 SEAL substrate contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED — D4.1 byte-lock holds)

---

## Architectural decision ratified: static PNGs + Ken Burns

Architect ratified static PNGs with Ken Burns for the credential-demo segments; skip QEMU motion capture for V1.0 SHIP. **R12 risk** (cross-platform FFmpeg with x11grab/gdigrab/screencapture; sync-to-CBS-state complexity) outweighed the credibility delta. The 6 canary PNGs are real artifacts from real canary runs against real substrate; static framebuffer shots from a working OS still demonstrate it works, especially with subtitle annotations naming what's onscreen.

**No exception was taken** — all 6 canary segments use Ken Burns. The Fibonacci motion-relevance argument was considered; the credibility gain was marginal vs the build-pipeline complexity. Architect's R12 framing was correct.

---

## 90-second master timeline (executed as specified)

| Time | Segment | Source | Subtitle |
|---|---|---|---|
| 00:00–00:10 | boot animation | polish_boot_anim.mp4 (full 10s) | (animation has its own titles) |
| 00:10–00:20 | about demo | polish_about.mp4 trimmed to 10s | (animation has its own narrative scroll) |
| 00:20–00:30 | B53 fib energy | Ken Burns over canary PNG | "EVERY OPCODE DECLARES ITS COST" |
| 00:30–00:40 | B58 drift anchor | Ken Burns over canary PNG | "BYTE-EXACT F32 DETERMINISM" |
| 00:40–00:50 | B55 vector composer | Ken Burns over canary PNG | "CROSS-DOCTRINE COMPOSITION" |
| 00:50–01:00 | B54 similarity browser | Ken Burns over canary PNG | "MAID V1.0 - SEMANTIC SUBSTRATE" |
| 01:00–01:10 | B57 press-X | Ken Burns over canary PNG | "CAPABILITY-TOKENIZED I/O" |
| 01:10–01:20 | B56 cap lifecycle | Ken Burns over canary PNG | "FEDERATION ACCOUNTING" |
| 01:20–01:30 | outro card | rendered (PIL + scaled_font) | "CODEBOOKOS V1.0 / 25.4KB NASM / 44 doctrines / github URL" |

**Final output**:
- File: `polish/dist/codebookos_v1.0_demo.mp4`
- Duration: **90.000000s** (ffprobe-verified exact to 6 decimals)
- Resolution: 1280×720
- Codec: h264 + yuv420p (universal compatibility for YouTube, Gumroad, README embed, VLC/Chrome/Firefox playback)
- Size: **9,867,522 bytes ≈ 9.4 MB** (within 5-15MB target band)

---

## Ken Burns shape

For each canary PNG segment:
- **Zoom**: 1.0 → 1.2× (linear in eased time; ease_in_out smoothstep)
- **Pan**: vertical from center to slightly below center (where canary final stats / energy totals typically render)
- **Subtitle**: bottom semi-transparent black bar (~80px high; y ~ HEIGHT - 100); gold text scale=3
  - Fade in over first 1.0s (ease_in_out)
  - Hold from 1.0s to 8.0s
  - Fade out from 8.0s to 10.0s (ease_in_out)

Visual continuity with the polish/common.tricolor + scaled_font modules per D4.3 (boot animation discipline) tricolor palette + scaled-font conventions.

---

## Verification (D4.8 polish-layer discipline)

| Check | Result |
|---|---|
| Output exists at expected path | ✓ |
| Duration exact (ffprobe to 6 decimals) | **90.000000s** ✓ |
| Codec h264 + pix_fmt yuv420p | ✓ |
| Resolution 1280×720 | ✓ |
| Size within target band (5-15 MB) | 9.4 MB ✓ |
| First frame (t=0s) decodes | ✓ (8,190 bytes PNG sample) |
| Middle frame (t=45s) decodes | ✓ (150,500 bytes PNG sample) |
| Last frame (t=85s) decodes | ✓ (150,606 bytes PNG sample) |
| Visual spot-check (middle frame B55 with subtitle bar) | ✓ Ken Burns zoom visible + "CROSS-DOCTRINE COMPOSITION" subtitle rendered |
| Visual spot-check (outro card) | ✓ metallic tricolor "CODEBOOKOS" + V1.0 + stats + github URL all visible |
| pytest harness | **47/47 PASS** (40 from prior + 7 demo-video tests added) |

### pytest verification tier (D4.8 Tier 2 — output-existence + sanity checks)

7 new tests in `polish/test/test_demo_video.py`:
- `test_demo_video_exists_and_reasonable_size`
- `test_demo_video_duration_exact` (tolerance ±0.1s; ffprobe-driven)
- `test_demo_video_codec_h264_yuv420p`
- `test_demo_video_resolution_1280x720`
- `test_demo_video_frame_decodes` (parametrized over [0s, 45s, 85s])

All gated by ffprobe/ffmpeg availability via `pytest.skip` — graceful fallback when binary tools absent.

---

## Silent audio decision

V1.0 SHIP ships **silent** (no audio track). FFmpeg invocations include `-an` flag throughout to strip any incidental audio. Per architect framing: "Silent audio acceptable for V1.0 SHIP; can be replaced with Suno music in a v1.0.1 patch if architect produces it."

Rationale: silent video plays everywhere (no codec compat issues on muted browsers); explicit "no audio" is honest to "the polish layer is presentation; the substrate is the credential." If the architect produces a track later, a single FFmpeg re-mux replaces the silent track without re-rendering frames.

---

## Files landed at Pod 4.0.G

```
polish/build_demo_video.py             — orchestrator (~280 lines):
                                          KenBurnsSegment class
                                          OutroCard class
                                          _trim_mp4 / _concat_mp4s helpers
                                          _verify_mp4 sanity check
                                          build_demo_video() main entry

polish/test/test_demo_video.py         — 7 new pytest tests (Tier 2 output-existence
                                          + format-sanity + duration + frame-sample)

polish/dist/codebookos_v1.0_demo.mp4   — 9.4 MB; 90.000000s; h264+yuv420p; 1280x720

recon/POD4.0G_DECISION_RECORD.md       — this file
```

---

## Catch profile

- **Build-time catches**: 0
- **Substrate-catches**: 0 (no substrate edits; substrate sha `c9923b8c…` unchanged)
- **Polish-tier catches**: 0
- **Architect-framing-corrections**: 0

D3.44 catch-surface-migration prediction continues: video composition is inheritance-tier (KenBurnsSegment + OutroCard reuse polish.common.frames Animation protocol from 4.0.D); zero catches at any tier.

---

## Substrate state at Pod 4.0.G SEAL

- BOOTX64.EFI sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (**UNCHANGED** — D4.1 byte-lock holds throughout Pod 4.0 arc)
- Two-build determinism: preserved
- All 37 prior + 6 Pod 4.0.F canaries: deductive equivalence (substrate unchanged)
- D4.1 byte-lock empirical chain: 8 consecutive commits with substrate sha invariant (Pod 4.0.C, D, E, F partial, F.7, F.8, F.9, F SEAL, G — `c9923b8c…` at every chunk close)

---

## Pod 4.0 progress

| Sub-pod | Status |
|---|---|
| 4.0.A sit + plan | DONE |
| 4.0.B V1.0 SEAL closeout | DONE (`v1.0-seal` tag) |
| 4.0.C wrapper tooling spike | DONE |
| 4.0.D boot anim + About demo | DONE |
| 4.0.E in-fiction surface mocks | DONE |
| 4.0.F real CBS demos suite (6/6 PASS) | DONE |
| **4.0.G demo video composition** | **DONE (this commit)** |
| 4.0.H documentation pass | pending |
| 4.0.I manifesto PDF + release artifacts | pending |
| 4.0.J V1.0 SHIP — public flip | pending |

---

## Headline moment

**The 90-second master is the primary credential-demonstration artifact for V1.0 SHIP.** Most reviewers — HN visitors, recruiters, future engineers — will see this video before they see the substrate code or the repo. It composes 90 seconds of empirical proof:

- 10s of branded boot animation (polish-tier signal)
- 10s of architectural-truth scroll (credential narrative)
- 60s of 6 real canary PNGs from real substrate runs, each annotated with a doctrine-anchored subtitle
- 10s of outro card with concrete anchors (25.4 KB / 44 doctrines / github URL)

**Every byte of credit is honest**: the canary PNGs are real artifacts from real canary runs against the V1.0 SEAL substrate at `c9923b8c…`. The polish layer animates them (Ken Burns + subtitles) but doesn't fabricate content. The substrate that the video shows is the substrate the viewer can clone and run.

Standing by for **Pod 4.0.H** — documentation pass (GETTING_STARTED.md / CBS_LANGUAGE.md / ARCHITECTURE.md / CONTRIBUTING.md / README.md).
