# Pod 1.10.1 Decision Record — Cap canon and design

**Pod:** 1.10.1 — recon-only canon pod (Cap design seal + RECONSTITUTION v10 patch)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (Pod 1.9.3 BOOTX64.EFI; preserved through 1.9.4 and 1.10.1)
**Exit contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (preserved; canon-only pod)
**Entry HEAD:** 31cd80dfeaa8011b7eb687e90f8ba0e41a26c219 (Pod 1.9.4 seal)

---

## D1.10.1.1 — Cap slot layout (128-byte symmetric, no mirror fields)

Cap slot layout fits in 128 bytes per Pod 1.8.5c A1(d) precedent. Per
A2 ratification: **Cap drops the +0x70/+0x78 arena/owner mirror fields
that other primitives carry**, because Cap is the source of authority,
not a consumer of it.

```
+0x00  cap_id_self           u64   redundant copy of own ID for slot self-identification
+0x08  arena_id              u64   the arena this cap grants authority within
+0x10  owner_demod_id        u64   the demod that owns this cap
+0x18  resource_descriptor   u64   opaque u64 the cap grants access to; per-application meaning
+0x20  parent_cap_id         u64   delegation chain; 0 for ROOT_CAP only
+0x28  generation_counter    u64   Pod 2+ revocation support; V1.0 always 0
+0x30  mac                   u64   SipHash-2-4 over fields above
+0x38  reserved              80 bytes (10 qwords) for Pod 2+ extensions
+0x80  (slot end)
```

**Source-of-authority vs consumer-primitive distinction.** Sign,
Energy, Outcome are consumers — they receive arena_id/owner_demod_id
from current_cap context at allocation time and store the inherited
values at +0x70/+0x78. Cap declares those values at +0x08/+0x10. There
is nothing for Cap to inherit from; the mirror would be self-redundant.

**Pod 1.12 (Demod) inheritance note:** Demod is also a candidate
source-of-authority primitive. demod_id is itself the identifier in
arena/owner pairs; demod slots may also drop the +0x70/+0x78 mirror.
Pod 1.12 recon ratifies whether Demod is consumer-shape (inherits
mirrors) or source-shape (drops them) based on whether demods can
themselves be created under a parent cap context.

## D1.10.1.2 — Opcode allocation: Cap → 0xB0-0xBF per RECONSTITUTION v9

Five core opcodes:
- OP_CAP_NEW = 0xB0
- OP_CAP_ENTER = 0xB1
- OP_CAP_EXIT = 0xB2
- OP_CAP_CURRENT = 0xB3
- OP_CAP_CHECK = 0xB4
- 0xB5-0xBF reserved for future Cap operations (delegation revocation,
  per-arena queries, generation-counter advance, etc.)

RECONSTITUTION v9 (Pod 1.9.1 patch) already places Cap at 0xB0-0xBF.
Stale `boot/energy_costs.asm:113` ("Outcome 0xB0-0xBF") and `:115`
("Cap 0xC0-0xCF Pod 1.10") are documentation drift surfaced at R2;
Pod 1.10.2b corrects both during cost-table extension. RECONSTITUTION
v9 stays the authoritative source.

## D1.10.1.3 — Five core opcodes with cost classification

| Opcode | Hex | Cost | Classification | Stack effect |
|--------|-----|------|----------------|--------------|
| OP_CAP_NEW | 0xB0 | 1j | metabolic construction | pop resource_descriptor + arena_id + owner_demod_id; push outcome_id (Outcome<cap_id>) |
| OP_CAP_ENTER | 0xB1 | 0j | structural — cap_stack push + cache update | pop cap_id; push nothing |
| OP_CAP_EXIT | 0xB2 | 0j | structural — cap_stack pop + cache restore | pop nothing; push nothing |
| OP_CAP_CURRENT | 0xB3 | 0j | structural — read substrate state | pop nothing; push current_cap_id |
| OP_CAP_CHECK | 0xB4 | 1j | metabolic — SipHash crypto | pop cap_id + expected_arena_id + expected_owner_demod_id; push 1 if MAC valid AND arena matches AND owner matches; 0 otherwise |

Cost classification follows Pod 1.8.5c D1.8.5c.8 / Pod 1.9.2b D1.9.2b.1
doctrine: substrate state queries and bookkeeping = 0j; construction
work and crypto = metabolic. CHECK at 1j flat rather than computed
because SipHash work is bounded (16 SIPROUND iterations) and per-opcode
flat cost matches the existing model. Pod 2 (Cop) may refine to a
cryptographic cost class if useful.

## D1.10.1.4 — cap_stack semantics (256-entry parallel to vm_ret_stack)

Substrate state additions:
```
cap_stack_ptr: dq 0
cap_stack:     times 256 dq 0
```

OP_CAP_ENTER: write current_cap_id to `[cap_stack + cap_stack_ptr*8]`,
increment cap_stack_ptr; set current_cap_id to popped operand and
update cache fields.

OP_CAP_EXIT: decrement cap_stack_ptr; read prior current_cap_id from
`[cap_stack + cap_stack_ptr*8]`; restore current_cap_id and cache
fields.

**Err handling reuses Pod 1.9.3 ERR_STACK_* constants:**
- cap_stack overflow at 256 entries on OP_CAP_ENTER → ERR_STACK_OVERFLOW;
  source_op=OP_CAP_ENTER (0xB1) disambiguates from OP_CALL (0x50)
  overflow
- cap_stack underflow on OP_CAP_EXIT at empty stack → ERR_STACK_UNDERFLOW;
  source_op=OP_CAP_EXIT (0xB2) disambiguates from OP_RET (0x53)
  underflow

The source_op field carries context; err_code stays generic. Doctrine-
consistent with Pod 1.9.3 D1.9.3.2 / D1.9.3.3.

## D1.10.1.5 — ROOT_CAP bootstrap

Substrate init creates ROOT_CAP at cap_id=1 with field values:
- cap_id_self = 1
- arena_id = 0 (substrate self-arena)
- owner_demod_id = 0 (substrate self-ownership)
- resource_descriptor = 0
- parent_cap_id = 0 (no parent; ROOT only)
- generation_counter = 0
- mac = SipHash-2-4(siphash_key, fields_above) computed at boot

current_cap_id initialized to 1. current_cap_arena_id_cache initialized
to 0. current_cap_owner_demod_id_cache initialized to 0. cap_stack_ptr
initialized to 0 (ROOT_CAP is the implicit base; not on the stack).

**Bootstrap insertion site:** after GOP framebuffer is located in
boot.asm efi_entry (so RDSEED-fallback fail messages can render via
auryn_puts), and before any cbs_run-callable code path. Recommended
insertion between locate_gop success and SEED→FORM phase write — moves
the Pod 1.8.5c cost-table-ptr init alongside the new substrate-init
block (siphash_key derivation + ROOT_CAP construction + current_cap_id
init). Pod 1.10.2a determines exact line.

## D1.10.1.6 — Substrate-secret RDSEED-with-RDRAND-fallback (A1 option iii)

Per architect ratification of A1 option (iii). Boot probes:
1. **RDSEED** via CPUID leaf 7 sub-leaf 0 EBX bit 18. If present, use
   `rdseed rax` instruction with bounded retry loop (64 iterations) for
   each of two u64 entries (128-bit key total). `siphash_key_source = 0`.
2. **RDRAND** via CPUID leaf 1 ECX bit 30 if RDSEED unavailable. RDRAND
   is software-accessible PRNG seeded from hardware entropy; available
   on Intel Ivy Bridge (~2012) and later. `siphash_key_source = 1`.
3. **Hard-fail** if both unavailable. Substrate emits fail message via
   auryn_puts ("FATAL: RDSEED and RDRAND unavailable — substrate
   refuses to boot without hardware entropy") and HALTs before MIND
   phase advancement. No fixed-key fallback tier — **a cryptographic
   capability system with a known-fixed key isn't cryptographic**.

Per-boot key regeneration; no persistence. **Caps don't survive
reboot.** A program storing cap_id values across reboots gets all-Err
on subsequent boots when the new boot's MAC doesn't match — correct
V1.0 semantic. Persistent capability database is a future pod concern.

Substrate refuses to boot on pre-2012 hardware; modern hardware
(Intel Ivy Bridge / AMD Ryzen / etc.) is supported. QEMU `-cpu max`
exposes both RDSEED and RDRAND so test environment is unaffected.

## D1.10.1.7 — SipHash-2-4 over 6 u64 fields (V1.0-specific signature)

SipHash-2-4: 64-bit MAC, 128-bit key, c=2 compression rounds, d=4
finalization rounds. Algorithm reference:
https://www.aumasson.jp/siphash/siphash.pdf

Cap MAC input: 6 u64 fields (cap_id_self, arena_id, owner_demod_id,
resource_descriptor, parent_cap_id, generation_counter) = 48 bytes.
Six compression iterations × 2 rounds = 12 rounds, plus 4 finalization
rounds = 16 SIPROUND total per Cap MAC computation.

**V1.0-specific signature per A3 ratification:**
```
siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac
```

Reads 6 qwords from `[rdi + 0x00]` through `[rdi + 0x28]`. Hard-coded
for Cap shape. NASM implementation ~150 lines including state init,
compression loop, finalization.

**Forward-log:** generalize to variable-length signature
(`siphash_compute(rdi=field_ptr, rsi=field_count_in_qwords)` or similar)
when a second use case appears (Pod 1.12 Demod authenticity? Pod 2 Cop
arbitrary-data MAC?). Until then, the V1.0-specific hard-coded shape
is simpler and easier to verify.

## D1.10.1.8 — Cap activates dormant arena/owner in existing primitives

**Substrate-wide elegance unlock.** Sign, Energy, Outcome have been
carrying placeholder zero arena_id/owner_demod_id at +0x70/+0x78 since
Pod 1.8.5c Move 3. Pod 1.10.2b's allocator retrofit makes those fields
meaningful for the first time:

| Allocator | Pre-1.10.2b behavior | Post-1.10.2b behavior |
|-----------|----------------------|------------------------|
| `.sign_alloc` | writes 0 to +0x70, 0 to +0x78 | reads from `[rel current_cap_arena_id_cache]` and `[rel current_cap_owner_demod_id_cache]` |
| `.energy_alloc` | writes 0 to +0x10 (arena), 0 to +0x18 (owner) | reads from cache fields |
| `.outcome_alloc` (via `.construct_ok_outcome` and `.construct_err_outcome`) | writes 0 to +0x70, 0 to +0x78 | reads from cache fields |

**Substrate state cache fields** (added at Pod 1.10.2a):
- `current_cap_arena_id_cache: dq 0`
- `current_cap_owner_demod_id_cache: dq 0`

Cache fields mirror current_cap slot's +0x08 and +0x10 for fast access
(avoid registry lookup on every allocation). Updated alongside
current_cap_id on OP_CAP_ENTER, OP_CAP_EXIT, and ROOT_CAP bootstrap.

**The substrate has been waiting for Cap to activate the whole
arena/owner mechanism.** D1.10.1.8 is the architectural moment when
the dormant fields wake up. Every subsequent typed-primitive allocation
inherits arena/owner from the current cap context, making sandboxed
execution patterns expressible at substrate level.

## D1.10.1.9 — OP_CAP_NEW returns Outcome<cap_id> per Path A

Path A semantics from Pod 1.9.3 D1.9.3.1 inherit cleanly. OP_CAP_NEW
constructs success Outcome::Ok via `.construct_ok_outcome` helper
(Pod 1.9.3) wrapping the new cap_id; failure constructs Err via
`.construct_err_outcome`. value_type_id = TYPE_CODE_CAP=3 (already
reserved at Pod 1.9.2a per D1.9.1.1).

Failure paths and their err_codes:
- siphash_key not initialized (substrate-init-incomplete) → ERR_POOL_FULL
  with source_op=OP_CAP_NEW (substrate state error; reusing closest
  existing err_code)
- vm_cap_pool exhausted → ERR_POOL_FULL
- cap_registry exhausted → ERR_POOL_FULL (capacities matched at 64)
- arena_id or owner_demod_id exceeds parent cap's authority (strict
  delegation violation per D1.10.1.12) → new ERR_CAP_AUTHORITY_EXCEEDED
  defined in Pod 1.10.2a (constant value 7)

## D1.10.1.10 — cap_id space and pool sizing

cap_id space:
- 0 = CAP_ID_NULL (sentinel; parallels SIGN_ID_NULL etc.)
- 1 = ROOT_CAP (substrate-bootstrap; only cap with parent_cap_id=0)
- 2+ = user allocations from OP_CAP_NEW

CAP_POOL_SLOTS = 64 (matches existing pool capacity convention from
Sign/Energy/Outcome). CAP_SLOT_SIZE = 0x80 (128 bytes). Bump-allocator
with no free-list per existing pattern; OP_CAP_FREE not in scope for
V1.0.

CAP_ID_NULL = 0 added to defines.asm null-sentinel block at Pod 1.10.2a
(was already reserved as type code at Pod 1.8.5b but not as a NULL
sentinel constant).

## D1.10.1.11 — OP_CAP_CHECK = authenticity + authorization

Per architect ratification. OP_CAP_CHECK pops three values (top-down):
expected_owner_demod_id, expected_arena_id, cap_id. Performs:
1. **Authenticity:** registry_lookup_cap(cap_id) → slot_ptr (0 if
   invalid id). If invalid, push 0 (treats invalid as "not authorized"
   per Pod 1.9.2b D1.9.2b.7 doctrine).
2. Recompute MAC over slot's 6 u64 fields via
   `siphash_compute_cap_mac(slot_ptr)`. Compare against stored MAC at
   `[slot_ptr + 0x30]`. If mismatch, push 0.
3. **Authorization:** compare slot's arena_id against expected_arena_id
   and owner_demod_id against expected_owner_demod_id. If either
   mismatches, push 0.
4. Otherwise push 1 (authentic AND authorized).

This single-opcode design makes the check meaningful for sandboxed
execution patterns. A typed program holding an opaque cap_id can
verify in one operation that the cap is real (MAC-checked), genuinely
delegated (registry-resolved), AND grants authority over the specific
arena/owner pair the program needs. Forging a cap_id requires forging
the MAC, which requires the siphash_key — substrate-internal and
per-boot.

## D1.10.1.12 — Strict delegation in V1.0

Per architect ratification. OP_CAP_NEW always derives from current_cap
(no "anywhere-cap" or super-user mode in V1.0). Behavior:
1. Read current_cap_id; lookup current_cap slot.
2. Pop user-supplied resource_descriptor + arena_id + owner_demod_id.
3. **Strict delegation check:**
   - If user-supplied arena_id ≠ current_cap.arena_id, push Err with
     ERR_CAP_AUTHORITY_EXCEEDED. (V1.0 doesn't support sub-arena
     delegation; child cap inherits parent's arena exactly.)
   - Similarly for owner_demod_id.
4. Allocate new cap slot with parent_cap_id = current_cap_id;
   arena_id = inherited; owner_demod_id = inherited;
   resource_descriptor = user-supplied; generation_counter = 0;
   compute MAC.
5. Register, return Outcome<cap_id>.

**Holding a cap genuinely transfers authority along the delegation
chain.** Pod 2 (Cop) can extend with sub-arena delegation, owner-pair
relaxation, or revocation via generation_counter advancement. V1.0
ships strict-delegation real capability semantics — not a placeholder.

**Pod 1.12 (Demod) inheritance note:** Demod registration likely uses
the same strict-delegation pattern — a demod registers under the
current_cap's authority. Pod 1.12 recon confirms.

## D1.10.1.13 — Substrate state additions

Pod 1.10.2a lays the following substrate state in `boot/vmdata.asm`:

| Symbol | Size | Purpose |
|--------|------|---------|
| `vm_cap_pool` | 8KB (64 × 128) | bump-allocated Cap slots |
| `vm_cap_next` | 8B | bump allocator index |
| `cap_registry_count` | 8B | active count |
| `cap_registry_next_id` | 8B | id counter (starts at 1; ROOT_CAP claims this on bootstrap) |
| `cap_registry` | 1KB (64 × 16) | id → slot_ptr table |
| `cap_stack_ptr` | 8B | active count for cap_stack |
| `cap_stack` | 2KB (256 × 8) | parallel to vm_ret_stack |
| `current_cap_id` | 8B | initialized to 1 (ROOT_CAP) at boot |
| `current_cap_arena_id_cache` | 8B | mirrors current_cap.arena_id |
| `current_cap_owner_demod_id_cache` | 8B | mirrors current_cap.owner_demod_id |
| `siphash_key` | 16B | 128-bit key derived at boot via RDSEED/RDRAND |
| `siphash_key_source` | 1B (qword-aligned) | 0=rdseed, 1=rdrand |

Total new substrate state: ~11.1 KB. Plus new `boot/cap.asm` file
(~250 lines: `registry_register_cap` + `registry_lookup_cap` + SipHash
implementation + ROOT_CAP construction helper).

## D1.10.1.14 — Pod 1.10.2 split: 1.10.2a substrate / 1.10.2b handlers + retrofit + tests

Pattern matches Pod 1.9.2 split (Pod 1.9.2a substrate plumbing /
Pod 1.9.2b opcode handlers + tests).

**Pod 1.10.2a — substrate plumbing:**
- CAP_ID_NULL constant in defines.asm
- 5 OP_CAP_* opcode constants in defines.asm
- ERR_CAP_AUTHORITY_EXCEEDED constant
- Substrate state per D1.10.1.13 in boot/vmdata.asm
- New file `boot/cap.asm` with registry functions, SipHash, ROOT_CAP
  bootstrap helper
- ROOT_CAP construction wired into boot.asm efi_entry
- siphash_key derivation block in boot.asm efi_entry (RDSEED → RDRAND
  → fail-and-halt per D1.10.1.6)
- No opcode handlers, no dispatch entries, no allocator retrofit, no
  tools changes
- Cross-asset constant verification per D1.9.2b.10: opcode constants
  land here in substrate-plumbing pod (not handler pod)

**Pod 1.10.2b — handlers + retrofit + tests:**
- 5 opcode handlers in boot/cbs_vm.asm + dispatch entries
- Cost table extension in boot/energy_costs.asm + cleanup of stale
  comments at lines 113 and 115
- Allocator retrofit (3 sites: .sign_alloc, .energy_alloc,
  .outcome_alloc) to read current_cap cache fields per D1.10.1.8
- Tools support in tools/atreyu_x86.py (5 opcodes + AST handlers +
  demos + CLI flags)
- Test surfaces (TBD count): test_cap_new.cbc, test_cap_enter_exit.cbc,
  test_cap_check.cbc, test_cap_delegation.cbc, test_cap_invalid_check.cbc,
  test_arena_owner_inheritance.cbc (verifies D1.10.1.8 retrofit)
- Sign/Energy regeneration regression to confirm canaries still hold
  under retrofitted allocators (174j, 53j discipline continues)

The split keeps each pod's commit footprint reviewable. Pod 1.10.2a
ships ~400 lines of new asm; Pod 1.10.2b ships handlers + retrofit + 6+
test surfaces.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.10.1.1 | Cap slot layout 128B; drops mirror fields per A2 (source-of-authority) |
| D1.10.1.2 | Opcode allocation Cap → 0xB0-0xBF per RECONSTITUTION v9 |
| D1.10.1.3 | 5 core opcodes; OP_CAP_NEW + CHECK = 1j metabolic; ENTER + EXIT + CURRENT = 0j structural |
| D1.10.1.4 | cap_stack 256-entry; ERR_STACK_* reuse with source_op disambiguation |
| D1.10.1.5 | ROOT_CAP at cap_id=1; bootstrap after GOP setup, before MIND phase |
| D1.10.1.6 | RDSEED→RDRAND→hard-fail per A1; siphash_key_source flag |
| D1.10.1.7 | SipHash-2-4 over 6 u64 fields; V1.0-specific signature per A3 |
| D1.10.1.8 | Cap activates dormant arena/owner in Sign/Energy/Outcome |
| D1.10.1.9 | OP_CAP_NEW returns Outcome<cap_id> per Path A; TYPE_CODE_CAP=3 |
| D1.10.1.10 | cap_id space: 0=null, 1=ROOT, 2+=user; CAP_POOL_SLOTS=64 |
| D1.10.1.11 | OP_CAP_CHECK = authenticity + authorization (architect-ratified) |
| D1.10.1.12 | Strict delegation in V1.0 (architect-ratified) |
| D1.10.1.13 | Substrate state additions enumerated (~11.1 KB total) |
| D1.10.1.14 | Pod 1.10.2 split: 1.10.2a substrate / 1.10.2b handlers+retrofit+tests |

Architect ratifications:
- Strict delegation, RDSEED-per-boot, authenticity+authorization, 1j
  metabolic flat for crypto: pre-recon ratification baked in
- A1 (RDSEED→RDRAND→hard-fail), A2 (drop mirrors for Cap), A3
  (V1.0-specific siphash signature): ratified at AUTHORIZED-1

— Terminal Boy
May 03 2026
