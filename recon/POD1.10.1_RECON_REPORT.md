# Pod 1.10.1 Recon Report — Cap canon and design

**Pod:** 1.10.1 — recon-only canon pod (Cap design seal + RECONSTITUTION v10 patch)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** 3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6 (Pod 1.9.3 BOOTX64.EFI; preserved through 1.9.4 and through 1.10.1 — canon-only pod)
**Entry HEAD:** 31cd80dfeaa8011b7eb687e90f8ba0e41a26c219 (Pod 1.9.4 seal)
**Scope:** RECONSTITUTION.md, DEFERRED.md, binary_contracts.md, recon/POD1.10.1_*.md (new). No source touched.

---

## R1 — Pre-flight three-oracle

Three-oracle agrees at `31cd80dfeaa8011b7eb687e90f8ba0e41a26c219`. Build artifacts (DEFERRED #10) modified per protocol. Working tree clean — all 5 throwaway scripts gone after Pod 1.9.4 housekeeping.

## R2 — Opcode allocation range audit (LOAD-BEARING)

**Conflict surfaces enumerated:**

| Source | Claim | Authority |
|--------|-------|-----------|
| RECONSTITUTION v9 (Pod 1.9.1 patch) | Cap → 0xB0-0xBF; 0xC0-0xCF reserved | **Architect-ratified at Pod 1.9.1 v9 patch** |
| `boot/energy_costs.asm:113` | "0xB0-0xBF — unallocated (Outcome 0xB0-0xBF Pod 1.9)" | Stale; Pod 1.8.5b hint, never updated when Outcome moved to 0xE0-0xE4 |
| `boot/energy_costs.asm:115` | "0xC0-0xCF — unallocated (Cap 0xC0-0xCF Pod 1.10)" | Stale; Pod 1.8.5b hint, never canonicalized in RECONSTITUTION (DEFERRED #37 explicitly notes this drift) |

**No real opcode conflicts in either range.** Greps for `0xB[0-9A-F]` / `0xC[0-9A-F]` returned:
- `boot/cbs_vm.asm:462-589`: `0xCA000xxx` references — these are 4-byte capability tokens (DEFERRED #6 dead-code from Phase 5.1 ghost), not opcodes
- `boot/data.asm:601+`: font bitmap bytes (8-byte glyph rows), not opcodes
- `boot/energy_costs.asm:113-115`: only the stale comment lines

**TB recommendation: Cap → 0xB0-0xBF per RECONSTITUTION v9 (architect-ratified).**

Five core opcodes:
- OP_CAP_NEW = 0xB0
- OP_CAP_ENTER = 0xB1
- OP_CAP_EXIT = 0xB2
- OP_CAP_CURRENT = 0xB3
- OP_CAP_CHECK = 0xB4
- 0xB5-0xBF reserved for future Cap operations

Pod 1.10.2 source pod also corrects the two stale comments at energy_costs.asm:113 (Outcome was at 0xB0-0xBF; relocated 0xE0-0xE4 per Pod 1.9.1) and :115 (Cap moved from 0xC0-0xCF hint to 0xB0-0xBF canon). DEFERRED #37 partially closed by these corrections in Pod 1.10.2.

## R3 — Cap slot layout

Architect's draft layout exceeded 128 bytes (header 56B + reserved 72B + mirror 16B = 144B). Recon caught this. **TB recommendation: option (b)** — drop +0x70/+0x78 mirror fields for Cap because Cap is the **source of authority**, not a consumer of arena_id/owner_demod_id from current_cap context.

The mirror convention applies to consumer primitives (Sign, Energy, Outcome) that receive arena/owner from current_cap at allocation time. Cap slots don't inherit those fields from anything; they declare them.

**Final layout (128 bytes):**
```
+0x00  cap_id_self           u64   redundant copy of own ID (slot self-identification)
+0x08  arena_id              u64   the arena this cap grants authority within
+0x10  owner_demod_id        u64   the demod that owns this cap
+0x18  resource_descriptor   u64   opaque u64 the cap grants access to
+0x20  parent_cap_id         u64   delegation chain; 0 for ROOT_CAP only
+0x28  generation_counter    u64   Pod 2+ revocation; V1.0 always 0
+0x30  mac                   u64   SipHash-2-4 over fields above
+0x38  reserved              80 bytes (10 qwords) for Pod 2+ extensions
+0x80  (slot end)
```

MAC input: 6 u64 fields (cap_id_self through generation_counter) = 48 bytes. SipHash compression iterates 6 times (12 rounds @ c=2) plus 4 finalization rounds = 16 SIPROUND total.

## R4 — cap_stack semantics

`vm_ret_stack` precedent verified verbatim (boot/vmdata.asm):
```
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
```

Pointer first then 256-qword stack. cap_stack mirrors:
```
cap_stack_ptr: dq 0
cap_stack:     times 256 dq 0
```

OP_CAP_ENTER: write current_cap_id to `[cap_stack + cap_stack_ptr*8]`, increment cap_stack_ptr; set current_cap_id to popped operand.

OP_CAP_EXIT: decrement cap_stack_ptr; read prior current_cap_id from `[cap_stack + cap_stack_ptr*8]`; restore.

**Err handling:**
- cap_stack overflow at 256 entries on OP_CAP_ENTER → reuse ERR_STACK_OVERFLOW (Pod 1.9.3 D1.9.3.2 pattern); source_op=OP_CAP_ENTER disambiguates from OP_CALL overflow
- cap_stack underflow on OP_CAP_EXIT at empty stack → reuse ERR_STACK_UNDERFLOW; source_op=OP_CAP_EXIT disambiguates from OP_RET underflow

**TB recommendation: reuse existing ERR_STACK_* constants with source_op disambiguation.** Doctrine-consistent with Pod 1.9.3; avoids fragmenting err_code space; the source_op field carries the context.

## R5 — ROOT_CAP bootstrap

Substrate init sequence in `boot/boot.asm` `efi_entry`:
- Lines 67-87: UEFI table capture (CONOUT/CONIN/BS/RT)
- Lines 89-94: Pod 1.8.5c cost-table-ptr init
- Lines ~115-118: locate_sfsp, locate_gop (GOP framebuffer ready)
- Line 128: SEED → FORM phase write
- Lines ~143-145: %ifdef NATIVE_KBD exit_boot_services
- Line 158: FORM → CHANNELS
- Line 164: CHANNELS → MIND
- Line 165: jmp bastian_home

**Recommended ROOT_CAP bootstrap insertion:** between line 94 (cost-table-ptr init) and line 96 (locate_sfsp). Earliest safe point — siphash_key derivation needs RDSEED only (no UEFI), ROOT_CAP MAC computation needs siphash_key, and no cbs_run path is reachable before locate_sfsp completes.

Sequence:
1. UEFI table capture
2. Watchdog disable
3. Cost-table-ptr init (existing)
4. **NEW: siphash_key derivation (RDSEED with fallback)**
5. **NEW: ROOT_CAP slot construction (cap_id=1, arena_id=0, owner_demod_id=0, parent_cap_id=0, gen=0, MAC)**
6. **NEW: registry_register_cap(ROOT_CAP slot_ptr) — assigns cap_id=1**
7. **NEW: current_cap_id=1; current_cap_arena_id_cache=0; current_cap_owner_demod_id_cache=0; cap_stack_ptr=0**
8. locate_sfsp / locate_gop (existing)
9. (rest of boot)

Fallback warnings (RDSEED unavailable) need auryn_puts which renders to GOP framebuffer. If RDSEED probe at step 4 fails BEFORE GOP is located, the warning can't render. Two options:
- (i) Move ROOT_CAP bootstrap to after GOP setup (line 119+)
- (ii) Defer warning emission until after GOP, store entropy-source-flag in substrate state

TB recommendation: (i). Move substrate init (cost-table-ptr + siphash_key + ROOT_CAP) to after GOP location. Trade-off: substrate state initialized slightly later in boot. No code path between current init site and GOP needs the new substrate state.

## R6 — Substrate-secret RDSEED-with-fallback

**Three-tier fallback policy (TB recommendation):**

1. **RDSEED preferred** — probe via CPUID leaf 7 sub-leaf 0 EBX bit 18. If present, use rdseed instruction with bounded retry loop (64 iterations). Returns 64-bit hardware entropy.

2. **RDRAND fallback** — probe via CPUID leaf 1 ECX bit 30. RDRAND is software-accessible PRNG seeded from hardware entropy; available on older CPUs (Ivy Bridge ~2012, vs RDSEED Broadwell ~2014). Same retry pattern.

3. **Fixed key + audit log** — if both unavailable, use compile-time fixed key (e.g., 0x0123456789ABCDEF / 0xFEDCBA9876543210) and emit warning string via auryn_puts. Substrate state flag (`siphash_key_source: 0=rdseed, 1=rdrand, 2=fixed`) preserves the entropy-source decision for audit.

NASM implementation outline (~30 lines for derivation):
```
.derive_siphash_key:
    ; Probe RDSEED via CPUID
    mov eax, 7
    xor ecx, ecx
    cpuid
    bt ebx, 18                    ; RDSEED bit
    jc .have_rdseed
    ; Probe RDRAND via CPUID
    mov eax, 1
    cpuid
    bt ecx, 30                    ; RDRAND bit
    jc .have_rdrand
    ; Fall back to fixed key
    [fixed key + audit log]
    ret
.have_rdseed:
    [rdseed with retry × 2 for 128-bit key]
    mov byte [rel siphash_key_source], 0
    ret
.have_rdrand:
    [rdrand with retry × 2]
    mov byte [rel siphash_key_source], 1
    ret
```

**A-call surfaced — A1: RDSEED unavailable behavior.** TB recommends three-tier fallback. Architect alternatives: (a) hard-fail boot if RDSEED missing, (b) hard-fail if both RDSEED and RDRAND missing, (c) accept TB recommendation. Question is whether substrate boot should refuse to operate without hardware entropy.

QEMU `-cpu max` exposes RDSEED; bare-metal target depends on CPU. For Pod 1.10.2 testing the QEMU path is sufficient; for production boot on older hardware, fallback policy matters.

## R7 — SipHash-2-4 specification

**Algorithm reference:** https://www.aumasson.jp/siphash/siphash.pdf

64-bit MAC, 128-bit key, c=2 compression rounds, d=4 finalization rounds.

**Algorithm structure:**
- Initialize 4 × u64 state (v0, v1, v2, v3) from key + magic constants
- For each 8-byte chunk: XOR into v3, run 2 SIPROUND, XOR into v0
- Append length-tag byte; do final block; XOR 0xFF into v2; run 4 SIPROUND
- Return v0 XOR v1 XOR v2 XOR v3

**SIPROUND macro:** 6 ADD/XOR/ROTATE operations on the 4 state variables. Bit-rotates (rol) on 64-bit values.

**Cap MAC input: 6 u64 fields (48 bytes) = 6 compression iterations × 2 rounds = 12 rounds, plus 4 finalization rounds = 16 SIPROUND total per Cap MAC.**

**NASM implementation:** ~150 lines. Single function `siphash_compute(rdi=field_ptr, rsi=field_count_in_qwords) -> rax=mac`. Caller passes pointer to first MAC-input field (the slot's +0x00). Reads 6 qwords from there (cap_id_self through generation_counter); no length variation needed (Cap MAC always over fixed 6 qwords).

Could simplify the signature for V1.0:
```
siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac
```
Just reads 6 qwords from `[rdi + 0x00]` through `[rdi + 0x28]`. Hard-coded for Cap shape.

If future primitives need MAC, generalize to variable-length signature then.

## R8 — Existing allocator retrofit sites

Three primitive allocators to retrofit at Pod 1.10.2b:

| Allocator | Current slot writes | Retrofit |
|-----------|---------------------|----------|
| `.sign_alloc` (cbs_vm.asm) | OP_SIGN_NEW handler line 776-794: writes hash, label, energy_cost, embedding_handle=0, arena_id=0 (line 793), owner_demod_id=0 (line 794) | Replace `mov qword [rbx + 0x70], 0` and `mov qword [rbx + 0x78], 0` with reads from `[rel current_cap_arena_id_cache]` and `[rel current_cap_owner_demod_id_cache]` |
| `.energy_alloc` (cbs_vm.asm) | OP_ENERGY_NEW handler line 936-938: writes joules, source_op, arena_id=0 (+0x10), owner_demod_id=0 (+0x18) | Same shape — replace 0-writes with cache reads |
| `.outcome_alloc` (cbs_vm.asm) | OP_OUTCOME_NEW_OK / NEW_ERR handlers + Pod 1.9.3 `.construct_ok_outcome` and `.construct_err_outcome` helpers all write `[rbx + 0x70]=0` and `[rbx + 0x78]=0` | Same shape — replace 0-writes with cache reads |

**Substrate cache fields needed:** `current_cap_arena_id_cache` (u64) and `current_cap_owner_demod_id_cache` (u64). Updated alongside `current_cap_id` on OP_CAP_ENTER / OP_CAP_EXIT and at ROOT_CAP bootstrap.

**Three retrofit sites, two new substrate cache fields.** Pod 1.10.2b (handlers + retrofit) does this work; Pod 1.10.2a (substrate plumbing) lays the cache field foundations.

## R9 — Cost table extension

Per architect ratification + D1.8.5c.8 doctrine:

```
; Row 0xB0–0xBF — Cap opcodes (Pod 1.10.2 at 0xB0-0xB4)
    dq 1                    ; 0xB0 — OP_CAP_NEW (metabolic construction)
    dq 0                    ; 0xB1 — OP_CAP_ENTER (structural; cap_stack push + cache update)
    dq 0                    ; 0xB2 — OP_CAP_EXIT (structural)
    dq 0                    ; 0xB3 — OP_CAP_CURRENT (structural; read substrate state)
    dq 1                    ; 0xB4 — OP_CAP_CHECK (metabolic; SipHash crypto work per architect ratification)
    dq 1, 1, 1, 1, 1       ; 0xB5–0xB9 — reserved
    dq 1, 1, 1, 1, 1       ; 0xBA–0xBE — reserved
    dq 1                    ; 0xBF — reserved
```

Pod 1.10.2b also corrects the stale energy_costs.asm:113 comment (Outcome was at 0xB0-0xBF in v8 placeholder; relocated to 0xE0-0xE4 in v9). Net comment change: row 0xB0-0xBF now Cap, row 0xE0-0xE4 already Outcome (Pod 1.9.2b).

## R10 — RECONSTITUTION v10 patch scope

Bounded patch (4 edits):
1. Header v9 → v10; "Why v10 exists" subsection (Cap canon)
2. Opcode allocation table line 322 (Cap row) — already says `0xB0-0xBF | Cap<R> | 1.10-1.11`; gets cleanup of "(reserved; was Outcome v8 placeholder; relocated v9)" line at 323 — that placeholder text was added in v9 and can stay or be removed. TB recommendation: keep as historical signal.
3. Cap subsection (post-v9 placeholder): add canonical D1.10.1 definition (slot layout, opcodes, decisions, ROOT_CAP bootstrap, SipHash crypto, cap_stack, strict delegation, forward-log to 1.10.2)
4. Pod arc Pod 1.10 row split into 1.10.1 / 1.10.2a / 1.10.2b

Out-of-scope drift items (DEFERRED #37 — Pod 1.5.5 hash, Pod 1.8 hash placeholder, missing 1.8.5-1.9.4 sub-pod rows) stay deferred per Pod 1.9.4 D1.9.4.2 scope-discipline ratification.

## R11 — Build chain confirmation

| Tool | Version | Status |
|------|---------|--------|
| nasm | 2.16.01 | ✓ |
| mtools | 4.0.43 | ✓ |
| qemu-system-x86_64 | 8.2.2 | ✓ |
| `./build.sh` × 1 | exit 0 | ✓ |

EFI sha256: `3bfb0c0a2410e90c9aa9d5def1c598ec26d6c058d68c73cf67cb2da5e737fff6` — matches Pod 1.9.3 row exactly. Single build sufficient since canon-only pod doesn't touch source.

---

## Section 2 — Architect calls before AUTHORIZED-1

### A1 — RDSEED unavailable behavior (per R6)

Three options:
- **(i) TB recommendation: three-tier fallback** (RDSEED → RDRAND → fixed key + audit log). Substrate boots regardless of hardware capability; entropy-source flag preserved in substrate state for audit.
- (ii) Hard-fail if RDSEED missing. Substrate refuses to boot on pre-Broadwell hardware. Stronger crypto guarantee; weaker hardware portability.
- (iii) Hard-fail only if both RDSEED and RDRAND missing. Middle ground; rejects only ancient hardware (pre-2012).

QEMU `-cpu max` has RDSEED; tests pass under (i)/(ii)/(iii). Production boot on bare metal is the differentiator.

### A2 — Slot layout option (b) (per R3)

Architect's draft was 144 bytes (overflows 128-byte slot). TB recommends option (b) — drop the +0x70/+0x78 mirror fields for Cap because Cap is the source of authority, not a consumer. Architectural rationale: Cap declares arena_id/owner_demod_id at +0x08/+0x10; the mirror fields at +0x70/+0x78 in other primitives carry the values inherited from current_cap at allocation time. Cap doesn't inherit; it declares. Mirrors don't apply.

Confirm or override.

### A3 — siphash_compute signature (per R7)

TB recommends V1.0-specific signature: `siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac`, hard-coded for 6-qword Cap MAC input. Generalize to variable-length signature only when a future primitive needs MAC over different-shaped data.

Confirm or override (architect may prefer general signature for forward-compatibility).

---

## Section 3 — Risks identified

- **R3.1 — A1 (RDSEED policy) is load-bearing.** Different policies have different production-boot consequences. Pod 1.10.2 implementation depends on which option is ratified.
- **R3.2 — Cap slot layout drops mirror convention.** Pod 1.10.2b allocator retrofit assumes Sign/Energy/Outcome retain the mirror fields. Cap-specific layout deviation must be explicit in canon for Pod 1.12 (Demod) inheritance — Demod typed primitive may also be source-of-authority shape.
- **R3.3 — energy_costs.asm has two stale comment lines.** Pod 1.10.2b corrects both as part of cost-table extension. Deferred today; flagged to ensure 1.10.2b doesn't miss the cleanup.
- **R3.4 — current_cap_arena_id_cache / current_cap_owner_demod_id_cache** are new substrate state. Pod 1.10.2a lays them; Pod 1.10.2b consumes them in allocator retrofit. The cache must be updated on every OP_CAP_ENTER / OP_CAP_EXIT or allocations get stale arena/owner. Atomicity not a concern in single-threaded V1.0; Pod 2 (Cop) inherits cache discipline.

---

## Section 4 — Phase 2 execution gates (post-AUTHORIZED-1)

S1: write `recon/POD1.10.1_DECISION_RECORD.md` with 14 D-numbered entries
S2: RECONSTITUTION v10 patch (4 edits per R10)
S3: append binary_contracts.md row (preserved)
S4: append DEFERRED entries #53-#56 (verify next-available)

Phase 3: stage 5 files (RECONSTITUTION.md, DEFERRED.md, binary_contracts.md, recon/POD1.10.1_DECISION_RECORD.md, recon/POD1.10.1_RECON_REPORT.md), commit with no-BOM message, push, three-oracle.

---

## Section 5 — Surprises

- **S5.1 — Architect's draft layout was 144 bytes, exceeding the 128-byte slot.** Recon caught this at R3. Option (b) emerges as the architecturally-honest fix: Cap is source of authority, doesn't carry mirror fields. The draft layout was a mechanical inheritance of the layout convention without realizing Cap's semantic role inverts it.
- **S5.2 — RECONSTITUTION v9 already places Cap at 0xB0-0xBF.** R2 surfaced that the energy_costs.asm comment at line 115 is the stale source, not RECONSTITUTION. Architect's ratified canon (v9) is correct; source-side comments need cleanup at Pod 1.10.2b.
- **S5.3 — Cap activates dormant fields — substrate-maturity unlock.** D1.10.1.8 captures this. Sign/Energy/Outcome have been carrying placeholder zero arena_id/owner_demod_id at +0x70/+0x78 since Pod 1.8.5c. Pod 1.10.2b's retrofit makes those fields meaningful for the first time. The substrate has been waiting for Cap to activate the whole arena/owner mechanism.

---

## Section 6 — HALT 1 status

- All R-items completed.
- No source files modified.
- No commits staged.
- 3 architect calls (A1 load-bearing for RDSEED policy; A2/A3 simpler).
- 4 risks surfaced.
- 3 surprises surfaced.

**HALT 1 — awaiting AUTHORIZED.**

— Terminal Boy
May 03 2026
