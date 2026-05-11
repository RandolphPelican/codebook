# Pod 3.11 Recon Notes — "Maid maintains" (codebook metadata accessors) sit prep

**Status:** Informal recon notes for HALT 1 architect ratification. NOT a formalized recon report. Eight findings + recommendations surfaced for sit-time call before any code lands.

**Entry HEAD:** 9772b34ab7811d45d314355dcc33e7c580358b32 (Pod 3.10 SEAL — Maid orthogonalizes)
**Entry contract:** b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981 (canonical Pod 3.10 BOOTX64.EFI)
**Three-oracle:** ✓ HEAD = origin/main = ls-remote at 9772b34
**Identifier audit:** META / codebook_meta accessor / OP_EMBEDDING_CODEBOOK_META / 0xF5 — zero canonical matches in tree as user-surface ops ("META" only appears in ROCKBITER_METABOLIC comment + decision-record retrospectives; `vm_codebook_meta` BSS block exists from Pod 3.8 D3.30 but has no dispatch accessor)
**Build chain:** unchanged (NASM 2.16.01 / mtools 4.0.43 / QEMU 8.2.2 in WSL)

**Framing context** (per architect): Pod 3.11 path (c) ratified — codebook metadata accessors (light, completes codebook read surface). Paths (a) aggregation and (b) multi-codebook deferred to V2.0 per empirical-pressure discipline (D3.16). Pod 3.11 estimated 5-7 chunks to SEAL.

**Existing substrate state for codebook surface** (Pod 3.8):
- `vm_codebook_meta` — 64-byte BSS block at known address (populated by `boot_ingest_codebook` per D3.31)
- 4 user-relevant qword fields: `CBK_META_OFF_COUNT=0`, `CBK_META_OFF_DIM=8`, `CBK_META_OFF_SCALAR_TYPE=16`, `CBK_META_OFF_INGESTION_STATUS=24`
- 16-byte `CBK_META_OFF_PAYLOAD_HASH=32` (substrate-runtime integrity; build-tool/CI artifact per D3.30)
- 16-byte `CBK_META_OFF_RESERVED=48` (future expansion)
- Status constants: `CBK_STATUS_NOT_RUN=0`, `_SUCCESS=1`, `_ERR_BAD_MAGIC=2`, `_ERR_BAD_DIM=3`, `_ERR_POOL_FULL=4`, `_ERR_OTHER=255`

---

## Q1 — Op surface scope

**Two paths:**

### (a) Single OP_*_META(field_index) accessor
One opcode; one handler; pops `field_index`, validates `< 4`, reads `vm_codebook_meta + field_index*8`, wraps as Outcome::Ok. Mirrors IMPORTED_HANDLE (0xF1) / SYNTHESIS_HANDLE (0xCF) / GET_DIM (0xC4) — the established **GET_DIM-style parameterized accessor** convention.

### (b) Multiple distinct ops (OP_*_COUNT / OP_*_DIM / OP_*_STATUS / OP_*_SCALAR_TYPE)
Four opcodes; four handlers; each pops zero operands and reads a single field. More discoverable for user code (no field_index lookup table needed); each op self-describes.

**Tradeoff audit:**

| Concern | (a) Single accessor | (b) Multiple ops |
|---|---|---|
| Substrate code | ~30-line handler (one) | ~30-line handlers × 4 = ~120 lines |
| Opcode slots consumed | 1 (0xF5) | 4 (0xF5–0xF8) |
| Convention alignment | matches GET_DIM / IMPORTED_HANDLE / SYNTHESIS_HANDLE family (3 prior witness accessors) | departs from established pattern |
| User-code discoverability | requires field_index constants documented at atreyu surface (`META_FIELD_COUNT=0`, etc.) | natural names per op |
| Atreyu emitter ergonomics | one parameterized emit (`embedding_codebook_meta(field_index=0)`) | four named emitters (`embedding_codebook_count()`, ...) |
| Future expansion to new fields | extend field_index range (no opcode burn) | new opcode per new field |

**TB recommendation: (a) single OP_*_META(field_index) accessor.** Rationale:

- **Convention continuity over discoverability micro-optimization**: GET_DIM-style parameterized accessor is the substrate's canonical pattern for "read field N of structured state." Three prior witness accessors (Pod 3, 3.6, 3.8) follow this pattern; Pod 3.11 inherits without precedent break.
- **Opcode-slot conservation**: 0xF5–0xFE row has 10 slots remaining; (b) burns 4 for one logical feature (codebook metadata access). (a) reserves slots for genuinely-distinct ops (multi-codebook activation per #91; aggregation per #92; etc.).
- **Atreyu emitter cleanliness**: parameterized emit (`embedding_codebook_meta(field_index=N)`) matches existing `embedding_imported_handle` / `embedding_synthesis_handle` / `embedding_get_dim` emitter shapes; user-code legibility is preserved via documented field-index constants at the atreyu level (`META_FIELD_COUNT=0`, `META_FIELD_DIM=1`, etc.).
- **Future expansion**: if Pod 3.X+ adds more metadata fields (build-time timestamp, ingestion duration, etc.), they slot into reserved field_index range without new opcode burn.

The "discoverability" argument for (b) is real but cosmetic — atreyu emitter naming covers the discoverability axis at the user-code surface; substrate-level multi-op proliferation is the wrong layer to fix it.

---

## Q2 — Naming prefix

**Two paths:**

### (a) OP_EMBEDDING_CODEBOOK_META (within OP_EMBEDDING_* family)
Codebook metadata is a property of the embedding subsystem (the codebook is what produced the embedding pool). Naming continuity with OP_EMBEDDING_IMPORT / OP_EMBEDDING_IMPORTED_HANDLE.

### (b) OP_CODEBOOK_META (new type-prefix)
Codebook is conceptually a separate substrate entity from embeddings (per Pod 3.8 D3.32 codebook surface asymmetry — codebook is *production* layer, embeddings are *runtime* layer). New type-prefix matches the conceptual separation.

**Tradeoff audit:**

| Concern | (a) OP_EMBEDDING_CODEBOOK_META | (b) OP_CODEBOOK_META |
|---|---|---|
| D3.34 row alignment | matches "embedding-tier extensions" framing | breaks row's type-prefix uniformity |
| Naming hierarchy | OP_EMBEDDING_* family extends naturally | introduces new top-level prefix in row |
| User-code legibility | longer name; clear domain | shorter; ambiguous w.r.t. typed pool? |
| Constant prefix space | shares CBK_META_OFF_* (existing Pod 3.8) | symmetric with CBK_* constants |
| Service-tier classification | maintenance-tier within embedding family | new tier (codebook-tier; distinct service) |

**TB recommendation: (a) OP_EMBEDDING_CODEBOOK_META.** Rationale:

- **D3.34 reframe directly applies**: Pod 3.9 D3.34 widened the 0xF0–0xFE row scope from Pod 3.8's "codebook-tier" to "embedding-tier extensions." The reframe explicitly absorbs codebook ops into the embedding-tier framing; Pod 3.11 inherits this scope.
- **Row uniformity preserved**: 0xF0 OP_EMBEDDING_IMPORT / 0xF1 OP_EMBEDDING_IMPORTED_HANDLE / 0xF2 OP_EMBEDDING_LOOKUP_TOP_K / 0xF3 OP_EMBEDDING_PROJECT / 0xF4 OP_EMBEDDING_REJECT — all OP_EMBEDDING_*. Pod 3.11 inserting OP_CODEBOOK_META would be the first row-prefix break.
- **Conceptual fit**: codebook IS embedding infrastructure — codebook ingestion produces embeddings; codebook metadata describes the embedding pool's source. The naming hierarchy reflects the dependency.
- **Constant naming asymmetry already exists**: substrate has `CBK_META_OFF_*` (codebook-prefixed) AND `OP_EMBEDDING_IMPORTED_HANDLE` (embedding-prefixed for the runtime accessor that reads codebook-related state). The split is "BSS data structures use CBK_* prefix; user-surface opcodes use OP_EMBEDDING_* prefix." Pod 3.11 continues the convention.

---

## Q3 — Payload hash exposure

**The question:** Should V1.0 expose `vm_codebook_meta.payload_hash` (16 bytes at CBK_META_OFF_PAYLOAD_HASH) via runtime accessor?

**Analysis:**

- **What it is**: SHA-256-truncated hash of the codebook image's vector block (per D3.30 build-time integrity tier). 16 bytes; doesn't fit single qword accessor.
- **V1.0 user need**: K-metric demo workflow requires count/dim/status; payload_hash is substrate-runtime audit info, not user-program input.
- **Accessor shape if exposed**: would require 2-qword split (field_index=4=hash_low, field_index=5=hash_high) OR a different op shape that returns 16 bytes (which substrate has no precedent for — all current accessors return single qword Outcome).
- **Substrate complexity**: exposing requires deciding the split convention + adding 2 field_index slots + doctrine for "split-payload accessor." Substantial for cosmetic-at-V1.0 audit value.

**TB recommendation: skip at V1.0; defer to V2.0 audit-tier if production scenarios surface empirical pressure.** Rationale:

- **D3.16 anticipated-empirical-pressure discipline**: ship the conservative form (4-field accessor, field_index in 0..3); defer split-payload accessor until production demand surfaces.
- **CBK_META_OFF_PAYLOAD_HASH preserved in substrate**: V2.0 audit-tier or substrate-introspection feature can land the exposure later without breaking V1.0 contract (just adds field_index 4+ semantics).
- **K-metric demo workflow proceeds**: count/dim/status fully sufficient for population-code analysis loops.

**Field_index validation**: V1.0 accepts field_index ∈ {0, 1, 2, 3} for the 4 user-relevant qword fields. field_index >= 4 returns Err(InvalidEmbeddingArg). When V2.0 adds payload_hash split, valid range extends to {0..5}; substrate code patch is one-line constant change.

---

## Q4 — Multi-codebook future-proofing

**The question:** Should META accessor take a `codebook_id` parameter (forward-compat with #91) or default to single codebook (V1.0)?

**Analysis:**

- **V1.0 reality**: single codebook (vm_codebook_meta is one BSS block; codebook_id always = 1 in imported tuples).
- **Future #91 activation**: would introduce multi-codebook substrate state; vm_codebook_meta becomes vm_codebook_meta_array[N]; accessor would need codebook_id parameter to disambiguate.
- **API forward-compat options**:
  - **(i) Take codebook_id parameter at V1.0**: user code passes `codebook_id=1` always; substrate validates `== 1` (else Err); future #91 relaxes the validation to `<= num_codebooks`.
  - **(ii) Skip codebook_id at V1.0**: single-codebook implicit; future #91 lands its own multi-codebook accessor opcode(s).

**Tradeoff audit:**

| Concern | (i) codebook_id param at V1.0 | (ii) skip codebook_id |
|---|---|---|
| V1.0 user-code burden | passes `1` as constant; 2-arg accessor vs 1-arg | clean 1-arg |
| Future #91 transition | parameter relaxes; signature stable | new opcode; old V1.0 op becomes single-codebook-only legacy |
| Substrate complexity at V1.0 | extra `cmp/jne` for codebook_id validation; ~5 extra lines | none |
| Pod 3.8 precedent | (Pod 3.8 D3.32 made codebook surface asymmetric — substrate-private write, dispatch-runtime read; codebook_id baked into tuple, not call signature) | matches Pod 3.8 precedent |
| API design effort saved at future #91 | minor (extends existing accessor) | none (new opcode at #91 anyway) |

**TB recommendation: (ii) skip codebook_id parameter at V1.0.** Rationale:

- **Pod 3.8 precedent**: D3.32 "substrate-private write, dispatch-runtime read" framing established that codebook_id lives in the data (tuple's CODEBOOK_ID field), not in the call signature. Pod 3.11 continues this — META is "read this (singular) codebook's metadata" at V1.0.
- **Future #91 lands its own surface**: when multi-codebook activates, it'll need substantially more than just `codebook_id` parameter on META — it'll need multi-codebook constructor/destructor surface, runtime IMPORT activation (currently deferred per #91), codebook lifecycle management, possibly a Codebook typed primitive (sixth pool). Adding codebook_id parameter NOW saves no future API design work; the V1.0 META accessor would still need re-evaluation at multi-codebook activation regardless.
- **D3.16 anticipated-empirical-pressure**: ship conservative V1.0 form; defer expansion until empirical demand surfaces with concrete consumer use cases.
- **API simplicity**: 1-arg accessor is cleaner than 2-arg-with-always-1; user code legibility favored.

**Forward-compatibility framing**: when #91 activates, the V1.0 META accessor becomes the "single-codebook legacy" op (still functional for codebook_id=1; substrate could even alias 0xF5 to "META for the primary codebook"). New multi-codebook accessor(s) land at fresh opcodes — clean separation of legacy and multi-codebook surfaces.

---

## Q5 — Opcode allocation

**Per Q1 + Q2 recommendations**: single accessor; OP_EMBEDDING_* prefix.

**TB recommendation: 0xF5 OP_EMBEDDING_CODEBOOK_META.** Sequential continuation within D3.34 embedding-tier-extensions row. Post-Pod-3.11 row utilization:

| Slot | Pod | Op | Service tier |
|---|---|---|---|
| 0xF0 | 3.8 | IMPORT | codebook write (handler deferred per #91) |
| 0xF1 | 3.8 | IMPORTED_HANDLE | codebook witness (per-embedding) |
| 0xF2 | 3.9 | LOOKUP_TOP_K | housekeeper (recognition) |
| 0xF3 | 3.10 | PROJECT | composer (geometric) |
| 0xF4 | 3.10 | REJECT | composer (geometric) |
| **0xF5** | **3.11** | **CODEBOOK_META** | **maintenance (codebook witness)** |
| 0xF6–0xFE | reserved | future | embedding-tier (9 slots remaining post-Pod-3.11) |

---

## Q6 — Cost model

**Per D3.13 witness-op convention**: lookup + accessor read; no compute; no forge. Cost = 1j (metabolic minimum).

**Precedent ops at 1j**: 0xF1 IMPORTED_HANDLE, 0xCF SYNTHESIS_HANDLE, 0xC5 SIGN_HANDLE (Pod 3.5) — all witness accessors at 1j.

**TB recommendation: 1j confirmed.** Pure substrate-internal BSS read + Outcome construction; matches witness-tier metabolic floor per D3.13.

---

## Q7 — Forge-path adaptability

**Existing accessor pattern** (IMPORTED_HANDLE 0xF1, per cbs_vm.asm:3437–3488):

1. Pop `field_index` (TOS), pop `embedding_id`
2. Validate `field_index < 4` (else `Err(InvalidEmbeddingArg)`)
3. Validate `embedding_id != 0`; resolve via registry (else `Err(InvalidId)`)
4. Read tuple at `vm_embedding_imported + (embedding_id - 1) * 32 + field_index * 8`
5. Wrap as `Outcome::Ok(value)`; push to operand stack

**For META, clone-substitution adapts cleanly with simplifications**:

1. Pop `field_index` only (no `embedding_id`; codebook is singular per Q4)
2. Validate `field_index < 4` (else `Err(InvalidEmbeddingArg)`)
3. Read `vm_codebook_meta + field_index * 8` (no registry lookup; no per-embedding indexing)
4. Wrap as `Outcome::Ok(value)`; push to operand stack

**Simplifications vs IMPORTED_HANDLE**:
- No second operand pop (1 vs 2)
- No embedding_id validation
- No registry lookup call (`registry_lookup_embedding`)
- No per-embedding offset computation (`(id-1) * 32`)
- 1 error path (InvalidEmbeddingArg) vs 2 (InvalidEmbeddingArg + InvalidId)

**Estimated handler size**: ~25-30 lines NASM (vs IMPORTED_HANDLE's ~50). Even simpler than GET_DIM (which has MAC verify).

**Atreyu emitter shape**: mirrors `embedding_imported_handle` template:
```python
elif t == 'embedding_codebook_meta':
    e.emit(OP_PUSH); e.emit_i64(n['field_index'])
    e.emit(OP_EMBEDDING_CODEBOOK_META); e.emit(OP_OUTCOME_UNWRAP_OK)
elif t == 'embedding_codebook_meta_raw':
    e.emit(OP_PUSH); e.emit_i64(n['field_index'])
    e.emit(OP_EMBEDDING_CODEBOOK_META)
```

**Pattern adapts cleanly** — clone-substitution from IMPORTED_HANDLE with the embedding_id-axis removed.

**Field_index constants for atreyu/user surface**:
```
META_FIELD_COUNT          = 0
META_FIELD_DIM            = 1
META_FIELD_SCALAR_TYPE    = 2
META_FIELD_INGESTION_STATUS = 3
```

---

## Q8 — Iteration primitive

**The question:** Is META(field=count) readback sufficient for user-program iteration over imported embeddings, or does substrate need explicit iteration primitive?

**Analysis:**

User-program iteration pattern with META(count):
```
let count = embedding_codebook_meta(META_FIELD_COUNT);  // reads vm_codebook_meta[0]
let i = 1;
while (i <= count) {
    // operate on imported embedding at id=i
    // (e.g., compute_cosine, lookup_top_k, etc.)
    i = i + 1;
}
```

CBS-program-native constructs already provide:
- `while`/`for` loop primitives (atreyu emits OP_JIF + OP_JMP per existing canon)
- Variable binding via `let`
- Arithmetic (add/sub/mod) via existing 0x00–0x1F arithmetic opcode row
- Comparison (eq/lt/gt/le/ge) via existing arithmetic-comparison row

**Substrate-loop-primitive alternative** would be something like:
- `OP_EMBEDDING_FOREACH_IMPORTED` — substrate-side iteration with callback block
- Requires bytecode block-passing semantics (substrate has none at V1.0)
- Significant new surface for one consumer (user iteration)

**TB recommendation: (a) META(count) readback is sufficient; user loops are CBS-program-native.** Rationale:

- **Existing CBS surface covers iteration**: while/for/let/arithmetic already work; user can express any iteration pattern.
- **Substrate-loop-primitive is unnecessary architecture**: would add bytecode block-passing semantics for one consumer scenario; doesn't extend cleanly to other use cases at V1.0.
- **Composability with project/reject/lookup_top_k**: user loops compose with the entire Maid surface; substrate-loop-primitive would be specialized to iteration-over-imported-embeddings.
- **K-metric demo workflow proceeds**: `let count = meta(0); while i <= count { ... }` is the natural pattern.

---

## Open questions for HALT 1 architect ratification

| # | Question | TB lean |
|---|---|---|
| Q1 | Op surface scope | (a) single OP_*_META(field_index) accessor — GET_DIM/IMPORTED_HANDLE/SYNTHESIS_HANDLE convention continuity; opcode-slot conservation; one handler shape |
| Q2 | Naming prefix | OP_EMBEDDING_CODEBOOK_META — D3.34 embedding-tier-extensions row continuity; codebook conceptually IS embedding infrastructure |
| Q3 | Payload hash exposure | skip at V1.0 — defer to V2.0 audit-tier if empirical pressure surfaces; field_index ∈ {0..3} at V1.0 |
| Q4 | Multi-codebook future-proofing | (ii) skip codebook_id parameter — Pod 3.8 precedent (codebook_id lives in data, not signature); future #91 lands its own surface; D3.16 conservative-V1.0 |
| Q5 | Opcode allocation | 0xF5 OP_EMBEDDING_CODEBOOK_META within D3.34 embedding-tier-extensions row |
| Q6 | Cost-table | 1j confirmed — D3.13 witness-tier metabolic minimum; matches 0xC5 / 0xCF / 0xF1 precedent |
| Q7 | Forge-path adaptability | clean clone-substitution from IMPORTED_HANDLE; ~25-30 lines NASM (even simpler than IMPORTED_HANDLE — no registry lookup; no embedding-id axis); field_index 0..3 → vm_codebook_meta offset *8 |
| Q8 | Iteration primitive | (a) META(count) readback sufficient; CBS user-program loops cover iteration via existing while/for/let/arithmetic surface |

---

## Doctrine candidates for Pod 3.11 (post-ratification)

- **D3.42** — Codebook metadata witness accessor: V1.0 ships single-codebook field-indexed read surface; codebook_id parameter deferred to multi-codebook activation (#91); GET_DIM-style parameterized accessor convention extended to substrate-private singleton state (vs per-embedding state of GET_DIM/IMPORTED_HANDLE/SYNTHESIS_HANDLE).
- **D3.43** — V2.0-deferral discipline for substrate audit fields: substrate-runtime integrity metadata (payload_hash) stays internal at V1.0 absent empirical pressure; substrate retains the data, defers user-surface exposure to audit-tier landing.

(Numbering deferred to architect call; D3.42+ may shift based on actual landings.)

---

## Architect-framing observations worth surfacing

**(1) Pod 3.11 is a light pod** — confirmed by recon. Single new accessor handler (~25-30 lines NASM); single emitter; single dispatch entry; single cost-table annotation; single canary surface (B52 likely). Estimated chunks: 5-7 per architect framing — matches my estimate (3.11.A sit / 3.11.B handler+dispatch+emitter+constants / 3.11.C cost-table / 3.11.D B52 canary / 3.11.E SEAL = 5 chunks). Helper landing collapses into handler chunk (no separate "helper" pod since there's no compute primitive — just BSS read + Outcome wrap).

**(2) Field_index constants at atreyu level mirror existing pattern** — `META_FIELD_COUNT=0`, `META_FIELD_DIM=1`, `META_FIELD_SCALAR_TYPE=2`, `META_FIELD_INGESTION_STATUS=3`. Parallels Pod 3.6 / 3.8 / 3.9 emitter constants (SYNTHESIS_FIELD_*, IMPORTED_TUPLE_OFF_*). Consistency at the user-code surface.

**(3) Forward-compat NOT load-bearing for V1.0 design** — Q4 framing distinction. Multi-codebook activation at future Pod 3.X+ will introduce substantial surface (codebook lifecycle, possibly sixth typed pool); adding codebook_id parameter NOW saves no future API work. V1.0 ships the conservative shape; future expansion deals with its own scope.

**(4) Predicted catch rate**: 0–1, clustered at canary-tier discipline (per architect framing). Light pod with established accessor pattern; substrate-tier catches unlikely. Most likely catch surface:
- Canary forge-order discipline (per D3.41 from Pod 3.10) — META canary doesn't forge embeddings but reads pre-boot-ingested codebook state; canonical empty-codebook build → count=0, dim=384, scalar_type=0, status=CBK_STATUS_SUCCESS. Auxiliary B49-like substrate with 10-entry test codebook would produce count=10 etc. — canary design choice.
- field_index out-of-range Err path (field_index=4..7 reserved for future; should return Err(InvalidEmbeddingArg) per V1.0 conservative validation).

**(5) Empty-codebook canonical-build edge case** — META accessor on canonical Pod 3.11 substrate (no codebook configured) reads count=0, dim=384, scalar_type=0, status=CBK_STATUS_SUCCESS. User-program iteration `while i <= count` correctly does nothing (0-iteration loop). The accessor surface is consistent across canonical (count=0) and auxiliary (count>0) substrate builds — no special-case dispatching required.

**(6) D3.37 NASM RIP-relative discipline carries forward** — META handler reads `[rel vm_codebook_meta + field_index*8]` style. Per D3.37, use `lea rax, [rel vm_codebook_meta]; mov rax, [rax + rcx*8]` pattern; NOT `[rel vm_codebook_meta + rcx*8]` (silently miscompiles). Pod 3.10 had this discipline applied retroactively; Pod 3.11 inherits.

The "Maid maintains" tier extends Pod 3.8's codebook surface (write at boot; per-embedding read via IMPORTED_HANDLE) with **codebook-level metadata read** at Pod 3.11. Codebook surface reaches V1.0 read-completeness; substrate's external-embedding architecture has complete witness coverage at V1.0.

Standing by for HALT 1 architect ratification.
