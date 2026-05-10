# Pod 3.9 Decision Record — Maid finds many (top-K + threshold filter)

**Pod:** 3.9 — third forge-tier substrate-USE pod; Maid V1.0 finder-of-many surface lands; substrate's recognition-axis V1.0 coverage completes
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-10
**Entry HEAD:** 4acd34f5dfafa83d907559a157b01e3ee99129da (Pod 3.8 seal — Maid imports)
**Entry contract:** c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f (canonical Pod 3.8 BOOTX64.EFI; empty-codebook default)
**Exit contract:** a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99

> Pod 3.9 lands the Maid's fourth surface — **finder-of-many** — alongside her existing housekeeper (3.5: cosine + dot + L2 + lookup_top1), composer (3.6: synthesis ops), and importer (3.8: codebook ingest). `OP_EMBEDDING_LOOKUP_TOP_K` (0xF2) takes a query embedding, K, and an f32 threshold, returns ≤K embedding_ids in descending cosine order on the operand stack, with K' count wrapped as Outcome::Ok on TOS. Five new doctrine entries land: D3.33 (stack-based-ephemeral / pooled-persistent result-representation convention), D3.34 (0xF0–0xFE reframed as embedding-tier extensions, broader than Pod 3.8's codebook-tier scope), D3.35 (top_k as housekeeper-tier generalization of lookup_top1), D3.36 (Outcome-wrap-with-variable-cardinality-output convention), D3.37 (NASM RIP-relative indexed-BSS-access discipline — bug fix). Build-time catches: 0. Substrate catches: 1 — the NASM addressing bug that produced [2,3,4,5,10] before fix; recon-prediction validated (Pod 3.9 sit-time predicted "1–3 catches at 3.9.B helper or 3.9.D handler"; the catch landed at 3.9.B helper indexed-BSS pattern). The Maid finds many.

---

## D3.33 — Result-representation convention at V1.0

**Stack-based for ephemeral collections; pooled for persistent typed primitives.** Names the architectural choice and its rationale.

**The rule.** When a substrate operation produces a *collection* of values (variable cardinality K' ∈ [0, K_max]), the V1.0 convention is:

| Persistence | Representation | Use case |
|---|---|---|
| Ephemeral (single-use; consumed by user pop sequence) | **Operand-stack-based** — push K' values + a count Outcome on TOS | top-K recognition; analogical-reasoning intermediate steps; query-result enumeration |
| Persistent (passed across ops; outlives the producing scope) | **Pooled typed primitive** — registry-tracked slot with MAC + accessors | typed-pool members (Sign / Energy / Outcome / Cap / Embedding); lifetime-managed entities |

**Why both options exist.** A persistent collection would warrant a sixth typed pool (Result[T]; parametric type) — but at V1.0 there is no consumer for such persistence. Top-K results are read once by the user program (popped + consumed); aggregation ops (centroid / mean / variance) that would consume a stable result-set don't exist; cross-result analogical operations don't exist. Building Result[T] now would commit substrate substantial surface (parametric type machinery; sixth pool BSS; constructor + accessor + lifetime semantics) for hypothetical future demand.

**Premature-abstraction-avoidance precedent.** D3.16 ("anticipated empirical pressure") established that substrate features should land when production scenarios demand them, not when they're architecturally appealing. D3.33 extends this to result-representation: ephemeral-stack form is the conservative-V1.0 default; pooled form lands when empirical demand surfaces. If Pod 3.10+ or V2 production scenarios require result-set persistence, Result[T] becomes a justified addition with concrete consumer use cases driving its surface.

**Implementation shape.** `OP_EMBEDDING_LOOKUP_TOP_K`:
1. Substrate-private compute `compute_top_k_raw(query, K, threshold) → K'` writes scratch arrays (`top_k_scratch_ids`/`top_k_scratch_scores`); selection-sorts descending; returns K'.
2. Handler reads scratch[0..K'-1], pushes ids onto operand stack in **reverse** (worst-first), so TOS-most-recent-id is the best match after handler completes.
3. Handler wraps K' as Outcome::Ok via `.construct_ok_outcome` and pushes onto operand stack TOS-final.
4. User program: `outcome_unwrap_ok` → K' on TOS → pop K' (count first) → pop K' ids best-to-worst.

**Operand-stack net delta**: `-3` (popped query_id, K, threshold) `+K'` (pushed ids) `+1` (pushed Outcome). Variable based on K'; clean per-op accounting.

## D3.34 — 0xF0–0xFE embedding-tier extensions row (reframes Pod 3.8 D3.32)

**Broader scope than Pod 3.8's "codebook-tier" framing.** Pod 3.8 introduced 0xF0 (`OP_EMBEDDING_IMPORT`) and 0xF1 (`OP_EMBEDDING_IMPORTED_HANDLE`) and reserved 0xF2–0xFE for "codebook-tier extensions." Pod 3.9 ratifies a broader framing: **0xF0–0xFE is the embedding-tier-extensions row, Pod 3.8+** — overflow for embedding-tier ops once the 0xC0–0xCF row filled.

**The reframe.** Pod 3.8 D3.32 narrower scope was a sit-time framing; Pod 3.9 surfaces an empirical need (top-K is embedding-tier but not codebook-specific) which exposes the over-specificity of "codebook-tier" naming. D3.34 widens the row's scope retroactively without invalidating Pod 3.8's allocations:

| Slot | Pod | Op | Service-tier classification |
|---|---|---|---|
| 0xF0 | 3.8 | `OP_EMBEDDING_IMPORT` | codebook-tier write (handler deferred per #91) |
| 0xF1 | 3.8 | `OP_EMBEDDING_IMPORTED_HANDLE` | codebook-tier read |
| 0xF2 | 3.9 | `OP_EMBEDDING_LOOKUP_TOP_K` | **housekeeper-tier (not codebook-tier)** |
| 0xF3–0xFE | reserved | future | embedding-tier (any sub-classification) |

**Pod 3.8 D3.32 stands amended**: codebook write/read asymmetry remains the doctrinal point; the row scope was over-specific. D3.34 supersedes D3.32's row-naming; D3.32's substrate-private-write/dispatch-runtime-read asymmetry doctrine remains intact for codebook ops specifically.

**Forward discipline.** When a row is reserved for "tier X extensions," the framing should be the **broadest tier** that legitimately covers the operations, not the narrowest. Pod 3.8's "codebook-tier" was too narrow because top-K (recognition) and codebook-import (provenance) both share embedding-tier substrate but not codebook-specific concern.

## D3.35 — top_k as housekeeper-tier generalization of lookup_top1

**Maid V1.0 fourth capability variant.** Pod 3.5 housekeeper surface includes `lookup_top1` (D3.18) — single-result recognition. Pod 3.9 extends recognition to K-result via `lookup_top_k` along the same axis. Maid-tier identity preserved; doctrine lineage extends from D3.18 → D3.35.

**The four Maid V1.0 capabilities:**

| Pod | Surface | Capabilities |
|---|---|---|
| 3.5 | Housekeeper | cosine + dot + L2 + lookup_top1 + sign_handle |
| 3.6 | Composer | add + subtract + scale + normalize + lerp + synthesis_handle |
| 3.8 | Importer | boot_ingest_codebook + imported_handle |
| **3.9** | **Finder-of-many** | **lookup_top_k** |

**The recognition-axis is now V1.0-complete** (single-best + K-best + threshold-filtered). The substrate's lexical-computation pole reaches **operational completeness on the recognition axis**; future axes (aggregation, cross-result analogy, multi-codebook) remain open for Pod 3.10+ / V2.

**Helper-pair convention** holds (D3.7 / D3.18 lineage): `compute_top_k_raw` is the substrate-internal computation primitive; `OP_EMBEDDING_LOOKUP_TOP_K` is the dispatch surface that wraps it with operand-stack marshaling + Outcome construction. Mirrors `lookup_top1` ↔ `compute_lookup_top1_raw` shape from Pod 3.5.

**Cost-table value 100,000j** matches lookup_top1 (D3.17 anticipated-worst-case): same scan cost (both pool-bounded N=2048); K-tracking overhead negligible vs cosine-compute (~400j × 2048 ≈ 819,200j actual machine work; pricing is conventional, not measured, per D3.17 stance).

## D3.36 — Outcome-wrap-with-variable-cardinality-output convention

**The Outcome wraps the count, not the values.** When an op produces multiple outputs (collection), the Outcome::Ok wraps the **count** of values produced; the values themselves sit beneath the Outcome on the operand stack.

**Stack layout post-LOOKUP_TOP_K:**
```
Stack (bottom → top):
  ..., [pre-call state]
  id_K-1   (worst-ranked of returned set)
  id_K-2
  ...
  id_1
  id_0     (best match)
  Outcome::Ok(K')   ← TOS
```

User pattern:
```
OP_EMBEDDING_LOOKUP_TOP_K
OP_OUTCOME_UNWRAP_OK    ; pops outcome_id, pushes K' value
LET count = pop()       ; user binds count (single integer)
LOOP count times: LET id_i = pop()    ; user reads ids best-to-worst
```

**Why this convention works.** The Outcome::Ok carries the *cardinality decision* — "how many results did this op produce (∈ [0, K_max])?" — which the user must learn before consuming the values. Wrapping the count as Outcome::Ok lets standard error-path dispatch (Outcome::Err on invalid_arg / invalid_id) apply uniformly: errors land in the Outcome variant (no values pushed); success lands in the Outcome::Ok variant (K' values pushed below the Outcome).

**Convention generalizes.** Any future variable-cardinality op (e.g., hypothetical `OP_EMBEDDING_AGGREGATE_GROUP` returning ≤N centroids) adopts the same shape:
- **Inputs**: op-specific operand-stack arguments
- **Output (success)**: K' result values pushed below; Outcome::Ok(K') on TOS
- **Output (error)**: zero result values pushed; Outcome::Err(reason) on TOS

The pattern decouples error-path semantics (Outcome variant dispatch) from value cardinality (Outcome::Ok payload integer).

## D3.37 — NASM RIP-relative indexed-BSS-access discipline (substrate-catch)

**The rule.** In NASM 64-bit `-f bin` mode, indexed BSS access via `[rel sym + reg*scale]` does **NOT** generate correct x86_64 addressing. RIP-relative addressing is `RIP+disp32` only — it cannot combine with a register index. NASM silently produced broken code at Pod 3.9.B; the substrate read zero memory instead of the intended scratch slot. Pattern that DOES work: `lea reg_base, [rel sym]; [reg_base + reg_idx*scale]`.

**Empirical exposure (Pod 3.9.E B49).** `compute_top_k_raw` used `[rel top_k_scratch_scores + rcx*4]` and similar throughout (find-min loop; selection sort; append; replace). Bug-find chain:
1. **B49 first run** produced `[2, 3, 4, 5, 10]` instead of predicted `[1, 2, 3, 4, 5]`. id=1 evicted, id=10 inserted; id=6/7/8/9 missing. Empirical pattern impossible from any simple algorithmic bug under correct cosine inputs.
2. **`embedding_cosine` probe** confirmed cos(query, id=1) = 0x3F800000 byte-exact ✓ — cosine compute correct.
3. **`lookup_top1` probe** returned id=1 ✓ — scan loop + MAC verify + self-skip all correct.
4. **K-incremental probe** (K=1) returned id=10 — bug isolated to compute_top_k_raw's K-tracking specifically.
5. **Inline debug print** (movd edi, xmm0/xmm1; print_hex32) at find-min comparison showed xmm1 = 0x00000000 every iteration. find-min reading scratch_scores[0] returned zero despite the prior append cycle writing 1.0 there.
6. **Codebase audit**: `[rel sym + reg*scale]` pattern occurred ONLY in Pod 3.9 code (maid.asm + cbs_vm.asm). Existing convention (codebook.asm:97-98; cbs_vm.asm:3927-3928; cap.asm:324, 368) used `lea reg, [rel sym]; [reg + idx*scale]`.

**Fix shape.** All 14+ instances rewritten in maid.asm (compute_top_k_raw append/find-min/replace/sort paths) and 1 in cbs_vm.asm (op_embedding_lookup_top_k push-ids loop). At each access site:
```nasm
; BROKEN (NASM silently miscompiles):
mov [rel top_k_scratch_ids + r12*8], r13
movss xmm2, [rel top_k_scratch_scores + rcx*4]

; FIXED (matches existing substrate convention):
lea r10, [rel top_k_scratch_ids]
mov [r10 + r12*8], r13
lea r11, [rel top_k_scratch_scores]
movss xmm2, [r11 + rcx*4]
```

**Why NASM silent-miscompiles.** RIP-relative emit form is `[RIP + disp32]` (no SIB byte permitted in this mode). When NASM sees `[rel sym + reg*scale]`, it cannot encode RIP-relative + index, so it falls back to absolute-32-bit emit `[disp32 + reg*scale]` where `disp32` is the link-time absolute address. For a flat-binary build with high origin, disp32 may not equal the true symbol address (sign-extension at runtime; image-base offset; depends on linker). The result accesses a different memory region than intended — typically a zero-mapped or otherwise-unallocated region — silently.

**Forward discipline.** When indexing into a BSS array in 64-bit NASM `-f bin`:
1. **lea the base** into a caller-saved register (r10, r11, rax) before the access section.
2. **Use `[base + idx*scale]`** for the indexed access.
3. **Re-lea after any helper call** that clobbers the base register.

**Audit grep**: `[rel <symbol> + r<digit>*<digit>]` pattern returns zero matches in canonical Pod 3.9 substrate (re-verified post-SEAL). Future substrate code lands with this discipline.

**Pod 3.9 = 1 substrate-catch**, recon-prediction validated. Pod 3.9 sit-time recon notes (Q-rating section) predicted "1–3 catches at 3.9.B helper or 3.9.D handler" given new helper + handler operand-stack-protocol surface; the actual catch landed at 3.9.B helper's indexed-BSS-access pattern (substrate-behavior catch, not build-time catch). The catch surface differs from Pod 3.7/3.8's pattern (build-pipeline integration) — recognition pods land catches at substrate-behavioral surface where new computational shapes are introduced.

---

## Q-rating ratifications (Pod 3.9.A pre-flight + audit)

| # | Question | Ratified |
|---|---|---|
| **Q1** | Maid V1.0 framing — "Maid finds many" as housekeeper extension (preserves doctrine continuity from D3.18) | ✓ ratified per D3.35 |
| **Q2** | Top-K result representation — stack-based push-K'-ids-then-Outcome-of-K' (avoids premature pool abstraction) | ✓ ratified per D3.33 + D3.36 |
| **Sub-Q2** | Operand-stack ordering convention: ids first (descending; best at top), then Outcome-of-K' last — user pops Outcome → K' → K' ids best-to-worst | ✓ ratified |
| **Q3** | Threshold filter semantics — single op with threshold parameter (f32-as-i64); -INF (0xFF800000) sentinel for unfiltered top-K | ✓ ratified |
| **Sub-Q3** | Threshold = -INF case is unfiltered top-K (any finite cosine passes via IEEE 754 ≥ -INF) | ✓ confirmed empirically (B49 run with threshold=-INF) |
| **Q4** | Opcode allocation — 0xF2 (within reframed 0xF0-0xFE embedding-tier extensions row per D3.34) | ✓ ratified per D3.34 |
| **Sub-Q1** | Pod 3.8's "codebook-tier extensions" row scope (0xF2-0xFE) reframed broader as "embedding-tier extensions, Pod 3.8+" | ✓ ratified — D3.34 amends D3.32 row scope |
| **Q5** | Cost model — 100,000j matching lookup_top1 (D3.17 anticipated-worst-case; doctrine continuity over actual machine work) | ✓ ratified |
| **Q6** | Result lifetime — temporary single-use (coupled with Q2 stack-based) | ✓ ratified |
| **Q7** | Forge-path adaptability — sorted-array K-tracking in BSS scratch (`top_k_scratch_ids` + `top_k_scratch_scores`); MAX_K=256; new compute_top_k_raw helper; ~150 lines | ✓ ratified |

---

## 3.9.A–3.9.F chunk audit

| Chunk | Identity | Contract | Catches |
|---|---|---|---|
| 3.9.A | Pre-flight + Q1-Q7 sit (no code) | n/a (Pod 3.8 base c09f2b3c) | 0 |
| 3.9.B | OP_EMBEDDING_LOOKUP_TOP_K constant + MAX_K + BSS scratch + compute_top_k_raw helper | (substrate-changed; not separately checkpointed) | **1 (latent — surfaced at 3.9.E)**: NASM `[rel sym + reg*scale]` silently miscompiles indexed BSS access |
| 3.9.C | Cost-table annotation 0xF0/0xF1/0xF2 row | (substrate-changed; not separately checkpointed) | 0 |
| 3.9.D | atreyu emitter + cbs_vm dispatch entry + handler (op_embedding_lookup_top_k) | `7d1a76e02dc49414fd78b5c610618c44a00347db4e4987086b26af6b0b185bfb` | 0 (build-time clean; latent helper bug not yet exposed) |
| 3.9.E | R10 bit-exact sim + B49 canary + diagnostic-probe scaffolding | (B49 substrate auxiliary; canonical preserved at 7d1a76e0…) | **1 surfaced**: B49 produced [2,3,4,5,10] instead of [1,2,3,4,5]; bug-isolation chain (lookup_top1 + cosine probe + K-incremental probe + inline-debug-print) localized to NASM RIP-relative indexed-BSS pattern; fix landed (lea+base discipline per D3.37); B49 re-runs as [1,2,3,4,5] (sum=15 unambiguous validation) |
| 3.9.F | SEAL — decision record + regression + commit + push | `a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99` | — |
| **SEAL** | canonical contract | `a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99` | — |

**Build-time catches: 0**. **Substrate-catches: 1** (the NASM addressing bug). Pattern differs from Pod 3.7/3.8 prediction shape (build-pipeline integration catches) — Pod 3.9's recognition-pod-with-new-computational-shape clustered the catch at substrate-behavioral surface where new internal data structures (sorted-array scratch with indexed access) interacted with NASM's RIP-relative emit constraints. Recon-prediction validated (Pod 3.9 sit-time predicted "1–3 catches at 3.9.B helper or 3.9.D handler"); actual = 1 catch at 3.9.B helper.

**Architect-framing-corrections count: 0** at Pod 3.9. Architect's Q1-Q7 framings ratified as-recommended; sub-Q1 row-reframing (codebook-tier → embedding-tier-extensions) was TB recommendation accepted, not architect framing requiring correction.

---

## B49 boot-ingestion canary + bug-find narrative (3.9.E)

**Substrate built with `inputs/test_codebook_b49.txt`**: 10 entries × 384 dims with monotonically decreasing cosines vs query (entry i: vec[0]=1.0, vec[1]=i*0.1, rest=0; cosine = 1/sqrt(1 + (i*0.1)²)). Query forged at runtime as identical vector to entry_0 (id=11; vec=(1.0, 0.0, 0, …)).

**R10 bit-exact prediction (`tools/pod39_r10_sim.py`)**: top-5 in descending cosine order = `[1, 2, 3, 4, 5]` (substrate ids). Bit-exact f32 cosines match Form A evaluation order (D3.28 self-verifying canon).

**Bug-find narrative (six probes; full attribution chain):**

1. **B49 first run** (canary contract verified; substrate auxiliary built): output = `[2, 3, 4, 5, 10]`. id=1 (cos=1.0) evicted; id=10 (cos≈0.7434) inserted; id=6/7/8/9 missing. Pattern impossible from algorithmic-correctness scenario under correct cosine inputs.

2. **`embedding_cosine` probe** (uses Pod 3.5-validated cosine compute):
   - cos(q, id=1) = 1065353216 = 0x3F800000 ✓
   - cos(q, id=6) = 1063581998 = 0x3F64F06E ✓
   - cos(q, id=10) = 1061046406 = 0x3F3E4886 ✓
   All byte-exact match R10 predictions. Cosine compute eliminated as bug source.

3. **`lookup_top1` probe** (Pod 3.5-validated single-best scan):
   - lookup_top1(q) = 1 ✓
   Scan loop + MAC verify + self-skip + score comparison all working correctly. Bug isolated to compute_top_k_raw-specific path.

4. **K-incremental probe** (Pod 3.9 K=1, K=2, K=3 against B49):
   - K=1 returns best=10 (should be 1) — bug manifests even in single-element scratch; not K-tracking specifically.
   - K=1 with scratch[0] populated by id=1 (cos=1.0): every subsequent candidate (cos < 1.0) replaces scratch[0]. Replacement happening unconditionally.

5. **Inline debug print** (movd edi, xmm0/xmm1; call print_hex32 inside compute_top_k_raw at find_min_done):
   - xmm0 = new_score (correct per iteration: 0x3F7EBAC1, 0x3F7B0756, …)
   - xmm1 = min_score (0x00000000 every iteration — the bug)

   `[rel top_k_scratch_scores]` (no index) read scratch[0] correctly initially, but find-min loop's `[rel top_k_scratch_scores + rcx*4]` (indexed) read zero memory, propagating xmm1 = 0 through the loop.

6. **Codebase audit**: `[rel <sym> + reg*scale]` pattern occurred ONLY in Pod 3.9 code. Existing pool / registry / cap-pool accesses use `lea reg, [rel sym]; [reg + idx*scale]` (codebook.asm:97-98; cbs_vm.asm:3927-3928; cap.asm:324, 368). Pod 3.9 introduced the broken pattern; pre-Pod-3.9 substrate is unaffected.

**Fix shape**: 14+ access sites in maid.asm (`compute_top_k_raw` append + find-min + replace + selection sort) and 1 in cbs_vm.asm (`.op_embedding_lookup_top_k_push_ids_loop`). Pattern: `lea r10, [rel <ids_sym>]` and `lea r11, [rel <scores_sym>]` near each access section; use `[r10/r11 + idx*scale]`. Sort path swap rewritten to use rsi/esi as temps (r10/r11 hold bases through swap).

**B49 re-run on bug-fixed substrate**: output = `[1, 2, 3, 4, 5]`; sum = 15 (the only valid 5-subset of {1..10} summing to 15 is `{1,2,3,4,5}` — unambiguous validation independent of font/glyph rendering ambiguity in PNG screen-dump). R10-vs-canary ordering match. PNG produced; canonical contract preserved at exit.

**Diagnostic-probe scaffolding** (`demo_pod39_b49_probe`, `demo_pod39_b49_probe_k`, `tools/pod39_b49_probe_runner.sh`) is left in place for forensic record. Inert in canonical builds (atreyu CLI subcommands; not executed by canonical canary set; substrate sha unchanged whether scaffolding exists or not).

**Three-oracle empirical anchor**: substrate-catch + recon-prediction-validated + diagnostic-probe-scaffolding-as-forensic-record establishes the Pod 3.9 catch-surface profile.

---

## DEFERRED state (Pod 3.9 close)

| # | Description | Status |
|---|---|---|
| #80 | Maid semantic operations (Pod 3.5+) | RESOLVED at Pod 3.8 |
| #82 | Sign.provenance_handle activation candidate | unchanged |
| #83 | Embedding pool capacity expansion | RESOLVED at Pod 3.7 |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.9 adds 4 scripts (`gen_b49_codebook.py`, `pod39_r10_sim.py`, `pod39_b49_runner.sh`, `pod39_b49_probe_runner.sh`) — last two retained in tree per #93 |
| #85 | RECONSTITUTION.md ongoing canon refresh | unchanged |
| #89 | Build-shell-determinism hazard | RESOLVED at Pod 3.7 |
| #90 | Outcome pool capacity below embedding pool | RESOLVED at Pod 3.7 |
| #91 | **Codebook-symmetry**: runtime `OP_EMBEDDING_IMPORT` (0xF0) handler activation (renumbered from prior Pod 3.8 #91 — same content; no collision per reconciliation) | continues; future-pod activation when production scenarios demand runtime codebook forge |
| #92 | **Stream-stability**: aggregation / cross-result analogical operations (consumer ops for top-K result-set persistence) — would justify Result[T] sixth-pool addition per D3.33 if surfaced | NEW at Pod 3.9 |
| #93 | **Diagnostic-probe-scaffolding policy**: when to retain (forensic record across pods; helps future debugging of similar surface) vs retire (per-pod cleanup; reduces tree clutter) — formalize at architect call | NEW at Pod 3.9 (optional; architect to ratify policy) |

**Three new deferrals at Pod 3.9** (#92 stream-stability; #93 probe-scaffolding policy; #91 carried forward with reconciled numbering).

---

## Substrate state at SEAL

**Five typed pools** (Sign / Energy / Outcome / Cap / Embedding) — unchanged from Pod 3.8.

**Three non-MAC parallel side-tables** for Embedding linkage — unchanged.

**Substrate-private state cache** — unchanged (`vm_codebook_meta` from Pod 3.8).

**NEW BSS scratch (Pod 3.9)**:
- `top_k_scratch_ids` — `MAX_K × 8` = 2048 bytes; embedding_id values during compute_top_k_raw scan
- `top_k_scratch_scores` — `MAX_K × 4` = 1024 bytes; corresponding f32 cosine scores

Total Pod 3.9 BSS additions: 3 KB. Substrate-private; overwritten on each compute_top_k_raw invocation; not user-visible state.

**OP_EMBEDDING_ row 0xF0–0xFE allocation** (per D3.34 reframed embedding-tier extensions):
- 0xF0 OP_EMBEDDING_IMPORT — constant reserved (Pod 3.8); handler deferred (DEFERRED #91)
- 0xF1 OP_EMBEDDING_IMPORTED_HANDLE — witness accessor live (Pod 3.8)
- 0xF2 **OP_EMBEDDING_LOOKUP_TOP_K — housekeeper-tier; live (Pod 3.9)**
- 0xF3–0xFE — reserved for embedding-tier extensions (any sub-classification)

**Maid V1.0 surface complete on the recognition axis**: housekeeper (3.5: cosine + dot + L2 + lookup_top1) + composer (3.6: synthesis ops) + importer (3.8: codebook ingest) + **finder-of-many (3.9: lookup_top_k)**. The recognition axis covers single-best (lookup_top1), K-best (lookup_top_k), threshold-filtered (lookup_top_k with threshold parameter); aggregation / cross-result analogy / multi-codebook remain open for Pod 3.10+ / V2.

**NASM RIP-relative indexed-BSS-access discipline (D3.37)** newly canonical: substrate code uses `lea reg, [rel sym]; [reg + idx*scale]` for indexed BSS access; `[rel sym + reg*scale]` pattern is forbidden (silently miscompiles).

**Two-build determinism** preserved at canonical Pod 3.9 SEAL contract `a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99` — re-confirmed at SEAL.

**Pod 3.9 architect-error catches**: zero. Architect-framing-corrections count = 0.

**Pod 3.9 substrate-catches**: one (D3.37 NASM addressing bug; recon-prediction-validated; surfaced via 6-probe diagnostic chain at 3.9.E; fixed across 14+ access sites in maid.asm + cbs_vm.asm; B49 PASS post-fix).

---

## Headline moments

**Substrate-philosophical**: D3.33 names the V1.0 result-representation convention (stack-based-ephemeral; pooled-persistent) and codifies premature-abstraction-avoidance as architectural discipline. D3.36 codifies variable-cardinality-output Outcome wrap convention.

**Doctrinal continuity**: D3.35 extends D3.18 (lookup_top1 housekeeper canon) to D3.35 (top_k housekeeper-tier generalization). Maid V1.0's recognition axis reaches operational completeness.

**Doctrinal reframe**: D3.34 widens 0xF0-0xFE row scope from "codebook-tier" (Pod 3.8 D3.32 narrower) to "embedding-tier extensions, Pod 3.8+." D3.32's substrate-private-write/dispatch-runtime-read asymmetry doctrine remains intact for codebook ops; row-naming amends.

**Substrate discipline**: D3.37 names the NASM RIP-relative indexed-BSS pattern as forbidden; substrate convention (lea + base register) becomes canonical doctrine post-bug-find empirical exposure.

**Recon-prediction validated**: Pod 3.9 sit-time predicted "1–3 catches at 3.9.B helper or 3.9.D handler"; actual = 1 catch at 3.9.B helper indexed-BSS-pattern. Substrate-USE pods with new computational shapes cluster catches at substrate-behavioral surface; pattern differs from Pod 3.7/3.8 mechanical-pod build-pipeline catch profile.

**Forensic-record precedent**: diagnostic-probe scaffolding (`demo_pod39_b49_probe`, `demo_pod39_b49_probe_k`, `pod39_b49_probe_runner.sh`) retained in tree across SEAL; #93 deferred for architect policy ratification on retain-vs-retire convention.

---

## V1.0 progress checkpoint

**Pod 3.9 = 3 of 6 V1.0 pods sealed.** Pods 3.10 / 3.11 / 3.12 remain.

The Maid recognizes; the Maid composes; the Maid imports; the Maid finds many. **The substrate's lexical-computation pole reaches operational completeness on the recognition axis at V1.0** — single-best recognition (Pod 3.5 lookup_top1), K-best recognition with threshold (Pod 3.9 lookup_top_k), and the four Maid V1.0 capability variants are live.

What remains for V1.0 is broader architectural surface beyond Maid's current scope — exact framing deferred to Pod 3.10 architectural sit. Candidate axes: aggregation (centroid / mean / variance over result-sets — would justify Result[T] sixth-pool per D3.33 + #92), orthogonalization (Pod 3.10 working title), maintenance (Pod 3.11), or other V1.0-completing surfaces.
