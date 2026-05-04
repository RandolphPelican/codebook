# Pod 1.9.1 Design Decisions — Outcome Canon

**Pod:** 1.9.1 — recon-only canon pod (Outcome<T> design seal + RECONSTITUTION v9 patch)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 (Pod 1.8.5c BOOTX64.EFI; preserved through 1.9.1 — canon-only pod)
**Exit contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199 (preserved; no source change)
**Entry HEAD:** f5dccaf3f57f216a212391e9a4901f02197d0fcc (Pod 1.8.5c seal)

---

## D1.9.1.1 — Tagged Outcome with `value_type_id` discriminant

`Outcome<T>` is a single primitive with a u64 `discriminant` (0=ok, 1=err)
plus a u64 `value_type_id` naming which canonical-ID type the success
branch carries. The substrate already has canonical-ID types from
Pod 1.8.5b (sign_id, energy_id, cap_id, demod_id, signal_id; all u64
with semantic names); reusing the type-id space gives type-checking
with one new opcode family rather than five per-T variants.

**Considered alternatives:**
- (a) Type-erased Outcome with no `value_type_id` — too loose; loses
  the substrate's typed-primitive discipline at exactly the layer
  where typed errors most matter.
- (b) Per-T variants (`OP_OUTCOME_SIGN_NEW_OK`, `OP_OUTCOME_ENERGY_NEW_OK`,
  etc.) — opcode-hostile; each new typed primitive multiplies opcode
  count, exhausts the 0xE0-0xEF row, and forks user code.

**`TYPE_CODE_*` enum (sealed at 1.9.1, constants land in defines.asm at 1.9.2):**

```
TYPE_CODE_NONE     equ 0   ; sentinel — uninitialized / no-type
TYPE_CODE_SIGN     equ 1
TYPE_CODE_ENERGY   equ 2
TYPE_CODE_CAP      equ 3
TYPE_CODE_DEMOD    equ 4
TYPE_CODE_SIGNAL   equ 5
TYPE_CODE_OUTCOME  equ 6   ; Outcome wrapping Outcome (future)
```

Code 0 reserved as sentinel mirrors the canonical-ID NULL convention
(SIGN_ID_NULL = 0 etc., per Pod 1.8.5b). An Outcome with
`value_type_id = TYPE_CODE_NONE` is by definition uninitialized; the
substrate may treat such an Outcome as malformed in audit. Codes 1-6
are stable; code 7+ reserved for future canonical-ID types beyond
Sign/Energy/Cap/Demod/Signal.

`OUTCOME_ID_NULL equ 0` joins the existing null-sentinel block in
defines.asm at 1.9.2, alongside SIGN_ID_NULL, ENERGY_ID_NULL,
CAP_ID_NULL, DEMOD_ID_NULL, SIGNAL_ID_NULL.

## D1.9.1.2 — Standard 32-byte error context

Every err-Outcome carries the same 4-field error context: `error_code`
(u64), `source_op` (u64), `demod_id` (u64), `fetch_counter` (u64).
Total 32 bytes. Cache-aligned. **ProvEvent-shape-compatible** — the
ProvEvent struct from Pod 1.8.5c Move 2 is also 32 bytes with similar
fields (opcode, demod_id, fetch_counter, reserved). Errors and
provenance share buffer/serialization machinery; downstream tooling
(Pod 2 Cop, Pod 4 Interpreter) can treat both as the same audit
record shape.

**Considered alternatives:**
- (a) Variable-length error context with handle indirection — buys
  flexibility but costs a separate pool and indirection lookup. Pool
  capacity 64 means the worst-case inlined storage is 2KB; indirection
  buys nothing at V1.0 scale (D1.9.1.5).
- (b) Stringly-typed error messages — unbounded growth; Pod 3+ message
  handle routes through reserved field +0x40 the same way per-Sign
  provenance was supposed to (Pod 1.8.5c A1(d) supersession pattern).

## D1.9.1.3 — Two-mode handlers

Convention enforced by handler discipline. Each opcode handler either
fully succeeds (pushes `Outcome::ok`) or fully fails (cleans operand
stack, pushes `Outcome::err`). Substrate has no call-frame mechanism
(Pod 1.10 territory); push-error-sentinel approach makes Outcome
unreliable; convention-by-handler-discipline matches Move 1
cost-table pattern (V1.0 convention, Pod 2 hardens).

**Considered alternatives:**
- (a) VM-level stack-frame tracking with rollback on err — requires
  call-frame infrastructure that doesn't exist until Pod 1.10 (Cap
  introduces real call frames). Out-of-scope.
- (b) Push-error-sentinel without stack cleanup — breaks the "stack
  has known shape after handler" invariant; later opcodes pop the
  wrong values; cascading failures.

V1.0 ships convention; Pod 2 (Cop) hardens via runtime stack-shape
verification when the cost-table machinery is augmented with stack
discipline tracking.

## D1.9.1.4 — Five accessor opcodes at 0xE0–0xE4

Outcome's opcode allocation:

| Opcode | Hex | Stack effect | Behavior |
|--------|-----|--------------|----------|
| OP_OUTCOME_NEW_OK | 0xE0 | pop value, pop value_type_id; push outcome_id | construct ok-Outcome; discriminant=0; value at +0x10; value_type_id at +0x08 |
| OP_OUTCOME_NEW_ERR | 0xE1 | pop err_code, pop err_source_op, pop err_demod_id, pop err_fetch_counter; push outcome_id | construct err-Outcome; discriminant=1; context written to +0x20-+0x3F; auto-provenance hook fires (D1.9.1.6) |
| OP_OUTCOME_IS_OK | 0xE2 | pop outcome_id; push 1 if discriminant=0 else 0 | **consumes the outcome_id** (D1.9.1.4 A6 ratification); caller dups first to keep id available for unwrap |
| OP_OUTCOME_UNWRAP_OK | 0xE3 | pop outcome_id; if discriminant=0, push value; if discriminant=1, push sentinel + log | sentinel = 0; log via str_unwrap_ok_on_err (Pod 1.9.2) |
| OP_OUTCOME_UNWRAP_ERR | 0xE4 | pop outcome_id; if discriminant=1, push 4 fields (err_code, err_source_op, err_demod_id, err_fetch_counter); if discriminant=0, push 4 zero sentinels + log | log via str_unwrap_err_on_ok (Pod 1.9.2) |

**A6 ratification — IS_OK consumes (does not peek):** matches every
other VM accessor's stack-effect convention (pop args, push results).
Substrate has no peek-without-consume primitive. Caller pattern is
`DUP; IS_OK; <branch on result>; UNWRAP_*` — one extra opcode
(OP_DUP at 0x83) when the outcome_id needs to survive the test.

**A7 ratification — wrong-discriminant unwrap pushes sentinel + logs**
(does not fault): V1.0 has no general fault path. The whole purpose
of typed errors is to NOT halt on unexpected error. Sentinel-and-log
matches the existing accessor-null-handler pattern (registry_lookup_*
returns 0; accessor handlers push 0). Pod 2 (Cop) hardens to runtime
stack-shape verification if/when fault semantics get formalized.

Stack-effect details for UNWRAP_ERR on ok: pushes 4 zero sentinels
(matching the 4-value success-path stack delta) so downstream code's
stack shape stays predictable regardless of discriminant.

## D1.9.1.5 — Inline error context

Error context lives inside the Outcome slot, not in a separate buffer
with handle indirection. Pool capacity is 64 slots; worst-case
storage is 64 × 32 bytes = 2KB inlined. Indirection would add a
separate pool, lookup latency, and another set of registry mechanics —
all to save 2KB. The trade is not worth it at V1.0 scale.

When error message strings (Pod 3+) become a concern, they route
through the reserved +0x40 slot as a handle to a separate string
pool, the same way per-Sign provenance was supposed to route through
+0x70 before Pod 1.8.5c A1(d) reclaimed that slot. The pattern
generalizes: inline the bounded fields, route the unbounded fields
through Pod 3+ handle pools.

## D1.9.1.6 — Auto-provenance on error construction, gated

OP_OUTCOME_NEW_ERR (0xE1) calls `prov_append` after writing the err
context to the slot. The cap-gate is internal to prov_append (checks
`current_demod_prov_enabled`, default OFF per Move 2 doctrine), so
the OP_OUTCOME_NEW_ERR handler calls unconditionally — gate logic
stays in one place.

**A4.b ratification — `opcode` parameter:** pass the user-supplied
`err_source_op` (from the error context). Records the original error
origin opcode in the prov event, which is what audit consumers care
about. Passing the construction opcode (0xE1) instead would just
record "an Outcome was constructed" — already obvious from the
existence of the err-Outcome.

**A4.c ratification — `demod_id` parameter:** pass the user-supplied
`err_demod_id` (from the error context). Ties the prov event to the
demod the error was raised against. The substrate has no "current
demod" identifier today beyond the singleton placeholder
(current_demod_cost_table_ptr / current_demod_prov_enabled); the
err_demod_id from the user-supplied context is the most semantically
meaningful value available.

Wire-up shape (for Pod 1.9.2 source pod):
```
; After writing err context to slot at +0x20-+0x3F:
mov rdi, [rbx + 0x28]      ; err_source_op (user-supplied)
mov rsi, [rbx + 0x30]      ; err_demod_id (user-supplied)
mov rdx, [rel vm_fetch_count]   ; D1.9.1.7 substrate counter
call prov_append           ; cap-gate is internal; preserves rdi/rsi/rdx
```

## D1.9.1.7 — `vm_fetch_count` substrate gap closure (Pod 1.9.2)

Recon R6 surfaced that ProvEvent declares a `fetch_counter` field and
prov_append documents the corresponding parameter, but no substrate
code maintains a fetch counter today. Pod 1.8.5c shipped the
provenance conduit "for V1.0 default-OFF" so the gap was never
load-bearing; D1.9.1.6's wire-up makes it load-bearing the moment
auto-provenance is enabled (Pod 2 Cop).

**Closure plan (lands in Pod 1.9.2 source pod):**
- `boot/vmdata.asm`: add `vm_fetch_count: dq 0` storage
- `boot/cbs_vm.asm`: increment `[rel vm_fetch_count]` once per
  fetch-loop iteration, after the opcode is fetched and before
  dispatch (matches the natural counter semantics — "fetches
  executed so far")
- OP_OUTCOME_NEW_ERR handler reads `[rel vm_fetch_count]` into rdx
  for the prov_append call

The counter is also useful for substrate audit beyond D6 — Pod 2
(Cop) can use it for rate-limiting, fairness accounting, and
per-binding fetch budgets. Adding the counter at 1.9.2 instead of
deferring to "when first needed" closes the gap once and serves
multiple consumers.

**Considered alternatives** (rejected):
- (i) Pass 0 as placeholder fetch_counter — defers the gap; makes the
  prov event semantically incomplete; future Pod 2 (Cop) work has to
  add the counter anyway.
- (ii) Use `[rel energy_used]` as proxy — semantically loose; energy
  units are not fetch units; opcodes have variable cost.

Counter is monotonic u64; wraparound is not a V1.0 concern.

## D1.9.1.8 — UNWRAP-on-wrong-discriminant push-sentinel-and-log

Per A7 ratification. UNWRAP_OK on err pushes one zero (sentinel
matching the success-path 1-value push) and logs. UNWRAP_ERR on ok
pushes four zeros (sentinel matching the err-path 4-value push) and
logs. Stack shape is preserved across both discriminant paths;
downstream code does not need to test discriminant before consuming
the unwrap output (though it should — the log is audit signal that
the test was skipped).

**Suggested log strings (Pod 1.9.2 implementation):**
```
str_unwrap_ok_on_err: db '  UNWRAP_OK on Err — sentinel returned',10,0
str_unwrap_err_on_ok: db '  UNWRAP_ERR on Ok — zero sentinels returned',10,0
```

Pod 2 (Cop) may harden to runtime stack-shape verification or to a
real fault path when the substrate gets one. Until then, sentinel +
log is the convention.

---

## Slot layout (R3 confirmed verbatim, post-A1 ratification)

```
+0x00  discriminant       u64   (0=ok, 1=err)
+0x08  value_type_id      u64   (TYPE_CODE_* per D1.9.1.1)
+0x10  value              u64   (canonical ID of success value if ok; unused if err)
+0x18  reserved           u64   (Pod 3+ handle pool extension)
+0x20  err_code           u64   (D1.9.1.2; unused if ok)
+0x28  err_source_op      u64   (D1.9.1.2; unused if ok)
+0x30  err_demod_id       u64   (D1.9.1.2; unused if ok)
+0x38  err_fetch_counter  u64   (D1.9.1.2; unused if ok)
+0x40  reserved           u64   (Pod 3+ error message handle extension)
+0x48  reserved           u64
+0x50  reserved           u64
+0x58  reserved           u64
+0x60  reserved           u64
+0x68  reserved           u64
+0x70  arena_id           u64   (Pod 1.8.5c Move 3 inheritance; Pod 1.10 Cap activates)
+0x78  owner_demod_id     u64   (Pod 1.8.5c Move 3 inheritance; Pod 1.12 Demod activates)
```

Total 128 bytes (`OUTCOME_SLOT_SIZE = 0x80`). Symmetric with Sign and
Energy slots per Pod 1.8.5c A1(d) precedent.

## Pool sizing (R4 confirmed, post-A2 ratification)

```
OUTCOME_POOL_SLOTS  equ 64                                  ; Sign/Energy precedent
OUTCOME_SLOT_SIZE   equ 0x80                                ; 128 bytes
vm_outcome_pool:    times OUTCOME_POOL_SLOTS * OUTCOME_SLOT_SIZE db 0
vm_outcome_next:    dq 0                                    ; bump allocator index
outcome_registry_count:    dq 0
outcome_registry_next_id:  dq 1
outcome_registry:          times OUTCOME_POOL_SLOTS * 16 db 0  ; ~1KB; Pod 1.8.5b precedent
```

`registry_register_outcome` and `registry_lookup_outcome` follow the
Sign/Energy shape established in `boot/registry.asm` at Pod 1.8.5b.

---

## Forward-logs — what 1.9.1 does NOT seal

- Slot pool implementation (lands 1.9.2 source pod)
- Registry implementation (lands 1.9.2; inherits Pod 1.8.5b shape)
- Five opcode handlers (land 1.9.2)
- `vm_fetch_count` storage and fetch-loop increment (lands 1.9.2 per D1.9.1.7)
- TYPE_CODE_* and OUTCOME_ID_NULL constants in defines.asm (land 1.9.2)
- Sign and Energy accessor refit to return Outcome (lands 1.9.3)
- DEFERRED #13 closure (lands 1.9.3 with stack-violation refit)
- DEFERRED #16 closure (lands 1.9.3 with accessor refit)

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.9.1.1 | Tagged Outcome + TYPE_CODE_* enum (code 0 = sentinel) |
| D1.9.1.2 | 32-byte standard error context, ProvEvent-shape-compatible |
| D1.9.1.3 | Two-mode handlers, convention by discipline |
| D1.9.1.4 | Five opcodes at 0xE0–0xE4; A6 consume; A7 sentinel+log |
| D1.9.1.5 | Inline error context (no indirection at V1.0) |
| D1.9.1.6 | Auto-provenance gated; passes err_source_op, err_demod_id |
| D1.9.1.7 | vm_fetch_count substrate gap closure at 1.9.2 |
| D1.9.1.8 | UNWRAP-on-wrong-discriminant push-sentinel-and-log |

Architect ratified all eight decisions at AUTHORIZED-1.

— Terminal Boy
May 03 2026
