# Pod 1.5.6 — Recon Report

**Date:** 2026-04-28
**Pod:** 1.5.6 (canon-only, no source changes)
**Author:** Terminal Boy (Claude)
**Entry contract:** `32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6` (preserved — no source changes)
**Predecessor:** Pod 1.5.5 (pre-Pod-1.6 architect orientation recon, sealed at b560a6c)

---

## Section 1 — Sweep Findings

### Sweep A — File Inventory

**RECONSTITUTION.md:** 406 lines, sha256 `48fc60a8f263ba7fd320c4ffb7ee99a542491507bea6ec45953b7d76d8f5839c`

**recon/ directory listing (10 files, MEMO_VERIFICATION_PROVENANCE.md confirmed absent):**

| File | Present |
|------|---------|
| POD0.2.5_RECON_REPORT.md | Yes |
| POD0.9_CAP_GRAPH_DEEP_READ.md | Yes |
| POD1.0_BACKFILL_RECON_REPORT.md | Yes |
| POD1.1_VM_AUDIT.md | Yes |
| POD1.2_DECISION_RECORD.md | Yes |
| POD1.3_OP_RET_RECON.md | Yes |
| POD1.4_DECISION_RECORD.md | Yes |
| POD1.5.5_PRE_POD16_RECON.md | Yes |
| POD1.5_RECON_REPORT.md | Yes |
| POD1.5_VERIFICATION.md | Yes |
| MEMO_VERIFICATION_PROVENANCE.md | **No** |

### Sweep B — Symbol Inventory

N/A — no .asm files in scope for this pod.

### Sweep C — Cross-Module Dependencies

N/A — no .asm files in scope for this pod.

### Sweep D — Unexpected Directories

Top-level directories as of b560a6c:

```
boot/
build/
drivers/
kernel/
prompts/
recon/
surfaces/
tools/
```

Plus `.claude/` and `.git/`. No new directories since Pod 1.5.5.

### Sweep E — Git Log + Ref State

Last 5 commits:

```
b560a6c Pod 1.5.5 — pre-Pod-1.6 architect orientation recon
e6a2cc2 Pod 1.5: 64-bit integer width migration — runtime, toolchain, bytecode
eabf160 Pod 1.5: Phase 1 recon report (R1-R12)
7a825f2 Pod 1.4: RECONSTITUTION v5 — width-migration decisions, VM fixes retroactive, arc slide
ed5c68a Pod 1.3: OP_RET wired to vm_ret_stack; OP_HALT pre-existed
```

Three-oracle ref check:

```
git rev-parse HEAD:        b560a6c991d099c87d305dc1b949ee8fca2fc2ff
git rev-parse origin/main: b560a6c991d099c87d305dc1b949ee8fca2fc2ff
git ls-remote origin main: b560a6c991d099c87d305dc1b949ee8fca2fc2ff
```

All three match. Pod 1.5.5 seal confirmed at HEAD.

### Sweep F — Markdown Inventory

**RECONSTITUTION.md:** 406 lines, sha256 `48fc60a8f263ba7fd320c4ffb7ee99a542491507bea6ec45953b7d76d8f5839c`

**recon/MEMO_VERIFICATION_PROVENANCE.md:** Confirmed absent. `ls recon/` output shows 10 files, none named MEMO_VERIFICATION_PROVENANCE.md.

### Sweep G — Cemetery Verification

N/A — no _future/ files in scope for this pod.

---

## R1 — RECONSTITUTION.md pod-arc block (verbatim, pre-edit)

```
## The pod arc (v5 — Pod 1 sub-pods expanded to 13)

Pod 0 — Foundation Lock                                    [SEALED — pod0-complete]
├── 0.0  Reference lock + canonical docs                   [DONE — e2f5db8]
├── 0.1  Extract defines.asm                               [DONE — 4f02dcd]
├── 0.2  Polish auryn.asm header                           [DONE — 4489d01]
├── 0.2.5 Repo-wide archaeology recon                      [DONE — 7facf2a]
├── 0.3  Repo cleanup                                      [DONE]
├── 0.4  Canon updates v2                                  [DONE — a521db2/8a04b16]
├── 0.5  Header polish (5 boot/ modules)                   [DONE]
├── 0.6  Drivers + data.asm                                [DONE — fbb8ba3/e6d41b3]
├── 0.7  auryn_puts consolidation                          [DONE — 4ff12d8]
├── 0.8  Final sign-off + tag                              [DONE — d68167c, tagged pod0-complete]
└── 0.9  cap_graph + paging deep read                      [DONE — 0ab996c]

Pod 1 — Engywook Re-Forged (typed VM with Sign/Cap/Outcome/Energy/Demod)
│       Cap<R> design informed by Pod 0.9's salvaged spatial-merge mechanic.
│       Current cap ops (0x90/0x91) replaced, not extended.
├── 1.0  prompts/ backfill                                 [DONE]
├── 1.1  VM substrate audit (recon-only)                   [DONE]
├── 1.2  Canon update v4                                   [DONE]
├── 1.3  OP_CALL/OP_RET fix + OP_HALT                     [DONE — ebc9554]
├── 1.4  Canon update v5 (this document)                   [DONE]
├── 1.5  64-bit integer width migration                    [planned — VM fixes]
├── 1.6  Sign as native type (0xA0–0xAF)                   [planned — typed primitives]
├── 1.7  Energy: per-opcode cost table (0xD0–0xDF)         [planned — typed primitives]
├── 1.8  Outcome<T>: typed errors + stack bounds (0xC0–0xCF) [planned — typed primitives]
├── 1.9  Cap<R> data structures (0xB0–0xBF)                [planned — cap replacement]
├── 1.10 Cap ops retirement (retire 0x90/0x91)             [planned — cap replacement]
├── 1.11 Demod<S> registration (0xE0–0xEF)                 [planned — demod]
└── 1.12 Pod 1 cleanup + sign-off                          [planned — cleanup]

Pod 2 — Cop is Born (capability service + Ed25519 + energy market)

Pod 3 — Maid is Born (codebook substrate: log store + graph + lexical embed)

Pod 4 — Interpreter is Born (pub-sub demod routing with isolation)

Pod 5 — Surfaces Refactor (every surface becomes a Demod)

Pod 6 — Atreyu Walks (editor)

Pod 7 — Empress + Koreander (search + docs)

Pod 8 — Rockbiter + Falkor (scheduler + trust)

Pod 9 — Maid V2 (neural embeddings)

Pod 10 — Auryn Speaks Far (peer transport)
```

## R2 — Stale-marker audit

| Pod | Arc text | Marker | Actual commit | Classification | Notes |
|-----|----------|--------|---------------|----------------|-------|
| 0.0 | Reference lock + canonical docs | `[DONE — e2f5db8]` | e2f5db8 | **DONE** | Hash matches |
| 0.1 | Extract defines.asm | `[DONE — 4f02dcd]` | 4f02dcd | **DONE** | Hash matches |
| 0.2 | Polish auryn.asm header | `[DONE — 4489d01]` | 4489d01 | **DONE** | Hash matches |
| 0.2.5 | Repo-wide archaeology recon | `[DONE — 7facf2a]` | 7facf2a | **DONE** | Hash matches |
| 0.3 | Repo cleanup | `[DONE]` | 50b2b4a | **DONE** | Missing hash, status correct |
| 0.4 | Canon updates v2 | `[DONE — a521db2/8a04b16]` | a521db2, 8a04b16 | **DONE** | Dual hash matches |
| 0.5 | Header polish (5 boot/ modules) | `[DONE]` | 9f86040 | **DONE** | Missing hash, status correct |
| 0.6 | Drivers + data.asm | `[DONE — fbb8ba3/e6d41b3]` | fbb8ba3, e6d41b3 | **DONE** | Dual hash matches |
| 0.7 | auryn_puts consolidation | `[DONE — 4ff12d8]` | 4ff12d8 | **DONE** | Hash matches |
| 0.8 | Final sign-off + tag | `[DONE — d68167c, tagged pod0-complete]` | d68167c | **DONE** | Hash matches |
| 0.9 | cap_graph + paging deep read | `[DONE — 0ab996c]` | 0ab996c | **DONE** | Hash matches |
| 1.0 | prompts/ backfill | `[DONE]` | b30860e | **DONE** | Missing hash, status correct |
| 1.1 | VM substrate audit (recon-only) | `[DONE]` | 6d47237 | **DONE** | Missing hash, status correct |
| 1.2 | Canon update v4 | `[DONE]` | e69f51f | **DONE** | Missing hash, status correct |
| 1.3 | OP_CALL/OP_RET fix + OP_HALT | `[DONE — ebc9554]` | ed5c68a | **DONE — WRONG HASH** | See Surprise S1 |
| 1.4 | Canon update v5 (this document) | `[DONE]` | 7a825f2 | **DONE** | Missing hash, status correct |
| 1.5 | 64-bit integer width migration | `[planned — VM fixes]` | e6a2cc2 | **STALE** | Complete, marked planned |
| 1.5.5 | (not in arc) | (absent) | b560a6c | **MISSING** | Recon-only pod, not in arc |
| 1.6 | Sign as native type | `[planned — typed primitives]` | — | **FUTURE** | Correct |
| 1.7 | Energy: per-opcode cost table | `[planned — typed primitives]` | — | **FUTURE** | Correct |
| 1.8 | Outcome<T>: typed errors | `[planned — typed primitives]` | — | **FUTURE** | Correct |
| 1.9 | Cap<R> data structures | `[planned — cap replacement]` | — | **FUTURE** | Correct |
| 1.10 | Cap ops retirement | `[planned — cap replacement]` | — | **FUTURE** | Correct |
| 1.11 | Demod<S> registration | `[planned — demod]` | — | **FUTURE** | Correct |
| 1.12 | Pod 1 cleanup + sign-off | `[planned — cleanup]` | — | **FUTURE** | Correct |

**Summary:** 1 STALE (Pod 1.5), 1 MISSING (Pod 1.5.5), 1 WRONG HASH (Pod 1.3), 6 DONE-missing-hash (0.3, 0.5, 1.0, 1.1, 1.2, 1.4).

---

## Section 2 — Surprises

### S1 — Pod 1.3 pod-arc hash `ebc9554` is a dangling pre-amend commit

**What:** RECONSTITUTION.md line 355 reads `[DONE — ebc9554]` for Pod 1.3.
The commit on main for Pod 1.3 is `ed5c68a`. Both `ebc9554` and `ed5c68a`
resolve in the git object database with identical commit messages
("Pod 1.3: OP_RET wired to vm_ret_stack; OP_HALT pre-existed"), identical
timestamps (2026-04-27 23:36:27 -0700), and identical parent commits
(e69f51f). They are amend-siblings: `ebc9554` was the original commit,
`ed5c68a` replaced it via amend or rebase, and the RECONSTITUTION.md
pod-arc was written referencing the pre-amend hash.

**Where:** `RECONSTITUTION.md:355`

**Significance:** The hash `ebc9554` is dangling — it exists only in the
reflog and will eventually be garbage-collected. The pod-arc's reference
to it will become unresolvable. Phase 2 should fix this to `ed5c68a`.

**Pod 1.5.5 forecast comparison:** Pod 1.5.5 §S1 predicted only Pod 1.5
would be stale. The Pod 1.3 wrong-hash is an additional finding — a wider
stale-marker pattern than forecast.

### S2 — Six DONE rows have no commit hash

**What:** Pods 0.3, 0.5, 1.0, 1.1, 1.2, and 1.4 are all correctly marked
`[DONE]` but lack commit hashes. Not stale (status is correct), but
incomplete by the standard set by the other rows.

**Significance:** If Phase 2 is touching the pod-arc block anyway, adding
hashes to these rows creates consistency. The hashes are all verified
from git log above.

---

## Section 3 — Architect Questions

### AQ1 — Scope expansion: fix all incomplete markers, or scope-strict to Pod 1.5 only?

R2 found three categories of fixes needed:
1. **STALE:** Pod 1.5 `[planned]` → `[DONE — e6a2cc2]` (forecast scope)
2. **WRONG HASH:** Pod 1.3 `ebc9554` → `ed5c68a` (surprise — not in forecast)
3. **MISSING HASH:** Pods 0.3, 0.5, 1.0, 1.1, 1.2, 1.4 (no hash where other rows have one)
4. **MISSING ROW:** Pod 1.5.5 absent from arc

Does the architect want all four categories fixed in this pod, or
scope-strict to category 1 only (the forecast scope)?

Recommendation: fix all four. We're already in the pod-arc block. The
hashes are verified. Leaving known-incomplete annotations when we have
the data is the kind of "I'll get it later" that creates Pod 1.5.5-style
recon findings in the next pod.

---

## Section 4 — Proposed Phase 2 Plan

### Part 1 — RECONSTITUTION.md pod-arc edits

Assuming full-scope (all four categories):

**Line 341 (Pod 0.3):** `[DONE]` → `[DONE — 50b2b4a]`
**Line 343 (Pod 0.5):** `[DONE]` → `[DONE — 9f86040]`
**Line 352 (Pod 1.0):** `[DONE]` → `[DONE — b30860e]`
**Line 353 (Pod 1.1):** `[DONE]` → `[DONE — 6d47237]`
**Line 354 (Pod 1.2):** `[DONE]` → `[DONE — e69f51f]`
**Line 355 (Pod 1.3):** `[DONE — ebc9554]` → `[DONE — ed5c68a]`
**Line 356 (Pod 1.4):** `[DONE]` → `[DONE — 7a825f2]`
**Line 357 (Pod 1.5):** `[planned — VM fixes]` → `[DONE — e6a2cc2]`
**New row after 1.5:** `├── 1.5.5 Pre-Pod-1.6 architect orientation recon  [DONE — b560a6c]`

No other lines touched. Pod 0 rows with existing hashes unchanged.
Future pods (1.6–1.12, 2–10) unchanged.

### Part 2 — MEMO_VERIFICATION_PROVENANCE.md

Create `recon/MEMO_VERIFICATION_PROVENANCE.md` with verbatim text from
the Pod 1.5.6 prompt appendix. No edits to content.

---

*Phase 1 complete. Halting for architect AUTHORIZED.*

*From layer 1 kernel up.*
