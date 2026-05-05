# Pod 1.10.2b1 Recon Report — Cap operations + Cap accessors

**Pod:** 1.10.2b1 — first half of Section 2 part B of Pod 1.10
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 04 2026
**Entry contract:** a7e610c44651b5e5edd9a903792d4fec6b923a2b92a345ee0aa5cb4111293a81 (Pod 1.10.2a BOOTX64.EFI)
**Entry HEAD:** f642ca0473219938e0ce5a413e18512268aea660 (Pod 1.10.2a seal)
**Scope:** boot/defines.asm, boot/cbs_vm.asm, boot/energy_costs.asm, tools/atreyu_x86.py, surfaces/test_cap_*.cbc (6 NEW), canon files.

This pod implements the canon supersession of D1.10.1.3/D1.10.1.11: OP_CAP_CHECK retired, three Cap accessors (ARENA, OWNER, RESOURCE) ship instead. Bouncer-to-fingerprint reframe per architect pre-recon ratification (Pre-A1/A2/A3).

---

## R1 — Pre-flight three-oracle

```
HEAD               : f642ca0473219938e0ce5a413e18512268aea660
origin/main        : f642ca0473219938e0ce5a413e18512268aea660
ls-remote refs/heads/main : f642ca0473219938e0ce5a413e18512268aea660
```

All three agree at Pod 1.10.2a seal. Build artifacts (DEFERRED #10) modified; three throwaway scripts from 1.10.2a (DEFERRED #59) untracked. Both expected.

## R2 — Cap opcode allocation re-audit

Pod 1.10.2a defines.asm currently allocates 0xB0-0xB4 with OP_CAP_CHECK at 0xB4. Per Pre-A1 supersession, OP_CAP_CHECK retires; 0xB4-0xB6 carry the three accessors.

| Opcode | Value | Cost | Rationale |
|--------|-------|------|-----------|
| OP_CAP_NEW | 0xB0 | 1j metabolic | Construction work; SipHash MAC computation |
| OP_CAP_ENTER | 0xB1 | 1j metabolic | **MAC verify required for forgery prevention** (see A1) |
| OP_CAP_EXIT | 0xB2 | 0j structural | cap_stack pop + cache restore; restored cap_id was MAC-verified at its prior ENTER |
| OP_CAP_CURRENT | 0xB3 | 0j structural | Pure substrate state read (parallel to OP_PHASE_QUERY) |
| OP_CAP_ARENA | 0xB4 | 1j metabolic | Lookup + MAC verify + slot field read |
| OP_CAP_OWNER | 0xB5 | 1j metabolic | Same |
| OP_CAP_RESOURCE | 0xB6 | 1j metabolic | Same |
| 0xB7-0xBF | reserved | 1j default | Available for future Cap extensions |

No conflicts in 0xB0-0xB6 range. 0xB7-0xBF row default-1j stays per cost-table convention.

## R3 — Dispatch chain insertion-site audit

Current dispatch chain tail (boot/cbs_vm.asm):

```
152:    cmp     al, OP_OUTCOME_NEW_OK
153:    je      .op_outcome_new_ok
154:    cmp     al, OP_OUTCOME_NEW_ERR
155:    je      .op_outcome_new_err
156:    cmp     al, OP_OUTCOME_IS_OK
157:    je      .op_outcome_is_ok
158:    cmp     al, OP_OUTCOME_UNWRAP_OK
159:    je      .op_outcome_unwrap_ok
160:    cmp     al, OP_OUTCOME_UNWRAP_ERR
161:    je      .op_outcome_unwrap_err
162:
163:    ; Unknown opcode
```

**Insertion site: line 162** (between OP_OUTCOME_UNWRAP_ERR dispatch and Unknown opcode fallback). Chain order follows pod-addition order, parallel to Pod 1.9.2b's 0xE-block pattern.

Seven entries to insert (cmp + je pairs). NASM auto-promotes branch distances; no manual handling needed.

## R4 — Cost table site audit + planned replacement

Current 0xB-block in boot/energy_costs.asm:

```
112:; Row 0xB0–0xBF
113:    times 16 dq 1           ; 0xB0–0xBF — unallocated (Outcome 0xB0–0xBF Pod 1.9)
```

Stale comment ("Outcome 0xB0–0xBF Pod 1.9") carryover identified at Pod 1.10.1 R2 — Pod 1.10.2b1 corrects it. Replacement:

```nasm
; Row 0xB0–0xBF — Cap opcodes (Pod 1.10.2b1 at 0xB0-0xB6)
    dq 1                    ; 0xB0 — OP_CAP_NEW (metabolic construction)
    dq 1                    ; 0xB1 — OP_CAP_ENTER (metabolic; MAC verify required per A1)
    dq 0                    ; 0xB2 — OP_CAP_EXIT (structural; cap_stack pop + cache restore)
    dq 0                    ; 0xB3 — OP_CAP_CURRENT (structural; substrate state read)
    dq 1                    ; 0xB4 — OP_CAP_ARENA (metabolic; lookup + MAC verify + slot read)
    dq 1                    ; 0xB5 — OP_CAP_OWNER (metabolic; lookup + MAC verify + slot read)
    dq 1                    ; 0xB6 — OP_CAP_RESOURCE (metabolic; lookup + MAC verify + slot read)
    dq 1, 1, 1, 1, 1        ; 0xB7–0xBB — reserved
    dq 1, 1, 1, 1           ; 0xBC–0xBF — reserved
```

**Note:** Replacement deviates from architect's R4 specification at 0xB1 — architect specified `dq 0` (structural cap_stack push) but R7 outline includes MAC verify; cost classification must match the work done. See A1 below.

Partial closure of DEFERRED #37 (RECONSTITUTION pod-arc reconciliation) — energy_costs.asm side now accurate.

## R5 — defines.asm constants adjustment

Current Cap section (boot/defines.asm:124-152):

```nasm
%define ERR_CAP_AUTHORITY_EXCEEDED   7   ; Pod 1.10.2a; D1.10.1.9
...
%define OP_CAP_NEW       0xB0
%define OP_CAP_ENTER     0xB1
%define OP_CAP_EXIT      0xB2
%define OP_CAP_CURRENT   0xB3
%define OP_CAP_CHECK     0xB4              ← REMOVE per Pre-A1
...
%define CAP_POOL_SLOTS   64
%define CAP_SLOT_SIZE    0x80
%define ROOT_CAP_ID      1
%define CAP_STACK_DEPTH  256
%define CAP_OFF_*        (8 offset constants — keep)
%define CAP_MAC_INPUT_QWORDS 6
```

Adjustment plan:
- **Remove** `%define OP_CAP_CHECK     0xB4`
- **Add** three accessor opcode constants:
  ```nasm
  %define OP_CAP_ARENA     0xB4   ; Pod 1.10.2b1 — pop cap_id, MAC verify, push Outcome<arena_id>
  %define OP_CAP_OWNER     0xB5   ; Pod 1.10.2b1 — pop cap_id, MAC verify, push Outcome<owner_demod_id>
  %define OP_CAP_RESOURCE  0xB6   ; Pod 1.10.2b1 — pop cap_id, MAC verify, push Outcome<resource_descriptor>
  ```

ERR_CAP_AUTHORITY_EXCEEDED (=7) stays defined-but-unused per Pre-A2 — activates at sub-arena delegation pod (Pod 2 or beyond). Comment updated: "OP_CAP_NEW arena/owner exceeds parent cap's authority (Pod 1.10.2a; D1.10.1.9; defined-but-unused V1.0 per D1.10.2b1.2)".

TYPE_CODE_CAP=3 already exists at defines.asm:216 (no change).

## R6 — OP_CAP_NEW handler design

Per Pre-A2: pops only resource_descriptor. Strict delegation: arena_id and owner_demod_id inherited from current_cap; parent_cap_id = current_cap_id; generation_counter = 0.

**Architect's R6 outline has a register-convention bug** that I'll surface and correct: outline uses `mov rsi, TYPE_CODE_CAP; call .construct_ok_outcome` but the actual helper signature (cbs_vm.asm:1303-1307) is `rdi=value, r8=value_type_id`. Pod 1.9.3 call sites verified — all use `mov r8, TYPE_CODE_*`.

Corrected handler outline:

```nasm
.op_cap_new:
    ; Pop resource_descriptor from operand stack
    sub     r13, 8
    mov     r10, [r13]                   ; resource_descriptor

    ; Pool capacity check
    mov     rcx, [rel vm_cap_next]
    cmp     rcx, CAP_POOL_SLOTS
    jge     .op_cap_new_pool_full

    ; Compute slot pointer for next allocation
    lea     rbx, [rel vm_cap_pool]
    mov     rax, rcx
    shl     rax, 7                       ; * 128 (CAP_SLOT_SIZE)
    add     rbx, rax

    ; Write Cap slot fields (cap_id_self placeholder until registry returns id)
    mov     qword [rbx + CAP_OFF_CAP_ID_SELF], 0
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + CAP_OFF_ARENA_ID], rax
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + CAP_OFF_OWNER_DEMOD_ID], rax
    mov     [rbx + CAP_OFF_RESOURCE_DESC], r10
    mov     rax, [rel current_cap_id]
    mov     [rbx + CAP_OFF_PARENT_CAP_ID], rax
    mov     qword [rbx + CAP_OFF_GENERATION_COUNTER], 0

    ; Register slot to get cap_id
    mov     rdi, rbx
    call    registry_register_cap        ; rax = assigned cap_id
    test    rax, rax
    jz      .op_cap_new_pool_full        ; registry-full collapses with pool-full per matched capacity

    ; Write correct cap_id_self (now that we know the assigned id)
    mov     [rbx + CAP_OFF_CAP_ID_SELF], rax

    ; Increment vm_cap_next (slot consumed)
    inc     qword [rel vm_cap_next]

    ; Compute MAC over 6 input fields (cap_id_self through generation_counter)
    push    rax                          ; preserve assigned cap_id
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute              ; preserves r12-r15, rbx, rbp, rdi
    pop     rcx                          ; cap_id back in rcx
    mov     [rbx + CAP_OFF_MAC], rax     ; store MAC

    ; Wrap cap_id in Outcome::Ok
    mov     rdi, rcx                     ; value = cap_id
    mov     r8, TYPE_CODE_CAP            ; value_type_id (correct register per helper sig)
    call    .construct_ok_outcome
    mov     [r13], rax                   ; push outcome_id
    add     r13, 8
    jmp     .fetch

.op_cap_new_pool_full:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_CAP_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

Sequencing concerns addressed:
- Slot write order: write fields with cap_id_self=0, register to get id, write cap_id_self=id, then compute MAC. MAC covers correct cap_id_self.
- registry_register_cap preserves r12-r15, rbx, rbp, rdi (per cap.asm signature).
- siphash_compute preserves r12-r15, rbx, rbp, rdi (per cap.asm signature).
- vm_cap_next increment after registry success — failure paths leave the slot uninstalled.

Pool-full and registry-full collapse to ERR_POOL_FULL per matched capacities (CAP_POOL_SLOTS=64 = registry capacity).

## R7 — OP_CAP_ENTER + OP_CAP_EXIT handler design

Stack-effect-on-failure: surface as **A2** below. My recommendation: option (b) — every fallible operation returns Outcome per Path A consistency.

ENTER MUST MAC-verify for forgery detection. A forged cap_id might collide with a registry entry but the MAC won't match — that's the cryptographic property. EXIT does NOT need MAC re-verification — the restored cap_id was MAC-verified at its prior ENTER.

ENTER outline (option (b) — Outcome<()> return, stack net 0):

```nasm
.op_cap_enter:
    ; Pop cap_id from operand stack
    sub     r13, 8
    mov     rdi, [r13]                   ; new_cap_id

    ; Validate cap_id != 0
    test    rdi, rdi
    jz      .op_cap_enter_invalid

    ; Lookup slot
    call    registry_lookup_cap          ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .op_cap_enter_invalid

    ; Verify MAC (forgery detection)
    mov     rbx, rax                     ; preserve slot_ptr
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    cmp     rax, [rbx + CAP_OFF_MAC]
    jne     .op_cap_enter_invalid

    ; cap_stack overflow check
    mov     rcx, [rel cap_stack_ptr]
    cmp     rcx, CAP_STACK_DEPTH
    jge     .op_cap_enter_overflow

    ; Push current_cap_id to cap_stack
    mov     rax, [rel current_cap_id]
    mov     [rel cap_stack + rcx*8], rax
    inc     qword [rel cap_stack_ptr]

    ; Update current_cap_id and cache fields from new cap's slot
    mov     rax, [rbx + CAP_OFF_CAP_ID_SELF]
    mov     [rel current_cap_id], rax
    mov     rax, [rbx + CAP_OFF_ARENA_ID]
    mov     [rel current_cap_arena_id_cache], rax
    mov     rax, [rbx + CAP_OFF_OWNER_DEMOD_ID]
    mov     [rel current_cap_owner_demod_id_cache], rax

    ; Push Outcome::Ok (sentinel value 0; signals success)
    xor     edi, edi                     ; value = 0
    mov     r8, TYPE_CODE_NONE           ; value_type_id (no meaningful value)
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_enter_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_CAP_ENTER
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_enter_overflow:
    ; Pod 1.9.3 D1.9.3.2 tag-the-halt — push Err Outcome, emit diagnostic, halt
    mov     rdi, ERR_STACK_OVERFLOW
    mov     rsi, OP_CAP_ENTER
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_NONE           ; D1.9.3.3: stack violations have no expected-T
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    lea     rsi, [rel str_call_overflow] ; reuse Pod 1.3 string per architect spec
    call    auryn_puts
    jmp     .done                        ; HALT
```

EXIT outline (no MAC verify; cap_stack pop + cache restore):

```nasm
.op_cap_exit:
    mov     rcx, [rel cap_stack_ptr]
    test    rcx, rcx
    jz      .op_cap_exit_underflow

    ; Pop cap_stack
    dec     rcx
    mov     [rel cap_stack_ptr], rcx
    mov     rdi, [rel cap_stack + rcx*8]  ; restored cap_id

    ; Lookup restored cap's slot to refresh cache fields
    call    registry_lookup_cap          ; rax = slot_ptr (cap was registered at its ENTER; lookup must succeed)
    test    rax, rax
    jz      .op_cap_exit_underflow       ; defensive — should never fire if substrate consistent
    mov     rbx, rax

    ; Restore current_cap state from slot
    mov     rax, [rbx + CAP_OFF_CAP_ID_SELF]
    mov     [rel current_cap_id], rax
    mov     rax, [rbx + CAP_OFF_ARENA_ID]
    mov     [rel current_cap_arena_id_cache], rax
    mov     rax, [rbx + CAP_OFF_OWNER_DEMOD_ID]
    mov     [rel current_cap_owner_demod_id_cache], rax

    ; Push Outcome::Ok (sentinel value 0)
    xor     edi, edi
    mov     r8, TYPE_CODE_NONE
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_exit_underflow:
    mov     rdi, ERR_STACK_UNDERFLOW
    mov     rsi, OP_CAP_EXIT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_NONE
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    lea     rsi, [rel str_ret_underflow] ; reuse Pod 1.3 string per architect spec
    call    auryn_puts
    jmp     .done                        ; HALT
```

## R8 — OP_CAP_CURRENT handler design

Trivial. Push current_cap_id. No failure path; current_cap_id always ≥ ROOT_CAP_ID=1.

```nasm
.op_cap_current:
    mov     rax, [rel current_cap_id]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
```

Stack net +1. Cost 0j structural. No Outcome wrapping (parallel to OP_PHASE_QUERY from Pod 1.8.5c).

## R9 — OP_CAP_ARENA / OP_CAP_OWNER / OP_CAP_RESOURCE + .cap_accessor_common

Three handlers share shape via `.cap_accessor_common` helper (parallel to Pod 1.9.3 .construct_ok_outcome / .construct_err_outcome factoring).

ARENA handler:

```nasm
.op_cap_arena:
    sub     r13, 8
    mov     rdi, [r13]                   ; cap_id
    mov     rcx, CAP_OFF_ARENA_ID        ; field offset
    mov     rsi, OP_CAP_ARENA            ; source_op for Err
    call    .cap_accessor_common
    mov     [r13], rax                   ; outcome_id
    add     r13, 8
    jmp     .fetch
```

OWNER and RESOURCE handlers identical except `rcx = CAP_OFF_OWNER_DEMOD_ID` / `CAP_OFF_RESOURCE_DESC` and `rsi = OP_CAP_OWNER` / `OP_CAP_RESOURCE`.

`.cap_accessor_common` outline:

```nasm
; Input:  rdi = cap_id, rcx = field offset, rsi = source_op
; Output: rax = outcome_id (Ok wrapping field value, or Err)
.cap_accessor_common:
    push    rsi                          ; preserve source_op
    push    rcx                          ; preserve field offset

    ; Validate cap_id != 0
    test    rdi, rdi
    jz      .accessor_invalid

    ; Lookup slot
    call    registry_lookup_cap          ; rax = slot_ptr
    test    rax, rax
    jz      .accessor_invalid
    mov     rbx, rax

    ; Verify MAC (forged cap detection)
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute
    cmp     rax, [rbx + CAP_OFF_MAC]
    jne     .accessor_invalid            ; A3: MAC fail collapses to ERR_INVALID_ID

    ; Read field at offset, wrap in Outcome::Ok
    pop     rcx                          ; restore offset
    pop     rsi                          ; (source_op unused on success)
    mov     rdi, [rbx + rcx]             ; value
    mov     r8, TYPE_CODE_CAP
    call    .construct_ok_outcome
    ret

.accessor_invalid:
    pop     rcx                          ; discard offset
    pop     rsi                          ; restore source_op
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    ret
```

## R10 — Test surface designs

Six core test surfaces:

| T | Surface | Purpose | Expected Output (key values) |
|---|---------|---------|------------------------------|
| T1 | test_cap_new_basic.cbc | Construct cap with resource_descriptor=42; UNWRAP_OK; print cap_id | cap_id=2 (ROOT=1, first user-created=2) |
| T2 | test_cap_arena_owner_resource.cbc | Three accessors on user-created cap | arena=0, owner=0, resource=42 |
| T3 | test_cap_current.cbc | OP_CAP_CURRENT before/inside/after ENTER+EXIT | 1, A's id, 1 |
| T4 | test_cap_invalid_id.cbc | OP_CAP_ARENA on cap_id=99 | Err{err_code=1, source_op=180 (=0xB4)} |
| T5 | test_cap_stack_underflow.cbc | OP_CAP_EXIT on empty cap_stack | str_ret_underflow + halt; Err{err_code=3, source_op=178 (=0xB2)} |
| T6 | test_cap_stack_overflow.cbc | 257 OP_CAP_ENTER (fills 256-deep stack) | str_call_overflow + halt; Err{err_code=4, source_op=177 (=0xB1)} |

T6 size: 257 ENTER opcodes need 257 cap_ids on operand stack first. Construct one cap, DUP it 256 times = 257 instances of same cap_id, then 257 ENTER operations. Bytecode budget: ~30 bytes setup + 257 × 1 byte ENTER = ~290 bytes. Within budget.

Inherited regression: B2 (Sign 174j), B3 (Energy 53j), B4 (pristine boot), B5 (6 Outcome regression), B6 (4 error-path regression), plus B7-B12 for T1-T6, plus B13 liveness probe.

**Total: 13 B-items.**

## R11 — Build chain confirmation

```
NASM version 2.16.01
mcopy (GNU mtools) 4.0.43
QEMU emulator version 8.2.2

Build 1: a7e610c44651b5e5edd9a903792d4fec6b923a2b92a345ee0aa5cb4111293a81
Build 2: a7e610c44651b5e5edd9a903792d4fec6b923a2b92a345ee0aa5cb4111293a81
cmp -s:  BYTE-IDENTICAL
```

Entry contract verified at `a7e610c4...` (Pod 1.10.2a hash). Two-build determinism preserved.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — OP_CAP_ENTER cost classification

Architect R2 specifies OP_CAP_ENTER = 0j structural; architect R7 outline includes MAC verification (siphash_compute + cmp against stored MAC).

The classifications are contradictory. Two paths:
- **(a)** ENTER = 1j metabolic. MAC verify stays. Forgery detection at ENTER is essential — without it, any cap_id colliding with a registry entry could enter authority. Cost matches the work done.
- **(b)** ENTER = 0j structural. Drop MAC verify; trust registry_lookup_cap result. Weakens security model.

**TB recommendation: (a).** Forgery detection is load-bearing for the substrate's "authority is fingerprint" reframe. The cost-table classification follows the work, not the surface label. R4 cost table has been written assuming (a).

D1.10.2b1.6 records the resolution.

### A2 — OP_CAP_ENTER / OP_CAP_EXIT stack effect on failure

Two readings of Path A consistency:
- **(a)** Asymmetric stack effects. Success: pop cap_id, push nothing (net -1). Failure: pop cap_id, push Err Outcome (net 0). Programs can't easily detect success since success has no return.
- **(b)** Outcome<()> always — every fallible operation returns Outcome. Success pushes Outcome::Ok with sentinel value=0 / value_type_id=TYPE_CODE_NONE. Failure pushes Outcome::Err. Stack net 0 on both paths. Caller IS_OK to confirm.

**TB recommendation: (b).** Path A consistency: every fallible operation returns Outcome. The "Ok with no meaningful value" pattern is honest — TYPE_CODE_NONE signals "operation succeeded, no value to extract." Programs that don't care about the success signal can DROP. Programs that care can IS_OK or pattern-match.

R7 outlines written assuming (b). D1.10.2b1.6 records the resolution.

### A3 — MAC-failure err_code

Two readings:
- **(a)** ERR_INVALID_ID. From caller's view, "cap_id doesn't resolve" and "cap_id resolves to corrupted/forged slot" are operationally identical.
- **(b)** New ERR_CAP_MAC_INVALID = 8. Distinguished err_code allows substrate-side audit to distinguish forgery attempts from random misses.

**TB recommendation: (a).** V1.0 simplicity: caller sees "this cap doesn't work" and that's all they need. Forgery detection at substrate-secret level is V2+ concern (Pod 2 / Cop). Pod 2 may distinguish for audit per DEFERRED #56.

R9 outline (.cap_accessor_common) written assuming (a). D1.10.2b1.7 records the resolution.

### A4 — Helper register-convention bug in architect's outlines

Architect R6 / R9 outlines use `mov rsi, TYPE_CODE_CAP; call .construct_ok_outcome`. The actual helper signature (cbs_vm.asm:1303-1307) is `rdi=value, r8=value_type_id`. All Pod 1.9.3 call sites verified — `r8` is the canonical register.

**TB will use `mov r8, TYPE_CODE_CAP` for all Cap handler calls into .construct_ok_outcome / .construct_err_outcome.** No architect ratification needed — this is a strict correction of the architect outline against the actual code in tree. R6/R9 outlines in this report use the corrected `r8`.

This is recon catching architect-side detail-level inconsistency at the cheapest verification point. D1.10.2b1.8 records the catch.

---

## Section 3 — Risks identified

- **R3.1 — ENTER MAC-verify cost surfacing.** A1 classification choice; if (a) ratified, OP_CAP_ENTER's 1j cost will appear in canary tests that exercise ENTER. Pod 1.10.2b1's canary tests under ROOT context don't ENTER child caps (Sign/Energy/Outcome handlers don't do ENTER). 174j Sign canary and 53j Energy canary should hold. T3 (test_cap_current) does ENTER once; budget impact tracked at T3 expected output.
- **R3.2 — current_cap_arena/owner cache reads in OP_CAP_NEW.** Strict delegation reads current_cap_arena_id_cache (V1.0 = 0 under ROOT) and current_cap_owner_demod_id_cache (V1.0 = 0). Until 1.10.2b2 lands the Sign/Energy/Outcome allocator retrofit, these zero values match the substrate-wide V1.0 state. After 1.10.2b2: caps inherit non-zero arena/owner from caller's current_cap. No refit for 1.10.2b1 itself.
- **R3.3 — Test surface T6 size budget.** 257 ENTER opcodes plus DUP setup ~290 bytes total. Well within program budget. Stack at runtime: 257 × 8 bytes = 2056 bytes on operand stack; vm_stack capacity 512 entries × 8 = 4096 bytes. Fits.
- **R3.4 — TYPE_CODE_NONE on OP_CAP_ENTER success.** Outcome::Ok with value=0 and value_type_id=TYPE_CODE_NONE is novel — first use of "operation succeeded, no meaningful value to wrap" pattern. UNWRAP_OK on it produces 0 sentinel, which is correct. IS_OK on it produces 1, which is what the caller checks. No inconsistency with Pod 1.9.3 patterns; just a new application.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

**S1:** Constants in defines.asm — remove OP_CAP_CHECK; add OP_CAP_ARENA/OWNER/RESOURCE.
**S2:** Seven opcode handlers + .cap_accessor_common helper in cbs_vm.asm per R6/R7/R8/R9.
**S3:** Seven dispatch entries inserted at cbs_vm.asm:162.
**S4:** Cost table replacement in energy_costs.asm:112-113.
**S5:** atreyu_x86.py support — 7 opcode constants, 7 AST handlers, 6 demos, 12 CLI flags, usage update.
**S6:** Six new test surfaces compiled via atreyu_x86.py CLI to surfaces/.

Phase 2B B1 reads BOOTX64.EFI; B2/B3 verify 174j/53j canaries hold; B4 pristine boot; B5/B6 inherited regression invisibility; B7-B12 six new test surfaces; B13 liveness probe. 13 B-items total.

---

## Section 5 — Surprises

- **S5.1 — A1 cost-classification inconsistency** in architect's spec is the most-load-bearing recon finding. Cost-of-work doctrine (D1.9.2b.1, D1.9.2a.3) requires cost-table values to match the work performed. ENTER's MAC verify is real cryptographic work; classifying it as 0j contradicts the doctrine. Per D1.10.2a.10's cross-reference-against-authoritative-source pattern, recon is the cheapest checkpoint to surface this.
- **S5.2 — A4 helper register-convention bug** in architect's outlines is a separate detail-level catch. The actual code uses r8 for value_type_id; outlines used rsi. No ratification needed (corrected unilaterally against in-tree code), but worth recording as part of the recon discipline working as designed.
- **S5.3 — The bouncer-to-fingerprint reframe lands cleanly at implementation pod time.** D1.10.1.3/D1.10.1.11 specified OP_CAP_CHECK; recon at Pod 1.10.2b1 supersedes. The architect's pre-recon ratification anticipated the supersession; this recon implements it. Substrate-witness pattern (program reads slot field via accessor) is structurally simpler than substrate-police (program asks substrate to confirm match). The accessors are byte-for-byte parallel in shape — three handlers calling one helper, each doing the same lookup-verify-read with different field offsets.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 4 architect calls (A1 ENTER cost, A2 stack-effect-on-failure, A3 MAC-failure err_code, A4 helper register correction).
- 4 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED-1.**

— Terminal Boy
May 04 2026
