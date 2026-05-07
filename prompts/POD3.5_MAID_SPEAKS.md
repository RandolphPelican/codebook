# Pod 3.5 — Maid speaks (semantic operations: cosine + dot + L2 + lookup top-1)

**Entry HEAD:** 86fb0572aab42a261fd50f1c8aaf0efb76425f4a (Pod 3 seal — Maid is born)

**Entry binary contract:** 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3

**Pod scope:** First substrate-USE pod. Ship V1.0 Maid semantic operations: cosine similarity (primary), dot product, L2 distance, lookup-top-1, plus reverse side-table for embedding→sign mapping with OP_EMBEDDING_SIGN_HANDLE accessor. Expand Embedding pool from 64 to 256 slots (anticipated empirical pressure for Maid V1.0 demo scope; #83 cashes; precedent does NOT generalize). New `boot/maid.asm` houses Maid helper functions (compute_cosine, compute_dot_product, compute_l2_distance, lookup_top1) mirroring `boot/babylon.asm` pattern. FP determinism doctrine entered (D3.12): scalar SSE single-precision only across substrate. Witness doctrine generalizes to compute (D3.13): read-and-compute over substrate state bypasses bit-check.

**Pacing inflection:** Pod 3.5 is the second meaningful inflection in the project arc (Pod 3 was the first — substrate-EVOLUTION → substrate-PREP). Pod 3.5 is substrate-PREP → substrate-USE proper. Substrate computes over its own content for the first time. Heavier recon than Pod 3 due to FP-determinism enumeration, numerical-stability test-vector specification, and broader test surface area.

**Architect implementation notes (HALT 1 ratified at green-light):**
1. **xmm clobber convention** — boot/maid.asm helper docstrings document xmm0-xmm5 clobbers explicitly (substrate's existing convention silent on xmm; this is a doctrine micro-extension landing cleanly at S3).
2. **TYPE_CODE_EMBEDDING wraps derived FP results** — Pod 3 OP_EMBEDDING_GET_DIM convention preserved (B8 empirical: dim[100]=1120403456 returned with TYPE_CODE_EMBEDDING). Cosine/dot/L2 follow same. TYPE_CODE_F32 deferred to Pod 3.6+ if semantic friction surfaces.
3. **compute_cosine factoring at HALT 2A** — Pre-A13 raw-slot-pointer signature holds; layered implementation: public `compute_cosine_by_id(rdi=id_a, rsi=id_b)` does resolve+verify + delegates to private `compute_cosine_raw(rdi=ptr_a, rsi=ptr_b)`; lookup_top1 calls raw form inside its loop after per-candidate resolve+verify. Both API surfaces, single FP-math implementation, no redundant query re-resolution. TB picks at HALT 2A.

---

## Pre-A architect priors

**Pre-A1 — Five new opcodes.** OP_EMBEDDING_SIGN_HANDLE (reverse side-table accessor) + OP_EMBEDDING_COSINE + OP_EMBEDDING_DOT_PRODUCT + OP_EMBEDDING_L2_DISTANCE + OP_EMBEDDING_LOOKUP_TOP1.

**Pre-A2 — Opcode allocations:**
```
OP_EMBEDDING_SIGN_HANDLE  = 0xC5   ; reverse side-table accessor (sign_id from embedding_id)
OP_EMBEDDING_COSINE       = 0xC6   ; pop two embedding_ids, push Outcome<f32-as-i64>
OP_EMBEDDING_DOT_PRODUCT  = 0xC7   ; pop two embedding_ids, push Outcome<f32-as-i64>
OP_EMBEDDING_L2_DISTANCE  = 0xC8   ; pop two embedding_ids, push Outcome<f32-as-i64>
OP_EMBEDDING_LOOKUP_TOP1  = 0xC9   ; pop query embedding_id, push Outcome<best_match_embedding_id>
; 0xCA-0xCF reserved for Pod 3.6+ semantic ops (top-k, ranked lists, indexed lookup, lookup-by-Sign fused if friction)
```

**Pre-A3 — Pool capacity expansion.** EMBEDDING_POOL_SLOTS changes from 64 to 256. Memory footprint: 256 × 1576 = 403,456 bytes (~400KB) in BSS. Expansion is anticipated-empirical-pressure justification per #83 cash + D3.16 doctrine note: precedent does NOT generalize. Future pool expansions still require empirical or similarly-justified pressure. Sign pool stays at 64 slots (no change).

**Pre-A4 — Reverse side-table.** New BSS allocation:
```asm
vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0   ; 256 × 8 = 2048 bytes
```
Indexed by `(embedding_id - 1)`. Written at `OP_SIGN_NEW` after `registry_register_sign` returns sign_id, **only when** embedding_handle != 0; substrate writes `vm_embedding_sign_handle[embedding_handle - 1] = sign_id`. Read via OP_EMBEDDING_SIGN_HANDLE accessor. Returns 0 if no Sign linked (default BSS-zero state).

**Pre-A5 — FP determinism doctrine (D3.12).** Substrate FP arithmetic uses SSE scalar single-precision instructions only:
- **Allowed:** movss, mulss, addss, subss, divss, sqrtss, comiss, ucomiss, xorps (sign manipulation), cvtsi2ss, cvtss2si
- **Forbidden:** x87 (fld/fmul/faddp/fstp), SIMD-vectorized (mulps/addps), FMA (vfmadd*), AVX, runtime-rounding-mode-dependent ops
- Bit-exact reproducibility across builds is **non-negotiable**; two-build determinism doctrine extends to FP results
- TB enumerates planned FP instruction usage in `boot/maid.asm` at HALT 1 R-call; HALT 2A verifies zero leak

**Pre-A6 — Cosine canonical evaluation order (D3.14).** Form A — separate sqrts. Document in `boot/maid.asm` comment block:
```
1. dot       = sum_i a[i] * b[i]                        (384 mulss + 383 addss)
2. norm_a_sq = sum_i a[i] * a[i]                        (384 mulss + 383 addss)
3. norm_b_sq = sum_i b[i] * b[i]                        (384 mulss + 383 addss)
4. if norm_a_sq == 0.0f OR norm_b_sq == 0.0f → ERR_INVALID_EMBEDDING_ARG
5. norm_a    = sqrtss(norm_a_sq)
6. norm_b    = sqrtss(norm_b_sq)
7. denom     = norm_a * norm_b                          (mulss)
8. cosine    = dot / denom                              (divss)
9. return cosine (32-bit zero-extended to i64 in rax)
```
Total FP ops per cosine: ~1152 mulss + ~1149 addss + 2 sqrtss + 1 mulss + 1 divss + 2 ucomiss = ~2305 FP ops. Form A's two-sqrt cost vs Form B's one-sqrt is ~30j marginal; stability advantage worth it for substrate-permanent reproducibility.

**Pre-A7 — Zero-norm rejection.** Strict zero check: if `norm_a_sq` OR `norm_b_sq` literally equals 0.0f (bit pattern 0x00000000 — comparison via `xorps` against zero-loaded register or `ucomiss` against memory zero), cosine routes to `.embedding_cosine_zero_norm` failure path with `ERR_INVALID_EMBEDDING_ARG`. Near-zero but non-zero norms produce well-defined cosine results (which programs handle).

**Pre-A8 — L2 distance canonical form.**
```
1. diff_sq   = sum_i (a[i] - b[i])^2     (384 subss + 384 mulss + 383 addss)
2. l2        = sqrtss(diff_sq)
3. return l2 (32-bit zero-extended)
```
No zero-norm rejection (L2 has no division). Returns 0.0 cleanly for identical vectors.

**Pre-A9 — Dot product canonical form.**
```
1. dot       = sum_i a[i] * b[i]   (384 mulss + 383 addss)
2. return dot (32-bit zero-extended)
```
No normalization. No zero check.

**Pre-A10 — Lookup-top-1 algorithm with explicit MAC-verify-each-candidate (D3.18).**
```
1. Resolve query_id → query_slot_ptr via registry_lookup_embedding (MAC verify)
2. Initialize best_id = 0; best_score = -infinity (i32 bit pattern 0xFF800000)
3. For embed_id in 1..vm_embedding_next:
4.     If embed_id == query_id: continue (exclude query from results)
5.     candidate_slot = registry_lookup_embedding(embed_id)
6.     If candidate_slot == 0: continue (sentinel/missing)
7.     **MAC verify candidate_slot via siphash_compute over EMBEDDING_MAC_INPUT_QWORDS;
       compare to candidate_slot[EMBEDDING_OFF_MAC]; if mismatch → continue
       (substrate refuses corrupt slot; treats as missing; does NOT halt lookup
       with err — corrupt slots are skipped and lookup proceeds with remaining
       valid candidates)**
8.     score = compute_cosine(query_slot, candidate_slot)
9.     If score > best_score (via comiss; IEEE-aware): best_score = score; best_id = embed_id
10. If best_id == 0: return Outcome::Err(ERR_INVALID_EMBEDDING_ARG, source_op=OP_EMBEDDING_LOOKUP_TOP1)
    (empty pool / only query in pool / all candidates corrupt)
11. Return Outcome::Ok(best_id)
```
**MAC-verify on each candidate** matches Pod 3 `.embedding_accessor_common` accessor convention exactly (D3.18 codifies). Corrupt candidates skipped silently; lookup proceeds with valid remainder. Ties go to first-encountered (lowest embed_id). compute_cosine called with raw slot pointers (no internal re-resolution; saves redundant work).

**Pre-A11 — Energy costs (provisional priors; TB measures at B-N canary surfaces; architect adjudicates at AUTHORIZED-2B):**
```
0xC5 OP_EMBEDDING_SIGN_HANDLE  = 1j      (accessor convention)
0xC6 OP_EMBEDDING_COSINE       = 400j    (1152 mulss + 1149 addss + 2 sqrtss + mul + div + ucomiss + MAC verify ×2)
0xC7 OP_EMBEDDING_DOT_PRODUCT  = 200j    (384 mulss + 383 addss + MAC verify ×2)
0xC8 OP_EMBEDDING_L2_DISTANCE  = 280j    (384 sub + 384 mulss + 383 addss + sqrtss + MAC verify ×2)
0xC9 OP_EMBEDDING_LOOKUP_TOP1  = 100000j (256 × cosine internal work including 256 × MAC verify;
                                          D3.17 anticipated-worst-case static costing for heavy composite ops;
                                          dynamic costing deferred per V1.0 simplicity convention)
```
Lookup is heavyweight by V1.0 design; demos forge larger-budget caps (≥1,000,000j) for lookup tests. Static-cost convention preserved across substrate; dynamic cost deferred to future pod when usage patterns motivate the dispatch complexity.

**Pre-A12 — Witness doctrine extension (D3.13).** Compute-over-substrate-state ops bypass bit-check per the same convention as accessor/observation paths (Pod 1.10.2b1 D2.1.2 generalized). No `BIT_EMBEDDING_SIMILARITY` in V1.0 vocabulary. Cosine/dot/L2/lookup execute regardless of current_cap's bitmap. Codifies witness doctrine generalizing from accessors (slot field reads) to compute (math over slot content). Substrate is witness, not police, for read-and-compute paths; only state mutation requires forge bits.

**Pre-A13 — Maid helpers in `boot/maid.asm`.** New file mirroring `boot/babylon.asm` pattern. Exports:
```
compute_cosine(rdi=embedding_slot_ptr_a, rsi=embedding_slot_ptr_b)
    → rax = f32-as-i64 on success
    → rax = 0 (sentinel; high bit clear) AND CF set on zero-norm rejection
    Clobbers: rax, rcx, rdx, xmm0-xmm5
    Preserves: rbx, rbp, r12-r15

compute_dot_product(rdi=slot_ptr_a, rsi=slot_ptr_b) → rax = f32-as-i64; no err
compute_l2_distance(rdi=slot_ptr_a, rsi=slot_ptr_b) → rax = f32-as-i64; no err
lookup_top1(rdi=query_slot_ptr) → rax = best_match_embedding_id (0 if pool empty/only-self)
```
Helpers take **raw slot pointers** (post-MAC-verify, post-registry-lookup); callers do registry resolution + initial MAC verify. This factoring avoids redundant work in lookup_top1 (resolve query once, iterate candidates with internal MAC-verify per Pre-A10). Helpers do NOT call `.construct_ok_outcome` — that's the opcode-handler's job. Helpers return primitive values; handlers wrap.

**Pre-A14 — D-entry numbering.** Continues flat from Pod 3's D3.11. Pod 3.5's D-entries are D3.12 through D3.22 (eleven entries). NOT sub-numbered as D3.5.X.

**Pre-A15 — Test surface count anticipated.** ~17 surfaces. Larger than Pod 3 (7 surfaces) due to FP correctness coverage + lookup demos + reverse-side-table verification + bit-exactness canaries + witness doctrine canary. Acknowledged.

---

## R-call recon directives

**R1 — Pre-flight three-oracle.** All three at 86fb0572 verbatim. If drift, halt.

**R2 — Identifier audit.** Tree-wide grep for `cosine|dot_product|l2_distance|lookup|MAID|Maid|maid|compute_` (excluding `boot/cap.asm:262` SipHash test-vectors comment). Should be near-zero collisions. Surface any.

**R3 — Constants enumeration:**
- Confirm OP_EMBEDDING_NEW=0xC0, OP_EMBEDDING_ARENA=0xC1, OP_EMBEDDING_OWNER=0xC2, OP_EMBEDDING_CREATOR=0xC3, OP_EMBEDDING_GET_DIM=0xC4 from Pod 3 seal
- Confirm 0xC5-0xCF unclaimed (TB enumerates current allocation)
- Confirm SIGN_POOL_SLOTS, EMBEDDING_POOL_SLOTS current values
- Confirm ERR_INVALID_EMBEDDING_ARG = 9 from Pod 3

**R4 — FP instruction canonicality (LOAD-BEARING for D3.12 doctrine).** Tree-wide grep for x87 instructions (`fld`, `fmul`, `faddp`, `fstp`, etc.) and SIMD-vector instructions (`mulps`, `addpd`, `vfmadd*`, etc.) in `boot/`. Should be near-zero hits — confirm substrate has no pre-existing FP arithmetic. Surface any pre-existing FP use; if surprising, flag for D3.12 doctrine framing.

Also verify NASM 2.16.01 emits SSE scalar ops cleanly for `movss xmm0, [rsi]`, `mulss xmm0, xmm1`, `sqrtss xmm0, xmm0` etc. as written. No assembler magic.

**R5 — Pool expansion mechanics.** Audit current `vm_embedding_pool` BSS allocation in `boot/vmdata.asm`:
- Confirm size declared as `EMBEDDING_POOL_SLOTS * EMBEDDING_SLOT_BYTES` (constant-driven, scales cleanly via constant change)
- If hardcoded bytes anywhere, surface as A-finding
- Verify BSS layout has space for ~300KB additional Embedding pool + 2KB reverse side-table without colliding with other pools or kernel data
- Confirm no boot-code assumes EMBEDDING_POOL_SLOTS=64 hardcoded

**R6 — Reverse side-table layout.** Confirm `vm_embedding_sign_handle` BSS allocation slot fits adjacent to existing `vm_sign_embedding_handle` (Pod 3) per organizational convention. Sign side-table stays 64 entries; embedding reverse side-table is 256 entries.

**R7 — `.construct_ok_outcome` signature verification.** Read verbatim from `boot/cbs_vm.asm`. Confirm:
- Accepts arbitrary 64-bit value via rdi without semantic-validity assertion (cosine returns f32 bit-pattern zero-extended; helper must not reject non-typed-id values)
- Accepts TYPE_CODE_EMBEDDING via r8
- Returns outcome_id via rax
- Caller does the operand-stack push

**R8 — Pre-existing helper file structure.** Read `boot/babylon.asm` verbatim (full ~140 lines). Use as template for `boot/maid.asm` structure (header comment style, function organization, register clobber convention, top-level vs dot-prefix label conventions).

Read `boot/embedding.asm` verbatim. Confirm `registry_lookup_embedding` signature (rdi=embedding_id → rax=slot_ptr or 0). Note: lookup_top1 helper in maid.asm calls `registry_lookup_embedding` directly via extern declaration.

**R9 — Build chain confirmation.** Two-build determinism on Pod 3 entry contract `41e92bb2...`. nasm 2.16.01 / mtools 4.0.43 / qemu 8.2.2 unchanged.

**R10 — Numerical stability test-vector enumeration (LOAD-BEARING for FP correctness).** TB constructs canonical f32[384] test vectors with bit-exact specifications:

```
v_zero        : all 384 dims = 0.0           (i32 bits 0x00000000)
v_e0          : dim[0]=1.0, others=0.0        (one-hot first dim)
v_e1          : dim[1]=1.0, others=0.0        (one-hot second dim)
v_neg_e0      : dim[0]=-1.0, others=0.0       (antipodal to v_e0)
v_45deg       : dim[0]=1/sqrt(2), dim[1]=1/sqrt(2), others=0.0  (45° from v_e0 in (e0,e1) plane)
v_uniform     : all 384 dims = 1.0/sqrt(384)  (uniform unit vector; TB enumerates exact i32 bits)
```

Expected outputs (TB enumerates exact i32 bit patterns and adjudicates if any surprise at A6):
```
cosine(v_e0, v_e0)        = 1.0     = 0x3F800000
cosine(v_e0, v_e1)        = 0.0     = 0x00000000
cosine(v_e0, v_neg_e0)    = -1.0    = 0xBF800000
cosine(v_e0, v_45deg)     = 1/sqrt(2) ≈ 0x3F3504F3 (TB confirms exact)
cosine(v_zero, v_e0)      → ERR_INVALID_EMBEDDING_ARG, source_op=0xC6, err_code=9
cosine(v_e0, v_zero)      → ERR_INVALID_EMBEDDING_ARG  (symmetric rejection)

dot(v_e0, v_e0)           = 1.0
dot(v_e0, v_e1)           = 0.0
dot(v_e0, v_neg_e0)       = -1.0

L2(v_e0, v_e0)            = 0.0     = 0x00000000
L2(v_e0, v_e1)            = sqrt(2) ≈ 0x3FB504F3 (TB confirms exact)
L2(v_e0, v_neg_e0)        = 2.0     = 0x40000000
```

TB enumerates at recon and surfaces any non-trivial result (e.g., if 1/sqrt(2) bit pattern differs from expected due to FP rounding mode).

**R11 — Affected surface enumeration.** Pre-Pod-3.5 affected surfaces: zero (Pod 3.5 is purely additive — no retrofit of existing handlers; no field changes; no pool layout changes in Sign pool; OP_SIGN_NEW handler gains one conditional store for reverse side-table but bytecode shape unchanged). ~17 new T-surfaces planned. TB confirms count at HALT 2A.

---

## A-call surfaces (load-bearing recon adjudications)

**A1 — Opcode range 0xC5-0xC9 unclaimed.** Confirm.

**A2 — Pool expansion EMBEDDING_POOL_SLOTS constant-driven.** Surface any hardcoded byte counts requiring refactor.

**A3 — Cosine cost-table 400j vs measured.** TB measures via T-surface canary; architect adjudicates at AUTHORIZED-2B if 400j prior is materially off.

**A4 — Lookup-top-1 cost-table 100,000j vs measured.** Same; demo budgets sized accordingly. Architect adjudicates if cost differs materially.

**A5 — FP instruction set verification.** TB enumerates ALL FP instructions used in `boot/maid.asm`; confirms zero x87 / zero SIMD-vector / zero FMA. Adjudicate at AUTHORIZED-2A if any leak.

**A6 — Numerical-stability test-vector exact bit patterns.** TB enumerates expected outputs with verbatim i32 bit patterns for cosine(v_e0, v_45deg), L2(v_e0, v_e1), and v_uniform construction. Architect adjudicates if any pattern surprises.

**A7 — Reverse side-table indexing convention.** Confirm `(embedding_id - 1) * 8` indexing matches Pod 3's forward side-table convention.

**A8 — `.construct_ok_outcome` value-agnostic signature.** Confirm helper accepts arbitrary 64-bit values without type-id assertion (per R7).

---

(S-call directives, D-entries, DEFERRED updates, B-call tests, Phase 3 staging, closing report — full content per architect's prompt above. Saved verbatim for substrate reference.)

— Chauncey
