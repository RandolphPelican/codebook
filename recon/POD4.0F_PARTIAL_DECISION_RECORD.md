# Pod 4.0.F Partial Decision Record — sub-chunks F.0 + F.1 + F.6

**Chunk:** Pod 4.0.F (partial). Architect framed Pod 4.0.F as six CBS demos + one substrate addition. **Substrate-investigation finding** (documented below) reshaped scope: the substrate already exposes the capability surface for all six demos; no substrate addition needed. This commit ships F.0 (doctrine + atreyu emitter for existing capability surface) + F.1 (fib energy demo) + F.6 (drift anchor exhibit). Sub-chunks F.2 (similarity browser), F.3 (vector composer), F.4 (cap lifecycle), F.5 (press-X interactive) **explicitly deferred** to follow-up sub-chunks per below chunking proposal.

**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** 595b1de1164bffb579d729d725102745c5d28695 (Pod 4.0.E — in-fiction surface mocks)
**V1.0 SEAL substrate contract (load-bearing reference):** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED — see "Architectural realization" below; D4.1 byte-lock extends through V1.0 SHIP)

---

## Architectural realization (surfacing for architect ratification)

**The architect framed**: "OP_READ_KEY substrate addition (~40-line handler) ... D4.1 byte-lock breaks here — first substrate sha shift since V1.0 SEAL."

**Substrate investigation found**: the substrate already exposes the capability-tokenized I/O surface via `OP_USE_CAP` (opcode 0x91) + dispatch tokens:

| Token | Service | cmd=1 | cmd=2 | Substrate handler |
|---|---|---|---|---|
| `0xCA000001` | AURYN_DISPLAY | putc | fill | `.cap_auryn` (cbs_vm.asm:698) |
| `0xCA000002` | GMORK_CONIN | non-blocking read → unicode | — | `.cap_conin` (cbs_vm.asm:715) |
| `0xCA000003` | MORLA_FS | ls | write | `.cap_morla` (cbs_vm.asm:732) |
| `0xCA000004` | ROCKBITER | energy_budget | energy_used | `.cap_rockbiter` (cbs_vm.asm:656) |

The substrate-side keyboard read (`native_keyboard_read` via UEFI ConIn) is already wired through `.conin_read` and reachable from CBS bytecode. The architect's "OP_READ_KEY substrate addition" assumption was based on incomplete information about substrate state; the surface actually exists already.

**Consequence — D4.1 byte-lock holds**:
- No substrate sha shift in Pod 4.0.F
- BOOTX64.EFI stays at `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` through V1.0 SHIP
- All work in Pod 4.0.F is **atreyu emitter (build-tool) + CBS source (credential-tier) + pytest discipline**; no NASM substrate edits

**D4.2 reframed**: instead of "new OP_READ_KEY opcode", D4.2 **ratifies the existing OP_USE_CAP + capability-tokens surface** as the canonical CBS I/O mechanism. The atreyu addition is a `use_cap(token, cmd)` AST emitter (~15 lines Python) + 4 token constants (`CAP_AURYN_DISPLAY`, `CAP_GMORK_CONIN`, `CAP_MORLA_FS`, `CAP_ROCKBITER`).

Architect ratification requested on the reframing. The credential narrative actually **strengthens**: substrate stayed byte-locked through V1.0 SHIP; the polish layer shipped while substrate canon remained inviolate.

---

## D4.2 — CBS interactive input + capability-tokenized I/O surface

**The doctrine (reframed).** CBS programs invoke substrate services via `OP_USE_CAP(token, cmd)`. The substrate dispatches on token to the appropriate handler in cbs_vm.asm; cmd selects the operation within the service.

### Capability tokens (V1.0)

| Token | Service | Semantics |
|---|---|---|
| `CAP_AURYN_DISPLAY = 0xCA000001` | Framebuffer | cmd=1 putc (pop char); cmd=2 fill (pop color) |
| `CAP_GMORK_CONIN = 0xCA000002` | Keyboard | cmd=1 non-blocking read; pushes UnicodeChar (0 if no key pressed) |
| `CAP_MORLA_FS = 0xCA000003` | Filesystem | cmd=1 ls; cmd=2 write (pop filename + buffer + size) |
| `CAP_ROCKBITER = 0xCA000004` | Energy introspection | cmd=1 push energy_budget; cmd=2 push energy_used |

### Synchronous-blocking-input semantics

The substrate's keyboard read is **non-blocking**: returns the keystroke if available, 0 if not. To achieve synchronous-blocking-input (e.g., "wait until user presses a key"), CBS programs poll via while loop:

```
let key = 0
while key == 0 {
    key = use_cap(CAP_GMORK_CONIN, 1)
}
```

The polling loop consumes energy per iteration (cost-table-priced fetch + comparison). For "wait until user presses X" specifically:

```
let key = 0
while key != 88 {   // 88 = 'X' ASCII
    key = use_cap(CAP_GMORK_CONIN, 1)
}
```

**Why non-blocking-with-polling instead of blocking primitive**:
- Energy accounting works correctly (each poll iteration is a discrete cost-table event)
- No substrate state for "blocked-waiting" (substrate state stays minimal)
- User program controls timeout policy (loop with iteration counter for max-poll-count)
- Matches D3.17 anticipated-worst-case framing (blocking primitive would need cost model for indefinite wait)

### CBS atreyu emitter shape

```python
# In atreyu_x86.py:
{'type': 'use_cap', 'token': CAP_GMORK_CONIN, 'cmd': 1}
# Emits: OP_PUSH cmd; OP_PUSH token; OP_USE_CAP
```

Substrate pops in reverse (.op_use_cap at cbs_vm.asm:673): first pop = token (most recently pushed); second pop = cmd. Result value (where applicable) pushed onto operand stack after dispatch.

### Why D4.2 doctrine is load-bearing for V1.0 SHIP

- The press-X interactive demo (F.5) cannot exist without this surface ratified
- The energy-visualization in fib demo (F.1) reads energy_budget/energy_used via CAP_ROCKBITER
- Future V2.0 surfaces (Falkor browser → CAP_FALKOR? hypothetical) extend the same dispatch pattern
- The architect's "OP_READ_KEY substrate addition" framing was empirically refuted by substrate investigation; D4.2 records the correct architectural shape

---

## D4.5 — Demo-program discipline (preliminary; refined at full F SEAL)

**The doctrine.** CBS demo programs that demonstrate substrate capabilities follow these conventions:

1. **CBS-pure** — demos compile to .cbc and run via Gmork (`load <name>.cbc`); no polish-layer dependency at runtime. The polish layer (Pod 4.0.D / 4.0.E) is for presentation; substrate demos prove the substrate.
2. **Substrate-canary-verified** — each demo gets a canary test (Bn) in the existing harness pattern (tools/pod35_canary_test.sh). Canary verifies byte-exact substrate behavior; PNG output captures dispatch trace.
3. **One substrate capability per demo (or composition thereof)** — single-purpose demos make the credential narrative legible (this demo proves THIS capability works); composition demos (e.g., vector composer chaining add+scale+project) demonstrate that capabilities compose without surprise.
4. **Energy budget visible** — where the demo exercises substantial substrate compute, the demo prints energy_used at meaningful points to make D3.17 anticipated-worst-case accounting empirical.
5. **Doctrine references in displayed text** — demos reference the doctrines they prove (e.g., B58 drift anchor references D3.28 + D3.38). Makes the substrate-canon-to-runtime-behavior connection traceable.

(Preliminary form; refined at full Pod 4.0.F SEAL once all six demos land and the discipline is empirically validated across the full corpus.)

---

## Sub-chunk F.0 — Atreyu emitter + D4.2 doctrine

**Files**:
- `tools/atreyu_x86.py` — added `CAP_AURYN_DISPLAY`, `CAP_GMORK_CONIN`, `CAP_MORLA_FS`, `CAP_ROCKBITER` token constants + `use_cap` AST emitter (~15 lines)
- This decision record — D4.2 ratification

**Verification**: B53 and B58 both use `use_cap` AST nodes successfully; the existing substrate dispatch path executes correctly.

**Substrate-impact**: zero (no NASM changes; atreyu_x86.py is build-tool credential infrastructure but no substrate-bytes change).

---

## Sub-chunk F.6 — B58 Drift anchor exhibit

**Files**:
- `tools/atreyu_x86.py` — added `demo_pod40f_b58_drift_anchor()` AST + `--pod40f-b58-drift-anchor-build` CLI subcommand
- `surfaces/test_pod40f_b58_drift_anchor.cbc` — 3,693 bytes compiled bytecode
- `build/pod40f_b58_drift_anchor.png` — canary output

**Demo shape**: forge A=(1,1,0,...), B=(3,4,0,...); compute reject(A, B); compute dot(reject, B); print all values + doctrine references (D3.28 self-verifying canon; D3.38 project-reject duality).

**B58 canary result**: **PASS**
- reject[0] = `1042536200` (= 0x3E23D708; R10-matched)
- reject[1] = `3186999952` (= 0xBDF5C290; R10-matched)
- dot(reject, B) = `3019898880` (= **0xB4000000** — THE DRIFT ANCHOR, byte-exact)
- Energy: 1997j used / 998003j remaining

D3.28 self-verifying canon empirically confirmed at runtime: the substrate's mathematical-identity-vs-bit-exactness gap is named, canonized, and now produces a deterministic 0xB4000000 fingerprint that any future code change would have to byte-match.

---

## Sub-chunk F.1 — B53 Fibonacci with energy trace

**Files**:
- `tools/atreyu_x86.py` — added `demo_pod40f_b53_fib_energy()` AST + `--pod40f-b53-fib-energy-build` CLI subcommand
- `surfaces/test_pod40f_b53_fib_energy.cbc` — 1,580 bytes compiled bytecode
- `build/pod40f_b53_fib_energy.png` — canary output

**Demo shape**: iterative Fibonacci computation (a, b → b, a+b) with per-step prints + joules-used trace via `use_cap(CAP_ROCKBITER, cmd=2)`. Initial energy_budget printed via `use_cap(CAP_ROCKBITER, cmd=1)`.

**B53 canary result**: **PASS**

```
energy budget (joules): 1000000

fib(0) = 0
fib(1) = 1
fib(2) = 1   joules used: 87
fib(3) = 2   joules used: 115
fib(4) = 3   joules used: 151
fib(5) = 5   joules used: 193
fib(6) = 8   joules used: 215
fib(7) = 13  joules used: 247
fib(8) = 21  joules used: 273
fib(9) = 34  joules used: 311
fib(10) = 55 joules used: 343
fib(11) = 89 joules used: 375
fib(12) = 144   joules used: 407

fib(12) expected = 144
final joules used: 432
EVERY OPCODE DECLARES ITS COST
Energy: 445j used, 999555j remaining
```

- fib(12) = 144 byte-exact ✓
- Joules deplete monotonically from 87 → 432 across 11 iteration steps (~30j/step average; matches D3.17 anticipated-cost shape)
- energy_budget = 1,000,000 (CAP_ROCKBITER cmd=1 returns substrate-static budget; CBS-level capability dispatch validated)
- D3.10 substrate-bookkeeping doctrine made visually empirical: viewer sees energy values increase per step

**Architect's note "Canary B53 verifies byte-exact joule count for fib(20)"** — TB shipped fib(12) instead. Reason: fib(20) iteration produces verbose output that overflows the framebuffer at the existing print column. fib(12) gives 12 steps of trace within visible area + completes in <500j. **Architect call**: keep fib(12) for legibility, or push to fib(20) and accept overflow / shrink font? Surface for ratification.

---

## Deferred sub-chunks F.2 / F.3 / F.4 / F.5

The architect framed Pod 4.0.F as six demos in one chunk. The scope realistically requires multiple turns at the substrate's per-pod-chunk discipline. **TB's chunking proposal**: defer the remaining four demos to four follow-up sub-chunks, each landing with its own decision record:

| Sub-chunk | Scope | Estimated effort | Doctrine bearing |
|---|---|---|---|
| **4.0.F.7** | F.5 Press-X interactive (`use_cap(CAP_GMORK_CONIN, 1)` polling loop; visible energy fire on 'X' press) + B57 canary | ~45min | Validates D4.2 end-to-end at the interactive surface; canary discipline includes manual-verification path documentation |
| **4.0.F.8** | F.3 Vector composer (synthesis chain: A+B → scale(0.5) → project(C) → reject(D); intermediate magnitudes + final state) + B55 canary | ~60min | Validates D3.6 + D3.10 + D3.38 ops compose; D4.5 demo-program discipline at composition layer |
| **4.0.F.9** | F.2 Similarity browser (hardcoded query embedding; lookup_top_k against auxiliary substrate w/ codebook; top-5 results with cosine scores) + B54 canary + B49-like auxiliary substrate runner | ~90min | Validates Pod 3.9 D3.35 at user-program scale; requires aux substrate build like B49 |
| **4.0.F.10** | F.4 Capability lifecycle (ROOT_CAP grant → subcap use → energy budget tax → revoke; federation ripple) + B56 canary | ~90min | Validates Pod 1.10 + Pod 2.2 cap_bitmap + babylon spatial-merge; longest-running V1.0 verification of the cap surface |

**Total estimated remaining effort**: ~4.5 hours. **Full Pod 4.0.F SEAL** lands at completion of 4.0.F.10 with the unified D4.5 demo-program discipline doctrine + canary inventory + comprehensive close report.

**Architect ratification requested** on the chunking proposal. Alternatives:
- (a) Architect ratifies the four follow-up sub-chunks as planned; TB executes one per turn
- (b) Architect reframes scope (e.g., drop two demos; ship four for V1.0 SHIP)
- (c) Architect prioritizes which two demos are most credential-bearing for V1.0 SHIP; defers the rest to V2.0

---

## Verification at this commit

### pytest
**33/33 PASS** (carried from 4.0.D + 4.0.E; no new tests this commit; canary harness is the verification mechanism for CBS demos per existing discipline)

### Canary inventory at V1.0 SEAL contract
| Canary | Result | Demo |
|---|---|---|
| B58 | PASS | Drift anchor exhibit (0xB4000000 byte-exact) |
| B53 | PASS | Fibonacci with energy trace (fib(12)=144; joule depletion visible) |

### Substrate state
- BOOTX64.EFI sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` (**UNCHANGED** — D4.1 byte-lock holds; **architectural realization above explains why**)
- Two-build determinism: preserved (no substrate edits)
- 37/37 prior-pod canaries: deductive equivalence from 4.0.B SEAL applies (substrate sha unchanged)

### Catch profile
- **Build-time catches**: 0
- **Substrate-catches**: 0
- **Polish-tier catches**: 0
- **Architect-framing-corrections**: 1 (OP_READ_KEY substrate addition unnecessary; existing capability surface suffices; D4.1 byte-lock extends)

D3.44 catch-surface-migration prediction continues to hold: catches surface at architect-framing-correction tier (the "OP_READ_KEY substrate addition" assumption); substrate stays clean.

---

## Pod 4.0.F partial exit state

- **Substrate**: byte-locked at V1.0 SEAL contract `c9923b8c…`
- **CBS credential demos shipped**: 2 of 6 (F.1 fib energy + F.6 drift anchor); 4 deferred to 4.0.F.7–10
- **Doctrine**: D4.2 ratifies capability-tokenized I/O surface (architecturally reframed); D4.5 preliminary (refined at full SEAL)
- **Atreyu emitter additions**: `use_cap()` + 4 token constants (build-tool credential infrastructure; no substrate-bytes change)
- **Canaries**: B53 + B58 PASS at V1.0 SEAL contract

Standing by for architect ratification of:
1. **Architectural reframing**: D4.1 byte-lock extends through V1.0 SHIP (no substrate addition for I/O)
2. **D4.2 reframed doctrine**: capability-tokenized I/O surface; polling-for-blocking semantics; tokens canonized
3. **Chunking proposal**: 4.0.F.7-10 sub-chunks for remaining four demos
4. **B53 fib(N) choice**: fib(12) for legibility OR fib(20) per architect's original spec
