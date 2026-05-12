# Pod 4.0.E Decision Record — In-fiction surface mocks

**Chunk:** 4.0.E — three Python in-fiction surface mocks (Falkor browser / Atreyu editor / Rockbiter scheduler). Each rendered as PyGame live app + MP4 export via the dual-mode harness from 4.0.D.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** a4b51571e20843fcfce1269393c388bbc43d584e (Pod 4.0.D — boot animation + About demo)
**V1.0 SEAL substrate contract (load-bearing reference):** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED — D4.1 byte-lock holds; pure polish additions only)

> Pod 4.0.E delivers three in-fiction polish apps that give the V1.0 SHIP demo a "populated OS" feel without implementing the underlying systems. Falkor browser shows capability-addressed networking; Atreyu editor shows real CBS source (surfaces/demo_fib_energy.cbs loaded live); Rockbiter scheduler shows energy budgets depleting with deferred-V2.0 surfaces queued. Each is 15.000s exact at 1280×720 H.264. All three reuse the 4.0.D dual-mode harness; no new shared utilities surfaced. One new doctrine entry lands: **D4.4 In-fiction surface discipline** (mock-as-narrative; pure framebuffer painting; honest deferral annotations; framework-test for future polish: does this mock honestly preview a future surface, or does it overpromise?).

---

## D4.4 — In-fiction surface discipline

**The doctrine.** When a polish-tier app mocks a surface that doesn't exist yet at V1.0, it follows the in-fiction surface discipline to keep the credential narrative honest.

### Rule 1 — Mock-as-narrative

The mock IS the narrative preview of the surface. It honestly conveys *what the surface will do at V2.0* through visual evocation, not promise. The viewer should understand "this is what's coming" without believing "this works today." Three signals carry the narrative:

1. **Surface-appropriate visual chrome** that LOOKS like a working app of its category (browser chrome → real browser feel; editor chrome → real editor feel; process monitor chrome → real monitor feel)
2. **Honest content** — when the mock displays text or data, it uses real source from the credential layer where possible (Atreyu editor loads `surfaces/demo_fib_energy.cbs` live), and in-fiction-but-coherent content where no real source exists (Falkor browser shows in-fiction "Falkor Codex" entry; Rockbiter scheduler shows in-fiction queued surface list)
3. **Explicit V2.0 deferral annotation** at the end of the timing budget — every mock fades to a metallic-tricolor title + "V2.0" subtitle. Falkor: "FALKOR WALKS THE WEB - V2.0". Atreyu: "ATREYU WALKS THROUGH IDEAS - V2.0". Rockbiter: "ROCKBITER HOLDS THEM WITH GRIEF - V2.0".

### Rule 2 — Pure framebuffer painting

The mock is **pure framebuffer painting via Pillow** — no underlying systems exist. The browser has no networking; the editor has no buffer model; the scheduler has no process table. Per D4.1 polish-vs-credential separation, the mock lives in `polish/` and never modifies substrate code. The credential narrative is preserved because the boundary is auditable on inspection (any reviewer can grep "browser" in `boot/`, find nothing, confirm "the OS doesn't ship a browser yet").

### Rule 3 — Honest deferral annotation

V2.0 deferral annotations honor the original Neverending Story mythology framing:
- **Falkor** walks the web (lighthearted; flight; traversal)
- **Atreyu** walks through ideas (the warrior; intellectual quest)
- **Rockbiter** holds them with grief (mournful; the original Rockbiter laments the inability to hold; here transformed to "holding them" — the scheduler's queue is held in grief over surfaces not yet built)

The mythology-coherent voice is itself part of the credential — "mythology-coherent architecture" is one of the V1.0 advantages from the About demo. Mocks that reference the mythology honestly extend it; mocks that ignore it would weaken the architectural story.

### Rule 4 — Framework-test for future polish

When deciding whether a polish-tier mock honestly previews a future surface, apply the framework-test:

**Does this mock honestly preview a future surface, OR does it overpromise?**

A mock **honestly previews** when:
- The visual surface is what a V2.0 implementation would actually look like (within reasonable polish-tier framebuffer rendering)
- The narrative claim ("Falkor walks the web") matches the planned future surface (capability-addressed networking is on the V2.0 roadmap per the trinity vision)
- The deferral annotation is explicit and visible at the end

A mock **overpromises** when:
- The visual surface implies behavior the future implementation can't honestly deliver
- The narrative claim creates expectations that exceed the planned scope
- The deferral annotation is missing or hidden in a way that lets viewers believe "this works today"

**V1.0 SHIP three mocks pass the framework-test**:
- Falkor browser: previews capability-addressed networking (#91 codebook-symmetry forward-anchor + V2.0 federated organism vision); mock is in-fiction Codex entry on the SAME concepts the future Falkor implementation would expose
- Atreyu editor: previews a CBS-aware code editor (V2.0 editor surface; Pod 4.0 wrapper-pivot established that polish-tier Python presentations are honest); mock shows real CBS source (zero misrepresentation)
- Rockbiter scheduler: previews substrate-metabolic process monitoring (D3.17 energy accounting + capability-typed scheduling; V2.0 scheduler surface); mock shows real V1.0 substrate processes (Gmork + CBS demos + Maid) plus honest-queued V2.0 surfaces

---

## Three mocks in detail

### Atreyu editor (`polish/atreyu_editor.py`)

**15.000s exact**; 1280×720; 423,334 bytes MP4.

**Layout**:
- Top status bar (36px): `surfaces/demo_fib_energy.cbs` path (gold) + save indicator (red dot during edit window 6-8s; gray otherwise)
- Left gutter (64px): line numbers in dim gray
- Main pane: CBS source loaded live from `surfaces/demo_fib_energy.cbs` with **tricolor syntax accent**:
  - Cost keywords (PRINT, ENERGY_USED, ENERGY_INITIAL) → gold
  - Capability keywords (CONST, RETURN, IF) → red
  - Primitive types (LET, FUNC) → green
  - Comments → dim gray
  - Default text → dim
- Bottom status bar (36px): cursor position + "ATREYU WALKS THROUGH IDEAS" + "INSERT" mode
- Cursor: blinking gold rectangle at target line (1Hz blink); moves and "edit" animation occurs 6-8s

**Honest content**: pulls `surfaces/demo_fib_energy.cbs` at module load. That file is draft CBS source for Pod 4.0.F polish; lands as real surface at this commit. The editor mock displays real CBS, not synthesized stand-in.

**End annotation (last 2s)**: dim overlay + "ATREYU WALKS THROUGH IDEAS" (metallic tricolor, scale 5) + "V2.0" (gold, scale 3).

### Falkor browser (`polish/falkor_browser.py`)

**15.000s exact**; 1280×720; 535,844 bytes MP4.

**Layout**:
- Top chrome (80px): back/forward/refresh buttons (3 outlined squares) + URL bar with `AURYN://RANDOLPHPELICAN.III/CODEX/REALM-TRAVERSAL` + blinking gold cursor
- Tab strip (40px): "FALKOR CODEX" active tab in dark indigo + "+" new-tab button
- Loading bar at page top: gold bar fills first 1.5s then disappears
- Main page (parchment cream background): "FALKOR CODEX - REALM-TRAVERSAL" header + three in-fiction sections:
  - TRUST-ENGINE SEMANTICS (red header; green bullets: CAPABILITIES INSTEAD OF URLS / MAC-PROTECTED PRIMITIVES BETWEEN REALMS / ENERGY ACCOUNTING ACROSS HOPS / NO APP STORES OR GATEKEEPERS OR ADS)
  - CAPABILITY-ADDRESSED NETWORKING (red header; dark body text on parchment)
  - POST-SURVEILLANCE BY DESIGN (red header; "compliance by absence" closing)
- Subtle page scroll: parchment scrolls down 80px over middle 8 seconds (3s→11s)
- Bottom status bar (36px): "FALKOR WALKS THE WEB" (green) + scroll percentage indicator (right)

**End annotation (last 2s)**: dim overlay + "FALKOR WALKS THE WEB" (metallic tricolor) + "V2.0" subtitle.

### Rockbiter scheduler (`polish/rockbiter_scheduler.py`)

**15.000s exact**; 1280×720; 315,827 bytes MP4.

**Layout**:
- Top banner (64px): "ROCKBITER SCHEDULER" (gold, scale 4) + "V1.0" (green, scale 3)
- Column headers (36px): PROCESS | ENERGY | STATUS in bright white on header gray
- Process rows (52px each, alternating shade):
  - **GMORK SESSION** — 1M initial → drains 3K/s → ends at 955K J — green bar — RUNNING
  - **FIB_ENERGY.CBS** — 100K initial → drains 14.2K/s → depletes around 7s — green→gold→red bar — RUNNING (with "* DEPLETED *" indicator post-depletion)
  - **MAID HOUSEKEEPER** — 500K initial → drains 800/s → 488K at end — green bar — WAITING
  - **FALKOR BROWSER** / **ATREYU EDITOR** / **EMPRESS SETTINGS** / **KOREANDER LIBRARY** / **SOUTHERN ORACLE SEARCH** — 0 J, DEFERRED V2.0 (dim gray)
  - **ARTAX COMPANION** — 0 J, QUEUED (dim green)
- Bottom tagline (40px): "EVERY OPCODE DECLARES ITS COST" in gold

**Metabolic discipline made visually load-bearing**: energy bars animate downward across the 15s budget. The substrate's D3.17 per-opcode cost accounting becomes a process-monitor metaphor — each running process consumes joules at a documented rate; depletion is visible; deferred surfaces show zero energy because they don't run.

**End annotation (last 2s)**: dim overlay + "ROCKBITER HOLDS THEM WITH GRIEF" (metallic tricolor, scale 4) + "V2.0" subtitle.

---

## Files landed at Pod 4.0.E

```
polish/atreyu_editor.py                  +300 lines — code editor mock with real CBS source
polish/falkor_browser.py                 +260 lines — browser mock with in-fiction Codex
polish/rockbiter_scheduler.py            +230 lines — process monitor mock with energy bars
polish/test/test_surface_mocks.py         +70 lines — pytest smoke tests for all three
polish/dist/polish_atreyu_editor.mp4      423 KB    — 15.000s exact
polish/dist/polish_falkor_browser.mp4     536 KB    — 15.000s exact
polish/dist/polish_rockbiter_scheduler.mp4 316 KB   — 15.000s exact
surfaces/demo_fib_energy.cbs              +35 lines — draft Fibonacci CBS source (4.0.F refines; loaded by Atreyu mock for honest content)
recon/POD4.0E_DECISION_RECORD.md          this file
```

**Note on `surfaces/demo_fib_energy.cbs`**: this is a CBS source file (credential-tier per D4.1 location `surfaces/`). It lands as a draft at Pod 4.0.E to provide honest content for the Atreyu editor mock; the actual runtime polish happens at Pod 4.0.F (Real CBS demos). The mock loads the file live at module import time — when 4.0.F refines the source, the mock auto-reflects the changes without a polish-layer code edit. Honest provenance preserved end-to-end.

---

## Verification at Pod 4.0.E SEAL

### MP4 exports
| App | Duration (ffprobe) | Size |
|---|---|---|
| Atreyu editor | **15.000000s** | 423,334 bytes |
| Falkor browser | **15.000000s** | 535,844 bytes |
| Rockbiter scheduler | **15.000000s** | 315,827 bytes |

All three: 1280×720, libx264 + yuv420p, FPS 30.

### pytest harness
**40/40 PASS** (33 from 4.0.D + 7 new smoke tests for surface mocks: metadata + scene-boundary renders + 15s-budget verification).

### Substrate state
- BOOTX64.EFI sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (UNCHANGED — verified post-build)
- Two-build determinism: preserved (no substrate edits in 4.0.E; the new `surfaces/demo_fib_energy.cbs` is a CBS source file added to the credential layer, but no `.asm` source or build chain changes)
- 36/36 + B52 canaries: deductive equivalence from 4.0.B SEAL applies; substrate sha unchanged → D4.1 byte-lock holds across all of Pod 4.0.E

### Catch profile
- **Build-time catches**: 0
- **Substrate-catches**: 0
- **Polish-tier catches**: 0
- **Architect-framing-corrections**: 0

D3.44 catch-surface-migration: Pod 4.0.E continues the inheritance-tier maturity established at 4.0.C/D. Three mocks at clean shape; no catches at any tier.

---

## Pod 4.0.E close-criteria review

| Criterion (per architect) | Result |
|---|---|
| Three apps runnable as PyGame windows | ✓ All three apps support live mode via `polish.common.frames.run_live` |
| Three apps renderable to MP4 | ✓ All three apps support `--mp4 [path]` flag |
| Each app hits 15s timing budget exactly | ✓ ffprobe-verified to 6 decimals: 15.000000s for all three |
| pytest harness extended with smoke tests for each | ✓ `test_surface_mocks.py` 7 new tests; 40/40 total PASS |
| Substrate sha unchanged | ✓ `c9923b8c…` byte-locked |
| D4.4 doctrine documented in decision record | ✓ (this document; 4 rules: mock-as-narrative / pure framebuffer / honest deferral / framework-test) |

---

## Architectural moments worth marking

1. **D4.4 framework-test creates V2.0 surface contract via mock**. The Falkor / Atreyu / Rockbiter mocks aren't just visual filler — they make implicit V2.0 commitments that the architecture has to honor. Falkor mock implies V2.0 will have capability-addressed networking; Atreyu mock implies V2.0 will have a CBS-aware editor; Rockbiter mock implies V2.0 will expose substrate-metabolic process state. When V2.0 sit happens, these mocks become **forward-anchored commitments** — V2.0 surfaces must deliver what the V1.0 mock previews, or the mock should be revised.

2. **Honest content via live file load**. The Atreyu editor mock doesn't ship a hardcoded fake CBS string; it loads `surfaces/demo_fib_energy.cbs` at module import. This means: (a) the editor mock auto-reflects 4.0.F runtime polish without polish-layer edits; (b) "the OS that shows its source ships its source" — the file in the screenshot is the same file in the repo. Mock-as-narrative reaches a tighter shape when the content is loaded from the credential layer rather than re-encoded in polish.

3. **Metabolic discipline as visual narrative**. Rockbiter mock makes the substrate's D3.17 per-opcode energy accounting visually load-bearing. The "every opcode declares its cost" tagline (also surfaces in About demo) becomes empirical-feeling: the viewer SEES energy bars deplete; the credential ("energy accounting at opcode level") gains immediate visual confirmation. This is the credential-via-presentation pattern that D4.1 polish-vs-credential separation enables — polish doesn't fake the credential, it makes the real credential more legible.

4. **Mythology coherence through deferral annotations**. The three V2.0 annotations honor the original Neverending Story mythology framing:
   - Falkor (the white luck dragon): "WALKS THE WEB" (lighthearted; flight; effortless traversal)
   - Atreyu (the warrior boy): "WALKS THROUGH IDEAS" (intellectual quest)
   - Rockbiter ("they look like big strong hands, don't they?"): "HOLDS THEM WITH GRIEF" (mournful; the original Rockbiter laments his inability to hold; here transformed — the scheduler holds queued surfaces in grief over their not-yet-built state)

   The mythology-coherent voice is itself part of V1.0's credential claim ("mythology-coherent architecture" appears in About demo). Mocks that reference the mythology extend the credential; mocks that ignored it would have weakened the architectural story.

---

## Pod 4.0.E exit state

- **Substrate**: byte-locked at V1.0 SEAL contract `c9923b8c…`
- **Polish surface**: three in-fiction surface mocks live + MP4 artifacts in `polish/dist/`
- **Doctrine corpus**: D4.1 + D4.3 + D4.4 + D4.8 landed; D4.2 (OP_READ_KEY) defers to 4.0.F; D4.5-D4.7 to later chunks
- **pytest harness**: 40/40 PASS
- **MP4 artifacts ready for 4.0.G demo video composition**:
  - polish_boot_anim.mp4 (4.0.D)
  - polish_about.mp4 (4.0.D)
  - polish_atreyu_editor.mp4 (4.0.E)
  - polish_falkor_browser.mp4 (4.0.E)
  - polish_rockbiter_scheduler.mp4 (4.0.E)

Pod 4.0.F (Real CBS demos polish — pure CBS for credential demos) begins next. The substrate gets its one allowed addition (OP_READ_KEY per D4.2) for the press-X interactive demo; other demos use existing V1.0 capability surface. Each demo lands as `surfaces/demo_*.cbs` + canary verification.
