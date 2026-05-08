# Pod 3.7 Decision Record — The substrate scales

**Pod:** 3.7 — housekeeping + production capacity expansion; substrate-EVOLUTION pod
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-07
**Entry contract:** 7349875648f64b9143d768bcaec14a6fb8c40f62f379ce2ab6ce68ceee0b8871 (Pod 3.6 BOOTX64.EFI)
**Exit contract:** 435e17eca9b9d26028e8a67c8fe411b727a762cc471a61d0fe1e3eb77bcbf36a
**Entry HEAD:** 1b2a666e3edc767fc2a60645bd7d879c45249dc0 (Pod 3.6 seal — Maid composes)

> Pod 3.7 is heavy on mechanics, light on new ontology. Embedding pool grows 256 → 2048; outcome pool grows 64 → 4096; build.sh gains dual-layer pinning. The single new doctrine D3.29 names a discipline that was already implicit in the substrate (side-tables cascade via shared constants) and explicit in retrospect (the Pod 3.6 B42 outcome-pool-exhaustion-masks-err-observability quirk was a coupling-violation in disguise). Doctrine names what canon was already saying — the substrate's recurring pattern of self-understanding, fourth landing this pod chain (D3.6 placeholder→reclaimed pattern; D3.20→D3.26 non-MAC parallel linkage; D3.28 FP-precision predicted-drift; D3.29 typed-pool capacity proportionality). DEFERRED #83 / #89 / #90 all RESOLVED. **B47 introduces the build-system canary class** as substrate-meta-architectural addition: surface-distinct from substrate canaries; future build-system canaries follow.

---

## D3.29 — Typed-pool capacity proportionality (two axes)

**Cross-cutting summary doctrine entry; future pods cite D3.29 rather than re-recording the typed-pool-coupling discipline.**

The substrate has **two distinct coupling axes** between typed pools, both with proportionality discipline:

### Axis 1 — Capacity-stress proportionality

Pools coupled by op-output relationships scale together. Every Outcome-producing op consumes outcome_pool; outcome_pool must satisfy:

```
OUTCOME_POOL_SLOTS ≥ N × max(forge-pool size that can be stress-loaded by program shape)
```

where `N` reflects per-op + per-accessor-call multiplicity. **`N=2` baseline** for typical workloads (one outcome per forge + one outcome per accessor query). For Pod 3.7 with EMBEDDING_POOL_SLOTS=2048 and embedding-pool dominance, this reduces to `2 × 2048 = 4096`.

**Future-proofing**: if Pod 4+ expands Sign / Energy / Cap pools to similar magnitudes, the `max()` in the rule binds to whichever is largest. Embedding-pool dominance currently makes the rule trivially satisfiable, but the framing prevents silent under-sizing as future pods scale other pools.

**Mechanism**: outcome_pool is universally coupled to all four forge pools (Sign / Energy / Cap / Embedding) — every successful primitive construction produces an Outcome via `.construct_ok_outcome`; every Err path also constructs an Outcome via `.construct_err_outcome`. In practice embedding workload dominates by 32× pool-size advantage; the `2 × embedding_pool` rule is the binding constraint for codebook scenarios.

**Empirical anchors**:
- B43: 2048 forges + 1 err = 2049 outcomes; outcome_pool 2049/4096 (50% headroom). Err outcome fully readable.
- B44: 2048 ok + 1900 err + 1 final = 3949 outcomes; outcome_pool 3949/4096 (96% utilization). Err outcome **still** fully readable. Distinct from Pod 3.6 B42 quirk where outcome_pool=64 exhausted before embedding_pool=256, masking err observability.
- B45: 50 forges + 3 synthesis ops + accessors → outcome_pool ≈ 60/4096 (1.5% utilization); comfortable headroom under realistic workload.

### Axis 2 — Side-table mechanical-sizing proportionality

Side-tables sized to their parent typed-pool's SLOTS via shared constant. Mechanical coupling (BSS sizing) distinct from capacity-stress coupling (outcome production), but shares the proportionality discipline.

**Existing instances**:
- `vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0` (Pod 3 D3.4 forward Sign→Embedding linkage)
- `vm_embedding_sign_handle: times EMBEDDING_POOL_SLOTS dq 0` (Pod 3.5 D3.20 reverse Embedding→Sign linkage)
- `vm_embedding_synthesis: times EMBEDDING_POOL_SLOTS * SYNTHESIS_TUPLE_BYTES db 0` (Pod 3.6 D3.26 generalized non-MAC parallel linkage)
- All five typed-pool registries: `*_registry: times *_POOL_SLOTS * 16 db 0`

With Pod 3.7 EMBEDDING_POOL_SLOTS=2048, the cascade is automatic:
- vm_embedding_sign_handle: 2048 × 8 = 16 KB
- vm_embedding_synthesis: 2048 × 32 = 64 KB
- embedding_registry: 2048 × 16 = 32 KB
- vm_embedding_pool: 2048 × 1576 = 3.16 MB

**Doctrine**: side-tables MUST size to their parent pool's SLOTS via shared constant; never via hardcoded byte counts. Shared-constant discipline ensures cascade correctness when parent pool grows.

**The discipline was already in canon before D3.29 named it**. Pod 3 D3.4 / Pod 3.5 D3.20 / Pod 3.6 D3.26 all enacted shared-constant-sizing without invoking the doctrine explicitly. D3.29 makes the implicit pattern explicit; recognition, not invention. Mirrors D3.26's recognition pattern (D3.20 generalization). The substrate's recurring self-understanding pattern.

### Combined discipline

Future pool additions follow both axes:
- Coupling enumeration mandatory at pool-introduction pods (which forge ops produce outcomes? which side-tables size to this pool? which side-tables this pool sizes from?)
- Capacity-stress proportionality: outcome_pool sizing reviewed when any forge pool grows
- Side-table mechanical-sizing: parent-constant discipline enforces cascade automatically

D3.29 is **substrate self-understanding** — the second axis (mechanical-sizing) lands as recognition in canon; the first axis (capacity-stress) lands as the empirically-discovered Pod 3.6 B42 lesson reframed as design discipline.

---

## Typed-pool audit (post-Pod-3.7 expansion)

| Pool | SLOTS | bytes/slot | Pool BSS | Registry BSS | Side-tables coupling-from |
|---|---|---|---|---|---|
| Sign | 64 | 128 | 8 KB | 1 KB | `vm_sign_embedding_handle` 512 B (sized SIGN_POOL_SLOTS) |
| Energy | 64 | 128 | 8 KB | 1 KB | — |
| **Outcome** | **4096** | 128 | **512 KB** | **64 KB** | universal coupling-target (every forge produces outcome) |
| Cap | 64 | 128 | 8 KB | 1 KB | — |
| **Embedding** | **2048** | 1576 | **3.16 MB** | **32 KB** | `vm_embedding_sign_handle` 16 KB + `vm_embedding_synthesis` 64 KB (sized EMBEDDING_POOL_SLOTS) |

**Total typed-pool BSS post-expansion**: ~3.86 MB (vs ~436 KB pre-expansion; +3.4 MB delta).

**Stress estimate per pool at Pod 3.7 production scale**:
- Sign / Energy / Cap at 64: not stressed by codebook workloads. Cap nesting < 10; Sign/Energy modest. **No expansion needed at Pod 3.7.**
- Outcome at 4096: 96% utilization at extreme stress (B44); ~50% utilization at typical capacity-bounded codebook (B43); <2% under realistic workload (B45). **D3.29 proportionality holds with comfortable headroom.**
- Embedding at 2048: production codebook scale per DEFERRED #83 framing.

**No additional second-couplings beyond outcome/embedding identified.** All forge pools couple unidirectionally to outcome_pool; no mutual coupling between forge pools (Sign doesn't size-couple with Embedding); side-tables couple their own size to parent's SLOTS but introduce no additional axes.

**PE text-section budget**: TEXT_RAWSZ expanded 0x100000 (1 MB) → 0x500000 (5 MB) to accommodate BSS growth. Final BOOTX64.EFI: 5,243,904 bytes (~5 MB; previously ~1 MB at Pod 3.6 SEAL). RELOC_RVA / RELOC_RAW / IMAGE_SZ shifted accordingly. Boot-time impact: sub-second BSS init; no measurable launch delay.

---

## Build-shell hardening (DEFERRED #89 RESOLVED)

`build.sh` gains **dual-layer pinning**:

1. **Absolute-path pin** (`NASM=/usr/bin/nasm`, `MCOPY=/usr/bin/mcopy`) — bypasses `$PATH`-resolved binaries. Defends against Git-Bash-on-Windows or other shells exposing different binaries on PATH (Pod 3.6 SEAL surfaced this empirically: harness Git-Bash had NASM 3.01 vs WSL's 2.16.01).
2. **Version-grep guard** (`grep -q "$EXPECTED_NASM_VERSION"`, `grep -q "$EXPECTED_MCOPY_VERSION"`) — fail-loud on toolchain drift. Even if absolute path resolves correctly, an OS-level toolchain upgrade would break determinism silently; version check catches that.

**Override-friendly**: `NASM` and `MCOPY` are env-var-overridable (`${NASM:-/usr/bin/nasm}`) for testability. B47 host-side guard test fakes wrong-version binaries via this mechanism without privileged ops.

**B47 (build-system canary class introduction)**:
Surface-distinct from substrate canaries — text-log artifact rather than QEMU screendump. New canary class: build-system canaries verify the build-pipeline integrity itself rather than substrate behavior. Pattern for future build-system canaries:
- Inject controlled fault into build infrastructure
- Run build, capture log
- Assert exit code + error message matches expected fail-loud behavior
- Cleanup; preserve log

**Empirical**: 2/2 guards fire loud on toolchain drift:
```
BUILD-SHELL: nasm version mismatch (expected 2.16.01); got: NASM version 1.99.99 ...
BUILD-SHELL: mcopy version mismatch (expected 4.0.43); got: mcopy (GNU mtools) 1.99.99
```

**Build-shell determinism shifts from editorial discipline to mechanically-enforced contract.** Pre-Pod-3.7: "the build runs through WSL where 2.16.01 lives" was a documentation note. Post-Pod-3.7: silent toolchain drift triggers loud fail at build dispatch, before the wrong assembler ever runs. Defense-in-depth + B47 meta-canary verifies the defense-in-depth.

---

## B43-B47 empirical results

| # | Surface | Result | Headline finding |
|---|---|---|---|
| B43 | embedding_pool_capacity_at_2048 | **PASS** | 2048 forges + err on 2049th: source_op=192, err_code=2 byte-exact |
| B44 | outcome_pool_under_synthesis_load | **PASS** | 3949 outcomes registered; final err outcome fully readable. Pod 3.6 B42 quirk retired |
| B45 | mixed_workload_within_capacity | **PASS** | 50 forges + 3 synthesis ops; doubled[0]=0x40000000, sum[0]=0x40400000, mid[0]=0x3FC00000, tuple op=1 byte-exact |
| B46 | Pod 3.5/3.6 regression at Pod 3.7 layout | **PASS** | 29/29 Pod 3.5 + 20/20 Pod 3.6 byte-exact preserved |
| B47 | build-shell guard host-side meta-test | **PASS** | 2/2 guards fire loud on faked nasm/mcopy version drift |

**Total catches at Pod 3.7 SEAL: zero.** Architect prediction matched (predicted catch rate: zero, mechanical pod). The single substrate-architectural finding — PE text-section overflow at first build attempt — was anticipated mechanical (BSS grew past 1 MB ceiling) and resolved with a `TEXT_RAWSZ 1MB → 5MB` expansion.

**Energy budgets observed**:
- B43: 229,547j (mostly 2049 × 100j forge dispatch)
- B44: 442,362j (mostly 3949 × 100j forge dispatch + 2 while loops)
- B45: 7,471j (50 × 100j forge + synthesis ops + accessors; 0.75% of 1M ceiling — comfortable headroom for production workload)

---

## Architectural observations worth marking

### Observation 1 — Pod 3.6 B42 quirk retired by D3.29

Pod 3.6's B42 (pool_capacity_synthesis_pressure) surfaced a substrate-architectural quirk: with OUTCOME_POOL_SLOTS=64 and EMBEDDING_POOL_SLOTS=256, outcome_pool exhausted at iteration 64, well before embedding_pool could fill at iteration 256. The result: when ADD's pool-full err path attempted to construct an Err outcome via `.construct_err_outcome`, the outcome_pool was already exhausted, returning sentinel 0. The substrate's correct error-path behavior was masked by the disproportionate pool sizes; user code observed outcome_id=0 (lookup-fails) rather than a properly-readable Err outcome.

D3.29 codifies the lesson: outcome_pool MUST satisfy proportionality with the largest stress-loadable forge pool. The Pod 3.6 quirk wasn't a substrate defect; it was a **coupling-violation** that D3.29 names. Pod 3.7's 4096:2048 ratio resolves this empirically (B44 verified 3949 outcomes registered with err outcomes still fully readable).

The B42-style observability gap is now structurally impossible at Pod 3.7 production scale. Future pool growth follows the proportionality rule by construction; the bug-class B42 represented retires.

### Observation 2 — Build-shell determinism shifts from editorial to mechanically-enforced

Pre-Pod-3.7: the "build runs through WSL with NASM 2.16.01" guarantee was documented as DEFERRED #89 forward-anchor. Editorial discipline; no mechanism to enforce. Pod 3.6 SEAL surfaced the actual hazard empirically (Git-Bash NASM 3.01 in harness vs WSL 2.16.01 in build).

Post-Pod-3.7: dual-layer pinning at build.sh dispatch makes the guarantee mechanical. **The substrate's two-build determinism contract gains a build-pipeline guard** to match the substrate-behavior guards already in place (canary regressions). Defense-in-depth + B47 meta-canary verifies the defense-in-depth fires correctly under simulated drift.

The shift parallels D3.28's pattern (FP-precision drift moves from documentation-only anti-pattern to mechanically-enforced canon via B-aux canaries). Pod 3.7 generalizes the pattern to the build pipeline itself: any class of substrate-determinism guarantee can be mechanically verified via meta-canaries surface-distinct from substrate canaries.

**B47 is the build-system canary class introduction.** Pod 3.7 establishes the surface; future build-system canaries follow the pattern.

---

## Resolution summary

| # | Description | Status |
|---|---|---|
| #83 | Embedding pool capacity expansion | **RESOLVED** — 256 → 2048 (production scale) |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.7 adds 3 housekeeping scripts (regression + B43-45 runner + B47 guard) |
| #89 | Build-shell-determinism hazard | **RESOLVED** — dual-layer pinning + B47 meta-canary |
| #90 | Outcome pool capacity below embedding pool | **RESOLVED** — 64 → 4096 per D3.29 axis 1 |

**Three deferrals resolved at Pod 3.7 SEAL.**

---

## Substrate state at seal

**Pool sizes (final)**:
- Sign / Energy / Cap: 64 each (unchanged; not stressed by codebook workloads)
- Outcome: **4096** (per D3.29 axis 1)
- Embedding: **2048** (production codebook scale)

**Side-tables (cascade automatically per D3.29 axis 2)**:
- vm_sign_embedding_handle: 64 × 8 = 512 B (parent SIGN_POOL_SLOTS unchanged)
- vm_embedding_sign_handle: 2048 × 8 = 16 KB
- vm_embedding_synthesis: 2048 × 32 = 64 KB

**PE layout**:
- TEXT_RAWSZ: 0x500000 (5 MB; was 0x100000 at Pod 3.6)
- IMAGE_SZ: 0x502000
- BOOTX64.EFI: 5,243,904 bytes

**Build-pipeline integrity**:
- NASM 2.16.01 / mtools 4.0.43 pinned at absolute path + version-grep
- B47 meta-canary verifies fail-loud on drift

**Maid V1.0 surface**: unchanged from Pod 3.6 (housekeeper + composer + lineage recovery). Pod 3.7 scales the substrate around Maid; Maid's surface is identical, just operating at production scale.

**Federation accounting / authority gating / FP determinism**: all unchanged from Pod 3.6 SEAL. Substrate-USE behavior is byte-exact preserved across the Pod 3.7 substrate-EVOLUTION event (29/29 Pod 3.5 + 20/20 Pod 3.6 PNG regression confirms).

**Two-build determinism**: preserved at Pod 3.7 contract `435e17ec…`.

**Pod 3.7 architect-error catches**: zero. Mechanical pod prediction held.

**The substrate scales.** D3.29 names two coupling-discipline axes; capacity ceiling rises 8× for embeddings + 64× for outcomes; build-pipeline integrity gains mechanical enforcement; three deferrals resolve. Pod 3.7 is the housekeeping pod that makes Pod 3.6's Maid production-ready.
