# Pod 3 Decision Record — Maid is born (Embedding typed primitive substrate-prep)

**Pod:** 3 — first substrate-USE pod after seven pods of substrate-EVOLUTION; lexical embedding substrate-prep for Maid V1.0
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-05
**Entry contract:** 0f598ec585245820da7d1cf89d6611cd80cb3327b76da74e5fe35c7590ccdb5f (Pod 2.2 BOOTX64.EFI)
**Exit contract:** 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3
**Entry HEAD:** ec0899bf6e79cb5f9586357a2f825248bbe79478 (Pod 2.2 seal — Babylon's vocabulary)

---

## D3.1 — Embedding as fifth typed primitive

f32[384] vector substrate-prep matching Pod 1.7 Sign / Pod 1.8 Energy substrate-prep pacing. Substrate primitive count V1.0 increments from 4 to 5: Sign, Energy, Outcome, Cap, **Embedding**.

**The architectural moment.** Pods 1-2 prep + activate the substrate's own physics (typed primitives, identity, lineage, metabolism, authority shape). Pod 3 is the first substrate-USE pod — Embedding is the substrate primitive Maid V1.0 needs to do real semantic work. The architectural pacing inflection lands cleanly: every prior pod added structural substrate; Pod 3 adds a primitive that exercises substrate.

Pod 3 ships substrate-prep mode only — typed pool + accessors + forge bit + Sign linkage activation. Semantic operations (similarity, lookup-by-meaning, codebook ingestion) deferred to Pod 3.5+ per D3.8.

## D3.2 — Canonical V1.0 dimension EMBEDDING_DIM = 384

Compile-time constant. f32 per dimension. EMBEDDING_VECTOR_BYTES = 1536. EMBEDDING_SLOT_BYTES = 1576 (197 qwords). EMBEDDING_POOL_SLOTS = 64.

**No runtime configurability in V1.0.** Avoids pool slot sizing / MAC range / arena layout complexity at substrate-prep tier. Future minor versions can recompile for different canonical sizes (EMBEDDING_DIM=128 for compressed embeddings, EMBEDDING_DIM=768 for larger lexical-embedding models).

384 is canonical for sentence-transformer-class lexical embeddings (per ARCHAEOLOGY's `maid.py` reference: `384-dim sentence-transformer embeddings`). The Python prototype's choice carries forward.

## D3.3 — Full vector under MAC protection

196-qword MAC-input range covers header (4 qwords: id + arena + owner + creator) + vector (192 qwords = 1536 bytes / 8). Mutation goes detected. SipHash-2-4 over 196 qwords is sub-linear; cost basis matches OP_EMBEDDING_NEW = 100j substrate prior.

**Embeddings are immutable post-construction.** No mutable field analog to Cap.energy_used. Once stamped + MAC'd, the embedding is byte-frozen. Pod 3.5+ similarity computations rely on bit-exact retrieval (B8 empirical: dim[100]=1120403456 verbatim survives MAC stamp + retrieval cycle).

The embedding's integrity model is the strongest in the substrate: every byte (header + vector) is under MAC. This matters for cross-pod consumers reading dimensions hours/days after construction — the substrate's promise is "what was forged is what you read."

## D3.4 — Sign embedding_handle linkage via parallel side-table

The DEFERRED #65 resolution shape was load-bearing recon adjudication at HALT 1 (A7). Three options per #65:
- (a) Slot expansion to 136/256 bytes — architect rejected at Pre-A10
- (b) Side-table indexed by sign_id — TB recommended
- (c) Out-of-line lookup table — variant of (b)

**Architect ratified option (b).** Implementation:
- BSS allocation: `vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0` in vmdata.asm
- OP_SIGN_NEW retrofit: pre-Pod-3 `test r9, r9 / jnz` validation (rejected non-zero) replaced with non-zero-via-registry-lookup_embedding validation; post-registry_register_sign side-table write at index `(sign_id - 1) * 8`
- New accessor OP_SIGN_EMBEDDING_HANDLE = 0xA7 reads side-table at same index
- Failure path `.sign_new_invalid_embedding` routes to `.construct_err_outcome(ERR_INVALID_ID, OP_SIGN_NEW, TYPE_CODE_SIGN)`

The side-table integrity model matches Sign's existing non-MAC convention. Sign slots are non-MAC per Pod-1.7-archaeology asymmetry (D3.6 / DEFERRED #81 forward-log); the embedding linkage extends that same parallel-structure-tracking convention rather than introducing a new integrity tier.

**B12 architectural moment empirically validated:**
```
embedding_id (expect 1):  1
sign_id (expect 1):  1
sign.embedding_handle (expect 1; #65 cash):  1
```

The substrate now persists cross-pool typed references via parallel structure and exposes them via accessor. The cross-pool-reference pattern lands clean.

## D3.5 — DEFERRED #65 RESOLVED via parallel side-table

Three-pod forward-log resolution distinct from #61's in-place activation pattern.

**Resolution chain:**
- **Pod 1.10.2b2** (D1.10.2b2.X): Sign slot at +0x68 reclaimed from former embedding_handle for creator_cap_id (Pod 1.8.5c reclamation pattern continuation). OP_SIGN_NEW preserved 5-arg ABI, validating embedding_handle=0 then silently discarding.
- **Pods 2.x** (anchor): #65 forward-logged through Pod 2.1 (Babylon spatial-merge), Pod 2.2 (cap_bitmap texture). Reservation carried via documented intent.
- **Pod 3.0** (cash): D3.4 parallel side-table activation. Three resolution options weighed; option (b) ratified at AUTHORIZED-1.

**Resolution shape contrast with #61:**
- **#61** (ERR_CAP_AUTHORITY_EXCEEDED, 4-pod forward-anchor): in-place semantic activation. The constant existed at value 7 throughout; Pod 2.2 just activated the consumer (subset-on-grant logic).
- **#65** (Sign embedding_handle, 3-pod forward-anchor): reclaimed-slot-via-parallel-structure. The slot field was retired at Pod 1.10.2b2; Pod 3 added a parallel BSS structure to hold the linkage.

Both patterns now canonized for substrate evolution without slot-layout disruption (D3.6).

## D3.6 — Two patterns canonized for substrate evolution

After Pods 2.2 and 3, the substrate has empirically validated **two distinct architectural patterns** for evolving typed primitives without disrupting existing slot layouts:

| Pattern | Pod | Mechanism | Resolution shape |
|---|---|---|---|
| **Placeholder-field semantic activation** | 2.2 | Existing field at known offset gains structured semantics | Constant rename + content-shift (resource_descriptor → granted_bitmap at +0x18) |
| **Reclaimed-slot via parallel BSS structure** | 3.0 | Slot field was reclaimed for other purpose; new linkage lives outside slot | New BSS array indexed by primitive_id + new accessor opcode (vm_sign_embedding_handle + OP_SIGN_EMBEDDING_HANDLE) |

**The difference is whether the original placeholder field still exists at its original offset.** Pod 2.2's cap_bitmap pattern: yes, +0x18 still in MAC-input range, content shifts. Pod 3's embedding_handle pattern: no, +0x68 was reclaimed for creator_cap_id, parallel structure lives separately.

Both patterns:
- Pay out forward-log discipline (intent reserved across pods, cashed at activation)
- Preserve byte-layout invariants of existing slots (no breaking changes to bytecode shape or MAC range)
- Match the substrate's existing integrity model for the affected pool

Future pods inherit both patterns as design-tool choices when activation triggers depend on whether the target field's slot still exists.

## D3.7 — Codebook as collection-of-embeddings (no separate primitive)

Maid's "plastic codebook" framing from ARCHAEOLOGY (graph + vector + log substrate) doesn't require a separate `Codebook` typed primitive in V1.0. The substrate primitive is **Embedding** — the codebook is the *collection* of embeddings in the pool, indexed by embedding_id.

Maid V1.0 layers semantic indexing/lookup logic above the embedding pool in Pod 3.5+:
- **Lookup-by-meaning**: scan embedding pool, compute similarity to query, return best match
- **Codebook ingestion**: bulk-load embeddings from external source (FAT32 file via Morla, programmatic, etc.)
- **Graph structure**: emerges from Sign-Embedding linkage (D3.4) + Outcome chains; no separate graph primitive needed in V1.0

**Substrate stays minimal.** The Codebook is a *programming model* layered above the substrate primitive, not a substrate primitive itself. Pod 3.5+ Maid semantic operations exercise this layered model without adding primitive count.

This matches the original ARCHAEOLOGY framing: Maid is the *housekeeper* (semantic logic + similarity + ingestion); Embedding is the *substrate primitive* (immutable f32[384] vector under MAC). Two roles, one substrate primitive.

## D3.8 — Substrate-prep mode pacing

V1.0 ships embedding primitive + accessors + forge bit; semantic operations (similarity, lookup, ingestion) deferred to Pod 3.5+. Pattern matches Pod 1.7 / Pod 1.8 substrate-prep mode (small, fast-to-seal, validates new-pool machinery before adding semantic complexity).

**Pod 3 specifically chose substrate-prep mode** (rather than full-Maid mode) for three reasons:
1. **Small change-surface for new typed pool** — adding fifth typed primitive with 5 opcodes + 1 cross-pool linkage opcode + Sign retrofit fits the substrate-prep envelope. Adding similarity/lookup/ingestion would inflate change-surface 3-4x.
2. **Validates new-pool machinery** — pool BSS, registry, MAC, accessor pattern, bit-check, single-fire axiom — all need to land cleanly before semantic ops can rely on them. Substrate-prep mode catches integration issues at minimum-scope.
3. **Architect-led architectural sit** — semantic operations involve design choices (cosine vs dot product as primary; thresholds; lookup ranking; ingestion API) that benefit from a real architectural sit between substrate-prep seal and semantic-ops drafting.

**Zero prior-pod surface ripple confirmed empirically** — first such pod since Pod 1.10.3. Substrate-prep mode delivered truly mechanically additive evolution: 6/6 Outcome regression + 4/4 Error-path regression byte-identical to Pod 2.2 reference.

## D3.9 — Single-fire substrate axiom inherited at greenfield by construction

Pod 2.2 D2.2.10 established the single-fire axiom for Sign/Energy success paths via Path A retrofit (handler-explicit babylon_charge_lineage call removed; .construct_ok_outcome's internal call became sole spatial-merge fire site).

**Pod 3's OP_EMBEDDING_NEW propagates this axiom forward by construction.** Greenfield typed primitives use .construct_ok_outcome from the start; no Path A retrofit needed; no double-fire risk introduced at greenfield. The axiom propagates by virtue of the canonical handler template inheriting from the post-Pod-2.2 state.

**B10/B14 sub-cap canary empirically validated:**
```
A.used (expect 0; originating):  0
ROOT.used (expect 50; 100/2 floor):  50
```

ROOT.used = 50, not 100. .construct_ok_outcome's internal babylon fired exactly once for the 100j Embedding cost; A's parent (ROOT) charged half-cost-floor. **Seventh empirical landing of single-fire substrate axiom** (Sign post-Path-A, Energy post-Path-A from Pod 2.2; Outcome NEW_OK direct, NEW_ERR direct, OP_CAP_NEW from earlier pods; Embedding via greenfield this pod).

The discipline carries forward: any future greenfield typed primitive (Pod 3.5+ Maid semantic ops creating intermediate values? Pod 4+ Interpreter Signal primitive? Pod 1.12 Demod primitive?) that uses .construct_ok_outcome from the start inherits single-fire automatically.

## D3.10 — Substrate-bookkeeping doctrine PROMOTED to canonical reference

**Cross-cutting summary doctrine entry; future pods cite D3.10 rather than re-recording the family chain.**

Six prior empirical landings:
- D1.9.2b.1 — vm_fetch_count substrate gap closure
- D1.10.2a.7 — cryptographic init (RDSEED + SipHash + ROOT_CAP MAC)
- D1.10.2b2.3 — Move 3 + creator_cap_id field writes at six allocator sites
- D1.10.3.X — energy_budget MAC-input + energy_used non-MAC field writes
- D2.1.6 — spatial-merge ripple writes at seven construction sites
- D2.2.9 — bit-check at 4 forge dispatch sites + subset-on-grant at OP_CAP_NEW

**Pod 3 makes seventh:** bit-check at .op_embedding_new dispatch site + OP_SIGN_NEW embedding_handle validation + side-table write — all substrate-bookkeeping work; 0j cost; 174j Sign canary + 53j Energy canary held verbatim under ROOT context (B2/B3 empirical).

**Canonical doctrine entry: substrate-private operations (counter increments, field writes, MAC compute, spatial-merge ripples, bit-checks, side-table writes) are 0j; only operand-visible work charges.** Originating opcode's cost-table value unchanged across all seven landings.

Future pods reference D3.10 rather than re-recording the doctrine chain. The substrate's quiet doctrine, holding canonically.

## D3.11 — Verification surface authority hierarchy doctrine

**The architect-error doctrine family (D2.2.11) gains a ninth empirical landing with a new subtype caught at Pod 3 HALT 1 Pre-A10:** *canon-doc-stale state rather than current tree*.

Architect Pre-A10 referenced "Sign slot offset +0x00 (in MAC-input range; existing layout)" for embedding_handle activation. Both:
- The OFFSET was wrong (+0x00 is hash, not embedding_handle)
- The very EXISTENCE of the field as a slot-resident value was wrong (reclaimed at Pod 1.10.2b2; no slot field exists)

Architect's source: `RECONSTITUTION.md:235` says `0x68 8 embedding_handle (u64; index into vm_embed_pool, defined Pod 3+)` — pre-Pod-1.10.2b2 spec; outdated since the slot reclaim. Canon doc lagged source-of-truth tree state by three pods.

**Doctrine canonized:**
- **Verification surface authority hierarchy: in-tree state (defines.asm, asm files) > narrative documents (RECONSTITUTION.md, design docs) > architect priors.**
- Architect cross-checks must defer to in-tree state; recon catches canon-doc-stale-state drift as a substrate-evolution verification surface.
- Narrative documents lag and require periodic synchronization; refresh discipline canonized as DEFERRED #85.

**Empirical landings of architect-error doctrine family** (D2.2.11 → D3.11):
1. D1.10.2a.10 — architect cost-table claim caught at recon
2. D1.10.2b1.8 — architect register-clobber claim
3. D1.10.2b2.9 — architect retrofit-count claim
4. D1.10.3.8 — architect bytecode-shape claim
5. D2.1.9 — architect site-enumeration claim
6. D2.2.11.A3 — architect retrofit-count claim (Pod 2.2)
7. D2.2.11.R6.a — architect helper-signature claim (Pod 2.2)
8. D2.2.11.R6.b — architect side-effect claim (Pod 2.2; load-bearing double-fire)
9. **D3.11** — architect canon-doc-stale-state claim (Pod 3; slot-layout reference predating Pod 1.10.2b2 reclaim)

The doctrine performs across all error subtypes regardless of architectural distance — count direction, mechanical completeness, side-effect tracking, **canon-doc-stale state**. Recon checks every architect-side claim regardless of subtype; in-tree code is canon; narrative documents are second-tier; architect priors are hypotheses.

Pod 3 C4 closes the immediate gap (RECONSTITUTION.md refresh covering Sign slot layout + Embedding section + Sign-non-MAC archaeology note + D3.11 footer reminder). DEFERRED #85 forward-logs the broader principle as ongoing canon refresh discipline.

---

## Resolution summary

| # | Description | Status |
|---|---|---|
| #65 | Sign embedding_handle relocation when Pod 3 (Maid) lands | **RESOLVED** — parallel side-table per D3.4; B12 empirical |
| #76 | Bit vocabulary expansion | **PARTIALLY RESOLVED FURTHER** — BIT_EMBEDDING_FORGE earned slot 4 |
| #80 | Pod 3.5+ Maid semantic operations | **NEW** — similarity, lookup, ingestion |
| #81 | Sign / Energy MAC retrofit candidate | **NEW** — Pod-1.7-archaeology asymmetry forward-log |
| #82 | Sign.provenance_handle activation candidate | **NEW** — D3.6 reclaimed-slot pattern reuse |
| #83 | Embedding pool capacity expansion | **NEW** — V1.0 conservative at 64; Pod 3.5+ pressure |
| #84 | Pod 3 throwaway test scripts | **NEW** — 21-script accumulation across 8 pods |
| #85 | RECONSTITUTION.md ongoing canon refresh discipline | **NEW** — D3.11 codified |

## Substrate state at seal

**Five typed pools** (Sign, Energy, Outcome, Cap, **Embedding**):
- **3 MAC-protected** (Cap, Outcome, Embedding)
- **2 non-MAC** (Sign, Energy) — Pod-1.7-archaeology asymmetry now structurally explicit (DEFERRED #81)

Every primitive across the typed pools carries full provenance (arena/owner/creator). Every successful primitive construction triggers spatial-merge ripple via single-fire floor-divided geometric decay (Sign/Energy via .construct_ok_outcome post-Path-A from Pod 2.2; Outcome direct paths via handler-explicit; OP_CAP_NEW via existing 1j benign double-fire; Embedding via greenfield single-fire by construction per D3.9).

**Every act of creation** is bit-check-gated by originating cap's bitmap (D2.2.6). **Subset-on-grant** prevents privilege escalation across delegation (D2.2.5). ROOT_CAP at cap_id=1 anchors all chains with both poles unbounded (`ENERGY_BUDGET_UNBOUNDED` metabolic + `CAP_BITMAP_UNBOUNDED` textural).

**Sign.embedding_handle** activated as typed cross-pool reference via parallel side-table (D3.4). cap_bitmap V1.0 vocabulary at **5/64 bits earned** (BIT_SIGN/ENERGY/OUTCOME/CAP/EMBEDDING_FORGE). Bits 5-63 reserved for organic future growth.

**Lexical embedding substrate-prep complete.** First substrate-USE pod after seven pods of substrate-EVOLUTION; Pod 3 inflection from substrate-prep arc to substrate-use arc validated empirically (zero prior-pod ripple; 16/16 B-items first attempt).

Pod 3.5+ Maid semantic operations (similarity, lookup, codebook ingestion) requires architect-authored prompt; do not initiate. Architect-led architectural sit before drafting Pod 3.5 recon — parallel to rethink moments before Pod 1.10.2b2 / Pod 2.1 / Pod 2.2 / Pod 3.

**Maid is born.**
