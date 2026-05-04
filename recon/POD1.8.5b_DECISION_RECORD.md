# Pod 1.8.5b Decision Record — Canonical IDs Retrofit (Move 4)

**Pod:** 1.8.5b — Move 4 (canonical IDs through registry indirection for Sign and Energy)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** ee50771f6802c7b5b69ba5c4af9d0393b13ced5b13b3e616a70bdf94727d4e65 (Pod 1.8 BOOTX64.EFI)
**Exit contract:** a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75
**Entry HEAD:** 327bdf1c9e602e2ec79d449791aa339e89da8b99 (pressure seal)

---

## D1.8.5b.1 — ID 0 reserved as null sentinel

`SIGN_ID_NULL`, `ENERGY_ID_NULL`, `CAP_ID_NULL`, `DEMOD_ID_NULL`,
`SIGNAL_ID_NULL` all defined as `0` in `boot/defines.asm`. Registry
counters (`sign_registry_next_id`, `energy_registry_next_id`) start
at `1`, so no allocated ID can collide with the null sentinel.

`registry_lookup_*` functions short-circuit on `id == 0` and return
`0` (slot_ptr null) without scanning. This makes the null check
constant-time and matches the existing accessor null-handler shape
(handlers fall through to their `.*_null` labels which push 0 on the
operand stack).

**Why:** consistent null-handling discipline across the canonical-ID
type family. Future primitives (Cap, Demod, Signal) inherit the same
contract on day one.

## D1.8.5b.2 — Linear scan acceptable for V1.0

`registry_lookup_*` does an unrolled linear scan over the `{id,
slot_ptr}` registry table, comparing each entry's id field against
the input. Worst-case lookup is 64 entries × ~3 instructions per
entry = trivial at current scale. No hash table, no btree.

DEFERRED #18 forward-logs the optimization to post-V1 if profiling
shows accessor calls as a hot path. This decision is reversible
without ABI impact — `registry_lookup_*` signature stays the same,
internal mechanism can change.

**Why:** YAGNI at current pool capacity. A 64-entry linear scan is
faster than a hash-table function-call overhead at this scale.

## D1.8.5b.3 — Registry capacity matches pool capacity (1:1)

`sign_registry` is sized `SIGN_POOL_SLOTS * 16 bytes = 1024 bytes`
(64 entries × 16 bytes/entry). Same for `energy_registry` against
`ENERGY_POOL_SLOTS`. Since the slot pool is bump-allocated and never
shrinks (V1.0), the registry can never run out of room before the
pool does. `registry_register_*` does check `count >= POOL_SLOTS` and
returns 0 on overflow, but in V1.0 this branch is unreachable.

**Why:** capacities equal → no extra failure mode introduced.
`OP_SIGN_NEW` / `OP_ENERGY_NEW` already had a "pool full" failure
path; `registry_register_*` failure routes to the same path
(`.sign_new_fail` / `.energy_new_fail`). When free-list recycling
activates (Pod 1.10+ or post-V1, see DEFERRED #19), registry
invalidation becomes mandatory — at that point the 1:1 capacity
relationship is reconsidered.

## D1.8.5b.4 — Outcome error path forward-logged to Pod 1.9

When `registry_lookup_*` returns 0 (id not found), the accessor
handler currently jumps to its existing null-handler that pushes `0`
on the operand stack. This is the same behavior the pre-Move-4 code
exhibited for out-of-range slot indices.

Pod 1.9 (Outcome) introduces typed `Err(InvalidId)` results that
should replace the silent-null behavior across all canonical-ID
accessors. DEFERRED #16 forward-logs this. Move 4 does not touch the
null-handler shape because doing so would require Outcome's encoding
to land first.

**Why:** scope discipline. Move 4's job is the registry retrofit;
error-result typing is Pod 1.9's surface area.

## D1.8.5b.5 — cap_id, demod_id, signal_id reserved-not-built

`CAP_ID_NULL`, `DEMOD_ID_NULL`, `SIGNAL_ID_NULL` are added to
`boot/defines.asm` as null sentinels even though no Cap/Demod/Signal
primitives exist yet. The corresponding registry tables and
register/lookup functions are NOT created in this pod.

Pod 1.10 (Cap), Pod 1.12 (Demod), Pod 4 (Interpreter) inherit the
pattern from `boot/registry.asm` — copy the Sign/Energy function pair
shape, allocate a per-pool registry table in `boot/vmdata.asm`, route
their `OP_*_NEW` handlers through `registry_register_*` and their
accessors through `registry_lookup_*`.

**Why:** establishes the type-name convention now so future pods don't
have to re-litigate naming. ID null sentinels are 5-line additions
with zero binary impact, so the cost of reserving them today is nil.

## D1.8.5b.6 — Sign-pool constants brought to Energy-parity

Pre-Move-4: `vm_sign_pool` was `times 64 * 128 db 0` (magic numbers)
and `.sign_alloc` had `cmp rcx, 64` (magic 64). Pod 1.7 predated the
named-constants discipline that Pod 1.8 established for Energy
(`ENERGY_POOL_SLOTS`, `ENERGY_SLOT_SIZE`).

Move 4 added `SIGN_POOL_SLOTS` (64) and `SIGN_SLOT_SIZE` (0x80) to
`boot/defines.asm` and refactored `vm_sign_pool` declaration to use
them. `.sign_alloc` was NOT refactored to use `SIGN_POOL_SLOTS` in
this pod — minimizing scope creep — but the constants exist and a
later cleanup pod can drop the magic 64 in `cmp rcx, 64`.

**Why:** symmetry with Energy makes the registry-table sizing in
`vmdata.asm` parameterized by the same constants, and reduces magic
numbers in the file most-touched by this pod. Per architect call A5
in the recon report.

## D1.8.5b.7 — Public ABI is preserved; only id semantics change

Pre-Move-4: a Sign id was `slot_index + 1` (1-based, position-
derived). Lookup was `O(1)` arithmetic: `vm_sign_pool + (id-1) * 128`.
Post-Move-4: a Sign id is an opaque counter from
`sign_registry_next_id`. Lookup is `O(n)` linear scan. The id is
still a `u64` on the operand stack, still consumed by the same
accessor opcodes, still pushed by `OP_SIGN_NEW`.

For test programs that allocate one Sign and observe `sign_id == 1`,
behavior is identical (counter starts at 1). For programs that
allocate multiple Signs and observe monotonically-increasing ids,
behavior is also identical (counter monotonically increments).
Behavior diverges only when slots are reordered or recycled — which
V1.0 does not do.

**Why:** retrofit was structured to enable future arena
reorganization, demod restarts, and FAT32 boundary persistence
without breaking any current-pod test or downstream pod's assumptions.

## D1.8.5b.8 — `OP_ENERGY_FREE` stays V1.0 no-op

`OP_ENERGY_FREE` was a V1.0 no-op pre-Move-4 (consume id, discard).
Move 4 leaves it as a no-op. When free-list recycling activates
(Pod 1.10+), the registry must invalidate the freed entry — DEFERRED
#19 captures this. Per architect call A4 in the recon report.

**Why:** scope discipline; Move 4's job is the registry retrofit, not
the recycling design.

## D1.8.5b.9 — OP_SIGN_EMBED and OP_SIGN_PROV not added in this pod

Recon's R1.B finding: prompt referenced `OP_SIGN_EMBED` and
`OP_SIGN_PROV` opcodes that don't exist. Sign slots have the
underlying fields (embedding_handle at +0x68, provenance_handle at
+0x70) but no accessors expose them. `OP_SIGN_NEW` rejects non-zero
values for both, enforcing a V1.0 "must be 0" contract.

Move 4 does not add these opcodes. Adding them requires designing
handle pool semantics, which is out of scope. They are deferred to
whichever pod activates handle pools (Pod 3+). Per architect call A1
in the recon report.

**Why:** scope discipline. Adding new accessors raises blast radius
beyond the registry retrofit.

## D1.8.5b.10 — B1 determinism check targets BOOTX64.EFI per binary_contracts.md convention

`binary_contracts.md` header explicitly states "Each source pod
captures its post-build BOOTX64.EFI sha256." `codebook.img` is
non-deterministic across builds (mtools `mformat` random volume
serial; DEFERRED #20 captures this). The substantive product is the
EFI; the .img is transport.

Phase 2B B1 sha256summed `BOOTX64.EFI` twice, both runs returned
`a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75`.
Per architect call A3 in the recon report.

**Why:** continuity with existing contract chain. The .img wrapper
non-determinism is a separate and pre-existing condition with its
own deferred entry.

## D1.8.5b.11 — Test surface filename: `surfaces/sign_test.cbc` accepted as-is

Recon R3 finding: `surfaces/sign_test.cbc` exists; `surfaces/test_sign.cbc`
does not. `tools/atreyu_x86.py --sign-build` defaults output to
`sign_test.cbc`; `--energy-build` defaults to `test_energy.cbc`
(opposite ordering — pre-existing inconsistency).

Pod 1.8.5b's B2 round-trip used `sign_test.cbc` as-is (lowest blast
radius). Test passed. The naming asymmetry between Sign and Energy
test files is acknowledged but not addressed in this pod. Per
architect call A2 in the recon report.

**Why:** scope discipline. Renaming files or refactoring tool defaults
is a separate cleanup whose value does not justify the noise inside
a registry-retrofit commit.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.8.5b.1 | ID 0 = null sentinel for all canonical-ID types |
| D1.8.5b.2 | Linear scan acceptable for V1.0; optimize post-V1 if hot |
| D1.8.5b.3 | Registry capacity = pool capacity (1:1) |
| D1.8.5b.4 | Outcome error path → Pod 1.9 |
| D1.8.5b.5 | cap_id / demod_id / signal_id reserved as types only |
| D1.8.5b.6 | Sign pool gets named constants for Energy parity |
| D1.8.5b.7 | Public ABI preserved; only id semantics change |
| D1.8.5b.8 | `OP_ENERGY_FREE` stays V1.0 no-op; invalidation → free-list pod |
| D1.8.5b.9 | `OP_SIGN_EMBED` / `OP_SIGN_PROV` not added (handle-pool pod) |
| D1.8.5b.10 | B1 determinism on `BOOTX64.EFI` per binary_contracts convention |
| D1.8.5b.11 | `surfaces/sign_test.cbc` used as-is for B2 round-trip |

Architect ratified all 11 decisions via single AUTHORIZED collapsing
the three Phase 2 halts, with the recon's five A-call recommendations
serving as the defaults.

— Terminal Boy
May 03 2026
