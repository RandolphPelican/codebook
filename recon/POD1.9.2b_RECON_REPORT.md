# Pod 1.9.2b Recon Report — Outcome opcode handlers + tests

**Pod:** 1.9.2b — second source pod of Section 2 (handlers, cost table, log strings, prov_append wire-up, tools, 6 test surfaces)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432 (Pod 1.9.2a BOOTX64.EFI)
**Entry HEAD:** 164238fa9926c825ef9f4872757647c3eb7e234c (Pod 1.9.2a seal)
**Scope:** boot/cbs_vm.asm (handlers + dispatch), boot/energy_costs.asm (cost table), boot/data.asm (log strings), tools/atreyu_x86.py (5 opcodes + 5 AST handlers + 6 demos + 12 flags), surfaces/* (6 new .cbc), canon files.

---

## R1 — Pre-flight three-oracle

| Source | Hash | Match |
|--------|------|-------|
| `git rev-parse HEAD` | 164238fa9926c825ef9f4872757647c3eb7e234c | ✓ |
| `git rev-parse origin/main` | 164238fa9926c825ef9f4872757647c3eb7e234c | ✓ |
| `git ls-remote origin refs/heads/main` | 164238fa9926c825ef9f4872757647c3eb7e234c | ✓ |

Three-oracle agrees. Build artifacts (DEFERRED #10) and three throwaway scripts (DEFERRED #33-#34) untracked.

## R2 — Dispatch chain insertion site

Current dispatch chain tail (verbatim, cbs_vm.asm:140-152):

```
    cmp     al, OP_ENERGY_NEW
    je      .op_energy_new
    cmp     al, OP_ENERGY_JOULES
    je      .op_energy_joules
    cmp     al, OP_ENERGY_SOURCE_OP
    je      .op_energy_source_op
    cmp     al, OP_ENERGY_FREE
    je      .op_energy_free
    cmp     al, OP_ENERGY_RECOVER
    je      .op_energy_recover
    cmp     al, OP_PHASE_QUERY
    je      .op_phase_query
                                              <-- INSERTION SITE
    ; Unknown opcode
```

Insert 5 new entries after line 151 (`je .op_phase_query`), before line 152 (blank/Unknown comment):
```
    cmp     al, OP_OUTCOME_NEW_OK
    je      .op_outcome_new_ok
    cmp     al, OP_OUTCOME_NEW_ERR
    je      .op_outcome_new_err
    cmp     al, OP_OUTCOME_IS_OK
    je      .op_outcome_is_ok
    cmp     al, OP_OUTCOME_UNWRAP_OK
    je      .op_outcome_unwrap_ok
    cmp     al, OP_OUTCOME_UNWRAP_ERR
    je      .op_outcome_unwrap_err
```

Pattern matches Pod 1.8.5c 0xD4/0xD5 additions exactly.

**Branch-distance:** dispatch chain has 22 cmp/je pairs pre-insertion (24 post). Each `je` is short by default. NASM auto-promotes to near-jump if target exceeds ±127 bytes. Since outcome handlers will be inserted after `.op_phase_query` (around line 1009), they're well past 127 bytes from the dispatch chain. NASM handles this transparently — no branch-distance work required. Flag for completeness, not action.

## R3 — Cost table site audit

Current 0xE0-0xEF row (energy_costs.asm:126-127):

```
; Row 0xE0–0xEF
    times 16 dq 1           ; 0xE0–0xEF — unallocated (Demod 0xE0–0xEF Pod 1.12)
```

**Note:** RECONSTITUTION v9 (Pod 1.9.1) updated the documentation to relocate Outcome to 0xE0-0xE4 and tighten Demod to 0xE5-0xEF, but `boot/energy_costs.asm` was not touched. Pod 1.9.2b makes the source-side update.

**Recommended replacement** (mirrors Pod 1.8.5c 0xD-block per-entry pattern):

```
; Row 0xE0–0xEF — Outcome opcodes (Pod 1.9.2b at 0xE0-0xE4) + Demod reserved (Pod 1.12 at 0xE5-0xEF)
    dq 1                    ; 0xE0 — OP_OUTCOME_NEW_OK (metabolic construction; A3 ratification)
    dq 1                    ; 0xE1 — OP_OUTCOME_NEW_ERR (metabolic construction; A3 ratification)
    dq 0                    ; 0xE2 — OP_OUTCOME_IS_OK (structural read; A3 ratification)
    dq 0                    ; 0xE3 — OP_OUTCOME_UNWRAP_OK (structural; diagnostic emit on err is structural side effect)
    dq 0                    ; 0xE4 — OP_OUTCOME_UNWRAP_ERR (structural; diagnostic emit on ok is structural side effect)
    dq 1, 1, 1, 1, 1       ; 0xE5–0xE9 — reserved (Demod Pod 1.12)
    dq 1, 1, 1, 1, 1       ; 0xEA–0xEE — reserved (Demod Pod 1.12)
    dq 1                    ; 0xEF — reserved (Demod Pod 1.12)
```

Total 16 entries (5 Outcome + 11 reserved). Format matches existing 0xD-block convention exactly.

## R4 — auryn_puts calling convention

Verified via OP_ENERGY_RECOVER template (cbs_vm.asm:997-1001):

```
.op_energy_recover:
    sub     r13, 8                  ; pop recovery argument (discard V1.0)
    lea     rsi, [rel str_op_energy_recover_noop]
    call    auryn_puts
    jmp     .fetch
```

- **Calling convention:** `lea rsi, [rel str_label]; call auryn_puts`
- **String format:** null-terminated; auryn_puts handles the trailing newline if string includes it (str_op_energy_recover_noop ends `,10,0`)
- **Save/restore:** none required around the call. r12 (instruction ptr), r13 (operand stack), r14 (energy budget) all preserved by auryn_puts.
- **Insertion point for new outcome handlers:** after `.op_phase_query` (cbs_vm.asm:1009), before `.energy_alloc` (line 1011). Section break is natural.

## R5 — Sentinel log string sites

Current end of string-literal block (data.asm:285-289):

```
str_vm_unk:   db '  Unknown opcode: ',0
str_ret_underflow: db '  VIOLATION: return stack underflow',10,0
str_call_overflow: db '  VIOLATION: return stack overflow',10,0
str_run_bad:  db '  Usage: run <0-8>',10,0
str_op_energy_recover_noop: db '  OP_ENERGY_RECOVER no-op V1.0',10,0
                                                        <-- INSERT HERE (line 290)

str_prog_list:
```

Insert two new strings:
```
str_unwrap_ok_on_err: db '  UNWRAP_OK on Err — sentinel returned',10,0
str_unwrap_err_on_ok: db '  UNWRAP_ERR on Ok — sentinels returned',10,0
```

Format matches str_op_energy_recover_noop (Pod 1.8.5c) precedent exactly.

## R6 — prov_append re-verify

Confirmed unchanged from Pod 1.9.1 R6 / Pod 1.9.2a R-confirmation:
- Input: `rdi=opcode, rsi=demod_id, rdx=fetch_counter`
- Output: none
- Clobbers: rax, rcx
- Preserves: r12, r13, r14, r15, rbx, rbp, rdi, rsi, rdx
- Cap-gate internal (checks `[rel current_demod_prov_enabled]`, returns immediately if 0)

**Subtle interaction with NEW_ERR's energy-debit register state:** none. r14 (energy budget) is preserved by prov_append per its documented preserve discipline. NEW_ERR's handler can call prov_append immediately after writing the err context without saving any registers.

## R7 — atreyu_x86.py addition plan

Pattern from existing extensions (Pod 1.8.5c added phase / energy_recover):

**Opcode constants (after line 50, the existing OP_ENERGY_RECOVER + OP_PHASE_QUERY block):**
```
OP_OUTCOME_NEW_OK     = 0xE0
OP_OUTCOME_NEW_ERR    = 0xE1
OP_OUTCOME_IS_OK      = 0xE2
OP_OUTCOME_UNWRAP_OK  = 0xE3
OP_OUTCOME_UNWRAP_ERR = 0xE4
```

**Plus TYPE_CODE_* constants** (referenced by demo programs; landed in defines.asm at Pod 1.9.2a):
```
TYPE_CODE_NONE     = 0
TYPE_CODE_SIGN     = 1
TYPE_CODE_ENERGY   = 2
TYPE_CODE_CAP      = 3
TYPE_CODE_DEMOD    = 4
TYPE_CODE_SIGNAL   = 5
TYPE_CODE_OUTCOME  = 6
```

**AST handlers (5 expression-form):**
- `outcome_new_ok` (operand-form): pushes value_type_id, value, OP_OUTCOME_NEW_OK
- `outcome_new_err` (5-arg form): pushes value_type_id, err_code, err_source_op, err_demod_id, err_fetch_counter, OP_OUTCOME_NEW_ERR
- `outcome_is_ok` (operand-form): pushes operand, OP_OUTCOME_IS_OK
- `outcome_unwrap_ok` (operand-form): pushes operand, OP_OUTCOME_UNWRAP_OK
- `outcome_unwrap_err` (operand-form): pushes operand, OP_OUTCOME_UNWRAP_ERR

**Plus T6-specific compound nodes** (per R8/A1 design):
- `outcome_dup_is_ok` (operand-form): pushes operand, OP_DUP, OP_OUTCOME_IS_OK — leaves [outcome_id, 0/1] on stack for T6
- `outcome_unwrap_ok_tos`: emits OP_OUTCOME_UNWRAP_OK only, expects TOS = outcome_id (T6 follow-up)

**Plus UNWRAP_ERR field-extraction helper for T2/T5** (avoids stack rotation):
- `outcome_unwrap_err_field` (operand+index): emits operand, OP_OUTCOME_UNWRAP_ERR, then drops to extract one field. Approach depends on A1 resolution.

**6 demo programs:** demo_outcome_ok, demo_outcome_err, demo_outcome_is_ok, demo_outcome_unwrap_ok, demo_outcome_unwrap_err, demo_outcome_dup_is_ok.

**12 CLI flags:** `--outcome-{ok,err,is-ok,unwrap-ok,unwrap-err,dup-is-ok}-{build,test}` parallel to phase / energy_recover patterns.

## R8 — Test surface design pre-plan

T1 (test_outcome_ok), T3 (test_outcome_is_ok), T4 (test_outcome_unwrap_ok), T6 (test_outcome_dup_is_ok): tractable with the AST extensions in R7. T6 specifically uses `outcome_dup_is_ok` for the DUP-IS_OK pattern + `outcome_unwrap_ok_tos` for the follow-up unwrap.

T2 (test_outcome_err) and T5 (test_outcome_unwrap_err): print-order issue surfaced as A1 above.

**Tractability summary:** All 6 tests are tractable. T2/T5 print order depends on A1 resolution — option (ii) recommended (reverse UNWRAP_ERR push order so TOS = err_code, prints in field-declaration order naturally).

## R9 — Build chain confirmation

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 | ✓ |
| `./build.sh` × 2 | exit 0 both runs | ✓ |

**Determinism / entry contract:**
- Run 1 EFI sha256: `23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432` ✓
- Run 2 EFI sha256: `23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432` ✓
- ENTRY_DETERMINISM: MATCH ✓
- ENTRY_CONTRACT: MATCHES Pod 1.9.2a row in binary_contracts.md ✓

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — UNWRAP_ERR push order

D1.9.1.4 spec: "push err_code, push err_source_op, push err_demod_id, push err_fetch_counter (4 values)". Sequential reading → TOS = err_fetch_counter. With PRINT_NUM popping TOS, output order is **reverse** of field-declaration order.

Test specs T2 and T5 expect output in field-declaration order ("99, 0xA0, 1, 12345 in order" and "42, 160, 1, 99").

OP_SIGN_HASH precedent: pushes hash[0:8] at bottom, hash[24:32] at TOS — field-position-0 is at bottom. UNWRAP_ERR following the same convention puts err_code at bottom.

**Three options:**
- **(i)** Spec verbatim, test prints in reverse (output: 12345, 1, 160, 99 / 99, 1, 160, 42). Faithful to spec; matches OP_SIGN_HASH convention; T2/T5 verify specs adjust.
- **(ii)** **TB recommendation.** Reverse handler push order: err_fetch_counter pushed first (bottom), err_code pushed last (TOS). Caller pops in field-declaration order naturally. Tests pass without stack rotation. Diverges from D1.9.1.4 verbatim wording but preserves architectural intent (4 fields available for read).
- **(iii)** Test program does extra stack rotation (4× UNWRAP + drops). Ugly; opcode-wasteful.

Confirm or override.

### A2 — Pool-full strings

S1 spec ("if at capacity, push 0 sentinel and emit error log") implies a new string `str_outcome_pool_full` (or similar). Pool-full is unreachable in V1.0 (capacity 64; tests construct 1-2 outcomes). Could:
- (i) Add the string and log line in this pod for completeness/future-proofing
- (ii) Skip the log (sentinel only); add string later when pool-full handling matters

**TB recommendation:** (ii) skip — pool-full is unreachable in V1.0; sentinel (0 push) already matches the existing accessor null-handler pattern (sign_new_fail / energy_new_fail). DEFERRED entry forward-logs pool-full handling (architect's C2 list already covers it as "Pool-full handling in OP_OUTCOME_NEW_OK / OP_OUTCOME_NEW_ERR (sentinel-and-log per V1.0 convention; Pod 2 Cop hardens)").

Confirm or amend (add string in this pod).

### A3 — IS_OK on invalid id

S1 spec for OP_OUTCOME_IS_OK: "If slot_ptr=0 (invalid id), push 0 (treats invalid as not-ok; surface as A-call if alternative wanted)."

Two options:
- (i) **TB recommendation.** Invalid id → push 0 (treats invalid as not-ok). Matches the substrate's "null is err-ish" convention. Caller doing IS_OK on garbage gets "not OK" which is the safe default.
- (ii) Invalid id → push some other sentinel (e.g., -1 / u64::MAX). Distinguishes "real err" from "invalid id." Requires the caller to check three values instead of two.

(i) is simpler; (ii) is more honest. Confirm.

---

## Section 3 — Risks identified

- **R3.1 — A1 resolution affects 5 source touches** (UNWRAP_ERR handler; 2 test surface designs T2/T5; possibly the AST helper for field extraction). Resolving early avoids rework.
- **R3.2 — UNWRAP_ERR handler complexity grows with 4-value push** (vs. UNWRAP_OK's 1-value push). Stack-pointer arithmetic gets verbose. Verifying NASM `add r13, 32` after 4 writes is correct.
- **R3.3 — NEW_ERR handler is the most complex of the five** — pops 5 args, writes 8 slot fields (4 args + value=0 + zeros for value/arena/owner), registers, calls prov_append. Worth careful review at HALT 2A.
- **R3.4 — Six new test surfaces are six new opportunities for compiler bugs in atreyu_x86.py.** Each demo program is its own integration. Failures in any demo signal compiler defect, not handler defect — careful diagnosis needed.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

S1: 5 handler labels in cbs_vm.asm (~150-200 lines added)
S2: 5 dispatch entries in cbs_vm.asm (10 lines added)
S3: cost table replacement in energy_costs.asm (line 126-127 → 16-line block)
S4: 2 new sentinel log strings in data.asm
S5: tools/atreyu_x86.py — 5 opcodes + 8 AST handlers + 6 demos + 12 flags

Phase 2B B1 reads BOOTX64.EFI determinism. B2/B3 verify Sign/Energy invisibility. B4-B9 verify 6 outcome surfaces. B10 liveness probe.

---

## Section 5 — Surprises

- **S5.1 — A1 surfaces a real spec-vs-test conflict** that could have been silent if Phase 2A executed without R8 verification. The DUP-IS_OK pattern test (T6) made the print-order issue obvious by requiring multi-value retention; T2/T5 alone might have been "fixed" with stack rotation in the demo. Recon caught the design surface.
- **S5.2 — All 5 handlers can call auryn_puts safely** without register save/restore. The OP_ENERGY_RECOVER template generalizes cleanly. UNWRAP_OK and UNWRAP_ERR diagnostic emission is a one-line pattern.
- **S5.3 — RECONSTITUTION v9 was canon-only — energy_costs.asm wasn't updated in 1.9.1.** The 0xE0-0xEF row still says "Demod Pod 1.12" in the source. Pod 1.9.2b carries the source-side update of what 1.9.1 documented.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 3 architect calls (A1-A3); A1 is load-bearing for handler shape and test design, A2/A3 are simple confirms.
- 4 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
