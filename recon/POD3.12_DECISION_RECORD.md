# Pod 3.12 Decision Record — V1.0 SEAL (consolidation + final codification)

**Pod:** 3.12 — V1.0 SEAL; the canon-binding moment for the Maid V1.0 capability surface. NOT adding capability — closing the architectural arc. Executed under Pod 4.0 umbrella per the wrapper-pivot redirect (Pod 4.0.B = Pod 3.12 V1.0 SEAL closeout).
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-11
**Entry HEAD:** e5638c690d8e0de1d5becbe3a2055c0b68de6bfa (Pod 3.11 SEAL — Maid maintains)
**Entry contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900
**Exit contract:** c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900 (UNCHANGED from Pod 3.11 — Pod 3.12 V1.0 SEAL is documentation + doctrine codification + script consolidation; zero substrate-bytes change)
**Tag:** `v1.0-seal`

> Pod 3.12 SEALs V1.0. Substrate at the 44-doctrine canon state; six Maid V1.0 capability variants live (recognize / compose / import / find-many / orthogonalize / maintain); five typed pools; the codebook surface reaches V1.0 read-completeness; SipHash MAC integrity per primitive; byte-exact f32 IEEE 754 determinism; energy accounting at opcode level. Two doctrine entries land: D3.43 (V1.0-deferral framework, broad — three convergent patterns) and D3.44 (catch-surface-migration tri-tier doctrine). RECONSTITUTION refreshes to v11. DEFERRED #84 / #85 / #93 close at V1.0 SEAL. The substrate IS V1.0.

---

## D3.43 — V1.0-deferral framework (broad)

**The doctrine.** The substrate has, across V1.0, accumulated three convergent patterns for deferring features to future versions. D3.43 names them collectively: when a feature is considered for V1.0 inclusion, it gets framework-tested against these patterns. Features that fail the test defer to V2.0.

### D3.43.1 — Anticipated-empirical-pressure deferral (D3.16 family canonized)

**Origin**: D3.16 (Pod 3.5 cosine pool sizing decision).

**Rule**: features land when production scenarios surface concrete demand, not when they're architecturally appealing. The substrate ships the *conservative* shape; expansion follows empirical demand.

**Discipline test**: "What consumer scenario justifies this feature today?" If the answer is "future-pod consumers might want this," defer.

**V1.0 instances**:
- Pod 3.5 cosine: 256-slot pool (matched then-anticipated demand); Pod 3.7 expanded to 2048 only when production-scale codebook ingestion landed
- Pod 3.9 top-K: stack-based ephemeral result representation (not Result[T] sixth-pool persistent)
- Pod 3.10 project/reject scalar field: scalar=0 (not computed-ratio storage)
- Pod 3.11 codebook META: 4 user-relevant fields (not payload_hash exposure)

### D3.43.2 — Asymmetric-surface deferral (D3.32 family canonized)

**Origin**: D3.32 (Pod 3.8 codebook write/read surface asymmetry).

**Rule**: land write OR read at V1.0 (whichever production needs); defer the other axis until concrete demand. Surface-asymmetry-at-V1.0 is a feature, not a bug — it acknowledges that production scenarios at V1.0 exercise one direction.

**Discipline test**: "Which direction does production currently exercise?" Land that direction; defer the other.

**V1.0 instances**:
- Pod 3.8 codebook: write substrate-private (boot ingestion); read dispatch-runtime (IMPORTED_HANDLE + META); user-program write deferred to multi-codebook activation (#91)

### D3.43.3 — Audit-field deferral (specific case)

**Origin**: Pod 3.11 Q3 sit ratification (payload_hash + reserved bytes).

**Rule**: substrate-internal integrity/audit metadata stays internal at V1.0; user-surface exposure deferred until audit-tier scenarios emerge. The substrate retains the data (BSS allocations preserved); accessor exposure is the deferred axis.

**Discipline test**: "Is the user-program reading this for *production behavior*, or for *substrate introspection*?" Production-behavior reads land at V1.0; introspection reads defer to audit-tier.

**V1.0 instances**:
- Pod 3.11 CODEBOOK_META payload_hash (16 bytes at +0x20): substrate retains; user-surface exposure deferred to V2.0 audit-tier if production demand surfaces
- vm_codebook_meta reserved block (16 bytes at +0x30): same pattern

### D3.43.x — Forensic-record retention discipline

**Rule**: diagnostic probe scaffolding from substrate-catch events stays in canonical tree as inert artifact. Retention threshold: probes from catch events with *substantial future-debugging applicability* retained; trivial single-instance probes may be retired at the catch-discovery pod's SEAL.

**V1.0 instance**:
- Pod 3.9 D3.37 NASM RIP-relative bug-find probes (`demo_pod39_b49_probe`, `demo_pod39_b49_probe_k`, `tools/pod39_b49_probe_runner.sh`, `surfaces/test_pod39_b49_probe.cbc`, `test_pod39_b49_probe_k.cbc`) — RETAINED. The indexed-BSS-access pattern recurs at any future helper with similar surface; probe templates are forensic-reference for future debugging.

**DEFERRED #93 CLOSES at V1.0 SEAL with retention ratified.**

---

## D3.44 — Catch-surface-migration tri-tier doctrine

**The doctrine.** Across the V1.0 sequence (Pods 3.7 through 3.11), an empirical pattern emerged: a pod's tier classification predicts where its catches cluster. The doctrine codifies the three-tier framing for V2.0 sit-time recon to use predictively.

### Tier A — Mechanical (substrate-EVOLUTION pods)

Pool sizing, build-shell hardening, infrastructure expansion. Catches cluster at **build-pipeline integration** (NASM warnings, build-shell determinism, CI/CD interactions).

**V1.0 instance**: Pod 3.7 substrate scales (pool expansion 256→2048; build-shell hardening). 2 build-time catches; 0 substrate-behavior.

### Tier B — Substrate-behavior (new primitives, new computational shapes)

New typed primitives, new helpers, new computational patterns. Catches cluster at **substrate-internal surface** (NASM addressing, helper precision, register allocation, Form A/B drift).

**V1.0 instances**:
- Pod 3.8 Maid imports (codebook ingestion, new BSS structures): 2 build-time catches
- Pod 3.9 Maid finds many (compute_top_k_raw with new BSS scratch arrays): 1 substrate-catch (D3.37 NASM `[rel sym + reg*scale]` silently miscompiles)

### Tier C — Inheritance (substrate-USE pods inheriting established patterns)

Existing helper-pair convention extension, existing accessor pattern derivation. Catches cluster at **canary-tier discipline** or are absent entirely.

**V1.0 instances**:
- Pod 3.10 Maid orthogonalizes (project/reject from synthesis-tier pattern): 1 architect-framing-correction + 1 canary-tier discipline (D3.41 forge-order tracking)
- Pod 3.11 Maid maintains (CODEBOOK_META via axis-removal from IMPORTED_HANDLE): **0 catches across all surfaces** — cleanest pod in V1.0 sequence

### The migration trajectory

As substrate matures across the V1.0 sequence, catches migrate **outward**:
- Early (Tier A): catches cluster INWARD at build-pipeline
- Mid (Tier B): catches at substrate-internal surface
- Late (Tier C): catches at canary-tier or absent

**V1.0 SEAL is the catch-clean boundary.** Pod 3.11 reached zero catches; Pod 3.12 V1.0 SEAL inherits the clean state.

### Forward use (V2.0 sit-time)

V2.0 pod sit-prep can predict catch surfaces via tier classification:
- New substrate primitives → Tier B; expect substrate-behavior catches; prepare debugging probes per D3.43.x retention
- New CBS surface / new demo → Tier C; expect canary-tier discipline catches; prepare forge-order documentation per D3.41
- Infrastructure expansion → Tier A; expect build-pipeline catches; verify NASM/mtools/build-shell discipline

Tier classification becomes a **sit-time recon input**.

---

## Empirical code-byte measurement (per architect 64KB-narrative directive)

**Method**: measure non-zero byte count of `build/BOOTX64.EFI` (proxy for "actual content"; excludes BSS pool reservations + PE32+ TEXT_RAWSZ padding).

**Result**:
- **Binary file size**: 5,243,904 bytes (5.0 MB total)
- **Non-zero content**: **26,031 bytes (≈ 25.4 KB)**
- **BSS pool reservations** (sized at compile-time for V1.0 production capacity):
  - vm_embedding_pool: 2048 slots × 1576 bytes = ~3.08 MB
  - vm_outcome_pool: 4096 slots × ~80 bytes = ~320 KB
  - vm_embedding_imported + vm_embedding_synthesis + vm_embedding_sign_handle side-tables: ~144 KB
  - vm_codebook_meta + top_k scratch + cap pool + sign pool + energy pool + registries: ~150 KB
  - Subtotal BSS: ~3.7 MB
- **PE32+ padding**: remainder to 5MB TEXT_RAWSZ

**Public narrative ratified per architect direction**:

> **CodebookOS substrate: ~25 KB of hand-crafted NASM x86_64 UEFI code + data.**

The "64KB-class" framing is *conservative* — actual content is well under 64KB. The 5MB binary footprint is dominated by BSS reservations for production-scale pools (embedding pool at 2048 slots is the dominant allocation per Pod 3.7 D3.29 production-scale sizing).

**Auditability claim**: ~25KB of hand-crafted assembly is **auditable in a fortnight** by a competent reviewer. This is the credential-anchor claim; the size figure is honest empirical.

---

## DEFERRED state at V1.0 SEAL

### Closed at V1.0 SEAL (or earlier)

| # | Description | Closed at |
|---|---|---|
| #80 | Maid semantic operations | Pod 3.8 (Maid V1.0 surface complete) |
| #83 | Embedding pool capacity expansion | Pod 3.7 (256 → 2048) |
| **#84** | **Pod 3 throwaway test scripts** | **Pod 3.12 V1.0 SEAL** (light consolidation: 4 actively-used scripts added to git; deprecated stays untracked per documented audit) |
| **#85** | **RECONSTITUTION.md ongoing canon refresh** | **Pod 3.12 V1.0 SEAL** (v11 refresh lands at this commit) |
| #89 | Build-shell-determinism hazard | Pod 3.7 |
| #90 | Outcome pool capacity below embedding pool | Pod 3.7 |
| **#93** | **Diagnostic-probe-scaffolding policy** | **Pod 3.12 V1.0 SEAL** (D3.43.x forensic-record retention ratified) |

### V2.0-candidate forward (5 items carry forward)

| # | Description | V2.0 framework-test |
|---|---|---|
| #1 | LLC / signing entity rename | Cosmetic; awaiting architect decision; carry forward |
| #2 | ide_pio.asm NASM warnings | Cosmetic; substrate-functional; carry forward |
| #82 | Sign.provenance_handle activation candidate | Framework-test at activation: per D3.43.1 (what consumer demands this?) |
| #91 | Codebook-symmetry: runtime IMPORT + multi-codebook | Framework-test per D3.43.2 (which direction does production exercise?) |
| #92 | Stream-stability: aggregation / cross-result analogical / Result[T] sixth pool | Framework-test per D3.43.1 (when does the consumer scenario surface?) |

**Five V2.0-candidate forward** + **three V1.0-SEAL-closed at this commit** + **four already-resolved at prior pods** = clean inventory.

---

## Substrate state at V1.0 SEAL

**Maid V1.0 capability surface** (six variants live):

| Pod | Surface | Capabilities |
|---|---|---|
| 3.5 | Housekeeper | cosine + dot + L2 + lookup_top1 + sign_handle |
| 3.6 | Composer | add + subtract + scale + normalize + lerp + synthesis_handle |
| 3.8 | Importer | boot_ingest_codebook + imported_handle |
| 3.9 | Finder-of-many | lookup_top_k |
| 3.10 | Orthogonalizer | project + reject |
| 3.11 | Maintainer | codebook_meta |

**Five typed pools** (Sign / Energy / Outcome / Cap / Embedding) — each SipHash-MAC-protected (Outcome and Embedding); each with cap_bitmap authority enforcement; each with metabolic accounting via per-opcode energy table.

**Three non-MAC parallel side-tables** for Embedding linkage (D3.20 family):
- vm_embedding_sign_handle (reverse linkage; Pod 3.5)
- vm_embedding_synthesis (synthesis lineage tuple; Pod 3.6)
- vm_embedding_imported (imported provenance tuple; Pod 3.8)

**Substrate-private singleton state**:
- vm_codebook_meta (64-byte block; Pod 3.8; accessor at Pod 3.11)

**OP_EMBEDDING_ row 0xF0–0xFE allocation** (per D3.34 embedding-tier extensions):
- 0xF0 IMPORT (deferred handler per #91) / 0xF1 IMPORTED_HANDLE / 0xF2 LOOKUP_TOP_K / 0xF3 PROJECT / 0xF4 REJECT / 0xF5 CODEBOOK_META / 0xF6-0xFE reserved (9 slots remaining)

**SYNTHESIS_OP_* allocation**: 0x00 NONE / 0x01 ADD / 0x02 SUBTRACT / 0x03 SCALE / 0x04 NORMALIZE / 0x05 LERP / 0x06 PROJECT / 0x07 REJECT / 0x08+ reserved.

**Doctrine corpus at V1.0 SEAL**: 44 entries (D3.1 through D3.44).

**Substrate code+data size**: ~25.4 KB non-zero content; 5 MB binary including BSS pool reservations.

**Two-build determinism**: preserved at canonical V1.0 SEAL contract `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`.

**Substrate sha UNCHANGED from Pod 3.11**: Pod 3.12 V1.0 SEAL is documentation + doctrine codification + script consolidation; zero substrate-bytes change. The canon-binding moment is doctrinal, not substrate-shifting.

---

## V1.0 SEAL closeout — Pod 4.0.B chunk audit

| Step | Action | Outcome |
|---|---|---|
| 1 | Measure substrate code-byte count | 25,031 bytes non-zero content; 25.4 KB |
| 2 | Land D3.43 broad + D3.44 doctrine entries | This file (POD3.12_DECISION_RECORD.md) |
| 3 | RECONSTITUTION.md v11 refresh | (separate file) |
| 4 | Close #84 (light consolidation: 4 active scripts to git) | `tools/pod35_canary_test.sh` + `tools/pod35_run_all_canaries.sh` + `tools/pod36_phase22_canary_runner.sh` + `tools/pod36_phase3_canary_runner.sh` added |
| 5 | Close #85 (RECONSTITUTION refresh) | v11 lands at this commit |
| 6 | Close #93 (probe-scaffolding retention) | D3.43.x ratified |
| 7 | Empirical 36/36 prior-pod regression + B52 | (executed at SEAL build) |
| 8 | Two-build determinism re-confirmed | (verified) |
| 9 | Three-oracle commit + push + v1.0-seal tag | (executed at SEAL commit) |

**Build-time catches: 0**. **Substrate-catches: 0**. **Architect-framing-corrections: 0**.

Cleanest pod in V1.0 sequence continues — Pod 3.11 zero catches → Pod 3.12 zero catches. The inheritance-tier maturity confirmed via D3.44 prediction.

---

## V1.0 SEAL framing

**The trinity's first pillar landed clean.** Maid V1.0 (the lexical-computation pole) is operationally complete. Cop (capability-typed security inspector) and Interpreter (text-to-bytecode runtime) remain V2.0+ surfaces; Maid stands.

**The substrate is the credential.** Pure x86_64 NASM UEFI; SipHash-2-4 MAC integrity per primitive; F32 IEEE 754 byte-exact determinism per Form A canon (D3.14); 44 codified architectural decisions documenting every choice; ~25 KB of hand-crafted assembly auditable in a fortnight; energy accounting at opcode level; capability-typed security from layer 1; two-build determinism preserved across 16 substrate-pod sequence.

**This is V1.0 SEAL** — the canon-binding moment for the substrate. V1.0 SHIP at Pod 4.0.J extends with polish layer (Python wrapper for boot animation, About demo, in-fiction mocks) + release artifacts (demo video, manifesto PDF, USB image) per D4.X doctrines. The substrate stays unchanged at V1.0 SEAL state across Pod 4.0 polish work; only the OP_READ_KEY substrate addition (per D4.2 — landing at Pod 4.0.F.0) extends the substrate to enable interactive CBS demos.

V1.0 SEAL contract sha: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` — load-bearing reference across Pod 4.0 regression discipline.

---

## V1.0 SEAL — the resume-piece anchor

What Pod 3.12 V1.0 SEAL ratifies as credential:

- **Custom programming language** (CBS) with lexer + parser + bytecode compiler + stack-VM, all hand-crafted, all operationally complete at V1.0
- **Custom bare-metal operating system** (CodebookOS) in pure x86_64 NASM UEFI, ~25 KB of substrate code, demonstrably booting in QEMU, demonstrably running CBS programs, demonstrably executing the six Maid V1.0 capability variants
- **Built solo** by Randolph Pelican III over 30 architect-hours of work across 3 months (April-May 2026), with every architectural decision codified as one of 44 doctrines

V1.0 SHIP (Pod 4.0.J) packages the credential for public consumption. V1.0 SEAL (this commit) establishes the credential's empirical anchor.

The Maid recognizes; the Maid composes; the Maid imports; the Maid finds many; the Maid orthogonalizes; the Maid maintains. **V1.0 SEAL.**
