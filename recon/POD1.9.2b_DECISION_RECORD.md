# Pod 1.9.2b Decision Record — Outcome opcode handlers + tests

**Pod:** 1.9.2b — second source pod of Section 2 (handlers, cost table, log strings, prov_append wire-up, tools, 6 test surfaces)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432 (Pod 1.9.2a BOOTX64.EFI)
**Exit contract:** 857622e97747df37a19fa5dfed733c211a98257670ae77f20260c06bdfca797b
**Entry HEAD:** 164238fa9926c825ef9f4872757647c3eb7e234c (Pod 1.9.2a seal)

---

## D1.9.2b.1 — Cost table generalization: typed-primitive accessor split

Three of five Outcome opcodes carry 0j cost (IS_OK, UNWRAP_OK,
UNWRAP_ERR); two carry 1j metabolic (NEW_OK, NEW_ERR). The split
matches the structural-vs-metabolic doctrine established in Pod 1.8.5c
D1.8.5c.8 (HALT/RESERVE/PHASE_QUERY at 0j) and generalized in Pod
1.9.2a D1.9.2a.3 (substrate bookkeeping is 0j).

**Generalization:** typed-primitive accessor opcodes split as:
- **NEW_*** (construction): metabolic — allocates a slot, writes
  fields, registers in canonical-ID table. Real work; pays cost.
- **IS_*/UNWRAP_***: structural — reads slot fields and pushes onto
  operand stack. Reading is not work, even when the read includes
  diagnostic emission (UNWRAP wrong-discriminant). Cost = 0j.

**B7 and B8 confirm empirically:** UNWRAP_OK on err and UNWRAP_ERR
on ok both emit log lines via auryn_puts, and both cost 0j per the
cost table. The diagnostic emission is a structural side effect, not
metabolic work — an audit signal, not a computation.

This pattern is canon for Pod 1.10 (Cap), Pod 1.12 (Demod), and any
future typed primitive: NEW_* metabolic, IS_*/UNWRAP_* structural.

## D1.9.2b.2 — fetch_counter bifurcation per A1

OP_OUTCOME_NEW_ERR populates two distinct fetch_counter values:
- **Substrate-domain** (`[rel vm_fetch_count]`) → `prov_append(rdx)`.
  Records when the prov event was generated, in substrate-internal
  fetch ticks. Independent of program semantics.
- **Program-domain** (user-supplied via stack arg) → Outcome inline
  context at +0x38. Records what the program-author considers the
  relevant timestamp for the err — could be a request-id, sequence
  number, or arbitrary tag the program is using.

**Why both:** prov events serve substrate audit (fairness, rate
limiting, debugging the substrate); inline err context serves
typed-program semantics (the consuming code chooses what the
fetch_counter means). Coupling them would force one domain to
dominate the other; bifurcation lets each evolve independently.

**B5 confirms:** with `err_fetch_counter=12345` user-supplied,
UNWRAP_ERR returns 12345 from the inline context. The substrate
counter would have been a different (smaller, monotonically
increasing per-boot) value if observable.

## D1.9.2b.3 — NEW_ERR value_type_id = expected-T-on-error per A2

OP_OUTCOME_NEW_ERR's `value_type_id` arg records the type T that
the failing operation was supposed to produce. Caller routes by
this code (e.g., `if value_type_id == TYPE_CODE_SIGN: handle as
sign-construction-failure`).

**Inheritance pattern for Pod 1.10 (Cap), Pod 1.12 (Demod), and any
operation returning Outcome<T> on err:** the operation must record
the expected T at construction time. This is the sole architectural
artifact of the err that ties it to the success-shape it failed to
deliver.

DEFERRED #44, #45 (Sign and Energy accessor refit) explicitly use
TYPE_CODE_SIGN and TYPE_CODE_ENERGY for their err Outcomes per this
rule.

## D1.9.2b.4 — UNWRAP_ERR push order per A1 verbatim spec (option i)

D1.9.1.4 spec: "push err_code, push err_source_op, push err_demod_id,
push err_fetch_counter (4 values)". Sequential pushes → TOS =
err_fetch_counter (last pushed); err_code at bottom (first pushed).

**Architectural consistency over test ergonomics.** OP_SIGN_HASH
established the precedent for typed-primitive multi-value pushes:
hash[0:8] at bottom of the 4-value group, hash[24:32] at TOS.
UNWRAP_ERR follows the same field-position-0-at-bottom convention.

**B8 confirms:** test prints in TOS-pop order (fetch_counter=99,
demod_id=1, source_op=160, err_code=42), which is **reverse** of
field-declaration order. Tests adapted with explicit labels per A1
ratification ("fetch_counter (TOS)", "err_code (bottom)"). The label
discipline is the cost of architectural consistency; trivial cost
because labels are 1 OP_PRINT_STR each.

**Pod 1.10/1.12 inherit:** when a typed primitive's UNWRAP returns
multiple values, push field-position-0 at bottom. Caller pops in
TOS-first order (typically reverse of field-declaration); labels
disambiguate.

## D1.9.2b.5 — Sentinel-and-log on UNWRAP wrong-discriminant per D1.9.1.8

UNWRAP_OK on err: pushes 0 sentinel + emits `str_unwrap_ok_on_err`.
UNWRAP_ERR on ok: pushes 4 zero sentinels + emits `str_unwrap_err_on_ok`.

**Empirical confirmation via B7 and B8:** both log lines appear
verbatim in the screen output, between the test's pre-unwrap
PRINT_STR label and the post-unwrap PRINT_NUM. The diagnostic
appears mid-statement-execution because the handler emits the log
before pushing the sentinel; the sentinel is then printed by the
test's outer print expression.

**Stack shape preserved across both discriminant paths:** UNWRAP_OK
always pushes 1 value (real or sentinel); UNWRAP_ERR always pushes
4 values (real or 4 sentinels). Downstream code's stack arithmetic
stays predictable regardless of discriminant.

Pod 2 (Cop) may harden to runtime stack-shape verification or to a
real fault path when the substrate gets one. Until then, sentinel +
log is the convention.

## D1.9.2b.6 — prov_append first-consumer wire-up per D1.9.1.6

OP_OUTCOME_NEW_ERR is the substrate's first consumer of Move 2's
auto-provenance hook (Pod 1.8.5c). The wire-up:
```
mov     rdi, [rsp + 16]         ; opcode = err_source_op (A4.b)
mov     rsi, [rsp + 8]          ; demod_id = err_demod_id (A4.c)
mov     rdx, [rel vm_fetch_count] ; fetch_counter = substrate value (A1)
call    prov_append             ; cap-gate internal; preserves r9/r10/etc.
```

**Cap-gate default-OFF kept the call no-op in V1.0** (B5 ran with
`current_demod_prov_enabled=0`). The call site itself was verified
clean — no crash, VM state preserved (r12 instruction pointer, r13
operand stack, r14 energy budget all intact across the call).

When Pod 2 (Cop) flips `current_demod_prov_enabled=1` for relevant
demods, this hook activates without further source change. The
ProvEvent ring buffer at `prov_ring_buf` will receive one entry per
NEW_ERR firing under those demods.

## D1.9.2b.7 — IS_OK on invalid id pushes 0 per A3

`registry_lookup_outcome` returns 0 for invalid outcome_id (id=0 or
not-in-registry). OP_OUTCOME_IS_OK treats this as "not-OK" and
pushes 0.

**Rationale:** matches the substrate's null-is-err-ish convention.
Caller doing IS_OK on garbage gets the safe default (0 = "not OK,
maybe handle as err"). Distinguishing "real err" from "invalid id"
would require a third return value (e.g., -1) and force callers to
check three values instead of two — not worth the complexity at V1.0.

If a future pod needs the distinction (e.g., Pod 2 Cop's audit may
want to flag invalid-id events separately from real errs), the
mechanism is to add a separate `OP_OUTCOME_VALIDATE` opcode that
returns 0/1/2 (invalid/err/ok). Forward-log to that pod when the
need surfaces.

## D1.9.2b.8 — Pool-full handling: sentinel-only per A2

NEW_OK and NEW_ERR push 0 sentinel if `vm_outcome_alloc` returns
NULL (pool at capacity) or if `registry_register_outcome` returns
0 (registry at capacity; capacities matched at 64 so this is also
unreachable in V1.0 unless one diverges).

**No log string in V1.0** per A2 ratification — pool-full is
unreachable with capacity 64 and tests constructing 1-2 outcomes.
The sentinel matches the existing accessor null-handler pattern
(`sign_new_fail`, `energy_new_fail`).

DEFERRED #47 forward-logs Pod 2 (Cop) hardening: explicit log +
audit signal + possibly graceful degradation when pool-full becomes
reachable in production workloads.

## D1.9.2b.9 — CPU-stack save/restore in NEW_ERR for register state preservation

R3.3 risk addressed. NEW_ERR's handler is the most complex of the
five — pops 5 args (r8/r9/r10/r11/rcx), writes 8 slot fields,
performs 8-qword stosq zero-fill, calls registry_register_outcome,
then calls prov_append. Across these calls, `r9` (err_demod_id) and
`r10` (err_source_op) need to survive for the prov_append call.

**Approach: defensive cpu-stack save/restore** rather than relying on
register-preservation conventions:
```
push    r10                     ; -> [rsp+8] after one more push
push    r9                      ; -> [rsp+0]
[stosq, registry_register_outcome]
push    rax                     ; outcome_id
mov     rdi, [rsp + 16]         ; err_source_op (saved 16 below TOS)
mov     rsi, [rsp + 8]          ; err_demod_id (saved 8 below TOS)
mov     rdx, [rel vm_fetch_count]
call    prov_append
pop     rax                     ; outcome_id
add     rsp, 16                 ; discard saved args
```

Cleanup paths in both success (`pop rax; add rsp, 16`) and failure
branches (`add rsp, 16` at `.outcome_new_err_pop2_fail`) preserve
cpu-stack invariants. The defensive pattern made NEW_ERR easier to
verify than trusting that registry_register_outcome and prov_append
both preserve r9/r10 — the explicit save/restore is mechanical and
correctness-by-inspection.

## D1.9.2b.10 — Cross-asset constants verification doctrine

**Mid-Phase-2B fix surfaced an audit-trail gap.** Pod 1.9.2a's
substrate plumbing landed type codes (TYPE_CODE_*), pool constants
(OUTCOME_POOL_SLOTS, OUTCOME_SLOT_SIZE), and OUTCOME_ID_NULL — but
**not** the OP_OUTCOME_* opcode constants themselves. Pod 1.9.2b's
build failed with `symbol 'OP_OUTCOME_UNWRAP_OK' not defined` when
the dispatch entries (which reference these constants) tried to
assemble.

The fix was within-scope under D1.8.5c.7 doctrine (unique fix, no
design alternative — opcodes already canon at 0xE0-0xE4 per Pod
1.9.1 D1.9.1.4; only `%define` placement was missing). Five
`%define` lines added to `boot/defines.asm`; rebuild succeeded; B1
deterministic.

**Doctrine note for future opcode-adding pods:** when a pod adds
opcodes, three independent assets need the constant:
1. `boot/defines.asm` for assembler symbol resolution
2. `tools/atreyu_x86.py` for emitter
3. dispatch chain entries in `boot/cbs_vm.asm`

Recon should verify all three assets, not just the asset under
primary attention. Pod 1.9.2a's recon R5 covered TYPE_CODE_* and
OUTCOME_ID_NULL placement but not OP_OUTCOME_*; Pod 1.9.2b's recon
R7 covered `tools/atreyu_x86.py` opcode constants but didn't
cross-check `boot/defines.asm`. Two pods of recon discipline missed
it. The build catch is the safety net; recon should catch first.

**Reframing in canon:** opcode constants belong with their
primitive's substrate plumbing pod, not the handler pod. Pod 1.10
(Cap) and Pod 1.12 (Demod) inherit the rule: substrate plumbing
includes opcode constant declarations. Their respective recon R-items
include explicit cross-asset constant verification.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.9.2b.1 | Cost table generalization — NEW_* metabolic, IS_*/UNWRAP_* structural |
| D1.9.2b.2 | fetch_counter bifurcation: substrate-domain to prov, program-domain to inline |
| D1.9.2b.3 | NEW_ERR value_type_id = expected-T-on-error |
| D1.9.2b.4 | UNWRAP_ERR push order: A1 verbatim (err_code at bottom, fetch_counter at TOS) |
| D1.9.2b.5 | Sentinel-and-log on UNWRAP wrong-discriminant — confirmed via B7/B8 |
| D1.9.2b.6 | prov_append first-consumer wire-up — clean; cap-gate default-OFF in V1.0 |
| D1.9.2b.7 | IS_OK on invalid id pushes 0 (treats invalid as not-ok) |
| D1.9.2b.8 | Pool-full sentinel-only; no log in V1.0; Pod 2 Cop hardens |
| D1.9.2b.9 | CPU-stack save/restore in NEW_ERR for defensive register preservation |
| D1.9.2b.10 | Cross-asset constants verification doctrine — opcode constants belong in substrate plumbing pod |

Architect ratified A1, A2, A3 at AUTHORIZED-1; D1.9.2b.10 doctrine
note added at AUTHORIZED-2B per architect's explicit framing of the
mid-Phase-2B fix as audit-trail-worthy.

— Terminal Boy
May 03 2026
