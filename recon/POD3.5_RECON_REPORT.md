# Pod 3.5 Recon Report — Maid speaks (semantic operations)

**Pod:** 3.5 — first substrate-USE pod proper; semantic operations + FP determinism doctrine entry
**Entry HEAD:** 86fb0572aab42a261fd50f1c8aaf0efb76425f4a (Pod 3 seal — Maid is born)
**Entry binary contract:** 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3 (verified two-build deterministic)
**Recon date:** 2026-05-06

---

## R1 — Pre-flight three-oracle

```
HEAD:        86fb0572aab42a261fd50f1c8aaf0efb76425f4a
origin/main: 86fb0572aab42a261fd50f1c8aaf0efb76425f4a
ls-remote:   86fb0572aab42a261fd50f1c8aaf0efb76425f4a  refs/heads/main
```

Three-oracle agreement at Pod 3 seal. Pre-existing housekeeping deferral state per DEFERRED #10 / #59 / #62 / #67 / #70 / #74 / #78 / #79 / #84 unchanged.

---

## R2 — Identifier audit

Tree-wide grep `boot/` for new Pod 3.5 identifier candidates:

| Term | Matches | Note |
|---|---|---|
| `cosine` / `Cosine` / `COSINE` | **0** | Fresh territory |
| `dot_product` | **0** | Fresh territory |
| `l2_distance` | **0** | Fresh territory |
| `compute_` | **0** | Fresh territory |
| `MAID` | **0** | Fresh |
| `Maid` (case-insensitive) | 2 narrative-only | `boot/boot.asm:401` Pod 3 %include comment + `boot/data.asm:11` Layer 0 refactor note. **No identifier collisions.** |
| `lookup` | (Grep tool transient error; manual confirmation) | Existing `registry_lookup_*` family (sign/energy/outcome/cap/embedding); no `lookup_top1` / `lookup_*` outside that family |

Fresh territory confirmed for all Pod 3.5 helper identifiers. No collisions surface.

---

## R3 — Constants enumeration

**Pod 3 opcodes (verified verbatim at `boot/defines.asm:170-174`):**
```
OP_EMBEDDING_NEW       = 0xC0
OP_EMBEDDING_ARENA     = 0xC1
OP_EMBEDDING_OWNER     = 0xC2
OP_EMBEDDING_CREATOR   = 0xC3
OP_EMBEDDING_GET_DIM   = 0xC4
```

**0xC5-0xCF unclaimed** in `boot/defines.asm` (no `OP_EMBEDDING_*` declarations beyond 0xC4; no other 0xC*-byte single-byte opcode allocations). 32-bit cap-token tags `0xCA00000X` from legacy demo dispatch (boot/cbs_vm.asm:626-635) are different namespace; no collision.

**TB ratifies architect priors:**
```
OP_EMBEDDING_SIGN_HANDLE  = 0xC5
OP_EMBEDDING_COSINE       = 0xC6
OP_EMBEDDING_DOT_PRODUCT  = 0xC7
OP_EMBEDDING_L2_DISTANCE  = 0xC8
OP_EMBEDDING_LOOKUP_TOP1  = 0xC9
```
0xCA-0xCF reserved for Pod 3.6+. (A1 ✓)

**Pool sizes:**
```
SIGN_POOL_SLOTS      = 64    (boot/defines.asm:239)
EMBEDDING_POOL_SLOTS = 64    (boot/defines.asm:277; will become 256 at Pod 3.5)
```

**Error code:**
```
ERR_INVALID_EMBEDDING_ARG = 9    (boot/defines.asm:139; reused for cosine zero-norm + lookup empty-pool)
```

No new ERR codes needed; existing `ERR_INVALID_EMBEDDING_ARG=9` covers Pod 3.5 failure modes (zero-norm rejection, empty-pool lookup) per architect Pre-A7 / Pre-A10.

---

## R4 — FP instruction canonicality (LOAD-BEARING for D3.12 doctrine)

Tree-wide grep `boot/`:

| Category | Pattern | Matches |
|---|---|---|
| **x87 (forbidden)** | `\b(fld\|fmul\|faddp\|fstp\|fdiv\|fsub\|fsqrt)\b` | **0** |
| **SIMD-vector (forbidden)** | `\b(mulps\|addps\|subps\|divps\|mulpd\|addpd\|vfmadd)\b` | **0** |
| **SSE scalar (allowed)** | `\b(movss\|mulss\|addss\|sqrtss\|xmm[0-9])\b` | **0** (no files) |

**Substrate has zero pre-existing FP code.** boot/maid.asm will be the **first FP code path** in the substrate. Pre-Pod-3.5 codebase is entirely integer-only (siphash_compute uses standard integer arithmetic; all helpers are integer; opcode handlers are integer; arena/owner/creator manipulation is u64).

**D3.12 doctrine implications:**
- No conflict with any pre-existing code; D3.12 lands cleanly as substrate-permanent canon at first-FP-pod
- Zero retrofit needed; D3.12 governs only forward additions
- TB enumerates ALL FP instructions used in `boot/maid.asm` at HALT 2A (must cover only the whitelist per Pre-A5)

NASM 2.16.01 emits SSE scalar ops cleanly; no assembler magic required. Standard syntax `movss xmm0, [rsi]` / `mulss xmm0, xmm1` / `sqrtss xmm0, xmm0` / `comiss xmm0, xmm1` etc. are all standard NASM. `xorps xmm0, xmm0` for sign-bit manipulation (zeroing) is also standard.

---

## R5 — Pool expansion mechanics

`boot/vmdata.asm:55-61` (Pod 3 BSS) verbatim:
```asm
; Embedding pool (Pod 3 — D3.1; 64 slots × 1576 bytes = ~100KB; bump-allocator)
;   Fifth typed pool. Slot is MAC-protected (full vector under SipHash per D3.3).
;   Substrate-prep mode: pool + accessors land at this pod; semantic operations
;   (similarity, lookup-by-meaning) deferred to Pod 3.5+.
    align 16
vm_embedding_pool: times EMBEDDING_POOL_SLOTS * EMBEDDING_SLOT_BYTES db 0
vm_embedding_next: dq 0                ; bump allocator index (next free slot)
```

**Constant-driven sizing confirmed.** Both factors are `%define` constants:
- `EMBEDDING_POOL_SLOTS = 64` (will become 256 at Pod 3.5 S1)
- `EMBEDDING_SLOT_BYTES = 1576` (unchanged)

**64 → 256 expansion lands automatically** by changing `EMBEDDING_POOL_SLOTS` in defines.asm. New pool size: 256 × 1576 = 403,456 bytes (~400KB). Pool growth: +303,232 bytes (~300KB).

**embedding_registry** (vmdata.asm:106-112) follows the same convention:
```asm
embedding_registry:         times EMBEDDING_POOL_SLOTS * 16 db 0
```
256 × 16 = 4,096 bytes (was 1,024 bytes); grows +3,072 bytes. Cascades automatically.

**No hardcoded byte counts in pool/registry sizing.** A2 ratified.

**BSS layout headroom:** the existing BSS section accommodates pools of varying sizes; no fixed-size assumption. The 64-byte pad between aligned regions is ample. No other pool's BSS sizing or boot-time alignment depends on EMBEDDING_POOL_SLOTS.

---

## R6 — Reverse side-table layout

Pod 3's `vm_sign_embedding_handle` (vmdata.asm:71) is sized `times SIGN_POOL_SLOTS dq 0` = 64 × 8 = 512 bytes. **Stays unchanged at Pod 3.5** (one entry per Sign; Sign pool unchanged at 64).

Pod 3.5's new `vm_embedding_sign_handle` will be sized `times EMBEDDING_POOL_SLOTS dq 0`. After EMBEDDING_POOL_SLOTS = 256: 256 × 8 = **2,048 bytes**. Reverse side-table indexed by `(embedding_id - 1) * 8`; written at OP_SIGN_NEW post-registry when embedding_handle != 0; read via OP_EMBEDDING_SIGN_HANDLE accessor.

Architectural placement at S2 — adjacent to Pod 3's `vm_sign_embedding_handle` per organizational convention. Symmetric naming (forward/reverse). (A7 ✓)

---

## R7 — `.construct_ok_outcome` signature

Confirmed at file fetch (boot/cbs_vm.asm:2466-2526):
- **Input:** rdi = value (arbitrary u64), r8 = value_type_id
- **Output:** rax = outcome_id
- **Helper does NOT push to operand stack** — caller does `mov [r13], rax; add r13, 8`
- **Body:** `mov [rbx + 0x10], rdi` stores value raw; **no semantic-validity assertion on rdi**

Cosine returning f32 bit-pattern zero-extended works trivially (Pod 3 B8 already validated this empirically with `dim[100]=1120403456`). Same pattern for cosine/dot/L2: compute f32 → zero-extend to i64 in rax → pass to `.construct_ok_outcome` → wrap in Outcome::Ok with TYPE_CODE_EMBEDDING.

(A8 ✓)

---

## R8 — Helper file structure (template)

Confirmed at file fetch.

**`boot/babylon.asm` pattern for `boot/maid.asm` to mirror:**
- File-header `;=== Service — purpose (Pod N.M)` block with metaphysical framing + cross-references to design doctrines (Pre-A / D-entries)
- Each helper has its own `; --- name(rdi=arg, rsi=arg) ---` docstring block: input / output / clobbers / preserves
- Top-level labels (not dot-prefixed) for entry points; dot-prefixed locals for internal branches
- Standard convention: clobber rax/rcx/rdx/rsi/rdi; preserve r12-r15/rbx/rbp (VM state regs)
- Helper bodies use `push X / mov rdi, ... / call registry_lookup_X / pop X` pattern to preserve args across registry calls

**xmm clobber convention micro-extension** (per architect's HALT 1 implementation note 1): boot/maid.asm helper docstrings explicitly document `xmm0-xmm5` clobber set. Substrate's existing register convention is silent on xmm because no pre-existing helper uses FP. Pod 3.5's helpers are first to claim xmm registers; doctrine micro-extension lands at S3 in maid.asm header comment.

**`registry_lookup_embedding`** (boot/embedding.asm:55-78): pure registry lookup, no internal MAC verify. Caller MAC-verifies after lookup. lookup_top1 helper in maid.asm calls this directly; per-candidate MAC verify happens in lookup_top1's loop body (D3.18).

---

## R9 — Build chain confirmation

```
NASM version 2.16.01                                     ✓ matches Pod 3
mcopy (GNU mtools) 4.0.43                                ✓ matches
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16)  ✓ matches
```

**Two-build determinism on Pod 3 entry contract:**
```
build1 sha256: 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3
build2 sha256: 41e92bb22560f5e632bd7df0dc2a05427a7b5f2075fb91555cfbe873be4582f3
```

Both builds byte-identical to Pod 3 sealed contract. Build chain ready.

---

## R10 — Numerical stability test-vector enumeration (LOAD-BEARING — A6 surface)

Bit-exact f32 simulation via Python `struct.pack('<f', ...)`:

### Canonical scalar f32 bit patterns

| Value | i32 bits |
|---|---|
| 0.0 | `0x00000000` |
| 1.0 | `0x3F800000` |
| -1.0 | `0xBF800000` |
| 2.0 | `0x40000000` |
| -2.0 | `0xC0000000` |
| 1/sqrt(2) ≈ 0.7071067690849304 | `0x3F3504F3` |
| sqrt(2) ≈ 1.4142135381698608 | `0x3FB504F3` |
| -infinity (best_score init) | `0xFF800000` |
| 1/sqrt(384) ≈ 0.05103... | `0x3D5105EC` |

### Test vector outputs through Form A canonical evaluation

**cosine(v_e0, v_e0) = 1.0 = `0x3F800000`** ✓ matches architect prior

**cosine(v_e0, v_e1) = 0.0 = `0x00000000`** ✓ matches architect prior
- dot = 0; norm_a_sq = norm_b_sq = 1.0; cosine = 0/1 = 0

**cosine(v_e0, v_neg_e0) = -1.0 = `0xBF800000`** ✓ matches architect prior

**cosine(v_e0, v_45deg) — LOAD-BEARING DISCREPANCY (A6):**

Architect prior: `0x3F3504F3` (= mathematical 1/sqrt(2) f32 bits).
**Bit-exact Form A simulation: `0x3F3504F4` (1 ulp higher).**

Why the discrepancy:
- `inv_sqrt2_f32 = 0x3F3504F3 = 0.7071067690849304` (slightly less than mathematical 1/sqrt(2))
- Step 3 norm_b_sq = `inv_sqrt2_f32 * inv_sqrt2_f32` (twice) + 0.0 (382 times):
  - `inv_sqrt2_f32 * inv_sqrt2_f32 = 0x3EFFFFFF = 0.4999999701976776` (NOT exactly 0.5; rounds down)
  - Two halves summed: `0.4999999701976776 + 0.4999999701976776 = 0x3F7FFFFF = 0.9999999403953552` (NOT exactly 1.0)
- Step 6 norm_b = `sqrtss(0x3F7FFFFF) = 0x3F7FFFFF` (the representable value just below 1.0)
- Step 7 denom = `1.0 * 0x3F7FFFFF = 0x3F7FFFFF`
- Step 8 cosine = `0x3F3504F3 / 0x3F7FFFFF = 0x3F3504F4` (LSB up because dividing by slightly-less-than-1.0)

**The 1-ulp shift is a load-bearing demonstration of why D3.12 FP determinism doctrine matters.** Bit-exact f32 results require simulation, not abstract math. The architect's prior was the abstract-math expected value (1/sqrt(2)); Form A through f32 produces 1 ulp higher due to the lossy `inv_sqrt2_f32^2` rounding-down propagating through the denominator.

**TB recommends architect ratify B10 (T4 cosine_45deg) expected output as `0x3F3504F4`** (the bit-exact Form A result). Test surface compares against the empirical f32 result, not the mathematical value.

**cosine(v_zero, v_e0) → ERR_INVALID_EMBEDDING_ARG, source_op=0xC6=198, err_code=9** ✓ (Pre-A7 zero-norm rejection)

**dot(v_e0, v_e0) = 1.0 = `0x3F800000`** ✓
**dot(v_e0, v_e1) = 0.0 = `0x00000000`** ✓
**dot(v_e0, v_neg_e0) = -1.0 = `0xBF800000`** ✓

**L2(v_e0, v_e0) = 0.0 = `0x00000000`** ✓
**L2(v_e0, v_e1) = sqrt(2) = `0x3FB504F3`** ✓ matches architect prior
- diff_sq = (1-0)^2 + (0-1)^2 + 0+0+...+0 = 2.0 = `0x40000000`
- sqrtss(2.0) = sqrt(2) = `0x3FB504F3` exactly representable

**L2(v_e0, v_neg_e0) = 2.0 = `0x40000000`** ✓
- diff_sq = (1-(-1))^2 + 0+0+...+0 = 4.0 = `0x40800000`
- sqrtss(4.0) = 2.0 = `0x40000000` exactly

**Summary of A6:** 12 of 13 architect-predicted bit patterns match bit-exact Form A simulation. One discrepancy:
- cosine(v_e0, v_45deg): architect prior 0x3F3504F3 → bit-exact 0x3F3504F4 (1 ulp shift due to Form A norm_b_sq accumulation through f32(half+half) ≠ 1.0)

### v_uniform construction

`v_uniform[i] = 1.0/sqrt(384)` for all 384 dims = `0x3D5105EC` per dim.

For testing: `cosine(v_uniform, v_uniform)` should be 1.0 if normalized correctly. Computing:
- dot = 384 × (1/sqrt(384))^2 ≈ 384 × (1/384) = 1.0 (with f32 accumulation effects)
- norm_a_sq = norm_b_sq = same as dot ≈ 1.0
- cosine = 1.0 / sqrt(1.0 * 1.0) ≈ 1.0 (modulo f32 accumulation errors)

The accumulated 384-element sum may not produce exactly 1.0 in f32 due to associativity of repeated addition. Bit-exact result depends on accumulation order; canonical sequential left-to-right produces a specific bit pattern. Test surfaces using v_uniform should read back via OP_EMBEDDING_GET_DIM (which produces exact stored values) rather than computing cosine through Form A on accumulated sums (which may shift LSBs).

**Recommendation:** Pod 3.5 test surfaces avoid v_uniform-vs-v_uniform cosine for bit-exactness assertions; use v_e0/v_e1/v_neg_e0/v_45deg for primary correctness coverage (which all produce well-defined exact bit patterns per the table above).

---

## R11 — Affected surface enumeration

**Pre-Pod-3.5 affected surfaces: ZERO.**

Pod 3.5 is purely additive:
- No retrofit of existing handlers (5 new handlers + 1 OP_SIGN_NEW micro-retrofit for reverse side-table conditional store)
- No field changes to any pool
- No pool layout changes in Sign/Energy/Outcome/Cap pools
- Embedding pool grows from 64 to 256 slots (BSS allocation only; no slot-layout change)
- OP_SIGN_NEW handler gains one conditional store for reverse side-table when embedding_handle != 0; **bytecode shape unchanged** (5-arg ABI preserved); existing Sign demos with embedding_handle=0 default produce byte-identical output

**~17 new T-surfaces planned** per architect Pre-A15:
1. T1 cosine_identical
2. T2 cosine_orthogonal
3. T3 cosine_antiparallel
4. T4 cosine_45deg (FP correctness moment)
5. T5 cosine_zero_norm (rejection moment)
6. T6 dot_product_basic
7. T7 l2_distance_basic
8. T8 lookup_top1_basic
9. T9 lookup_top1_empty (rejection moment)
10. T10 reverse side-table round-trip
11. T11 lookup_with_sign_recovery (Maid composition)
12. T12 large_codebook_stress (256-slot pool validation)
13. T13 fp_determinism_canary
14. T14 witness compute-without-bit-check
15. T15 sub-cap canary for compute ops
16. (T16/T17 reserved for B22/B23 cost-table canary measurement surfaces)

TB confirms exact count at HALT 2A.

---

## A-call surfaces with TB recommendations

### A1 — Opcode range 0xC5-0xC9 unclaimed
**TB confirms:** clean. Ratify architect priors.

### A2 — Pool expansion EMBEDDING_POOL_SLOTS constant-driven
**TB confirms:** vm_embedding_pool + embedding_registry both sized via constant expression. 64→256 cascades automatically via single defines.asm edit. No hardcoded byte-count refactor needed.

### A3 — Cosine cost-table 400j vs measured
Deferred to B-N canary surface (B22). Architect adjudicates at AUTHORIZED-2B.

### A4 — Lookup-top-1 cost-table 100,000j vs measured
Deferred to B-N (B23). Architect adjudicates at AUTHORIZED-2B.

### A5 — FP instruction set verification
**TB confirms:** zero pre-existing FP use in boot/. boot/maid.asm will be the first FP code in substrate. TB enumerates ALL FP instructions used in maid.asm at HALT 2A; will cover only the D3.12 whitelist (movss, mulss, addss, subss, divss, sqrtss, comiss, ucomiss, xorps, cvtsi2ss, cvtss2si).

### A6 — Numerical-stability test-vector exact bit patterns (LOAD-BEARING)
**TB findings:**

| Test | Architect prior | Bit-exact Form A | Match |
|---|---|---|---|
| cosine(v_e0, v_e0) | `0x3F800000` | `0x3F800000` | ✓ |
| cosine(v_e0, v_e1) | `0x00000000` | `0x00000000` | ✓ |
| cosine(v_e0, v_neg_e0) | `0xBF800000` | `0xBF800000` | ✓ |
| **cosine(v_e0, v_45deg)** | **`0x3F3504F3`** | **`0x3F3504F4`** | **✗ (1 ulp shift)** |
| L2(v_e0, v_e1) | `0x3FB504F3` | `0x3FB504F3` | ✓ |
| L2(v_e0, v_neg_e0) | `0x40000000` | `0x40000000` | ✓ |
| L2(v_e0, v_e0) | `0x00000000` | `0x00000000` | ✓ |
| dot(*) | various | matches | ✓ |
| zero-norm rejection | ERR | ERR | ✓ |

**TB recommendation A6:** ratify `0x3F3504F4` as the bit-exact Form A result for cosine(v_e0, v_45deg). The architect's prior `0x3F3504F3` was the abstract-math 1/sqrt(2); Form A canonical evaluation through f32 produces 0x3F3504F4 due to the lossy `inv_sqrt2_f32^2` rounding-down propagating through Step 3 (norm_b_sq) and Step 7 (denom). The 1-ulp shift is bit-exact and deterministic; B10 (T4) test surface should compare against `0x3F3504F4`.

### A7 — Reverse side-table indexing convention
**TB confirms:** `(embedding_id - 1) * 8` indexing matches Pod 3 forward side-table convention exactly.

### A8 — `.construct_ok_outcome` value-agnostic signature
**TB confirms:** verified at file fetch. Helper accepts opaque u64 in rdi without semantic validity check. Pod 3 B8 already empirically validated f32 bit pattern round-trip through this helper.

---

## Surprises

### Surprise 1 — A6 1-ulp FP shift discovered at recon (LOAD-BEARING)

**Tenth empirical landing of architect-error doctrine family** (D2.2.11 → D3.11). Subtype: **FP-numerical-precision-prediction-vs-bit-exact-f32-result**.

Architect's R10 prior expected `cosine(v_e0, v_45deg) = 0x3F3504F3` (abstract-math 1/sqrt(2) f32). Bit-exact Form A simulation through Python `struct.pack('<f', ...)` produces `0x3F3504F4` (1 ulp higher). Cause: Form A's two-sqrt evaluation order accumulates `inv_sqrt2_f32^2` through the norm_b_sq sum (`half + half = 0x3F7FFFFF` not exactly 1.0), which propagates through the denominator and shifts the cosine by 1 ulp.

**This is exactly why D3.12 FP determinism doctrine matters.** Bit-exact f32 reproducibility requires simulation, not algebra. The substrate's two-build determinism guarantee extends to FP results only because operations are bit-exact reproducible per IEEE 754; abstract math doesn't predict the exact bit pattern when intermediate values lose precision.

TB recommends ratifying 0x3F3504F4 at AUTHORIZED-1.

### Surprise 2 — Substrate has zero pre-existing FP code

**Confirmed empirically at R4.** No x87, no SIMD-vector, no SSE scalar, no xmm references in any boot/ file. boot/maid.asm will be the first FP code path in the substrate.

D3.12 doctrine lands as substrate-permanent canon at first-FP-pod with zero retrofit. Future pods inherit; the discipline is established at maximum-clarity moment (no pre-existing patterns to override).

### Surprise 3 — xmm clobber convention micro-extension

Architect's HALT 1 implementation note 1 confirmed: substrate's existing register convention is silent on xmm because no helper has needed them. Pod 3.5 helpers are the first to claim xmm0-xmm5; the doctrine micro-extension lands at S3 in maid.asm header comment block. Future helpers requiring xmm follow the same pattern: explicitly document xmm clobber set.

### Surprise 4 — v_uniform bit-exactness boundary

For the v_uniform vector (all 384 dims = 1/sqrt(384)), the canonical 384-element sum accumulation has order-dependent behavior in f32. cosine(v_uniform, v_uniform) won't necessarily produce exactly 1.0 due to f32 associativity loss in repeated `addss`. Test surfaces should avoid v_uniform-vs-v_uniform cosine for bit-exactness assertions; use the e0/e1/neg_e0/45deg vectors for primary correctness coverage.

This is not load-bearing for the prompt (v_uniform is mentioned in R10 but not used as a primary test vector in B-items 7-13). Surface as documentation note; no architect adjudication needed unless bit-exact v_uniform tests get added later.

---

## HALT 1 conclusion

Three load-bearing items for AUTHORIZED-1 adjudication:

1. **A6 — cosine(v_e0, v_45deg) bit-exact result is `0x3F3504F4` (1 ulp from architect prior `0x3F3504F3`).** TB recommends ratifying 0x3F3504F4 as the correct expected output for B10 (T4 cosine_45deg). The shift is bit-exact, deterministic, and demonstrates exactly why D3.12 FP determinism doctrine matters.

2. **Surprise 2 — substrate is FP-virgin.** boot/maid.asm is the first FP code path. D3.12 lands as substrate-permanent canon with zero retrofit; future pods inherit.

3. **Surprise 3 — xmm clobber convention micro-extension.** Architect's HALT 1 implementation note ratified at green-light; lands at S3 in maid.asm header comment block.

Other A-calls (A1-A5, A7, A8) ratify architect priors. A3/A4 cost-table verification deferred to B22/B23 measurement surfaces at Phase 2B.

Substrate state at HALT 1: 86fb0572 sealed; build chain deterministic at 41e92bb2... (Pod 3 entry contract); range 0xC5-0xCF clean for Pod 3.5 allocation; pool capacity 64 awaiting D3.16 expansion to 256; reverse side-table BSS slot reserved adjacent to Pod 3's forward side-table.

Awaiting **AUTHORIZED-1**. Stand by.
