# Pod 1.9.3 Recon Report — Sign + Energy accessor refit + stack-violation refit

**Pod:** 1.9.3 — third source pod of Section 2 (closing pod for Outcome work). Closes DEFERRED #13 + #16.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 857622e97747df37a19fa5dfed733c211a98257670ae77f20260c06bdfca797b (Pod 1.9.2b BOOTX64.EFI)
**Entry HEAD:** 760a3d3e0749ea3ebabffe85680553d6a2bfda84 (Pod 1.9.2b seal)

---

## R1 — Pre-flight three-oracle

Three-oracle agrees at `760a3d3e0749ea3ebabffe85680553d6a2bfda84`. Build artifacts (DEFERRED #10) and four throwaway scripts (DEFERRED #33-#34, #48) untracked per protocol.

## R2 — Sign accessor null-path enumeration

| Accessor | Entry label | Lookup site | Test/branch | Null path stack effect | Success path stack effect |
|----------|-------------|-------------|-------------|------------------------|---------------------------|
| OP_SIGN_HASH | `.op_sign_hash` (line 841) | line 847 `call registry_lookup_sign` | line 848-849 `test/jz .sign_hash_null` | `.sign_hash_null` (lines 862-868): pushes 4 zero qwords (matches success shape) | success: pushes 4 hash qwords (32 bytes) |
| OP_SIGN_LABEL | `.op_sign_label` (line 870) | line 876 `call registry_lookup_sign` | line 877-878 `test/jz .sign_label_null` | `.sign_label_null` (lines 888-892): pushes 2 zero qwords (matches success shape) | success: pushes addr+length pair (2 qwords) |
| OP_SIGN_ENERGY | `.op_sign_energy` (line 894) | line 900 `call registry_lookup_sign` | line 901-902 `test/jz .sign_energy_null` | `.sign_energy_null` (lines 909-912): pushes 1 zero qword | success: pushes energy_cost (1 qword) |

Pre-call register state: each accessor pops sign_id into rdi (immediate) and calls registry_lookup_sign (which preserves r12/r13/r14/r15/rbx/rbp/rdi). No additional state preservation needed for the lookup itself.

**CRITICAL FINDING — stack-shape mismatch with Outcome<u64> refit (surfaced as A1 below).** Outcome<T> per D1.9.1.1 wraps a single u64. Refitting OP_SIGN_HASH or OP_SIGN_LABEL to push outcome_id on err **diverges stack shape** between OK and Err paths (4 qwords vs 1; or 2 qwords vs 1). The downstream AST `sign_hash_first` does `OP_SIGN_HASH; DROP; DROP; DROP` (drops 3 of the 4 hash qwords). On err with 1 outcome_id pushed, the DROPs underflow into prior stack values. Caller cannot safely consume.

Only OP_SIGN_ENERGY (single u64 success) refits naturally.

## R3 — Energy accessor null-path enumeration

| Accessor | Entry label | Null path stack effect | Success path stack effect |
|----------|-------------|------------------------|---------------------------|
| OP_ENERGY_JOULES | `.op_energy_joules` (line 959) | `.energy_joules_null` (lines 973-976): pushes 1 zero qword | success: 1 qword |
| OP_ENERGY_SOURCE_OP | `.op_energy_source_op` (line 978) | `.energy_source_op_null` (lines 992-995): pushes 1 zero qword | success: 1 qword |

**Both Energy accessors single-value; refit cleanly.** No stack-shape divergence.

## R4 — OP_SIGN_NEW allocation-failure path

`.sign_new_fail` (lines 835-839) is reached from **four** distinct conditions:

| Condition | Source | Recommended err_code |
|-----------|--------|----------------------|
| Label length > 63 | line 762-763 (validate after pops) | ERR_INVALID_SIGN_ARG |
| embedding_handle != 0 | line 765-766 | ERR_INVALID_SIGN_ARG |
| `.sign_alloc` returns 0 | line 771-772 (pool full) | ERR_POOL_FULL |
| registry_register_sign returns 0 | line 829-830 (registry full) | ERR_POOL_FULL |

**Distinguishing the err codes requires splitting `.sign_new_fail` into two labels** (`.sign_new_fail_invalid_arg` and `.sign_new_fail_pool_full`) and routing the 4 jumps appropriately. Modest refactor — 4 jump-target updates, 2 fail labels, each with its own Err construction body.

TB recommendation: split. The two cases have different audit semantics (invalid arg = caller bug; pool full = capacity exhaustion). Worth the modest refactor.

## R5 — OP_ENERGY_NEW allocation-failure path

`.energy_new_fail` (lines 954-957) is reached from **two** conditions:

| Condition | Source | Recommended err_code |
|-----------|--------|----------------------|
| `.energy_alloc` returns 0 | line 931-932 (pool full) | ERR_POOL_FULL |
| registry_register_energy returns 0 | line 948-949 (registry full) | ERR_POOL_FULL |

Both effectively "exhaustion of allocation resources" with matched capacities (V1.0 capacity 64). Single err_code (ERR_POOL_FULL) covers both honestly. No invalid-arg paths in current OP_ENERGY_NEW (joules and source_op aren't validated).

TB recommendation: single fail label; ERR_POOL_FULL only. ERR_INVALID_ENERGY_ARG defined in S1 stays unused for now (forward-log for when arg validation lands).

## R6 — Stack-violation halt-site audit

Both halt sites follow identical 3-line shape (`lea rsi, [rel str]; call auryn_puts; jmp .done`):

```
.ret_underflow:                           ; line 403, reached from OP_RET (line 395 jz)
    lea     rsi, [rel str_ret_underflow]
    call    auryn_puts
    jmp     .done

.call_overflow:                           ; line 698, reached from OP_CALL
    lea     rsi, [rel str_call_overflow]
    call    auryn_puts
    jmp     .done
```

`.done` is the VM exit handler (cleanly halts and returns control to gmork). Refit per Pre-A2 option (b) layers the Err push **before** the existing emit/halt sequence:

```
.ret_underflow:
    ; Pod 1.9.3 — push Err Outcome before halt per Pre-A2 option (b)
    [inline construction: alloc slot, write Err with ERR_STACK_UNDERFLOW,
     register, push outcome_id]
    ; Existing diagnostic + halt preserved
    lea     rsi, [rel str_ret_underflow]
    call    auryn_puts
    jmp     .done
```

The Err is observable on the operand stack at halt time. Diagnostic still emits for human post-mortem.

**TB recommendation: option (a) — inline before existing emit/halt.** Cleanest layering; no diagnostic structure change.

## R7 — Test program audit

`tools/atreyu_x86.py` AST handlers for accessor invocations (lines 195-205 in current source):
- `sign_energy` (line 195-196): `self._expr(n['operand']); e.emit(OP_SIGN_ENERGY)` — single-qword result
- `sign_hash_first` (line 197-199): `self._expr(n['operand']); e.emit(OP_SIGN_HASH); e.emit(OP_DROP); e.emit(OP_DROP); e.emit(OP_DROP)` — emits OP_SIGN_HASH (4 qwords), drops 3, keeps slot0
- `sign_label_print` (line 121-122): `self._expr(n['value']); e.emit(OP_SIGN_LABEL); e.emit(OP_PRINT_STR); e.emit(OP_NEWLINE)` — emits LABEL (2 qwords), then OP_PRINT_STR (consumes 2 qwords)
- `energy_joules` (line 201-202): single-qword result
- `energy_source_op` (line 203-204): single-qword result

**Refit pattern proposed by prompt:** "modify existing AST handlers to emit accessor opcode followed by OP_OUTCOME_UNWRAP_OK." This works cleanly for `sign_energy`, `energy_joules`, `energy_source_op` (single-qword result becomes Outcome<u64>; UNWRAP_OK extracts the u64).

This **does NOT work** for `sign_hash_first` and `sign_label_print` — they consume multi-qword results that don't fit the Outcome<u64> shape. The DROP-DROP-DROP for hash and OP_PRINT_STR for label assume specific multi-value stack shapes that diverge from the err path's 1-qword outcome_id.

→ Surfaces as **A1 — multi-value accessor refit strategy**.

## R8 — Test surface designs

T1 (regenerated sign_test.cbc), T2 (regenerated test_energy.cbc): tractable IF A1 resolution permits OP_SIGN_HASH / OP_SIGN_LABEL refit. If A1 resolves to "skip refit for HASH/LABEL," then sign_test.cbc retains existing sign_hash_first / sign_label_print without UNWRAP_OK wrapping. Only sign_energy gets UNWRAP_OK.

T3 (test_sign_invalid_id): tractable. Test program constructs Sign (sign_id=1), calls OP_SIGN_ENERGY with sign_id=99 (invalid), gets outcome_id, IS_OK returns 0, UNWRAP_ERR returns 4 fields. **Note:** must use OP_SIGN_ENERGY (single-value accessor) for the invalid-id test, not HASH or LABEL — otherwise the test trips the A1 stack-shape issue.

T4 (test_energy_invalid_id): tractable with OP_ENERGY_JOULES.

T5 (test_stack_underflow): triggers OP_RET on empty return stack. Verify diagnostic + Err on operand stack at halt. **Test design constraint:** the Err is on stack but VM halts before any program-level inspection. Visible only via post-mortem screen output. The test program could push a marker before triggering underflow so the screen shows "before underflow" then the diagnostic, demonstrating the trigger fired and the Err construction happened (the diagnostic emits AFTER the Err push per S6 layering, so seeing the diagnostic in output proves Err was already constructed).

T6 (test_stack_overflow): same shape, requires recursive OP_CALL to fill the 256-entry return stack (vm_ret_stack from vmdata.asm). 256 nested calls = test program emits 256 OP_CALLs to itself. Tractable but bytecode-heavy. Alternative: shorter test, just confirm the diagnostic appears.

T7 (test_sign_pool_full): requires loop in atreyu_x86.py to emit 65 NEW_OK constructions. atreyu has `while` AST (line 195-202) so loop emission is feasible. **TB recommendation: SKIP T7.** Pool-full handling refit requires the .sign_new_fail split (R4). Once that's in place, T7 is straightforward but adds substantial test complexity. Forward-log to a future verification pod (or add to Pod 1.9.3 if architect prioritizes).

## R9 — Build chain confirmation

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 | ✓ |
| `./build.sh` × 2 | exit 0 both runs | ✓ |

EFI sha256 deterministic across two runs: `857622e97747df37a19fa5dfed733c211a98257670ae77f20260c06bdfca797b`. Matches Pod 1.9.2b row exactly.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Multi-value accessor refit strategy (LOAD-BEARING)

OP_SIGN_HASH (returns 32-byte hash as 4 qwords) and OP_SIGN_LABEL (returns addr+length as 2 qwords) cannot cleanly refit to push Outcome<u64> on err while preserving multi-qword success. Three options:

**(i) Skip refit for HASH/LABEL.** Pre-A1's "5 lookup accessors" narrows to 3 (OP_SIGN_ENERGY, OP_ENERGY_JOULES, OP_ENERGY_SOURCE_OP). HASH and LABEL retain current null-shape-preserving behavior. DEFERRED #16 partially closed; full closure waits for a multi-value Outcome design (or a HASH/LABEL handle-pool redesign that returns single-handle per call).
- **TB recommendation.** Cleanest semantically; no stack-shape divergence; test programs that already drop hash bytes / consume label string keep working unchanged. Pod 1.10 (Cap) and Pod 1.12 (Demod) primitives are likely also single-value (cap_id, demod_id), so the multi-value accessor refit is a Sign-specific concern that doesn't block downstream pods.

**(ii) Stack-shape divergence.** Refit all 5 accessors. Success path keeps multi-qword push; err path pushes 1 outcome_id. Caller must check IS_OK before assuming a particular shape — but Outcome's IS_OK consumes the outcome_id, so caller can't easily check then unwrap. Requires a peek-without-consume primitive that doesn't exist (Pod 1.9.1 A6 explicitly chose consume-not-peek). Not viable without revising A6.

**(iii) New opcode design — OP_SIGN_HASH_HANDLE / OP_SIGN_LABEL_HANDLE.** Returns single u64 handle to the hash/label data; caller fetches bytes via a separate primitive. Substantial design work; multi-pod scope. Defer to a future pod.

If architect chooses (i): R8's T1 (regenerated sign_test.cbc) keeps sign_hash_first and sign_label_print AST handlers unchanged; only sign_energy gets UNWRAP_OK. T3 (test_sign_invalid_id) tests OP_SIGN_ENERGY's invalid-id path (not HASH).

### A2 — Sign NEW fail-path err_code distinction

R4 found 4 conditions collapsing to one `.sign_new_fail`. Two options:
- **(i) Split into 2 labels** (`.sign_new_fail_invalid_arg` + `.sign_new_fail_pool_full`) with distinguished err_codes (TB recommendation; modest refactor).
- **(ii) Single fail label, single err_code** (e.g., ERR_SIGN_NEW_FAILED) with documented ambiguity. Lower mechanical cost; loses err_code precision.

### A3 — Energy NEW fail-path

R5 found 2 conditions both = "allocation exhausted." TB recommendation: single fail label, ERR_POOL_FULL. ERR_INVALID_ENERGY_ARG defined but unused; forward-log to when joules/source_op validation lands. Confirm or amend.

### A4 — T7 (test_sign_pool_full) inclusion

Requires loop in demo program emitting 65 OP_SIGN_NEW constructions. TB recommendation: SKIP for this pod; forward-log to a future verification pod. Architect can include if the pool-full path verification is load-bearing for Pod 1.10 inheritance.

### A5 — T5/T6 stack-violation test verification approach

The Err is on operand stack at halt time but invisible to in-program code (VM halts before next opcode). Verification path: (a) test program prints "before violation" marker, then (b) triggers violation, (c) screen shows "marker → diagnostic" sequence proving the violation fired AND the Err construction happened (since S6 lays Err before diagnostic, seeing the diagnostic implies the Err construction completed).

TB recommendation: this verification approach. Architect ratifies or amends.

---

## Section 3 — Risks identified

- **R3.1 — A1 resolution affects scope of Pod 1.9.3 substantially.** Option (i) reduces 5 → 3 accessor refits + leaves DEFERRED #16 partially open. Option (ii)/(iii) are larger redesigns.
- **R3.2 — Stack-violation Err construction in halt path requires careful register preservation.** OP_RET and OP_CALL handlers are mid-execution; r12/r13/r14 hold critical state. Inline Err construction must preserve them. Same defensive cpu-stack save/restore pattern as D1.9.2b.9.
- **R3.3 — Cross-asset constants verification per D1.9.2b.10.** This pod adds ERR_* err_code constants; they're used in cbs_vm.asm Err constructions (substrate side). Not used by tools/atreyu_x86.py at compile time (test programs hard-code expected err_code values for verification). Single-asset constant; less risk than D1.9.2b.10 but still verify.
- **R3.4 — Test surface filename** per Pod 1.8.5b A2 (DEFERRED #21 area). Current files: `surfaces/sign_test.cbc` (matches `--sign-build` default) and `surfaces/test_energy.cbc`. Inconsistent naming was accepted as-is per A2; Pod 1.9.3 regeneration uses the existing filenames.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

S1: 6 ERR_* constants in defines.asm
S2: Refit Sign accessor null paths per A1 resolution (3 sites if (i), 5 if (ii))
S3: Refit Energy accessor null paths (2 sites)
S4: Refit OP_SIGN_NEW fail paths per A2 resolution
S5: Refit OP_ENERGY_NEW fail path per A3 resolution
S6: Refit stack-violation halt sites (2 sites — `.ret_underflow`, `.call_overflow`)
S7: Regenerate sign_test.cbc and test_energy.cbc per A1 resolution
S8: New test demos (T3, T4, T5, T6; T7 skipped per A4)
S9: Cost table comments unchanged per existing classification

---

## Section 5 — Surprises

- **S5.1 — Multi-value accessor refit conflict.** D1.9.1.1 designed Outcome<T> to wrap a single u64. OP_SIGN_HASH and OP_SIGN_LABEL violate this assumption with their multi-qword success paths. Recon caught this before Phase 2A; the architect's Pre-A1 framing didn't anticipate the divergence.
- **S5.2 — Sign NEW fail path collapses 4 conditions** into one label. Pre-existing condition since Pod 1.7. Distinguishing err_codes requires modest refactor; the alternative (single err_code) loses audit precision.
- **S5.3 — Stack-violation Err on operand stack at halt is observable only via post-mortem.** No in-program code can read it (VM halts). The diagnostic emission ordering proves the Err was constructed.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 5 architect calls (A1 LOAD-BEARING, A2-A5 simpler).
- 4 risks surfaced.
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED. A1 resolution is load-bearing for the entire Phase 2A shape.**

— Terminal Boy
May 03 2026
