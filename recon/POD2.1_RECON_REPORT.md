# Pod 2.1 Recon Report — Babylon is Born (spatial-merge activation)

**Pod:** 2.1 — opens Pod 2 with the metabolic activation half
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 5c822f2476ed93f71c2887dfd6547ce265c4d4c8ebcc11bbcee390319e415370 (Pod 1.10.3 BOOTX64.EFI)
**Entry HEAD:** 74f435cd4b525459995546a302150c1cde78f2b3 (Pod 1.10.3 seal)
**Scope:** boot/babylon.asm (NEW), boot/boot.asm (1-line include), boot/cbs_vm.asm (7 retrofit sites + 1 cost stash in fetch), boot/vmdata.asm (1 var), tools/atreyu_x86.py (6 demos + 12 CLI flags), surfaces/test_babylon_*.cbc (6 NEW), canon files.

This pod activates spatial-merge — substrate becomes observably metabolically self-aware. Cop renamed to Babylon at canon supersession.

---

## R1 — Pre-flight three-oracle

```
HEAD               : 74f435cd4b525459995546a302150c1cde78f2b3
origin/main        : 74f435cd4b525459995546a302150c1cde78f2b3
ls-remote refs/heads/main : 74f435cd4b525459995546a302150c1cde78f2b3
```

All three agree at Pod 1.10.3 seal. Build artifacts (#10) modified; twelve untracked test scripts (#59 + #62 + #67 + #70). Both expected.

## R2 — Construction site enumeration (cross-referenced against in-tree code per D1.10.2b2.9 / D1.10.3.8 doctrine)

**Architect estimate: 7 sites. In-tree count: 7 sites. CONFIRMED.**

| # | Site | File:Line | Post-stamp insertion line | Originating cost |
|---|------|-----------|---------------------------|------------------|
| 1 | `.op_sign_new` | cbs_vm.asm:844 | After `call registry_register_sign` at line 899; insert before `mov [r13], rax` at 902 | OP_SIGN_NEW = 100j |
| 2 | `.op_energy_new` | cbs_vm.asm:1025 | After `call registry_register_energy` at line 1054; insert before push at line 1057 | OP_ENERGY_NEW = 10j |
| 3 | `.op_outcome_new_ok` | cbs_vm.asm:1172 | After `call registry_register_outcome` at line 1202; insert before push at line 1205 | OP_OUTCOME_NEW_OK = 1j |
| 4 | `.op_outcome_new_err` | cbs_vm.asm:1219 | After `call registry_register_outcome` at line 1262 (success branch); insert after `pop rax` at line 1272, before push at 1274 | OP_OUTCOME_NEW_ERR = 1j |
| 5 | `.op_cap_new` | cbs_vm.asm:1380 | After MAC stamp at line 1430, before `.construct_ok_outcome` call at line 1435 | OP_CAP_NEW = 1j |
| 6 | `.construct_ok_outcome` helper | cbs_vm.asm:1914 | After `call registry_register_outcome` at line 1948, before `ret` at 1949 | dispatching opcode's cost (varies) |
| 7 | `.construct_err_outcome` helper | cbs_vm.asm:1967 | After `call registry_register_outcome` at line 2008, before `ret` at 2009 | dispatching opcode's cost (varies) |

**Surface S5.1 — OP_CAP_NEW dispatch fires babylon TWICE per success path:**
- Site 5 (Cap slot stamp): babylon(1j, current_cap)
- Site 6 (.construct_ok_outcome wrapping cap_id): babylon(1j, current_cap)

Per Pre-A2's "construction creates" doctrine, OP_CAP_NEW success creates two substrate slots (Cap slot + wrapping Outcome) and rightly fires babylon twice. With cost=1j, both halve to 0 immediately — no actual ripple to ancestors. Net effect equivalent under floor-divide; doctrine preserved without surprise charges.

## R3 — `babylon_charge_lineage` helper design + A2 location

**A2 — TB recommendation: new file `boot/babylon.asm`** parallel to Pod 1.10.2a's `boot/cap.asm`. Spatial naming clarity at the codebase level — Babylon as substrate role earns its own file. Single-symbol export: `babylon_charge_lineage`.

```nasm
; =============================================================
; Babylon — substrate metabolic-accountant (Pod 2.1)
;
; Spatial-merge: walks up the originating cap's parent chain,
; charging each ancestor energy_used += cost / 2^depth via floor
; division. Fires after every successful primitive construction.
;
; Walk semantics:
;   1. Look up originating cap → get its parent_cap_id
;   2. While ancestor != 0:
;        halve cost (shr 1; floor div)
;        if cost == 0: early-terminate (depth tail rounds away)
;        look up ancestor slot
;        add halved cost to ancestor.energy_used
;        advance to next ancestor via ancestor's parent_cap_id
;   3. Terminate when ancestor = 0 (ROOT's parent sentinel)
;
; Originating cap doesn't charge itself. Walk starts at parent.
; ROOT-context operations terminate immediately (ROOT's parent=0).
; No MAC verify on ancestors per Pre-A5 — substrate-private bookkeeping.
;
; Input:  rdi = cost in joules
;         rsi = originating_cap_id
; Output: none (side effects on ancestor slots)
; Clobbers: rax, rcx, rdx, rsi, rdi
; Preserves: r12, r13, r14, r15, rbx, rbp (caller VM state)
; =============================================================

babylon_charge_lineage:
    push    rdi                              ; preserve cost
    mov     rdi, rsi
    call    registry_lookup_cap              ; rax = slot_ptr or 0
    pop     rdi
    test    rax, rax
    jz      .babylon_done                    ; broken originating

    mov     rcx, [rax + CAP_OFF_PARENT_CAP_ID] ; first ancestor

.babylon_loop:
    test    rcx, rcx
    jz      .babylon_done                    ; reached ROOT.parent=0
    shr     rdi, 1                           ; halve cost (floor div)
    jz      .babylon_done                    ; cost decayed to 0

    push    rdi
    push    rcx
    mov     rdi, rcx
    call    registry_lookup_cap              ; rax = ancestor slot_ptr
    pop     rcx
    pop     rdi
    test    rax, rax
    jz      .babylon_done                    ; broken lineage (defensive)

    add     [rax + CAP_OFF_ENERGY_USED], rdi
    mov     rcx, [rax + CAP_OFF_PARENT_CAP_ID]
    jmp     .babylon_loop

.babylon_done:
    ret
```

Approximately 30 lines plus header comment block. Per Pre-A5, no MAC verify on ancestors — bookkeeping at substrate-private speed.

## R4 — Insertion site pattern + A1 cost-fetch strategy

**A1 — TB recommendation: Strategy (c) — global memory cost stash at fetch loop.** Cleaner than (a) dispatcher refactor or (b) at-site re-lookup. Single 1-line addition at fetch loop stashes cost in `[rel current_dispatch_cost]`; helpers and handlers read it back at construction site. **No helper signature changes; no per-site cost-table re-lookup.**

Rationale:
- (a) dispatcher refactor would propagate cost through many handlers; high blast radius
- (b) at-site re-lookup means each handler hardcodes its own opcode and re-runs `energy_cost_lookup`; works for opcode-level sites (1-5) but requires .construct_ok/err_outcome helpers to know the dispatching opcode (passed via source_op for err helper, but ok helper doesn't take source_op — would require helper signature change)
- (c) global stash is one mov in fetch loop, one read at each construction site; no cross-cutting changes

Required additions:
1. `vmdata.asm`: `current_dispatch_cost: dq 0` (one qword)
2. `cbs_vm.asm` fetch loop (line 61 area): after `mov rbx, rax ; cost`, add `mov [rel current_dispatch_cost], rbx`
3. Each construction site: `mov rdi, [rel current_dispatch_cost]; mov rsi, [rel current_cap_id]; call babylon_charge_lineage`

**Insertion pattern at each of 7 sites** (post-stamp / post-register, before any operand-stack push):

```nasm
    ; Pod 2.1 spatial-merge — Babylon charges lineage with dispatching opcode cost
    push    rax                              ; preserve any in-flight result
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rax
```

Exact insertion lines per R2 table. Each site identical 5-line block.

## R5 — Six new test surface designs

| T | Surface | Construction | Expected outputs |
|---|---------|-------------|------------------|
| T1 | test_babylon_single_level.cbc | Cap A under ROOT (1j → 0 ripple). ENTER A. Sign forge (100j). EXIT. | A.used=0 (originating); ROOT.used=50 (100/2 floor) |
| T2 | test_babylon_multi_level.cbc | A under ROOT, B under A, C under B. ENTER chain to C. Sign forge (100j). EXIT chain. | C=0, B=50, A=25, ROOT=12. Three-step geometric decay. **Architectural moment.** |
| T3 | test_babylon_root_only_invisible.cbc | Sign forge under ROOT directly (no sub-cap). | ROOT.used=0 (ROOT's parent=0; walk terminates immediately) |
| T4 | test_babylon_federation_total.cbc | A under ROOT, B under A. Sign×3 forged under B (100j each). Energy×2 forged under A (10j each per cost table — **NOT 50j as architect's spec assumed**; OP_ENERGY_NEW = 10 in tree). | A=150 (3×50 from Sign forges via B); ROOT=85 (3×25 + 2×5 = 75 + 10) |
| T5 | test_babylon_canary_subcap.cbc | Sign forge under sub-cap A. Verify operand-stack cost still 174j; A.used=0; ROOT.used=50 (**NOT 87 as architect's spec — see A4 below**) | 174j operand stack; A=0; ROOT=50 |
| T6 | test_babylon_initial_zero.cbc | At program start, read OP_CAP_USED(ROOT_CAP_ID). | ROOT.used=0 (sanity baseline; fresh boot starts clean) |

## R6 — Regression analysis

All prior pod tests run under ROOT context (originating cap = ROOT, parent_cap_id = 0). Walk-up terminates immediately. **No spatial-merge ripple under ROOT context.**

- Sign 174j canary, Energy 53j canary: hold byte-identical (operand-stack cost unchanged per Pre-A6; substrate-bookkeeping doctrine extends; ROOT-originating means walk terminates)
- Pod 1.9.2b Outcome regression (6 tests): hold (no Cap construction; no sub-cap context)
- Pod 1.9.3 error-path regression (4 tests): hold
- Pod 1.10.2b1 Cap tests (rebuilt at Pod 1.10.3): construct sub-caps but each cap_new under current_cap=ROOT or shallower; spatial-merge fires but cost=1j → 0 ripple; ROOT.used remains 0; bytecode and screen output unchanged
- Pod 1.10.2b2 provenance tests (rebuilt at Pod 1.10.3): same shape; sub-cap constructions ripple at 1j cost (no propagation); Sign forge at 100j under sub-cap WOULD ripple, but those tests don't read OP_CAP_USED to observe — output unchanged
- Pod 1.10.3 budget/used tests: read OP_CAP_USED on caps with no sub-cap operations under them; values unchanged. test_root_cap_unbounded reads OP_CAP_USED(ROOT) → still 0 because no Sign/Energy forge happens before that read in the test program

**Empirical confirmation at HALT 2B B2/B3/B5/B6/B13.**

## R7 — Build chain confirmation

```
NASM version 2.16.01
Build 1: 5c822f2476ed93f71c2887dfd6547ce265c4d4c8ebcc11bbcee390319e415370
Build 2: 5c822f2476ed93f71c2887dfd6547ce265c4d4c8ebcc11bbcee390319e415370
cmp -s:  BYTE-IDENTICAL
```

Entry contract verified at `5c822f24...`. Two-build determinism preserved.

## R8 — Recon report

This document at `recon/POD2.1_RECON_REPORT.md`.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Cost fetch strategy

**TB recommendation: (c) global memory stash at fetch loop.** Adds one qword in vmdata.asm and one mov in fetch loop; helpers + handlers read at construction site. No helper signature changes; cleanest blast radius. Surface (a) dispatcher refactor and (b) at-site re-lookup as alternatives at recon; architect ratifies.

D2.1 will record the choice.

### A2 — `babylon_charge_lineage` helper location

**TB recommendation: new file `boot/babylon.asm`** per architect's pre-recon framing. Spatial naming clarity at the codebase level. Single-symbol export. Parallel to `boot/cap.asm` (Pod 1.10.2a). Adds one `%include` line to `boot/boot.asm` adjacent to existing cap.asm include at line 399.

D2.1 records the choice.

### A3 — Construction site count verification

**Architect estimate: 7. In-tree count: 7. CONFIRMED at recon.** Sites enumerated verbatim in R2 above. No discrepancy; D1.10.2b2.9 / D1.10.3.8 doctrine cleared at recon.

### A4 — T5 expected value correction (NEW recon finding)

Architect's T5 spec: "Sign forge under sub-cap A; ROOT.used = 87 (174/2 = 87)."

**This expected value is mathematically inconsistent with the proposed mechanism.** The 174j is the *canary aggregate* (sum of all opcode costs in the test program — OP_SIGN_NEW 100j + accessor reads + PUSH/print scaffolding). It is NOT the cost of any single opcode dispatch. babylon_charge_lineage fires per-construction-site with the dispatching opcode's cost (per Pre-A2 / R2 / R4).

For Sign forge under depth-1 sub-cap A:
- OP_SIGN_NEW (100j) at site #1: babylon(100, A) → first ancestor = ROOT. shr 100=50. ROOT += 50. ROOT.parent=0; exit.
- Other test program ops (PUSH, prints, accessor reads) fire spatial-merge at small costs (≤5j); each propagates 0-2j into ROOT.

Expected ROOT.used after T5:
- **50** from OP_SIGN_NEW alone
- **+2** from OP_SIGN_ENERGY (5j accessor → 5/2=2 charged to ROOT)
- **= 52** total (if accessor reads happen before the OP_CAP_USED(ROOT) measurement)

OR — for predictability — redesign T5 to be a MINIMAL test that does only Sign forge + immediate OP_CAP_USED(ROOT) read, expecting **ROOT=50**.

**TB recommendation: redesign T5 to minimal shape; expected ROOT=50.** Keep the canary spirit (sub-cap forge does not affect operand-stack cost) but separate it from the spatial-merge measurement.

Surface for architect ratification at HALT 1; the architect's "ROOT=87" expectation as written cannot be produced by the proposed mechanism without reinterpreting "originating operation's cost" to mean "test-program aggregate cost" (which would conflict with Pre-A2 / per-construction-site framing).

D2.1 will record the T5 design.

---

## Section 3 — Risks identified

- **R3.1 — OP_CAP_NEW double-fires babylon per success path** (R2 surface S5.1). With cost=1j, both fires halve to 0 immediately; no actual ripple to ancestors. Doctrine preserved (each construction creates → each fires babylon); no surprise charges. Document explicitly so future readers see the two-site nature of OP_CAP_NEW dispatch.
- **R3.2 — current_dispatch_cost stash must happen BEFORE handler dispatch** so the cost is available at construction-site read. Insertion at fetch loop must follow `mov rbx, rax` (cost lookup) and precede the `cmp al, OP_*` dispatch chain. Verified at HALT 2A diff review.
- **R3.3 — T5 architect expectation incorrect** (A4 surface). Mathematical reconciliation above.
- **R3.4 — Helper-driven Outcome construction propagates dispatching opcode cost.** When .op_sign_arena (0j) calls .construct_ok_outcome (site 6), babylon fires at 0j → walk no-op. When .op_cap_arena (1j) calls helper, babylon fires at 1j → 0 ripple. When .op_sign_new (100j) FAILS and calls .construct_err_outcome (site 7), babylon fires at 100j → 50 ripple to ancestors. The cost-stash strategy means the helper reads the ORIGINATING opcode's cost, not the helper's own cost. Verified mechanism at HALT 2B B11.

---

## Section 4 — Phase 2 execution gates

S1: defines.asm — no changes (no new opcodes; no new slot offsets).
S2: vmdata.asm — `current_dispatch_cost: dq 0` (one qword).
S3: boot/babylon.asm NEW — `babylon_charge_lineage` helper per R3.
S4: boot/boot.asm — one `%include "boot/babylon.asm"` adjacent to existing includes.
S5: boot/cbs_vm.asm — fetch loop adds `mov [rel current_dispatch_cost], rbx`; 7 retrofit insertion sites at the locations enumerated in R2; uniform 5-line block per site.
S6: tools/atreyu_x86.py — 6 new demo programs (T1-T6) per R5; 12 new CLI flags. `cap_new` AST handler unchanged (already 2-arg from Pod 1.10.3).
S7: surfaces — 6 new test surfaces compiled.

Phase 2B: 14 B-items per architect spec (B1 determinism + B2/B3 canaries + B4 pristine boot + B5/B6 regression invisibility + B7-B12 six new + B13 Cap regression rebuild + B14 liveness).

---

## Section 5 — Surprises

- **S5.1 — OP_CAP_NEW double-fires** (R3.1). Documented; floor-divide neutralizes.
- **S5.2 — Helper sites read dispatching opcode cost via global stash, not own cost.** Per A1 ratification. Helpers execute spatial-merge as proxy for the calling opcode.
- **S5.3 — T5 architect spec needed correction** (A4). Same family as D1.10.2a.10 / D1.10.2b1.8 / D1.10.2b2.9 / D1.10.3.8 — architect-side detail error caught at recon. Expected-value computation conflated canary aggregate with single-op cost.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 4 architect calls (A1 cost fetch strategy → global stash, A2 helper location → boot/babylon.asm, A3 site count verified at 7, A4 T5 expected-value correction).
- 4 risks surfaced (R3.1 double-fire benign; R3.2 fetch-loop ordering; R3.3 T5 redesign; R3.4 helper cost-source clarification).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED-1.**

— Terminal Boy
May 04 2026
