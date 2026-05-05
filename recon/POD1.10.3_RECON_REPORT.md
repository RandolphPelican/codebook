# Pod 1.10.3 Recon Report — Cap Metabolic Wiring

**Pod:** 1.10.3 — substrate prep for Cop (no behavior activation)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 39ad88603422f68a41dec3e0430dedc0526fe92ba2e29f9fb40b6516aead0f25 (Pod 1.10.2b2 BOOTX64.EFI)
**Entry HEAD:** 5167287a4c3ecd4547e095c8bbe7f9da27ea9b62 (Pod 1.10.2b2 seal)
**Scope:** boot/defines.asm, boot/cap.asm, boot/cbs_vm.asm, boot/energy_costs.asm, tools/atreyu_x86.py, surfaces/test_cap_*_(NEW + rebuilt) (5 NEW + 6 rebuild), canon files.

This pod adds two new Cap slot fields (energy_budget MAC-input + energy_used non-MAC), amends OP_CAP_NEW to pop two args, and ships two new accessors via .cap_accessor_common reuse. The pod is **substrate prep only**; no spatial-merge / delegation tax / behavior activation. Pod 2 (Cop) wires the accounting flows.

---

## R1 — Pre-flight three-oracle

```
HEAD               : 5167287a4c3ecd4547e095c8bbe7f9da27ea9b62
origin/main        : 5167287a4c3ecd4547e095c8bbe7f9da27ea9b62
ls-remote refs/heads/main : 5167287a4c3ecd4547e095c8bbe7f9da27ea9b62
```

All three agree at Pod 1.10.2b2 seal. Build artifacts (#10) modified; nine throwaway scripts (#59 + #62 + #67) untracked. Both expected.

## R2 — Cap slot layout audit + relayout plan

Current Cap slot layout (defines.asm:163-170 + cap.asm:303 comments):

```
+0x00 cap_id_self
+0x08 arena_id
+0x10 owner_demod_id
+0x18 resource_descriptor
+0x20 parent_cap_id
+0x28 generation_counter
+0x30 mac
+0x38..0x7F reserved (9 qwords / 72 bytes)

CAP_MAC_INPUT_QWORDS = 6
CAP_OFF_MAC = 0x30
CAP_SLOT_SIZE = 0x80 (128 bytes — unchanged)
```

**Proposed relayout per Pre-A1/A6:**

```
+0x00 cap_id_self
+0x08 arena_id
+0x10 owner_demod_id
+0x18 resource_descriptor
+0x20 parent_cap_id
+0x28 generation_counter
+0x30 energy_budget          ← NEW (MAC-input, immutable identity component)
+0x38 mac                    ← shifted from 0x30
+0x40 energy_used            ← NEW (non-MAC, mutable substrate-managed state)
+0x48..0x7F reserved (8 qwords / 64 bytes)

CAP_MAC_INPUT_QWORDS = 7      ← was 6
CAP_OFF_ENERGY_BUDGET = 0x30  ← NEW
CAP_OFF_MAC = 0x38            ← was 0x30
CAP_OFF_ENERGY_USED = 0x40    ← NEW
CAP_SLOT_SIZE = 0x80 (unchanged; reserved zone shrinks 9q→8q)
```

**Propagation analysis:** all five existing call sites that compute/verify Cap MAC use the symbolic `CAP_MAC_INPUT_QWORDS` constant (none hardcoded as literal `6`):
- `cbs_vm.asm:1410` — `.op_cap_new` MAC compute at construction
- `cbs_vm.asm:1453` — `.op_cap_enter` MAC verify
- `cbs_vm.asm:1630` — `.cap_accessor_common` MAC verify
- `cap.asm:130` — `siphash_compute_cap_mac` wrapper
- `cap.asm:320, 351` — `construct_root_cap` and `verify_root_cap_mac` (boot E3 self-test)

Updating the constant 6→7 propagates cleanly. **No site-count surprise** (per D1.10.2b2.9 doctrine — cross-referenced against in-tree code).

`CAP_OFF_MAC` is referenced as `[rbx + CAP_OFF_MAC]` at multiple sites in cbs_vm.asm and cap.asm. The shift 0x30→0x38 propagates via the constant. Verified: no hardcoded `0x30` in MAC-write/MAC-compare paths.

## R3 — OP_CAP_NEW signature audit + amendment plan

Current handler (cbs_vm.asm:1371-1395+):

```nasm
.op_cap_new:
    sub     r13, 8
    mov     r10, [r13]                      ; resource_descriptor
    ; Pool capacity check ...
    ; Compute slot pointer ...
    ; Write Cap slot fields:
    mov     qword [rbx + CAP_OFF_CAP_ID_SELF], 0
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + CAP_OFF_ARENA_ID], rax
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + CAP_OFF_OWNER_DEMOD_ID], rax
    mov     [rbx + CAP_OFF_RESOURCE_DESC], r10
    mov     rax, [rel current_cap_id]
    mov     [rbx + CAP_OFF_PARENT_CAP_ID], rax
    mov     qword [rbx + CAP_OFF_GENERATION_COUNTER], 0
    ; ... register, stamp cap_id_self, MAC compute over 6 qwords ...
```

**Amendment plan** — pop two args; top of stack is `energy_budget` (last pushed); next is `resource_descriptor`. Stack order confirms with existing CBS calling convention (every Pod 1.7+ multi-arg opcode pops top first; e.g., `.op_outcome_new_err` pops err_fetch_counter first).

```nasm
.op_cap_new:
    sub     r13, 8
    mov     r9, [r13]                       ; energy_budget (top of stack)
    sub     r13, 8
    mov     r10, [r13]                      ; resource_descriptor
    ; Pool capacity check ...
    ; Compute slot pointer ...
    ; Write Cap slot fields:
    mov     qword [rbx + CAP_OFF_CAP_ID_SELF], 0
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + CAP_OFF_ARENA_ID], rax
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + CAP_OFF_OWNER_DEMOD_ID], rax
    mov     [rbx + CAP_OFF_RESOURCE_DESC], r10
    mov     rax, [rel current_cap_id]
    mov     [rbx + CAP_OFF_PARENT_CAP_ID], rax
    mov     qword [rbx + CAP_OFF_GENERATION_COUNTER], 0
    mov     [rbx + CAP_OFF_ENERGY_BUDGET], r9       ; NEW (Pod 1.10.3, MAC-input)
    mov     qword [rbx + CAP_OFF_ENERGY_USED], 0    ; NEW (Pod 1.10.3, non-MAC, init=0)
    ; ... register, stamp cap_id_self, MAC compute over 7 qwords (unchanged source — symbolic constant) ...
```

Note: the `energy_used=0` write happens at the construction site even though Pod 1.10.3 doesn't ever increment it. This is honest "initialize at construction" hygiene; substrate-bookkeeping per D1.10.2b2.3 is 0j regardless of field count, so canaries hold.

## R4 — ROOT_CAP construction + verification update plan

Current `construct_root_cap` (cap.asm:310-337):

```nasm
construct_root_cap:
    lea     rdi, [rel vm_cap_pool]
    mov     qword [rdi + CAP_OFF_CAP_ID_SELF],        ROOT_CAP_ID
    mov     qword [rdi + CAP_OFF_ARENA_ID],           0
    mov     qword [rdi + CAP_OFF_OWNER_DEMOD_ID],     0
    mov     qword [rdi + CAP_OFF_RESOURCE_DESC],      0
    mov     qword [rdi + CAP_OFF_PARENT_CAP_ID],      0
    mov     qword [rdi + CAP_OFF_GENERATION_COUNTER], 0
    ; Compute MAC over 6 qwords
    push    rdi
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    pop     rdi
    mov     [rdi + CAP_OFF_MAC], rax
    inc     qword [rel vm_cap_next]
    call    registry_register_cap
    ; cap_id sanity check ...
```

**Amendment plan** — write `energy_budget = ENERGY_BUDGET_UNBOUNDED = 0xFFFFFFFFFFFFFFFF` and `energy_used = 0` between generation_counter write and MAC compute:

```nasm
construct_root_cap:
    lea     rdi, [rel vm_cap_pool]
    mov     qword [rdi + CAP_OFF_CAP_ID_SELF],        ROOT_CAP_ID
    mov     qword [rdi + CAP_OFF_ARENA_ID],           0
    mov     qword [rdi + CAP_OFF_OWNER_DEMOD_ID],     0
    mov     qword [rdi + CAP_OFF_RESOURCE_DESC],      0
    mov     qword [rdi + CAP_OFF_PARENT_CAP_ID],      0
    mov     qword [rdi + CAP_OFF_GENERATION_COUNTER], 0
    mov     rax, ENERGY_BUDGET_UNBOUNDED                  ; NEW (MAX_U64; can't use 64-bit immediate to memory)
    mov     [rdi + CAP_OFF_ENERGY_BUDGET], rax            ; NEW
    mov     qword [rdi + CAP_OFF_ENERGY_USED], 0          ; NEW (non-MAC, init=0)
    ; Compute MAC over 7 qwords (constant updated; siphash_compute reads cap_id through energy_budget)
    push    rdi
    mov     rsi, CAP_MAC_INPUT_QWORDS                     ; now 7
    call    siphash_compute
    pop     rdi
    mov     [rdi + CAP_OFF_MAC], rax                       ; CAP_OFF_MAC now 0x38 (constant updated)
    inc     qword [rel vm_cap_next]
    call    registry_register_cap
    ; cap_id sanity check ...
```

`verify_root_cap_mac` (cap.asm:344-363) parallel — recomputes over 7 qwords (constant propagates), compares to MAC at new offset 0x38 (constant propagates). Source change: zero — only constant updates.

`siphash_compute_cap_mac` wrapper (cap.asm:129-131) parallel — `mov rsi, CAP_MAC_INPUT_QWORDS` symbolically; updates with constant.

## R5 — Two new accessor handler designs

Both reuse Pod 1.10.2b1's `.cap_accessor_common` (already polymorphic over Cap-slot field offsets, already MAC-verifies). Five-line stubs each — third and fourth consumers of D1.10.2b1.5's factoring.

```nasm
; --- OP_CAP_BUDGET (0xB8) ---
.op_cap_budget:
    sub     r13, 8
    mov     rdi, [r13]                       ; cap_id
    mov     rcx, CAP_OFF_ENERGY_BUDGET       ; 0x30
    mov     rsi, OP_CAP_BUDGET
    call    .cap_accessor_common             ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_USED (0xB9) ---
.op_cap_used:
    sub     r13, 8
    mov     rdi, [r13]                       ; cap_id
    mov     rcx, CAP_OFF_ENERGY_USED         ; 0x40
    mov     rsi, OP_CAP_USED
    call    .cap_accessor_common             ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

Cost 1j metabolic each — Cap accessor convention (helper does MAC verify per Pod 1.10.2b1 D1.10.2b1.4).

## R6 — Opcode allocation

Cap range 0xB0-0xBF: 0xB0-0xB6 used by Pod 1.10.2b1, 0xB7 used by Pod 1.10.2b2. Pod 1.10.3 takes:

| Opcode | Value | Decimal (for source_op tests) |
|--------|-------|-------|
| OP_CAP_BUDGET | 0xB8 | 184 |
| OP_CAP_USED   | 0xB9 | 185 |

Reserved range now 0xBA-0xBF (6 slots remain in Cap block).

## R7 — Cost table additions

```nasm
; (existing 0xB-row from Pod 1.10.2b1 + 1.10.2b2)
    dq 1                    ; 0xB7 — OP_CAP_PARENT (Pod 1.10.2b2)
    dq 1                    ; 0xB8 — OP_CAP_BUDGET (Pod 1.10.3; metabolic; lookup + MAC verify + budget read)
    dq 1                    ; 0xB9 — OP_CAP_USED (Pod 1.10.3; metabolic; lookup + MAC verify + used read)
    dq 1, 1, 1, 1, 1, 1     ; 0xBA–0xBF — reserved
```

Both at 1j metabolic per Cap accessor convention. Comment cleanup on Cap row header to mention Pod 1.10.3.

## R8 — Cap test regression strategy (A1 surface)

OP_CAP_NEW signature amendment ripples through every Cap test built under the 1-arg shape. **Six existing demos in atreyu_x86.py use the `cap_new` AST emitter:**

| # | Demo (1.10.2b1/2b2) | Constructs cap with resource_descriptor= |
|---|---------------------|-------------------------------------------|
| 1 | demo_cap_new_basic | 42 |
| 2 | demo_cap_arena_owner_resource | 42 |
| 3 | demo_cap_current | 99 |
| 4 | demo_cap_stack_overflow | 77 |
| 5 | demo_provenance_under_subcap | 42 |
| 6 | demo_provenance_walk | 77 |

`demo_cap_invalid_id` and `demo_cap_stack_underflow` from 1.10.2b1 do NOT use `cap_new` (they use `cap_arena_raw_id` and `raw_op_cap_exit` respectively). Their bytecode is unaffected.

**Two strategies:**

- **(a)** Update `cap_new` AST emitter to push two args (resource_descriptor + energy_budget); existing demos inherit by passing default `energy_budget=ENERGY_BUDGET_UNBOUNDED` if not specified. Bytecode shape changes by 9 bytes per cap_new (one extra `OP_PUSH` + 8-byte i64 immediate). All 6 demos rebuild under new shape; semantics preserved (cap_id=2 still first user-created, walk still produces same values), byte-identity to prior pod references intentionally broken.
- **(b)** Add a separate `OP_CAP_NEW_BUDGETED` opcode; keep `OP_CAP_NEW` 1-arg with default energy_budget. Backward compat at the cost of opcode count + contradicting D1.10.3.2 doctrine ("metabolic accounting introduces non-vestigial caller input").

**TB recommendation: (a).** Honest canon evolution. The 1-arg version was correct for V1.0 strict delegation with no metabolic accounting; the 2-arg version is correct for the substrate at this pod. Decision record makes the reasoning explicit (D1.10.3.2). Surface implication: B5/B6 file-size byte-identity for Cap-involving regression tests breaks intentionally; non-Cap regressions (Outcome, error-path, canaries) hold.

## R9 — Test surface designs

**Five new tests:**

| T | Surface | Expected output |
|---|---------|----------------|
| T1 | test_cap_budget_basic.cbc | Construct cap with energy_budget=1000; OP_CAP_BUDGET returns 1000 |
| T2 | test_cap_used_zero_at_construction.cbc | Construct cap with energy_budget=500; OP_CAP_USED returns 0 |
| T3 | test_root_cap_unbounded.cbc | OP_CAP_BUDGET(ROOT_CAP_ID=1) returns 0xFFFFFFFFFFFFFFFF (MAX_U64) |
| T4 | test_cap_budget_invalid_id.cbc | OP_CAP_BUDGET(99) returns Err with err_code=1, source_op=184 |
| T5 | test_cap_budget_immutable_via_mac.cbc | Construct cap with budget=X; OP_CAP_BUDGET returns X (V1.0 structural confirmation; Pod 2 adds tamper detection) |

**Six rebuilt tests** (semantics preserved across two-arg amendment):

| Old surface | What changes | Rebuilt expectation |
|-------------|--------------|---------------------|
| test_cap_new_basic | bytecode +9 bytes | cap_id=2 (still) |
| test_cap_arena_owner_resource | bytecode +9 bytes | arena=0, owner=0, resource=42 (still) |
| test_cap_current | bytecode +9 bytes | ROOT(1)→A(2)→ROOT(1) walk (still) |
| test_cap_stack_overflow | bytecode +9 bytes | 257-deep ENTER overflow (still) |
| test_provenance_under_subcap | bytecode +9 bytes | creator=2, arena=0, owner=0 (still) |
| test_provenance_walk | bytecode +9 bytes | creator_of_S=2, parent_of_A=1, parent_of_ROOT=0 (still) |

**Unchanged** (no cap_new in their bytecode): test_cap_invalid_id, test_cap_stack_underflow.

**Regression analysis:**

- **B2/B3 canaries** — no Cap involvement; should hold (174j Sign / 53j Energy).
- **B5 Outcome regression** (6 tests from Pod 1.9.2b) — no Cap construction; should hold byte-identical to Pod 1.10.2b2 reference.
- **B6 error-path regression** (4 tests from Pod 1.9.3) — no Cap construction; should hold byte-identical to Pod 1.10.2b2 reference.
- **Cap-involving tests** (6 rebuilt) — bytecode shape changes, byte-identity breaks intentionally. New baseline established at Pod 1.10.3 seal.
- **B4 pristine boot** — load-bearing change is ROOT_CAP MAC over new 7-qword range. If ANY wiring of relayout is wrong (offset, qword count, missing field write), `verify_root_cap_mac` at boot hard-fails with FATAL diagnostic before MIND phase. Empirical validation of the slot relayout.

### Total: 19 B-items
B1 (determinism) + B2/B3 (canaries) + B4 (pristine boot — load-bearing for relayout) + B5/B6 (10 regression tests) + B7-B11 (5 new) + B12-B17 (6 Cap rebuilds) + B18 (provenance walk rebuild) + B19 (liveness probe).

## R10 — Build chain confirmation

```
NASM version 2.16.01
Build 1: 39ad88603422f68a41dec3e0430dedc0526fe92ba2e29f9fb40b6516aead0f25
Build 2: 39ad88603422f68a41dec3e0430dedc0526fe92ba2e29f9fb40b6516aead0f25
cmp -s:  BYTE-IDENTICAL
```

Entry contract verified at `39ad8860...`. Two-build determinism preserved.

## R11 — Recon report

This document at `recon/POD1.10.3_RECON_REPORT.md`.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Cap test compat strategy

Two strategies analyzed in R8. **TB recommendation: (a)** — break compat cleanly; rebuild 6 Cap-involving demos under two-arg shape; partial regression invisibility loss is structural reality of substrate evolution. Honest canon evolution per D1.10.3.2. The other 4 Cap-test demos (`cap_invalid_id`, `cap_stack_underflow`, `cap_parent_root`, `invalid_id_each_new_accessor`) don't construct caps — bytecode unaffected.

D1.10.3.7 records the baseline reset.

### A2 — ENERGY_BUDGET_UNBOUNDED named constant

TB recommendation: **named constant** (`%define ENERGY_BUDGET_UNBOUNDED 0xFFFFFFFFFFFFFFFF`). Forward-anchors the "unbounded" semantic for any future grant primitive (Demod budgets, Signal grants, Cop policy thresholds). Literal `0xFFFFFFFFFFFFFFFF` is identical bytes but loses the readability — when Pod 2 audit-reads the substrate, "ENERGY_BUDGET_UNBOUNDED" reads instantly; the literal requires decoding.

D1.10.3.3 records the choice.

### A3 — Two-arg OP_CAP_NEW stack pop order

Verified against existing CBS calling convention. Multi-arg opcode handlers pop top-of-stack first (last pushed), then next-to-top. Examples:
- `.op_outcome_new_err` (cbs_vm.asm:1193+) pops in this order: err_fetch_counter (top) → err_demod_id → err_source_op → err_code → value_type_id (bottom)
- `.op_sign_new` pops: provenance_handle (top, ignored) → embedding_handle → energy_cost → label_addr → hash_addr (bottom)

**TB recommendation: top-of-stack is `energy_budget` (last pushed); next is `resource_descriptor`.** Caller emits:
```
PUSH resource_descriptor
PUSH energy_budget
OP_CAP_NEW
```
Handler pops `energy_budget` first, then `resource_descriptor`. Convention matches all existing multi-arg handlers.

D1.10.3.2 records the convention.

---

## Section 3 — Risks identified

- **R3.1 — ROOT_CAP MAC layout shift load-bearing at boot.** B4 pristine boot is the empirical validation surface. If `construct_root_cap` writes energy_budget at +0x30 but the constant says +0x38, or if `verify_root_cap_mac` recomputes over 6 qwords while construct stamps over 7, boot hard-fails with FATAL. The boot-time E3 self-verification from Pod 1.10.2a is the safety net per D1.10.2a.5 doctrine. Same risk-class as Pod 1.10.2a's HALT 2B-DEFECT (wrong magic number caught at boot self-test).
- **R3.2 — Cap test bytecode shape shift partial regression invisibility loss.** Six Cap-involving regression tests rebuild under 2-arg shape. Byte-identity to Pod 1.10.2b2 reference intentionally breaks for those six. Non-Cap regressions (Outcome 6 + error-path 4 + Sign 174j + Energy 53j) hold. New baseline established at Pod 1.10.3 seal per D1.10.3.7.
- **R3.3 — Outcome four-path retrofit non-issue this pod.** Pod 1.10.2b2 D1.10.2b2.2 lands creator_cap_id at four Outcome construction sites; Pod 1.10.3 doesn't add any Outcome slot fields, so the four-path retrofit surface doesn't apply. (DEFERRED #66 forward-logs the consolidation refactor opportunity for a future pod.)
- **R3.4 — Reserved zone shrink.** Cap reserved zone goes from 9 qwords (0x38-0x7F) to 8 qwords (0x48-0x7F) — still ample for Pod 2+ Cap field additions (cap_bitmap, nonce, expiry, etc. per DEFERRED #64). Slot stays 128B; no pool size change.

---

## Section 4 — Phase 2 execution gates

S1: defines.asm — 2 opcode constants, 2 slot offset constants, ENERGY_BUDGET_UNBOUNDED, CAP_OFF_MAC shift 0x30→0x38, CAP_MAC_INPUT_QWORDS 6→7.
S2: cap.asm — `construct_root_cap` writes energy_budget=ENERGY_BUDGET_UNBOUNDED + energy_used=0; `verify_root_cap_mac` parallel via constant. `siphash_compute_cap_mac` wrapper picks up rsi=7 via constant.
S3: cbs_vm.asm — `.op_cap_new` amended to pop 2 args + write 2 new fields. Two new handlers `.op_cap_budget` / `.op_cap_used` (5-line stubs each calling `.cap_accessor_common`). Two new dispatch entries.
S4: energy_costs.asm — 2 new cost-table entries at 0xB8/0xB9 (both 1j metabolic).
S5: atreyu_x86.py — 2 new opcode constants, 2 new AST handlers (cap_budget, cap_used), 1 amended AST handler (cap_new emits 2 pushes), 5 new demos, 10 new CLI flags. Existing 6 cap_new-using demos inherit the amendment via the AST emitter; no per-demo source change.
S6: surfaces — 5 new test surfaces compiled + 6 cap_new-using surfaces rebuilt under new shape.

Phase 2B B1 reads BOOTX64.EFI; B2/B3 verify canaries hold; B4 pristine boot (load-bearing for relayout); B5/B6 non-Cap regression invisibility holds; B7-B11 five new tests; B12-B17 six rebuilt Cap tests; B18 provenance walk rebuild verifies semantics preserved; B19 liveness probe. **19 B-items total.**

---

## Section 5 — Surprises

- **S5.1 — `siphash_compute_cap_mac` wrapper already symbolic.** Pod 1.10.2a's Pre-A1 ratification (parameterized signature `siphash_compute(rdi, rsi)` with `siphash_compute_cap_mac` as thin wrapper using `mov rsi, CAP_MAC_INPUT_QWORDS`) means updating `CAP_MAC_INPUT_QWORDS = 6 → 7` in defines.asm propagates through the wrapper and all five call sites with zero source-line changes. Pod 1.10.2a's parameterization decision paying dividends two pods later.
- **S5.2 — Two cap test surfaces have NO bytecode change.** `test_cap_invalid_id` and `test_cap_stack_underflow` don't construct caps (use raw-id helpers and direct `OP_CAP_EXIT` respectively). Their bytecode is unaffected by the OP_CAP_NEW amendment; byte-identity to Pod 1.10.2b2 reference holds. Surface-level audit recommended at HALT 2B to confirm — they're naturally part of the regression-invisibility set, not the rebuild set.
- **S5.3 — D1.10.2b1.5 helper polymorphism paying off again.** Third and fourth consumers of `.cap_accessor_common` (after ARENA/OWNER/RESOURCE in 1.10.2b1, PARENT in 1.10.2b2) — OP_CAP_BUDGET and OP_CAP_USED. Five-line dispatch stubs per opcode, zero new helper code. Same architectural-reuse pattern as D1.10.2b2.6. The factoring decision keeps earning structural credit at zero cost per consumer.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 3 architect calls (A1 Cap test compat strategy → break clean, A2 ENERGY_BUDGET_UNBOUNDED named constant, A3 two-arg pop order top-first).
- 4 risks surfaced (R3.1 ROOT_CAP MAC at boot is load-bearing; others non-blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED-1.**

— Terminal Boy
May 04 2026
