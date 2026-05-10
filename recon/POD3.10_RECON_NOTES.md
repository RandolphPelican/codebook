# Pod 3.10 Recon Notes — "Maid orthogonalizes" (project + reject) sit prep

**Status:** Informal recon notes for HALT 1 architect ratification. NOT a formalized recon report. Seven findings + recommendations surfaced for sit-time call before any code lands.

**Entry HEAD:** 989c8fc452395e73ae773769c979054f772992a6 (Pod 3.9 SEAL — Maid finds many)
**Entry contract:** a6fa3debb834b1a71216b16ee2358e6c8fd7b9d005947883b0bcc061fbe2da99 (canonical Pod 3.9 BOOTX64.EFI)
**Three-oracle:** ✓ HEAD = origin/main = ls-remote at 989c8fc
**Identifier audit:** PROJECT / REJECT / ORTHOGON / 0xF3 / 0xF4 — zero canonical matches in tree (placeholder `dq 1` reservations at 0xF3/0xF4 in `boot/energy_costs.asm:178`; comment-only "REJECTION" in zero-norm code paths; no semantic collision with the new Pod 3.10 surface)
**Build chain:** unchanged (NASM 2.16.01 / mtools 4.0.43 / QEMU 8.2.2 in WSL)

---

## Q1 — Project + reject as primitive ops vs derived

**Math:**
- `project(A, B) = (A·B / B·B) * B` — vector A's component in B's direction
- `reject(A, B) = A - project(A, B)` — vector A's component orthogonal to B

**Two paths:**

### (a) Native primitive ops (compute_project_raw + compute_reject_raw)
- Two new helpers; two new handlers; two new opcodes; two synthesis_op codes (6, 7)
- Single forge per call (one MAC, one synthesis tuple, one babylon ripple)
- Bit-exact predictability via R10 sim (D3.28 self-verifying canon precedent)
- Coherent cost-table entries (one row per op)
- One canary surface per op

### (b) Derived via existing dot + scale + sub composition
- User program writes: `dot(A,B) → s1; dot(B,B) → s2; div s1/s2 → ratio; scale(B, ratio) → proj; sub(A, proj) → rej`
- Substrate complexity: zero new code
- Multiple forges per logical op (~3-4 intermediate Outcomes + embeddings + MACs + babylon ripples per project; same for reject)
- Cost accumulates through compound charges (~500j × 3 = 1500j+ for project's compute steps PLUS forge/MAC/lineage overhead per intermediate)
- Bit-exact reproducibility relies on user composition order (substrate can't enforce; if user composes Form B vs Form A, drift)

**Tradeoff audit:**

| Concern | (a) Native | (b) Derived |
|---|---|---|
| Substrate code | +2 helpers, +2 handlers | 0 |
| Per-call forges | 1 | 3-4 |
| Per-call cost | 1500j-2000j single charge | 1500j+ compound (multiple babylon ripples) |
| Bit-exact predictability | substrate-enforced (Form A canon) | user-composition-order-dependent |
| Synthesis tuple recovery | one tuple captures (op=PROJECT, A, B) | multiple tuples scatter the lineage |
| Canary surface | one per op (clean R10 verification) | ad-hoc compositions; harder to anchor empirically |
| Intermediate Outcome pool pressure | none | per-step Outcome forge consumes pool slots |
| Analogical-reasoning use case ergonomics | one `project(A, B)` call | 5-call composition the user rebuilds each time |

**TB recommendation: (a) native primitive ops.** Rationale:

- **Substrate-doctrine continuity**: Pod 3.6 chose the same path for `add/sub/scale/normalize/lerp` over user-composed-via-pop/push variants. The project/reject decision mirrors that ratification; **"Maid composes" precedent applies**.
- **Forge-path single-fire alignment**: D3.23 substrate-bookkeeping doctrine (single babylon fire per Outcome production) interacts cleanly with native ops (one fire per project) but creates 3-4× ripple amplification under derived composition (each intermediate forge fires babylon).
- **Bit-exact substrate promise**: D3.28 self-verifying canon depends on substrate-controlled f32 evaluation order. Native helpers freeze the order in canon; derived path cannot.
- **Intermediate-pool pressure**: each derived-path call burns 3-4 embedding pool slots + 3-4 outcome pool slots for transients the user doesn't need. At pool capacities (2048 / 4096), heavy use of derived-path project/reject would exhaust pools quickly. Native ops produce one persistent result + one persistent Outcome.
- **Analogical-reasoning ergonomics**: project/reject are core operations for vector-arithmetic reasoning (Gram-Schmidt; modular semantic decomposition; subspace projections). User code reading `embedding_project(A, B)` is dramatically more legible than the 5-step composition.

The substrate complexity cost (~2 helpers, ~150-200 lines NASM) is the same magnitude as Pod 3.6's synthesis ops landing — empirically tractable, doctrine-consistent.

---

## Q2 — Synthesis tuple shape extension

**The question:** D3.27 synthesis tuple is `(op, source_a, source_b, scalar)` × 32 bytes per slot. Project/reject are binary ops without user-supplied scalar. Where does project's internally-computed `(A·B / B·B)` ratio belong?

**Three options:**

### (a) Store computed ratio in the scalar field
- **Pros**: Forensic recoverability (verify project was bit-exact); single architectural-record per op
- **Cons**: Semantic asymmetry with existing tuple (scalar is meant for *user-input* scalars: SCALE's multiplier, LERP's t); breaks invariant that tuple captures "user-visible inputs"
- **Drift risk**: ratio is f32; scalar field is u64 (32 zero bits + 32 ratio bits) or full u64 (?); non-trivial to bit-exact serialize

### (b) Store 0 in the scalar field (sentinel "no scalar input")
- **Pros**: Layout-2 inheritance preserved; matches ADD/SUBTRACT convention (which also have no user scalar; scalar=0 by current canon); semantic-asymmetry-free
- **Cons**: Loss of forensic recoverability of internal ratio (user must recompute from sources to verify)
- **Loss is acceptable**: synthesis tuple captures *what produced this embedding*, not *what intermediate values were observed*; ratio can be recomputed from (A, B) trivially

### (c) Extend tuple to 5 fields (op, source_a, source_b, user_scalar, derived_scalar)
- **Pros**: Future-proof for hypothetical ops with both user + derived scalars
- **Cons**: D3.27 tuple-shape break; 32-byte slot overflow (becomes 40 bytes); side-table BSS expands ~25%; cascade through D3.29 axis-2 mechanical sizing; substrate-architectural disruption for one V1.0 use case

**TB recommendation: (b) scalar = 0 for both PROJECT and REJECT.**

Rationale:
- **Layout-2 inheritance preserved**: D3.27 32-byte synthesis tuple shape stays canon; no BSS expansion; D3.29 axis-2 mechanical-sizing cascade unaffected
- **Existing canon already has the precedent**: ADD (op=1) writes scalar=0; SUBTRACT (op=2) writes scalar=0 — they're binary ops with no user scalar, identical to project/reject's shape
- **Forensic recovery is decoupled**: user verifies project's correctness by recomputing `dot(A,B)/dot(B,B) * B` via Form A bit-exact sim; ratio recovery doesn't need on-substrate persistence
- **D3.27 invariant intact**: synthesis tuple captures *what user-visible inputs produced this embedding*; internally-computed intermediate values stay implementation detail

If forensic ratio-storage becomes empirically demanded later (Pod 3.11+ debug surfaces? V2 audit-trail features?), option (a) or (c) can land at that pod with concrete consumer use case driving it. Pod 3.10 ships the conservative shape.

---

## Q3 — Numerical stability handling

**The risk:** `dot(B, B) = ||B||²` can be:
- Exactly zero (B is the zero vector) → division by zero → NaN propagation
- Tiny but nonzero (denormalized B) → ratio could overflow → +Inf
- Normal magnitude → math is fine

**Three options:**

### (a) IEEE 754 standard propagation (no substrate-side check)
- Behavior: zero-vector B → NaN result; tiny B → potentially Inf result; user gets the IEEE result and decides
- **Pros**: No substrate code; user is responsible
- **Cons**: NaN result is byte-exact-different from a "real" zero; user has no way to distinguish; downstream ops on NaN-vector propagate further; **breaks substrate's "always observable Outcome" doctrine** (NaN-on-stack with success Outcome is a contradiction)

### (b) Substrate-side check on B·B == 0 (return Err on zero magnitude)
- Behavior: exact-zero B detected → CF=1 from helper → handler returns `Err(InvalidEmbeddingArg)`; tiny-but-nonzero B → IEEE 754 propagates (math proceeds)
- **Pros**: Matches existing substrate doctrine — `compute_cosine_raw` (D3.14) and `compute_normalize_raw` (D3.14 Form A) already use this CF=1 sentinel pattern for zero-norm rejection; user gets an Outcome variant (Ok(embedding) on success; Err on zero-divisor)
- **Cons**: None substantively — extends existing canon

### (c) Hybrid: Err on exact zero; IEEE for small-but-nonzero
- Behavior: same as (b) — "exact zero rejection" is the contract; finite-IEEE-propagation handles the rest
- **Pros**: Same as (b)
- **Cons**: This IS option (b); the "hybrid" framing distinguishes it from a pure-IEEE-everywhere option

**Note**: (b) and (c) are the same option. The architect's framing distinguishes "substrate check covers all degenerate cases" (b — strict) vs "substrate check covers exact-zero only; tiny IEEE'd through" (c — hybrid). The strict variant would require a non-trivial epsilon decision (what's "tiny enough"?); the hybrid inherits IEEE 754's continuity at small-but-nonzero values without an arbitrary substrate threshold.

**TB recommendation: (c) hybrid — exact-zero substrate rejection + IEEE 754 propagation for the rest.**

Rationale:
- **Existing canon precedent**: `compute_cosine_raw` rejects `bits(norm_a_sq) == 0 OR bits(norm_b_sq) == 0` exactly — not "tiny norm." Same pattern for `compute_normalize_raw`. Project/reject inherit the convention rather than diverging.
- **Avoids epsilon-policy decision**: any "small-but-nonzero" threshold introduces a substrate-arbitrary cutoff — no obvious right value; substrate-doctrine prefers IEEE 754 continuity unless exact degeneracy.
- **Composable substrate behavior**: a user composing project ↔ normalize ↔ cosine sees consistent zero-rejection semantics across all three; the substrate's degenerate-case discipline is uniform.
- **Outcome surface clean**: Err(InvalidEmbeddingArg) on exact-zero B; Ok(new embedding_id) on success; user gets standard dispatch. No "success-with-NaN" pathological state.

**Error code**: reuse `ERR_INVALID_EMBEDDING_ARG=9` (existing; matches normalize's zero-norm rejection). Avoids new error code allocation; semantic intent matches.

---

## Q4 — Opcode allocation

**Available row 0xF0–0xFE** (per D3.34 embedding-tier extensions reframe):
- 0xF0 IMPORT (handler deferred per #91)
- 0xF1 IMPORTED_HANDLE (Pod 3.8)
- 0xF2 LOOKUP_TOP_K (Pod 3.9)
- **0xF3–0xFE** — reserved for embedding-tier extensions

**TB recommendation: 0xF3 OP_EMBEDDING_PROJECT, 0xF4 OP_EMBEDDING_REJECT.** Sequential allocation within the embedding-tier-extensions row per D3.34. No row-collision; no service-tier mismatch.

Post-Pod-3.10 row utilization:

| Slot | Pod | Op | Tier |
|---|---|---|---|
| 0xF0 | 3.8 | IMPORT | codebook (handler deferred) |
| 0xF1 | 3.8 | IMPORTED_HANDLE | codebook witness |
| 0xF2 | 3.9 | LOOKUP_TOP_K | housekeeper (recognition) |
| 0xF3 | 3.10 | **PROJECT** | **composer (geometric synthesis)** |
| 0xF4 | 3.10 | **REJECT** | **composer (geometric synthesis)** |
| 0xF5–0xFE | reserved | future | embedding-tier (10 slots remaining) |

Doctrine continuity: D3.34 embedding-tier-extensions row absorbs the new ops without service-tier-naming friction.

---

## Q5 — SYNTHESIS_OP_* code allocation

**Existing (Pod 3.6)**:
- `SYNTHESIS_OP_NONE     = 0x00` (BSS-zero default; non-synthesized embeddings)
- `SYNTHESIS_OP_ADD      = 0x01`
- `SYNTHESIS_OP_SUBTRACT = 0x02`
- `SYNTHESIS_OP_SCALE    = 0x03`
- `SYNTHESIS_OP_NORMALIZE= 0x04`
- `SYNTHESIS_OP_LERP     = 0x05`

**Proposed (Pod 3.10)**:
- `SYNTHESIS_OP_PROJECT  = 0x06`
- `SYNTHESIS_OP_REJECT   = 0x07`

**TB confirmation: sequential 0x06 / 0x07.** No collision; D3.27 synthesis-tuple `op` field (1 byte; full 0x00-0xFF range available) accommodates trivially. Forward room for further synthesis ops at 0x08+ if Pod 3.11+ adds geometric or aggregation ops.

---

## Q6 — Cost model

**Computational shape (per-op machine work)**:

| Op | Steps | Approx ops |
|---|---|---|
| ADD (0xCA) | 384 addss + forge | ~768 ops |
| SUBTRACT (0xCB) | 384 subss + forge | ~768 ops |
| SCALE (0xCC) | 384 mulss + forge | ~768 ops (one mulss per dim) |
| NORMALIZE (0xCD) | 384 mulss (norm_sq) + 384 addss + sqrt + 384 divss + forge | ~1536 ops |
| LERP (0xCE) | 768 mulss ((1-t)·A + t·B) + 384 addss + forge | ~1536 ops |
| **PROJECT (0xF3)** | **384 mulss + 384 addss (dot AB) + 384 mulss + 384 addss (dot BB) + divss (ratio) + 384 mulss (scale B) + forge** | **~2300 ops** |
| **REJECT (0xF4)** | **PROJECT steps + 384 subss (A - proj)** | **~2700 ops** |

**Existing cost-table values (Pod 3.6 SEAL-calibrated; B25-B34 empirical anchors)**:
- 0xCA ADD: 500j (~503j empirical)
- 0xCB SUBTRACT: 500j (~503j)
- 0xCC SCALE: 500j (~489j)
- 0xCD NORMALIZE: 700j (~699j)
- 0xCE LERP: 800j (~804j)

**Pricing rationale (D3.17 anticipated-worst-case framing; round numbers per substrate-aesthetic doctrine)**:

For PROJECT at ~2300 ops: scaling LERP's 800j (~1536 ops) proportionally → 800 × (2300/1536) ≈ 1200j. Round to 1500j for substrate-aesthetic round-number doctrine + slight forge-overhead premium for compound geometric op.

For REJECT at ~2700 ops: scaling proportionally → ~1400j. Round to 1500j for parity with project, OR 2000j for explicit "reject = project + sub" pricing.

**Two pricing options:**

| | (i) Parity pricing | (ii) Compound pricing |
|---|---|---|
| PROJECT | 1500j | 1500j |
| REJECT | 1500j | 2000j |
| Rationale | Reject's extra subss cost is marginal; round-pricing simplicity | Reject pays for the additional pass; doctrine-faithful to ops-counted shape |

**TB recommendation: (i) parity pricing — both 1500j.**

Rationale:
- **Round-number aesthetic + minimal pricing decisions**: substrate has 5 synthesis ops at 500/500/500/700/800j (small-step round-number ladder). Adding 1500j parity ops continues the ladder cleanly.
- **Reject's marginal extra work (384 subss = ~25% premium over project)**: doesn't justify a full doctrine bookkeeping decision; ~125j premium would be cosmetic
- **Composability ergonomics**: user composing project ↔ reject sees uniform pricing; predictable budget arithmetic
- **D3.17 anticipated-worst-case stance**: cost values are doctrine, not measured-machine-work; substrate's r14 enforces budget, not cost-accuracy

If architect prefers compound pricing per "machine work counted" doctrine, (ii) 1500j project / 2000j reject is the alternative. Both are doctrinally defensible; (i) is the simpler default.

**Note on architect's "10,000j range" framing**: the existing synthesis cost row is 500-800j (substantially below 10,000j). The architect's prior reference may have been a rough estimate; actual existing range is in the hundreds-of-joules. PROJECT/REJECT at ~1500j fit cleanly above the existing synthesis ops, below the `lookup_top1`/`lookup_top_k` 100,000j recognition tier.

---

## Q7 — Forge-path adaptability

**Existing synthesis-tuple-write pattern (Pod 3.6 ADD/SUBTRACT/SCALE shape, per D3.27)**:
1. Handler resolves `source_a` + `source_b` slots via `registry_lookup_embedding`
2. Handler MAC-verifies both source slots
3. Handler allocates new embedding slot via `registry_register_embedding` → `dest_slot_ptr`
4. Handler calls `compute_<op>_raw(rdi=source_a_slot, rsi=source_b_slot, rdx=dest_slot)` — helper writes vector
5. Handler stamps id_self, computes new MAC over dest, writes synthesis tuple `(op, source_a, source_b, scalar=0)` at `dest_id-1` index
6. Handler wraps `dest_id` as `Outcome::Ok` on operand stack

**For PROJECT, the same shape adapts directly**:
- `compute_project_raw(rdi=A_slot, rsi=B_slot, rdx=dest_slot)` — helper:
  1. Compute `dot(A, B)` accumulating in xmm — 384 iterations
  2. Compute `dot(B, B)` accumulating in xmm — 384 iterations
  3. Zero-norm check: if `bits(dot_BB) == 0` return CF=1 (matches normalize/cosine pattern per D3.14)
  4. Compute `ratio = dot_AB / dot_BB` via divss
  5. Scale-and-write loop: for each dim i, `dest[i] = ratio * B[i]` via mulss + movss store — 384 iterations
- Helper internal-derived-scalar (the ratio) doesn't propagate to handler — fully internal to compute_project_raw
- Handler treats project as binary op (no scalar parameter at handler level; same as ADD/SUBTRACT)
- Synthesis tuple write: `(op=SYNTHESIS_OP_PROJECT=6, source_a=A_id, source_b=B_id, scalar=0)` per Q2 recommendation

**For REJECT, similar but final loop differs**:
- `compute_reject_raw(rdi=A_slot, rsi=B_slot, rdx=dest_slot)`:
  1. Same dot(A,B) + dot(B,B) + zero-check + ratio
  2. Final loop: for each dim i, `dest[i] = A[i] - (ratio * B[i])` — 384 mulss + 384 subss
- OR (cleaner factoring): `compute_reject_raw` calls `compute_project_raw` then subtracts in-place via `compute_subtract_raw`
- Tradeoff: separate-helper composition is clean code-wise but creates two slot-writes (dest written by project, then overwritten by subtract). Single-pass implementation is one slot-write but ~50 more lines NASM.

**TB recommendation for reject internal shape: single-pass implementation.** Rationale:
- Slot-write overhead is real (1536 bytes); two slot-writes vs one is 1.5× memory traffic
- compute_reject_raw fits ~120-150 lines; same magnitude as compute_normalize_raw (~80 lines) or compute_lerp_raw (~100 lines)
- Single-pass keeps cost-table value clean (one composition; no intermediate forge)

**Pattern adaptation summary**:
- Helper-pair convention (compute_project_raw + compute_reject_raw as substrate-internal; handlers as dispatch surface) holds per D3.27 / D3.28
- Synthesis tuple write at handler level (existing shape; just add the two new op codes 6, 7)
- Zero-norm rejection per D3.14 (CF=1 sentinel; handler converts to Err Outcome)
- Estimated implementation: ~150 lines compute_project_raw + ~150 lines compute_reject_raw + ~80 lines handler op_embedding_project + ~80 lines handler op_embedding_reject = **~460 lines NASM**, similar magnitude to Pod 3.6's synthesis ops landing (~600 lines for 5 ops + tuple infrastructure).

**Pattern adapts cleanly**; no fully separate code path warranted. Helper-pair convention extends naturally; binary-op-with-internally-derived-scalar shape doesn't diverge from D3.27.

---

## Open questions for HALT 1 architect ratification

| # | Question | TB lean |
|---|---|---|
| Q1 | Primitive vs derived | (a) native primitive ops — substrate-doctrine continuity from Pod 3.6; single-fire forge alignment; bit-exact predictability; intermediate-pool-pressure avoidance |
| Q2 | Synthesis tuple shape extension | (b) scalar=0 for both — Layout-2 inheritance preserved; matches ADD/SUBTRACT precedent; ratio recovery via user recomputation if needed |
| Q3 | Numerical stability | (c) hybrid — exact-zero rejection (CF=1; matches D3.14 cosine/normalize precedent) + IEEE 754 propagation for finite math; no arbitrary epsilon threshold |
| Q4 | Opcode allocation | 0xF3 PROJECT, 0xF4 REJECT — sequential within D3.34 embedding-tier-extensions row |
| Q5 | SYNTHESIS_OP_* codes | 0x06 PROJECT, 0x07 REJECT — sequential continuation of Pod 3.6 0x01-0x05 |
| Q6 | Cost model | (i) parity pricing — both 1500j (round-number aesthetic; reject's marginal extra work doesn't justify pricing decision overhead) |
| Q7 | Forge-path adaptability | clean adaptation — helper-pair convention extends naturally; ~460 lines NASM total; single-pass reject implementation; binary-op-with-internally-derived-scalar shape doesn't diverge from D3.27 |

**Doctrine candidates for Pod 3.10 (post-ratification):**

- **D3.38** — Project-Reject duality as orthogonalization primitive pair; named geometric decomposition (project = parallel component; reject = perpendicular component); together complete vector-arithmetic synthesis tier
- **D3.39** — Internally-derived-scalar discipline: when a synthesis op computes a scalar internally (project's ratio) rather than receiving one from operand stack, the synthesis tuple's `scalar` field stores 0 (matches ADD/SUBTRACT binary-op convention); ratio recoverability stays user-side (recompute from sources)
- **D3.40** — Hybrid IEEE-degeneracy convention extension: substrate rejects exact-zero magnitude (CF=1 helper sentinel) and propagates IEEE 754 finite-math otherwise; the convention now spans cosine (D3.14), normalize (D3.14), project, reject — substrate's degenerate-case discipline is uniform across the f32 surface

(Numbering deferred to architect call; D3.38+ may shift based on actual landings.)

---

## Architect-framing observations worth surfacing

**(1) Q1 framing decision is genuinely substrate-philosophical.** Native primitive vs derived-via-composition affects substrate complexity, forge accounting, intermediate-pool pressure, and the clean-API-vs-build-from-parts ergonomic axis. Pod 3.6 ratified native-primitive for add/sub/scale/normalize/lerp; Pod 3.10 inherits the same call. Doctrine continuity holds.

**(2) Q3 hybrid framing distinguishes (b) "all degenerate cases" from (c) "exact-zero only".** The architect's three-option presentation may have intended (b) as strict-substrate-side-check (covering tiny-norm) and (c) as hybrid (covering exact-zero only). The strict variant requires an arbitrary epsilon decision; the hybrid inherits IEEE 754 continuity at small-but-nonzero. Recommend (c) hybrid; if architect prefers strict-substrate-side-check, the additional epsilon-policy decision becomes a sit-time call.

**(3) Q6 cost-magnitude correction**: architect's "10,000j range or higher" framing may have been a rough estimate. Actual existing synthesis ops are 500-800j range. Project/reject at ~1500j fit the synthesis-tier cost ladder cleanly, well below the 100,000j recognition-tier (lookup_top1/lookup_top_k). The cost-table value range across Pod 3.10 should stay coherent with Pod 3.6 synthesis-op pricing.

**(4) Predicted catch rate at Pod 3.10 build-time**: 0–2, given substrate-USE pod with an established helper-pattern (Pod 3.6 ADD/SUBTRACT/SCALE precedent) extending to two new compute helpers. Most likely catches cluster at:
- Helper-implementation precision (bit-exact division ordering for project's ratio computation; possible Form A vs Form B choice for reject's combined-pass vs separate-pass) — empirical anchor via R10 sim per Pod 3.6 / 3.9 precedent
- Synthesis-tuple write at scalar=0 vs computed-ratio (Q2 ratification dependency)
- Possible re-emergence of NASM-RIP-relative-indexed-BSS pattern if compute_project_raw uses scratch arrays — D3.37 discipline must apply

**(5) D3.37 substrate discipline applies.** Pod 3.10 helpers must use `lea reg_base, [rel sym]; [reg_base + idx*scale]` for any indexed BSS access. Pod 3.9 SEAL re-verified zero remaining `[rel sym + reg*scale]` patterns. Pod 3.10 helpers stay disciplined.

**(6) Existing helper interfaces preserved as-is**. compute_dot_product_raw exists from Pod 3.5 — could be REUSED for project/reject's two dot accumulations, OR inlined for cleanliness. Tradeoff: reuse reduces code duplication (~50 lines saved) but ties project/reject's bit-exact behavior to compute_dot_product_raw's specific evaluation order (which IS Form A canon already, so no semantic risk). Recommend inline implementation for Pod 3.10 helpers — keeps each helper self-contained per existing add/sub/scale shape; D3.28 self-verifying canon covers each helper independently.

The "Maid composes" tier extends with "Maid orthogonalizes" at Pod 3.10 — vector-arithmetic synthesis tier completes its geometric-operation set. Substrate's lexical-computation pole gains the orthogonal-decomposition primitive necessary for analogical reasoning, Gram-Schmidt-style operations, and modular semantic decomposition.

Standing by for HALT 1 architect ratification.
