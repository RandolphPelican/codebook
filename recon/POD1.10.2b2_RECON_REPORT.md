# Pod 1.10.2b2 Recon Report — Witness Substrate-Wide + Provenance Anchoring

**Pod:** 1.10.2b2 — closes Section 2 of Pod 1.10; seals Pod 1.10
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** 78b313ce8de2496235654e6ddfbc278321f818793404d1fbc1ba0e181f6f6e3e (Pod 1.10.2b1 BOOTX64.EFI)
**Entry HEAD:** 0b707f5ab1d7a1e1d868ddd4e5be101f6e8ce42c (Pod 1.10.2b1 seal)
**Scope:** boot/defines.asm, boot/cbs_vm.asm, boot/energy_costs.asm, tools/atreyu_x86.py, surfaces/test_*_provenance*.cbc + 4 more (7 NEW), canon files.

This pod implements three connected moves: (1) creator_cap_id field on Sign/Energy/Outcome slots, (2) three-allocator retrofit per D1.10.1.8, (3) ten new accessor opcodes (Sign/Energy/Outcome × {ARENA, OWNER, CREATOR} + OP_CAP_PARENT) enabling provenance walks from any forged cell back to ROOT. The architectural moment is B11 — the substrate narrating its own lineage.

---

## R1 — Pre-flight three-oracle

```
HEAD               : 0b707f5ab1d7a1e1d868ddd4e5be101f6e8ce42c
origin/main        : 0b707f5ab1d7a1e1d868ddd4e5be101f6e8ce42c
ls-remote refs/heads/main : 0b707f5ab1d7a1e1d868ddd4e5be101f6e8ce42c
```

All three agree at Pod 1.10.2b1 seal. Build artifacts (DEFERRED #10) modified; six throwaway scripts (#59 + #62) untracked. Both expected.

## R2 — Slot layout audit + creator_cap_id placement plan

All three slot types are 128B (filled by current usage). Placement requires either reclamation of an existing-but-unused field or slot expansion. **TB recommendation: reclamation; no slot expansion needed.** Rationale: each type has either a Pod 3+ reserved zone or a Pod 1.8.5c-style "declared-but-V1.0-unused" field that can be reclaimed under the same supersession discipline.

### Sign slot (boot/cbs_vm.asm:801-816, 128B)

```
+0x00 hash[32]
+0x20 label[64]
+0x60 energy_cost (u64)
+0x68 embedding_handle (u64)   ← V1.0=0; reserved for Pod 3+ handle pools
+0x70 arena_id (u64)            ← Pod 1.8.5c Move 3
+0x78 owner_demod_id (u64)      ← Pod 1.8.5c Move 3
```

**Plan: SIGN_OFF_CREATOR_CAP_ID = 0x68** (reclaim embedding_handle slot — same Pod 1.8.5c pattern that reclaimed provenance_handle→arena_id and V1.1 sentinel→owner_demod_id). OP_SIGN_NEW preserves 5-arg ABI: still pops embedding_handle, validates =0, silently discards. Pod 3+ handle pools when they land allocate slots elsewhere. Slot stays 128B.

### Energy slot (boot/cbs_vm.asm:985-991, 128B)

```
+0x00 joules (u64)
+0x08 source_op (u64)
+0x10 arena_id (u64)
+0x18 owner_demod_id (u64)
+0x20-0x7F reserved (96 bytes)
```

**Plan: ENERGY_OFF_CREATOR_CAP_ID = 0x20** (immediately after owner_demod_id; first qword of former reserved zone). Reserved zone shrinks from 96B (12 qwords) to 88B (11 qwords). Slot stays 128B.

### Outcome slot (boot/cbs_vm.asm:1108 area, 128B)

```
+0x00 discriminant (u64)
+0x08 value_type_id
+0x10 value
+0x18 reserved
+0x20 err_code
+0x28 err_source_op
+0x30 err_demod_id
+0x38 err_fetch_counter
+0x40-0x68 Pod 3+ reserved (5 qwords)
+0x70 arena_id
+0x78 owner_demod_id
```

**Plan: OUTCOME_OFF_CREATOR_CAP_ID = 0x68** (immediately before arena_id; last qword of Pod 3+ reserved zone). Reserved zone shrinks from 5 qwords to 4 qwords. Slot stays 128B.

### Pool size implications: none

All three types stay at 64 slots × 128B = 8KB pool each. No vmdata.asm pool size changes.

## R3 — Opcode allocation audit

| Range | Block | Currently used | Free slots needed |
|-------|-------|----------------|-------------------|
| 0xA0–0xAF | Sign (Pod 1.7) | 0xA0–0xA3 | 3 |
| 0xB0–0xBF | Cap (Pod 1.10.2a-b1) | 0xB0–0xB6 | 1 |
| 0xD0–0xDF | Energy (Pod 1.8) | 0xD0–0xD5 | 3 |
| 0xE0–0xEF | Outcome (Pod 1.9.2b) | 0xE0–0xE4 | 3 |

**Proposed allocation (10 new opcodes):**

| Opcode | Value | Decimal (for source_op) |
|--------|-------|-------|
| OP_SIGN_ARENA | 0xA4 | 164 |
| OP_SIGN_OWNER | 0xA5 | 165 |
| OP_SIGN_CREATOR | 0xA6 | 166 |
| OP_CAP_PARENT | 0xB7 | 183 |
| OP_ENERGY_ARENA | 0xD6 | 214 |
| OP_ENERGY_OWNER | 0xD7 | 215 |
| OP_ENERGY_CREATOR | 0xD8 | 216 |
| OP_OUTCOME_ARENA | 0xE5 | 229 |
| OP_OUTCOME_OWNER | 0xE6 | 230 |
| OP_OUTCOME_CREATOR | 0xE7 | 231 |

No conflicts. Each block has remaining reserved range after these additions.

## R4 — Cost classification A-call (A1)

Per D1.9.2b.1 / D1.10.2a.7 work-matches-cost doctrine:
- Sign/Energy/Outcome accessors: registry lookup + slot field read. **No MAC verify** (these primitives don't carry SipHash MACs). Substrate bookkeeping. → **0j structural**.
- OP_CAP_PARENT: registry lookup + **MAC verify** + slot field read. Real cryptographic work consistent with Pod 1.10.2b1 Cap accessor cost. → **1j metabolic**.

**TB recommendation: 0j × 9 for non-MAC accessors, 1j × 1 for OP_CAP_PARENT.**

The asymmetry is honest about the asymmetric work. Cost-symmetry argument (all accessors at 1j) would override D1.9.2b.1 doctrine; that's the architect's call to ratify or override at HALT 1.

## R5 — defines.asm constants additions plan

```nasm
; --- Pod 1.10.2b2 substrate-wide accessor opcodes (D1.10.2b2.4) ---
%define OP_SIGN_ARENA        0xA4
%define OP_SIGN_OWNER        0xA5
%define OP_SIGN_CREATOR      0xA6
%define OP_CAP_PARENT        0xB7
%define OP_ENERGY_ARENA      0xD6
%define OP_ENERGY_OWNER      0xD7
%define OP_ENERGY_CREATOR    0xD8
%define OP_OUTCOME_ARENA     0xE5
%define OP_OUTCOME_OWNER     0xE6
%define OP_OUTCOME_CREATOR   0xE7

; --- Pod 1.10.2b2 creator_cap_id slot offsets (D1.10.2b2.1) ---
%define SIGN_OFF_CREATOR_CAP_ID    0x68    ; reclaimed from embedding_handle (Pod 1.8.5c reclamation pattern)
%define ENERGY_OFF_CREATOR_CAP_ID  0x20    ; first qword of former reserved zone
%define OUTCOME_OFF_CREATOR_CAP_ID 0x68    ; last qword of former Pod 3+ reserved zone
```

Per D1.9.2b.10 cross-asset-constants doctrine, all 13 constants land at this pod entry. **No** SIGN_OFF_ARENA_ID / ENERGY_OFF_ARENA_ID / OUTCOME_OFF_ARENA_ID constants added — the existing slot-write code uses hardcoded literals (0x70 for Sign/Outcome, 0x10 for Energy); minimal-disturbance retrofit reuses the same hardcoded literals in the new accessor handlers. Adding *_OFF_ARENA_ID constants would be a cleanliness refactor with broader scope; defer.

## R6 — Six retrofit sites (architect's "three-allocator retrofit" expanded)

The architect's instruction-doc says "three-allocator retrofit"; in tree there are **six** internal sites that construct primitive slots with arena/owner fields that need to be retrofit + the new creator_cap_id field added:

| # | Site | Type | Arena/Owner offsets | Retrofit shape |
|---|------|------|---------------------|----------------|
| 1 | `.op_sign_new` (cbs_vm.asm:818-873) | Sign | +0x70/+0x78 | Replace 3 hardcoded zeros (lines 862-864) with substrate state reads |
| 2 | `.op_energy_new` (cbs_vm.asm:993-) | Energy | +0x10/+0x18 | Replace 2 zeros (lines 1007-1008) + add creator at +0x20 (formerly part of zero'd reserved zone) |
| 3 | `.op_outcome_new_ok` (cbs_vm.asm:1121-) | Outcome (NEW_OK) | +0x70/+0x78 | Keep `rep stosq 12 qwords at +0x20` zeroing; add 3 writes after for arena/owner/creator |
| 4 | `.op_outcome_new_err` (cbs_vm.asm:1160-) | Outcome (NEW_ERR) | +0x70/+0x78 | Same shape as #3 |
| 5 | `.construct_ok_outcome` helper (cbs_vm.asm:1308-) | Outcome (accessor success path) | +0x70/+0x78 | Same shape as #3 |
| 6 | `.construct_err_outcome` helper (cbs_vm.asm:1352-) | Outcome (accessor failure path) | +0x70/+0x78 | Replace 3 explicit zeros (lines 1383-1385) with substrate state reads (also write creator at +0x68) |

Outcome's four sites all need retrofit because Outcomes are constructed both from program-driven NEW_OK/NEW_ERR opcodes AND from accessor success/failure helpers.

**Pattern for sites #1, #2, #6 (zero-write replacement):**

```nasm
; OLD:
mov     qword [slot + ARENA_OFF], 0
mov     qword [slot + OWNER_OFF], 0
; (creator: not previously written — new field)

; NEW:
mov     rax, [rel current_cap_arena_id_cache]
mov     [slot + ARENA_OFF], rax
mov     rax, [rel current_cap_owner_demod_id_cache]
mov     [slot + OWNER_OFF], rax
mov     rax, [rel current_cap_id]
mov     [slot + CREATOR_OFF], rax
```

**Pattern for sites #3, #4, #5 (rep stosq plus overwrite):**

```nasm
; OLD: (already does rep stosq covering arena/owner)
lea     rdi, [rbx + 0x20]
xor     eax, eax
mov     rcx, 12
rep     stosq

; NEW: (keep rep stosq; overwrite three retrofit fields after)
lea     rdi, [rbx + 0x20]
xor     eax, eax
mov     rcx, 12
rep     stosq
mov     rax, [rel current_cap_arena_id_cache]
mov     [rbx + 0x70], rax
mov     rax, [rel current_cap_owner_demod_id_cache]
mov     [rbx + 0x78], rax
mov     rax, [rel current_cap_id]
mov     [rbx + 0x68], rax
```

The rep-stosq-plus-overwrite is slightly inefficient (3 stosq writes get overwritten) but minimal-disturbance; alternative is shrinking stosq count and writing each non-retrofit reserved field individually, which adds complexity without speedup at allocator-rare frequency.

## R7 — Nine accessor handler design + factoring (A2)

All nine handlers share shape: pop typed_id, registry lookup, read field at offset, wrap in Outcome::Ok per Path A. No MAC verify. Failure → ERR_INVALID_ID.

**A2 surface — factor or explicit?** Three options considered:

| Option | Lines | Notes |
|--------|-------|-------|
| (a) Single `.typed_accessor_common` with fn-ptr + type-code params | ~115 | Clever; fn-ptr indirection feels polymorphic |
| (b) Three per-type helpers (.sign_accessor_common etc.) | ~120 | Mirrors 1.10.2b1's per-type `.cap_accessor_common` shape |
| (c) Nine explicit handlers | ~180 | Verbose; symmetric |

**TB recommendation: (b) three per-type helpers.** Mirrors Pod 1.10.2b1 `.cap_accessor_common` pattern; type code hardcoded per helper, not parameterized; no fn-pointer indirection (each helper calls the right `registry_lookup_*` directly); total handler+helper lines competitive with option (a) but more honest about per-type structure.

Option (b) shape (sign accessor common shown; energy/outcome parallel):

```nasm
; Input:  rdi = sign_id, rcx = field offset, rsi = source_op
; Output: rax = outcome_id (Ok wrapping field value, or Err)
.sign_accessor_common:
    push    rsi
    push    rcx
    test    rdi, rdi
    jz      .sign_accessor_invalid
    call    registry_lookup_sign       ; rax = slot_ptr
    test    rax, rax
    jz      .sign_accessor_invalid
    pop     rcx                         ; restore offset
    pop     rsi                         ; (unused on success)
    mov     rdi, [rax + rcx]            ; field value
    mov     r8, TYPE_CODE_SIGN
    call    .construct_ok_outcome
    ret
.sign_accessor_invalid:
    pop     rcx
    pop     rsi
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    ret
```

Per-type handler stubs (5 lines each):

```nasm
.op_sign_arena:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, 0x70                   ; SIGN arena_id offset
    mov     rsi, OP_SIGN_ARENA
    call    .sign_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

OWNER and CREATOR handlers same shape with offset/source_op variations. Energy handlers parallel (offsets 0x10/0x18/0x20, source_op variations). Outcome handlers parallel (offsets 0x70/0x78/0x68, source_op variations).

## R8 — OP_CAP_PARENT handler design

Same shape as Pod 1.10.2b1's `.cap_accessor_common` (which already does MAC verify). Pop cap_id, registry lookup, MAC verify, read CAP_OFF_PARENT_CAP_ID, wrap in Outcome::Ok. Cost 1j metabolic.

**Implementation: single handler stub that calls Pod 1.10.2b1's existing `.cap_accessor_common` with `rcx = CAP_OFF_PARENT_CAP_ID = 0x20` and `rsi = OP_CAP_PARENT`.** Zero new helper code — the Pod 1.10.2b1 helper already supports this opcode by parameter swap.

```nasm
.op_cap_parent:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, CAP_OFF_PARENT_CAP_ID  ; 0x20
    mov     rsi, OP_CAP_PARENT
    call    .cap_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

This is a clean reuse of existing infrastructure.

## R9 — Test surface designs + R3.2 risk analysis

Seven tests:

| T | Surface | Expected output |
|---|---------|----------------|
| T1 | test_sign_provenance_root.cbc | arena=0, owner=0, creator=1 (ROOT) |
| T2 | test_energy_provenance_root.cbc | arena=0, owner=0, creator=1 |
| T3 | test_outcome_provenance_root.cbc | arena=0, owner=0, creator=1 (verifies retrofit propagates through Outcome construction helpers) |
| T4 | test_provenance_under_subcap.cbc | Forge cap A under ROOT, ENTER A, forge Sign S, EXIT, verify arena=0/owner=0/creator=A's_id (=2) |
| T5 | test_provenance_walk.cbc | The architectural moment. Forge cap A, ENTER A, forge Sign S, EXIT. Walk: SIGN_CREATOR(S)=2, CAP_PARENT(2)=1, CAP_PARENT(1)=0 |
| T6 | test_cap_parent_root.cbc | OP_CAP_PARENT(1)=0 (ROOT's parent is 0 by construction) |
| T7 | test_invalid_id_each_new_accessor.cbc | OP_SIGN_ARENA(99)/OP_ENERGY_OWNER(99)/OP_OUTCOME_CREATOR(99)/OP_CAP_PARENT(99) each return Err with err_code=1, source_op=respective opcode |

### R3.2 risk: B5/B6 byte-identity may shift

**Slot SIZE unchanged** (all three types stay 128B per R2). PNG file size is determined by framebuffer pixel content, not by EFI binary size or slot pool size. Therefore B5/B6 file-size invisibility depends on whether the *printed output* of regression tests changes.

Pod 1.9.2b Outcome regression tests print: outcome_id, is_ok value, value, discriminant fields (err_code, err_source_op, err_demod_id, err_fetch_counter), and "test complete" labels. **None of these reads creator_cap_id.** ✓

Pod 1.9.3 error-path regression tests print: is_ok, the 4 unwrap_err fields (err_code, err_source_op, err_demod_id, err_fetch_counter), labels. **None reads creator_cap_id.** ✓

Energy used will be unchanged because:
- Cost table for Sign/Energy/Outcome NEW unchanged (allocator-side bookkeeping is 0j per substrate-bookkeeping doctrine)
- Pod 1.9.2b/1.9.3 tests don't exercise the new accessor opcodes

Therefore B5/B6 byte-identity SHOULD hold. Empirically verify at HALT 2B; if unexpected shift, R3.2 surfaces as PAUSED-MID-EXECUTION.

### Total: 14 B-items

B1 determinism + B2/B3 canaries + B4 pristine boot + B5 (6 Outcome) + B6 (4 error-path) + B7-B13 (7 new tests) + B14 liveness probe.

## R10 — Build chain confirmation

```
NASM version 2.16.01
mcopy (GNU mtools) 4.0.43
QEMU emulator version 8.2.2

Build 1: 78b313ce8de2496235654e6ddfbc278321f818793404d1fbc1ba0e181f6f6e3e
Build 2: 78b313ce8de2496235654e6ddfbc278321f818793404d1fbc1ba0e181f6f6e3e
cmp -s:  BYTE-IDENTICAL
```

Entry contract verified at `78b313ce...`. Two-build determinism preserved.

## R11 — Recon report

This document at `recon/POD1.10.2b2_RECON_REPORT.md`.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Cost classification for new accessors

Surfaced per architect's R4 prompt. Two readings:
- (a) **0j × 9 + 1j × 1** — cost matches work; non-MAC accessors are substrate bookkeeping; OP_CAP_PARENT does real SipHash work.
- (b) **1j × 10** — interface symmetry; all accessors cost 1j regardless of internal mechanism.

**TB recommendation: (a).** D1.9.2b.1 and D1.10.2a.7 explicitly say cost matches work. Cap's 1j is paid for SipHash MAC verify, not for the accessor interface. Asymmetric cost is honest about asymmetric work — matches architect's own reasoning at Pod 1.10.2b1 A1 (ENTER's 1j charged because MAC verify is real; EXIT's 0j because no MAC verify).

D1.10.2b2.5 records the classification.

### A2 — Helper factoring shape

Surfaced per architect's R7 prompt. Three options considered (R7 above). **TB recommendation: (b) three per-type helpers** mirroring Pod 1.10.2b1 `.cap_accessor_common` pattern. Each helper is small, type-specific, no fn-pointer indirection. Total ~120 lines vs ~180 for explicit option (c). Reads as a parallel-structure family.

D1.10.2b2.4 records the per-type pattern preservation (preserving Pre-A3 ratification at the implementation level).

---

## Section 3 — Risks identified

- **R3.1 — Sign embedding_handle slot reclamation.** OP_SIGN_NEW preserves 5-arg ABI (still pops embedding_handle, validates =0). Slot field at +0x68 reclaimed for creator_cap_id under same Pod 1.8.5c discipline that reclaimed provenance_handle and V1.1 sentinel. When Pod 3+ handle pools land, embedding_handle will need a new slot allocation strategy — that's a Pod 3+ concern, forward-logged here.
- **R3.2 — B5/B6 byte-identity under retrofit.** Analyzed in R9 above. Slot sizes unchanged; regression tests don't print creator_cap_id; expected to hold. Empirically verify at HALT 2B.
- **R3.3 — Energy slot creator_cap_id placement.** ENERGY_OFF_CREATOR_CAP_ID = 0x20 places creator_cap_id immediately after owner_demod_id (+0x18). Energy accessors at this offset don't conflict with existing JOULES (+0x00) / SOURCE_OP (+0x08) / arena_id (+0x10) / owner_demod_id (+0x18) reads. Adjacency is honest but breaks the "Move 3 fields all live at +0x70/+0x78" pattern other types follow. Acceptable — Energy slot was structured differently from Sign/Outcome at Pod 1.8 (arena/owner placed early to leave 96B reserved at end); creator_cap_id following arena/owner adjacency fits Energy's own pattern.
- **R3.4 — Outcome four-site retrofit.** Architect's "three-allocator retrofit" understates Outcome's complexity. Six total sites need retrofit (Sign×1, Energy×1, Outcome×4). All four Outcome sites must propagate identically; mechanical work but invariant under audit at HALT 2A.

---

## Section 4 — Phase 2 execution gates

S1: defines.asm — 10 opcode constants + 3 slot offset constants per R5.
S2: vmdata.asm — no changes (slots stay 128B; pool sizes unchanged).
S3: cbs_vm.asm — six retrofit sites per R6. Mechanical replacement of zero-writes / addition of three-field retrofit after rep stosq.
S4: cbs_vm.asm — ten new opcode handlers per R7/R8. Three per-type helpers (.sign_accessor_common, .energy_accessor_common, .outcome_accessor_common) plus one Cap helper reuse via existing `.cap_accessor_common`. Ten 5-line handler stubs.
S5: cbs_vm.asm — ten dispatch entries between Pod 1.10.2b1's seventh Cap dispatch entry and "Unknown opcode" fallback.
S6: energy_costs.asm — 10 cost table entries (9 × 0j + 1 × 1j per A1).
S7: atreyu_x86.py — 10 opcode constants, 10 AST handlers (3 per type for Sign/Energy/Outcome accessors + 1 cap_parent + 4 raw test primitives), 7 demos, 14 CLI flags.
S8: surfaces/ — 7 new test surfaces compiled.

Phase 2B B1 reads BOOTX64.EFI; B2/B3 verify 174j/53j canaries hold; B4 pristine boot; B5/B6 file-size invisibility; B7-B13 seven new tests; B14 liveness probe. **14 B-items total.**

---

## Section 5 — Surprises

- **S5.1 — Outcome retrofit lands in four sites, not one.** The architect's "three-allocator retrofit" was Sign/Energy/Outcome conceptually; Outcome alone has four internal slot-construction sites (NEW_OK, NEW_ERR, .construct_ok_outcome helper, .construct_err_outcome helper). All four must propagate the retrofit identically. Documented as R3.4.
- **S5.2 — OP_CAP_PARENT requires zero new helper code.** Pod 1.10.2b1's `.cap_accessor_common` is already shape-correct for any Cap field offset. OP_CAP_PARENT becomes a 5-line handler stub calling the existing helper with offset=0x20. Pod 1.10.2b1's helper factoring was prescient about future Cap accessor additions even though only ARENA/OWNER/RESOURCE were planned at the time.
- **S5.3 — The architectural moment lands at one program.** B11 / T5 — three accessor calls trace from forged cell to anchor. Three opcodes. Three substrate state reads. The provenance walk feels small in implementation terms but architecturally is the inverse of the bouncer: not "did this cap match?" but "where does this cap come from?" The substrate's narrative voice activates with three accessors.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 2 architect calls (A1 cost classification 0j/1j, A2 helper factoring three per-type vs other shapes).
- 4 risks surfaced (none blocking; R3.2 is the watching point at HALT 2B).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED-1.**

— Terminal Boy
May 04 2026
