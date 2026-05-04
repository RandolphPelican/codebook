# Pod 1.8.5b Recon Report — Canonical IDs Retrofit (Move 4)

**Pod:** 1.8.5b — Move 4 from SGDR_TERRAFORMING (canonical IDs through registry indirection for Sign and Energy accessors)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** ee50771f6802c7b5b69ba5c4af9d0393b13ced5b13b3e616a70bdf94727d4e65 (Pod 1.8 BOOTX64.EFI sha256)
**Entry HEAD:** 327bdf1c9e602e2ec79d449791aa339e89da8b99 (pressure seal)
**Scope:** boot/cbs_vm.asm, boot/defines.asm, boot/vmdata.asm, boot/boot.asm, tools/atreyu_x86.py, surfaces/, build chain, canon files.

---

## Section 0 — Pre-flight three-oracle

| Source | Hash | Match |
|--------|------|-------|
| `git rev-parse HEAD` | 327bdf1c9e602e2ec79d449791aa339e89da8b99 | ✓ |
| `git rev-parse origin/main` | 327bdf1c9e602e2ec79d449791aa339e89da8b99 | ✓ |
| `git ls-remote origin refs/heads/main` | 327bdf1c9e602e2ec79d449791aa339e89da8b99 | ✓ |

Three-oracle agrees at expected entry HEAD. (Note: `git fetch` returned a transient `Recv failure: Connection was reset` once during pre-flight; `ls-remote` succeeded on the same invocation, so the three-oracle reading is authoritative.)

Build artifacts `build/BOOTX64.EFI` and `build/codebook.img` show as modified per DEFERRED #10. Left untouched.

---

## Section 1 — R-item findings

### R1 — Accessor opcode call-site enumeration

**Sign opcodes** (`boot/defines.asm` lines 91-95, dispatched in `boot/cbs_vm.asm` lines 130-137, handlers at lines 746-886):

| Opcode | Hex | Handler | Stack effect | Current return |
|--------|-----|---------|--------------|----------------|
| OP_SIGN_NEW | 0xA0 | `.op_sign_new` (746) | pop 5 args (prov, embed, energy, label_addr, hash_addr), push 1 | **u64 sign_id** (1-based slot index in rcx) |
| OP_SIGN_HASH | 0xA1 | `.op_sign_hash` (802) | pop sign_id, push 4 qwords (32-byte hash) | hash bytes |
| OP_SIGN_LABEL | 0xA2 | `.op_sign_label` (836) | pop sign_id, push (addr, length) pair | label string ref |
| OP_SIGN_ENERGY | 0xA3 | `.op_sign_energy` (864) | pop sign_id, push energy_cost | energy_cost u64 |

**Energy opcodes** (`boot/defines.asm` lines 97-101, dispatched at lines 138-145, handlers at lines 892-975):

| Opcode | Hex | Handler | Stack effect | Current return |
|--------|-----|---------|--------------|----------------|
| OP_ENERGY_NEW | 0xD0 | `.op_energy_new` (892) | pop joules, source_op; push 1 | **u64 energy_id** (1-based slot index in rdx) |
| OP_ENERGY_JOULES | 0xD1 | `.op_energy_joules` (923) | pop energy_id, push joules | u64 joules |
| OP_ENERGY_SOURCE_OP | 0xD2 | `.op_energy_source_op` (947) | pop energy_id, push source_op | u64 source_op |
| OP_ENERGY_FREE | 0xD3 | `.op_energy_free` (971) | pop energy_id, push nothing | V1.0 no-op (consume + discard) |

**Critical finding R1.A — public ABI is already u64-id-on-stack.** Both `OP_SIGN_NEW` and `OP_ENERGY_NEW` already return a 1-based ID on the operand stack (not a slot pointer). All accessors already pop a u64 ID, validate range (1 ≤ id ≤ 64 / ENERGY_POOL_SLOTS), and arithmetically compute slot pointer via `pool_base + (id-1) * 128`.

**Move 4 is a semantic retrofit, not a public-ABI break.** The change is:
- Current: `id` ≡ `slot_index + 1` (position-derived; lookup is O(1) arithmetic; survives nothing if slots reorder)
- Move 4: `id` is opaque counter from `*_registry_next_id`; lookup is O(n) linear scan of `{id, slot_ptr}` registry entries; survives arena reorganization, demod restarts, FAT32 boundaries

Tests that consume the first allocated id (currently observe `1`) will continue to observe `1` because the registry counter also starts at 1. Tests do not need regeneration for that reason alone (see R3).

**Critical finding R1.B — opcodes named in prompt do not exist.** The prompt's R1 enumeration mentions `OP_SIGN_EMBED` and `OP_SIGN_PROV`. These opcodes are not defined anywhere in `boot/defines.asm`, `boot/cbs_vm.asm`, or `tools/atreyu_x86.py`. The Sign slot stores `embedding_handle` at +0x68 and `provenance_handle` at +0x70 (cbs_vm.asm:788-789), but no accessor opcode reads them. They are fields-without-getters at the current pod boundary. The OP_SIGN_NEW handler currently rejects (.sign_new_fail) any non-zero embedding_handle or provenance_handle (lines 765-768), enforcing a V1.0 "must be 0" contract.

→ Surfaces architect call A1 (below).

### R2 — Slot pool layout audit

**Sign pool** (`boot/vmdata.asm:20-23`):
```
vm_sign_pool:   times 64 * 128 db 0    ; 8KB, 64 slots × 128 bytes — magic numbers
vm_sign_next:   dq 0                   ; bump allocator index
```

**Energy pool** (`boot/vmdata.asm:25-28`):
```
vm_energy_pool:  times ENERGY_POOL_SLOTS * ENERGY_SLOT_SIZE db 0   ; 8KB
vm_energy_next:  dq 0                                              ; bump allocator index
```

**Pool capacity constants**:

| Pool | Slot count | Slot size | Constants in defines.asm |
|------|-----------|-----------|--------------------------|
| Sign | 64 | 128 | **none — magic numbers in vmdata.asm and sign_alloc (cbs_vm.asm:1003)** |
| Energy | ENERGY_POOL_SLOTS=64 | ENERGY_SLOT_SIZE=0x80 (128) | clean (defines.asm:106-107) |

**Allocator mechanism**: pure bump-allocator both pools. Monotonic increment of `vm_sign_next` / `vm_energy_next`. No free-list. No recycling. `OP_ENERGY_FREE` documented as V1.0 no-op (cbs_vm.asm:971-975). No external handle exposed beyond the existing slot-index-as-id.

**External handle exposure**: zero. The pools are not directly addressed by anything outside the accessor handlers in `boot/cbs_vm.asm`. Registry tables can be inserted with no other source touched.

→ Surfaces S2 deviation: prompt uses `SIGN_POOL_CAP` and `ENERGY_POOL_CAP` constant names. Actual: `ENERGY_POOL_SLOTS` exists and would be used as-is; `SIGN_POOL_CAP` does not exist and would need adding to defines.asm (proposed: `SIGN_POOL_SLOTS` for symmetry with Energy convention, plus `SIGN_SLOT_SIZE 0x80`). Will deviate from prompt naming with stated rationale unless architect prefers `*_CAP` suffix.

### R3 — Test program assumption audit

**`tools/atreyu_x86.py`** declares Sign and Energy opcodes at lines 41-50. Two demo functions:

- `demo_sign()` (lines 249-273): allocates one Sign with hash=0xAB+31×0x00, label="hello", energy=42. Asserts/prints:
  - `sign_id:` then var `s` → expects **1**
  - `energy:` then `sign_energy(s)` → expects **42**
  - `label:` then `sign_label_print(s)` → expects **hello**
  - `hash[0:8]:` then `sign_hash_first(s)` → expects **171** (0xAB)

- `demo_energy()` (lines 275-294): allocates one Energy with joules=500, source_op=0xA0. Asserts/prints:
  - `energy_id:` then var `e` → expects **1**
  - `joules:` then `energy_joules(e)` → expects **500**
  - `source_op:` then `energy_source_op(e)` → expects **160** (0xA0)

**No slot-pointer assumptions encoded in either test.** Tests treat the id as opaque and only verify field round-trip. The "expect 1" assertion is ABI-stable under both schemes (current bump-index and Move 4 registry-counter both produce 1 for first allocation in a fresh VM).

**Build flags** (lines 311-332): `--sign-build [out]` defaults output to `sign_test.cbc`; `--sign-test` is a non-writing dry-run. `--energy-build [out]` defaults output to `test_energy.cbc`; `--energy-test` dry-run.

**File-on-disk inventory** (`surfaces/`):
- `surfaces/sign_test.cbc` — exists (matches `--sign-build` default name)
- `surfaces/test_energy.cbc` — exists (matches `--energy-build` default name)
- **`surfaces/test_sign.cbc` — does NOT exist.** Prompt's Phase 2B B2 references this filename.

→ Surfaces architect call A2 (below): naming asymmetry. Either accept `sign_test.cbc` for B2 round-trip, or regenerate as `test_sign.cbc` via `--sign-build test_sign.cbc`, or rename existing file.

### R4 — Free space audit

**`boot/defines.asm`**: pure `%define` / `%define`-equivalent file (no allocated data, just preprocessor symbols). Adding the canonical-ID null-sentinel block per S1 is trivial — adds ~9 lines, zero binary impact.

**`boot/vmdata.asm`**: registry table allocation per S2:
```
sign_registry_count   = 8 bytes
sign_registry_next_id = 8 bytes
sign_registry         = 64 × 16 = 1024 bytes
energy_registry_count = 8 bytes
energy_registry_next_id = 8 bytes
energy_registry       = 64 × 16 = 1024 bytes
                      = ~2080 bytes total
```

Current vmdata.asm consumes ≈25KB (4KB stack + 2KB ret_stack + 0.5KB vars + 8KB sign + 8KB energy + 8KB mmap + headers). Section budget (`TEXT_RAWSZ` = 0x100000 = 1MB) has abundant headroom.

**`boot/boot.asm` include site**: `%include` chain at lines 366-377. Natural insertion point for `%include "boot/registry.asm"` is between `cbs_vm.asm` (line 370) and `bastian.asm` (line 371), so registry symbols are visible to opcode handlers above and to vmdata.asm declarations below.

### R5 — Build chain confirmation (WSL Ubuntu)

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 (mformat/mcopy) | ✓ |
| qemu-system-x86_64 | 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16) | ✓ |
| `./build.sh` | exit 0, both runs | ✓ |

**Determinism check (TWO RUNS, ENTRY HEAD UNMODIFIED):**

| Artifact | Run 1 sha256 | Run 2 sha256 | Match |
|----------|--------------|--------------|-------|
| `build/BOOTX64.EFI` | ee50771f6802c7b5b69ba5c4af9d0393b13ced5b13b3e616a70bdf94727d4e65 | ee50771f6802c7b5b69ba5c4af9d0393b13ced5b13b3e616a70bdf94727d4e65 | ✓ MATCH |
| `build/codebook.img` | eecadd5a1f844c59f3e81e6f80c9a46761d42e7ea0c531fae4315ba476c94746 | 86e8362ab55a0a642615825df38765ef9a7049fc69515a2e8aea5638c43e722e | ✗ MISMATCH |

**The EFI binary is deterministic and matches the Pod 1.8 entry contract verbatim.** The FAT32 image wrapper is not deterministic — almost certainly mtools `mformat` injecting a random volume serial number on each invocation. This is a pre-existing condition (latent at least since Pod 1.8 sealed), not introduced by this pod.

`binary_contracts.md` header explicitly states "Each source pod captures its post-build BOOTX64.EFI sha256 here" — convention is EFI-only. Phase 2B B1 ("./build.sh twice in succession; sha256sum both binaries. Must match.") needs to be interpreted as `BOOTX64.EFI`, not `codebook.img`.

→ Surfaces architect call A3 (below): confirm B1 targets EFI per existing convention; consider DEFERRED entry for img-wrapper non-determinism.

---

## Section 2 — Architect calls before AUTHORIZED-1

These are clarifications surfaced by recon that affect Phase 2 execution. Each blocks AUTHORIZED unless ratified or waved through.

### A1 — Sign accessor scope: HASH/LABEL/ENERGY only, or also EMBED/PROV?

The prompt's R1 enumeration mentions `OP_SIGN_EMBED` and `OP_SIGN_PROV`. Neither exists. The Sign slot has the underlying fields (embedding_handle at +0x68, provenance_handle at +0x70), but no accessor opcodes are wired and OP_SIGN_NEW currently rejects non-zero values for both.

**Two readings:**
- (a) Prompt was working from the architect's design corpus and OP_SIGN_EMBED / OP_SIGN_PROV are *intended-but-not-yet-built*. Move 4 should add them as part of this pod.
- (b) Prompt was working from a richer planned shape; current pod scope is "retrofit existing accessors only" and EMBED/PROV are deferred to whichever later pod activates handles.

**TB recommendation:** (b) — strict scope. Adding EMBED/PROV requires designing handle pool semantics (Pod 3+ per the existing comment in cbs_vm.asm:764). Move 4's stated focus is the registry retrofit; expanding scope to add new accessors raises blast radius. Defer EMBED/PROV with a DEFERRED entry to whichever pod activates handle pools.

### A2 — `surfaces/test_sign.cbc` does not exist; canonical name is `sign_test.cbc`

Prompt's Phase 2B B2 references `surfaces/test_sign.cbc`. Actual file is `surfaces/sign_test.cbc` (matching `tools/atreyu_x86.py --sign-build` default). Energy file is `surfaces/test_energy.cbc` (matching `--energy-build` default — opposite ordering).

**Three options:**
- (a) Use `sign_test.cbc` as-is for round-trip; update Phase 2B B2 reference in pod execution.
- (b) Regenerate as `test_sign.cbc` via `--sign-build test_sign.cbc`, leaving `sign_test.cbc` orphaned (or removed in same pod).
- (c) Rename surfaces/sign_test.cbc → test_sign.cbc and update `tools/atreyu_x86.py` default output filename for symmetry.

**TB recommendation:** (a) for this pod (least change), with a DEFERRED entry to standardize naming convention in a later cleanup pod. Alternatively (c) if the architect wants to absorb the cleanup now — file rename + 1-line tool change is minimal.

### A3 — B1 determinism check: target BOOTX64.EFI (per binary_contracts.md convention)

The .img wrapper is non-deterministic at entry HEAD. The .EFI is deterministic and matches the Pod 1.8 entry contract verbatim. binary_contracts.md convention is "BOOTX64.EFI sha256."

**TB recommendation:** Phase 2B B1 reads sha256sum on `build/BOOTX64.EFI`, not `build/codebook.img`. Surface the .img mismatch as a new DEFERRED entry (mtools mformat random volume serial; investigate `-N <fixed-serial>` flag in a later cleanup pod).

### A4 — `OP_ENERGY_FREE` semantics under registry indirection

Currently a V1.0 no-op (consume id, discard). Under registry indirection, the energy registry would never shrink — every freed Energy still has a registry entry (orphaned, slot_ptr still valid because pool also doesn't shrink). For V1.0 this is benign (capacity is fixed at 64); for V1.1+ it becomes pressure on registry capacity if free-list recycling lands.

**TB recommendation:** keep V1.0 no-op for OP_ENERGY_FREE in this pod. Add DEFERRED entry: "When OP_ENERGY_FREE activates recycling (Pod 1.10+ or post-V1), registry must mark the entry invalidated (slot_ptr=0 or remove entry) and `registry_lookup_energy` must return 0 (null) for invalidated entries." Same caveat applies to OP_SIGN_FREE if/when it lands.

### A5 — S2 constant naming: SIGN_POOL_SLOTS vs SIGN_POOL_CAP

Prompt's S2 uses `SIGN_POOL_CAP` and `ENERGY_POOL_CAP`. Actual existing constant: `ENERGY_POOL_SLOTS`. No `SIGN_POOL_SLOTS` exists; would need adding to defines.asm.

**TB recommendation:** add `SIGN_POOL_SLOTS 64` and `SIGN_SLOT_SIZE 0x80` to defines.asm (parity with Energy section), use `SIGN_POOL_SLOTS` and `ENERGY_POOL_SLOTS` in S2 registry-table sizing. Refactor magic numbers in vmdata.asm and sign_alloc to use the new constants in the same edit (low blast radius, improves audit hygiene).

---

## Section 3 — Risks identified

- **R3.1 — Linear scan O(n) on every accessor.** Pool capacity is 64; worst-case lookup is 64 × {compare 8 bytes, branch}. Negligible at current scale. Acceptable per prompt. Forward-logged to "Linear-scan registry lookup optimization (post-V1)."
- **R3.2 — Registry counter monotonic, never resets.** After 2^64 allocations the counter wraps. Will not happen at human timescales; flagging only for completeness.
- **R3.3 — No invalidation path.** Currently no SIGN_FREE / proper ENERGY_FREE. If those ever land, registry must support invalidation (A4 above). Not a current-pod risk; deferred.
- **R3.4 — Embedding/provenance handles still hardcoded to 0.** Move 4 does not touch this constraint. When handle pools land (Pod 3+), the handle types may want canonical-ID treatment too — `embedding_id`, `provenance_id` as additional reserved types. Worth noting for forward-log.
- **R3.5 — Determinism of registry tables.** Registry data is statically allocated (`times N db 0` in vmdata.asm) and populated only at runtime by allocator calls. Build-time output (BOOTX64.EFI) should remain deterministic; runtime state is not part of the binary. No new risk.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

Once architect ratifies the five A-calls above, Phase 2A proceeds with these adjustments locked in:

- **S1**: as written, +5 null sentinels in defines.asm.
- **S2**: rename `SIGN_POOL_CAP` → `SIGN_POOL_SLOTS`; add `SIGN_POOL_SLOTS 64` and `SIGN_SLOT_SIZE 0x80` to defines.asm; refactor magic numbers in vmdata.asm and sign_alloc.
- **S3**: `boot/registry.asm` new file. Functions:
  - `registry_register_sign(slot_ptr in rdi) -> sign_id in rax`
  - `registry_lookup_sign(sign_id in rdi) -> slot_ptr in rax (0 if not found)`
  - `registry_register_energy(slot_ptr in rdi) -> energy_id in rax`
  - `registry_lookup_energy(energy_id in rdi) -> slot_ptr in rax (0 if not found)`
  - Linear scan over registry table; ID 0 reserved; counter starts at 1.
  - `%include "boot/registry.asm"` in boot.asm between cbs_vm.asm and bastian.asm.
- **S4**: refactor 4 Sign accessors per architect ratification on A1 (default: HASH/LABEL/ENERGY only; OP_SIGN_NEW pushes registry-allocated id).
- **S5**: refactor 4 Energy accessors (NEW/JOULES/SOURCE_OP; FREE remains no-op per A4).

Phase 2B B1 reads `BOOTX64.EFI` per A3.
Phase 2B B2 uses `surfaces/sign_test.cbc` per A2 option (a), or whatever architect ratifies.

---

## Section 5 — Surprises

- **S5.1 — Public ABI is already u64-id-on-stack.** Move 4 is semantically meaningful (id semantics change from slot-position to opaque-counter, enabling future arena reorganization) but does not break any test or any consumer. The "retrofit" is more about preparing for future moves than fixing today's behavior. Worth recording in the decision record.
- **S5.2 — The .img wrapper is not deterministic, has not been since at least Pod 1.8.** binary_contracts.md only ever recorded the EFI hash; the .img non-determinism was implicitly known but never explicitly flagged in DEFERRED. Worth surfacing.
- **S5.3 — Sign predates the Energy constants discipline.** Pod 1.7 left magic numbers in vmdata.asm and sign_alloc; Pod 1.8 added named constants for Energy. Move 4 is a natural opportunity to backport the constants pattern to Sign for parity (S2 deviation A5).

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 5 architect calls (A1-A5) surfaced for ratification.
- 5 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
