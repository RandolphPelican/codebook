# Pod 1.8.5c Recon Report — Conduits (Moves 1, 2, 3, 6, 7)

**Pod:** 1.8.5c — substrate-terraforming source pod (5 conduits)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75 (Pod 1.8.5b BOOTX64.EFI; preserved through 1.8.5b.5)
**Entry HEAD:** 7a82fc3befccb0a72351577e4d65807882ce6305 (Pod 1.8.5b.5 final commit)
**Scope:** boot/* (new file boot/provenance.asm proposed), tools/atreyu_x86.py, surfaces/, build chain, canon files.

---

## Section 0 — Pre-flight three-oracle

| Source | Hash | Match |
|--------|------|-------|
| `git rev-parse HEAD` | 7a82fc3befccb0a72351577e4d65807882ce6305 | ✓ |
| `git rev-parse origin/main` | 7a82fc3befccb0a72351577e4d65807882ce6305 | ✓ |
| `git ls-remote origin refs/heads/main` | 7a82fc3befccb0a72351577e4d65807882ce6305 | ✓ |

Three-oracle agrees. Build artifacts (DEFERRED #10) modified. Untracked `tools/pod185b_qemu_test.sh` carryover (housekeeping bundle deferred).

---

## R1 — Sign slot layout audit (POST-1.8.5b)

Sign slot is `SIGN_SLOT_SIZE = 0x80` = 128 bytes. Current usage map (from `boot/cbs_vm.asm` `.op_sign_new` lines 776-790):

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| 0x00 | 32 bytes | hash | full 32-byte content hash |
| 0x20 | 64 bytes | label | byte 0 = length, bytes 1-63 = chars |
| 0x60 | 8 bytes | energy_cost | u64 |
| 0x68 | 8 bytes | embedding_handle | u64; V1.0 = 0; reserved for handle pools (Pod 3+) |
| 0x70 | 8 bytes | provenance_handle | u64; V1.0 = 0; reserved |
| 0x78 | 8 bytes | "V1.1 sentinel" | u64; explicit reserved-as-0 |
| 0x80 | — | (slot end) | |

**Highest used offset:** 0x78 (8-byte field).
**First available offset for new fields:** none — slot is fully partitioned.
**Move 3 needs:** arena_id (u64) + owner_demod_id (u64) = 16 bytes appended to end.
**Verdict:** the 128-byte Sign slot has zero free bytes. arena_id + owner_demod_id will not fit without expanding `SIGN_SLOT_SIZE`.

→ Surfaces architect call **A1** (below): how to resolve.

## R2 — Energy slot layout audit

Energy slot is `ENERGY_SLOT_SIZE = 0x80` = 128 bytes. Current usage map (from `boot/cbs_vm.asm` `.op_energy_new` lines 894-901):

| Offset | Size | Field | Notes |
|--------|------|-------|-------|
| 0x00 | 8 bytes | joules (`ENERGY_OFF_JOULES`) | u64 |
| 0x08 | 8 bytes | source_op (`ENERGY_OFF_SOURCE_OP`) | u64 |
| 0x10 | 112 bytes | reserved | explicitly zeroed via 14×stosq at construction |
| 0x80 | — | (slot end) | |

**Highest used offset:** 0x08 (named field).
**First available offset for arena_id:** 0x10.
**owner_demod_id:** 0x18.
**Verdict:** Energy has 112 bytes of clean reserved space at 0x10-0x7F. arena_id + owner_demod_id fit at 0x10/0x18 with 96 bytes remaining for future expansion.

**Asymmetry vs R1:** the SGDR_TERRAFORMING estimate of "Energy reserves through 0x80 with ~48 bytes of headroom" was conservative; actual headroom is 112 bytes. Sign has zero. The **lockstep retrofit** + **single binary contract row** specification means Sign and Energy must both move; if Sign needs slot expansion, the architect's call is whether Energy expands too (for layout symmetry) or stays at 128 (for memory parity but layout asymmetry).

## R3 — Demod runtime state audit

`grep` for `demod|Demod|DEMOD` across `boot/`:

| Hit | Type |
|-----|------|
| `defines.asm:118-124` | DEMOD_ID_NULL type sentinel (Pod 1.8.5b Move 4) |
| `gmork_cmds.asm:8` | comment: "Pod 5 refactor when terminal becomes a Demod" |
| `bastian.asm:8` | comment: "Layer 3 — Surface (V1 inline; will become a Demod under Pod 5)" |
| `cbs_vm.asm:8` | comment in header |
| `energy_costs.asm:123` | comment reserving opcode row 0xE0-0xEF for Demod (Pod 1.12) |

**No formal demod-state struct exists.** Move 1's `cost_table_ptr` (and Move 2's `prov_enabled`) need a host. Per Chauncey's S8 default pattern, recommend introducing a singleton placeholder in `boot/vmdata.asm`:

```nasm
; Pod 1.8.5c — current demod runtime state (V1.0: singleton placeholder)
; Pod 1.12 (Demod<S>) replaces with real per-demod state.
current_demod_cost_table_ptr:  dq energy_cost_table  ; Move 1 host
current_demod_prov_enabled:    dq 0                   ; Move 2 cap-gate, default OFF
```

This is the simplest insertion that satisfies both moves without inventing a struct definition that Pod 1.12 would have to replace anyway.

## R4 — energy_cost_table location

| Aspect | Value |
|--------|-------|
| Symbol | `energy_cost_table` |
| File | `boot/energy_costs.asm:35` |
| Size | 256 entries × 8 bytes = 2048 bytes |
| Indexed by | opcode byte (0x00 through 0xFF) |
| Lookup function | `energy_cost_lookup` (lines 23-29): `lea rax, [rel energy_cost_table]; mov rax, [rax + rbx*8]` |

**Move 1 indirection:** swap the direct `[rel energy_cost_table]` lea for `[rel current_demod_cost_table_ptr]` deref. One additional memory read per opcode fetch. Negligible cost. Clean refactor.

## R5 — Opcode space audit (0xD4, 0xD5)

`grep` for `0xD4|0xD5` across `boot/`:
- Single hit: `boot/energy_costs.asm:119` — comment line "0xD4–0xD8 — reserved (Energy V1.1+)".
- No `%define` for either opcode in `boot/defines.asm`.
- No dispatch entry (`cmp al, OP_*`) for either in `boot/cbs_vm.asm`.

**0xD4 and 0xD5 are fully unallocated.** No conflicts. Cost-table comment reserves the 0xD4-0xD8 range to "Energy V1.1+" — Move 6 (OP_ENERGY_RECOVER at 0xD4) fits that reservation; Move 7 (OP_PHASE_QUERY at 0xD5) is structural-not-energy and reclaims the 0xD5 slot from the Energy reservation. Worth documenting in the cost-table comment.

## R6 — Boot sequence audit + phase boundaries

`boot/boot.asm` `efi_entry` (lines 66-149) sequence:

| Lines | Action | Suggested phase boundary |
|-------|--------|--------------------------|
| 66-87 | Save callee regs, capture UEFI tables (CONOUT/CONIN/BS/RT) | **SEED** (entry; set on first instruction) |
| 89-96 | Disable watchdog | (within SEED) |
| 98-107 | "Locating SFSP" message | (within SEED) |
| 109-118 | locate_sfsp + locate_gop succeed | **SEED → FORM** (after `ucs_gop_ok` print at line 118) |
| 120-142 | Splash sequence (boot screens) | (within FORM) |
| 144 | `call exit_boot_services` (ifdef NATIVE_KBD) | **FORM → CHANNELS** (after EBS returns) |
| 146-148 | Final framebuffer fill + cursor reset | (within CHANNELS) |
| 149 | `jmp bastian_home` | **CHANNELS → MODES → MIND**? (see A2 below) |

The first three transitions (SEED, FORM, CHANNELS) map cleanly. The MODES vs MIND distinction is ambiguous in the current boot sequence — there's nothing structurally between "framebuffer ready for surface" and "user can interact with home surface." Two readings:

- **Reading 1 (boot-only):** MODES = "VM is callable" (which is true the moment cbs_run is reachable, i.e. at boot.asm's tail). MIND = "user can interact" (when bastian_home enters its input loop).
- **Reading 2 (collapse):** MODES is a no-op transition for V1.0; vm_phase jumps from CHANNELS straight to MIND at the bastian_home jmp. MODES is reserved for Pod 5 (Surfaces) when actual mode-switching machinery exists.

Reading 2 is more honest for V1.0 but leaves MODES unused at runtime. Reading 1 is a design fiction. **Surfacing as architect call A2.**

`%ifdef NATIVE_KBD` complication: if `NATIVE_KBD` is undefined, `exit_boot_services` is skipped — UEFI services stay live. The phase model should still advance through CHANNELS regardless (the substrate is "in CHANNELS" semantically even if literal EBS hasn't fired). Recommend setting CHANNELS unconditionally in the same spot; flag for architect review.

## R7 — ProvEvent struct sizing

Per SGDR_TERRAFORMING: `ProvEvent = (opcode, demod_id, fetch_counter)`. Two viable layouts:

**Option A — minimum (24 bytes):**
```
offset 0x00: opcode (u8) + 7 bytes pad
offset 0x08: demod_id (u64)
offset 0x10: fetch_counter (u64)
total: 24 bytes
```
4KB ring → 170 events.

**Option B — cache-aligned (32 bytes, recommended):**
```
offset 0x00: opcode (u8) + 7 bytes pad
offset 0x08: demod_id (u64)
offset 0x10: fetch_counter (u64)
offset 0x18: reserved (u64) — future timestamp / source / outcome bits
total: 32 bytes
```
4KB ring → 128 events exactly. Power-of-2 stride; cleaner ring-buffer math (`shl idx, 5` instead of `imul idx, 24`).

**TB recommendation:** Option B. The reserved 8 bytes future-proofs against the "ProvEvent struct fields finalized when first consumer lands" deferred entry — first consumer can claim the reserved field without breaking the layout.

**Cap-flag-gating:** `current_demod_prov_enabled` (Move 2) lives in the singleton placeholder from R3. `prov_append` body checks `[rel current_demod_prov_enabled]` — if 0, returns immediately; if non-zero, writes a ProvEvent.

**Ring buffer:** `prov_ring_buf: times PROV_RING_SIZE * PROV_EVENT_SIZE db 0` in `boot/vmdata.asm`, with `prov_ring_head: dq 0` write index. Overwrite on full (head wraps). 4KB / 32 = 128 entries.

**File placement:** `prov_append` could live in `boot/cbs_vm.asm` or a new `boot/provenance.asm`. Recommend new file — provenance is a distinct concern that grows under Pod 2 (Cop) and beyond. Inserting `%include "boot/provenance.asm"` between `boot/registry.asm` and `boot/bastian.asm` in `boot/boot.asm` (matches the registry's recent insertion pattern).

## R8 — Build chain confirmation

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16) | ✓ |
| `./build.sh` × 2 | exit 0 both runs | ✓ |

**Determinism / contract:**
- Run 1 EFI sha256: `a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75` ✓
- Run 2 EFI sha256: `a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75` ✓
- ENTRY_DETERMINISM: MATCH ✓
- ENTRY_CONTRACT: MATCHES Pod 1.8.5b row in binary_contracts.md ✓

`.img` non-determinism (DEFERRED #20) still present; not relevant to contract chain.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — Sign slot expansion: how to fit arena_id + owner_demod_id

Sign slot is fully consumed at 128 bytes (R1). Move 3 needs 16 more bytes. Three viable approaches:

- **(a)** Expand both slots from 128 → 144 (`SIGN_SLOT_SIZE = ENERGY_SLOT_SIZE = 0x90`). arena_id at 0x80, owner_demod_id at 0x88, lockstep symmetric layout. Pool memory grows from 8KB → 9KB per pool. Bump allocator `shl rax, 7` (×128) becomes `imul rax, 0x90` or restructured. Cost: ~2KB extra binary. **TB recommendation.**
- **(b)** Expand both slots from 128 → 256 (`*_SLOT_SIZE = 0x100`). Power-of-2 alignment preserved (`shl rax, 8`). Doubles pool memory (8KB → 16KB per pool). Cost: ~16KB extra binary. Future-proof for more reserved fields without further expansion.
- **(c)** Asymmetric — Sign expands to 144; Energy stays at 128 with arena_id/owner_demod_id at 0x10/0x18 (fits in the existing reserved area). Memory-cheaper but layout-asymmetric across pools. Violates Chauncey's "lockstep retrofit, single binary contract row" intent.

TB recommends **(a)**. (b) is overkill for the immediate need and (c) breaks the lockstep specification.

### A2 — MODES vs MIND boundary in V1.0

Boot sequence has no clear structural distinction between "VM ready" and "user interactive" in V1.0 (R6). Two readings:

- **(R1) Boot-only**: MODES = "VM is callable" (set at boot.asm tail before bastian jmp); MIND = "user can interact" (set inside bastian_home before its input loop).
- **(R2) Collapse**: vm_phase jumps CHANNELS → MIND at the bastian_home jmp; MODES is reserved unused for Pod 5 (Surfaces).

**TB recommendation:** R2 (collapse). MODES is honest only when actual mode-switching machinery exists; design-fiction phase advancements muddy the audit signal vm_phase is supposed to provide. Forward-log a DEFERRED entry: "MODES boundary refinement when Pod 5 (Surfaces) gives MODES real semantics."

If architect prefers R1 (boot-only), set MODES at boot.asm line 148 (after framebuffer reset, before bastian_home jmp); set MIND at the head of bastian_home (which is in `boot/bastian.asm`).

### A3 — `%ifdef NATIVE_KBD` and CHANNELS placement

`exit_boot_services` is wrapped in `%ifdef NATIVE_KBD`. If NATIVE_KBD is undefined, EBS never fires — UEFI services stay live. The phase semantics ("CHANNELS = direct hardware") are then partially false.

**TB recommendation:** set CHANNELS unconditionally at line 145 (after the `%ifdef` block, regardless of whether EBS fired). The phase reflects "we're done with the EBS-eligible portion of boot" rather than literal EBS state. Document that CHANNELS does not strictly imply EBS in build configurations where NATIVE_KBD is undefined.

### A4 — ProvEvent layout: 24 bytes vs 32 bytes (cache-aligned)

Per R7. TB recommends Option B (32 bytes, cache-aligned, 128-entry ring at 4KB). Architect override possible for tighter packing if memory budget matters.

### A5 — `boot/provenance.asm` as new file vs inline in `boot/cbs_vm.asm`

Per R7. TB recommends new file. Architect can override if file-count discipline argues against new files.

---

## Section 3 — Risks identified

- **R3.1 — Slot expansion is a wider blast radius than other moves.** A1 option (a) changes the bump-allocator math in `.sign_alloc` and `.energy_alloc`. Existing canon (Pod 1.7 D1.7.6 cost values, Pod 1.8 ENERGY_SLOT_SIZE constant) referenced 128-byte slots; the constants migration is the largest single source-touch in this pod.
- **R3.2 — Per-opcode fetch overhead from Move 1.** One extra memory read per opcode (the `current_demod_cost_table_ptr` deref). Profiled negligible at V1.0 scale; flagging only.
- **R3.3 — vm_phase race in non-NATIVE_KBD build.** If UEFI services stay live and the system uses ConOut/ConIn for input, the phase model claims CHANNELS but reality is FORM. Cosmetic for V1.0; could mislead audit consumers.
- **R3.4 — ProvEvent ring buffer size is unmeasured.** 128 entries / 4KB chosen by symmetry, not measurement. Pod 2 (Cop) DeepSeek measurement (TERRAFORM-2) revisits.
- **R3.5 — OP_PHASE_QUERY lands at 0xD5 in the Energy row.** Cost-table comment will need updating to reflect the structural-not-energy occupant.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

Once architect ratifies A1-A5, Phase 2A executes S1-S9 with these adjustments locked in:

- **S1**: opcodes + vm_phase enum in defines.asm. Add `SIGN_SLOT_SIZE` / `ENERGY_SLOT_SIZE` change per A1.
- **S2**: vm_phase storage in vmdata.asm.
- **S3**: phase writes per A2 (collapse) and A3 (unconditional CHANNELS).
- **S4**: OP_PHASE_QUERY handler.
- **S5**: OP_ENERGY_RECOVER handler.
- **S6**: Sign slot retrofit per A1.
- **S7**: Energy slot retrofit per A1.
- **S8**: singleton demod state in vmdata.asm; cost-lookup indirection in energy_costs.asm.
- **S9**: ProvEvent struct + prov_append per A4/A5; new boot/provenance.asm.

Phase 2B B1 reads `BOOTX64.EFI` per the binary_contracts convention. B4 needs a new `--phase-test` build flag in atreyu_x86.py + a new `surfaces/test_phase.cbc` (architect should ratify whether to add this in scope or accept the test as a transient artifact).

---

## Section 5 — Surprises

- **S5.1 — Sign slot has zero free bytes.** This is the most consequential finding. Move 3 cannot be a pure append without slot expansion.
- **S5.2 — Energy slot has 4× the headroom SGDR_TERRAFORMING estimated.** 112 bytes free vs. ~48 expected.
- **S5.3 — `boot/registry.asm` from Pod 1.8.5b sets the precedent for new-file insertion site** between cbs_vm.asm and bastian.asm. `boot/provenance.asm` follows the same pattern.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 5 architect calls (A1-A5) surfaced.
- 5 risks surfaced (none blocking).
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
