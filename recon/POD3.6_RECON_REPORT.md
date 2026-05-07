# Pod 3.6 Recon Report — Maid composes (synthesis: add + subtract + scale + normalize + lerp + accessor)

**Pod:** 3.6 — first forge-tier substrate-USE pod; Maid V1.0 synthesis layer; the substrate becomes generator of meaning
**Entry HEAD:** 88fcb958b20d08f3ff8953f07f32425db3c45845 (Pod 3.5 seal — Maid speaks)
**Entry binary contract:** a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad (verified two-build deterministic)
**Recon date:** 2026-05-07

---

> Pod 3.6 crosses the witness/forge boundary inside the compute tier. D3.13 witness doctrine governed Pod 3.5's compute-over-substrate-state; Pod 3.6 introduces compute-that-creates-substrate-state. The substrate gains its first synthesis primitives — add, subtract, scale, normalize, lerp — each of which forges a new typed Embedding from existing ones, with synthesis lineage tracked via D3.20-generalized non-MAC parallel side-table. Pod 3.6 makes Maid the lexical-computation pole as designed: housekeeper plus composer. Two A6 landings surface at recon — normalize(v_uniform) accumulator drift and lerp irrational-t asymmetric traversal — both materially larger than Pod 3.5's 1-ulp cosine_45deg precedent. The project learns how to learn from its FP frontier; D3.28 codifies the discipline.

---

## R1 — Pre-flight three-oracle

```
HEAD:        88fcb958b20d08f3ff8953f07f32425db3c45845
origin/main: 88fcb958b20d08f3ff8953f07f32425db3c45845
ls-remote:   88fcb958b20d08f3ff8953f07f32425db3c45845  refs/heads/main
```

Three-oracle agreement at Pod 3.5 seal. Pre-existing housekeeping deferral state per DEFERRED #10 / #59 / #62 / #67 / #70 / #74 / #78 / #79 / #80 (partial) / #83 (partial) / #84 / #86 / #87 / #88 unchanged.

---

## R2 — Identifier audit

Tree-wide grep `boot/` for new Pod 3.6 identifier candidates:

| Term | Matches | Note |
|---|---|---|
| `synthesis` / `SYNTHESIS_` | **0** | Fresh territory |
| `vm_embedding_synthesis` | **0** | Fresh BSS identifier |
| `compute_add` / `compute_subtract` / `compute_scale` / `compute_normalize` / `compute_lerp` | **0** | Fresh helper names |
| `OP_EMBEDDING_ADD` / `_SUBTRACT` / `_SCALE` / `_NORMALIZE` / `_LERP` / `_SYNTHESIS_HANDLE` | **0** | Fresh opcode names |
| `lerp` / `LERP` (case-insensitive, tree-wide) | **0** | Fresh; no narrative-only matches |

Fresh territory confirmed for all Pod 3.6 helper / BSS / opcode / synthesis-tuple identifiers. No collisions surface anywhere in the tree.

---

## R3 — Constants enumeration

**Pod 3 + Pod 3.5 OP_EMBEDDING_ range fully consumed at 0xC0–0xC9** (verified verbatim at `boot/defines.asm:170-185`):

```
OP_EMBEDDING_NEW              = 0xC0
OP_EMBEDDING_ARENA            = 0xC1
OP_EMBEDDING_OWNER            = 0xC2
OP_EMBEDDING_CREATOR          = 0xC3
OP_EMBEDDING_GET_DIM          = 0xC4
OP_EMBEDDING_SIGN_HANDLE      = 0xC5
OP_EMBEDDING_COSINE           = 0xC6
OP_EMBEDDING_DOT_PRODUCT      = 0xC7
OP_EMBEDDING_L2_DISTANCE      = 0xC8
OP_EMBEDDING_LOOKUP_TOP1      = 0xC9
```

**0xCA–0xCF unclaimed.** Cost-table at `boot/energy_costs.asm:144` row 0xCA–0xCF currently `dq 1, 1, 1, 1, 1, 1` with annotation `; 0xCA–0xCF reserved for Pod 3.5+ extensions`. Six entries, **one-to-one match with Pod 3.6's allocation**. (See Surprise 1 — substrate pre-shaping.)

**TB ratifies architect priors:**
```
OP_EMBEDDING_ADD              = 0xCA
OP_EMBEDDING_SUBTRACT         = 0xCB
OP_EMBEDDING_SCALE            = 0xCC
OP_EMBEDDING_NORMALIZE        = 0xCD
OP_EMBEDDING_LERP             = 0xCE
OP_EMBEDDING_SYNTHESIS_HANDLE = 0xCF
```
(A1 ✓.)

**Synthesis source-op codes (new constant block):**
```
SYNTHESIS_OP_NONE       = 0x00     ; BSS-zero default; non-synthesized embeddings register as 0
SYNTHESIS_OP_ADD        = 0x01
SYNTHESIS_OP_SUBTRACT   = 0x02
SYNTHESIS_OP_SCALE      = 0x03
SYNTHESIS_OP_NORMALIZE  = 0x04
SYNTHESIS_OP_LERP       = 0x05
; 0x06-0xFF reserved for Pod 3.7+ extensions
```

**Synthesis tuple Layout 2 quad-tuple constants:**
```
SYNTHESIS_TUPLE_BYTES         = 32
SYNTHESIS_TUPLE_OFF_OP        = 0
SYNTHESIS_TUPLE_OFF_SOURCE_A  = 8
SYNTHESIS_TUPLE_OFF_SOURCE_B  = 16
SYNTHESIS_TUPLE_OFF_SCALAR    = 24
```

**Inherited (no Pod 3.6 change):**
- `BIT_EMBEDDING_FORGE = (1 << 4) = 0x10` — declared and consumed at `OP_EMBEDDING_NEW` dispatch site (`cbs_vm.asm:2172-2177`); synthesis ops inherit gating without new bit (R9)
- `TYPE_CODE_EMBEDDING = 7` — Outcome wrap value-type-id
- `ERR_INVALID_EMBEDDING_ARG = 9` — covers zero-norm rejection on normalize, parameter validation on lerp; no new ERR codes needed
- Slot field offsets: `EMBEDDING_OFF_ID_SELF = 0x000`, `EMBEDDING_OFF_ARENA_ID = 0x008`, `EMBEDDING_OFF_OWNER_DEMOD_ID = 0x010`, `EMBEDDING_OFF_CREATOR_CAP_ID = 0x018`, `EMBEDDING_OFF_VECTOR = 0x020`, `EMBEDDING_OFF_MAC = 0x620`
- Pool sizing: `EMBEDDING_DIM = 384`, `EMBEDDING_VECTOR_BYTES = 1536`, `EMBEDDING_SLOT_BYTES = 1576`, `EMBEDDING_POOL_SLOTS = 256`, `EMBEDDING_MAC_INPUT_QWORDS = 196`

---

## R4 — Forge-path canonicality (LOAD-BEARING for Phase 1.2 mirror)

Canonical forge sequence per `OP_EMBEDDING_NEW` (`cbs_vm.asm:2166-2255`):

1. Pop vector_addr from operand stack
2. Bit-check `BIT_EMBEDDING_FORGE` via `babylon_check_authority(rdi=mask, rsi=current_cap_id)` → `.embedding_new_insufficient_authority` on fail
3. Pool capacity check vs `EMBEDDING_POOL_SLOTS` → `.embedding_new_pool_full` on full
4. `.embedding_alloc` → slot_ptr (in `rbx` by convention; `rbx` is callee-saved across siphash per substrate convention)
5. Write placeholder id=0, then `current_cap_arena_id_cache`, `current_cap_owner_demod_id_cache`, `current_cap_id` at slot offsets 0x000 / 0x008 / 0x010 / 0x018
6. `rep movsb` 1536-byte vector copy (rsi=vector_addr, rdi=slot+0x020, rcx=1536)
7. `registry_register_embedding(rdi=slot_ptr)` → rax = embedding_id; preserves rdi
8. **R7-corrected ordering**: stamp `[rbx + EMBEDDING_OFF_ID_SELF] = embedding_id` AFTER registry — placeholder→content→registry→id-stamp→siphash sequence is canon (Pod 3 R7)
9. `siphash_compute(rdi=slot_ptr, rsi=EMBEDDING_MAC_INPUT_QWORDS=196)` → MAC stamped at +0x620; preserves rdi
10. `.construct_ok_outcome(rdi=embedding_id, r8=TYPE_CODE_EMBEDDING)` — D3.9 single-fire axiom; handler does NOT call `babylon_charge_lineage` directly

**Phase 1.2 synthesis forge mirrors verbatim with one inserted step between 9 and 10:**

**9.5. Synthesis-tuple write at `vm_embedding_synthesis + (embedding_id - 1) * SYNTHESIS_TUPLE_BYTES`:**
```nasm
; rbx = slot_ptr (preserved); rax = embedding_id from step 7;
; handler-staged: source_a_id, source_b_or_scalar, scalar_or_zero
; Write tuple at vm_embedding_synthesis + (embedding_id - 1) * 32
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax                                 ; embedding_id
    dec     rcx                                      ; - 1
    shl     rcx, 5                                   ; * SYNTHESIS_TUPLE_BYTES (32)
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       <SYNTHESIS_OP_*>
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], <source_a>
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], <source_b>
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   <scalar>
```
(Final register choreography fixed at Phase 1.2 build; sketch holds the architectural shape.)

The position **post-siphash, pre-Outcome-wrap** matches `OP_SIGN_NEW`'s reverse-table-write-after-registry shape (`vmdata.asm:81-87` documents the convention; the existing OP_SIGN_NEW handler enacts it). Substrate trusts its own write paths — D3.20 inheritance. The placement is canon-aligned, not novel; D3.6's "Reclaimed-slot via parallel BSS" pattern from Pod 3 is the prior precedent.

(A4 ✓.)

---

## R5 — BSS placement

Existing reverse side-table at `vmdata.asm:81-89` (verbatim):
```asm
; Embedding reverse side-table (Pod 3.5 — D3.20; reverse of D3.4 forward direction)
;   Parallel BSS array indexed by (embedding_id - 1). Tracks Embedding->Sign linkage
;   for O(1) recovery of "which Sign owns this embedding". Written at OP_SIGN_NEW
;   post-registry_register_sign WHEN embedding_handle != 0:
;       vm_embedding_sign_handle[(embedding_handle - 1) * 8] = sign_id
;   Read via OP_EMBEDDING_SIGN_HANDLE accessor (0xC5). Returns 0 if no Sign linked.
;   Sized to EMBEDDING_POOL_SLOTS (256 post-Pod-3.5 expansion); 256 × 8 = 2048 bytes.
    align 16
vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0
```

Sign registry block begins at `vmdata.asm:91` (`sign_registry_count: dq 0`). The natural gap between line 89 and line 91 is exactly where Pod 3.6's `vm_embedding_synthesis` lands.

**Pod 3.6 placement** (post-line-89, pre-line-91):
```asm
; Pod 3.6 — synthesis side-table (D3.20 generalized: non-MAC parallel linkage)
;   D3.20 broadens from Sign-reverse specifically to non-MAC parallel linkage generally.
;   The convention this side-table embodies was already enacted by vm_embedding_sign_handle
;   above; D3.26 makes the generalization explicit (recognition, not invention).
;   Indexed by (embedding_id - 1) * SYNTHESIS_TUPLE_BYTES.
;   BSS-zero default = SYNTHESIS_OP_NONE (0x00) for non-synthesized embeddings
;   (Sign-forged or raw OP_EMBEDDING_NEW).
;   Written at synthesis forge time (Pod 3.6 ops 0xCA-0xCE);
;   read via OP_EMBEDDING_SYNTHESIS_HANDLE (0xCF) accessor.
;   Substrate trusts its own write paths (D3.20 inheritance).
    align 16
vm_embedding_synthesis: times EMBEDDING_POOL_SLOTS * SYNTHESIS_TUPLE_BYTES db 0
```

**Footprint:** 256 × 32 = 8192 bytes (8KB). Total embedding-tier BSS post-Phase-1.1: ~408KB pool + 2KB sign-reverse + 8KB synthesis ≈ 418KB. Sub-second BSS init at boot; no measurable boot-time impact.

**Organizational symmetry:** `vm_embedding_sign_handle` and `vm_embedding_synthesis` sit adjacent — both are non-MAC parallel side-tables indexed by `(embedding_id - 1) × stride`. Placing them together makes the convention visible structurally. (See Surprise 2.)

---

## R6 — Synthesis tuple Layout 2 byte-exact specification

```
Offset  Field                              Width   Note
------  ---------------------------------  -----   ------------------------------------------
0x00    SYNTHESIS_TUPLE_OFF_OP             qword   Source op code (SYNTHESIS_OP_*)
0x08    SYNTHESIS_TUPLE_OFF_SOURCE_A       qword   embedding_id of first source
                                                   (0 for unsynthesized)
0x10    SYNTHESIS_TUPLE_OFF_SOURCE_B       qword   embedding_id of second source (binary ops);
                                                   scalar (f32-as-i64) for SCALE;
                                                   0 for NORMALIZE / unsynthesized
0x18    SYNTHESIS_TUPLE_OFF_SCALAR         qword   scalar t (f32-as-i64) for LERP only;
                                                   0 for ADD/SUBTRACT/NORMALIZE/SCALE
0x20    (next slot stride)                         32-byte stride
```

**Per-op tuple shapes:**

| Op | source_a | source_b | scalar |
|---|---|---|---|
| ADD | a_id | b_id | 0 |
| SUBTRACT | a_id | b_id | 0 |
| SCALE | a_id | scalar (f32-as-i64) | 0 |
| NORMALIZE | a_id | 0 | 0 |
| LERP | a_id | b_id | t (f32-as-i64) |
| (none / Sign-forged / raw new) | 0 | 0 | 0 |

**Layout 2 commitment rationale** (from architectural sit): Quad-tuple chosen at Phase 1.1 to avoid mid-pod migration when ternary lerp lands at Phase 3.1. Cost: 8 bytes per slot (~2KB across 256 slots) traded for uniform write convention across all five synthesis ops. Layout 1 (triple) would have worked through Phase 2.2 then forced extension at Phase 3.1 — two write conventions in same pod. Layout 2 from the start = one convention for entire pod. Doctrine cost paid once, upstream. (See Surprise 3.)

(A2 / A3 ✓.)

---

## R7 — Cost-table reservation match

`boot/energy_costs.asm:144` row 0xCA–0xCF currently:
```nasm
    dq 1, 1, 1, 1, 1, 1     ; 0xCA-0xCF reserved for Pod 3.5+ extensions
```

Six entries; exact one-to-one match with Phase 1.1's six-opcode allocation. Pod 3.5 left the substrate already shaped for Pod 3.6 — the reservation predated this architectural sit. (See Surprise 1.)

**Phase 1.1 placeholders** (final values land at Phase 2.x post-empirical-measurement):

| Opcode | Phase 1.1 placeholder | Final-value source |
|---|---|---|
| 0xCA OP_EMBEDDING_ADD | 500j | 384 mulss + 384 addss + forge (~100j) + MAC (~10j) |
| 0xCB OP_EMBEDDING_SUBTRACT | 500j | same shape as ADD (subss) |
| 0xCC OP_EMBEDDING_SCALE | 500j | 384 mulss + forge + MAC |
| 0xCD OP_EMBEDDING_NORMALIZE | 700j | sum_sq + sqrt + 384 divss + forge + MAC |
| 0xCE OP_EMBEDDING_LERP | 800j | (1-t) precompute + 768 mulss + 384 addss + forge + MAC |
| 0xCF OP_EMBEDDING_SYNTHESIS_HANDLE | 1j | accessor; mirrors OP_EMBEDDING_SIGN_HANDLE shape |

`current_demod_cost_table_ptr` indirection (Pod 1.8.5c Move 1) means Phase 1.1 placeholders land in the static table; per-demod tuning available at any later phase.

(A5 ratifies placeholders; final values at AUTHORIZED-2A or AUTHORIZED-2B per measurement.)

---

## R8 — Babylon ripple inheritance

`babylon_charge_lineage(rdi=cost, rsi=originating_cap_id)` (`boot/babylon.asm:63`) — walks `parent_cap_id` chain, `shr rdi, 1` per level, adds halved cost to ancestor's `[CAP_OFF_ENERGY_USED]`, terminates on parent=0 OR cost-decayed-to-0. Clobbers rax/rcx/rdx/rsi/rdi. 0j substrate-bookkeeping per D3.10.

`.construct_ok_outcome` (`cbs_vm.asm:2752`) — the **sole** spatial-merge fire site. After Outcome slot allocation + value/type/discriminant write + retrofit of arena/owner/creator at +0x70/+0x78/+0x68 from substrate state + registry, fires `babylon_charge_lineage(rdi=current_dispatch_cost, rsi=current_cap_id)`.

**Pod 3.6 synthesis ops inherit verbatim** — same single-fire by construction (D3.9 axiom), same babylon ripple shape (D3.23 axiom).

Phase 1.2–3.1 synthesis op handlers do NOT call `babylon_charge_lineage` directly. Babylon participation is automatic via `.construct_ok_outcome` wrap. Same shape as Pod 3.5 compute ops (B23 empirical anchor).

**Predicted ripple per synthesis op:** cost-table entry at op's opcode (e.g., 500j for ADD) becomes `current_dispatch_cost`; `.construct_ok_outcome` fires `babylon_charge_lineage(500, current_cap_id)`. Under sub-cap A with parent ROOT: A.used unchanged (originating cap doesn't accumulate own cost), ROOT.used += floor(500/2) = 250j per ADD.

(R8 verification surface: B41 babylon_ripple_synthesis canary at Phase 3.2.)

---

## R9 — BIT_EMBEDDING_FORGE inheritance

`BIT_EMBEDDING_FORGE = (1 << 4) = 0x10` declared in `defines.asm:221`; consumed at `OP_EMBEDDING_NEW` dispatch site (`cbs_vm.asm:2172-2177`) via `babylon_check_authority(rdi=BIT_EMBEDDING_FORGE, rsi=current_cap_id)` → rax=0(ok)/1(fail).

**Pod 3.6 synthesis ops (0xCA–0xCE) inherit the same gate.** Each handler's first action: bit-check via `babylon_check_authority(BIT_EMBEDDING_FORGE, current_cap_id)` → branch to `.op_embedding_<name>_insufficient_authority` on fail. **No new authority bit needed.**

**Synthesis-handle accessor (0xCF) bypasses the gate** per D3.13 witness doctrine — accessor reads existing substrate state without state mutation; no forge bit required. The witness/forge boundary lives interior to Pod 3.6. (See Surprise 4.)

(B40 forge_authority_required canary at Phase 3.2 verifies inheritance.)

---

## R10 — Canonical f32 evaluation order per op (LOAD-BEARING — A6 surface for each op)

D3.14 precedent: bit-exact deterministic evaluation order is doctrine. Each Pod 3.6 op's canonical form documented; bit-exact f32 simulation via Python `struct.pack('<f', ...)` against the form lands at HALT 1 R10 for each op. Simulation harness at `tools/pod36_r10_sim.py`.

### ADD canonical form
```
result[i] = a[i] + b[i]    for i in 0..384
```
Single per-element `addss`; no reduction; no sqrt. Bit-exact deterministic by construction.

**B25** add(e_unit_x, e_unit_y) → `result[0]=0x3F800000`, `result[1]=0x3F800000`, `result[2..383]=0x00000000` ✓
**B26** add(a, zero_vec) → `result[i] == a[i]` byte-exact (∵ `addss(x, 0.0) = x` for finite x) ✓

### SUBTRACT canonical form
```
result[i] = a[i] - b[i]    for i in 0..384
```
Same shape as ADD with `subss`. Bit-exact deterministic.

**B27** sub(e_unit_x, e_unit_y) → `result[0]=0x3F800000`, `result[1]=0xBF800000`, `result[2..383]=0` ✓
**B28** sub(a, a) → `result[i] = 0` byte-exact (`subss(x, x) = 0.0` for finite non-NaN x) ✓

### SCALE canonical form
```
result[i] = scalar * a[i]    for i in 0..384
```
Per-element `mulss` with broadcast scalar. Scalar loaded once into xmm register, then per-element `movss xmm1, [a+i*4] / mulss xmm1, xmm_scalar / movss [result+i*4], xmm1`.

**B29** scale(2.0, e_unit_x) → `result[0]=0x40000000`, `result[1..383]=0` ✓
**B30** scale(0.0, a) → `result[i]=0` byte-exact ✓
**B31** scale(-1.0, a) → `result[i]=-a[i]` byte-exact (negation) ✓

### NORMALIZE canonical form (Form A; D3.14 precedent)
```
1. norm_sq = sum_i a[i] * a[i]                  (384 mulss + 383 addss accumulation)
2. if norm_sq == 0.0f → CF=1 zero-norm rejection (mirrors compute_cosine_raw)
3. norm = sqrtss(norm_sq)
4. result[i] = a[i] / norm                      for i in 0..384
```

**Form A chosen over Form B** (`inv_norm = 1.0 / sqrtss(norm_sq); result[i] = a[i] * inv_norm`):
- Per-element `divss` vs per-element `mulss`-by-reciprocal: in single-precision f32, `a[i] / norm` and `a[i] * (1.0 / norm)` produce different bit patterns when `1.0 / norm` is itself a non-exact f32 representation. Per-element `divss` is fewer rounding events.
- D3.12 whitelist alignment: `rsqrtss` (reciprocal-square-root) is FORBIDDEN per D3.12 (SSE approximation, not bit-exact deterministic across CPUs). Form B with explicit `1.0 / sqrtss()` works but adds an extra `divss` without compensating accuracy benefit.

**B32** normalize(scale(2.0, e_unit_x)) → `norm_sq=0x40800000` (= 4.0), `norm=0x40000000` (= 2.0), `result[0]=0x3F800000` (= 1.0), `result[1..383]=0` ✓
**B33** normalize(zero_vector) → CF=1 zero-norm rejection routes handler to `.op_embedding_normalize_zero_norm` → Err(InvalidEmbeddingArg, src=0xCD, err_code=9) ✓

**v_uniform-class anti-pattern note** (mirror of Pod 3.5 Surprise 4 framing): vectors with all 384 elements at non-trivial value (e.g., `1/sqrt(384)` for a uniform unit vector) accumulate substantial drift through 384 sequential `addss` operations. Test surfaces should avoid v_uniform-class inputs for normalize bit-exactness assertions. Use `e_unit_*` and `scale(2.0, e_unit_*)` style sparse-non-trivial vectors instead. (See Surprise 5 — first A6 landing.)

### LERP canonical form (Form A; endpoint-byte-exactness alignment)
```
1. one_minus_t = 1.0 - t                              (single subss)
2. result[i] = (one_minus_t * a[i]) + (t * b[i])       for i in 0..384
                                                       (per element: 2 mulss + 1 addss)
```

**Form A chosen over Form B** (`a[i] + t * (b[i] - a[i])`) **and Form C** (`a[i] - t*a[i] + t*b[i]`) **for endpoint byte-exactness:**
- Form A at t=0.0: `(1.0 * a[i]) + (0.0 * b[i]) = a[i] + 0.0 = a[i]` byte-exact.
- Form A at t=1.0: `(0.0 * a[i]) + (1.0 * b[i]) = 0.0 + b[i] = b[i]` byte-exact.
- Form B at t=1.0: `a[i] + 1.0 * (b[i] - a[i]) = a[i] + b[i] - a[i]`. The `subss` followed by `addss` has cancellation drift; not byte-exact at endpoints.
- Form C: similar cancellation issues; rejected.

**B34** lerp(e_unit_x, e_unit_y, 0.5) → `result[0]=0x3F000000` (= 0.5), `result[1]=0x3F000000` (= 0.5), `result[2..383]=0` ✓
**B35** lerp(a, b, 0.0) → `result[i] == a[i]` byte-exact (Form A endpoint property) ✓
**B36** lerp(a, b, 1.0) → `result[i] == b[i]` byte-exact (Form A endpoint property) ✓

**Irrational-t drift surface note**: when `t` is not exactly representable in f32 (e.g., `t = 1/3`), `subss(1.0, t)` rounds to `f32(2/3) - 1 ulp`, producing **asymmetric drift** between `result[0]` and `result[1]` via the same algebraic value. (See Surprise 6 — second A6 landing.)

---

## R11 — B-canary set enumeration (21 canaries: 3 substrate-prep + 18 synthesis-tier)

**Phase 1.1 substrate-prep (3 entries, no compute):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B-prep-1 | Pod 3.5 B1-B24 re-execution at new BSS layout | D3.24 substrate-scaling | ALL PASS (semantic preservation) |
| B-prep-2 | BSS-dump probe `vm_embedding_synthesis[0..31]` after boot | BSS-zero default | 32 zero bytes |
| B-prep-3 | Two-build determinism on new BOOTX64.EFI sha256 | D3.12 inheritance | reproducible across builds |

**Phase 1.2 add (binary forge path proven; 2 entries):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B25 | add_basic | R10 / Layout 2 write | result[0..1]=0x3F800000, [2..]=0; tuple (op=0x01, source_a=1, source_b=2, scalar=0) |
| B26 | add_zero_vectors | R10 endpoint | result == a byte-exact |

**Phase 2.1 subtract (binary same shape; 2 entries):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B27 | subtract_basic | R10 | result[0]=0x3F800000, result[1]=0xBF800000, [2..]=0; tuple (op=0x02, ...) |
| B28 | subtract_self | R10 | zero vector byte-exact |

**Phase 2.2 scale + normalize (5 entries):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B29 | scale_basic | R10 / Layout 2 SCALE shape | result[0]=0x40000000; tuple (op=0x03, source_a=1, source_b=2.0_as_i64, scalar=0) |
| B30 | scale_by_zero | R10 | zero vector |
| B31 | scale_by_negative | R10 | -a byte-exact (negation) |
| B32 | normalize_basic | R10 NORMALIZE Form A | norm_sq=0x40800000, norm=0x40000000, result[0]=0x3F800000 |
| B33 | normalize_zero_vector_rejection | D3.14 / handler err path | Err(InvalidEmbeddingArg, src=0xCD, err=9) |

**Phase 3.1 lerp (3 entries):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B34 | lerp_basic | R10 LERP Form A | result[0..1]=0x3F000000, [2..]=0; tuple (op=0x05, source_a=1, source_b=2, scalar=0.5_as_i64) |
| B35 | lerp_t_zero | R10 endpoint | result == a byte-exact |
| B36 | lerp_t_one | R10 endpoint | result == b byte-exact |

**Phase 3.2 synthesis accessor + end-to-end (6 entries):**

| # | Name | Doctrine | Expected |
|---|---|---|---|
| B37 | synthesis_handle_round_trip | D3.20-generalized / D3.26 | tuple (op=0x01, source_a=1, source_b=2, scalar=0) recoverable |
| B38 | synthesis_handle_unsynthesized | BSS-zero default / D3.13 | tuple (op=0x00, 0, 0, 0) for Sign-forged or raw OP_EMBEDDING_NEW embedding |
| B39 | analogical_reasoning_demo | D3.13 + D3.20 + D3.26 end-to-end | (king − man) + woman → lookup_top1 → SIGN_HANDLE → SYNTHESIS_HANDLE recovers full lineage. **The Maid composes.** |
| B40 | forge_authority_required | R9 / D2.2 bit-check | cap without BIT_EMBEDDING_FORGE → Err(InsufficientAuthority, src=0xCA, ...) |
| B41 | babylon_ripple_synthesis | D3.23 / R8 | A.used=0, ROOT.used += floor(<final_cost>/2) |
| B42 | pool_capacity_synthesis_pressure | D3.16 ceiling | forge until 256-slot exhaustion → Err(PoolFull) |

(Architect prose count was "~18"; verbatim enumeration produces 21. Count corrected to 21 = 3 prep + 18 synthesis-tier.)

---

## R12 — Build chain confirmation

```
NASM version 2.16.01                                           ✓ matches Pod 3.5
mcopy (GNU mtools) 4.0.43                                      ✓ matches
QEMU emulator version 8.2.2 (Debian 1:8.2.2+ds-0ubuntu1.16)    ✓ matches
```

**Two-build determinism on Pod 3.5 entry contract:**
```
build1 sha256: a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad
build2 sha256: a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad
expected:      a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad
```

Both builds byte-identical to Pod 3.5 sealed contract. Build chain ready for Pod 3.6.

**Build-shell-determinism note** (DEFERRED #89 forward-anchor): the Git-Bash on Windows `$PATH` exposes a different NASM (3.01) than the WSL build shell (2.16.01). `build.sh` invokes `nasm` by name; running the build script from the wrong shell would silently use the wrong assembler. Not a Pod 3.6 concern (substrate develops in the WSL build shell), but DEFERRED-worthy as a "build-shell-determinism" hazard that could surface in future contributors' environments. Recommend a one-line `nasm --version` assertion in `build.sh`'s dependency-check block (line 33) to catch the drift at the moment it would matter.

---

## A-call surfaces with TB recommendations

### A1 — Opcode allocation 0xCA–0xCF unclaimed
**TB confirms:** clean. Architect priors (ADD=0xCA, SUBTRACT=0xCB, SCALE=0xCC, NORMALIZE=0xCD, LERP=0xCE, SYNTHESIS_HANDLE=0xCF) ratify.

### A2 — Layout 2 quad-tuple commitment at Phase 1.1
**TB ratifies.** Avoids mid-pod migration when ternary lerp lands at Phase 3.1. 8 bytes/slot × 256 slots = ~2KB additional vs Layout 1 (triple). One uniform write convention across all five synthesis ops; lerp uses scalar field, others zero it.

### A3 — Synthesis tuple field convention
**TB ratifies.** (op, source_a, source_b, scalar) at offsets 0/8/16/24. Per-op shapes per R6 table. SYNTHESIS_OP_NONE = 0x00 BSS-zero default codified.

### A4 — Forge sequence position for synthesis-tuple write
**TB ratifies.** Position post-siphash, pre-Outcome-wrap (between R4 step 9 and step 10) matches OP_SIGN_NEW reverse-write shape. Substrate-private bookkeeping at the same architectural moment.

### A5 — Cost-table placeholders
**TB recommends** accepting Phase 1.1 placeholders (500/500/500/700/800/1). Final values land at AUTHORIZED-2A (post-add-implementation empirical measurement) or AUTHORIZED-2B (post-canary-execution).

### A6 — Canonical f32 evaluation order per op (LOAD-BEARING)

**TB findings (per R10 simulation):**

| Op | Form choice | Endpoint behavior | A6 surface |
|---|---|---|---|
| ADD | trivial per-element `addss` | exact at zeros | none |
| SUBTRACT | trivial per-element `subss` | a − a = 0 byte-exact | none |
| SCALE | trivial per-element `mulss` | 0×a = 0, −1×a = −a byte-exact | none |
| NORMALIZE | Form A (sum_sq → sqrt → divss) | e_unit round-trips byte-exact | **v_uniform 25-ulp drift (Surprise 5)** |
| LERP | Form A ((1−t)a + tb) | t=0/t=1 byte-exact | **irrational-t asymmetric drift (Surprise 6)** |

**TB ratification recommendations:**

1. **Ratify all 12 primary B-canary bit patterns** at AUTHORIZED-1 — they match architect R10 prior byte-exact.
2. **Ratify NORMALIZE Form A** despite v_uniform 25-ulp drift. Drift is bit-exact deterministic, doctrine-aligned (D3.12 says "deterministic," not "algebraic-perfect"), and Form B (`a[i] * (1.0 / norm)`) wouldn't help — same 25-ulp norm_sq feeds the reciprocal, plus an extra divss-then-mulss chain. v_uniform-class inputs codified as **B-canary anti-pattern** for normalize bit-exact assertions (parallel to Pod 3.5 Surprise 4).
3. **Ratify LERP Form A** despite irrational-t asymmetric drift. Endpoints (B35/B36) byte-exact, clean-t-clean-vectors (B34) byte-exact, drift only at irrational t with one-sided source vectors. Form A's endpoint-byte-exactness is the load-bearing feature; asymmetric mid-t drift is its acceptable cost.
4. **D3.28 codifies the discipline.** (See decision-record draft below.)

### A7 — Pool capacity holds at 256 for Pod 3.6
**TB ratifies.** Synthesis ops produce new pool entries; ~250 forges before exhaustion. Growth to 1000+ deferred to Pod 3.7+ when production codebook scenarios become empirical (DEFERRED #83 partial-resolution forward-anchor).

### A8 — Trinity-naming canonization (D3.25)
**TB ratifies** the "as intended" canonical reading. Maid's surface includes both housekeeping (Pod 3.5 ops) and lexical computation including synthesis (Pod 3.6 ops). Future services (Cop, Interpreter) carry their own surfaces. The housekeeper-vs-computation tension resolved by canonical reading; the inclusive reading was always available.

### A9 — D3.20 generalization framing (recognition not invention)
**TB ratifies.** `vmdata.asm:81-87` comment block already enacts the convention; D3.26 names what canon was already saying. The substrate's pattern of self-understanding: conventions are in canon before doctrines name them. D3.26's text should soften from "generalizes" to "makes explicit"; the doctrine is recognition, not creation.

---

## Surprises

### Surprise 1 — The substrate was pre-shaped for the move

Cost-table at `boot/energy_costs.asm:144` row 0xCA–0xCF currently `dq 1, 1, 1, 1, 1, 1` with annotation "0xCA–0xCF reserved for Pod 3.5+ extensions." Six entries, exact one-to-one match with Phase 1.1's six-opcode allocation (ADD/SUBTRACT/SCALE/NORMALIZE/LERP/SYNTHESIS_HANDLE). The reservation predated this architectural sit.

BSS placement is similarly natural: `vmdata.asm` has a gap between `vm_embedding_sign_handle` (line 89) and the registry block (line 91+) where `vm_embedding_synthesis` lands organically. The structure was already shaped for this addition.

**Pacing pattern at canon-layout level**: Pod 3 prep → Pod 3.5 use → Pod 3.6 use-richer. Each pod leaves slots open for the next. This is not coincidence; this is the project's foresight discipline showing in the substrate's structure. Worth surfacing in Pod 3.6's decision record as architectural observation about the project's foresight.

### Surprise 2 — D3.20 generalization is recognition, not invention

`vmdata.asm:81-87` comment block: "Embedding reverse side-table (Pod 3.5 — D3.20; reverse of D3.4 forward direction)... Parallel BSS array indexed by (embedding_id - 1)... non-MAC parallel structure per substrate's 'trusts its own write paths' convention." The substrate's existing language for the pattern already enacts what D3.26's "non-MAC parallel linkage" generalization names.

**Substrate-philosophical anchor for Pod 3.6**: the conventions are in canon before the doctrines name them. D3.26's framing softens from "generalizes" to "makes explicit." The doctrine is recognition, not creation. This is a recurring shape in the project — D3.6's "Reclaimed-slot via parallel BSS" was the prior precedent; D3.26 extends the same generalized recognition to synthesis lineage.

### Surprise 3 — Layout 2 commitment moves doctrine cost forward

Choosing Layout 2 quad-tuple at Phase 1.1 (rather than Layout 1 → Layout 2 mid-pod migration) means D3.27's tuple-shape doctrine lands at substrate-prep time, before any synthesis op executes. The doctrine canonizes the shape that NO op writes yet. This is unusual — most doctrines land at the implementation moment of the relevant feature.

**Why it matters**: Phase 3.1 (lerp) inherits the layout without migration; Phase 1.2-2.2 forge ops write the layout from day one with scalar=0. One write convention through the entire pod. The cost of "doctrine before use" is paid once, upstream; it eliminates the alternative cost of "two write conventions in one pod" entirely.

### Surprise 4 — Witness/forge boundary interior to synthesis

The synthesis-handle accessor (0xCF, OP_EMBEDDING_SYNTHESIS_HANDLE) is a witness op (D3.13) — reads existing substrate state without forge bit. The five synthesis ops (0xCA–0xCE) are forge ops — gate on BIT_EMBEDDING_FORGE.

The boundary lives interior to Pod 3.6. **Synthesis lineage is forge-written and witness-read.** The pod itself spans both sides of the witness/forge axis the architectural sit decided to cross. Worth surfacing in D3.25's framing — "Maid as lexical-computation pole" includes both the witness side (Pod 3.5 ops + 0xCF) and the forge side (0xCA–0xCE).

### Surprise 5 — normalize(v_uniform) accumulator drift (first A6 landing for Pod 3.6)

**A6 surface mechanism** — 384 sequential `addss(norm_sq, mulss(a[i], a[i]))` accumulations of `(1/sqrt(384))^2` compound their per-step rounding. Empirical f32 simulation:

- `v_uniform[i] = f32(1/sqrt(384)) = 0x3D5105EC`
- `norm_sq` after 384 sequential `addss`: **`0x3F800019`** (NOT algebraic 1.0 = 0x3F800000) — drift **+25 ulp**
- `norm = sqrtss(0x3F800019) = 0x3F80000C` — **+12 ulp** from algebraic 1.0
- `result[0] = divss(0x3D5105EC, 0x3F80000C) = 0x3D5105D8` — drift **−20 ulp** from input bit pattern
- **All 384 elements drift** from the input pattern.

This is materially larger than Pod 3.5's 1-ulp `cosine_45_degree` drift (which compounded only through `(1/sqrt(2))^2` doubled and the resulting denominator). Pod 3.6's normalize compounds through 384 elements; the drift magnitude tracks accumulator depth.

**Doctrine-load-bearing**: confirms why D3.12 matters for *deterministic* (not algebraic-perfect) reproducibility. Bit-exact across builds is what D3.12 promises; algebraic perfection is not in the contract. Programs needing exact 1.0 for normalized-vector identity comparisons should compare embedding_ids directly, not rely on `norm == 1.0` bit-pattern matching.

**Test-surface implication**: `v_uniform`-class inputs (all 384 dims at non-trivial value) are codified as **B-canary anti-pattern** for normalize bit-exact assertions. Use sparse-non-trivial inputs (e_unit_*, scale(2.0, e_unit_*), …) for primary B-set coverage. Mirrors Pod 3.5 Surprise 4 framing for cosine v_uniform.

### Surprise 6 — lerp irrational-t asymmetric traversal (second A6 landing for Pod 3.6)

**A6 surface mechanism** — when `t` is not exactly representable in f32, `subss(1.0, t)` rounds to a slightly-off `one_minus_t`, and the asymmetry in Form A's two-mulss-then-addss order produces different bit patterns for algebraically-equal values:

```
lerp(e_unit_x, scale(2.0, e_unit_y), t=1/3):
  one_minus_t = subss(1.0, f32(1/3)) = 0x3F2AAAAA  (= f32(2/3) − 1 ulp)
  result[0]   = mulss(0x3F2AAAAA, 1.0) + mulss(0x3F2AAAAB, 0.0)
              = 0x3F2AAAAA + 0x00000000
              = 0x3F2AAAAA              (drift −1 ulp from algebraic 2/3 = 0x3F2AAAAB)
  result[1]   = mulss(0x3F2AAAAA, 0.0) + mulss(0x3F2AAAAB, 2.0)
              = 0x00000000 + 0x3F2AAAAB
              = 0x3F2AAAAB              (byte-exact at algebraic 2/3)
```

**Same algebraic value, different bit patterns** depending on which side of the lerp the lossy multiplier traversed. The asymmetry is bit-exact deterministic and reproducible.

Counter-check: lerp((3,0,…), (1,0,…), 0.5) → result[0] = 0x40000000 = 2.0 byte-exact. **Mid-t with cleanly-representable vectors and clean t doesn't drift**; only irrational t with one-side-zero values does. Drift surface is narrow but real.

**Test-surface implication**: B-canaries B34/B35/B36 use clean t values (0.0, 0.5, 1.0) and clean source vectors; drift surface doesn't intersect. Future codebook scenarios using arbitrary t-values inherit the form's asymmetric drift; programs needing algebraic-form-invariance should compute the lerp twice (a/b swapped, t → 1−t) and compare. Doctrine-aligned with Form A's endpoint-byte-exactness as the load-bearing feature.

---

## D3.28 — The project learns how to learn from its FP frontier

**Cross-cutting summary doctrine entry; future pods cite D3.28 rather than re-recording the FP-precision-prediction landings.**

**Empirical landings catalog** (FP-precision-prediction subtype within architect-error doctrine family):

1. **Pod 3.5 D3.11 / Surprise 1** — `cosine(v_e0, v_45deg)` 1-ulp drift (`0x3F3504F3` → `0x3F3504F4`) via `(1/sqrt(2))^2` rounding through Form A norm_sq accumulation. Tenth landing of architect-error doctrine; first FP-precision-prediction landing in the project.

2. **Pod 3.6 / Surprise 5** — `normalize(v_uniform)` 25-ulp norm_sq drift (`0x3F800000` → `0x3F800019`) via 384 sequential `addss` accumulations of `(1/sqrt(384))^2`. **First FP-precision-prediction landing where drift magnitude exceeds 1 ulp.** Mechanism: per-step rounding compounds with accumulator depth.

3. **Pod 3.6 / Surprise 6** — `lerp(a, b, irrational-t)` asymmetric traversal drift, where Form A produces different bit patterns for algebraically-equal `result[i]` and `result[j]` because `subss(1.0, t)` rounds and the multiplication chain differs by source vector value. **First FP-precision-prediction landing showing form-traversal asymmetry rather than monotone accumulator drift.**

**Doctrine canonized**:

- **Algebraic priors are starting hypotheses; bit-exact f32 simulation is canonical.** Architect-side priors that derive from algebraic math should be treated as approximations subject to verification.
- **Drift magnitude tracks accumulator depth and operation count**, not just operation count alone. Single-step ops (ADD, SUBTRACT, SCALE) have zero drift surface against algebraic priors. Reduction ops (cosine, normalize) have drift magnitudes proportional to vector length. Form-traversal ops (lerp at irrational t) have asymmetric drift surfaces depending on input symmetry.
- **Bit-exact deterministic across builds is what D3.12 promises; algebraic perfection is not in the contract.** Programs needing exact equality for identity comparisons should compare canonical IDs (embedding_id), not rely on FP bit-patterns matching.
- **Test surfaces should select inputs that intersect or avoid drift surfaces deliberately.** Sparse-non-trivial vectors (e_unit_*, scale(2.0, e_unit_*)) for primary correctness coverage; v_uniform-class inputs explicitly codified as B-canary anti-pattern for bit-exact normalize/cosine assertions.
- **The project learns how to learn from its FP frontier.** Each new FP op surfaces its own precision-prediction landing at recon time; the discipline is to simulate-before-asserting, ratify the bit-exact result as canon, and codify the input-class anti-pattern when one emerges.

**Future-pod inheritance pattern**: any FP op introduced post-Pod-3.6 (lerp variants, dot-product extensions, codebook ingestion arithmetic, …) follows D3.28's discipline by construction. TB simulates bit-exact behavior at HALT 1 R10; architect ratifies bit patterns; landings against algebraic priors get codified as additional Surprise-N entries with mechanism explanations; B-canary anti-patterns get codified for the input classes that surface drift.

D3.28 is **substrate self-understanding** — the project's stance toward its own FP frontier, named explicitly. The doctrine is not just an empirical pattern; it's the discipline by which the project's substrate evolves while preserving the determinism contract.

---

## DEFERRED #89 — Build-shell-determinism hazard

**New deferral logged at Pod 3.6 recon.**

**Surface**: `build.sh:33` invokes `nasm` by name in the dependency-check block. The Git-Bash-on-Windows `$PATH` exposes a different NASM (3.01 in the harness host) than the WSL build shell where the substrate's two-build determinism guarantee lives (NASM 2.16.01). Running `./build.sh` from the wrong shell would silently use the wrong assembler and produce a different sha256 from the canonical sealed contract.

**Impact**: low for current contributors (substrate develops in WSL build shell exclusively). Latent for future contributors who clone the repo and try to build from Windows shells.

**Mitigation** (DEFERRED candidate): one-line `nasm --version` assertion in `build.sh`'s dependency-check block (line 33), checking for "NASM version 2.16.01" exact-match-and-fail. Keeps the guarantee enforceable at the moment it would matter.

**Logged-not-resolved**: Pod 3.6 doesn't fix the substrate-build script; the deferral pattern matches DEFERRED #84 (test-script housekeeping) — substrate cleanup work that doesn't block synthesis-tier development.

---

## HALT 1 conclusion

**Load-bearing items for AUTHORIZED-1 adjudication:**

1. **A1–A4 architect priors** — opcode allocation, Layout 2 commitment, tuple field convention, forge-sequence write position. TB confirms / ratifies all four.
2. **A6 canonical f32 forms** (LOAD-BEARING) — five forms; ADD/SUBTRACT/SCALE trivial; NORMALIZE Form A vs B; LERP Form A vs B vs C. TB simulates bit-exact f32 patterns for all R10 test vectors; **12/12 primary canary patterns match architect prior**; **two A6 landings surfaced** (normalize_v_uniform 25-ulp; lerp irrational-t asymmetric).
3. **A6 ratification recommendations** — ratify all 12 primary patterns; ratify NORMALIZE Form A with v_uniform-class anti-pattern note; ratify LERP Form A with irrational-t drift surface note; codify D3.28 as cross-cutting doctrine.
4. **A8 Trinity-naming canonization** — D3.25 frames Maid as lexical-computation pole including synthesis. Resolves the housekeeper-vs-computation tension by canonical reading.
5. **A9 D3.20 generalization framing** — recognition not invention. D3.26 names what `vmdata.asm:81-87` comment block already enacts.

**Other A-calls** (A5, A7) accept Phase 1.1 placeholders / 256-slot ceiling carryover.

**Substrate state at HALT 1**: Pod 3.5 sealed at `a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad`; build chain deterministic via WSL (NASM 2.16.01 / mtools 4.0.43 / QEMU 8.2.2); 0xCA–0xCF cost-table row pre-reserved for Pod 3.6 (D3.21 row 0xC0–0xCF six-slot remainder); BSS gap between `vmdata.asm:89` and `:91` awaiting `vm_embedding_synthesis`; `BIT_EMBEDDING_FORGE` existing gate inherited; `.construct_ok_outcome` / `babylon_charge_lineage` existing infrastructure inherited.

**Catch-rate prediction for Pod 3.6**: 3–5 architect-error landings expected, given substrate-USE + substrate-EVOLUTION simultaneity. **Two already at HALT 1 R10** (Surprises 5 and 6 = both FP-precision-prediction subtype, fourteenth and fifteenth landings of architect-error doctrine family). Likely additional subtypes still ahead:

- Synthesis-tuple write timing relative to `.construct_ok_outcome`'s internal register clobber (potential precondition for handler write order; mirror of Pod 3.5's siphash-r9-clobber-precedes-reverse-write requirement).
- Witness/forge boundary subtlety on accessor 0xCF (reads forge-written tuples without forge bit; axiom-inheritance gap possible).
- Possible canon-doc-stale variant if any Phase 1.1 constant is hardcoded somewhere TB recon doesn't trace (mirror of Pod 3.5's thirteenth landing on r14-init paths).

The discipline performs at every halt phase. Pod 3.5's elevated catch rate is the new baseline; Pod 3.6's first two catches at HALT 1 confirm the pattern.

**Awaiting AUTHORIZED-1 ratification.** On ratification: TB proceeds to Phase 1.1 — "The substrate readies."
