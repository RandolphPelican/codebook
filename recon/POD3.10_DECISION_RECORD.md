# Pod 3.10 Decision Record — Maid orthogonalizes (project + reject)

**Pod:** 3.10 — fourth forge-tier substrate-USE pod; Maid V1.0 finder-of-many surface gains its geometric-decomposition pair; vector-arithmetic synthesis tier completes its V1.0 surface.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-10
**Entry HEAD:** 989c8fc452395e73ae773769c979054f772992a6 (Pod 3.9 SEAL — Maid finds many)
**Entry contract:** a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99 (canonical Pod 3.9 BOOTX64.EFI; bug-fixed substrate post-D3.37)
**Exit contract:** b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981

> Pod 3.10 lands the Maid's geometric-decomposition pair — `OP_EMBEDDING_PROJECT` (0xF3) and `OP_EMBEDDING_REJECT` (0xF4) — completing the synthesis tier's vector-arithmetic surface. project(A, B) returns A's component along B's direction; reject(A, B) returns A's component orthogonal to B; together they decompose any nonzero A relative to B. Four new doctrine entries land: D3.38 (project-reject duality as orthogonalization primitive pair), D3.39 (internally-derived-scalar discipline; synthesis tuple `scalar=0` for ops with no user scalar), D3.40 (hybrid IEEE-degeneracy convention extension; substrate exact-zero rejection + IEEE finite-math; spans cosine/normalize/project/reject uniformly), D3.41 (raw-emitter literal-id discipline; forge-order comment-tagging at call sites). Build-time catches: 0. Substrate catches: 0. Architect-framing-corrections: 1 (cost-magnitude at 3.10.A Q6). The Maid orthogonalizes.

---

## D3.38 — Project-Reject duality as orthogonalization primitive pair

**Geometric decomposition primitive.** Project and reject together complete the substrate's vector-arithmetic surface for V1.0:

| Op | Math | Returns |
|---|---|---|
| `project(A, B)` | `(A·B / B·B) * B` | A's component along B's direction (the "parallel" part) |
| `reject(A, B)` | `A - project(A, B)` | A's component orthogonal to B (the "perpendicular" part) |
| Identity | `A = project(A, B) + reject(A, B)` | full decomposition (mathematical; f32 has compound rounding) |

**Why both as native primitives** (Q1 ratification): neither can be derived from the other without forging an intermediate full-vector embedding (project's scaled-B intermediate, then reject's subtraction). Native pair:
- Single forge per call (one MAC, one synthesis tuple, one babylon ripple) per D3.23
- Bit-exact predictability via R10 sim — substrate-controlled f32 evaluation order frozen in canon per D3.28
- Coherent cost-table entries (one row per op; 1500j parity per Q6)
- Zero intermediate-pool pressure (vs derived-via-composition burning 3-4 transient embedding/outcome pool slots per call)

**Doctrinal continuity**: extends D3.25 (Pod 3.6 synthesis tier — add/sub/scale/normalize/lerp); D3.38 is the natural completion of vector-arithmetic synthesis.

**Maid V1.0 surface (post-Pod-3.10)**:

| Pod | Surface | Capabilities |
|---|---|---|
| 3.5 | Housekeeper | cosine + dot + L2 + lookup_top1 + sign_handle |
| 3.6 | Composer | add + subtract + scale + normalize + lerp + synthesis_handle |
| 3.8 | Importer | boot_ingest_codebook + imported_handle |
| 3.9 | Finder-of-many | lookup_top_k |
| **3.10** | **Orthogonalizer** | **project + reject** |

**Synthesis tier scope at V1.0**: vector arithmetic (add/sub/scale/normalize/lerp from Pod 3.6) **+ geometric decomposition (project/reject from Pod 3.10)** = complete synthesis-tier surface for V1.0. Future axes (aggregation, cross-result analogy, multi-codebook) remain open for Pod 3.11+ / V2.

**The architectural arc**: Pod 3.5 lookup_top1 is single-best recognition; Pod 3.9 lookup_top_k extends to K-best recognition; Pod 3.10 project/reject provides the **decomposition primitive** that future analogical-reasoning operations would consume. The substrate now has the building blocks for Gram-Schmidt-style orthogonalization, modular semantic decomposition, and subspace projection — all expressible in user code via the project/reject primitive pair.

## D3.39 — Internally-derived-scalar discipline

**The rule.** When a synthesis op computes a scalar internally (rather than receiving one from operand stack), the synthesis tuple's `scalar` field stores `0` — matching the ADD/SUBTRACT binary-op convention from Pod 3.6. The substrate's `scalar` field convention is preserved as **"the user-input scalar"**, not "any scalar value present in the computation."

**Per-op scalar field semantics (Pod 3.6 + Pod 3.10 union)**:

| Op | Scalar field stores | Why |
|---|---|---|
| ADD | `0` | No scalar input |
| SUBTRACT | `0` | No scalar input |
| SCALE | user-supplied f32-as-i64 | The multiplier |
| NORMALIZE | `0` | No scalar input (norm is internally derived) |
| LERP | user-supplied `t` (f32-as-i64) | The interpolation parameter |
| **PROJECT** | **`0`** | **Ratio is internally derived** |
| **REJECT** | **`0`** | **Ratio is internally derived** |

**Forensic recovery argument**: storing the computed ratio in the tuple would enable byte-exact recovery of project's intermediate value, but the user can recompute ratio = `dot(A, B) / dot(B, B)` from sources trivially (one extra op). Doctrine integrity wins over forensic convenience; D3.27 invariant **"synthesis tuple captures user-visible inputs, not internal intermediates"** is preserved.

**Surface symmetry**: project/reject's user surface is (lhs, rhs) → result; identical to add/subtract. Synthesis tuple shape symmetry follows (op, source_a, source_b, scalar=0). User-visible API simplicity preserved across the synthesis tier.

**Future-pod composability**: when later ops introduce both user-supplied AND internally-derived scalars (hypothetical scenario), the discipline provides clear precedent — the user-supplied stays in the scalar field; the internally-derived stays helper-internal. No new architecture needed if/when that case arrives.

## D3.40 — Hybrid IEEE-degeneracy convention extension

**Substrate exact-zero rejection + IEEE finite-math.** When an f32 operation faces division-by-zero or sqrt-of-negative degeneracy, the substrate convention is:

1. **Exact-zero magnitude check**: if the divisor's bit pattern is exactly `0x00000000` (or `0x80000000`), return `CF=1` from the helper (zero-norm rejection sentinel). Handler converts to `Err(InvalidEmbeddingArg)`.
2. **IEEE 754 finite-math otherwise**: small-but-nonzero magnitudes propagate through standard IEEE rounding; substrate does NOT introduce an arbitrary epsilon threshold for "tiny" values.

**The convention now spans uniformly across the f32 surface**:

| Op | Pod | Degeneracy check | Path on degenerate |
|---|---|---|---|
| `compute_cosine_raw` | 3.5 | `bits(norm_a_sq) == 0 OR bits(norm_b_sq) == 0` | CF=1 → handler Err |
| `compute_normalize_raw` | 3.6 | `bits(norm_sq) == 0` | CF=1 → handler Err |
| `compute_project_raw` | 3.10 | `bits(dot_BB) == 0` | CF=1 → handler Err |
| `compute_reject_raw` | 3.10 | `bits(dot_BB) == 0` | CF=1 → handler Err |

**Why hybrid (vs strict-substrate-side-check)**: an "always-substrate-validates" approach would require an arbitrary epsilon decision for "tiny norm" — substrate-policy cost with no obvious right value. The hybrid approach **only handles the empirically-distinct case** (exact zero) and lets IEEE 754's continuity handle small-but-nonzero values. Substrate doctrine prefers IEEE 754 semantics unless exact degeneracy is empirically observable as a failure mode.

**Empirical validation across Pod 3.10**:
- B50.id3 `project(A, zero) → CF=1 → source_op=243, err_code=9` ✓
- B51.id3 `reject(A, zero) → CF=1 → source_op=244, err_code=9` ✓

The `source_op` discriminator (243 vs 244) confirms the err path dispatches uniformly across both ops with op-specific provenance.

**D3.40 supersedes D3.14's narrower zero-norm framing**: D3.14 named the cosine/normalize zero-norm rejection convention; D3.40 names it as the substrate's general degeneracy-handling discipline. D3.14 substrate-canon stays operational (cosine/normalize behavior unchanged); D3.40 is the doctrinal generalization.

## D3.41 — Raw-emitter literal-id discipline

**The rule.** When an atreyu emitter takes literal `id_a`/`id_b` integers (the `_raw` variant convention from Pod 3.6, mirroring `embedding_add_raw` / `embedding_subtract_raw`), the user-surface canary code MUST document the forge-order at the call site as a comment, ensuring forensic recoverability of which substrate-id each literal references.

**Empirical exposure (Pod 3.10.E B50/B51 first-draft)**:

The B50 canary's `id3` test forged `a3` and `z3` then called `embedding_project_raw(id_a=5, id_b=6)` — but the actual forge order at that point produced `a3=id=6` and `z3=id=7`. Hardcoded literals 5/6 referenced previously-forged embeddings (`p2` at id=5; `a3` at id=6), causing the test to call `project(p2, a3)` instead of intended `project(a3, z3)`. Result diverged from prediction; debug surface (UNWRAP_ERR-on-Ok diagnostic) caught it; fix was simple (correct hardcoded literals to id_a=6, id_b=7).

**Forward discipline (`_raw` emitter caller convention)**:
```python
# Forge order so far: a1=1, p1=2, z2=3, b2=4, p2=5; next forges: a3=6, z3=7
{'type':'let','name':'a3','value':{'type':'embedding_new','vector':v_one}},
{'type':'let','name':'z3','value':{'type':'embedding_new'}},
{'type':'let','name':'o3','value':{'type':'embedding_project_raw','id_a':6,'id_b':7}},
```

Comment immediately preceding the `_raw` call documents:
- All previously-forged embeddings + their assigned ids
- The next embedding(s) to be forged + their predicted ids
- The literal `id_a`/`id_b` values used in the `_raw` call

**Why not refactor the emitter**: changing `_raw` to accept variable expressions would require adding a new AST node type (`embedding_project_raw_var`) or extending the existing emitter to handle both literal and variable forms. Either approach diverges from the existing Pod 3.6 `embedding_add_raw` / `embedding_subtract_raw` pattern for marginal benefit — comment discipline at the call site is sufficient.

**Doctrine generalization**: any current or future `_raw` emitter taking literal ids inherits this comment-discipline convention. Surface canary code emerges more legible (the forge-order trace makes the test's intent visible) and forensic recoverability is preserved without architectural complexity.

---

## Q-rating ratifications (Pod 3.10.A pre-flight + audit)

| # | Question | Ratified |
|---|---|---|
| **Q1** | Native primitive ops vs derived-via-composition — native chosen for Pod 3.6 doctrine continuity, single-fire forge alignment, bit-exact R10 predictability, intermediate-pool-pressure avoidance | ✓ ratified per D3.38 |
| **Q2** | Synthesis tuple shape extension — `scalar=0` for both PROJECT and REJECT (Layout-2 inheritance preserved; matches ADD/SUBTRACT precedent) | ✓ ratified per D3.39 |
| **Q3** | Numerical stability — hybrid (exact-zero substrate rejection per D3.14 cosine/normalize precedent; IEEE 754 propagation for finite math; no arbitrary epsilon) | ✓ ratified per D3.40 |
| **Sub-Q3** | (b) strict-substrate-side-check distinguished from (c) hybrid; strict would require arbitrary epsilon threshold; hybrid inherits IEEE continuity at small-but-nonzero values | ✓ hybrid chosen |
| **Q4** | Opcode allocation — 0xF3 PROJECT / 0xF4 REJECT within D3.34 embedding-tier-extensions row | ✓ ratified |
| **Q5** | SYNTHESIS_OP_* codes — 0x06 PROJECT / 0x07 REJECT (sequential continuation of Pod 3.6 0x01-0x05) | ✓ ratified |
| **Q6** | Cost model — parity 1500j both (round-number aesthetic; reject's marginal +384 subss doesn't justify pricing-decision overhead) | ✓ ratified |
| **Sub-Q6** | Architect's "10,000j range or higher" framing corrected — actual existing synthesis row is 500-800j; 1500j places project/reject above synthesis tier (compound geometric op tier) but below 100,000j recognition tier | ✓ framing-correction acknowledged |
| **Q7** | Forge-path adaptability — clean adaptation (helper-pair convention extends naturally; ~460 lines NASM total; single-pass reject; binary-op-with-internally-derived-scalar doesn't diverge from D3.27) | ✓ ratified |

---

## 3.10.A–3.10.F chunk audit

| Chunk | Identity | Contract | Catches |
|---|---|---|---|
| 3.10.A | Pre-flight + Q1-Q7 sit (no code) | n/a (Pod 3.9 base a6fa3deb) | 0 |
| 3.10.B | compute_project_raw + compute_reject_raw helpers | `21e1a0db2eedc5d81ca6415452b11e0e8486aabc28fc117b7cefc8b1f0823ed6` | 0 (helpers dead code; 33/33 prior-pod regression PASS at new contract) |
| 3.10.C | Cost-table annotation pass (0xF3=1500j / 0xF4=1500j) | `025aa758b78c9895f0806589c90d06b371eec755b93bf9dfb606028e5e843e8f` | 0 (cost values for unreachable opcodes are dead binary data; same pattern as Pod 3.9.C) |
| 3.10.D | Handlers + atreyu emitters + dispatch entries | `b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981` | 0 (36/36 prior-pod regression byte-exact at new contract; project/reject unreachable from any prior canary) |
| 3.10.E | R10 sim + B50/B51 canaries (canonical preserved) | `b6097e60…` (canonical preserved; canaries don't modify substrate) | 0 substrate; **forge-id mismatch caught at canary debug** (D3.41 surfaced); B50/B51 PASS post-fix; **drift panel byte-exact (0xB4000000 anchor)** |
| 3.10.F | SEAL — decision record + commit + push | `b6097e60…` (canonical preserved through SEAL) | — |
| **SEAL** | canonical contract | `b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981` | — |

**Build-time catches: 0**. **Substrate-catches: 0**. **Architect-framing-corrections: 1** (Q6 cost-magnitude at 3.10.A — architect's "10,000j range or higher" → actual existing synthesis row 500-800j; 1500j placed above synthesis tier but below recognition tier per TB framing recommendation).

The forge-id mismatch caught at 3.10.E B50/B51 canary debug is **canary-tier discipline** (D3.41), not substrate-catch — bytecode emitter literal-id convention surfaced as documented forward discipline rather than substrate-behavioral defect. Pattern differs from Pod 3.9's substrate-catch (D3.37 NASM addressing); Pod 3.10 substrate stayed clean across all five chunks.

---

## B50/B51 PASS narrative + drift panel byte-exact (3.10.E)

**B50 PROJECT canary** — five test cases, all PASS:
- B50.id1 `project(A, A) = A` byte-exact (ratio = 0x3F800000 = 1.0; `mulss(1.0, x) = x` per B30 transferred)
- B50.id2 `project(zero, B) = zero` byte-exact (ratio = 0/dot_BB = 0; `mulss(0, x) = 0`)
- B50.id3 `project(A, zero) → Err(InvalidEmbeddingArg, src=243, err=9)` per D3.40 (CF=1 → handler emits Err; zero-norm path canonical)
- B50.c1 `project((1,1,0..), (1,0,0..)) = (1,0,0..)` (result == B byte-exact)
- B50.c2 `project((3,4,0..), (1,0,0..)) = (3,0,0..)` (ratio = 3.0)

**B51 REJECT canary** — five test cases + three drift panels, all PASS:
- B51.id1 `reject(A, A) = +0 vector` byte-exact (ratio = 1.0; `subss(x, mulss(1.0, x)) = subss(x, x) = +0` via B28 endpoint property)
- B51.id2 `reject(zero, B) = zero` byte-exact
- B51.id3 `reject(A, zero) → Err(InvalidEmbeddingArg, src=244, err=9)` per D3.40
- B51.c1 `reject((1,1), (1,0)) = (0,1,0..)` byte-exact
- B51.c2 `reject((3,4), (1,0)) = (0,4,0..)` byte-exact

**Drift panel — D3.28 self-verifying canon for Pod 3.10**:
- B51.drift1 `dot(reject((1,1), (1,0)), (1,0)) = 0` byte-exact (trivial case; reject's nonzero dim is orthogonal to B)
- **B51.drift2 `dot(reject((1,1), (3,4)), (3,4)) = 0xB4000000` byte-exact** ← compound-rounding drift; mathematical 0; substrate matches R10 prediction
- B51.drift3 `dot(reject((1,2,3), (1,1,1)), (1,1,1)) = 0` byte-exact (ratio = 2.0 byte-exact; clean cancellation)

The **drift2 anchor `0xB4000000`** is Pod 3.10's instance of D3.28 self-verifying canon — substrate's mathematical-identity-vs-f32-bit-exactness gap is **predictable and named** rather than implicit-and-suspicious. Same family as:
- Pod 3.5 cosine_same_vector (`0x3F7FFFFF = 1.0-1ulp`; sqrt(14)² ≠ 14 in f32)
- Pod 3.6 normalize v_uniform (25-ulp drift accumulator)
- Pod 3.10 reject orthogonality (compound mulss + subss + dot accumulator drift)

D3.28 self-verifying canon now spans **recognition (cosine; Pod 3.5)**, **synthesis (normalize; Pod 3.6)**, and **compound geometric (reject; Pod 3.10)** — the discipline is uniform across the f32 substrate surface.

---

## Doctrinal-merger architectural moment (Pod 3.10)

**Project/reject = combinatorial union of two existing handler shapes.**

| Source pattern | Pod | Contribution to project/reject |
|---|---|---|
| `compute_add_raw` / `compute_subtract_raw` (binary-input, source_a/source_b synthesis tuple) | 3.6 | Stack discipline (push id_a, push id_b → resolve+verify → push slot_a, push slot_b → pop slot_b/slot_a pre-compute); 4 cleanup labels (pool_full_drop4, pool_full_drop2, invalid_drop2, insufficient_authority_drop2) |
| `compute_normalize_raw` / `compute_cosine_raw` (zero-norm CF=1 sentinel) | 3.5/3.6 | Zero-norm rejection path; CF=1 helper return; 5th cleanup label (zero_norm_drop2) returning Err(InvalidEmbeddingArg) |

**Result: first handlers in the codebase to combine both patterns.** The cleanup-label set is the **union** of both source patterns — 5 labels total instead of 4. This is the architectural moment of Pod 3.10: existing handler-shape primitives compose to handle a new operation class (binary-input + zero-norm-degenerate) without inventing new patterns.

**Forward composability**: future synthesis ops with the same shape (binary-input, internally-derived-scalar, possibly-degenerate input) inherit the merger as canon — handler skeleton, stack discipline, and cleanup labels all reusable.

---

## DEFERRED state (Pod 3.10 close)

| # | Description | Status |
|---|---|---|
| #80, #83, #89, #90 | RESOLVED at prior pods | unchanged |
| #82 | Sign.provenance_handle activation candidate | unchanged |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.10 adds 1 (`pod310_r10_sim.py`) — no new runner script (B50/B51 use existing pod35_canary_test.sh harness per architect direction) |
| #85 | RECONSTITUTION.md ongoing canon refresh | unchanged |
| #91 | Codebook-symmetry: runtime `OP_EMBEDDING_IMPORT` (0xF0) handler activation | continues; 0xF row capacity remaining at 0xF5-0xFE (10 slots) |
| #92 | Stream-stability: aggregation / cross-result analogical operations | continues; **stronger candidate after Pod 3.10**: project/reject provide the decomposition primitive that aggregation ops (centroid, mean, variance) would consume; if surfaced, would justify Result[T] sixth-pool addition per D3.33 |
| #93 | Diagnostic-probe-scaffolding policy | continues from Pod 3.9 (3.10 didn't surface new diagnostic-probe scaffolding; B50/B51 are canon canaries, not probe scaffolding); architect call still pending on retain-vs-retire convention |

**No new deferrals at Pod 3.10.** Existing deferrals updated with Pod 3.10 context where relevant (#92 stronger candidate post-decomposition-primitive landing).

---

## Substrate state at SEAL

**Five typed pools** (Sign / Energy / Outcome / Cap / Embedding) — unchanged.

**Three non-MAC parallel side-tables** for Embedding linkage — unchanged (sign_handle / synthesis / imported).

**OP_EMBEDDING_ row 0xF0–0xFE allocation** (per D3.34 reframed embedding-tier extensions):
- 0xF0 OP_EMBEDDING_IMPORT — constant reserved (Pod 3.8); handler deferred (#91)
- 0xF1 OP_EMBEDDING_IMPORTED_HANDLE — witness accessor live (Pod 3.8)
- 0xF2 OP_EMBEDDING_LOOKUP_TOP_K — housekeeper-tier; live (Pod 3.9)
- **0xF3 OP_EMBEDDING_PROJECT — composer-tier (geometric synthesis); live (Pod 3.10)**
- **0xF4 OP_EMBEDDING_REJECT — composer-tier (geometric synthesis); live (Pod 3.10)**
- 0xF5–0xFE — reserved for embedding-tier extensions (10 slots remaining)

**SYNTHESIS_OP_* allocation**:
- 0x00 NONE / 0x01 ADD / 0x02 SUBTRACT / 0x03 SCALE / 0x04 NORMALIZE / 0x05 LERP (Pod 3.6)
- **0x06 PROJECT / 0x07 REJECT (Pod 3.10)**
- 0x08–0xFF reserved for future synthesis-op extensions

**Maid V1.0 surface (recognition + composition + import + decomposition)** complete on the recognition+arithmetic axes:
- Recognition: cosine + dot + L2 + lookup_top1 + lookup_top_k (single-best; K-best with threshold)
- Synthesis arithmetic: add + subtract + scale + normalize + lerp
- **Synthesis geometric: project + reject (NEW Pod 3.10)**
- Import + provenance: boot_ingest_codebook + imported_handle + synthesis_handle

**D3.40 hybrid IEEE-degeneracy convention** newly canonical: cosine / normalize / project / reject all reject exact-zero divisors via CF=1 sentinel + handler Err(InvalidEmbeddingArg) per D3.40; finite-IEEE math for nonzero degenerate magnitudes (no arbitrary epsilon).

**D3.41 raw-emitter literal-id discipline** canonical from Pod 3.10: surface canary code documents forge-order at `_raw` call sites for forensic recoverability.

**Two-build determinism** preserved at canonical Pod 3.10 SEAL contract `b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981` — re-confirmed at SEAL.

---

## Headline moments

**Substrate-philosophical**: D3.38 names project-reject duality as the geometric-decomposition primitive pair; substrate's vector-arithmetic synthesis tier reaches V1.0 completeness. D3.39 codifies internally-derived-scalar discipline; D3.27 synthesis tuple invariant preserved.

**Doctrinal generalization**: D3.40 widens D3.14's cosine/normalize zero-norm framing to the substrate's general degeneracy-handling discipline (exact-zero rejection + IEEE finite-math); spans 4 ops uniformly.

**Empirical first**: Pod 3.10's D3.28 drift-canon instance — `dot(reject((1,1), (3,4)), (3,4)) = 0xB4000000` byte-exact — extends self-verifying-canon lineage from Pod 3.5 cosine and Pod 3.6 normalize to compound geometric ops.

**Architectural moment**: project/reject are the first handlers to combine binary-input shape (add/sub/scale) AND zero-norm-rejection shape (cosine/normalize) — 5-cleanup-label union pattern; future ops with similar profile inherit as canon.

**Catch profile**: 0 substrate-catches across 5 chunks; recon-prediction validated (TB at 3.10.A predicted "0–2 catches at helper precision or synthesis tuple write"; actual = 0 substrate, 1 canary-tier discipline catch surfaced as D3.41). Pattern shift from Pod 3.9 (substrate-catch at NASM addressing) to Pod 3.10 (zero substrate, doctrinal documentation refinement) — substrate-USE pods inheriting established patterns cluster catches at canary-surface convention rather than substrate-behavioral surface.

**Architect-framing-correction**: 1 (Q6 cost-magnitude at 3.10.A — "10,000j range or higher" → actual existing synthesis row 500-800j; 1500j placed in compound-geometric tier between synthesis and recognition).

---

## V1.0 progress checkpoint

**Pod 3.10 = 4 of 6 V1.0 pods sealed.** Pods 3.11 / 3.12 remain.

The Maid recognizes; the Maid composes; the Maid imports; the Maid finds many; **the Maid orthogonalizes**. The substrate's lexical-computation pole reaches operational completeness on the **recognition axis (Pod 3.5 + 3.9)** and the **synthesis axis (Pod 3.6 + 3.10)** at V1.0 — five Maid V1.0 capability variants live, vector arithmetic + geometric decomposition complete.

What remains for V1.0 is broader architectural surface — Pod 3.11 (working title: "maintain") and Pod 3.12 (V1.0 SEAL). Exact framing for Pod 3.11 deferred to its architectural sit. Candidate axes:
- Aggregation (centroid / mean / variance over result-sets) — would justify Result[T] sixth-pool per D3.33 + #92 stream-stability
- Multi-codebook ingestion (would activate #91 codebook-symmetry; runtime OP_EMBEDDING_IMPORT handler)
- Substrate-maintenance ops (garbage collection, defragmentation, slot reuse) — speculative
- Cross-result analogical operations (analogy-based reasoning over recognition results)

Pod 3.10 closes the synthesis tier's V1.0 surface; whatever lands at Pod 3.11/3.12 builds on the now-complete Maid foundation.
