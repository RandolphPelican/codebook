# Pod 4.0 Recon Notes — V1.0 SHIP (resume-piece polish campaign) HALT 1

**Status:** Informal HALT 1 recon report. Pod 4.0 = whole-arc directive (~55-90 architect-hours); 8 deliverable categories; full creative freedom inside hard constraints. This recon surfaces architectural calls, chunk-plan, risk register, and open questions BEFORE any Pod 4 code lands.

**Entry HEAD:** e5638c690d8e0de1d5becbe3a2055c0b68de6bfa (Pod 3.11 SEAL — Maid maintains)
**Entry contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (canonical Pod 3.11 BOOTX64.EFI)
**Three-oracle:** ✓ HEAD = origin/main = ls-remote at e5638c6
**Pod 3.12 status:** sit-prep complete (POD3.12_RECON_NOTES.md exists); NOT sealed; absorbed into Pod 4.0 per architect directive (4.0.B = V1.0 SEAL closeout)

---

## Framing

V1.0 SHIP transitions the substrate from "build to learn" mode to "build to show" mode. The credential is the empirical anchor: a complete custom programming language AND a complete bare-metal OS, both demonstrably working, both built solo in 30 architect-hours over 3 months. The polish surfaces this credential unambiguously.

**Two contract refs across Pod 4.0**:
- **V1.0 SEAL contract** (Pod 3.12 SEAL; canon-binding for the 6 Maid capability surface) — load-bearing reference for regression
- **V1.0 SHIP contract** (Pod 4.0 final; what gets flashed to USB / released publicly) — the substrate enriched with polish, animations, demos, branding

Pod 4.0 work ADDS to substrate without rolling back V1.0 capability surface. SEAL canaries (36/36 prior-pod + B52 + B53) continue passing at every Pod 4.0 chunk; NEW canaries (B54-B65+) verify Pod 4.0 deliverables.

---

## Architectural calls requiring HALT 1 ratification

### Call 1 — Pod 3.12 V1.0 SEAL absorption

Architect directive: "4.0.B — Pod 3.12 V1.0 SEAL closeout" folds Pod 3.12 SEAL into Pod 4.0.B.

**TB reading**: Pod 3.12 V1.0 SEAL = a distinct empirical milestone (canon-binding moment; v1.0 tag; D3.43/D3.44 land) executed AS chunk 4.0.B. The V1.0 SEAL commit + tag happen at 4.0.B closure; everything after Pod 3.12 SEAL is Pod 4.0 polish/ship work landing as subsequent commits.

**Recommendation**: ratify Pod 3.12 SEAL as the SAME commit that ends 4.0.B — single tag (v1.0) marks V1.0 capability canon completion. Pod 4.0.C onward extends substrate from that anchor; the v1.0 tag stays load-bearing as regression reference.

### Call 2 — Doctrine numbering: D3.45+ continuation or D4.1+ new family?

Doctrine corpus currently at D3.42; Pod 3.12 plans D3.43 + D3.44. Post-V1.0-SEAL Pod 4.0 work introduces polish/ship architectural decisions (boot animation rendering, branding palette, public-repo-flip discipline, etc.).

**Option (a) Continue D3.X** — Pod 4.0 doctrines land as D3.45, D3.46, D3.47+. Treats V1.0 SHIP as resolution of Pod-3-family arc.
**Option (b) Open D4.X** — Pod 4.0 introduces D4.1, D4.2+ as "polish/release doctrine family." V2.0 starts D5.X+.

**TB recommendation**: **(b) Open D4.X family**. Pod 4.0 is the canonical Pod-4 series (Pod 4.0 / 4.0.A-J); doctrines belong to that family. D4.X cleanly separates "V1.0 capability canon" (D3.X) from "V1.0 SHIP polish canon" (D4.X). V2.0 substrate-feature work would open D5.X.

Counter-argument: D3.X has been the embedding/substrate-USE arc; Pod 4.0 IS still in that arc spiritually. But pragmatically: D4.X namespace makes the V1.0 SEAL ↔ V1.0 SHIP separation explicit.

### Call 3 — Binary size narrative honesty

**Empirical state**: `build/BOOTX64.EFI` = **5,243,904 bytes** (5MB). PE32+ image has .text section at 5MB (`TEXT_RAWSZ=0x500000` from Pod 3.7 expansion); BSS pools (embedding 3.2MB + outcome 320KB + cap/sign/energy/scratch) live within the .text reserved space because flat-binary mode doesn't allocate separate BSS.

**Architect framing claims**: "64KB substrate, energy accounting at opcode level" — narrative.

**Defensible reframings**:
- (a) "64KB substrate" = actual NASM source lines compiled to opcodes (excluding BSS reservations) ≈ ~50-100KB code; honest claim if measured
- (b) "5MB image including 5MB BSS reservation for substrate state" — honest about the file; less marketing-clean
- (c) "Substrate code is auditable in a fortnight; image size is a function of BSS reservations for embedding pool, outcome pool, etc." — process claim, not byte claim

**TB recommendation**: SURFACE this at HALT 1. The public narrative needs to be honest. The "auditable in a fortnight" claim is unambiguously true regardless of byte count; lead with that. If we want "64KB" branding, MEASURE actual code bytes (TEXT - BSS - padding) and validate the claim empirically; ELSE drop "64KB" and use "auditable substrate" or "5MB image with 3.2MB embedding pool reservation" or similar.

**Action item for 4.0.A**: measure actual code byte count; report; ratify narrative.

### Call 4 — Atreyu surface vs atreyu_x86.py tool naming

`tools/atreyu_x86.py` is the CBS bytecode COMPILER (build-time tool). `boot/atreyu.cbs` exists as a stub CBS program. Architect directive picks Atreyu as one of the 3 visual-mock stubs ("Atreyu walks through ideas" → editor surface).

**Naming tension**: Atreyu-the-tool (compiler) vs Atreyu-the-surface (editor mock). Both legitimate per Neverending Story mythology — Atreyu the warrior walks through ideas, brings them into being. Compiler IS bringing ideas into being.

**Options**:
- (a) Dual-use is fine; tool is build-time; surface is user-facing — same mythology axis; no rename needed
- (b) Rename `atreyu_x86.py` to `cbs_forge.py` or similar; free up Atreyu name for editor surface exclusively
- (c) Rename surface to a different name; Atreyu stays the compiler

**TB recommendation**: (a) keep dual-use. Tool ≠ surface; the disambiguation is by layer (build-time vs runtime) not by name collision. Same precedent as codebook (substrate-private write vs dispatch-runtime read per D3.32).

### Call 5 — Press-X interactive demo viability

**Substrate state**: keyboard input exists via UEFI ConIn (used by Bastian for menu nav, by Gmork for shell commands). **No CBS-level OP_READ_KEY opcode**; CBS programs can't access keyboard reads.

**Three paths**:
- (a) Add `OP_READ_KEY` to CBS opcode space (likely 0xF6 in D3.34 embedding-tier-extensions row — though it's not embedding-tier; or new row 0xA0 area); requires substrate change + new doctrine entry + canary
- (b) Skip press-X demo; replace with a non-interactive substitute (e.g., "energy-budget visualization on auto-replay")
- (c) Implement press-X as NATIVE substrate demo mode (NASM-rendered; not a CBS program); architect directive says "Each demo runs as a CBS program loaded by Gmork" so this departs from spec

**TB recommendation**: **(a) add `OP_READ_KEY`**. Cost: ~1 new opcode + ~40-line handler reusing `native_keyboard_read` + 1 doctrine entry (D4.1 maybe — "CBS interactive input surface; first user-program-driven keyboard input opcode at V1.0 SHIP"). Benefit: press-X demo lands as a CBS program per spec; substrate gains a genuinely useful capability (CBS programs can be interactive); future demos can leverage keyboard input.

Risk: substrate change at V1.0 SHIP (post-SEAL). Mitigation: ratify D4.1 explicitly; new opcode is additive, doesn't affect V1.0 SEAL capability surface; canary B59 (or similar) verifies press-X end-to-end.

Alternative: **(b) skip with substitute** if architect prefers V1.0 SEAL contract truly frozen + only polish/cosmetics in Pod 4.0. This is the conservative path.

### Call 6 — Binary size budget for Pod 4.0 additions

Current 5MB; Pod 4.0 adds: boot animation (~50-100KB code + glyph data), Bastian polish (~50KB), 5-6 demos (~10-20KB each as CBS), in-fiction surfaces (~30-50KB), About demo (~20KB), `OP_READ_KEY` if ratified (~5KB). Total Pod 4.0 addition: ~200-400KB of code + assets.

**Recommended budget**: hard ceiling at **~6MB BOOTX64.EFI** at SHIP. Above that, stop adding substrate features; ship without optional 6th demo or simplified animation.

**TB recommendation**: ratify 6MB ceiling. Track binary size at every chunk SEAL; if approaching ceiling, surface to architect for prioritization.

### Call 7 — Public-repo-flip authorization

GitHub repo currently private (presumably; or already public — TB to verify at 4.0.J). Flipping private→public is **one-way, affects shared state visible to the world, irreversible (effectively)**.

Per TB's standing "Executing actions with care" discipline: actions visible to others / affecting shared state require explicit user confirmation before action. Repo-flip is the prototype of this category.

**TB recommendation**: at 4.0.J, BEFORE flipping the repo public, present a final go/no-go checklist to architect; flip ONLY on explicit `AUTHORIZE FLIP` confirmation. The checklist:
- All canaries pass at V1.0 SHIP contract
- README.md polished
- Demo video uploaded + embedded
- Release artifacts ready
- Manifesto PDF exported
- HN/Reddit drafts ready (but NOT published per architect "don't publish — wait for John's go signal")

### Call 8 — Third-party platform actions (Lulu / Gumroad / YouTube / GitHub Public)

These are OUT OF SCOPE for TB direct execution:
- **Lulu print-on-demand**: requires Lulu account + cover design + interior file upload; TB cannot execute (no Lulu credentials; TB doesn't have shell access to upload to Lulu).
- **Gumroad listing**: requires Gumroad account + listing setup + payment routing; TB can draft listing copy but not create the listing.
- **YouTube upload**: John's channel; TB cannot upload without explicit channel access.
- **GitHub repo public flip**: TB CAN execute via `gh` CLI (if `gh` is authenticated to John's account), but per Call 7, only on explicit authorization.

**TB recommendation**: split deliverables into TB-executable (substrate code, CBS demos, docs, draft texts) and architect-executable (third-party platform actions). TB completes drafts + artifacts; architect executes the platform actions. Pod 4.0.J SEAL gates on architect-executed parts being complete; the gate is "drafts ready + artifacts exported," not "drafts published."

### Call 9 — V1.0 SHIP contract vs V1.0 SEAL contract

**V1.0 SEAL contract** (Pod 3.12 closeout / 4.0.B): canon-binding sha; capability surface frozen; regression reference.

**V1.0 SHIP contract** (4.0.J final): polished substrate sha; user-visible artifact; what gets flashed.

Both are load-bearing as reference points. SEAL contract verifies "V1.0 capabilities work"; SHIP contract verifies "V1.0 ships with polish that doesn't break capabilities."

**TB recommendation**: record both shas in the eventual V1.0 SHIP commit message; both are listed in RECONSTITUTION v11; both stay valid as canon-anchored reference points across Pod 4.0 history.

---

## Chunk plan (Pod 4.0.A through 4.0.J)

| Chunk | Identity | Substrate scope | Doctrine candidates | Risk |
|---|---|---|---|---|
| 4.0.A | This recon (sit + arch calls) | none | none (sit) | low |
| 4.0.B | Pod 3.12 V1.0 SEAL closeout | D3.43 broad + D3.44 + RECONSTITUTION v11; close #84/#85/#93; empirical 36/36 + B52 regression; commit v1.0 tag | D3.43 + D3.44 (per Pod 3.12 recon) | low-med (substantial doc; light substrate) |
| 4.0.C | Boot animation NASM (searchlights + Pelican III + CodebookOS title) | `boot/anim.asm` ~600-1000 lines; 32x32 font scale-up + tricolor gradient renderer; sequencing logic | D4.1 boot-animation discipline (timing budgets, fade-in/fade-out shape) | med-high (NASM complexity; framebuffer animation) |
| 4.0.D | Bastian polish + branding (bordered cells + mythology icons + banner + tagline + stub coming-soon text) | bastian.asm edits ~200-400 lines; icon pixel-art data | D4.2 home-screen brand discipline | low-med |
| 4.0.E | Interactive demos × 5-6 sub-chunks | mostly CBS source (.cbs files); 1 substrate addition (OP_READ_KEY if Call 5 (a) ratified) | D4.3 demo-program discipline; D4.x interactive-input opcode (if Call 5 (a)) | med (CBS development; OP_READ_KEY substrate change) |
| 4.0.F | In-fiction visual surfaces (Falkor/Atreyu/Rockbiter mocks) | 3 surface programs (could be CBS or substrate-native rendering); each ~100-200 lines | D4.4 in-fiction surface discipline (mock-as-narrative) | low (pure framebuffer painting) |
| 4.0.G | About demo (praise + future + invite) | 1 CBS program ~200-300 lines; scrolling text + visual flourishes | possibly D4.5 narrative-CBS discipline | low |
| 4.0.H | Documentation pass (GETTING_STARTED / CBS_LANGUAGE / ARCHITECTURE / CONTRIBUTING / README) | 5 .md files; ~2000-3000 lines total | none (doc) | low-med (substantial volume) |
| 4.0.I | Demo video + release artifacts + manifesto PDF | QEMU capture pipeline; video + PDF + draft files | D4.6 release-artifact discipline | high (capture pipeline complexity; PDF export tooling; ~40-60 page manifesto) |
| 4.0.J | V1.0 SHIP — public flip + release drafts + tag pushes | mostly orchestration; repo flip (architect-authorized); drafts polished | D4.7 public-repo-flip discipline | low (mostly already-prepared artifacts) |

**Total estimated chunks**: 10 top-level (A-J), with E having 5-6 sub-chunks (E.1-E.6).

**Per-chunk discipline** (carry forward from Pod 3.X):
- Foreground-only standing rule (no background watchers; ~590s timeout per shell; split regression as needed)
- Three-oracle verification at every SEAL
- Two-build determinism re-confirmed at every SEAL
- Empirical regression of prior-pod canaries + new canaries at every SEAL
- D3.37 NASM RIP-relative discipline applies (no `[rel sym + reg*scale]`; use `lea base + idx*scale`)
- D3.41 raw-emitter literal-id forge-order comment-tagging applies

---

## Risk register

| # | Risk | Probability | Severity | Mitigation |
|---|---|---|---|---|
| R1 | Boot animation NASM complexity overruns time budget | high | med | Scope animation generously; consider 4x scale-up over hand-crafted 32x32 font; accept "chunky pixel-art" aesthetic as on-brand for 64KB-class OS |
| R2 | Press-X demo requires OP_READ_KEY substrate addition | high | low | Per Call 5, ratify D4.1 OP_READ_KEY at HALT 1; demo lands at 4.0.E |
| R3 | Binary size grows past target | high | low | Per Call 6, 6MB ceiling; surface at every chunk SEAL if approaching |
| R4 | Regression time at every SEAL (~50 canaries × ~25s = ~21min/run × ~10 SEALs = 3.5hrs total) | certain | low | Foreground-only discipline; split regression; accept time cost |
| R5 | Demo video capture pipeline complexity | med | med | QEMU has built-in screen recording (-display options); validate pipeline at 4.0.I.A before capture |
| R6 | Manifesto PDF export tooling | med | med | Pandoc or similar from existing .md sources; pre-validate at 4.0.I |
| R7 | Substrate-catch during boot animation (untested NASM rendering) | med | med | Catch surface = canary-tier (per D3.44 tri-tier doctrine prediction for inheritance pods); B54 verifies animation completes; if it doesn't, fix surface |
| R8 | Public-repo-flip premature | low | high | Per Call 7, explicit `AUTHORIZE FLIP` gate at 4.0.J |
| R9 | "64KB substrate" narrative honesty | low | med | Per Call 3, measure actual code bytes; ratify narrative at 4.0.A SEAL |
| R10 | Cross-pod canary regression at SHIP from substrate growth | low | high | Empirical regression at every SEAL; if regression, halt and fix before continuing |

---

## Doctrine candidates (Pod 4.0 surface)

If Call 2 ratifies D4.X numbering:

- **D4.1** — CBS interactive input surface: `OP_READ_KEY` discipline; CBS programs can read keyboard via substrate-mediated UEFI ConIn; first user-program-driven input opcode at V1.0 SHIP
- **D4.2** — Boot animation discipline: timing budgets (~8-10s total), framebuffer rendering primitives, gradient color interpolation, sequencing as substrate-private (pre-MIND-phase)
- **D4.3** — Home-screen brand discipline: Bastian as branded surface; mythology icons; tagline + banner; coming-soon convention for stub surfaces
- **D4.4** — Demo-program discipline: CBS programs as user-facing demonstrations; loading via Gmork; termination conventions (HALT or user input); 1-2 minute interactive scope
- **D4.5** — In-fiction surface discipline: pure framebuffer painting as user-facing mocks; "mock-as-narrative" — surface FEELS populated without underlying systems; explicit "coming soon in V2.0" framing
- **D4.6** — Release-artifact discipline: demo video + manifesto PDF + USB image + draft posts; V1.0 SHIP is the artifact set, not just the substrate
- **D4.7** — Public-repo-flip discipline: one-way action; pre-flip checklist; explicit architect authorization; tag + release artifacts ready before flip

Plus from Pod 3.12 V1.0 SEAL (4.0.B):
- **D3.43 (BROAD)** — V1.0-deferral framework: D3.43.1 anticipated-empirical-pressure + D3.43.2 asymmetric-surface + D3.43.3 audit-field + D3.43.x forensic-record retention
- **D3.44** — Catch-surface-migration tri-tier doctrine: Mechanical / Substrate-behavior / Inheritance

**Total post-Pod-4.0 doctrine corpus**: ~51 entries (D1.x + D2.x + D3.1-D3.44 + D4.1-D4.7). The "42 codified doctrines" architect-narrative is round-number; actual count higher. Public docs can frame as "40+ codified doctrines" or "44 doctrines through V1.0 SEAL + 7 polish/release doctrines."

---

## Open questions for architect ratification

1. **Doctrine numbering**: D3.X continuation or D4.X new family for Pod 4.0 work? (TB lean: D4.X)
2. **Binary size narrative**: keep "64KB" claim with measurement, or reframe to "auditable substrate" / different anchor? (TB lean: measure actual code bytes; if <100KB, keep claim; else reframe)
3. **OP_READ_KEY substrate addition**: ratify D4.1 + opcode addition for press-X demo, or skip with non-interactive substitute? (TB lean: ratify D4.1; substrate change is small + justified)
4. **Pod 3.12 SEAL absorption**: V1.0 SEAL commit happens at 4.0.B SEAL with v1.0 tag at that moment, OR Pod 3.12 SEAL is its own commit before Pod 4.0 starts? (TB lean: 4.0.B with v1.0 tag at that moment)
5. **About text voice**: TB drafted alternative voice; ratify TB voice or architect rewrites?
6. **3rd-party platform delegation**: TB drafts + exports; architect executes Lulu / Gumroad / YouTube / Public-repo-flip? (TB lean: yes split)
7. **6MB binary ceiling**: ratify the budget? (TB lean: yes; surface if approaching)
8. **Demo video music**: silent default, or architect provides track? (TB lean: silent unless architect provides)
9. **HN/Reddit/Twitter draft tone**: technical-with-soul (HN sharp audience) or more visionary? (TB lean: technical-with-soul; HN gets credibility-bound pitch)
10. **Subtitle styling for demo video**: gold-on-black; suggest font/size; ratify?
11. **Pod 4.0 numbering for future**: is Pod 4 the final pod-family (post-V1.0 SHIP, no Pod 5), or does V2.0 work continue as Pod 5+? (Affects how D4.X doctrine entries are scoped — V1.0-SHIP-only vs V2.0-extensible)

---

## TB voice draft for About demo (Call/Q5 reference)

```
CodebookOS is a 64KB-class bare-metal operating system with its own
programming language, written in pure x86_64 NASM. No borrowed code.
No safety nets.

Every primitive type — Sign, Cap, Outcome, Energy, Embedding — is
hand-crafted in assembly with SipHash MAC integrity. Every opcode has
a cost in joules and a published doctrine entry explaining why. The
compiler, lexer, parser, and stack-VM for the CBS language are all
custom.

This is not a demonstration. The Fibonacci sequence you saw computed
its 30th term using <ACTUAL_JOULES> joules of substrate-tracked energy.
Not simulation — metered execution against a metabolic ceiling.

Built by Randolph Pelican III over 30 hours of architectural work in
3 months. The substrate is auditable in a fortnight. The doctrines
codify every architectural decision; 44 of them through V1.0 SEAL,
51 through V1.0 SHIP.

Future work: the trinity — Cop (capability inspector), Maid (the
lexical-computation pole, complete in V1.0), Interpreter (text-to-
bytecode runtime). Surface ecology grows from Bastian's home screen.
Hormonal substrate (energy + spatial bookkeeping) tracks substrate
metabolism. The vision: a federated cognitive organism that knows
what it costs.

This is open source. Every doctrine, every surface, every byte of
substrate is at github.com/RandolphPelican/codebook. The operating
system humanity deserves is one we can audit, extend, and trust line
by line.

Help us build it.
```

Tone: architectural-truth over marketing-pitch. Specific numbers (44 doctrines through SEAL; 30 hours; 64KB-class) anchor credibility. "Not simulation — metered execution" is the credential moment. "Audit, extend, and trust line by line" is the closing CTA — "humanity deserves" stays from architect's draft.

Architect to ratify, rewrite, or veto. <ACTUAL_JOULES> placeholder fills in at 4.0.G implementation from canary measurement.

---

## Stub-surface picks (which 3 for visual mocks)

Architect directive named 3: Falkor (browser) + Atreyu (editor) + Rockbiter (scheduler). Other available: Empress, Koreander, Southern Oracle, Artax.

**TB recommendation**: keep architect's three (Falkor + Atreyu + Rockbiter). Rationale:

- **Falkor (browser)**: most iconic mockup; "auryn://randolphpelican.iii" URL is the strongest in-fiction touch; browser is the most OS-evocative mock for casual viewers
- **Atreyu (editor)**: CBS source visible in editor mock is the *credential* moment — viewers see "this OS has its own language with real source code"
- **Rockbiter (scheduler)**: process monitor mock universally readable as "real OS feature"; current-Gmork-program-energy-budget visible reinforces the energy-accounting credential

Alternatives considered:
- Empress (settings/realm-manager): less iconic; less credential-bearing
- Koreander (file manager / bookseller): plausible but generic
- Southern Oracle (oracle / search): interesting but harder to mock convincingly without underlying systems
- Artax (companion): no clear OS-feature mapping

The architect's 3 are right.

---

## Concrete artifacts plan (per deliverable category)

**Boot animation (4.0.C)**: `boot/anim.asm` (~600-1000 NASM lines) + larger glyph data (4x scale-up from existing 8x8 font; tricolor gradient renderer ~80 lines; star particle field ~30 lines; searchlight cone renderer ~120 lines; sequencing state machine ~200 lines). Animation as substrate-private (runs in MIND-phase init pre-bastian).

**Bastian polish (4.0.D)**: bastian.asm extension; 8x8 mythology icons for 12 surface slots (~96 bytes per icon × 12 = 1152 bytes glyph data; bordered cell rendering ~80 lines; banner/tagline string data + render calls).

**Demos (4.0.E)**: each demo = `surfaces/demo_<name>.cbs` + (sometimes) substrate addition (OP_READ_KEY only). Loaded via Gmork `load` command.
- E.1 fib_with_energy_trace.cbs — recursive Fib(N) with energy depletion visualization (renders joule bar)
- E.2 similarity_browser.cbs — Maid cosine ranking; type or pre-set word/embedding; displayed with similarity scores
- E.3 vector_composer.cbs — synthesis ops visualization (vectors as bars; add/sub/scale/normalize/lerp/project/reject demonstrated)
- E.4 cap_lifecycle.cbs — ROOT_CAP grant → use → revoke; federation ripple shown
- E.5 press_x_fire.cbs — keyboard input + energy expenditure (depends on OP_READ_KEY ratification)
- E.6 drift_anchor_exhibit.cbs — render the 0xB4000000 drift anchor with prose explanation (museum piece)

**In-fiction surfaces (4.0.F)**: `surfaces/mock_falkor.cbs` + `surfaces/mock_atreyu.cbs` + `surfaces/mock_rockbiter.cbs`. Each = pure framebuffer painting (using existing auryn primitives + CBS programs).

**About demo (4.0.G)**: `surfaces/about_codebookos.cbs` — scrolling text + visual flourishes (slow zoom on a doctrine; vector composition visualization; CBS source pretty-rendered).

**Docs (4.0.H)**: 5 .md files at repo root or `docs/`. Total ~2000-3000 lines.

**Demo video (4.0.I)**: 90-second QEMU screen recording; gold-on-black subtitles via post-processing (ffmpeg + subtitle overlay or similar tooling).

**Release artifacts (4.0.I/J)**: USB-bootable .img (already produced as build/codebook.img via existing build.sh — verify bootable); manifesto PDF (Pandoc from .md sources); HN/Reddit/Twitter drafts (.md files in `docs/` or `drafts/`).

---

## Standing-rule reminders (carry forward to Pod 4.0)

- **Foreground-only**: no background watchers; ~590s timeout per shell; split regression as needed
- **Three-oracle at every SEAL**: HEAD = origin/main = ls-remote
- **Two-build determinism at every SEAL**: re-confirm
- **Empirical regression at every SEAL**: 36+ prior canaries pass at current chunk's contract sha
- **D3.37 NASM RIP-relative discipline**: `lea base + idx*scale`, never `[rel sym + reg*scale]`
- **D3.41 raw-emitter literal-id discipline**: forge-order comment-tagging at `_raw` call sites
- **D3.43.x forensic-record retention** (per Pod 3.12 ratification): diagnostic probes retained as inert artifacts
- **Pod 3.12 V1.0 SEAL contract `c9923b8c…` (or whatever 4.0.B SEAL produces) load-bearing as regression reference**

---

Pod 4.0 = the resume-piece polish campaign. V1.0 SHIP ships the credential unambiguously. The substrate has earned the right to be seen.

Standing by for HALT 1 architect ratification on Calls 1-9 and Open Questions 1-11 — the eleven decisions that gate Pod 4.0 chunk execution. Once ratified, Pod 4.0.B (V1.0 SEAL closeout) begins.
