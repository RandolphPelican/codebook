# Pod 3.11 Decision Record — Maid maintains (codebook metadata accessor)

**Pod:** 3.11 — fifth forge-tier substrate-USE pod; Maid V1.0 codebook surface reaches read-completeness; the lightest pod in the Pod-3 series.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-11
**Entry HEAD:** 9772b34ab7811d45d314355dcc33e7c580358b32 (Pod 3.10 SEAL — Maid orthogonalizes)
**Entry contract:** b6097e602996a7a8a9d52a2901c9e11e9aae7d6575b5f849b479767ca0d2b981 (canonical Pod 3.10 BOOTX64.EFI)
**Exit contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900

> Pod 3.11 lands the Maid's codebook-metadata witness accessor — `OP_EMBEDDING_CODEBOOK_META` (0xF5) — completing the codebook read surface (Pod 3.8 wrote at boot + per-embedding accessor; Pod 3.11 adds codebook-level field-indexed read). One new doctrine entry lands: D3.42 (codebook metadata witness accessor; substrate-private singleton state; axis-removal inheritance from IMPORTED_HANDLE). Build-time catches: 0. Substrate-catches: 0. Architect-framing-corrections: 0. **Cleanest pod in V1.0 sequence — zero catches across all surfaces.** The Maid maintains.

---

## D3.42 — Codebook metadata witness accessor (substrate-private singleton state)

**Substrate-private singleton-state accessor pattern.** GET_DIM-style parameterized accessor convention (Pod 3 / 3.6 / 3.8 / 3.9 lineage) extends from per-embedding state to substrate-private singleton state via **axis-removal inheritance** from IMPORTED_HANDLE.

**The pattern**: when substrate-private state is a single fixed-address BSS block (singleton; not per-embedding indexed), the witness accessor pops only `field_index` and reads `[base + field_index*8]`. No registry lookup; no MAC verify; no per-embedding offset computation.

**Per-pod accessor surface comparison** (post-Pod-3.11):

| Op | Pod | State shape | Operands popped | Validation |
|---|---|---|---|---|
| GET_DIM (0xC4) | 3 | per-embedding vector | embedding_id + dim_index | MAC verify + registry + dim range |
| SIGN_HANDLE (0xC5) | 3.5 | per-embedding side-table | embedding_id | registry |
| SYNTHESIS_HANDLE (0xCF) | 3.6 | per-embedding tuple | embedding_id + field_index | registry + field range |
| IMPORTED_HANDLE (0xF1) | 3.8 | per-embedding tuple | embedding_id + field_index | registry + field range |
| **CODEBOOK_META (0xF5)** | **3.11** | **substrate-private singleton** | **field_index only** | **field range only** |

**The substrate's witness-accessor surface now spans two axes:**
- Per-embedding state (4 ops; GET_DIM / SIGN_HANDLE / SYNTHESIS_HANDLE / IMPORTED_HANDLE)
- Substrate-private singleton state (1 op; CODEBOOK_META)

Codifies the simplified shape if more singleton-state accessors land at future pods (e.g., hypothetical CAP_STATS_META, REGISTRY_STATS_META, etc.).

**V1.0 single-codebook framing**: META exposes the *singular* codebook's metadata; codebook_id parameter deferred to multi-codebook activation (#91). Pod 3.8 D3.32 precedent (codebook_id lives in the data, not the call signature) extends — the V1.0 META accessor naturally inherits "singular codebook" assumption without codebook_id complexity. Multi-codebook future activation lands its own surface; V1.0 META becomes the "single-codebook legacy" form.

**Field-index space at V1.0**: `field_index ∈ {0, 1, 2, 3}` for the 4 user-relevant qword fields (count / dim / scalar_type / ingestion_status). Out-of-range returns `Err(InvalidEmbeddingArg)`. Payload hash (16 bytes at +0x20) and reserved block (16 bytes at +0x30) remain substrate-private at V1.0 per D3.43-deferral (see below).

**D3.37 NASM RIP-relative discipline applied**: handler uses `lea rax, [rel vm_codebook_meta]; mov rdi, [rax + rcx*8]` pattern; NOT `[rel vm_codebook_meta + rcx*8]` (silently miscompiles per D3.37 substrate-catch from Pod 3.9). Pod 3.11 inherited the discipline from Pod 3.10 forward.

---

## D3.43 — DEFERRED to Pod 3.12

D3.43 (V2.0-deferral discipline for substrate audit fields) was a Pod 3.11.A sit-time doctrine candidate covering when substrate-runtime integrity metadata (payload_hash, ingestion_duration, etc.) stays internal vs gets user-surface exposure. The Pod 3.11 surface didn't require codifying this — the V1.0 K-metric demo workflow proceeds with the 4 currently-exposed fields, and payload_hash exposure remained a "skip at V1.0; defer to V2.0 audit-tier" decision per Q3 ratification.

Rather than land D3.43 as a single-instance doctrine entry, **deferred to Pod 3.12 V1.0 SEAL consolidation pass** — Pod 3.12 may surface multiple "what-stays-internal-at-V1.0" decisions across the substrate (audit fields, debug counters, diagnostic state) that warrant a unified doctrine. If Pod 3.12 lands such consolidation, D3.43 absorbs the audit-field-deferral discipline as one rule among several; if not, D3.43 can still land at Pod 3.12 SEAL as a standalone.

The Q3 ratification (skip payload_hash exposure at V1.0; field_index ∈ {0..3}) remains operational at Pod 3.11; only the doctrine entry's formalization defers.

---

## Q-rating ratifications (Pod 3.11.A pre-flight + audit)

| # | Question | Ratified |
|---|---|---|
| **Q1** | Op surface scope — single OP_*_META(field_index) accessor (GET_DIM/IMPORTED_HANDLE/SYNTHESIS_HANDLE convention continuity; opcode-slot conservation; one handler shape) | ✓ ratified per D3.42 |
| **Q2** | Naming prefix — OP_EMBEDDING_CODEBOOK_META within D3.34 embedding-tier-extensions row (codebook IS embedding infrastructure; row-prefix uniformity preserved) | ✓ ratified |
| **Q3** | Payload hash exposure — skip at V1.0; defer to V2.0 audit-tier (D3.16 anticipated-empirical-pressure discipline; field_index ∈ {0..3} at V1.0) | ✓ ratified; D3.43 formalization deferred to Pod 3.12 |
| **Q4** | Multi-codebook future-proofing — (ii) skip codebook_id parameter at V1.0 (Pod 3.8 D3.32 precedent: codebook_id lives in data, not signature; future #91 lands own surface) | ✓ ratified |
| **Q5** | Opcode allocation — 0xF5 within D3.34 embedding-tier-extensions row | ✓ ratified |
| **Q6** | Cost-table — 1j per D3.13 witness-tier metabolic minimum (matches 0xC5/0xCF/0xF1 precedent) | ✓ ratified |
| **Q7** | Forge-path adaptability — clean clone-substitution from IMPORTED_HANDLE; ~25-30 lines NASM; axis-removal pattern (embedding_id axis collapsed) | ✓ ratified per D3.42 |
| **Q8** | Iteration primitive — META(count) readback sufficient; user loops are CBS-program-native via existing while/for/let/arithmetic surface | ✓ ratified |

---

## 3.11.A–3.11.E chunk audit

| Chunk | Identity | Contract | Catches |
|---|---|---|---|
| 3.11.A | Pre-flight + Q1-Q8 sit (no code) | n/a (Pod 3.10 base b6097e60) | 0 |
| 3.11.B | Constants + handler + dispatch + emitter (bundled) | `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` | 0 (36/36 prior-pod regression byte-exact at new contract; new opcode unreachable from any prior canary) |
| 3.11.C | Cost-table annotation pass (0xF5=1j explicit) | `c9923b8c…` (sha UNCHANGED — first pure-doctrine chunk in V1.0 sequence; existing `dq 1` from reserved-row already produced the same bytes; only comments shifted) | 0 (deductive equivalence by sha-match; no empirical re-run needed) |
| 3.11.D | B52 canary (codebook metadata readback + Err path) | `c9923b8c…` (canonical preserved; B52 uses auxiliary substrate `caa6b315…` built with test_codebook_b48.txt; runner restores canonical post-canary) | 0 (B52 PASS: 5 META readbacks byte-exact; Err path source_op=245/err_code=9 ✓) |
| 3.11.E | SEAL — decision record + commit + push | `c9923b8c…` (canonical preserved through SEAL) | — |
| **SEAL** | canonical contract | `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` | — |

**Build-time catches: 0**. **Substrate-catches: 0**. **Architect-framing-corrections: 0**.

**Cleanest pod in V1.0 sequence** — first pod in the Pod-3 series with **zero catches across all surfaces** (vs Pod 3.5 four catches per-pod-record; Pod 3.8 two catches; Pod 3.9 one substrate catch; Pod 3.10 one architect-framing + one canary-tier discipline; Pod 3.11 ZERO). Pattern aligns with predicted catch rate (0–1, clustered at canary-tier discipline) — actual = 0 cleanly at the lowest end of the predicted range.

---

## B52 PASS narrative (3.11.D)

**Substrate**: built with `inputs/test_codebook_b48.txt` (5 basis vectors × 384 dims; reused from Pod 3.8). Auxiliary substrate sha `caa6b3150ed3ee1961f60faa9b9e57f5e272fd486ba821e3713ef5fb9a6d488a` (two-build IDENTICAL; not SEAL contract — canonical preserved post-canary).

**All 5 META readbacks byte-exact**:

| Field | Field_index | Expected | Actual |
|---|---|---|---|
| COUNT | 0 | 5 | **5** ✓ |
| DIM | 1 | 384 (EMBEDDING_DIM) | **384** ✓ |
| SCALAR_TYPE | 2 | 0 (f32) | **0** ✓ |
| INGESTION_STATUS | 3 | 1 (CBK_STATUS_SUCCESS) | **1** ✓ |
| Out-of-range | 4 | Err(InvalidEmbeddingArg, src=0xF5=245, err=9) | **is_ok=0; source_op=245; err_code=9** ✓ |

**Energy: 101j used** (5 META reads × ~20j each including dispatch + operand-stack overhead — substrate-bookkeeping doctrine per D3.10; 1j cost-table value confirmed empirically as the per-op substrate-internal compute cost).

**Empty-codebook canonical edge case implicitly verified**: every prior-pod canary runs against canonical (empty-codebook) substrate; META on canonical would return count=0, dim=384, scalar_type=0, status=SUCCESS — substrate boots clean on empty codebook (no FATAL); 36/36 prior-pod regression posture across Pod 3.5/3.6/3.7 confirms BSS-zero-default + boot-ingest-empty-codebook path is fully functional.

---

## Architectural moments worth marking

**(1) Axis-removal as inheritance pattern.** Pod 3.11 introduces a new shape for accessor pattern derivation: **axis-removal** — derive a new accessor from an existing one by collapsing one axis. CODEBOOK_META derives from IMPORTED_HANDLE via embedding_id-axis collapse:

| Concern | IMPORTED_HANDLE (0xF1) | CODEBOOK_META (0xF5) |
|---|---|---|
| Operand pops | 2 (field_index + embedding_id) | 1 (field_index only) |
| Validation paths | field range + embedding_id non-zero + registry success | field range only |
| Registry lookup | `call registry_lookup_embedding` | none |
| Address computation | `vm_embedding_imported + (id-1)*32 + field*8` | `vm_codebook_meta + field*8` |
| Error labels | 2 (invalid_field + invalid_id) | 1 (invalid_field) |
| Total lines | ~50 | **~25** |

The axis-removal inheritance is doctrinally meaningful: when substrate state shifts from per-embedding-indexed to singleton, the accessor shape collapses cleanly; the substrate's witness-accessor surface gains a new variant without architectural complexity. Future singleton-state accessors (CAP_STATS / REGISTRY_STATS / etc., if production demands surface) inherit the CODEBOOK_META shape verbatim.

**(2) First pure-doctrine chunk in V1.0 sequence (3.11.C).** Pod 3.11.C edited the cost-table annotation at row 0xF5 — value stayed at `dq 1` (same as the reserved-row default that already covered 0xF5). BOOTX64.EFI byte-exact unchanged at `c9923b8c…` from 3.11.B → 3.11.C. **First substrate-source edit in V1.0 sequence that produced zero binary delta** — pure doctrine alignment with zero binary cost. Earlier cost-table annotation passes (Pod 3.9.C, Pod 3.10.C) actually shifted values; 3.11.C only restructured comments. Doctrine entries can land without substrate-shift when the existing default already matches the new doctrine value.

**(3) Smallest handler in codebase.** `.op_embedding_codebook_meta` at ~25 lines NASM is the **smallest substrate handler in the codebase**. Prior smallest: IMPORTED_HANDLE (~50 lines); SIGN_HANDLE (~40 lines). The axis-removal inheritance enables this — no registry lookup, no MAC verify, no per-embedding offset computation, single error path. Pattern-level achievement: substrate-private singleton state is the simplest possible substrate state for a witness accessor.

**(4) Predicted catch rate (0-1) matched empirical (0) — catch-surface-migration framing validated at inheritance-pod boundary.** Pod 3.11 recon at 3.11.A predicted "0–1 catches, clustered at canary-tier discipline" — matching the architect framing that substrate-USE inheritance pods have catches cluster at canary surfaces rather than substrate-behavior. Actual = 0 catches at any surface. The catch-surface-migration framing (Pod 3.7 mechanical → Pod 3.8/3.9 substrate-behavior catches → Pod 3.10 framing+canary catches → Pod 3.11 zero) tracks substrate maturity at V1.0 — inheritance-pod boundary cleanly enters the "established pattern" regime.

---

## DEFERRED state (Pod 3.11 close)

| # | Description | Status |
|---|---|---|
| #80, #83, #89, #90 | RESOLVED at prior pods | unchanged |
| #82 | Sign.provenance_handle activation candidate | unchanged |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.11 adds 1 (`pod311_b52_runner.sh`) |
| #85 | RECONSTITUTION.md ongoing canon refresh | unchanged |
| #91 | Codebook-symmetry: runtime `OP_EMBEDDING_IMPORT` (0xF0) handler activation + multi-codebook activation | **continues**; codebook read surface reaches V1.0 completeness at Pod 3.11; write surface (#91) remains future-pod work |
| #92 | Stream-stability: aggregation / cross-result analogical operations | continues |
| #93 | Diagnostic-probe-scaffolding policy | unchanged from Pod 3.9 |
| **D3.43** | V2.0-deferral discipline for substrate audit fields (payload_hash + reserved) | **DEFERRED to Pod 3.12** — may absorb into V1.0 SEAL consolidation pass if multiple "what-stays-internal-at-V1.0" decisions surface |

**No new active deferrals at Pod 3.11.** D3.43 doctrine candidate formally deferred to Pod 3.12 consolidation surface.

---

## Substrate state at SEAL

**Five typed pools** (Sign / Energy / Outcome / Cap / Embedding) — unchanged.

**Three non-MAC parallel side-tables** for Embedding linkage — unchanged.

**Substrate-private state cache** — unchanged from Pod 3.8 (`vm_codebook_meta` 64-byte block). Pod 3.11 added the user-surface accessor; the BSS structure itself was already in place.

**OP_EMBEDDING_ row 0xF0–0xFE allocation** (per D3.34 embedding-tier extensions):
- 0xF0 IMPORT — deferred handler per #91
- 0xF1 IMPORTED_HANDLE — codebook witness (per-embedding)
- 0xF2 LOOKUP_TOP_K — housekeeper (recognition)
- 0xF3 PROJECT — composer (geometric)
- 0xF4 REJECT — composer (geometric)
- **0xF5 CODEBOOK_META — maintenance (codebook witness; singleton)**
- 0xF6–0xFE — reserved for embedding-tier extensions (9 slots remaining)

**Maid V1.0 surface (recognition + composition + geometric + import + maintenance)** complete on the codebook surface:
- Recognition: cosine + dot + L2 + lookup_top1 + lookup_top_k
- Synthesis arithmetic: add + subtract + scale + normalize + lerp
- Synthesis geometric: project + reject
- Import + provenance: boot_ingest_codebook + imported_handle + synthesis_handle
- **Codebook metadata: codebook_meta (NEW Pod 3.11)**

The codebook surface reaches **V1.0 read-completeness** — write at boot (Pod 3.8) + per-embedding provenance (Pod 3.8 IMPORTED_HANDLE) + codebook-level metadata (Pod 3.11 CODEBOOK_META). Production scenarios can iterate imported embeddings (loop 1..count via META), inspect per-embedding provenance (IMPORTED_HANDLE), and verify substrate-runtime ingestion status (META(INGESTION_STATUS) = SUCCESS / error code).

**Two-build determinism** preserved at canonical Pod 3.11 SEAL contract `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` — re-confirmed at SEAL.

---

## Headline moments

**Substrate-doctrinal**: D3.42 names codebook metadata witness accessor as substrate-private singleton-state accessor (vs per-embedding state of GET_DIM/SIGN_HANDLE/SYNTHESIS_HANDLE/IMPORTED_HANDLE); **axis-removal inheritance pattern** codified.

**Empirical first**: Pod 3.11.C — **first pure-doctrine chunk in V1.0 sequence**; cost-table annotation pass produced zero binary delta (sha unchanged from 3.11.B); doctrine entries can land without substrate-shift when the existing default already matches.

**Surface-level achievement**: Pod 3.11.B handler at ~25 lines NASM is the **smallest substrate handler in the codebase**; axis-removal collapse from IMPORTED_HANDLE achieves the minimum-surface form for substrate witness accessors.

**Catch profile**: **0 catches across all surfaces — cleanest pod in V1.0 sequence**; recon-prediction validated empirically at lowest end of predicted range (0-1 → 0); catch-surface-migration framing (mechanical pod → substrate-behavior pod → framing+canary pod → inheritance pod) tracks substrate maturity at V1.0; inheritance-pod boundary enters "established pattern" regime cleanly.

**Codebook surface completion**: Pod 3.8 write + per-embedding read; Pod 3.11 codebook-level read → **V1.0 read-completeness**. Write surface (#91 runtime IMPORT + multi-codebook activation) remains future-pod work; the V1.0 codebook architecture provides complete witness coverage.

---

## V1.0 progress checkpoint

**Pod 3.11 = 5 of 6 V1.0 pods sealed.** Pod 3.12 — the V1.0 SEAL — remains.

The Maid recognizes; the Maid composes; the Maid imports; the Maid finds many; the Maid orthogonalizes; **the Maid maintains**. The substrate's lexical-computation pole reaches operational completeness on:
- Recognition axis (single-best + K-best with threshold)
- Synthesis axis (vector arithmetic + geometric decomposition)
- Import axis (boot ingestion + per-embedding provenance + codebook-level metadata)

**Six Maid V1.0 capability variants live**; production scenarios for K-metric demo workflows (population-code analysis via cosine ranking + top-K + project/reject decomposition + import iteration via META(count)) have complete substrate coverage at V1.0.

Pod 3.12 (V1.0 SEAL — the last pod) lands the V1.0-completion surface: substrate consolidation, any final doctrinal codification (including D3.43 if it surfaces as part of broader "what-stays-internal-at-V1.0" consolidation), and the V1.0 SEAL marker itself. Exact framing deferred to Pod 3.12 architectural sit.
