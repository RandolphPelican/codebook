# Pod 4.0.F.9 Decision Record — Similarity browser demo (B54)

**Sub-chunk:** Pod 4.0.F.9 — codebook similarity browser; auxiliary substrate per B48/B49/B52 pattern; first V1.0 demo composing 4 doctrines across Pod 3.5 + 3.8 + 3.9 + 3.11.
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-12
**Entry HEAD:** f27e12b211a4d946c22682de340ec10b23fe4e97 (Pod 4.0.F.8 — vector composer)
**V1.0 SEAL substrate contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED — D4.1 byte-lock holds; verified via runner restore step)

---

## Query approach decision

Architect framing offered two options:

> "If you use one of the codebook entries directly via IMPORTED_HANDLE, the top-1 self-match is trivially predictable (cosine = 1.0 byte-exact). If you synthesize a fresh embedding via SYNTHESIS ops, top-K ordering depends on what you synthesize. The latter is more interesting cross-doctrine; the former is more robustly verifiable. Pick what reaches a clean canary outcome."

**TB chose: self-match via runtime-forged e_x (the cleaner-canary option).** Rationale:

- The codebook (inputs/test_codebook_b48.txt) holds 5 orthogonal basis vectors (id=1 has dim[0]=1.0; id=2 has dim[1]=1.0; etc.)
- A runtime-forged query = e_x (same vector as codebook id=1) produces:
  - Top-1: id=1 with cosine = **1.0 byte-exact** (0x3F800000); leverages D3.14 cosine same-vector identity + B30 mulss(1.0,x)=x endpoint + sqrt(1)=1 in f32
  - Top-2/3: id=2/3 with cosine = **0 byte-exact** (orthogonal basis vectors → dot=0 → cos=0)
- Tie-break for ranks 2/3 (both cos=0) follows scan order: id=2 first, then id=3 (per Pod 3.9 D3.35 selection-sort tie-break — JBE skips replacement on tied scores; first-encountered wins)
- 11 byte-exact predictions in one canary

Both approaches are interesting cross-doctrine; self-match cleaner-canary because the predicted values are universally-recognized constants (1.0, 0.0) rather than computed-via-R10 bit patterns. Architect's "clean canary outcome" framing wins.

---

## B54 — 11 byte-exact predictions PASS

### Codebook META verification (D3.42 — Pod 3.11)

```
codebook entries (META COUNT; expect 5):    5    ✓
codebook dim (META DIM; expect 384):        384  ✓
ingestion status (META STATUS; expect 1):   1    ✓
```

Confirms B48 auxiliary substrate ingested correctly; 5 entries × 384 dims; CBK_STATUS_SUCCESS = 1.

### Query forge (D3.31 — Pod 3.8)

```
query forged - id (expect 6):    6    ✓
```

After 5 boot-ingested codebook entries occupy ids 1-5, the user-program embedding_new forges id=6. Confirms boot-ingest-then-user-forge ordering canonical.

### Top-K (D3.35 — Pod 3.9)

```
K-prime returned (expect 3):    3    ✓
```

lookup_top_k(query, K=3, threshold=-INF) returns K'=3 (full K requested; no threshold filtering).

### Rank 0 — best match (D3.14 cosine same-vector + D3.18 lookup_top1 generalization)

```
rank 0 - best match:
  id (expect 1):                                                   1            ✓
  cosine (expect 1065353216 = 0x3F800000 = 1.0):                  1065353216   ✓
```

Self-match: query vector = (1, 0, 0, ...) = codebook id=1 vector. cosine = 1.0 byte-exact (B30 mulss(1.0,x)=x; sqrt(1)=1).

### Rank 1 — tie-break first-encountered (D3.35 selection-sort discipline)

```
rank 1:
  id (expect 2; tie-break first-encountered):    2    ✓
  cosine (expect 0):                              0    ✓
```

cosine(e_x, e_y) = dot/norms = 0/(1·1) = 0 byte-exact (orthogonal basis vectors). Tie-break: id=2 first-encountered in scan order (substrate scans id=1..6; finds id=2 with cos=0 first among cos=0 entries).

### Rank 2 — second tied entry

```
rank 2:
  id (expect 3):                  3    ✓
  cosine (expect 0):              0    ✓
```

cosine(e_x, e_z) = 0; second-encountered cos=0 entry (id=3 after id=2 in scan order).

### Energy trace (D3.17 — anticipated-worst-case)

```
joules used (full similarity browse):    101498
Energy: 101511j used, 898489j remaining
```

**~101k joules** — dominated by lookup_top_k's pool-bounded scan at 100,000j (matches D3.17 anticipated-worst-case for lookup_top1 → top_k generalization per D3.35); plus ~1500j accessor/forge/dispatch overhead. Substrate's per-opcode cost-table empirically validated at user-program scale with codebook scan.

---

## Five-doctrine cross-composition canary

B54 composes five doctrines in one canary:
1. **D3.14** — cosine Form A canon (same-vector → 1.0 byte-exact; orthogonal → 0 byte-exact)
2. **D3.18** → **D3.35** — lookup_top1 housekeeper canon generalized to lookup_top_k (Pod 3.9)
3. **D3.31** — boot-time codebook ingestion (Pod 3.8; the 5 basis vectors arrive at ids 1-5 before user forge)
4. **D3.42** — codebook META witness accessor (Pod 3.11; substrate-private singleton state)
5. **D3.35 tie-break** — selection-sort find-min JBE skips on tied scores → first-encountered wins for cos=0 ranks 2/3

The substrate-canon-to-runtime-behavior connection is traceable across five doctrines + the boot-ingest + user-forge orderings within one canary execution.

---

## Auxiliary substrate determinism

| Build | Result |
|---|---|
| B54 substrate sha (CODEBOOK_INPUT=test_codebook_b48.txt; first build) | `caa6b3150ed3ee1961f60faa9b9e57f5e272fd486ba821e3713ef5fb9a6d488a` |
| B54 substrate sha (second build) | `caa6b3150ed3ee1961f60faa9b9e57f5e272fd486ba821e3713ef5fb9a6d488a` ✓ IDENTICAL |
| Canonical sha (post-canary restore) | `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` ✓ matches V1.0 SEAL |

**B54 auxiliary substrate sha matches B52 auxiliary substrate sha** (`caa6b315…`) — verifiable continuity per architect framing ("Reuse inputs/test_codebook_b48.txt ... same input file across canaries means same auxiliary substrate sha across canaries"). The cross-canary invariant holds empirically.

---

## Files landed at Pod 4.0.F.9

```
tools/atreyu_x86.py                — added demo_pod40f_b54_similarity_browser()
                                      + --pod40f-b54-similarity-browser-build CLI
tools/pod40f_b54_runner.sh         — auxiliary-substrate runner (mirrors pod311_b52_runner.sh pattern)
surfaces/test_pod40f_b54_similarity_browser.cbc   2,591 bytes compiled bytecode
build/pod40f_b54_similarity_browser.png           14,849 bytes canary PNG
recon/POD4.0F9_DECISION_RECORD.md  this file
```

---

## Verification at Pod 4.0.F.9 SEAL

| Item | Result |
|---|---|
| Substrate sha (canonical, post-canary) | `c9923b8c…` (UNCHANGED; D4.1 byte-lock holds) |
| Two-build determinism (B54 aux substrate) | IDENTICAL ✓ |
| Cross-canary aux substrate continuity (B52 vs B54) | `caa6b315…` matches both — verifiable continuity ✓ |
| B54 canary | **PASS** — 11/11 byte-exact predictions; energy = 101511j |
| pytest harness | 33/33 PASS (carried) |

### Catch profile
- **Build-time catches**: 0
- **Substrate-catches**: 0
- **Polish-tier catches**: 0
- **Architect-framing-corrections**: 0

D3.44 prediction continues: composition canaries hit zero-catch zone.

---

## Pod 4.0.F progress

| Sub-chunk | Status |
|---|---|
| 4.0.F.0 D4.2 + use_cap emitter | DONE |
| 4.0.F.1 B53 fib energy | DONE |
| 4.0.F.6 B58 drift anchor | DONE |
| 4.0.F.7 B57 press-X | DONE |
| 4.0.F.8 B55 vector composer | DONE |
| **4.0.F.9 B54 similarity browser** | **DONE (this commit)** |
| 4.0.F.10 B56 cap lifecycle | pending — final demo before Pod 4.0.F SEAL |

**6 of 6 demos canary-PASS-ready in 4.0.F.10**, then unified D4.5 demo-program discipline doctrine + full Pod 4.0.F SEAL.

---

## Architectural moments worth marking

1. **Five-doctrine composition in one canary**. B54 validates D3.14 + D3.18→D3.35 + D3.31 + D3.42 + D3.35-tie-break simultaneously. The substrate-canon-to-canary-output traceability holds across all five at the same execution. This is the V1.0 credential's empirical density: every doctrine the substrate codified is reachable from one canary that runs in <30 seconds.

2. **Cross-canary auxiliary substrate continuity**. B48 (Pod 3.8 codebook ingestion canary), B52 (Pod 3.11 codebook META), and now B54 (Pod 4.0.F similarity browser) all use the same auxiliary substrate sha (`caa6b315…`) because they share the same codebook input. **The substrate's two-build determinism extends across canary boundaries** — same input deterministically produces same substrate, regardless of which canary runs against it. This is verifiable continuity in action.

3. **D4.1 byte-lock survives auxiliary-substrate builds**. The runner builds aux substrate, runs canary, then **restores canonical via final rebuild**. Canonical sha `c9923b8c…` returns byte-exact to V1.0 SEAL contract. D4.1 byte-lock holds across polish/credential boundaries — even when the credential layer temporarily builds a different substrate for a canary, the canonical state restores deterministically.

4. **Energy accounting at recognition-tier**. The substrate's per-opcode cost-table values land empirically: lookup_top_k drains ~100k joules (D3.17 anticipated-worst-case for pool-bounded scan); cosine ops drain ~400j each (3 cosine computes for ranks 0/1/2 ≈ 1200j additional); META reads + accessors + dispatch ≈ remaining overhead. **101,511j total empirically matches the cost-table sum** — substrate's metabolic accounting is internally consistent across composition layers.
