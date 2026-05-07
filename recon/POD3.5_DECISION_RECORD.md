# Pod 3.5 Decision Record — Maid speaks (semantic operations: cosine + dot + L2 + lookup top-1)

**Pod:** 3.5 — first compute-tier substrate-USE pod; first FP-bearing substrate; Maid V1.0 semantic operations layer
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-06
**Entry contract:** 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3 (Pod 3 BOOTX64.EFI)
**Exit contract:** a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad
**Entry HEAD:** f3f0f06... (Pod 2.1 — Babylon is born)

> Pod 3.5's architectural surface is dense enough to surface error modes the architect couldn't have caught by reading the prompt alone; the recon-source-build-test protocol IS the verification mechanism. THREE distinct architect-error doctrine landings in a single pod: A6 (FP-precision-prediction at HALT 1), C1 (axiom-inheritance trace at HALT 2A), C2-redux (substrate-vs-cap budget conflation at HALT 2B). Three subtypes, three halt phases, one pod — project record. Plus a fourth caught at Phase 2B execution: the substrate-r14-actual-init-paths-not-traced variant of canon-doc-stale.

---

## D3.12 — FP determinism doctrine: SSE-scalar single-precision only

Pod 3.5 introduces FP compute to the substrate. boot/maid.asm is the first FP code path in the project; the substrate is FP-virgin entering this pod (R4 recon empirical confirmation). D3.12 lands as substrate-permanent canon at maximum-clarity moment with zero retrofit.

**Whitelist** (the only FP instructions allowed in substrate code):
- `movss`, `xorps` (load/store/zero)
- `mulss`, `addss`, `subss`, `divss` (arithmetic)
- `sqrtss` (square root)
- `comiss`, `ucomiss` (compare)
- `cvtsi2ss`, `cvtss2si` (int↔f32 conversion)

**Forbidden**:
- x87 instructions (`fld`, `fmul`, `faddp`, `fstp`) — non-deterministic register allocation, 80-bit intermediate precision divergence
- SIMD-vector forms (`mulps`, `addps`) — different precision-rounding semantics across CPUs at extended-precision boundaries
- FMA (`vfmadd*`) — single-rounding fused multiply-add changes bit-exact result
- AVX (`vmovaps`, `vbroadcastss`) — extended-precision intermediate rounding divergence

**Rationale**: SSE scalar single-precision operates per IEEE 754-2008 deterministically across all x86_64 hosts. Two-build determinism extends to FP results bit-exact. The substrate's reproducibility guarantee — sha256 BOOTX64.EFI identical across builds — requires that FP execution is also bit-exact across runs and hosts. The whitelist enforces this.

**B10 empirical validation**: cosine(v_e0, v_45deg) returns exactly `1060439284 = 0x3F3504F4` — bit-identical to TB's HALT 1 R10 simulation prediction. D3.12 validated empirically at first FP demo.

**Two-build determinism extension**: Pod 3.5 entry contract candidate `a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad` reproducible across builds; FP-bearing substrate inherits the substrate-wide determinism guarantee.

## D3.13 — Witness doctrine: compute-over-substrate-state bypasses bit-check

Compute operations (cosine, dot product, L2 distance, lookup_top1) are read-and-witness operations on already-validated substrate state, NOT forge operations creating new authority surface. Authority gating via `babylon_check_authority` (BIT_*_FORGE) applies to construction sites; compute ops bypass bit-check entirely.

**Doctrine**: bit-check governs forge (the substrate-state-creation moment); witness compute requires no authority bit. The substrate's authority model gates "what new state can be brought into existence under this cap?", NOT "what existing state can this cap read?"

**B20 empirical validation** (B23 compute_under_subcap demo): sub-cap A grants ONLY BIT_CAP_FORGE (no BIT_EMBEDDING_FORGE); cosine succeeds — witness doctrine in action. Compute reads existing embeddings, doesn't forge.

**Witness ≠ free**: compute ops still consume metabolic budget at substrate r14 dispatch (per-op cost), and per D3.23 they fire babylon for Outcome wrap. Witness bounds the bit-check authority gate, not the metabolic-accountant ledger.

## D3.14 — Cosine canonical Form A; bit-exact load-bearing; Form A non-guarantee extension at HALT 2B

`compute_cosine_raw` implements **Form A**: `cosine = dot(a,b) / (sqrt(norm_sq_a) * sqrt(norm_sq_b))`. Two separate sqrts compute then multiply for the divisor; alternative Form B (`cosine = dot(a,b) / sqrt(norm_sq_a * norm_sq_b)`) was considered and rejected.

**Form A chosen because**:
1. Avoids precision loss in the norm_sq_a * norm_sq_b product (which can overflow or lose mantissa bits for large vectors)
2. Mirrors the canonical embedding-similarity textbook expression
3. Bit-exactly reproducible per D3.12 whitelist

**Bit-exactness load-bearing**: the canonical evaluation order IS doctrine. The order of operations in compute_cosine_raw — accumulate norm_sq via per-element fma-like (mul + add), separate sqrt of each norm_sq, multiply for divisor, divide dot by divisor — MUST be preserved verbatim. Any reordering shifts bit patterns.

**A6 / B10 empirical anchor**: cosine(v_e0, v_45deg) bit-exact = `0x3F3504F4 = 1060439284`, NOT the algebraically-pure `0x3F3504F3 = 1/sqrt(2)`. The 1-ulp shift comes from `(1/sqrt(2))_f32 = 0x3F3504F3 = 0.70710677`; squared in f32 = 0x3EFFFFFF (rounds DOWN, not exactly 0.5); two halves sum = `0x3F7FFFFF` (NOT exactly 1.0); divisor drift propagates 1 ulp to cosine. Substrate is bit-exact deterministic; the architect's algebraic-math prior was 1 ulp off.

**HALT 2B Form A non-guarantee extension** (B7 same-vector finding):

> Form A canonical evaluation order produces bit-exact deterministic results, but doesn't guarantee algebraic perfection for symmetric inputs. cosine(v, v) where v=(1,2,3) returns `0x3F7FFFFF` (= 1.0 - 1ulp), NOT exactly `0x3F800000`, because Form A path = dot(v,v) / (sqrt(norm_sq_a) * sqrt(norm_sq_b)); norm_sq = 14 in f32 is exact, but sqrt(14)² ≠ 14 exactly. Bit-pattern depends on whether the specific norm_sq value's sqrt round-trips through f32.

**Doctrine note**: bit-exact determinism wins over algebraic perfection — D3.12's reproducibility goal is the load-bearing requirement; D3.14 Form A delivers it. **Programs needing exact 1.0 for same-input detection should compare embedding_ids before computing**, not rely on cosine returning algebraically-perfect 1.0. The bit-exact result is identical for identical inputs; that's the contract.

## D3.15 — XMM clobber convention micro-extension

boot/maid.asm helpers establish substrate's first XMM clobber documentation:
- `compute_cosine_raw` clobbers `xmm0-xmm5` (working set: dot accumulator, norm_a accumulator, norm_b accumulator, sqrt scratch, divisor)
- `compute_dot_product` clobbers `xmm0-xmm2` (accumulator + 2 scratches)
- `compute_l2_distance` clobbers `xmm0-xmm3` (accumulator + diff scratch + sqrt scratch)
- `lookup_top1` clobbers `xmm0-xmm6` (cosine internal + best_score in xmm6)

**Convention**: helper headers document XMM clobber range explicitly. xmm6+ are caller-saved per Win64 (which doesn't apply to substrate — we're not calling external code), but the substrate convention treats xmm0-xmm15 as fully clobberable across helpers; documented explicitly in each helper's header.

**Substrate-wide rule** (forward-anchor for future FP code): every helper that uses XMM registers documents its XMM clobber range in its header. Mirrors the GPR clobber documentation convention established at Pod 1.10.2a (cap.asm helpers). The discipline scales naturally to FP.

## D3.16 — Anticipated-empirical-pressure pool expansion 64→256

`EMBEDDING_POOL_SLOTS` raised from 64 to 256 at Pod 3.5. DEFERRED #83 (forward-logged Pod 3) PARTIALLY RESOLVED.

**Rationale**: Pod 3.5's lookup_top1 demonstrates real codebook-search workloads. 64 slots was conservative for substrate-prep; 256 supports modest codebook ingestion experiments. Pod 3.6+ may want larger (1000+ for production codebooks); 256 is the empirically-right scale for compute-tier introduction.

**Side-effect**: the reverse side-table BSS sizing (`vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0`) inherits the 256-slot dimension; 256 × 8 = 2048 bytes BSS for reverse linkage.

**Memory footprint shift**: 256 × 1576 = 403,456 bytes (~400KB pool); ~4× the Pod 3 size. Sub-second BSS init; no boot-time impact.

## D3.17 — Static worst-case costing for compute composites

`OP_EMBEDDING_LOOKUP_TOP1` (0xC9) cost = 100,000j — static worst-case for full 256-candidate scan, each requiring MAC verify (~10j) + cosine compute (~390j Form A) ≈ 100,000j composite. The cost reflects machine work for the worst case; programs pay full price even if scan terminates early via short-circuit.

**Doctrine alignment**: D3.10 substrate-bookkeeping doctrine — every primitive operation carries its full metabolic weight as static cost. Compute composites follow the same convention; per-candidate dynamic costing was rejected as adding dispatch-loop complexity for marginal accuracy benefit.

**Empirical validation B18**: lookup_top1 dispatched at 100,000j against 1M substrate budget; r14 -= 100,000 succeeds; 256-candidate scan completes; ROOT.used += floor(100000/2) = 50,000j (D3.10 + D3.23 babylon ripple).

## D3.18 — lookup_top1 MAC-verify-each-candidate + self-exclusion

`lookup_top1(query_slot_ptr) → best_match_embedding_id (or 0)`:
1. Query slot already MAC-verified by handler before lookup_top1 invocation
2. Loop candidate i in 1..vm_embedding_next:
   - Skip self (candidate == query)
   - Resolve via registry_lookup_embedding (skip on miss)
   - **MAC-verify each candidate inline** (skip on mismatch — substrate refuses to compute over corrupt slots)
   - Compute cosine_raw(query, candidate); update best_score / best_id if higher

**MAC-verify-each-candidate** (not just at handler dispatch): substrate guarantees that every cosine input is structurally valid AT THE TIME OF COMPUTE. Slot corruption between handler dispatch and individual compute would silently corrupt results otherwise; the per-candidate verify closes the gap.

**Self-exclusion**: if the query embedding is in the pool, it's skipped from candidate scan (a query is not its own match). Self-exclusion convention reflects "find me something LIKE my query, not my query itself."

**Empty-pool error path**: if scan finds no candidates (only query in pool, or all candidates fail MAC verify), returns 0 → handler routes to ERR_INVALID_EMBEDDING_ARG.

**B19 empirical validation**: pool with single embedding (the query itself) → lookup returns 0 → handler emits Err(InvalidEmbeddingArg, source_op=201, err_code=9). ✓

## D3.19 — D3.9 single-fire greenfield axiom propagates to compute ops

Pod 3 D3.9 established: greenfield typed primitive constructors inherit single-fire spatial-merge by construction (the .construct_ok_outcome internal babylon is the sole fire site). Pod 3.5 compute ops are greenfield Outcome producers; they inherit the same axiom.

**Inheritance trace**: cosine handler success path → `mov rdi, rax / mov r8, TYPE_CODE_EMBEDDING / call .construct_ok_outcome` → helper internal: outcome slot stamp + babylon_charge_lineage(current_dispatch_cost) → spatial-merge ripple. ONE fire per cosine; same shape as Sign/Energy/Outcome/Cap/Embedding constructors.

**Empirical validation B23**: cosine under sub-cap A; A.used=0 (originating); ROOT.used=200 (floor(400/2)); single-fire confirmed. (Architect's prior at HALT 2A B21 expected "spatial-merge silent" — this didn't survive D3.9 axiom inheritance trace; see D3.23.)

## D3.20 — Reverse side-table (D3.4 forward direction inverted)

D3.4 (Pod 3) established forward Sign→Embedding linkage via `vm_sign_embedding_handle[sign_id-1]`. D3.20 establishes the reverse Embedding→Sign linkage via `vm_embedding_sign_handle[embedding_id-1]`.

**Implementation**:
- BSS: `vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0` (sized to D3.16's 256-slot pool)
- OP_SIGN_NEW retrofit: when `embedding_handle != 0` AND validation passes, write reverse entry: `vm_embedding_sign_handle[(embedding_handle - 1) * 8] = sign_id` AFTER registry_register_sign and BEFORE .construct_ok_outcome (siphash inside .construct_ok_outcome would clobber r9; reverse-write must precede)
- OP_EMBEDDING_SIGN_HANDLE = 0xC5 accessor: pop embedding_id; validate via registry_lookup_embedding (no MAC verify needed — reverse table is non-MAC parallel structure); read `vm_embedding_sign_handle[embedding_id-1]`; wrap in Outcome::Ok

**Integrity model**: matches D3.4's parallel-structure-tracking convention (non-MAC; consistent with Sign's Pod-1.7-archaeology asymmetry). Both forward AND reverse linkages live in non-MAC parallel BSS; substrate trusts its own write paths.

**B21/B22 empirical validation**:
- Linked: Sign forged with embedding_handle=1 → reverse table at index 0 = 1 → OP_EMBEDDING_SIGN_HANDLE returns sign_id=1 ✓
- Unlinked: orphan embedding (no Sign references it) → reverse table at index 0 = 0 (BSS-zero default) → returns 0 (no Sign linked) ✓

**Maid composition pattern (B24)**: end-to-end "lookup-by-meaning → recover Sign" demonstrates D3.13 witness compute + D3.20 reverse side-table working in concert. best_embedding_id from lookup_top1 → OP_EMBEDDING_SIGN_HANDLE recovers the linked sign_id in one accessor call. The Maid speaks.

## D3.21 — Five new opcodes 0xC5-0xC9 allocation

| Opcode | Name | Cost | Description |
|--------|------|------|-------------|
| 0xC5 | OP_EMBEDDING_SIGN_HANDLE | 1j | Reverse side-table read (D3.20) |
| 0xC6 | OP_EMBEDDING_COSINE | 400j | Form A cosine (D3.14) |
| 0xC7 | OP_EMBEDDING_DOT_PRODUCT | 200j | 384-element accumulation |
| 0xC8 | OP_EMBEDDING_L2_DISTANCE | 280j | sqrt(sum((a-b)²)) |
| 0xC9 | OP_EMBEDDING_LOOKUP_TOP1 | 100,000j | D3.18 worst-case composite |

Allocation contiguous at 0xC5-0xC9 within the 0xC0-0xCF Embedding row reserved at Pod 3. 0xCA-0xCF reserved for Pod 3.5+ extensions (vector arithmetic, codebook ingestion per DEFERRED #80 partial resolution).

## D3.22 — boot/maid.asm new file (mirror of babylon.asm pattern)

New substrate file `boot/maid.asm` houses the four FP compute helpers. File-creation convention mirrors Pod 2.1's `boot/babylon.asm`: a substrate primitive's compute helpers live in their own file, included from boot/boot.asm.

**File header documents D3.12/D3.13/D3.14/D3.15 doctrines + XMM clobber convention micro-extension**, making it the canonical entry point for understanding Pod 3.5's FP compute. Future readers learn the doctrines from the file that implements them.

**Helpers** (all callable; raw-pointer ABI per Pre-A13):
- `compute_cosine_raw(slot_a_ptr, slot_b_ptr) → rax = f32-as-i64; CF=1 on zero-norm`
- `compute_dot_product(slot_a_ptr, slot_b_ptr) → rax = f32-as-i64`
- `compute_l2_distance(slot_a_ptr, slot_b_ptr) → rax = f32-as-i64`
- `lookup_top1(query_slot_ptr) → rax = best_match_embedding_id (0 if none)`

Raw-pointer ABI eliminates redundant query re-resolution (caller resolves+verifies once; passes pointer in).

## D3.23 — Compute ops fire babylon via Outcome wrap (D3.9 axiom inheritance trace; eleventh empirical landing of architect-error doctrine)

**The architectural moment**. Babylon doesn't just track substrate-state-creation; it tracks **Outcome production**, which is the universal "completed substrate event" abstraction. Every operation that produces an Outcome wraps via `.construct_ok_outcome`, which fires `babylon_charge_lineage` by construction. Compute ops, accessor success paths, primitive constructors — all fire babylon by virtue of the Outcome wrap.

**Substrate-architectural unification**: federation accounting tracks the universal substrate event (Outcome production), not narrow per-event-type categorization.

**D3.10 (substrate-bookkeeping) and D3.23 together form a clean substrate-accounting framework**:
- Cost-table accounting at dispatch: per-op operand-stack cost reflects machine work (substrate r14 drain)
- Babylon ripple at Outcome production: federation lineage accumulates floor-divided geometric decay
- Both fire by construction at every Outcome-producing handler; uniform behavior across all paths

**Architect-error doctrine eleventh empirical landing** (subtype: "axiom-inheritance trace failure"): The architect's HALT 2A B21 framing assumed compute ops would be "spatial-merge silent" — a reasonable intuition that compute is "read-only" and shouldn't trigger metabolic accounting. But D3.9 axiom inheritance traces the actual implementation path: cosine wraps its f32 result in Outcome via .construct_ok_outcome, which fires babylon_charge_lineage unconditionally. The architect designed the doctrine correctly at AUTHORIZED-1 ("greenfield typed primitives inherit single-fire by construction") but failed to trace the same axiom through compute ops introduced in the same pod.

**Distinct from prior subtypes** (count drift, mechanical completeness, side-effect cross-reference, canon-doc-stale, FP-precision-prediction). The architect failed not by checking the wrong canonical surface, but by failing to extend established doctrine to new code paths where it propagates by construction.

**Reframed B21**: was "spatial-merge silent canary"; is now "compute-op single-fire canary" (B23). Empirical: ROOT.used = 200 = floor(400/2) under sub-cap.

## D3.24 — Substrate metabolic ceiling scales with op tier introduction (twelfth + thirteenth empirical landings of architect-error doctrine)

**Substrate r14 raised from 100,000j to 1,000,000j** to accommodate Pod 3.5's compute tier.

**Doctrine framing**: Pod 0-3 substrate ops were ≤100j tier; default 100,000j was sufficient. Pod 3.5 introduces 100-400j compute tier (cosine/dot/l2) + 100,000j composite tier (lookup_top1). Default scales 10× to 1,000,000j. Future tier introductions may motivate further raises with explicit doctrine framing. The substrate's metabolic ceiling **grows to accommodate the work it must metabolically host**.

**10× scaling rationale**:
- Comfortably accommodates lookup_top1 (100,000j) + cap forge (≤500j) + cap enter (50j) + multiple embedding_news (100j × N) + accessor reads + HALT
- Supports ~10 lookups in a single program — sufficient for Pod 3.5 demos and modest Pod 3.6+ extensions
- Preserves "ceiling means something" framing — programs CAN still hit the boundary at non-trivial work levels
- Clean scaling factor for op tier introduction; future tier raises would be similarly proportioned events

**Architect-error doctrine twelfth empirical landing** (subtype: "substrate-vs-cap budget model conflation"): The architect's AUTHORIZED-2A C2 ratification asserted "lookup demos forge sub-caps with sufficient budget; substrate stays unchanged; B5/B6 regression preserved." Empirically, this didn't work because substrate r14 (global VM dispatch ceiling) and cap.energy_budget (per-cap quota tracked via babylon spatial-merge) are orthogonal authority mechanisms. Sub-cap entry doesn't reset r14. The architect treated them as equivalent budget surfaces; they aren't.

**Architect-error doctrine thirteenth empirical landing** (subtype: "canon-doc-stale: substrate-r14-actual-init-paths-not-traced"): Discovered at Phase 2B execution. The architect's AUTHORIZED-2B directive specified "vmdata.asm energy_budget default 100,000j → 1,000,000j" — but the `vmdata.asm:energy_budget` data variable is read by ONLY ONE site (cbs_vm.asm:634 OP_CAP_BUDGET accessor). The actual VM r14 dispatch budget is initialized by hardcoded `mov r14d, 100000` at 7 sites in `bastian.asm` and `morla.asm`. The data variable looks like the source of truth (semantic naming) but is unused for r14 init. TB updated all 7 hardcoded sites in addition to the data variable to make the substrate raise effective.

**Pod 3.5 architect-error catches** (project record — three subtypes in one pod, plus the Phase-2B-execution variant):
1. **A6 / HALT 1** (FP-precision-prediction-vs-bit-exact-f32-result; tenth landing)
2. **C1 / HALT 2A** (axiom-inheritance trace failure; eleventh landing)
3. **C2-redux / HALT 2B** (substrate-vs-cap budget model conflation; twelfth landing)
4. **r14-init-paths / Phase 2B execution** (canon-doc-stale variant; thirteenth landing)

The recon-source-build-test protocol catches errors at every halt phase. Different phases catch different error classes. The discipline performs.

**B5/B6 regression handling**:
- Bytecode byte-identicality: B5/B6 still PASS (compilation produces identical bytecode regardless of substrate budget)
- Screendump byte-identicality: NEW BASELINE — Pod 3.5 reference PNGs replace Pod 3 reference; future regression compares against Pod 3.5 baseline
- Frame as "execution-trace semantic preservation across substrate scaling event" — matches Pod 3's "Path A retrofit" flexibility precedent

The HALT screen's "remaining: Xj" line differs by exactly the budget delta (e.g., 99,826j → 999,826j for the Sign canary). Doctrine-aligned shift.

---

## Empirical observations summary (Phase 2B canary results)

All 17 Pod 3.5 canaries PASS at substrate r14 = 1M:

| Test | Doctrine | Expected | Observed |
|------|----------|----------|----------|
| B4 boot liveness | Boot E3 self-test 8th run | clean boot | PASS |
| B7 cosine_same_vector | D3.14 Form A non-guarantee | 0x3F7FFFFF (1.0 - 1ulp) | 1065353215 ✓ |
| B8 cosine_orthogonal | D3.14 | 0x00000000 (0.0) | 0 ✓ |
| B9 cosine_antipodal | D3.14 | 0xBF800000 (-1.0) | 3212836864 ✓ |
| B10 cosine_45_degree | D3.14 / A6 ratification | 0x3F3504F4 | 1060439284 ✓ |
| B11 cosine_zero_vector | D3.14 zero-norm rejection | Err(9, src=198) | ✓ |
| B12 cosine_invalid_id | D3.13 / handler err path | Err(1, src=198) | ✓ |
| B13 dot_product_simple | D3.21 | 0x42000000 (32.0) | 1107296256 ✓ |
| B14 dot_product_invalid_id | handler err path | Err(1, src=199) | ✓ |
| B15 l2_distance_same | D3.14 | 0.0 | 0 ✓ |
| B16 l2_distance_simple | D3.14 | 0x40A00000 (5.0) | 1084227584 ✓ |
| B17 l2_distance_invalid_id | handler err path | Err(1, src=200) | ✓ |
| B18 lookup_top1_basic | D3.18 / D3.10 / D3.24 | best_id=2, A.used=0, **ROOT.used=50000** | ✓ **first 5-digit babylon ripple** |
| B19 lookup_top1_empty | D3.18 / handler err | Err(9, src=201) | ✓ |
| B20 lookup_top1_invalid_query | handler err path | Err(1, src=201) | ✓ |
| B21 embedding_sign_handle linked | D3.20 reverse | sign_id=1 | ✓ |
| B22 embedding_sign_handle unlinked | D3.20 BSS-default | 0 | ✓ |
| B23 compute_under_subcap | C1/D3.23 single-fire compute | A.used=0, **ROOT.used=200** | ✓ |
| B24 maid_composition | D3.13 + D3.20 end-to-end | best=1, sign_id=1 | ✓ **the Maid speaks** |

**Architectural moments**:
- **B10**: D3.12 SSE-scalar bit-exact determinism doctrine first empirical validation. cosine_45_degree returns architect-ratified `0x3F3504F4` exactly.
- **B18**: First 5-digit babylon ripple in the project. ROOT.used += 50000 from a single lookup_top1 demonstrates that the metabolic accountant scales empirically to compute-tier ops. D3.10 substrate-bookkeeping doctrine eighth empirical landing in compute-tier form.
- **B23**: D3.9/D3.23 axiom inheritance empirically anchored. Compute ops fire babylon via Outcome wrap; ROOT.used = 200 confirms.
- **B24**: End-to-end Maid speaks. Lookup-by-meaning + Sign recovery in two opcodes. The substrate's compute primitive lands.

**Two-build determinism**: entry contract candidate `a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad` reproducible across builds. FP-bearing substrate inherits the substrate-wide determinism guarantee.
