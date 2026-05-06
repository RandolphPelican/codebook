# Pod 3 Recon Report — Maid is born (substrate-prep: Embedding typed primitive)

**Pod:** 3 — first substrate-USE pod after seven pods of substrate-EVOLUTION
**Entry HEAD:** ec0899bf6e79cb5f9586357a2f825248bbe79478 (Pod 2.2 seal — Babylon's vocabulary)
**Entry binary contract:** 0f598ec585245820da7d1cf89d6611cd80cb3327b76da74e5fe35c7590ccdb5f (verified via two-build determinism)
**Recon date:** 2026-05-05

---

## R1 — Pre-flight three-oracle

```
HEAD:        ec0899bf6e79cb5f9586357a2f825248bbe79478
origin/main: ec0899bf6e79cb5f9586357a2f825248bbe79478
ls-remote:   ec0899bf6e79cb5f9586357a2f825248bbe79478  refs/heads/main
```

Three-oracle agreement at Pod 2.2 seal. No drift. Pre-existing housekeeping deferral state per DEFERRED #10 / #59 / #62 / #67 / #70 / #74 / #78 / #79 unchanged.

---

## R2 — Identifier audit

Tree-wide grep for `\b(EMBEDDING|embedding|VECTOR|vector|f32|float32|F32|FLOAT32)\b` in `boot/`: **single match**.

```
boot/cap.asm:262: ; Verifies SipHash-2-4 against Aumasson published vector at boot.
```

This is a comment in cap.asm referencing SipHash test vectors (cryptographic terminology — false match on "vector"). Not a substrate identifier.

**No collisions with existing names.** Fresh territory for `EMBEDDING_*`, `OP_EMBEDDING_*`, `vector[]` field, `f32` typing.

`embedding_handle` token appears only in:
- `boot/cbs_vm.asm:837, 860, 887, 911, 914, ...` — comments documenting Pod 1.10.2b2 reclaim history
- `boot/defines.asm:226-231` — comment block for SIGN_OFF_CREATOR_CAP_ID explaining it was "reclaimed from embedding_handle slot"
- `tools/atreyu_x86.py:263, 265` — `# embedding_handle (V1.0: always 0)` hardcoded literal in `_sign_new` emitter

No active embedding_* consumers. Fresh territory confirmed.

---

## R3 — Type code + opcode + bit + error code enumeration

### TYPE_CODE_* (boot/defines.asm:265-271)
```
TYPE_CODE_NONE     = 0
TYPE_CODE_SIGN     = 1
TYPE_CODE_ENERGY   = 2
TYPE_CODE_CAP      = 3   ; reserved for Pod 1.10
TYPE_CODE_DEMOD    = 4   ; reserved for Pod 1.12
TYPE_CODE_SIGNAL   = 5   ; reserved for Pod 4
TYPE_CODE_OUTCOME  = 6   ; reserved for Outcome wrapping Outcome
```
**Next-available: 7.** TB ratifies architect prior **TYPE_CODE_EMBEDDING = 7**. (A1 ✓)

### OP_* range 0xC0-0xCF (boot/defines.asm + boot/cbs_vm.asm dispatch table)
- `defines.asm` OP_* declarations: rows 0xA*, 0xB0-0xBA, 0xD0-0xD8, 0xE0-0xE7. **No 0xC* opcode declarations.**
- `cbs_vm.asm` dispatch table (lines 90-211 region): zero `cmp al, 0xC*` matches.
- Confounder: `0xCA000001` / `0xCA000002` / `0xCA000003` / `0xCA000004` appear as **32-bit cap-token tags** in legacy demo dispatch (boot/cbs_vm.asm:626-635 — auryn_display / gmork_conin / morla_fs / rockbiter cap-token namespace from Pod 0). These are 32-bit values starting with byte 0xCA, **not single-byte opcode allocations**. Separate namespace; no collision with single-byte opcode 0xC0-0xCF range.

**Range 0xC0-0xCF clean.** TB ratifies architect priors:
```
OP_EMBEDDING_NEW       = 0xC0
OP_EMBEDDING_ARENA     = 0xC1
OP_EMBEDDING_OWNER     = 0xC2
OP_EMBEDDING_CREATOR   = 0xC3
OP_EMBEDDING_GET_DIM   = 0xC4
; 0xC5–0xCF reserved for Pod 3.5+ semantic ops
```
(A2 ✓)

### BIT_* (boot/defines.asm:193-196)
```
BIT_SIGN_FORGE     = (1 << 0)   ; 0x01
BIT_ENERGY_FORGE   = (1 << 1)   ; 0x02
BIT_OUTCOME_FORGE  = (1 << 2)   ; 0x04
BIT_CAP_FORGE      = (1 << 3)   ; 0x08
```
**Bit 4 unclaimed.** TB ratifies **BIT_EMBEDDING_FORGE = (1 << 4) = 0x10**. (A3 ✓)

### ERR_* (boot/defines.asm:130-137)
```
ERR_INVALID_ID                  = 1
ERR_POOL_FULL                   = 2
ERR_STACK_UNDERFLOW             = 3
ERR_STACK_OVERFLOW              = 4
ERR_INVALID_SIGN_ARG            = 5
ERR_INVALID_ENERGY_ARG          = 6
ERR_CAP_AUTHORITY_EXCEEDED      = 7   (Pod 2.2 activated)
ERR_CAP_INSUFFICIENT_AUTHORITY  = 8   (Pod 2.2)
```
**Next-available: 9.** TB ratifies architect prior **ERR_INVALID_EMBEDDING_ARG = 9**. (A4 ✓)

---

## R4 — Sign slot layout audit (LOAD-BEARING DISCREPANCY)

**Architect Pre-A10 claim:** *"Field at Sign slot offset +0x00 (in MAC-input range; existing layout). Pre-Pod-3 semantics: always-0 placeholder, no validation."*

**In-tree reality (boot/cbs_vm.asm:833-843; SIGN_SLOT_SIZE = 0x80 = 128 bytes):**
```
+0x00 hash[32]              — full content hash (32 bytes, occupies +0x00..+0x1F)
+0x20 label[64]             — byte 0 = length, bytes 1-63 = chars (occupies +0x20..+0x5F)
+0x60 energy_cost (u64)     — at +0x60..+0x67
+0x68 creator_cap_id (u64)  — Pod 1.10.2b2 RECLAIMED from former embedding_handle slot
+0x70 arena_id (u64)        — Pod 1.8.5c RECLAIMED from former provenance_handle slot
+0x78 owner_demod_id (u64)  — Pod 1.8.5c RECLAIMED from former V1.1 sentinel slot
```

**Sign slot has NO embedding_handle field anywhere.** The slot field at +0x68 named "embedding_handle" in v3 manifesto / RECONSTITUTION.md was reclaimed at Pod 1.10.2b2 (`SIGN_OFF_CREATOR_CAP_ID = 0x68` per defines.asm:226). Sign slots are also **not MAC-protected** in V1.0 (no SipHash; integrity model differs from Cap).

**OP_SIGN_NEW operand-stack ABI (cbs_vm.asm:850-866) preserves 5-arg shape:**
```
Pop sequence (top-down):
  r8  = (formerly provenance_handle; now silently discarded)
  r9  = embedding_handle    ← currently validated == 0; rejected if non-zero
  r10 = energy_cost
  r11 = label_addr
  rbx = hash_addr
```

Lines 887-889 verbatim:
```asm
; Validate embedding_handle: must be 0 in V1.0 (handle pools land Pod 3+)
test    r9, r9
jnz     .sign_new_fail_invalid_arg
```

The opcode preserves an embedding_handle position in its 5-arg ABI, validates to zero, but **never writes the value to any slot field**. The arg is discarded post-validation.

**Architect's resolution model needs adjudication.** Pre-A10 / Pre-A11 / R7.b assume `Sign.embedding_handle` exists as a slot field. It doesn't. Three resolution options per DEFERRED #65:

- **(a) Slot expansion** to 136/256 bytes — architect explicitly rejected ("no byte-layout change to Sign slot")
- **(b) Side-table indexed by sign_id** — embedding_handle lives in a parallel BSS array
- **(c) Out-of-line lookup table** — variant of (b)

For B12 (T6 "Read Sign's embedding_handle accessor") to work end-to-end, the storage AND a reader-opcode are both needed. Surface as **A7** below.

**Canon doc lag (Surprise 1):** RECONSTITUTION.md line 235 still says `0x68 8 embedding_handle (u64; index into vm_embed_pool, defined Pod 3+)`. Pre-Pod-1.10.2b2 spec; outdated. Pod 3 canon update should refresh.

---

## R5 — Embedding pool/registry pattern research

Existing typed-pool conventions (consolidated):

| Primitive | Allocator | Registry register | Registry lookup | Init pattern |
|---|---|---|---|---|
| Sign | `.sign_alloc` (cbs_vm.asm:2301) | `registry_register_sign` (boot/registry.asm:28) | `registry_lookup_sign` (boot/registry.asm:54) | BSS auto-zero; bump allocator vm_sign_next |
| Energy | `.energy_alloc` (cbs_vm.asm:2280) | `registry_register_energy` (boot/registry.asm:79) | `registry_lookup_energy` (boot/registry.asm:~100) | Same |
| Outcome | `.outcome_alloc` (cbs_vm.asm:2263) | `registry_register_outcome` (boot/outcome.asm:29) | `registry_lookup_outcome` (boot/outcome.asm) | Same |
| Cap | inline in OP_CAP_NEW handler | `registry_register_cap` (boot/cap.asm:144) | `registry_lookup_cap` (boot/cap.asm:~164) | + `construct_root_cap` boot-time |

**Pattern observation:** allocator labels live in cbs_vm.asm (dot-prefixed local labels in the dispatch namespace); registry register/lookup functions live in primitive-specific files (boot/registry.asm for Sign+Energy, boot/outcome.asm for Outcome, boot/cap.asm for Cap).

**Architect S2 directive (new boot/embedding.asm) is sound.** TB recommends:
- BSS: `vm_embedding_pool times EMBEDDING_POOL_SLOTS resb EMBEDDING_SLOT_BYTES` + `vm_embedding_next dq 0` in vmdata.asm (matches existing pool data residence)
- `embedding_alloc` as a dot-prefixed local label `.embedding_alloc` in cbs_vm.asm (matches Sign/Energy/Outcome allocator residence) OR as top-level in boot/embedding.asm (matches Cap pattern); recommend **cbs_vm.asm placement** for consistency with Sign/Energy (closest semantic peers)
- `registry_register_embedding` + `registry_lookup_embedding` in **boot/embedding.asm** (matches outcome.asm / cap.asm pattern; new file justified by per-primitive separation)
- No construct_root_embedding; embeddings are program-driven (no boot-time auto-construction)

**Pool init in MIND-phase init sequence:** existing pools rely on BSS auto-zero + counter-init at boot. No explicit `*_pool_init` function is called for Sign/Energy/Outcome (BSS .bss section is zero-initialized by loader; counters at fixed addresses also auto-zero). Cap calls `construct_root_cap` at MIND-phase entry but that's the ROOT_CAP construction, not pool init. **Embedding doesn't need any init function.** BSS allocation in vmdata.asm handles it.

---

## R6 — Inline 1536-byte vector emission

`OP_PUSH_STR` length encoding: u16 (2 bytes; emitted via `e.emit_u16(...)`). Existing usage:
- Sign hash inline: `e.emit_u16(32)` (32 bytes)
- Sign label inline: `e.emit_u16(64)` (64 bytes)

Maximum representable length: **65535 bytes** (2^16 - 1). 1536 bytes for an Embedding vector fits trivially (~2.3% of max).

Verified against `tools/atreyu_x86.py:215-227`:
```python
e.emit(OP_PUSH_STR); e.emit_u16(32)
e.code.extend(hash_data[:32].ljust(32, b'\x00'))
e.emit(OP_DROP)         # drop len, keep addr (hash_addr)
```

Pattern extends cleanly to 1536 bytes:
```python
e.emit(OP_PUSH_STR); e.emit_u16(1536)
e.code.extend(vector_bytes[:1536].ljust(1536, b'\x00'))
e.emit(OP_DROP)
```

No alignment requirement (PUSH_STR pushes the data address; consumer handles alignment if needed). No constraint surfaces. (A6 ✓)

---

## R7 — OP_EMBEDDING_NEW handler insertion plan

Architect R7 plan reviewed against tree conventions. Per-step:

1. **Pop vector_addr** (single sub r13, 8; mov to register — likely rbx or r10 to match Sign pattern)
2. **Bit-check** for BIT_EMBEDDING_FORGE: push/pop vector_addr across `babylon_check_authority` call (helper preserves r12-r15, rbx, rbp; clobbers rax, rcx, rsi, rdi). If using rbx for vector_addr, no push/pop needed.
3. **Allocate slot** via `.embedding_alloc` (returns slot_ptr in rax; 0 if pool full)
4. **Write header fields** at slot offsets per Pre-A4 layout:
   - cap_id_self preserved 0 until registry assigns
   - arena_id from `[rel current_cap_arena_id_cache]`
   - owner_demod_id from `[rel current_cap_owner_demod_id_cache]`
   - creator_cap_id from `[rel current_cap_id]`
5. **Copy vector content**: rep movsb 1536 bytes from [vector_addr] to [slot + EMBEDDING_OFF_VECTOR]; preserve vector_addr in caller-saved register before the rep movsb (rep movsb clobbers rsi, rdi, rcx)
6. **SipHash MAC over 196 qwords** (header 4 + vector 192) via `siphash_compute(rdi=slot_ptr, rsi=EMBEDDING_MAC_INPUT_QWORDS=196)`; store at `slot + EMBEDDING_OFF_MAC` (+0x620)
7. **registry_register_embedding** assigns embedding_id (returns in rax; 0 if registry full)
8. **Stamp embedding_id_self** at slot +0x00 with the registry-assigned id
9. **Path A wrap** via `.construct_ok_outcome` (rdi=embedding_id, r8=TYPE_CODE_EMBEDDING) — single fire site for babylon_charge_lineage per D2.2.10 axiom inherited at greenfield (D3.9)
10. **Failure routes:**
    - `.embedding_new_pool_full` → ERR_POOL_FULL via .construct_err_outcome
    - `.embedding_new_insufficient_authority` → ERR_CAP_INSUFFICIENT_AUTHORITY via .construct_err_outcome
    - (No defensive `.embedding_new_invalid_arg` needed unless vector_addr can be malformed; rep movsb doesn't validate source — caller's responsibility. ERR_INVALID_EMBEDDING_ARG stays defined for OP_EMBEDDING_GET_DIM dim_index OOB.)

**Mac-stamp ordering note:** stamp embedding_id_self BEFORE siphash compute (since id is in the MAC-input range at offset +0x00). Architect R7 step 5/7 ordering should swap: first registry_register_embedding to get id, then write id to slot, then siphash, then store mac. TB confirms this matches the Cap pattern (boot/cbs_vm.asm:1457-1486 pre-Pod-2.2 / current `.op_cap_new` performs registry first, stamps id, then siphash). Restated:

```
1. Pop vector_addr
2. Bit-check (BIT_EMBEDDING_FORGE)
3. Pool capacity check (vm_embedding_next < EMBEDDING_POOL_SLOTS)
4. Allocate slot (.embedding_alloc)
5. Pre-write embedding_id_self placeholder = 0; arena/owner/creator; copy vector
6. registry_register_embedding → returns embedding_id
7. Stamp embedding_id_self at +0x00 with the assigned id
8. siphash_compute over 196 qwords; store MAC at +0x620
9. .construct_ok_outcome wrap; push outcome_id; jmp .fetch
```

This matches the Cap pattern exactly. (TB-corrected ordering surfaces as a small mechanical-completeness adjustment to architect R7.)

---

## R7.b — Sign embedding_handle validation insertion (pending A7 adjudication)

**Current state:** OP_SIGN_NEW (lines 850-935) pops embedding_handle into r9 (line 860), validates to zero (lines 887-889), rejects non-zero. Never written to slot.

**Pod 3 retrofit (CONTINGENT on A7 storage decision):**

If A7 ratifies **option (b) side-table** (TB recommendation):
1. Replace `test r9, r9 / jnz .sign_new_fail_invalid_arg` with non-zero branch:
   - If r9 == 0: skip validation, continue (backward-compat for embedding_handle=0)
   - If r9 != 0: registry_lookup_embedding(r9); if rax == 0, route to `.sign_new_invalid_embedding` via .construct_err_outcome with ERR_INVALID_ID, source_op=OP_SIGN_NEW
2. After registry_register_sign returns sign_id, write embedding_handle (r9) to side-table at index sign_id-1 (or sign_id if 1-indexed registry)
3. Add OP_SIGN_EMBEDDING_HANDLE accessor (likely 0xA7 — next-available in Sign opcode range; 0xA0-0xA6 used per defines.asm:92-99)
4. Side-table BSS: `vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0` in vmdata.asm
5. Side-table indexing helper `embedding_handle_for_sign(sign_id) → embedding_handle | 0` mirrors registry_lookup pattern

**Per-site live-register preservation:** in OP_SIGN_NEW, embedding_handle is in r9 post-pop. r9 must survive label-len validation, hash copy, label copy, registry_register_sign call, then be written to side-table after registry returns sign_id. Verify `.sign_alloc` and `registry_register_sign` callee-save conventions preserve r9. **Likely needs explicit push/pop bracket** if any of those calls clobber r9 (TB confirms at HALT 2A read).

If A7 ratifies option (a) slot expansion or option (c) out-of-line table, R7.b plan adjusts accordingly.

---

## R8 — Build chain confirmation

**Tool versions** (WSL Ubuntu):
```
NASM version 2.16.01                                     ✓ matches Pod 2.2
mcopy (GNU mtools) 4.0.43                                ✓ matches
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16)  ✓ matches
```

**Two-build determinism on Pod 2.2 entry contract:**
```
build1 sha256: 0f598ec585245820da7d1cf89d6611cd80cb3327b76da74e5fe35c7590ccdb5f
build2 sha256: 0f598ec585245820da7d1cf89d6611cd80cb3327b76da74e5fe35c7590ccdb5f
```

Both builds byte-identical to Pod 2.2 sealed contract. Build chain ready.

---

## R9 — Affected test surface enumeration

### Sign-forging surfaces with embedding_handle != 0
**Zero.** All existing Sign demos use the emitter's hardcoded `embedding_handle = 0` push at `tools/atreyu_x86.py:265`:
```python
e.emit(OP_PUSH); e.emit_i64(0)     # embedding_handle (V1.0: always 0)
```
TB confirmed via grep — no AST `'embedding_handle': N` literal exists in any demo. Architect prior matches.

### Outcome / Cap / Energy regression
Zero ripple expected. Pod 3 doesn't touch their handlers. The changes to OP_SIGN_NEW (per R7.b) only affect Sign-forging surfaces; tests that don't use Sign forge are byte-identical.

### Sign-forging surfaces with embedding_handle = 0 default
**Bytecode-shape question:** does `_sign_new` emitter's argument signature change?

Architect S7 directive: *"_sign_new emit method: extend to accept `embedding_handle` parameter (default 0 for backward-compat); push as i64 instead of hardcoded 0"*.

If the default stays 0, the emitted bytes are identical (push 0 either way). Sign-forging surfaces with no `'embedding_handle'` AST key get byte-identical output. **Zero ripple confirmed for default case.**

### New Pod 3 surfaces (T1-T7)
Per architect B-item plan:
1. T1 test_embedding_new_basic
2. T2 test_embedding_accessor_round_trip
3. T3 test_embedding_invalid_id
4. T4 test_embedding_authority_check_passes
5. T5 test_embedding_authority_check_fails
6. T6 test_sign_with_embedding (DEFERRED #65 cash)
7. T7 test_sign_invalid_embedding_handle

**Total: 7 new surfaces, 0 modified prior-pod surfaces.** Architect estimate matches.

---

## A-call surfaces with TB recommendations

### A1 — TYPE_CODE_EMBEDDING
**Architect prior:** likely 7. **TB confirms:** TYPE_CODE_EMBEDDING = 7 (next-available after OUTCOME=6). **Ratify.**

### A2 — 0xC0-0xCF range availability
**TB confirms:** Range clean; no single-byte opcode allocations. (32-bit cap-token tags 0xCA00000X are different namespace.) **Ratify.**

### A3 — BIT_EMBEDDING_FORGE bit position
**TB confirms:** Bit 4 (1 << 4 = 0x10) unclaimed. **Ratify.**

### A4 — ERR_INVALID_EMBEDDING_ARG numeric value
**TB confirms:** 9 next-available. **Ratify.**

### A5 — OP_EMBEDDING_NEW operand-stack canary
Deferred to B15 (Phase 2B) — demo doesn't exist yet. TB constructs minimal embedding_new under ROOT, measures joule cost. Architect adjudicates if math implies cost basis other than the 100j Sign-class content-bearing primitive convention.

### A6 — Inline 1536-byte vector emission
**TB confirms:** OP_PUSH_STR u16 length-prefix (max 65535) handles 1536 cleanly. No alignment constraint surfaced. **Ratify.**

### A7 — Sign embedding_handle storage location (NEW, LOAD-BEARING)

Architect Pre-A10 / Pre-A11 / R7.b assume `Sign.embedding_handle` is a slot field at offset +0x00. **In-tree reality: Sign slot has no embedding_handle field anywhere** (Pod 1.10.2b2 reclaim per R4 finding). Three storage options per DEFERRED #65:

- **(a) Slot expansion** to 136 or 256 bytes — disrupts SIGN_SLOT_SIZE=128 alignment; architect explicitly rejected at Pre-A10 ("No byte-layout change to Sign slot")
- **(b) Side-table indexed by sign_id** — `vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0` BSS array; OP_SIGN_NEW writes after registry_register_sign returns sign_id; new OP_SIGN_EMBEDDING_HANDLE accessor (likely 0xA7) reads from side-table
- **(c) Out-of-line lookup table** — variant of (b); same shape, different dispatch

**TB recommends option (b) — side-table.** Rationale:
- Preserves SIGN_SLOT_SIZE=128 (no architectural disruption)
- Matches existing storage doctrine: Sign slots aren't MAC-protected in V1.0; embedding_handle's integrity model matches Sign's (substrate-private; tampering requires substrate compromise which equally compromises slots)
- Supports B12 architectural moment (DEFERRED #65 cash) via OP_SIGN_EMBEDDING_HANDLE accessor reading from side-table at sign_id index
- Mechanically simplest — analogous to how Cap registry mirrors slot pointers

OP code allocation for OP_SIGN_EMBEDDING_HANDLE: **0xA7** next-available in Sign range (0xA0-0xA6 used). Architect ratifies value.

**This is the load-bearing recon surface for HALT 1 architect adjudication.**

---

## Surprises

### Surprise 1 — RECONSTITUTION.md canon doc lag

`RECONSTITUTION.md:235` says `0x68    8       embedding_handle   (u64; index into vm_embed_pool, defined Pod 3+)`. This is **pre-Pod-1.10.2b2 spec**; outdated since `SIGN_OFF_CREATOR_CAP_ID = 0x68` (Pod 1.10.2b2 reclaim; defines.asm:226). Canon doc didn't update at Pod 1.10.2b2 seal.

Pod 3 canon update (RECONSTITUTION v12 or update-in-place) should refresh:
- Sign slot layout reflects current (creator_cap_id at 0x68, no embedding_handle slot field)
- Embedding storage decision per A7 ratification (side-table)
- OP_SIGN_EMBEDDING_HANDLE accessor at 0xA7

### Surprise 2 — Architect Pre-A10/Pre-A11/R7.b coordinates assumption

Architect prompt states "Field at Sign slot offset +0x00 (in MAC-input range; existing layout)." Both:
- The OFFSET is wrong (+0x00 is hash, not embedding_handle)
- The very EXISTENCE of the field as a slot-resident value is wrong (reclaimed at Pod 1.10.2b2; no slot field exists)

This is the **ninth empirical instance** of architect-detail-error doctrine (D2.2.11 family at sixth/seventh/eighth empirical landings). Subtype: slot-layout-state staleness — architect referenced canon-doc-stale state rather than current tree. Recon caught the discrepancy; A7 surfaces resolution.

### Surprise 3 — B12 implicit accessor scope

Architect B12 says *"TBD: does Sign have an OP_SIGN_EMBEDDING_HANDLE accessor, or does the test inspect via different means?"* — combined with R4/A7 finding that embedding_handle has no slot field, and combined with B12's requirement to read embedding_handle back as 1 to validate the linkage, **a new opcode OP_SIGN_EMBEDDING_HANDLE is mandatory** for Pod 3 scope. Likely 0xA7 next-available in Sign range.

This expands Pod 3's S3 scope: not just `.op_embedding_*` handlers but also `.op_sign_embedding_handle`. Mechanically small (5-line stub via accessor pattern) but architecturally relevant — Sign opcode count grows to 8 (0xA0-0xA7).

### Surprise 4 — R7 step ordering

Architect R7 step 5 ("Write header fields ... embedding_id_self from registry pre-assignment") implies registry happens before slot writes. Cap pattern actually does the reverse: write placeholder id (0), copy content, MAC stamp, registry_register, then stamp the assigned id back into slot, then siphash_compute over the now-stamped slot. Either ordering works mechanically (registry is just a pool index assignment), but consistency with `.op_cap_new` (cbs_vm.asm:1524-1592 region) is cleaner. TB-corrected ordering surfaces as small mechanical clarification at R7 above.

---

## HALT 1 conclusion

**The load-bearing recon surface is A7 — Sign embedding_handle storage adjudication.** Architect Pre-A10 / Pre-A11 / R7.b assume a slot field that doesn't exist (reclaimed at Pod 1.10.2b2). TB recommends side-table option (b) with new OP_SIGN_EMBEDDING_HANDLE accessor at 0xA7. Architect ratifies at AUTHORIZED-1.

Other A-calls (A1-A4, A6) ratify architect priors. A5 (canary measurement) defers to B15.

Substrate state at HALT 1: ec0899bf sealed; build chain deterministic at 0f598ec5...; range 0xC0-0xCF + bit 4 + ERR=9 + TYPE_CODE=7 all clean for Embedding allocation; Sign slot layout has no embedding_handle field (Pod 1.10.2b2 reclaim) — DEFERRED #65 resolution shape needs A7 ratification before Phase 2A source changes can begin.

Awaiting **AUTHORIZED-1**. Stand by.
