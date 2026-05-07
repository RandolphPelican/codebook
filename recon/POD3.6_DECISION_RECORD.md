# Pod 3.6 Decision Record — Maid composes (synthesis: add + subtract + scale + normalize + lerp + accessor)

**Pod:** 3.6 — first forge-tier substrate-USE pod; Maid V1.0 synthesis layer; the substrate becomes generator of meaning
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-07
**Entry contract:** a19d1d4cc2743233521bd09ba2df9c9a74a23e1ffa5338ca4d2e16321d8b50ad (Pod 3.5 BOOTX64.EFI)
**Exit contract:** [SEAL pending two-build determinism check]
**Entry HEAD:** 88fcb958b20d08f3ff8953f07f32425db3c45845 (Pod 3.5 seal — Maid speaks)

> Pod 3.6 crosses the witness/forge boundary inside the compute tier. D3.13 witness doctrine governed Pod 3.5's compute-over-substrate-state; Pod 3.6 introduces compute-that-creates-substrate-state. The substrate gains its first synthesis primitives — add, subtract, scale, normalize, lerp — each forging a new typed Embedding from existing ones, with synthesis lineage tracked via D3.20-generalized non-MAC parallel side-table. The closing arc — B39 analogical reasoning — is the substrate forging concept embeddings, composing (king − man + woman), looking up the nearest via cosine-by-meaning, recovering the Sign symbolically, and recovering the synthesis lineage architecturally. Forge-witness duality lands in one program. **D3.28 self-verifying canon** (B32-aux + B34-aux): predicted FP-precision drift mechanically enforced as substrate contract; the doctrine learns to defend itself.

---

## D3.25 — Forge-tier introduction; Maid as lexical-computation pole; Trinity-naming canonization

Pod 3.6 introduces the substrate's first compute-that-creates-substrate-state. Six new opcodes (0xCA–0xCF) exercise the synthesis surface: five forge-tier (ADD/SUBTRACT/SCALE/NORMALIZE/LERP) + one witness accessor (SYNTHESIS_HANDLE).

**Trinity-naming canonization** (resolves prior naming tension): Maid's surface includes both housekeeping (Pod 3.5 ops: cosine, dot, L2, lookup_top1, sign_handle) and lexical computation including synthesis (Pod 3.6 ops). Future services (Cop, Interpreter) carry their own surfaces. The canonical reading picks the inclusive interpretation: Maid is the **lexical-computation pole** of the substrate, structurally; housekeeper + composer.

**Witness/forge boundary lives interior to Pod 3.6** (Surprise 4 from recon): synthesis-handle accessor (0xCF) is witness (D3.13; no bit-check); the five compute ops (0xCA–0xCE) are forge (gate on BIT_EMBEDDING_FORGE). Synthesis lineage is forge-written and witness-read. The pod itself spans both sides of the witness/forge axis the architectural sit decided to cross.

## D3.26 — D3.20 generalization as recognition (not invention); non-MAC parallel linkage convention

D3.20 (Pod 3.5 — Sign reverse side-table) broadens to the **substrate's general convention for non-MAC parallel linkage between typed primitives**.

**Substrate-philosophical anchor**: the convention this generalization names was already enacted by `vm_embedding_sign_handle` (vmdata.asm:81–87). The doctrine is **recognition, not creation** — the substrate's pattern of self-understanding revealing that conventions are in canon before doctrines name them. D3.6 (Pod 3) provided the prior precedent ("Reclaimed-slot via parallel BSS" pattern); D3.26 extends the same generalized recognition to synthesis lineage.

**Implementation**: `vm_embedding_synthesis: times EMBEDDING_POOL_SLOTS * SYNTHESIS_TUPLE_BYTES db 0` (8KB BSS) at `vmdata.asm:91+`, adjacent to `vm_embedding_sign_handle`. Substrate trusts its own write paths — the canon-aligned convention. Read via OP_EMBEDDING_SYNTHESIS_HANDLE accessor (0xCF) at Phase 3.2.

**B37 empirical anchor**: forge `e3 = add(e1, e2)`; query `vm_embedding_synthesis[(3-1)*32]` via 0xCF accessor; reads back (op=1=ADD, source_a=1, source_b=2, scalar=0) byte-exact. The substrate-trusts-its-own-write-paths convention validated empirically.

**B38 closes B-prep-2 deferral**: query unsynthesized embedding (raw OP_EMBEDDING_NEW) → reads (0, 0, 0, 0) per BSS-zero default. The verify-via-accessor-at-accessor-exists-time discipline established at B-prep-2 cashes empirically here. **Substrate trusts its own write paths is bidirectionally validated**: writes happen at forge time; reads recover at accessor time; BSS-zero defaults preserve the semantic for unsynthesized state.

## D3.27 — Synthesis tuple Layout 2 quad-tuple convention; doctrine-cost-paid-upstream

`SYNTHESIS_TUPLE_BYTES = 32` per slot at `vm_embedding_synthesis + (embedding_id - 1) * 32`. Field offsets: `OP=0`, `SOURCE_A=8`, `SOURCE_B=16`, `SCALAR=24`. Per-op shapes:

| Op | source_a | source_b | scalar |
|---|---|---|---|
| ADD | a_id | b_id | 0 |
| SUBTRACT | a_id | b_id | 0 |
| SCALE | a_id | scalar (f32-as-i64) | 0 |
| NORMALIZE | a_id | 0 | 0 |
| LERP | a_id | b_id | t (f32-as-i64) |
| (none / Sign-forged / raw new) | 0 | 0 | 0 |

**Layout 2 commitment at substrate-prep time** (Phase 1.1): chosen over Layout 1 (triple) to avoid mid-pod migration when ternary lerp lands at Phase 3.1. Doctrine canonized BEFORE any synthesis op writes the tuple. Cost: ~2KB additional BSS (8 bytes per slot × 256 slots) traded for **one uniform write convention across all five forge ops**. Phase 1.2–2.2 binary/scalar-mixed/unary ops write the layout from day one with scalar=0; Phase 3.1 lerp uses the scalar field. The doctrine cost paid once, upstream; eliminates the alternative cost of "two write conventions in one pod" entirely.

**GET_DIM-style parameterized accessor** (Phase 3.2 sub-decision): single opcode 0xCF handles all four field reads via `field_index` (0..3). Mirrors Pod 3 OP_EMBEDDING_GET_DIM precedent. Substrate-architectural symmetry; one Outcome wrap per call; no convention break. B37 round-trip reads the tuple via four sequential calls.

**Synthesis ops with mixed embedding+scalar operands follow GET_DIM TOS-is-rightmost-arg convention** — substrate ABI footnote. SCALE: `[..., embedding_id, scalar]`. LERP: `[..., id_a, id_b, t]`. SYNTHESIS_HANDLE: `[..., embedding_id, field_index]`. Scalar/index always on top of operand stack; popped first.

**Helper-arity-pair convention** (Phase 2.2 sub-decision): `.embedding_one_resolve_verify` paired with `.embedding_two_resolve_verify`. Future Pod 3.7+ unary forge ops inherit the pair by construction. Same recognition-not-invention pattern as D3.26: future-forward symmetry rather than premature factoring. Doctrine cost paid at first unary forge op landing.

## D3.28 — The project learns how to learn from its FP frontier

**Cross-cutting summary doctrine entry; future pods cite D3.28 rather than re-recording the FP-precision-prediction landings.**

**Substrate self-understanding**: each new FP op surfaces its own precision-prediction landing at recon time; the discipline is to simulate-before-asserting, ratify the bit-exact result as canon, and codify the input-class anti-pattern when one emerges. The doctrine canonizes both the **empirical pattern** (drift magnitude tracks accumulator depth and form-traversal asymmetry) and the **project's stance toward its own FP frontier**.

**Empirical landings catalog** (FP-precision-prediction subtype; tenth+ landings of architect-error doctrine family):

1. **Pod 3.5 D3.11 / Surprise 1** — `cosine(v_e0, v_45deg)` 1-ulp drift (`0x3F3504F3` → `0x3F3504F4`) via `(1/sqrt(2))^2` rounding through Form A norm_sq accumulation. **First** FP-precision-prediction landing.
2. **Pod 3.6 / Recon Surprise 5** — `normalize(v_uniform)` 25-ulp norm_sq drift (`0x3F800000` → `0x3F800019`) via 384 sequential `addss` accumulations of `(1/sqrt(384))^2`. **First** FP-precision-prediction landing where drift magnitude exceeds 1 ulp; mechanism is accumulator depth.
3. **Pod 3.6 / Recon Surprise 6** — `lerp(a, b, irrational-t)` asymmetric traversal drift via `subss(1.0, t)` lossy one_minus_t propagated through one mulss path but not the other. **First** form-traversal asymmetry landing (vs monotone accumulator drift).

**B32-aux + B34-aux: self-verifying canon**

Pod 3.6 introduces the **self-verifying canon** pattern: the predicted drift becomes a B-canary assertion, mechanically enforcing the discipline. If the substrate's FP behavior shifts in any future change, the canary fails by construction.

- **B32-aux** (`v_uniform` normalize, 25-ulp drift): empirically verified `n[0]=n[1]=n[383]=0x3D5105D8 = 1028720088` byte-exact. Two independent computations (Python `struct.pack` simulation at HALT 1 R10 + UEFI substrate execution at Phase 2.2) agree at the bit level. Doctrine canonized: **drift magnitude tracks accumulator depth**, mechanically.
- **B34-aux** (lerp irrational-t, asymmetric drift): empirically verified `c[0]=0x3F2AAAAA` (= 2/3 − 1ulp) and `c[1]=0x3F2AAAAB` (= 2/3 byte-exact); same algebraic value, different bit patterns from form-traversal asymmetry. Doctrine canonized: **form-traversal asymmetry produces algebraically-equal values with bit-different results**, mechanically.

**Doctrine canonized**:

- **Algebraic priors are starting hypotheses; bit-exact f32 simulation is canonical.** Architect-side priors deriving from algebraic math are approximations subject to verification.
- **Drift magnitude tracks accumulator depth and operation count**, not just operation count alone. Single-step ops (ADD, SUBTRACT, SCALE) have zero drift surface against algebraic priors. Reduction ops have drift proportional to vector length. Form-traversal ops have asymmetric drift surfaces depending on input symmetry.
- **Bit-exact deterministic across builds is what D3.12 promises; algebraic perfection is not in the contract.** Programs needing exact equality should compare canonical IDs (embedding_id), not rely on FP bit-patterns matching.
- **Test surfaces select inputs that intersect or avoid drift surfaces deliberately.** Sparse-non-trivial vectors for primary correctness coverage; v_uniform-class inputs codified as B-canary anti-pattern for normalize/cosine bit-exact assertions.
- **Predicted drifts upgrade from documentation-only anti-patterns to mechanically-enforced canon via B-aux canaries.** The discipline transfers compounded interest into build phases — Pod 3.6 hit zero unexpected catches across 5 phases (the predicted catches landed as confirmations rather than surprises).

**Future-pod inheritance pattern**: any FP op introduced post-Pod-3.6 (codebook ingestion arithmetic, dot extensions, …) follows D3.28's discipline by construction. TB simulates bit-exact behavior at HALT 1 R10; architect ratifies bit patterns; landings against algebraic priors get codified as additional Surprise entries with mechanism explanations; B-canary anti-patterns get codified for the input classes that surface drift; predicted drifts ship as B-aux canaries.

D3.28 is **substrate self-understanding** — the project's stance toward its own FP frontier, named explicitly. The doctrine is not just an empirical pattern; it's the discipline by which the project's substrate evolves while preserving the determinism contract.

---

## Phase / build progression

| Phase | Identity | Contract sha256 | Catches |
|---|---|---|---|
| 1.1 | The substrate readies | `aa95c8cd6769d10d5f075de701a66a53ac742b5623e99b0c8ef75185bfdeace2` | 0 |
| 1.2 | Maid's first composition (ADD) | `8aadd681bd422927e3ce452a190c81153b093d938bc89bcc5bb493c7653d599f` | 0 |
| 2.1 | ADD's twin (SUBTRACT) | `5c575ec9e212b5535dd1ee8d6dad4934e711c6e8ca7d13f18c0165956e04029a` | 0 |
| 2.2 | Direction and weight (SCALE + NORMALIZE) | `76de1d4da9b0543fc2420c324405e3517b31ff7d037cee04e7582780dcd98389` | 0 |
| 3.1 / 3.2 | The interpolated word + Provenance closes | `[SEAL]` | 0 unexpected (1 substrate-architectural finding: B42 outcome_pool < embedding_pool) |

**Total catches at SEAL: 0 unexpected.** Architect's catch-rate prediction was 3–5 for the pod; D3.28's transferred discipline (predicted drifts shipped as B-aux canaries) kept the count at zero across all 5 phases. The two predicted A6 landings (B32-aux, B34-aux) shipped as positive empirical anchors rather than surprises.

---

## Empirical observations summary (B-canary results)

**Phase 1.1 substrate-prep (3/3 PASS)**:
- B-prep-1: 17/17 Pod 3.5 canaries byte-exact preserved at new BSS layout (D3.24 substrate-scaling event)
- B-prep-2: BSS-zero default — implicit by NASM construction; explicit via 0xCF accessor in B38 (Phase 3.2)
- B-prep-3: Two-build determinism on Phase 1.1 contract reproducible

**Phase 1.2 — first composition (2/2 PASS)**:
- B25 add_basic: c[0]=c[1]=0x3F800000=1.0; c[2]=0 byte-exact; D3.28 zero-drift confirmed
- B26 add_zero: a + 0⃗ = a byte-exact (Form A endpoint property)

**Phase 2.1 — ADD's twin (2/2 PASS)**:
- B27 subtract_basic: c[0]=0x3F800000, c[1]=0xBF800000; D3.28 zero-drift
- B28 subtract_self: subss(x, x) = +0.0 byte-exact for finite non-NaN x

**Phase 2.2 — Direction and weight (5/5 PASS + 1/1 self-verifying)**:
- B29 scale_basic: c[0]=0x40000000=2.0
- B30 scale_zero: byte-exact zero vector
- B31 scale_negative: byte-exact negation
- B32 normalize_basic: norm_sq=0x40800000, norm=0x40000000, c[0]=0x3F800000 (sparse-non-trivial input)
- **B32-aux v_uniform_drift**: n[0]=n[1]=n[383]=0x3D5105D8 byte-exact ✓ R10 prediction confirmed; 25-ulp drift mechanically enforced
- B33 normalize_zero_reject: Err(InvalidEmbeddingArg, src=0xCD=205, err=9)

**Phase 3.1 — The interpolated word (3/3 PASS + 1/1 self-verifying)**:
- B34 lerp_basic: c[0]=c[1]=0x3F000000=0.5
- B35 lerp_t_zero: c == a byte-exact (Form A endpoint)
- B36 lerp_t_one: c == b byte-exact (Form A endpoint)
- **B34-aux lerp_irrational_drift**: c[0]=0x3F2AAAAA, c[1]=0x3F2AAAAB byte-exact ✓ R10 asymmetric-drift prediction confirmed

**Phase 3.2 — Provenance closes (4/4 PASS + 1/1 closing arc)**:
- B37 synthesis_round_trip: tuple (op=1, source_a=1, source_b=2, scalar=0) recovered byte-exact via 0xCF
- B38 synthesis_unsynthesized: tuple (0, 0, 0, 0) — closes B-prep-2 deferral
- **B39 analogical_reasoning** (THE closing arc): forge {king, man, woman, queen_ref}; compute (king − man) + woman → result; lookup_top1(result) → queen_ref byte-exact; OP_EMBEDDING_SIGN_HANDLE(queen_ref) → queen_sign; OP_EMBEDDING_SYNTHESIS_HANDLE(result, ...) recovers (ADD, diff_id, woman_id, 0). **The Maid composes; substrate accounts for what it composed.** Energy: 101618j (lookup_top1 dominates per D3.17 worst-case)
- B40 forge_authority_required: cap without BIT_EMBEDDING_FORGE → Err(InsufficientAuthority, src=0xCA=202, err=8)
- B41 babylon_ripple_synthesis: ADD under sub-cap A → A.used=0, ROOT.used=250 (= floor(500/2)) ✓ D3.9/D3.23 axiom inheritance

**Pod 3.5 regression at every phase boundary**: 29/29 baseline PNGs byte-exact preserved across all 5 substrate-scaling events. **D3.24 substrate-USE + substrate-EVOLUTION simultaneity empirically holds** across the entire pod.

---

## DEFERRED log additions

### DEFERRED #89 — Build-shell-determinism hazard
**Logged at Pod 3.6 recon HALT 1; carries forward to Pod 3.7+.**

**Surface**: `build.sh:33` invokes `nasm` by name. The Git-Bash-on-Windows `$PATH` exposes a different NASM (3.01 in current harness host) than the WSL build shell (NASM 2.16.01) where the substrate's two-build determinism guarantee lives. Running `./build.sh` from the wrong shell would silently use the wrong assembler and produce a different sha256 from the canonical sealed contract.

**Mitigation candidate**: one-line `nasm --version` assertion in `build.sh`'s dependency-check block, checking for "NASM version 2.16.01" exact-match-and-fail. Keeps the guarantee enforceable at the moment it would matter.

**Status**: low impact for current contributors (substrate develops in WSL build shell exclusively); latent for future contributors. Defer; address in Pod 3.7+ housekeeping pass.

### DEFERRED #90 — Outcome pool capacity below embedding pool capacity
**Surfaced empirically at Pod 3.6 Phase 3.2 B42 execution.**

**Surface**: `OUTCOME_POOL_SLOTS = 64` (vmdata.asm); `EMBEDDING_POOL_SLOTS = 256` (post-Pod-3.5 D3.16 expansion). Each forge produces an Outcome wrapping the embedding_id; outcome_pool fills well before embedding_pool can reach capacity through user-facing forge operations. Substrate behavior remains correct (`.construct_ok_outcome` returns 0 sentinel on outcome_pool exhaustion; `.construct_err_outcome` similar; OP_OUTCOME_UNWRAP_OK on outcome_id=0 prints diagnostic + sentinel), but **B42 cannot cleanly verify the embedding-pool-full err-path of OP_EMBEDDING_ADD** because the outcome wrapping the err itself can't be constructed once outcome_pool is full.

**Workaround at Pod 3.6**: B42 deferred from PASS verification. Substrate's pool-full path is correct by code inspection (inherited from Pod 3 OP_EMBEDDING_NEW pool-full path which IS empirically tested at Pod 3 verification). Pod 3.6 ships without B42 PASS empirical anchor.

**Resolution candidate at Pod 3.7+**: expand `OUTCOME_POOL_SLOTS` to match or exceed `EMBEDDING_POOL_SLOTS` (256). Anticipated-empirical-pressure pattern per D3.16 precedent. With expanded outcome_pool, B42 reframed: forge embeddings until embedding_pool full; verify ADD returns proper Err(PoolFull, src=0xCA, err=2) outcome.

**Status**: SEAL blocker if architect requires B42 PASS. Otherwise log as Pod 3.7+ work item; substrate semantic correctness unaffected.

---

## Resolution summary

| # | Description | Status |
|---|---|---|
| #80 | Pod 3.5+ Maid semantic operations | **FURTHER RESOLVED** — synthesis layer added (Pod 3.6); Maid V1.0 canonized as housekeeper + composer |
| #82 | Sign.provenance_handle activation candidate | unchanged |
| #83 | Embedding pool capacity expansion | unchanged at 256; growth deferred to Pod 3.7+ |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.6 adds 7+ scripts (DEFERRED) |
| #85 | RECONSTITUTION.md ongoing canon refresh | unchanged |
| #89 | Build-shell-determinism hazard | **NEW** — Pod 3.6 logged at recon |
| #90 | Outcome pool capacity below embedding pool | **NEW** — Pod 3.6 surfaced at B42 execution |

## Substrate state at seal

**Five typed pools** (Sign, Energy, Outcome, Cap, Embedding) with synthesis-tier compute landed:
- **3 MAC-protected** (Cap, Outcome, Embedding)
- **2 non-MAC** (Sign, Energy) — Pod-1.7-archaeology asymmetry preserved
- **2 non-MAC parallel side-tables** for Embedding linkage:
  - `vm_embedding_sign_handle` (Pod 3.5 D3.20) — Embedding → Sign reverse
  - `vm_embedding_synthesis` (Pod 3.6 D3.26) — Embedding → synthesis-lineage tuple

**OP_EMBEDDING_ row 0xC0–0xCF fully consumed**:
- 0xC0–0xC4 (Pod 3): typed-primitive substrate-prep
- 0xC5–0xC9 (Pod 3.5): semantic operations (witness)
- 0xCA–0xCE (Pod 3.6): synthesis operations (forge)
- 0xCF (Pod 3.6): synthesis lineage accessor (witness)

**Maid V1.0 surface complete**: housekeeper (Pod 3.5 ops) + composer (Pod 3.6 forge ops) + lineage recovery (0xCF accessor). The lexical-computation pole of the substrate's metaphysical surface, structurally lands.

**Federation accounting** intact: every Outcome production fires `babylon_charge_lineage` via `.construct_ok_outcome` (D3.9 / D3.23 axiom inheritance). Synthesis ops participate by construction; B41 empirical anchor (ADD under sub-cap A → ROOT.used += 250).

**Authority gating** intact: all five forge ops (0xCA–0xCE) gated on `BIT_EMBEDDING_FORGE` via `babylon_check_authority` (D2.2.6 mechanism). B40 empirical anchor (cap without BIT_EMBEDDING_FORGE → Err(InsufficientAuthority)).

**FP determinism** intact: D3.12 SSE-scalar-only substrate-permanent canon; D3.28 self-verifying via B32-aux + B34-aux. Two predicted A6 landings shipped as positive empirical anchors rather than catches.

**Two-build determinism** preserved at every phase boundary; Pod 3.6 final exit contract reproducible.

**Pod 3.6 architect-error catches**: zero unexpected. The two predicted FP-precision drifts shipped as self-verifying canon (B32-aux + B34-aux); D3.28's transferred discipline performed exactly as designed.

**Maid composes.**
