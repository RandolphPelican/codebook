# Architecture

CodebookOS is built as a substrate of **five typed primitives** orchestrated by a **stack-VM** that dispatches **energy-accounted opcodes**, with a **capability framework** that bounds every authority-bearing operation. This document traces those structures: the mythology that names them, the typed primitives that ground them, and the doctrinal corpus that constrains every decision.

V1.0 SEAL substrate contract: `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`.

---

## 1. Mythology and surface ecology

The substrate's named surfaces honor *The Neverending Story*. Each name is load-bearing — when a Gmork command says "auryn" or "morla", the architect-team can locate the responsible NASM file at a glance, and the API discipline (capability tokens, doctrine annotations) flows from the name.

### V1.0 surfaces (built; canary-verified)

| Surface | Role | NASM source | V1.0 status |
|---|---|---|---|
| **Bastian** | Home screen — the boy who reads | `boot/bastian.asm` | ✅ Live; first thing the user sees |
| **Gmork** | Terminal shell — interpreter of the dark | `boot/gmork.asm` | ✅ Live; ~15 commands; CAP_GMORK_CONIN exposed |
| **Auryn** | Display / framebuffer — the amulet that protects | `boot/auryn.asm` | ✅ Live; CAP_AURYN_DISPLAY exposed |
| **Morla** | Filesystem — the ancient turtle who knows | `boot/morla.asm` | ✅ Live; CAP_MORLA_FS exposed |
| **Rockbiter** | Energy introspection — "good strong stones" | substrate-internal | ✅ Live; CAP_ROCKBITER exposed (budget/used) |
| **Maid** | Lexical-computation pole — 6 capabilities | `boot/maid.asm` | ✅ Complete (housekeeper + composer + importer + finder-of-many + orthogonalizer + maintainer) |
| **Babylon** | Spatial-merge metabolism — federation accounting | `boot/babylon.asm` | ✅ Live; activates on every Outcome forge |
| **CBS / Atreyu** | Programming language + compiler | `tools/atreyu_x86.py` + `boot/cbs_vm.asm` | ✅ Live; 6 canary demos verify it |
| **Empress / capability framework** | ROOT_CAP + cap_stack + cap_graph | `boot/cap.asm` | ✅ Live (V1.0 surface: grant + use + lineage; revoke deferred) |
| **Koreander** | Bookmaster — codebook ingest at boot | `boot/codebook.asm` | ✅ Live; CBKBOK01 format; boot-time D3.31 |

### V2.0 carry-forward surfaces (designed; deferred)

| Surface | Role | Why V2.0 |
|---|---|---|
| **Cop** | Capability inspector — trinity pillar 2 | Renamed from earlier Cop to Babylon for spatial-merge; the *inspection* layer over capabilities defers to V2.0 |
| **Interpreter** | Text-to-bytecode at runtime — trinity pillar 3 | V1.0 ships ahead-of-time compiled `.cbc`; runtime IMPORT (#91) is V2.0 |
| **Falkor** | Web browser surface (in-fiction mock at V1.0) | Polish-tier mock in `polish/falkor_browser.py`; substrate API deferred |
| **Atreyu (editor)** | Code editor surface (in-fiction mock at V1.0) | Polish-tier mock in `polish/atreyu_editor.py`; substrate API deferred |
| **Rockbiter (scheduler)** | Process scheduler (in-fiction mock at V1.0) | Polish-tier mock in `polish/rockbiter_scheduler.py`; substrate API deferred |
| **Demod-tier surfaces** (0xE8-0xEF reserved) | Stream-stability / aggregation ops | Result[T] sixth pool deferred per D3.43 framework |
| **Southern Oracle / Artax / Empress (live)** | Designed but not surfaced | V2.0 |

The trinity — **Maid (lexical) + Cop (inspection) + Interpreter (runtime translation)** — completes at V2.0. V1.0 ships one of three pillars complete; that's honest scope, codified per **D3.43 V1.0-deferral framework**.

---

## 2. The five typed primitives

Every value in CBS that has identity is one of five types. Each lives in a pre-allocated pool with bounded capacity; each has a MAC (Message Authentication Code) guarding integrity where applicable; each has its own opcode row in the dispatch table.

### Sign — declarations of intent

A Sign is the substrate's first-class **declaration object**. It carries:
- An associated Energy reference (the metabolic budget for actions taken under this Sign)
- A SipHash MAC over its fields
- An embedding_handle pointing into the Embedding pool (the "meaning" of the Sign)
- An owner cap_id and arena (provenance per D1.10.2b2.1)

**Pool**: 256 slots (D3.16 anticipated-empirical-pressure expansion).
**Opcodes**: 0xA0-0xAF row.
**Governing doctrines**: D3.4 (embedding linkage via parallel side-table), D3.20 (reverse side-table), D1.8.5c (Sign slot reclamation).

### Energy — metabolic budget

Energy is **non-renewable spending capacity** for opcodes. Every opcode declares its cost in joules; the VM decrements `r14` (the active budget register) at each dispatch; depletion triggers graceful HALT.

**Fields**: joules, source_op, owner cap_id.
**Pool**: 256 slots.
**Opcodes**: 0xA8-0xAF row.
**Governing doctrines**: D3.17 (anticipated-worst-case static costing), D3.24 (metabolic ceiling scales with op tier), D1.8.5b.8 (energy_free is V1.0 no-op).

### Outcome — `Ok<T> | Err`

The substrate's **error-handling primitive** — a tagged union over typed Ok payloads (with `value_type_id` discriminant) and standardized 32-byte error contexts.

**Fields**: tag, value_type_id, payload (24 bytes), error_context_id (when err).
**Pool**: 256 slots.
**Opcodes**: 0xE0-0xE6 row.
**Governing doctrines**: D1.9.1.1 (tagged Outcome with discriminant), D1.9.1.2 (32-byte error context), D1.9.3.1 (refit scope under Path A), D3.36 (variable-cardinality output convention).

Every multi-result operation in V1.0 returns Outcome. Pop the Outcome, branch on `outcome_is_ok`, unwrap accordingly. There is no exception system, no error-by-side-channel.

### Cap — capability tokens

Cap is the **authority primitive**. Every action that touches restricted resources (forging primitives, dispatching I/O, capability creation itself) checks the active cap's bitmap and energy budget. Caps form a tree rooted at ROOT_CAP (cap_id=1, unbounded). Each child cap is forged via `cap_new` with subset-on-grant semantics.

**Fields**: bitmap (capabilities), energy_budget, energy_used, arena, owner cap_id, parent cap_id, MAC over 6 fields.
**Pool**: 256 slots.
**Opcodes**: 0xB0-0xBF row.
**Governing doctrines**: D1.10.1.1 (Cap slot layout), D1.10.1.7 (SipHash-2-4 over 6 fields), D2.2.5 (subset-on-grant), D2.1.4 (ROOT_CAP federation total), D1.10.3.3 (unbounded ROOT_CAP).

### Embedding — vector representations

Embedding is the **semantic primitive**: a 384-dimensional f32 vector with a MAC over the full vector body (D3.3). This is the substrate's interface to high-dimensional meaning — cosine similarity, geometric projection, lookup against a boot-ingested codebook.

**Fields**: 384 × f32 (1,536 bytes), MAC, owner cap_id, synthesis tuple (for composed Embeddings) or imported handle (for codebook-derived Embeddings).
**Pool**: 256 slots.
**Opcodes**: 0xC0-0xCF + 0xF0-0xF5 rows.
**Governing doctrines**: D3.1 (Embedding as fifth typed primitive), D3.2 (canonical V1.0 dim 384), D3.3 (full vector under MAC), D3.12 (SSE-scalar single-precision only), D3.14 (cosine canonical Form A), D3.27 (synthesis tuple Layout 2), D3.28 (FP frontier doctrine), D3.34 (0xF0-0xFE row reservation), D3.35 (top_k as housekeeper-tier generalization), D3.38 (project-reject duality), D3.40 (hybrid IEEE-degeneracy convention).

---

## 3. The CBS execution model

CBS programs compile to flat bytecode (one byte per opcode, operands follow per opcode shape). The VM is a stack machine with:

- **Stack** (`vm_stack`): general computation
- **Return-address stack** (`vm_ret_stack`): for OP_CALL / OP_RET
- **Capability stack** (`cap_stack`): tracks active cap context for cap_enter / cap_exit
- **Active budget register** (`r14`): joules remaining for the current cap context
- **Active cap context** (`r15` / `current_cap_id`): which cap's authority applies right now

### Dispatch loop (boot/cbs_vm.asm:.fetch)

```
1. Read 1 byte from PC; advance PC
2. Look up opcode in dispatch table
3. Look up cost in cost table
4. r14 -= cost
5. If r14 < 0: graceful HALT (energy depleted)
6. Jump to handler
7. Handler executes; returns to .fetch
```

Every opcode either succeeds, returns an Outcome::Err and continues, or HALTs the program. No undefined behavior; no silent corruption; every step bounded.

### Capability dispatch (OP_USE_CAP at 0x91)

Operands: token (u64) + cmd (i64) + optional args[].
- Token matches one of 4 V1.0 capability constants (0xCA000001..0xCA000004)
- Active cap must hold the bit for that capability (D2.2.5 subset-on-grant)
- Cap budget must cover the cost
- Dispatch to handler (.cap_auryn / .cap_conin / .cap_morla / .cap_rockbiter)

This unification is D4.2 — capability-tokenized I/O surface. Every external interaction goes through one opcode (0x91); the dispatch table for capabilities is a flat enum; new surfaces in V2.0 add new tokens without new opcodes.

---

## 4. The 44-doctrine corpus — load-bearing doctrines

44 codified architectural decisions through V1.0 SEAL, plus 6 D4.X doctrines through V1.0 SHIP. Not all are equal weight; the following are the load-bearing ones — the ones that, if reversed, would cascade.

### D1.X — substrate plumbing era (Pods 1.x)

- **D1.9.1.1** — *Tagged Outcome with `value_type_id` discriminant*. Outcome carries type information; the substrate distinguishes Ok<Sign> from Ok<Cap>. Foundation for every error path that follows.
- **D1.10.1.1** — *Cap slot layout (128-byte symmetric, no mirror fields)*. Cap pool layout drives MAC signature, parent walks, and bitmap checks. Reverse this and every Cap operation breaks.
- **D1.10.1.7** — *SipHash-2-4 over 6 u64 fields*. Universal MAC convention; all four MAC-bearing primitives (Sign, Outcome, Cap, Embedding) use this signature.
- **D1.10.2a.2** — *RDSEED → RDRAND → hard-fail-and-halt policy*. Substrate-secret bootstrap; if both fail, refuse to boot rather than ship a fixed secret.
- **D1.10.2b1.9** — *Substrate witnesses its own authority context for the first time*. cap_current, cap_arena, cap_owner activate the dormant arena/owner fields in earlier primitives.

### D2.X — Babylon spatial-merge era

- **D2.1.4** — *ROOT_CAP accumulates federation total*. Every Outcome forge anywhere ripples energy_used up the cap tree to ROOT_CAP. Substrate-wide accounting in one place.
- **D2.2.1** — *cap_bitmap structured semantics: texture as physics*. Each bit is a granted-or-denied capability; bitmap operations are bitwise AND/OR for subset checks.
- **D2.2.5** — *Subset-on-grant capability-correctness invariant*. `cap_new` cannot grant a bit the parent doesn't hold. Standard cap-system invariant; enforced at forge.

### D3.X — Embedding + Maid V1.0 era

- **D3.1** — *Embedding as fifth typed primitive*. The decision to give meaning a first-class pool, rather than treating embeddings as arrays.
- **D3.2** — *Canonical V1.0 dimension EMBEDDING_DIM = 384*. All-MiniLM-L6-v2 dimensionality; production-realistic ML embedding size.
- **D3.3** — *Full vector under MAC protection*. The 1,536-byte vector body is part of the MAC input. Mutate one f32, the MAC breaks.
- **D3.12** — *FP determinism doctrine: SSE-scalar single-precision only*. No x87 80-bit; no AVX2 reorderings under user control; movss/mulss/addss only. Foundation of F32 byte-exact determinism.
- **D3.14** — *Cosine canonical Form A; bit-exact load-bearing*. The order of accumulation in dot-product reductions is fixed. Same vector → same f32 bits, every run, every architecture (when ported).
- **D3.17** — *Static worst-case costing for compute composites*. Cosine = 400j, lookup_top1 = 100,000j, etc. — anticipated worst-case, not measured. Substrate prefers fixed pricing over per-pod re-tuning.
- **D3.25** — *Forge-tier introduction; Maid as lexical-computation pole; Trinity-naming canonization*. The cognitive trinity gets its names here; Maid claims the lexical pole.
- **D3.28** — *The project learns how to learn from its FP frontier*. Form A discipline + hybrid IEEE-degeneracy convention + canary self-verification.
- **D3.30** — *CBKBOK01 codebook image format*. Boot-time ingestion of embedding sets from a known file format; substrate-private 0j operation.
- **D3.37** — *NASM RIP-relative indexed-BSS-access discipline*. `[rel sym + reg*scale]` silently miscompiles in NASM `-f bin` mode; correct form is `lea reg, [rel sym]; [reg + idx*scale]`. Substrate-catch that surfaced from a 6-probe diagnostic chain in Pod 3.9.
- **D3.38** — *Project-Reject duality as orthogonalization primitive pair*. Both ops at 1500j (`proj_v u = ((u·v)/(v·v)) v`; `reject_v u = u - proj_v u`).
- **D3.40** — *Hybrid IEEE-degeneracy convention extension*. Zero-norm vectors and clean-cancellation regimes both fold to byte-exact 0.0; documented as canonical for orthogonality verification.
- **D3.43** — *V1.0-deferral framework (broad)*. Carries V2.0 work-items through framework tests at activation time; honest "not yet" rather than vague "future work."
- **D3.44** — *Catch-surface-migration tri-tier doctrine*. Architectural decisions land at one of three tiers: substrate (highest-stakes), inheritance (medium), polish (lowest). Catches above this expected tier are signal; catches at-or-below the expected tier are noise.

### D4.X — V1.0 SHIP polish-layer era

- **D4.1** — *Polish-vs-credential separation (canonical-anchor D4.X)*. `boot/ + surfaces/ + tools/` = credential; `polish/` = showroom. Two directories, two disciplines. The substrate sha must not change during polish work; this is empirically verified across Pod 4.0.C onward as the **D4.1 byte-lock**.
- **D4.2** — *Capability-tokenized I/O surface*. Every CBS interaction with substrate services goes through OP_USE_CAP with one of 4 tokens. New surfaces add new tokens, not new opcodes.
- **D4.3** — *Boot animation discipline*. Polish animations live in `polish/`; render to MP4 via FFmpeg + PIL; share `polish/common/` (tricolor + scaled_font + widgets + frames protocol).
- **D4.4** — *In-fiction surface discipline*. Surfaces that don't ship at V1.0 (Falkor, Atreyu editor, Rockbiter scheduler) get polish-layer mocks for the demo video. The mock is honestly framed as in-fiction.
- **D4.5** — *Demo-program discipline*. The 6 V1.0 canary demos exercise the full Maid V1.0 surface + 4 capability tokens + Outcome unwrap + cap lifecycle. Real CBS, byte-exact verified.
- **D4.8** — *Polish-layer verification discipline*. Tier 1 = byte-exact (substrate canaries only). Tier 2 = output-existence + format-sanity + sampled-decode (polish artifacts). Honest about what polish artifacts can and can't guarantee.

For the **full** corpus, each pod's decision record (`recon/POD*_DECISION_RECORD.md`) carries every doctrine landed in that pod with rationale, alternatives considered, and empirical landings.

---

## 5. The polish layer (D4.1 separation)

`polish/` is a Python directory tree, structurally separate from the substrate. Its purpose is to make the credential **legible** for non-technical reviewers in 90 seconds. It does not run on the substrate; it does not affect substrate behavior; it does not change the substrate contract sha.

```
polish/
├── common/
│   ├── tricolor.py        Pelican III red/gold/green metallic gradient
│   ├── scaled_font.py     8x8 bitmap font with scaling
│   ├── widgets.py         Cell / Banner / IconStub / ScrollFrame
│   └── frames.py          Animation protocol; PyGame live + FFmpeg export
├── boot_anim.py           10s — searchlights → PELICAN III tricolor → CODEBOOKOS
├── about_codebookos.py    45s — narrative scroll, 6 sections
├── falkor_browser.py      15s — in-fiction web browser surface (V2.0)
├── atreyu_editor.py       15s — in-fiction code editor surface (V2.0)
├── rockbiter_scheduler.py 15s — in-fiction scheduler surface (V2.0)
├── build_demo_video.py    90s master video composer (FFmpeg orchestration)
├── dist/
│   └── codebookos_v1.0_demo.mp4  9.4 MB; 90s; h264+yuv420p; 1280x720
└── test/                  pytest harness — 47/47 PASS
```

The **D4.1 byte-lock** is empirically verified: 8+ consecutive substrate-touch-free chunks during Pod 4.0 polish work, every chunk closing with the V1.0 SEAL sha unchanged. The boundary holds.

---

## 6. Doctrine corpus discipline

Every architectural decision lands as a doctrine in a pod's decision record. Decisions are:

1. **Codified** before implementation when possible (HALT 1 pattern: question raised, architect ratifies, doctrine landed before any code).
2. **Empirically verified** at canary stage (each pod's last chunk runs a B5X canary that byte-exact-verifies the doctrine's claims about substrate behavior).
3. **Numbered globally** (D1.X through D4.X) so cross-pod references work mechanically.
4. **Cited at use** — code comments cite the governing doctrine (e.g., `; D3.14 Form A`).

This corpus is the substrate's audit trail. A reviewer reading `recon/` in chronological order sees every architectural decision in the order it was made, the alternatives considered, and the empirical evidence that ratified it. The 30-architect-hour buildout is reproducible in concept because every decision is preserved.

---

## 7. Substrate determinism

Two-build determinism: assembling `boot/boot.asm` twice with the same NASM version produces byte-exact identical `BOOTX64.EFI`. The build script verifies the V1.0 SEAL contract sha at every build.

Verified across 16 substrate-pod chunks (Pod 3.0 through Pod 3.12 SEAL), then frozen at V1.0 SEAL. The D4.1 byte-lock extends this guarantee through V1.0 SHIP: no polish-tier work has touched substrate bytes.

F32 IEEE 754 byte-exact determinism: every f32 op in the Maid V1.0 surface uses Form A canonical evaluation order (D3.14). The same input vector produces the same f32 bit pattern across runs, builds, and architectures (when ported). Verified per canary (B53 fib energy trace + B58 drift anchor + B55 vector composer all rely on byte-exact f32 results).

---

## 8. Energy as the substrate's metabolism

Every opcode has a cost in joules. Every cap context has a budget. Every Outcome forge ripples energy_used up the cap tree to ROOT_CAP. The substrate **cannot** execute beyond a cap's budget; depletion HALTs gracefully.

This is the substrate's primary safety property. A misbehaving (or malicious) CBS program **cannot** run away — its cap budget runs out, the program HALTs, and the rest of the substrate continues. The ROOT_CAP's federation total tracks aggregate consumption across all child caps, making system-wide energy accounting visible at one slot.

D3.17's anticipated-worst-case costing means the budget is a **conservative ceiling** — actual machine work may be less than the budget asks. The substrate trades cost-table precision for never-undershooting; an op that finishes early returns the (small) unused remainder to the cap implicitly via the active register.

---

## 9. What this isn't (honest scope)

CodebookOS V1.0 is **not**:

- **A general-purpose OS.** No process scheduler, no virtual memory, no syscall interface for user programs beyond the capability-tokenized I/O surface. CBS is the only user-program execution path.
- **A networked system.** No TCP/IP, no Ethernet driver, no Wi-Fi. The substrate runs entirely on the bare metal that boots it.
- **A multi-user system.** Single-user, single-active-cap-context (with a cap_stack for nested authority). User authentication is deferred.
- **A self-hosted development environment.** CBS demos compile on a host (Linux/macOS/WSL2) with Python; the substrate runs them but doesn't compile them at runtime. Runtime IMPORT is V2.0 (#91).

It **is**: 25.4 KB of hand-written NASM that boots in QEMU, runs 6 byte-exact CBS demonstration programs against 5 typed primitive pools, with 44 doctrines codifying every architectural decision. The trinity has one pillar complete. The next two pillars will be built on the same substrate.

---

## 10. Where to start reading the source

For a competent reviewer doing a fortnight audit:

1. **`boot/boot.asm`** — UEFI entry, PE32+ header, boot initialization (~500 lines). Establishes the substrate's bring-up sequence.
2. **`boot/defines.asm`** — opcode constants, capability tokens, pool sizes, slot layouts. The substrate's grammar in one file.
3. **`boot/cbs_vm.asm`** — stack-VM dispatch + per-opcode handlers (~3,900 lines). The substrate's execution core.
4. **`boot/cap.asm`** — capability framework: cap_new, cap_enter, cap_exit, MAC verification, parent walks.
5. **`boot/maid.asm`** — Maid V1.0 compute helpers (~700 lines). The lexical-computation pole's f32 substrate.
6. **`recon/POD3_DECISION_RECORD.md`** — Embedding primitive landing; the bottom layer of the Maid surface.
7. **`recon/POD3.12_DECISION_RECORD.md`** — V1.0 SEAL pod; the synthesis where deferral framework + catch-surface-migration doctrine land.
8. **`tools/atreyu_x86.py`** — CBS compiler (~4,200 lines). The full language definition in one Python file.
9. **6 canary demos**: `surfaces/test_pod40f_b53..b58.cbc` + their `tools/atreyu_x86.py:demo_pod40f_b5X` source functions.

Read `recon/` in chronological order to see how the substrate evolved decision by decision. The mythology naming helps — every NASM file and every architectural surface has a name you can keep straight while you read.

---

*The substrate is the credential. The substrate's discipline is the doctrine corpus. The doctrine corpus is the audit trail.*
