# Pod 1.9.2a Decision Record — Outcome substrate plumbing

**Pod:** 1.9.2a — first source pod of Section 2 (substrate carriers only)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 (Pod 1.8.5c BOOTX64.EFI; preserved through 1.9.1)
**Exit contract:** 23e0ed8cfa9a0ba658034fbdaef154d43d81c442167ae77838108a89a9a7d432
**Entry HEAD:** e4c1e0083db43e9eae22364c4062548af8d85f51 (Pod 1.9.1 seal)

---

## D1.9.2a.1 — Substrate plumbing landed before opcode handlers

Pod 1.9.2 was split into 1.9.2a (substrate plumbing — this pod) and
1.9.2b (opcode handlers + tools + tests). The split was ratified at
Pod 1.9.1 sealing; 1.9.2a lands the carriers (slot pool, registry,
constants, vm_fetch_count) without the behavior, producing a clean
intermediate state — the substrate has Outcome storage but no
Outcome opcodes are reachable.

**Considered alternative:** single-pod 1.9.2 landing carriers and
handlers together. Rejected because:
- Larger commit footprint mixes substrate adds with handler logic,
  making review and rollback noisier
- The substrate carriers are mechanical (registry mirror + vmdata
  add); the handlers carry real architectural decisions (D1.9.1.4
  stack effects, D1.9.1.6 prov_append wire-up, D1.9.1.8 sentinel
  convention). Splitting separates "mechanical substrate work" from
  "architectural handler work" cleanly
- 1.9.2a's clean intermediate state is a useful audit point —
  binary contract differs from 1.8.5c only in substrate state size,
  not in observable behavior (B2/B3 invisibility tests confirm)

**R3.3 risk recorded as intentional partial state, not defect.**
A user calling OP_OUTCOME_NEW_OK in 1.9.2a hits "Unknown opcode"
because the opcode is undefined, not just unhandled. This is the
expected state between 1.9.2a and 1.9.2b; tests must avoid
Outcome opcodes until 1.9.2b lands handlers.

## D1.9.2a.2 — vm_fetch_count increment site at .fetch loop head

Per D1.9.1.7 spec ("after the opcode is fetched and before
dispatch"). Site verbatim from `boot/cbs_vm.asm`:

```
.fetch:
    ; Fetch opcode byte
    movzx   eax, byte [r12]
    inc     r12
    ; Pod 1.9.2a D1.9.1.7 — substrate fetch counter for ProvEvent.
    inc     qword [rel vm_fetch_count]
    ; Per-opcode energy cost (Pod 1.8: cost table replaces flat 1j/fetch)
    push    rax                     ; preserve opcode across call
    call    energy_cost_lookup      ; al = opcode byte → rax = joules
    ...
```

Counter increments unconditionally on every opcode fetch — including
HALT, structural opcodes (OP_RESERVE, OP_PHASE_QUERY), and the
.fatigue-bound path. Semantically: the increment counts "fetches
executed so far" regardless of whether energy was successfully
debited. The .fatigue path still got a fetch, even if it couldn't
be paid for.

**u64 wrap behavior:** at GHz fetch rates, 2^64 fetches takes
~5.85 × 10^11 seconds ≈ 18,000 years. No source-level guard. Wrap is
documented as a non-concern at human timescales. If a future
substrate consumer needs delta-fetch-count over a window where wrap
matters (e.g., per-binding rate-limiting with very long-running
bindings), the consumer can wrap-aware-subtract using u64 arithmetic.

## D1.9.2a.3 — Substrate bookkeeping is 0j (doctrine generalization)

Pod 1.8.5c D1.8.5c.8 established the structural-vs-metabolic split:
opcodes that query substrate state (HALT, OP_RESERVE, OP_PHASE_QUERY)
cost 0j because reading state is not work; opcodes that perform
metabolic operations pay their cost.

Pod 1.9.2a generalizes the principle to substrate counters:
**substrate bookkeeping that doesn't represent work-done is 0j.**
The vm_fetch_count increment is the canonical example — the substrate
counts fetches as part of its own operation, but the counting itself
is not a metabolic event. The increment fires before
energy_cost_lookup and never debits r14 or [rel energy_used].

**Empirical confirmation (B2/B3 canaries):** Pod 1.8.5c reference
test outputs were `Energy: 174j used, 99826j remaining` (Sign) and
`Energy: 53j used, 99947j remaining` (Energy). Pod 1.9.2a output
under bare-metal QEMU produced byte-identical strings. The 174j and
53j canaries held verbatim despite the new unconditional increment
firing on every opcode fetch — empirical proof the substrate counter
costs zero metabolic energy.

This doctrine extends naturally to future substrate counters Pod 2
(Cop) may introduce — per-binding fetch budgets, fairness counters,
audit timestamps, etc. All structural; all 0j.

## D1.9.2a.4 — Substrate maturity evidence: registry pattern generalizes

Pod 1.8.5b introduced the canonical-ID registry pattern in
`boot/registry.asm` (Sign and Energy). Pod 1.9.2a's `boot/outcome.asm`
is a byte-for-byte mirror with symbol substitutions — identical
calling convention, identical linear-scan algorithm, identical
null-return-on-not-found behavior, identical doc-comment shape.

**Recon HALT 1 surfaced zero architect calls.** All implementation
questions (insertion sites, naming, calling convention, algorithm
shape) resolved unambiguously per existing precedent. The substrate
is now mature enough that adding a typed-primitive registry is
mostly a copy-paste-and-rename of the established pattern.

**Recording as canon for Pod 1.10/1.12 inheritance:** when Cap and
Demod typed primitives land their registries, they follow this
exact pattern:
1. Add `<TYPE>_POOL_SLOTS`, `<TYPE>_SLOT_SIZE`, `<TYPE>_ID_NULL` to
   `boot/defines.asm`
2. Add `vm_<type>_pool` + `vm_<type>_next` + `<type>_registry_*`
   blocks to `boot/vmdata.asm`
3. Create `boot/<type>.asm` with `registry_register_<type>` and
   `registry_lookup_<type>` mirroring registry.asm shape
4. Add `%include "boot/<type>.asm"` to `boot/boot.asm` between the
   prior typed-primitive include and `bastian.asm`

Future substrate-mature pods inherit zero-A-call mechanical adds;
architectural surface lives in handler design (1.9.2b shape), not
in registry mechanics.

## D1.9.2a.5 — TYPE_CODE_* enum and OUTCOME_ID_NULL constants

Per D1.9.1.1 ratification. `boot/defines.asm` gained:

```
%define OUTCOME_ID_NULL 0   ; in canonical-ID null-sentinel block

%define TYPE_CODE_NONE     0
%define TYPE_CODE_SIGN     1
%define TYPE_CODE_ENERGY   2
%define TYPE_CODE_CAP      3   ; reserved for Pod 1.10
%define TYPE_CODE_DEMOD    4   ; reserved for Pod 1.12
%define TYPE_CODE_SIGNAL   5   ; reserved for Pod 4
%define TYPE_CODE_OUTCOME  6   ; reserved for Outcome wrapping Outcome
```

**TYPE_CODE_NONE = 0 sentinel rationale:** mirrors the canonical-ID
null-sentinel convention (SIGN_ID_NULL = 0 etc.). An Outcome with
`value_type_id = TYPE_CODE_NONE` is by definition uninitialized —
its slot bytes were never touched by a constructor, or the
constructor failed before writing the field. OP_OUTCOME_NEW_OK and
OP_OUTCOME_NEW_ERR (lands 1.9.2b) must set value_type_id to a
non-zero code or fail the construction. Audit consumers may flag
TYPE_CODE_NONE Outcomes as malformed.

The TYPE_CODE space is independent of the canonical-ID NULL
sentinels (which are all 0); only the discriminant role matters.
Codes 1-6 are stable; code 7+ reserved for future canonical-ID
types beyond Sign/Energy/Cap/Demod/Signal/Outcome.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.9.2a.1 | Substrate plumbing before handlers; 1.9.2 split into 1.9.2a/1.9.2b |
| D1.9.2a.2 | vm_fetch_count increment site verbatim documented; u64 wrap = 18,000 years |
| D1.9.2a.3 | Substrate bookkeeping is 0j — doctrine generalization with 174j/53j canary confirmation |
| D1.9.2a.4 | Registry pattern generalizes; substrate-maturity canon for Pod 1.10/1.12 |
| D1.9.2a.5 | TYPE_CODE_* enum + OUTCOME_ID_NULL with TYPE_CODE_NONE sentinel rationale |

Architect ratified all five decisions at AUTHORIZED-1 (D1.9.2a.1,
D1.9.2a.2, D1.9.2a.5 directly; D1.9.2a.3 and D1.9.2a.4 derived from
HALT 2B canary results and HALT 1 zero-A-call observation).

— Terminal Boy
May 03 2026
