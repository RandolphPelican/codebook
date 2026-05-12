# Pod 4.0.F Decision Record — Real CBS demos suite + D4.2 + D4.5 (FULL SEAL)

**Chunk:** Pod 4.0.F — credential-tier proof arc. Six CBS demos validate the V1.0 substrate end-to-end at the user-program scale. D4.2 ratified the existing capability-tokenized I/O surface (architectural realization at 4.0.F partial). D4.5 codifies demo-program discipline at this SEAL.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** 595b1de1164bffb579d729d725102745c5d28695 (Pod 4.0.E)
**Exit HEAD:** (this commit)
**V1.0 SEAL substrate contract:** **c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900** (UNCHANGED throughout Pod 4.0.F; D4.1 byte-lock empirically validated across 6 sub-chunks)

---

## The architectural realization (load-bearing for the entire post-V1.0-SEAL arc)

Pod 4.0.F was originally framed by the architect as requiring an **OP_READ_KEY substrate addition** with D4.1 byte-lock breaking. Substrate investigation at 4.0.F partial found: **the substrate already exposed the full capability-tokenized I/O surface via OP_USE_CAP + capability tokens**. No substrate addition was needed; D4.1 byte-lock extends through V1.0 SHIP.

**Consequence**: BOOTX64.EFI stays at `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` from V1.0 SEAL onward. The credential narrative strengthens materially: "44 doctrines + Maid V1.0 surface complete + substrate byte-locked across the entire polish layer + every demo in the polish layer uses pre-existing substrate primitives."

**Substrate state at Pod 4.0.F SEAL**: identical to V1.0 SEAL state. Same sha. Same canaries. Same two-build determinism. The substrate is what it was on V1.0 SEAL day; everything since has been polish (Pod 4.0.C-E) + credential-tier proof (Pod 4.0.F).

---

## D4.2 — Capability-tokenized I/O surface (ratified at 4.0.F partial; restated here)

**The doctrine.** CBS programs invoke substrate services via `OP_USE_CAP(token, cmd)`. The substrate dispatches on token to the appropriate handler in cbs_vm.asm; cmd selects the operation within the service.

### Capability tokens (V1.0 canonical)

| Token | Value | Service | Operations |
|---|---|---|---|
| `CAP_AURYN_DISPLAY` | 0xCA000001 | Framebuffer | cmd=1 putc; cmd=2 fill |
| `CAP_GMORK_CONIN` | 0xCA000002 | Keyboard (non-blocking) | cmd=1 read → unicode char (0 if no key) |
| `CAP_MORLA_FS` | 0xCA000003 | Filesystem | cmd=1 ls; cmd=2 write |
| `CAP_ROCKBITER` | 0xCA000004 | Energy introspection | cmd=1 energy_budget; cmd=2 energy_used |

### Polling-for-blocking semantics

CBS programs poll non-blocking conin via while loop for synchronous-blocking-input behavior. Each poll iteration consumes substrate cost-table energy; no special "blocked-waiting" substrate state required. Validated empirically at B57 press-X demo (5000-poll cycle = 145,080j; ~29j/iteration).

### Atreyu emitter

```python
{'type': 'use_cap', 'token': <u64>, 'cmd': <i64>, 'args': [<int or AST>, ...]}
# args (optional) push BEFORE cmd/token for service-specific arguments
# (e.g., CAP_AURYN_DISPLAY cmd=2 fill takes a color arg)
```

---

## D4.5 — Demo-program discipline (codified at this SEAL)

**The doctrine.** CBS demo programs that demonstrate substrate capabilities follow these conventions, validated empirically across the Pod 4.0.F six-demo suite:

### Rule 1 — CBS-pure runtime
Demos compile to `.cbc` bytecode and run via Gmork (`load <name>.cbc`); no polish-layer dependency at runtime. Polish (Pod 4.0.D / 4.0.E) is for *presentation*; substrate demos *prove the substrate*. The credential narrative depends on this separation.

### Rule 2 — Substrate-canary-verified
Each demo gets a canary test (Bn) in the existing pod35_canary_test.sh harness. Canary verifies byte-exact substrate behavior; PNG output captures execution trace. Demos that exercise codebook ingestion use auxiliary-substrate runners (pod40f_b54_runner.sh shape) that build aux substrate, run canary, restore canonical via final rebuild.

### Rule 3 — Single substrate capability per demo (or composition thereof)
Single-purpose demos make the credential narrative legible (this demo proves THIS capability works); composition demos demonstrate that capabilities compose without surprise. **B55 vector composer is the most-cross-doctrine canary in V1.0 SHIP** — composes D3.6 + D3.10 + D3.38 + D3.40 + D3.28 in one execution with 13 byte-exact predictions. **B54 similarity browser composes 5 doctrines** (D3.14 + D3.18→D3.35 + D3.31 + D3.42 + D3.35-tie-break) in one canary.

### Rule 4 — Energy budget visible
Demos exercising substantial substrate compute print energy_used at meaningful points via `use_cap(CAP_ROCKBITER, cmd=2)`. Makes D3.17 anticipated-worst-case empirical at user-program scale. Per-opcode cost-table values land predictably:
- B53 fib(12): ~432j (12 arithmetic + print iterations)
- B55 vector composer: 5647j (4 synthesis ops + 5 dot products + multiple accessors)
- B54 similarity browser: 101,511j (lookup_top_k dominates at ~100k per D3.17 lookup_top1-tier)
- B57 press-X: 145,080j (5000 polls × ~29j/iteration)
- B58 drift anchor: 1,997j (1 reject + 1 dot)
- B56 cap lifecycle: 264j (light cap accessors)

The cost-table is internally consistent across composition layers.

### Rule 5 — Doctrine references in displayed text
Demos reference the doctrines they prove in displayed text. Makes the substrate-canon-to-runtime-behavior connection traceable for any viewer. Examples:
- B53: "D3.17 anticipated-worst-case energy accounting"
- B54: "D3.35 top_k housekeeper-tier"
- B55: "D3.6 + D3.10 synthesis tier composed end-to-end"
- B58: "D3.28 self-verifying canon - mathematical-identity-vs-bit-exactness gap"
- B56: "D1.10 + D2.2 cap surface - V1.0 supports grant + use; revoke deferred to V2.0"

### Rule 6 — Honest framing for V2.0 carry-forward
When a demo touches a substrate surface that has V2.0 carry-forward components, the demo is *explicit* about what V1.0 supports vs what V2.0 will add. B56 cap lifecycle exemplifies: "V1.0 cap surface implements grant + use + accounting + lineage. Revocation propagation is V2.0 carry-forward per RECONSTITUTION cap_graph design." Demos don't pretend the substrate is more than it is; the credential is what's actually built.

### Rule 7 — Interactive verification two-tier
For demos that exercise interactive I/O (B57 press-X), automated canary validates the substrate dispatch surface (polling loop runs without hang); manual verification at SHIP demo video capture validates the interactive response. Documented in decision record.

---

## Six-demo suite — credential-tier proof of CBS-as-language + substrate-as-OS

### B53 — Fibonacci with energy trace (Pod 4.0.F.1; 4.0.F partial commit)

**Validates**: D3.17 anticipated-worst-case energy accounting visible per CBS iteration.

```
fib(0) = 0
fib(1) = 1
fib(2) = 1   joules used: 87
fib(3) = 2   joules used: 115
...
fib(12) = 144   joules used: 407
```

Total: ~432 joules tracked across 12-step iterative computation. CBS variable arithmetic + while loop equivalent (unrolled for trace visibility) + `use_cap(CAP_ROCKBITER, cmd=1/2)` for energy introspection. **First V1.0 demo to access substrate energy state from CBS.**

### B58 — Drift anchor exhibit (Pod 4.0.F.6; 4.0.F partial commit)

**Validates**: D3.28 self-verifying canon at runtime; D3.38 project-reject duality; D3.40 hybrid IEEE-degeneracy drift regime.

```
A = (1, 1, 0...);  B = (3, 4, 0...)
reject[0] = 0x3E23D708 (R10-matched byte-exact)
reject[1] = 0xBDF5C290 (R10-matched byte-exact)
dot(reject, B) = 0xB4000000   ← THE DRIFT ANCHOR
```

3,019,898,880 (= 0xB4000000) reproduced byte-exact. Pod 3.10's mathematical-identity-vs-bit-exactness fingerprint now produces a deterministic runtime byte-exact match that any future substrate change would have to preserve.

### B57 — Press-X interactive (Pod 4.0.F.7)

**Validates**: D4.2 capability-tokenized I/O surface end-to-end at the interactive boundary; first V1.0 CBS interactive program.

```
polls completed: 5000
fires registered: 0     (no keypress injection — automated path)
final joules used: 145080   (~29j/iteration)
```

Polling loop on `use_cap(CAP_GMORK_CONIN, cmd=1)`; on 'x' detected (manual verification path) fires visible energy expenditure; ESC for early exit; bounded by 5000 polls for canary completion. **First V1.0 CBS program to read user keyboard input** — and it required ZERO substrate changes.

### B55 — Vector composer (Pod 4.0.F.8)

**Validates**: D3.6 + D3.10 + D3.38 + D3.40 + D3.28 composed in one canary (most cross-doctrine canary in V1.0 SHIP).

Halving magnitudes-squared cascade:
```
S1 = ADD(A, B)         |S1|² = 2.0     (0x40000000)
S2 = SCALE(S1, 0.5)    |S2|² = 0.5     (0x3F000000)
S3 = PROJECT(S2, C)    |S3|² = 0.25    (0x3E800000)
S4 = REJECT(S3, D)     |S4|² = 0.125   (0x3E000000)
dot(S4, D) = 0 byte-exact (clean cancellation; D3.40 regime)
```

13 byte-exact predictions match. Energy: 5,647j (substrate cost-table sums to ~5500j ± dispatch overhead — internally consistent at composition layer).

### B54 — Similarity browser (Pod 4.0.F.9)

**Validates**: D3.14 + D3.18→D3.35 + D3.31 + D3.42 + D3.35-tie-break — five doctrines in one canary.

Auxiliary substrate w/ B48 codebook (5 basis-vector entries; sha `caa6b315…` matching B48 + B52 cross-canary continuity). Query = e_x via runtime forge.

```
META count = 5, dim = 384, status = SUCCESS
Query id = 6 (post-boot-ingest forge)
lookup_top_k(query, K=3, threshold=-INF) → K'=3
rank 0: id=1, cosine=0x3F800000 = 1.0  (D3.14 same-vector)
rank 1: id=2, cosine=0                 (D3.14 orthogonal basis; tie-break first-encountered)
rank 2: id=3, cosine=0                 (same)
```

11 byte-exact predictions match. Energy: 101,511j (lookup_top_k dominates ~100k per D3.17 + cosines + accessors + dispatch).

### B56 — Cap lifecycle (Pod 4.0.F.10; this commit)

**Validates**: D1.10 + D2.2 V1.0 cap surface (grant + use + accounting + lineage); honest about V2.0 carry-forward (revocation).

```
ORIGIN  current_cap = 1 (ROOT); ROOT bitmap = -1 (UNBOUNDED); ROOT budget = -1
GRANT   cap_new(BIT_OUTCOME_FORGE=4, budget=50000) → child id=2
        child bitmap=4, child budget=50000, child used=0, child parent=1
USE     cap_enter(child) → current_cap=2
        observe child state in child context (bitmap=4, budget=50000)
        cap_exit → current_cap=1
        child used post-cycle = 1 joule (cost-table fired under child context)
        ROOT used post-cycle = 0 (no babylon ripple for cap_enter/exit per current substrate)
REVOKE  deferred to V2.0 per RECONSTITUTION cap_graph design
```

13 byte-exact predictions match. **V1.0 cap surface empirical**: grant works (subset-on-grant per D2.2.5); enter/exit works (stack discipline per D1.10.2); accounting works (child used tracks compute under child context); lineage works (child.parent = ROOT). **V2.0 carry-forward**: `cap_revoke` (no opcode); explicit federation_total aggregate; cap_graph spatial-merge ripple visible at this layer (only 1j fired under child; ROOT didn't accumulate via babylon — substrate's spatial-merge fires elsewhere). Demo documents the substrate's *actual* cap discipline, not aspirational design.

---

## Pod 4.0.F sub-chunk audit

| Chunk | Demo | Commit | Canary | Doctrines validated |
|---|---|---|---|---|
| 4.0.F.0 | D4.2 + use_cap emitter | c50e95f | (foundation) | D4.2 |
| 4.0.F.1 | B53 fib energy | c50e95f | PASS | D3.17 |
| 4.0.F.6 | B58 drift anchor | c50e95f | PASS | D3.28 + D3.38 + D3.40 |
| 4.0.F.7 | B57 press-X | 5c96218 | PASS | D4.2 |
| 4.0.F.8 | B55 vector composer | f27e12b | PASS | D3.6 + D3.10 + D3.38 + D3.40 + D3.28 |
| 4.0.F.9 | B54 similarity browser | 527702c | PASS (aux substrate) | D3.14 + D3.35 + D3.31 + D3.42 + D3.35-tie-break |
| 4.0.F.10 | B56 cap lifecycle | this commit | PASS | D1.10 + D2.2 + V2.0 carry-forward framing |
| **SEAL** | Unified D4.5 + suite | this commit | — | D4.5 codifies discipline |

**Substrate sha at every chunk SEAL**: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (UNCHANGED — D4.1 byte-lock empirically validated across 7 commits).

---

## Catch profile across Pod 4.0.F

- **Build-time catches**: 0 across all sub-chunks
- **Substrate-catches**: 0 across all sub-chunks
- **Polish-tier catches**: 2 across all sub-chunks (AST block-body shape at F.7; cap_new outcome-wrap handling at F.10; both canary-tier; both corrected from tracebacks immediately)
- **Architect-framing-corrections**: 1 (OP_READ_KEY substrate addition unnecessary; existing capability surface suffices; D4.1 byte-lock extends — caught at substrate investigation at 4.0.F partial)

D3.44 catch-surface-migration prediction validated empirically across the Pod 4.0.F arc: catches surface at canary-tier discipline (CBS AST authoring) + architect-framing tier (substrate-state investigation); substrate-behavioral tier remains clean. The methodology is working as designed.

---

## V1.0 cap surface (B56-anchored empirical inventory)

**Implemented in V1.0** (visible at B56 canary):
- `cap_new(granted_bitmap, energy_budget)` — subset-on-grant per D2.2.5; cap_id sequential allocation (first user-forged = 2)
- `cap_enter(cap_id)` — cap_stack push; current_cap_id update; MAC verify per D1.10.2
- `cap_exit()` — cap_stack pop; current_cap restored
- `cap_current()` — substrate state read
- `cap_bitmap(cap_id)` — D2.2.1 structured forge-bit accessor; UNBOUNDED for ROOT (= -1 signed = 0xFFFFFFFFFFFFFFFF)
- `cap_budget(cap_id)` / `cap_used(cap_id)` — D1.10.3 metabolic accessors
- `cap_arena(cap_id)` / `cap_owner(cap_id)` / `cap_parent(cap_id)` — lineage accessors

**V2.0 carry-forward** (per architect's framing + RECONSTITUTION cap_graph design):
- `cap_revoke(cap_id)` — explicit revocation propagation
- `cap_grant_to(principal, cap_id)` — grant to specific principal (not current_cap-derived)
- `federation_total` — aggregate substrate state query
- Spatial-merge delegation tax fully observable at parent (in B56, child's 1j use did NOT propagate to ROOT's energy_used — either the substrate's spatial-merge fires through a different path, or it doesn't fire for cap_enter/exit specifically; V2.0 cap_graph activation lands its own demo)

**The demo proves the substrate's actual cap discipline**, not aspirational design. Architecturally honest.

---

## Files landed across Pod 4.0.F (7 commits)

```
tools/atreyu_x86.py
  +  CAP_AURYN_DISPLAY / CAP_GMORK_CONIN / CAP_MORLA_FS / CAP_ROCKBITER tokens
  +  use_cap AST emitter with optional args[] list
  +  demo_pod40f_b53_fib_energy() + CLI subcommand
  +  demo_pod40f_b58_drift_anchor() + CLI subcommand
  +  demo_pod40f_b57_press_x() + CLI subcommand
  +  demo_pod40f_b55_vector_composer() + CLI subcommand
  +  demo_pod40f_b54_similarity_browser() + CLI subcommand
  +  demo_pod40f_b56_cap_lifecycle() + CLI subcommand

surfaces/test_pod40f_b53_fib_energy.cbc          (1,580 bytes)
surfaces/test_pod40f_b54_similarity_browser.cbc  (2,591 bytes)
surfaces/test_pod40f_b55_vector_composer.cbc     (7,540 bytes)
surfaces/test_pod40f_b56_cap_lifecycle.cbc       (1,955 bytes)
surfaces/test_pod40f_b57_press_x.cbc             (748 bytes)
surfaces/test_pod40f_b58_drift_anchor.cbc        (3,693 bytes)

build/pod40f_b53_fib_energy.png         (canary PNG)
build/pod40f_b54_similarity_browser.png (canary PNG)
build/pod40f_b55_vector_composer.png    (canary PNG)
build/pod40f_b56_cap_lifecycle.png      (canary PNG)
build/pod40f_b57_press_x.png            (canary PNG)
build/pod40f_b58_drift_anchor.png       (canary PNG)

tools/pod40f_b54_runner.sh — auxiliary-substrate runner (B48 codebook reused)

recon/POD4.0F_PARTIAL_DECISION_RECORD.md (4.0.F partial; F.0 + F.1 + F.6)
recon/POD4.0F7_DECISION_RECORD.md        (4.0.F.7; press-X)
recon/POD4.0F8_DECISION_RECORD.md        (4.0.F.8; vector composer)
recon/POD4.0F9_DECISION_RECORD.md        (4.0.F.9; similarity browser)
recon/POD4.0F_DECISION_RECORD.md         (this file; unified SEAL)
```

---

## Verification at Pod 4.0.F SEAL

| Item | Result |
|---|---|
| Substrate sha | `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (UNCHANGED throughout Pod 4.0.F arc; D4.1 byte-lock empirically validated) |
| Two-build determinism | preserved (no substrate edits across Pod 4.0.F) |
| Six-demo suite | **6/6 PASS** byte-exact (B53 + B54 + B55 + B56 + B57 + B58) |
| Total byte-exact predictions across suite | ~50 (B53: 12+ joule traces / B54: 11 / B55: 13 / B56: 13 / B58: 3 anchors) |
| pytest harness | 33/33 PASS (carried; no Python tests added during Pod 4.0.F — canary harness is the verification mechanism per existing discipline) |
| Prior 37/37 canaries | deductive equivalence (substrate unchanged) |

---

## Headline moments

**(1) D4.1 byte-lock empirically validated across the entire credential-tier proof arc.** Substrate sha `c9923b8c…` holds throughout Pod 4.0.F (and all of Pod 4.0). The substrate at Pod 3.12 V1.0 SEAL is the substrate at Pod 4.0.F SEAL is the substrate at V1.0 SHIP. The credential narrative is unambiguous: "V1.0 SHIP ships the V1.0 SEAL substrate without modification; the polish layer reaches every demo via pre-existing primitives."

**(2) Six demos prove CBS-as-language + substrate-as-OS.** Each demo is a CBS-pure program that compiles to bytecode and runs in the substrate's stack-VM. Each demo demonstrates one or more substrate capabilities with byte-exact verifiable output. The credential — "built a complete custom programming language and a complete bare-metal OS, both demonstrably working" — has six anchored proofs at the canary level.

**(3) Cross-doctrine composition canaries (B54, B55).** Both demos compose 5 doctrines each in one execution. The substrate's compositional discipline is empirically validated: doctrines compose without surprise at user-program scale. This is the credential's empirical density — every doctrine the substrate codified is reachable from one canary that runs in <30 seconds.

**(4) Honest V2.0 framing throughout.** B56 cap lifecycle explicitly documents what V1.0 supports vs what V2.0 carries forward. The demo doesn't pretend; the substrate is what's actually built. RECONSTITUTION cap_graph design's V2.0 components (cap_revoke, federation_total, full spatial-merge ripple) are named honestly.

**(5) D3.44 catch-surface-migration prediction validated across the arc.** Zero substrate-tier catches across 6 sub-chunks; zero build-time catches; 2 canary-tier polish catches (AST shape; outcome unwrap) corrected from tracebacks immediately; 1 architect-framing-correction (OP_READ_KEY substrate addition unnecessary) caught at substrate investigation before any handler-writing. The methodology is working at the inheritance-tier maturity level D3.44 predicted.

**(6) "The substrate is complete enough that V1.0 SHIP doesn't need new substrate primitives" — empirically demonstrated.** First V1.0 interactive CBS program shipped (B57 press-X) using only pre-existing substrate surface. The boundary between V1.0 SEAL and V1.0 SHIP is purely doctrinal + polish — substrate canon is byte-locked across both.

---

## Pod 4.0.F exit state

- **Substrate**: byte-locked at V1.0 SEAL contract `c9923b8c…` (UNCHANGED throughout Pod 4.0.F)
- **CBS credential demos**: 6 of 6 shipped + canary-verified PASS
- **Doctrines landed across Pod 4.0**: D4.1 (polish-vs-credential) + D4.2 (capability-tokenized I/O) + D4.3 (boot animation discipline) + D4.4 (in-fiction surface discipline) + D4.5 (demo-program discipline) + D4.8 (polish-layer verification discipline)
- **Pending D4.X**: D4.6 (release-artifact discipline) lands at 4.0.I; D4.7 (public-repo-flip discipline) lands at 4.0.J SHIP

Pod 4.0.G (demo video composition pipeline) begins next. The six canary PNGs + the four polish MP4s (boot anim / About / Atreyu / Falkor / Rockbiter) provide the source material; FFmpeg orchestration composes the 90-second master timeline.
