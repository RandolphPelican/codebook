# Pod 3.8 Decision Record — Maid imports (codebook ingestion + imported provenance)

**Pod:** 3.8 — second forge-tier substrate-USE pod; Maid V1.0 importer surface lands; substrate gains external-data-ingestion capability
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** 2026-05-09
**Entry contract:** 435e17eca9b9d26028e8a67c8fe411b727a762cc471a61d0fe1e3eb77bcbf36a (Pod 3.7 BOOTX64.EFI)
**Exit contract:** c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f
**Entry HEAD:** c53f651b145466bed5f67f605f787ae5d41d1256 (Pod 3.7 seal — substrate scales)

> Pod 3.8 lands the Maid's third surface — **importer** — alongside her existing housekeeper (Pod 3.5) and composer (Pod 3.6) capabilities. The substrate becomes able to ingest external semantic surfaces (sentence-transformer codebooks, word2vec dumps, plaintext line-per-vector files) at boot time and account for what it ingested architecturally (per-embedding MAC + non-MAC parallel imported-provenance side-table). Three new doctrine entries land: D3.30 (CBKBOK01 image format), D3.31 (boot-time substrate-private 0j ingestion), D3.32 (asymmetric write/read codebook surface). The closing arc — B48 — observes 5 boot-ingested embeddings through the dispatch-runtime accessor, byte-exact tuple readback + basis-vector readback, validating the end-to-end architectural arc empirically. Build-time catches: 2. Substrate catches: 0. The Maid imports.

---

## D3.30 — CBKBOK01 codebook image format

**Substrate-tool binary contract.** External embedding sources (sentence-transformer `.npy`, plaintext line-per-vector, raw float32 binary dumps) convert to substrate-loadable images via `tools/codebook_builder.py`. The format is a **build-time/substrate handshake**: build tool emits, substrate ingests; both sides share the format contract.

**Format (V1.0):**
```
+0x00  magic "CBKBOK01"        (8 bytes ASCII; little-endian u64 = 0x31304B4F424B4243)
+0x08  count                   (u64; number of embeddings)
+0x10  dim                     (u64; must equal EMBEDDING_DIM=384 in V1.0)
+0x18  scalar_type             (u32; 0 = f32 in V1.0)
+0x1C  reserved                (u32; 0)
+0x20  vector_block_offset     (u64; 0x40 in V1.0)
+0x28  vector_block_bytes      (u64; count × dim × 4)
+0x30  payload_hash            (16 bytes; SHA-256 of vector block, truncated)
+0x40  vectors[count][dim]     contiguous f32 little-endian, no per-embedding metadata
```

**Two-tier integrity model**:
- **Build-time integrity** via `payload_hash` (SHA-256-truncated; offline-verifiable; substrate does NOT validate this at boot — image hash is build-tool/CI artifact for transit-corruption detection)
- **Substrate-runtime trust** via per-boot SipHash-2-4 key applied per-embedding at ingestion (each forged embedding gets its own MAC stamped into `EMBEDDING_OFF_MAC`; substrate's two-build determinism contract extends to imported embeddings via this MAC stamping)

The decoupling is deliberate: build-tool format identity (SHA-256) is a different concern from substrate-runtime tamper-detection (SipHash MAC). Substrate doesn't trust the image at file-format level; it MACs each embedding individually as it imports, using its per-boot derived crypto state. **Two integrity tiers, two crypto algorithms, distinct concerns.**

**Empty-default convention**: when no codebook input is configured (no `inputs/codebook.txt`), `codebook_builder.py --empty` emits a valid CBKBOK01 image with `count=0`, `dim=384`, `scalar_type=0`, `vector_block_bytes=0`, `payload_hash = SHA-256(b"") truncated`. Substrate boots, ingests 0 embeddings, vm_embedding_next stays at 0. **This is the canonical Pod 3.8 substrate build state.**

**Architect-tool symmetry**: the format is the contract surface between `tools/codebook_builder.py` (Python build tool) and `boot/codebook.asm:boot_ingest_codebook` (NASM substrate helper). Both implementations reference the same offset constants from `boot/defines.asm` (`CBK_HEADER_OFF_*`, `CBK_HEADER_BYTES`, `CBK_MAGIC_QWORD`, `CBK_SCALAR_TYPE_F32`). Single source of truth for the layout; build-tool and substrate-runtime can never diverge by accident.

## D3.31 — Boot-time codebook ingestion as substrate-private 0j operation

**Substrate-private operation, parallel to `construct_root_cap` / `verify_root_cap_mac`.** Not bytecode-dispatched; runs at boot between cap-substrate init and bastian dispatch under implicit ROOT_CAP context (current_cap_id=1 from boot init). 0j per D3.10 substrate-bookkeeping doctrine — codebook ingestion is substrate setup, not user-program work.

**Discovery moment (sit-time recon)**: the architectural premise that Pod 3.6/3.7 had "boot-time codebook ingestion via bytecode dispatch" as an implementation detail was wrong — substrate has no such mechanism. R1 oracle pre-flight at 3.8.A surfaced that `efi_entry` does NOT execute bytecode before user-program payload; bytecode dispatch happens only in response to user input via `bastian_home`'s `.go_atreyu` / `.go_rockbiter` / `.go_gmork` keystroke handlers (each setting r14=1M and calling `cbs_run` per-launch). D3.31 names the gap and adds the discipline: codebook ingestion is **substrate-private**, parallel to the existing boot-time helpers (construct_root_cap, verify_root_cap_mac, derive_siphash_key).

**Implementation** (`boot/codebook.asm:boot_ingest_codebook`):
1. Read CBKBOK01 image header from `codebook_image_start` (extern from `boot/codebook_data.asm`; auto-generated by `codebook_builder.py` at every build)
2. Validate magic == `CBK_MAGIC_QWORD` (FATAL on mismatch with `auryn_puts` diagnostic + `cli/hlt/jmp $`)
3. Validate dim == EMBEDDING_DIM and scalar_type == CBK_SCALAR_TYPE_F32 (FATAL on either mismatch)
4. For i in 0..count-1: inline alloc + cap-cache writes (ROOT arena/owner/creator) + `rep movsb` 1536-byte vector + `registry_register_embedding` + id-stamp + `siphash_compute` MAC + `vm_embedding_imported` tuple write at `(id-1) * 32` with `(codebook_id=1, line_index=i, 0, 0)`
5. On success: write `vm_codebook_meta` with count, dim, scalar_type, status=CBK_STATUS_SUCCESS, payload_hash (16 bytes from header)
6. On capacity exhaustion: FATAL with CBK_STATUS_ERR_POOL_FULL

**Boot-time forge path shares no code with `OP_EMBEDDING_NEW` handler** — the helper is a forge-path *peer* of the dispatched handler, not a caller of it. No `.construct_ok_outcome` wrap (no Outcome production at boot), no `babylon_charge_lineage` ripple (substrate-private 0j), no `babylon_check_authority` bit-check (boot-time runs unconditionally), no fetch counter increment, no cost-table drain. Concrete validation of the "substrate-private 0j" framing.

**EFI entry insertion point** (`boot/boot.asm`): immediately after `call verify_root_cap_mac` and before `mov qword [rel vm_phase], VM_PHASE_FORM`. Cap substrate fully initialized; framebuffer/GOP ready (post-`locate_gop`); `auryn_puts` callable for FATAL diagnostics. Sequenced in canonical efi_entry order.

**Empty-codebook compatibility**: `count=0` skips the loop entirely, writes meta with status=success, vm_embedding_next stays at 0. **Canonical Pod 3.8 substrate build (no codebook input configured) preserves prior-pod canary behavior byte-exact** — empirically validated 52/52 across Pod 3.5 (29) + Pod 3.6 (20) + Pod 3.7 (3) at canonical contract. Substrate-USE + substrate-EVOLUTION simultaneity holds even when substrate gains a new boot-time code path.

## D3.32 — Codebook write/read surface asymmetry at V1.0

**The codebook surface is asymmetric at V1.0.**

| Direction | Mechanism | Authority | Cost | Ops |
|---|---|---|---|---|
| **Write** | substrate-private boot-time | implicit ROOT_CAP | 0j (D3.10) | `boot_ingest_codebook` (single internal helper) |
| **Read** | dispatch-runtime user program | per-current-cap | 1j per accessor call | `OP_EMBEDDING_IMPORTED_HANDLE` (0xF1) + `OP_EMBEDDING_GET_DIM` (0xC4) |

**Write-path** is purely substrate-private. No user program can forge an imported embedding at runtime — only boot-time substrate-internal `boot_ingest_codebook` does the work. `OP_EMBEDDING_IMPORT` (0xF0) constant exists (pre-landed at 3.8.E for paired-commit cleanliness) but **no handler is implemented at V1.0** — opcode space reserved for hypothetical Pod 3.9+ runtime codebook forge (dynamic reload, multi-codebook ingestion at runtime, etc.) without committing to the design now.

**Read-path** is fully dispatch-runtime: any user program can read imported provenance via `OP_EMBEDDING_IMPORTED_HANDLE` (witness accessor; D3.13 inheritance — no bit-check; no forge bit required) and read vector dims via the existing `OP_EMBEDDING_GET_DIM` (Pod 3 substrate-prep accessor). The accessor surface is identical to other typed-pool accessors.

**Asymmetry rationale**: codebook ingestion is a *deployment-time* concern (which embeddings does this substrate carry?) rather than a *runtime* concern (what does this user program want to do?). Production scenarios match this: a substrate is deployed with a pre-baked codebook for its production lifetime; user programs query the codebook but don't extend it at runtime. Symmetric expansion (runtime forge from operand-stack codebook references) would be a Pod 3.9+ feature when production demands it; V1.0 ships the cleaner asymmetric form.

**Doctrinal precedent**: parallels Pod 1's approach to typed primitives (substrate provides the construction primitive; user programs use it via dispatch). Codebook surface at V1.0 is "substrate-built-in", not "user-extensible-at-runtime" — same flavor as how `construct_root_cap` is substrate-internal but `OP_CAP_NEW` is dispatch-runtime.

---

## Q-rating ratifications (Pod 3.8.A pre-flight + audit)

| # | Question | Ratified |
|---|---|---|
| **Q1** | CBKBOK01 image format (64-byte header + contiguous f32 block; SHA-256-truncated payload hash for build-time; per-boot SipHash MAC for runtime) | ✓ ratified per D3.30 |
| **Q2** | Memory placement (option (c) ingest-into-pool-at-boot; size cap ≤1500 to leave runtime synthesis headroom) | ✓ ratified |
| **Q3** | Authority bit (reuse BIT_EMBEDDING_FORGE; no new BIT_EMBEDDING_IMPORT; FORGE-without-IMPORT split deferred per D2.2 organic vocabulary growth) | ✓ ratified |
| **Q4** | Imported provenance side-table (Layout-2 quad-tuple matching synthesis: codebook_id / line_index / reserved_hash / reserved_timestamp; 32 bytes/slot; 64 KB BSS) | ✓ ratified |
| **Q5** | Opcode allocation (0xF0–0xFE row, NOT 0xD0–0xDF — Energy occupies 0xD0–0xD8) | ✓ ratified with framing correction |
| **Q6** | Forge-path adaptability (mirror OP_EMBEDDING_NEW shape via substrate-private clone; ~150-line helper; no cross-pod fork) | ✓ ratified |
| **Sub-Q1** | Production codebook size target ≤1500 entries at V1.0; >1500 deferred to Pod 3.9+ option (a)/(b) memory placement | ✓ confirmed |
| **Sub-Q2** | Codebook image hash/timestamp populated at V1.0 vs reserved | ✓ reserved (V1.0 minimum) |
| **Sub-Q3** | Boot-time ingestion mechanism — bytecode dispatch vs direct internal call | ✓ Path β (substrate-private direct call) per D3.31 |

---

## 3.8.A–3.8.G chunk audit

| Chunk | Identity | Contract | Catches |
|---|---|---|---|
| 3.8.A | Pre-flight + audit (no code) | n/a (Pod 3.7 base 435e17ec) | Init-phase recon catch (Path β surfaced; Q5 row collision; Pod 3.7 PNG count) |
| 3.8.B | Build tool + image format | n/a (build-tool only) | TB first-run catch: path-as-determinism-axis (different output paths produced different incbin strings) |
| 3.8.C | BSS allocation + constants | `d3de953a802208eff602cb7110c180cf200da1b0fe11b2628ab495115d2ac6c2` | 0 |
| 3.8.D | boot_ingest_codebook helper | `b930930369acea3912928f3f50cf3edd8f9b1494ed3a5d7cd0aaf97813c672e4` | section/global directives broke flat-binary mode |
| 3.8.E | OP_EMBEDDING_IMPORTED_HANDLE accessor | `f7bf286409d9db7291bd7e5b2931b34bfc73091ede29c314917a3d12740dc672` | 0 (Layout-2 inheritance pattern verified) |
| 3.8.F | build.sh integration + boot path call | `c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f` | filename collision (codebook_builder.py overwrote helper file) |
| 3.8.G | B48 boot-ingestion canary | `c09f2b3c…` (canonical preserved) | 0 (B48 PASS empirically; 5/5 imported embeddings observable) |
| **SEAL** | canonical contract preserved | `c09f2b3c449d9b32861b9ee3a1af85af3ccfba35224ccd05acb7a1ba72adb11f` | — |

**Build-time catches: 2** (section/global directives at 3.8.D; filename collision at 3.8.F). **Substrate-catches: 0** — both build-time issues caught by NASM at assembly, not by canary regression. Pattern matches Pod 3.7's mechanical-pod prediction shape: substrate behavior holds; integration-layer issues surface at build dispatch.

**Architect-framing-corrections count: 2**:
- 3.8.A Q5 row collision: architect's suggested 0xD0–0xDF row overlaps Energy ops (0xD0–0xD8); recommended 0xF0–0xFE (clean row, 15 unallocated slots) → ratified
- 3.8.C Pod 3.7 PNG count: architect referenced "5/5" but actual is 3/3 (B43+B44+B45 produce PNGs; B46 is regression-only; B47 is host-side text-log) → corrected in chunk close

---

## B48 boot-ingestion canary (3.8.G)

**Substrate built with `inputs/test_codebook_b48.txt`**: 5 basis-vector entries × 384 dims (entry i has `dim (i-1) = 1.0`, all other dims = 0). Auxiliary substrate sha (NOT canonical SEAL contract): `a481333fde4d589e1df67506a2e9a9c96e9714da06e4a9a8a21604ddc2663497` (two-build deterministic).

**Empirical (verbatim screen output):**
- 25 IMPORTED_HANDLE tuple-field readbacks: codebook_id=1 / line_index=i-1 / reserved_hash=0 / reserved_timestamp=0 — **byte-exact** for all 5 entries
- 5 GET_DIM vector readbacks: dim[i-1] = `0x3F800000` = 1.0 for each entry's basis dim — **byte-exact**
- 30 total dispatch-surface observations; all 30 match expected
- Energy: 296j used (witness-op cost-table shape per D3.13 confirmed)

**Doctrine-empirically-validated framing:**
- D3.31 confirmed via two paths:
  - **52/52 prior-pod canaries × empty-codebook canonical build**: substrate-USE + substrate-EVOLUTION simultaneity holds when substrate gains substrate-private boot-time path; user programs see no observable effect from the new code path running 0-iteration loop
  - **B48 dispatch-surface observation × 5-entry codebook auxiliary build**: ingested embeddings observable via standard accessor convention with byte-exact provenance + content fields
- D3.30 CBKBOK01 format functional end-to-end: build-tool emit → substrate validation → embedding pool population
- D3.32 asymmetric write/read confirmed: substrate-private write (0j boot-time); dispatch-runtime read (1j-per-accessor)

**Pod 3.8 architectural arc complete**: external embedding source → CBKBOK01 image → substrate-private boot ingestion → dispatch-runtime accessor. The Maid V1.0 surface gains its third capability: housekeeper (3.5) + composer (3.6) + **importer (3.8)**.

---

## Naming-discipline lesson (3.8.F)

**Build-tool output base must not collide with hand-written canon filenames in the same directory.**

At Pod 3.8.F first build, `codebook_builder.py` invoked with output base `boot/codebook` auto-generated `boot/codebook.bin` + `boot/codebook.asm` — but `boot/codebook.asm` was the hand-written helper file from 3.8.D. NASM caught the collision via "label codebook_image_start inconsistently redefined" (both files defined the same labels). Fix: changed build.sh output base to `boot/codebook_data` so generation lands at `boot/codebook_data.{bin,asm}`. Helper file (`boot/codebook.asm`) stays distinct from auto-generated data file (`boot/codebook_data.asm`).

**Forward pattern**: when a build-tool emits assembly artifacts into the substrate's source tree, the output base should be visibly distinguishable from hand-written .asm filenames. Suffix conventions like `_data` / `_generated` / `_auto` make the intent obvious. **Doctrine refinement candidate at future pod if it recurs** — for now, single empirical occurrence; not yet promoted to formal doctrine.

---

## DEFERRED state

| # | Description | Status |
|---|---|---|
| #80 | Maid semantic operations (Pod 3.5+) | **FULLY RESOLVED** at Pod 3.8 — Maid V1.0 surface complete (housekeeper + composer + importer) |
| #82 | Sign.provenance_handle activation candidate | unchanged |
| #83 | Embedding pool capacity expansion | RESOLVED at Pod 3.7 (256 → 2048) |
| #84 | Pod 3 throwaway test scripts | continues; Pod 3.8 adds 3 scripts (`gen_b48_codebook.py` + `pod38_b48_runner.sh` + `codebook_builder.py` is canonical though, not throwaway) |
| #85 | RECONSTITUTION.md ongoing canon refresh | unchanged |
| #89 | Build-shell-determinism hazard | RESOLVED at Pod 3.7 |
| #90 | Outcome pool capacity below embedding pool | RESOLVED at Pod 3.7 |
| #91 | Codebook-symmetry: runtime OP_EMBEDDING_IMPORT (0xF0) handler activation | **NEW** — 0xF0 opcode reserved at Pod 3.8 (constant landed; handler deferred); future-pod activation when production scenarios demand runtime codebook forge |

**One new deferral logged at Pod 3.8 (#91 codebook-symmetry).**

---

## Substrate state at SEAL

**Five typed pools** (Sign / Energy / Outcome / Cap / Embedding) — unchanged from Pod 3.7.

**Three non-MAC parallel side-tables** for Embedding linkage (D3.20-generalized convention; D3.29 axis-2 mechanical sizing):
- `vm_embedding_sign_handle` (Pod 3.5 D3.20) — Embedding→Sign reverse linkage; 16 KB
- `vm_embedding_synthesis` (Pod 3.6 D3.26) — Embedding→synthesis-lineage tuple; 64 KB
- `vm_embedding_imported` (Pod 3.8 D3.32) — Embedding→imported-provenance tuple; **64 KB (NEW)**

Total parallel side-table BSS: 144 KB. All three sized to `EMBEDDING_POOL_SLOTS=2048` via shared constant per D3.29 axis-2; cascade automatic.

**Substrate-private state cache** (Pod 3.8 NEW): `vm_codebook_meta` (64-byte block) holds count / dim / scalar_type / ingestion_status / payload_hash for diagnostic / audit visibility post-boot. Populated by `boot_ingest_codebook` on success; status = CBK_STATUS_* on FATAL paths.

**OP_EMBEDDING_ row 0xF0–0xFE allocated**:
- 0xF0 OP_EMBEDDING_IMPORT — constant reserved; handler deferred (DEFERRED #91)
- 0xF1 OP_EMBEDDING_IMPORTED_HANDLE — witness accessor live (Pod 3.8.E)
- 0xF2–0xFE — reserved for codebook-tier future expansions

**Maid V1.0 surface complete**: housekeeper (Pod 3.5: cosine + dot + L2 + lookup_top1 + sign_handle) + composer (Pod 3.6: add + subtract + scale + normalize + lerp + synthesis_handle) + **importer (Pod 3.8: boot_ingest_codebook + imported_handle)**. Three capabilities lateralizing the lexical-computation pole; codebook surface asymmetric at V1.0 (substrate-private write + dispatch-runtime read per D3.32).

**Build-pipeline integrity** (Pod 3.7 D3.29 axis-1 + DEFERRED #89):
- NASM 2.16.01 + mtools 4.0.43 pinned at absolute path + version-grep
- B47 build-system canary class verifies fail-loud guards
- Pod 3.8 adds: `codebook_builder.py` integration in build.sh (graceful empty-default; CODEBOOK_INPUT env var configurable); auto-generation overwrites `boot/codebook_data.{bin,asm}` at every build

**Two-build determinism** preserved at canonical Pod 3.8 SEAL contract `c09f2b3c…`.

**Pod 3.8 architect-error catches**: zero substrate. Two build-time integration catches (NASM-caught at assembly; not substrate-behavior). Mechanical-pod prediction holds; the empirical pattern from Pod 3.7 transfers — substrate-EVOLUTION pods cluster catches at the build-pipeline integration layer rather than substrate-behavior surface.

---

## V1.0 progress checkpoint

**Pod 3.8 = 2 of 6 V1.0 pods sealed.** Pods 3.9 / 3.10 / 3.11 / 3.12 remain.

The Maid composes; the Maid imports; the substrate accounts for what it imported. **The substrate's lexical-computation pole reaches operational completeness at V1.0** — housekeeper recognizes, composer creates, importer ingests. What remains for V1.0 is broader architectural surface (substrate features beyond Maid's specific lexical scope — exact framing deferred to Pod 3.9 architectural sit).
