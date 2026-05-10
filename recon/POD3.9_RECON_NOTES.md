# Pod 3.9 Recon Notes — "Maid finds many" (top-K + threshold) sit prep

**Status:** Informal recon notes for HALT 1 architect ratification. NOT a formalized recon report. Seven findings + recommendations surfaced for sit-time call before any code lands.

**Entry HEAD:** 4acd34f5dfafa83d907559a157b01e3ee99129da (Pod 3.8 seal — Maid imports)
**Entry contract:** c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f (canonical Pod 3.8 BOOTX64.EFI; empty-codebook default)
**Three-oracle:** ✓ HEAD = origin/main = ls-remote at 4acd34f5
**Identifier audit:** D3.33+/B49+/top_k/TOP_K/find_many — zero canonical matches in tree (2 false-positive matches are `lookup_top1` substring artifacts in Pod 3.5 docs)
**Build chain:** unchanged (NASM 2.16.01 / mtools 4.0.43 / QEMU 8.2.2 in WSL; build.sh dual-layer pinning + B47 meta-canary in place)

---

## Q1 — Maid V1.0 framing (substrate-philosophical centerpiece)

**Two paths:**

### (a) "Maid finds many" — natural generalization of lookup_top1
Pod 3.5 housekeeper surface includes lookup_top1 (D3.18 single-result recognition). Top-K extends single→many along the same axis. Maid-tier identity preserved; doctrine continuity holds.

### (b) Beyond-Maid substrate feature
Top-K introduces collection semantics not present in housekeeper/composer/importer. Result representation is a substrate-wide concern. Could warrant its own service-tier framing.

**Sub-philosophical question**: when a service's operation generalizes single→many, does the increase in scope warrant service-tier reframing?

**TB read**: only if the new operation requires *structural surface* that pre-exists outside the service's domain. For top-K, the result-collection concern is **endemic to the operation** — it doesn't pre-exist as substrate concern that top-K just consumes. The result representation IS Maid-internal; the operation stays Maid-tier.

Compare: Pod 3.6 added synthesis (six new ops + tuple side-table + helper-pair convention), and that was framed as Maid-tier extension because the structural surface (synthesis tuple) was endemic to the operation, not pre-existing substrate concern. Same framing applies here.

**TB recommendation: (a) "Maid finds many".** Pod 3.5 housekeeper surface extends; lineage preserved. Maid V1.0 surface gains its fourth capability variant: **finding many** (housekeeper sub-mode), alongside finding one (lookup_top1), composing (synthesis), and importing (codebook).

The "find many" framing is also doctrinally clean: lookup_top1 was D3.18 housekeeper canon; top_k generalizes D3.18; doctrine continuity holds without framework rewrite.

---

## Q2 — Top-K result representation (substrate-philosophical centerpiece per architect)

**Three options, distinct architectural shapes:**

### (a) Stack-based — push K embedding_ids in order; user pops them
- **Pros**: Simplest; no new typed primitive; no new BSS; no lifetime concerns; natural single-use consumer pattern; matches existing operand-stack convention
- **Cons**: K bounded by stack capacity (vm_stack = 512 qwords; K ≤ ~256 fits); user must remember to pop K times; no structural identity for "this result-set" (can't be passed to other ops as a unit)

### (b) Typed Result[T] pool — new primitive type with slot management
- **Pros**: First-class result representation; can be passed to other ops; persistent across program execution; forge/witness model applies (familiar typed-pool semantics)
- **Cons**: New typed primitive (sixth pool — Sign/Energy/Outcome/Cap/Embedding/**Result**); new opcode row; new constructor + accessor + lifetime semantics; substantial substrate surface for one V1.0 use case (top-K); Result[T]'s parametric nature complicates substrate's typed-primitive convention (T is template-style; substrate has no parametric type infrastructure)

### (c) Reverse side-table — D3.20→D3.27 family extension
- **Pros**: Lightweight; mirrors existing non-MAC parallel linkage convention; substrate-private write at op execution; dispatch-runtime read via accessor
- **Cons**: Side-table indexed by what? Query embedding_id is natural, but K and threshold are op-call parameters — re-running same query with different K/threshold would overwrite. Either pre-allocate K slots per query (wastes space; max K must be picked) or track "last result" (single-slot per query; loses parallel-query support). Doesn't fit the side-table pattern cleanly.

**Tradeoff analysis**:

The "results passed to other ops as a unit" concern (b's pro) — **NOT a clear V1.0 use case**. What would consume a top-K result-set? Aggregation ops (centroid, mean, variance) don't exist in V1.0. Cross-result analogical operations don't exist. The result-set is consumed by the user program reading individual ids, which stack-based supports natively.

The "persistent / reusable" concern (b's pro) — **NOT a clear V1.0 use case**. Production scenarios query and read; they don't query, store, requery, recompare. If they do, they can store the popped ids in vm_vars themselves (existing var-binding mechanism).

The "first-class" concern (b's pro) — substrate-aesthetic, not load-bearing. Premature abstraction.

**TB recommendation: (a) stack-based.** V1.0 ships the simplest form; future Pod (3.10+? V2?) can add Result[T] pool if production demands surface persistence/passing. The architectural cost of (b) — sixth typed pool + parametric type infrastructure — is high; deferring until empirical demand justifies it matches D3.16 anticipated-empirical-pressure precedent.

**Operand stack mechanics**: top_k pushes K' embedding_ids in **descending cosine order** (best match top of stack), then pushes K' itself as the count. User does:
```
PUSH query_id
PUSH K
PUSH threshold (f32-as-i64)
OP_EMBEDDING_LOOKUP_TOP_K
; Stack now: [..., id_K-1, id_K-2, ..., id_1, id_0_best, K']
; User reads K' first, then loops K' times popping ids
```

Or alternative: push K' on top first, then user reads count + pops K' ids. Either ordering works; pick one for the convention.

**Recommendation**: top_k pushes ids first (descending order; best at top), then K' count last. User pops K' (knows count first), then pops K' ids. Matches operand-stack TOS-is-rightmost-arg convention from synthesis ops.

---

## Q3 — Threshold filter semantics

**Three options:**

### (a) Top-K always; threshold filters post-K
First compute top-K via cosine ranking; then filter results below threshold. Returns ≤K ids (could be 0 if no candidates above threshold).

### (b) Threshold-first; return min(matches, K)
First filter all candidates above threshold; then take top-K of survivors. Returns ≤K ids.

### (c) Two ops: top_k_strict (always K) and top_k_threshold (≤K filtered)
Distinct ops, distinct semantics:
- **top_k_strict**: always returns exactly K ids (lowest-ranked could be poor matches). Use case: exploratory analogical reasoning where you want neighborhoods regardless of quality.
- **top_k_threshold**: returns ≤K ids, all above threshold. Use case: confidence-bounded retrieval where you want quality guarantee.

**Semantic equivalence note**: (a) and (b) produce **identical result sets** when correctly implemented. The top-K-of-(filtered set) equals (top-K of all) ∩ (above threshold), provided K' ≤ K and ranking is total-ordered. The implementation choice (filter-first-rank-second vs rank-first-filter-second) is internal to the substrate; user-visible behavior is identical.

**Single-op-with-threshold-parameter** is the cleanest API:
- One opcode (`OP_EMBEDDING_LOOKUP_TOP_K`)
- Three operand-stack inputs: query_id, K, threshold (f32-as-i64)
- Threshold = -INF (or specific sentinel like `0xFF800000` = -inf-as-f32) means "no threshold filtering" — behaves like pure top-K
- Threshold = high value means "few results survive" — could return 0 ids
- Threshold tunes recall vs precision continuously; user chooses

**TB recommendation: (a) — single op with threshold parameter; threshold = -INF sentinel for unfiltered top-K**. Rationale:
- API simplicity (one opcode, not two)
- Threshold continuum supports both use cases (c's two-op split) via parameter tuning
- Implementation can choose (a) or (b) order internally based on heuristic (e.g., if threshold near -inf, skip post-filter; if threshold high, filter early)
- User-visible semantic stays consistent

The `count K' returned on stack` (per Q2 stack-based recommendation) communicates "how many matched the threshold" naturally — user reads K' to know how much to consume.

---

## Q4 — Opcode allocation

**Current 0xC* row utilization** (Pod 3.5/3.6 Maid-tier; full):

| Range | Pod | Allocation |
|---|---|---|
| 0xC0–0xC4 | 3 (substrate-prep) | NEW + accessors + GET_DIM |
| 0xC5–0xC9 | 3.5 (housekeeper) | SIGN_HANDLE + COSINE + DOT + L2 + LOOKUP_TOP1 |
| 0xCA–0xCE | 3.6 (composer) | ADD + SUBTRACT + SCALE + NORMALIZE + LERP |
| 0xCF | 3.6 (composer) | SYNTHESIS_HANDLE |

**0xC* row is full.** Pod 3.9 top-K needs a different home.

**Available rows** (tree-wide opcode audit):

| Range | Status | Slots | Note |
|---|---|---|---|
| 0xA8–0xAF | Sign-reserved | 8 | Wrong service; don't squat |
| 0xBB–0xBF | Cap-reserved | 5 | Wrong service |
| 0xD9–0xDF | Energy-row tail | 7 | Wrong service; semantic mismatch |
| 0xE8–0xEF | Demod-reserved (Pod 1.12) | 8 | Wrong service; forward-anchor |
| **0xF2–0xFE** | **Codebook-tier extensions (Pod 3.8)** | **13** | Pod 3.8 reserved this range as "codebook-tier"; if reframed as "embedding-tier extensions (Pod 3.8+)" it can absorb top-K |

**Sub-decision**: how strictly is 0xF0–0xFE "codebook-tier"?

Pod 3.8 D3.32 says 0xF0 = OP_EMBEDDING_IMPORT (codebook-tier write), 0xF1 = OP_EMBEDDING_IMPORTED_HANDLE (codebook-tier read), 0xF2–0xFE = "reserved for codebook-tier extensions." But the row is structurally "embedding-tier-V1.0+ overflow from full 0xC* row." Top-K is embedding-tier (operates on embedding pool), even though it's not codebook-specific.

**Reframing**: 0xF0–0xFE is **"embedding-tier extensions row, Pod 3.8+"** — Pod 3.8 used 0xF0/0xF1 for codebook-tier; Pod 3.9 uses 0xF2 for top-K (recognition extension); future pods use remaining 0xF3–0xFE for further embedding-tier ops.

**TB recommendation: 0xF2 OP_EMBEDDING_LOOKUP_TOP_K**, with framing note that 0xF0–0xFE row is embedding-tier-extensions (not strictly codebook-tier). 0xF3–0xFE remain reserved for future embedding-tier ops (Pod 3.10+ aggregation? Pod 3.11+ multi-codebook?).

Doctrine refinement candidate: D3.X (Pod 3.9 sit) — name the 0xF0–0xFE row's broader scope; close the framing question definitively.

---

## Q5 — Cost model

**Computational shape**: top-K over N candidates is O(N log K) ranking + O(N × cosine_compute_cost) per-candidate compute. For Pod 3.7 production-scale (N = 2048; cosine ≈ 400j per candidate), full scan = 2048 × 400j ≈ 819,200j. Heap maintenance is sub-linear (O(log K) per insertion, K ≤ ~32 in practical cases) — negligible vs cosine compute.

**Existing precedent (D3.17, Pod 3.5)**: lookup_top1 cost-table value = **100,000j** as static worst-case for Pod 3.5's 256-pool (actual 256 × 400j ≈ 102,400j; rounded). Cost-table value did NOT auto-update at Pod 3.7 EMBEDDING_POOL_SLOTS=2048 expansion — it remains 100,000j despite actual machine work scaling 8× to ~819,200j. Pricing is conventional, not measured.

**Sub-philosophical question for Pod 3.9**: should the substrate's cost-table values track actual machine work, or remain fixed pricing decisions?

**Pod 3.5 precedent suggests**: fixed pricing. Cost-table values are doctrine, not measurements. The substrate's r14 mechanism enforces *budget* not *cost-accuracy*.

**TB recommendation**: top_k cost-table value = **100,000j**, matching lookup_top1. Rationale:
- Same scan cost (both pool-bounded)
- Heap maintenance vs single-best-tracking: marginal cost difference (small constant factor; doesn't justify pricing premium)
- Doctrine continuity: top_k generalizes lookup_top1; should price similarly to maintain D3.17 anticipated-worst-case framing

If architect wants pricing premium for K-tracking complexity, alternatives: 150,000j (50% premium) or 200,000j (2× lookup_top1). But these introduce pricing inconsistency across recognition ops. Recommend matching: 100,000j.

**Doctrine note for D3.X (Pod 3.9 sit)**: cost-table values are conventional pricing; substrate's r14 enforces budget; cost-accuracy-vs-budget separation is intentional.

---

## Q6 — Result lifetime

**Coupled with Q2 representation choice.** Stack-based (Q2 recommendation) → results are **temporary single-use**; consumed by user popping K' times. No registry pressure, no GC concerns, no lifetime management code.

If pooled (Q2 option (b)) → results are persistent registry-tracked Result[T] objects, requiring lifetime semantics + free-list machinery.

**TB recommendation: temporary single-use** (stack-based per Q2). Matches V1.0 production scenarios; simplest substrate surface.

---

## Q7 — Forge-path adaptability (implementation cost)

**Existing lookup_top1** (`boot/maid.asm:214-286`):
- Iterate 1..vm_embedding_next
- For each candidate (excluding self): MAC-verify (siphash_compute over 196 qwords) + cosine compute + score comparison
- Track single best_score (xmm6) + best_id (r12)
- Return best_id in rax (0 if pool empty / only-self / all candidates corrupt)

**For top-K, modifications**:
1. Track K best instead of 1 — need K-element data structure
2. Filter results below threshold (V1.0 single-op with threshold parameter per Q3)
3. Push K' results onto operand stack (handler-side, not helper-side)

**Internal data structure options for K-tracking**:

| Approach | Per-candidate cost | Total cost for N=2048, K=10 | Asm complexity |
|---|---|---|---|
| Heap (binary heap of size K) | O(log K) | ~6,800 ops | High (heap-up/heap-down implementations in asm) |
| Sorted array (insertion shift) | O(K) | ~20,000 ops | Low (mirrors lookup_top1 single-best-track shape) |
| Two-pass (compute all scores + partial sort) | O(N) compute + O(N log K) sort | ~65,000 ops | Medium (BSS scratch array; pseudo-quickselect) |

For K ≤ 32 and N = 2048, the sorted-array approach is the cleanest:
- Mirrors lookup_top1's single-best-track shape (just K elements instead of 1)
- O(NK) total = 65,000 ops at K=10 — well within substrate budget
- ASM implementation: ~150 lines (similar to lookup_top1's 70 lines)

**Memory placement for sorted array**:
- On call stack via push/pop: K=10 means 10 qwords id + 10 dwords score = 100 bytes. Fits.
- BSS scratch: cleaner; allocate `top_k_scratch_ids: times MAX_K dq 0` + `top_k_scratch_scores: times MAX_K dd 0` in vmdata.asm.

**TB recommendation**: BSS scratch (cleaner than call-stack push/pop dance for K-element bookkeeping). MAX_K = 256 (matches stack capacity; production scenarios typically K ≤ 32).

**New helper**: `compute_top_k_raw(rdi=query_slot_ptr, rsi=K, rdx=threshold_f32_as_i64) → rax = K' (count of results pushed)` in maid.asm. Mirrors lookup_top1 structure with K-tracking sorted-array body. Internal data: `top_k_scratch_ids` + `top_k_scratch_scores` BSS (allocated at Pod 3.9.B per D3.29 axis-2 sizing).

**Implementation cost**: low-to-modest. Existing lookup_top1's MAC-verify-each-candidate + cosine-compute pattern reuses verbatim; only the score-tracking section diverges.

**Pattern adapts cleanly**; no fully separate code path warranted.

---

## Open questions for HALT 1 architect ratification

| # | Question | TB lean |
|---|---|---|
| Q1 | Maid V1.0 framing | (a) "Maid finds many" — Pod 3.5 housekeeper extension; doctrine continuity |
| Q2 | Top-K result representation | (a) stack-based — push K' ids descending + push K' count last; simplest; no new typed primitive |
| Q3 | Threshold filter semantics | (a) single op with threshold param; threshold = -INF sentinel for unfiltered top-K; semantic continuum |
| Q4 | Opcode allocation | 0xF2 (within "embedding-tier extensions" row 0xF0-0xFE; reframe Pod 3.8's "codebook-tier" framing as broader embedding-tier-V1.0+) |
| Q5 | Cost model | 100,000j matching lookup_top1 (D3.17 anticipated-worst-case; doctrine continuity) |
| Q6 | Result lifetime | temporary single-use (coupled with Q2 stack-based) |
| Q7 | Forge-path adaptability | sorted-array K-tracking in BSS scratch; new compute_top_k_raw helper mirrors lookup_top1 shape; ~150 lines |

**Doctrine candidates for Pod 3.9 (post-ratification):**
- **D3.33** — Result-representation convention at V1.0: stack-based for ephemeral collections; pooled for persistent typed primitives. Names the choice and the rationale (premature pool-abstraction avoidance per D3.16 anticipated-empirical-pressure precedent).
- **D3.34** — 0xF0–0xFE embedding-tier extensions row (broader than Pod 3.8's "codebook-tier" framing); reframes Pod 3.8 D3.32 to absorb non-codebook embedding-tier ops.
- **D3.35** — top_k as housekeeper-tier generalization of lookup_top1; "Maid finds many" as fourth Maid V1.0 capability variant alongside finding one (lookup_top1), composing (synthesis), importing (codebook).

(Numbering deferred to architect call; D3.33+ may shift based on actual landings.)

---

## Architect-framing observations worth surfacing

**(1) Q1 framing decision is genuinely substrate-philosophical, not just naming**. The choice between "Maid finds many" (housekeeper extension) and "beyond-Maid substrate feature" affects:
- Doctrine lineage (extends D3.18 vs new doctrine family)
- Naming convention (top_k inside maid.asm vs new service name)
- Opcode-row allocation (0xF* embedding-tier vs entirely new row)
- Service-tier framing for V1.0 capability surface

The (a) recommendation preserves architectural continuity at the cost of slight Maid-tier scope creep. The (b) alternative would warrant fresh service-tier naming (Cop is deferred; another name would be needed) and significant doctrine framework rewrite.

**(2) Q2 representation is genuinely substrate-philosophical, per architect's note.** The (b) Result[T] pool option would be a substantial substrate addition (sixth typed pool + parametric types); deferring it preserves V1.0 substrate surface elegance. If production scenarios surface persistence/passing demand, the option (b) lands at Pod 3.10+ or V2 with empirical justification.

**(3) Predicted catch rate at Pod 3.9 build-time**: 1–3, given substrate-USE pod with new sorted-array internal data structure (potential off-by-one in K-tracking; potential operand-stack-protocol confusion if K' count placement drifts from convention). Most catches likely cluster at 3.9.B (new helper compute_top_k_raw) and 3.9.D (handler operand-stack protocol).

The codebook ingestion arc completed at Pod 3.8; "Maid finds many" extends Maid's recognition surface from single-best to K-best with confidence threshold, completing the substrate's recognition-axis V1.0 coverage. Substrate continues lateralizing the lexical-computation pole.

Standing by for HALT 1 architect ratification.
