# Pod 3.8 Recon Notes — Codebook ingestion sit prep

**Status:** Informal recon notes for HALT 1 architect ratification. NOT a formalized recon report. Six findings + recommendations surfaced for sit-time call before any code lands.

**Entry HEAD:** c53f651b145466bed5f67f605f787ae5d41d1256 (Pod 3.7 seal — substrate scales)
**Entry contract:** 435e17eca9b9d26028e8a67c8fe411b727a762cc471a61d0fe1e3eb77bcbf36a (Pod 3.7 BOOTX64.EFI)
**Three-oracle:** ✓ HEAD = origin/main = ls-remote at c53f651
**Build chain:** unchanged from Pod 3.7 (NASM 2.16.01 / mcopy 4.0.43 / QEMU 8.2.2; build.sh hardened pinning + B47 meta-canary in place per D3.29 axis-1)

---

## Q1 — Codebook image format

**External source forms the build-time tool needs to handle:**
- `.npy` (NumPy array; sentence-transformer canonical output)
- Plaintext line-per-vector (token + space-separated floats; word2vec / GloVe canon)
- Raw float32 binary dump (`count × dim` contiguous floats)
- TSV with metadata columns + vector

**Substrate-loadable image needs:** integrity-checkable container holding (count, dim, scalar type, contiguous f32 vector block) with optional metadata.

**Recommended shape (V1.0 minimum):**
```
+0x00  magic "CBKBOK01"      (8 bytes; 6-char tag + 2-digit version "01")
+0x08  count                 (u64)
+0x10  dim                   (u64; must equal EMBEDDING_DIM=384 in V1.0)
+0x18  scalar_type           (u64; 0 = f32 in V1.0; reserved 1+ for future)
+0x20  vector_block_offset   (u64; absolute offset to first vector byte; 0x40 in V1.0)
+0x28  vector_block_bytes    (u64; count × dim × 4)
+0x30  payload_hash          (u64 SipHash-2-4 over vector block under build-time fixed key, OR sha256 truncated; build-time only — verifies image hasn't been corrupted in transit)
+0x38  reserved              (u64; future: timestamp / format_revision / metadata_offset)
+0x40  vectors[count][dim]   contiguous f32 little-endian, no per-embedding metadata in V1.0
```

**Hash-vs-MAC sub-decision:**
- substrate doesn't trust the image at integrity level — substrate MACs each embedding individually using per-boot SipHash key as it gets imported (per-embedding MAC stamping inside OP_EMBEDDING_IMPORT; matches OP_EMBEDDING_NEW's siphash_compute + EMBEDDING_OFF_MAC stamp pattern)
- image-level `payload_hash` is **build-time + offline-verification artifact** (CI can verify build-tool output reproducibility), not enforced at boot
- decouples image format from substrate's per-boot crypto state

**TB recommendation:** ratify the 64-byte header + contiguous f32 block shape. Magic "CBKBOK01" makes file-type identification trivial; reserved fields document future extension points without committing now. Per-embedding metadata (labels) deferred — codebook image is vectors-only V1.0; labels can be a sidecar file or post-V1 extension.

---

## Q2 — Memory placement

**Three options + tradeoffs:**

### (a) Dedicated reserved-BSS codebook region read at boot
- Pre-allocate `vm_codebook: times CODEBOOK_BYTES db 0` in vmdata.asm
- Boot fills it (UEFI loader / FAT32 morla driver)
- **Pro**: substrate has direct address access; deterministic
- **Con**: codebook size baked into binary via CODEBOOK_BYTES constant; can't swap codebooks without rebuild; second storage region needs separate accessor patterns (substrate would have two embedding-state surfaces — pool + codebook region — mismatched accessor convention)

### (b) Codebook image as second build artifact, UEFI-loaded
- `BOOTX64.EFI` + `codebook.bin` shipped together; boot uses Boot Services (or morla FAT32) to load codebook.bin into a fixed memory region at known address
- **Pro**: codebook size flexible; can swap codebooks by replacing one file without rebuilding substrate
- **Con**: boot-time complexity (loader needs to read FAT32 + place at known address; load-failure handling at boot before VM is up); two-artifact deployment (DEFERRED #84-style discipline cost); same dual-storage accessor mismatch as (a)

### (c) Ingested-into-embedding-pool-at-boot with imported provenance pre-stamped
- Boot reads codebook image → forges embeddings via standard forge path (vector copy + MAC + register + tuple-write) with imported provenance pre-stamped → embedding_pool partially populated at boot completion
- **Pro**: cleanest semantic — imported embeddings live in pool just like forged/synthesized ones; existing accessors (GET_DIM, COSINE, SIGN_HANDLE, SYNTHESIS_HANDLE, IMPORTED_HANDLE per Q4) work uniformly; provenance integrates as a third side-table without storage divergence
- **Con**: pool capacity consumed at boot — codebook size capped by `EMBEDDING_POOL_SLOTS` minus runtime-synthesis headroom

**Capacity tradeoff is the binding constraint for option (c):**

With Pod 3.7 EMBEDDING_POOL_SLOTS=2048, capacity-stress estimates:
- Codebook ≤ 1500 → comfortable runtime synthesis room (500+ slots) — option (c) clean
- Codebook 1500–2000 → tight; little synthesis room — option (c) workable but cramped
- Codebook 2000+ → option (c) saturates; need option (a)/(b) — or expand pool further

**TB recommendation:** **option (c) for V1.0** with documented codebook-size upper bound at ~1500 entries (leaves 500+ slots for runtime synthesis and analogical-reasoning work). Architecturally cleanest: D3.20→D3.26 generalized non-MAC parallel linkage already pre-shaped the substrate for this — imported provenance becomes the third instance of the pattern, alongside vm_embedding_sign_handle (Pod 3.5) and vm_embedding_synthesis (Pod 3.6).

If production codebooks exceed ~1500, option (a)/(b) becomes Pod 3.9+ work item; substrate's two-tier storage (pool + reserved-region) is a substantial architectural addition meriting its own pod.

**Sub-question for architect**: is the V1.0 production codebook target ≤1500 entries? If the answer is "we want 10K+ codebooks at V1.0," the recommendation flips to option (b) and the pod scope grows substantially.

---

## Q3 — Authority bit

**BIT_EMBEDDING_FORGE = (1 << 4) = 0x10** (Pod 3 D3.X) gates OP_EMBEDDING_NEW + Pod 3.6 synthesis ops (0xCA-0xCE).

**Two paths:**

### (a) Reuse BIT_EMBEDDING_FORGE
- Imported embeddings are forge-class operations — substrate creates new embeddings with full provenance, MAC, tuple-side-table writes; the source of vector data (operand stack vs codebook block) is implementation detail rather than authority axis
- Mechanically minimal; no new authority axis; no new bit
- Pro: simpler; current authority model already handles "create new embedding" uniformly
- Con: programs cannot grant FORGE-without-IMPORT (e.g., allow runtime synthesis but not codebook ingestion)

### (b) New BIT_EMBEDDING_IMPORT (e.g., bit 5 = 0x20)
- Distinct authority class for "forge from external source"
- Pro: finer-grained authority surface; programs can grant forge-class rights without granting import rights
- Con: new authority axis with no current consumer-side use case; speculative

**TB recommendation:** **(a) reuse BIT_EMBEDDING_FORGE.** The substrate's existing forge-class authority correctly captures the semantics. Imported embeddings are forged with imported provenance pre-stamped; they're forge-class operations with a different vector source. Adding BIT_EMBEDDING_IMPORT now would be speculative authority granularity with no current program-shape demanding it.

If future production scenarios need finer-grained gating (e.g., "this cap can synthesize but cannot ingest new codebooks"), Pod 3.9+ can split BIT_EMBEDDING_FORGE into FORGE+IMPORT bits as a substrate-evolution event. D2.2's bit-vocabulary doctrine (bits 5–63 reserved for organic vocabulary growth) supports this without ABI breakage.

**Document the reuse explicitly in D3.X**: "imported embeddings are forge-class; gate via BIT_EMBEDDING_FORGE; no new authority axis at Pod 3.8. Deferred split if production scenarios surface FORGE-without-IMPORT need."

---

## Q4 — Imported provenance side-table

**Third non-MAC parallel structure** alongside Pod 3.5 vm_embedding_sign_handle (8 bytes per slot — Embedding→Sign linkage) and Pod 3.6 vm_embedding_synthesis (32 bytes per slot — Embedding→synthesis-lineage tuple). Per D3.29 axis-2 mechanical-sizing discipline, the new side-table sizes to EMBEDDING_POOL_SLOTS via shared constant; cascades automatically.

**Tuple shape options:**

| Option | Size/slot | Fields |
|---|---|---|
| Minimum | 16 B (2 qwords) | (codebook_id, line_index) |
| Layout-2 mirror | 32 B (4 qwords) | (codebook_id, line_index, hash, timestamp) — full provenance |
| Layout-2 reserved | 32 B (4 qwords) | (codebook_id, line_index, reserved, reserved) — V1.0 minimum + future extension |

**Layout consistency consideration:** Pod 3.6 D3.27 codified Layout 2 quad-tuple (32 bytes, 4 qwords) for synthesis lineage. If imported-tuple uses 16-byte shape, Pod 3.8 introduces a second Layout convention; if 32-byte, it inherits Layout 2 directly.

**TB recommendation:** **Layout-2 reserved** (32-byte quad-tuple matching synthesis tuple shape):
```
+0x00  codebook_id  (qword; opaque ID identifying which codebook was imported; V1.0 single-codebook → always 1; multi-codebook future → unique per codebook at import time)
+0x08  line_index   (qword; original line/index in the codebook)
+0x10  reserved     (qword; future: payload_hash for cross-build verification)
+0x18  reserved     (qword; future: timestamp / import_epoch for audit)
```

**BSS sizing:** `vm_embedding_imported: times EMBEDDING_POOL_SLOTS * IMPORTED_TUPLE_BYTES db 0` = 2048 × 32 = **64 KB** (mirrors vm_embedding_synthesis exactly).

**Why Layout-2 mirror over the minimum:**
- D3.27 doctrine cost already paid; reusing same shape costs nothing additional
- Substrate gains uniform tuple-shape across all linkage side-tables (synthesis + imported = same shape; sign reverse is the only odd one at 8B-per-slot, kept that way for D3.4 Pod-3 backward compat)
- Reserved fields document future extension without committing now (V1.0 ships with hash=0 / timestamp=0; future Pod can populate without ABI break)
- Single-codebook V1.0: `codebook_id` always = 1; multi-codebook becomes a future-Pod scoping change without tuple-shape migration

**Sub-question for architect:** does V1.0 want hash/timestamp populated immediately, or are reserved fields acceptable? If populated immediately, the build-time tool emits hash + timestamp in the codebook image and substrate copies into the tuple at import; if reserved, substrate writes 0/0 and forward-anchors the population for Pod 3.9+.

---

## Q5 — Opcode allocation

**Architect-suggested row 0xD0–0xDF is partially consumed**: Energy ops occupy 0xD0–0xD8 (NEW, JOULES, SOURCE_OP, FREE, RECOVER, PHASE_QUERY, ARENA, OWNER, CREATOR per defines.asm:103–116). Available within row D: 0xD9–0xDF (7 slots).

**Cleaner alternatives surveyed via tree-wide opcode audit:**

| Range | Status | Note |
|---|---|---|
| 0xA8–0xAF | Sign-reserved | 8 slots; reserved for Sign vocabulary growth (Pod 3.5+ pattern) |
| 0xBB–0xBF | Cap-reserved | 5 slots; reserved for Cap vocabulary growth |
| 0xC0–0xCF | **Embedding (FULL)** | 0xC0-0xC4 Pod 3 + 0xC5-0xC9 Pod 3.5 + 0xCA-0xCF Pod 3.6 |
| 0xD9–0xDF | Energy-row tail | 7 slots; reserved for Energy vocabulary growth — semantic mismatch for codebook ops |
| 0xE8–0xEF | Demod-reserved (Pod 1.12) | 8 slots; reserved per Pod 1.12 forward-anchor |
| **0xF0–0xFE** | **Unallocated, clean row** | **15 slots; no reservation** |
| 0xFF | HALT | terminator |

**TB recommendation:** **0xF0–0xFE row** for codebook-tier ops. Fresh row clarity beats squeezing into 0xD9-0xDF Energy-tail (which carries Energy semantic baggage and only 7 slots). 0xF0+ is genuinely unallocated.

**V1.0 minimum allocation (mirrors Pod 3.6 forge-tier + accessor pattern):**
```
0xF0  OP_EMBEDDING_IMPORT          ; pop codebook_id + line_index, forge embedding from codebook block, write imported tuple
0xF1  OP_EMBEDDING_IMPORTED_HANDLE  ; GET_DIM-style witness accessor: pop embedding_id + field_index (0..3), read imported tuple field
0xF2-0xFE  reserved for codebook-tier extensions (Pod 3.9+ multi-codebook ops, codebook metadata accessors, etc.)
```

Two opcodes for V1.0; 13 reserved slots for future. Mirrors Pod 3.6's pattern (forge ops + witness accessor) at smaller scale.

**Architect-framing-correction note**: the suggested 0xD0–0xDF in the directive overlaps Energy row. Surfaced for ratification — the 0xF0–0xFE recommendation feels more honest to canon.

---

## Q6 — Forge-path adaptability (implementation cost)

**OP_EMBEDDING_NEW** sequence at `cbs_vm.asm:2166–2255` (R4 canon from Pod 3.6 recon, verbatim):

1. Pop vector_addr from operand stack
2. Bit-check BIT_EMBEDDING_FORGE
3. Pool capacity check
4. `.embedding_alloc` → slot_ptr (rbx, callee-saved)
5. Write placeholder id + cap-cache (arena/owner/creator) at slot offsets
6. `rep movsb` 1536-byte vector copy from `[vector_addr]` to `slot+OFF_VECTOR`
7. `registry_register_embedding` → embedding_id
8. Stamp `embedding_id_self` post-registry (R7-corrected ordering)
9. `siphash_compute` → MAC at `+0x620`
10. `.construct_ok_outcome`

**For OP_EMBEDDING_IMPORT, what differs:**

- **Step 1**: pop `codebook_id + line_index` instead of `vector_addr`. New helper or inline computation needed: `codebook_addr_lookup(codebook_id, line_index) → vector_address` (computed from codebook block base + line_index × dim × 4)
- **Step 6**: `rep movsb` source becomes the codebook-block computed address, not operand-stack `vector_addr`. Otherwise identical (1536 bytes copied; substrate-trusts-its-own-write-paths convention applies)
- **Step 9.5 (new, mirrors Pod 3.6 R4 step 9.5)**: imported-tuple write at `vm_embedding_imported + (new_id-1) * 32`: `(codebook_id, line_index, 0, 0)` (or with hash/timestamp populated per Q4)

**Steps 2-5, 7-8, 10**: verbatim reusable from OP_EMBEDDING_NEW. The forge-tier pattern Pod 3.6 D3.27 codified extends cleanly.

**Implementation cost: low-to-modest.**

- New constant block in defines.asm: codebook-tier OP codes + imported-tuple field offsets + IMPORTED_TUPLE_BYTES + IMPORTED_FIELD_* constants
- New helper (or inline) for codebook_addr_lookup (mechanical address arithmetic; ~10 lines of asm)
- New handler `.op_embedding_import` (mirror of Pod 3.6 `.op_embedding_add` shape with steps 1, 6, 9.5 substituted) — ~150 lines of asm
- New handler `.op_embedding_imported_handle` (mirror of Pod 3.6 `.op_embedding_synthesis_handle` verbatim with `vm_embedding_imported` substituted for `vm_embedding_synthesis`) — ~50 lines of asm
- New BSS block: `vm_embedding_imported` (64 KB; sized to EMBEDDING_POOL_SLOTS × IMPORTED_TUPLE_BYTES per D3.29 axis-2)
- atreyu_x86.py: 2 emitters + demos + CLI subcommands

**No new private helper needed beyond optional `codebook_addr_lookup`.** Existing `.embedding_alloc`, `registry_register_embedding`, `siphash_compute`, `.construct_ok_outcome` all reusable. `.embedding_two_resolve_verify` / `.embedding_one_resolve_verify` don't apply (no input embedding-id resolution; codebook ID + line index are pre-existing data references, not embeddings to resolve).

**Pattern adapts cleanly.** No fully separate code path warranted.

**Boot-time codebook ingestion** (per Q2 option (c)) is a separate boot-time logic path: bastian/morla reads codebook image at boot completion, dispatches OP_EMBEDDING_IMPORT N times under ROOT cap, populates pool. Implementation: substrate-internal — boot calls the import handler directly via `.op_embedding_import` or via a substrate-internal C-style helper that bypasses the dispatch loop. Architect ratification needed on whether import is dispatched as bytecode (clean — runs through normal VM dispatch) or via direct call (fast — no operand-stack overhead but bypasses substrate-bookkeeping).

**Recommend**: dispatch as bytecode at boot for the cleaner architectural shape. ~1500 entries × (5 dispatch ops per import + per-op cost) = ~7500 op dispatches at boot. With per-op cost around 100j and substrate r14 = 1M, this fits comfortably. Boot-time r14 reset is a sub-decision (current substrate doesn't reset r14 between programs; codebook ingestion at boot before user programs run might want a "boot budget" separate from "user budget").

---

## Open questions for HALT 1 architect ratification

| # | Question | TB lean |
|---|---|---|
| Q1 | Codebook image format (64-byte header + contiguous f32 block; magic "CBKBOK01"; payload_hash build-time-only) | Ratify proposed shape |
| Q2 | Memory placement (option c: ingested-into-embedding-pool-at-boot) | Recommend (c) for V1.0; flag codebook-size cap ~1500 |
| Q3 | Authority bit (reuse BIT_EMBEDDING_FORGE; no new bit) | Reuse |
| Q4 | Imported provenance side-table (Layout-2 quad-tuple matching synthesis; reserved fields for hash/timestamp) | Layout-2 reserved |
| Q5 | Opcode allocation (0xF0–0xFE row, not 0xD0; framing correction) | 0xF0–0xFE |
| Q6 | Forge-path adaptability (mirror OP_EMBEDDING_NEW shape; ~150-line handler clone with steps 1/6/9.5 substituted; no fork) | Mirror clone, low cost |
| Sub-Q | Boot-time codebook ingestion via bytecode dispatch vs direct call | Bytecode dispatch (cleaner) |
| Sub-Q | Codebook image hash/timestamp populated at V1.0 vs reserved | Reserved (V1.0 minimum) |
| Sub-Q | Production codebook size target — ≤1500 (option c works) vs >1500 (need option a/b) | **Awaiting architect input** |

---

## Notes for the formal POD3.8_RECON_REPORT.md (post-HALT-1)

When the architect ratifies the above (or redirects), formalize as POD3.8_RECON_REPORT.md mirroring Pod 3.5 / 3.6 / 3.7 recon report structure: R1–R12 (or whatever the canonical R-call set lands at) + A-call surfaces with TB recommendations + Surprises + HALT 1 conclusion. The six findings here become the A-call core (A1–A6 plus the sub-decisions); R-calls are pre-flight (oracles, identifiers, constants, build chain) and audit-completeness checks.

**Predicted catch rate at Pod 3.8**: 1–3 (substrate-USE pod with new external-data-ingestion surface; potential FP-precision-prediction landings if hash/timestamp surface unexpected drift; potential canon-doc-stale variants if codebook format integration surfaces forge-path assumptions not previously load-bearing).

The codebook ingestion arc takes Maid to her V1.0 production form: housekeeper + composer + lineage-recovery + **importer**. The substrate becomes able to ingest external semantic surfaces and account for what it ingested, byte-by-byte through MAC stamping, line-by-line through imported-provenance side-table.

Standing by for HALT 1 architect ratification.
