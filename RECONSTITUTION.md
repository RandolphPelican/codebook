# CodebookOS — RECONSTITUTION MANIFESTO (v11 — V1.0 SEAL)

## Post-Pod-3.12 — V1.0 SEAL (Maid V1.0 surface complete; substrate canon-bound)

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026 (v1)
**Updated:** April 27 – May 03, 2026 (v2–v10; Cap canon sealed at Pod 1.10.1)
**Updated:** May 11, 2026 (v11 — V1.0 SEAL: Maid V1.0 surface complete across Pods 3.5–3.11; substrate canon-bound at `c9923b8c…`; 44 codified doctrines through V1.0 SEAL; Pod 4.0 wrapper-pivot redirect absorbed; D3.43 broad + D3.44 land at this SEAL)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD3.12_DECISION_RECORD.md, recon/POD4.0_RECON_NOTES.md, recon/POD3.5_DECISION_RECORD.md through recon/POD3.11_DECISION_RECORD.md
**Supersedes:** RECONSTITUTION.md v10

## Why v11 exists — V1.0 SEAL canon-binding moment

v10 sealed Cap design canon (Pod 1.10.1) and Pod 1.10 split. v11 records what happened next: Pod 1.10.2a (Cap substrate landing) → Pod 1.10.2b1/b2 (Cap conduits + accessors) → Pod 1.10.3 (Cap metabolic wiring) → Pod 2.1/2.2 (Babylon spatial-merge + cap_bitmap activation) → Pod 3 (Embedding typed-primitive substrate-prep) → **Pod 3.5–3.11 Maid V1.0 surface complete** → Pod 3.12 V1.0 SEAL.

**The substrate is V1.0.** Six Maid capability variants live; five typed pools; 44 codified architectural doctrines; ~25 KB of hand-crafted NASM auditable in a fortnight; SipHash MAC integrity per primitive; F32 IEEE 754 byte-exact determinism per Form A canon; energy accounting at opcode level; capability-typed security from layer 1; two-build determinism preserved across the V1.0 sequence.

V1.0 SEAL contract: **`c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`** (load-bearing reference for regression discipline across Pod 4.0 polish work).

---

## V1.0 SEAL state — what the substrate IS

### Maid V1.0 capability surface (six variants live)

| Pod | Surface | Capabilities |
|---|---|---|
| 3.5 | **Housekeeper** | cosine + dot + L2 + lookup_top1 + sign_handle |
| 3.6 | **Composer** | add + subtract + scale + normalize + lerp + synthesis_handle |
| 3.8 | **Importer** | boot_ingest_codebook + imported_handle |
| 3.9 | **Finder-of-many** | lookup_top_k |
| 3.10 | **Orthogonalizer** | project + reject |
| 3.11 | **Maintainer** | codebook_meta |

**Recognition axis** (Pod 3.5 + 3.9): single-best (lookup_top1) + K-best with threshold (lookup_top_k).
**Synthesis axis** (Pod 3.6 + 3.10): vector arithmetic (add/subtract/scale/normalize/lerp) + geometric decomposition (project/reject).
**Import axis** (Pod 3.8 + 3.11): boot-time codebook ingestion + per-embedding provenance (imported_handle) + codebook-level metadata (codebook_meta).

### Five typed pools (each SipHash-MAC-protected where applicable; each with cap_bitmap authority enforcement)

- **Sign** (Pod 1.6-1.8.5b; identity + provenance; 64 slots)
- **Energy** (Pod 1.8; metabolic budget primitive; 64 slots)
- **Outcome** (Pod 1.9.1-1.9.3; Result<T,E> with byte-exact MAC; 4096 slots per Pod 3.7 D3.29 proportional sizing)
- **Cap** (Pod 1.10.1-1.10.2b2; capability-typed authority; 64 slots; SipHash MAC; arena/owner/bitmap)
- **Embedding** (Pod 3; F32 vectors with SipHash MAC over 196 qwords; 2048 slots per Pod 3.7 production-scale)

### 44 codified architectural doctrines through V1.0 SEAL

- **D1.x** — Pre-Cap substrate doctrines (Pod 1.x)
- **D2.x** — Babylon doctrines (Pod 2.x; spatial-merge + cap_bitmap)
- **D3.1–3.44** — Embedding/Maid doctrines (Pod 3.x):
  - **D3.1–D3.11** Embedding substrate-prep (Pod 3)
  - **D3.12–D3.24** Maid speaks (Pod 3.5; FP-determinism canon)
  - **D3.25–D3.28** Maid composes (Pod 3.6; synthesis tier)
  - **D3.29** Substrate scales (Pod 3.7; axis-2 mechanical sizing)
  - **D3.30–D3.32** Maid imports (Pod 3.8; codebook ingestion)
  - **D3.33–D3.36** Maid finds many (Pod 3.9; result-rep + variable-cardinality Outcome)
  - **D3.37** NASM RIP-relative indexed-BSS-access discipline (substrate-catch landing)
  - **D3.38–D3.41** Maid orthogonalizes (Pod 3.10; project-reject + scalar discipline + IEEE-degeneracy + raw-emitter literal-id)
  - **D3.42** Maid maintains (Pod 3.11; codebook metadata witness; axis-removal inheritance)
  - **D3.43** V1.0-deferral framework (broad; three convergent patterns + forensic-record retention)
  - **D3.44** Catch-surface-migration tri-tier doctrine (Mechanical / Substrate-behavior / Inheritance)

### Substrate metrics

- **Code + non-zero data**: ~25.4 KB (26,031 non-zero bytes in BOOTX64.EFI)
- **BSS pool reservations**: ~3.7 MB (embedding pool 3.08 MB + outcome pool ~320 KB + side-tables ~144 KB + caps/signs/energy/registries/scratch)
- **PE32+ binary file size**: 5,243,904 bytes (5.0 MB total; dominated by BSS pre-allocation per Pod 3.7 TEXT_RAWSZ expansion)
- **Auditability**: ~25 KB of hand-crafted NASM is auditable in a fortnight by a competent reviewer
- **Build chain**: NASM 2.16.01 / mtools 4.0.43 / QEMU 8.2.2 in WSL; pinned absolute paths + version-grep per Pod 3.7 D3.29 axis-1 build-shell discipline

### Two-build determinism

Substrate compiles to byte-exact identical BOOTX64.EFI across two clean rebuilds at **`c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900`** — V1.0 SEAL contract sha.

Two-build determinism preserved across the full V1.0 sequence (Pod 1.6 → Pod 3.12; 16+ substrate-pod commits).

### Canary regression discipline

- **36+ prior-pod canaries** (Pod 3.5 17 + Pod 3.6 16 + Pod 3.7 3) pass byte-exact at canonical contract
- **Pod 3.8 B48** codebook-import canary PASSES (auxiliary substrate; canonical preserved post-canary)
- **Pod 3.9 B49** top-K canary PASSES (auxiliary substrate; predicted ordering [1,2,3,4,5] byte-exact)
- **Pod 3.10 B50/B51** project/reject canaries PASS (drift panel byte-exact at 0xB4000000 — D3.28 self-verifying canon extends to compound geometric ops)
- **Pod 3.11 B52** codebook-meta canary PASSES (all 5 META readbacks byte-exact)

### CBS language (Custom Bytecode Substrate)

- Custom assembly-level bytecode with typed-primitive opcodes (0x00–0xFF range; embedding ops 0xC0–0xCF + 0xF0–0xF5)
- **Compiler/lexer/parser**: `tools/atreyu_x86.py` (Python build-tool; AST → bytecode emit; ~3000 lines)
- **Stack-VM**: `boot/cbs_vm.asm` (NASM; ~3900 lines; per-opcode handlers with energy accounting; SipHash MAC verify per primitive)
- **Energy accounting**: per-opcode cost table at `boot/energy_costs.asm`; metabolic budget enforced at every fetch; D3.17 anticipated-worst-case static pricing
- **Demonstrably working**: 50+ canaries verify substrate behavior across every V1.0 capability surface

---

## DEFERRED state at V1.0 SEAL

### Closed at V1.0 SEAL

| # | Description | Closed at |
|---|---|---|
| #80 | Maid semantic operations | Pod 3.8 (Maid V1.0 surface complete) |
| #83 | Embedding pool capacity | Pod 3.7 (256→2048) |
| **#84** | **Pod 3 throwaway test scripts** | **Pod 3.12 V1.0 SEAL** (light consolidation: 4 actively-used scripts added to git; deprecated stays untracked per documented audit) |
| **#85** | **RECONSTITUTION.md ongoing canon refresh** | **Pod 3.12 V1.0 SEAL** (this v11 refresh) |
| #89 | Build-shell-determinism hazard | Pod 3.7 |
| #90 | Outcome pool capacity below embedding pool | Pod 3.7 |
| **#93** | **Diagnostic-probe-scaffolding policy** | **Pod 3.12 V1.0 SEAL** (D3.43.x forensic-record retention ratified) |

### V2.0-candidate forward

| # | Description |
|---|---|
| #1 | LLC / signing entity rename (cosmetic; awaiting architect decision) |
| #2 | ide_pio.asm NASM warnings (cosmetic; substrate-functional) |
| #82 | Sign.provenance_handle activation candidate |
| #91 | Codebook-symmetry: runtime IMPORT + multi-codebook |
| #92 | Stream-stability: aggregation / cross-result analogical / Result[T] sixth pool |

Each V2.0 candidate framework-tested at activation per D3.43 broad — no V2.0 surface is presumed; concrete production demand justifies substrate addition.

---

## What's coming — V1.0 SHIP + V2.0 forward

### V1.0 SHIP (Pod 4.0; in flight)

Pod 4.0 = the resume-piece polish campaign. Substrate stays unchanged at V1.0 SEAL state except for OP_READ_KEY substrate addition (D4.2; enables interactive CBS demos). Polish layer goes Python:

- Boot animation (searchlights → Pelican III → CodebookOS title)
- About demo (scrolling text + visual flourishes)
- In-fiction surface mocks (Falkor browser / Atreyu editor / Rockbiter scheduler)
- Demo video pipeline (90-second MP4)
- Manifesto PDF (~40-60 pages)
- Documentation pass (GETTING_STARTED / CBS_LANGUAGE / ARCHITECTURE / CONTRIBUTING / README)

**D4.X doctrine corpus** (8 entries through V1.0 SHIP):
- **D4.1** Polish-vs-credential separation (architecturally load-bearing — codifies why substrate stays NASM and polish goes Python)
- **D4.2** CBS interactive input surface (OP_READ_KEY substrate addition)
- **D4.3** Boot animation discipline
- **D4.4** In-fiction surface discipline
- **D4.5** Demo-program discipline
- **D4.6** Release-artifact discipline
- **D4.7** Public-repo-flip discipline
- **D4.8** Polish-layer verification discipline

V1.0 SHIP at Pod 4.0.J: public repo flip + v1.0-ship tag + demo video + USB image + manifesto PDF + HN/Reddit/Twitter drafts.

### V2.0 forward (post-SHIP)

- **Cop** (capability-typed security inspector — the trinity's second pillar)
- **Interpreter** (text-to-bytecode runtime — the trinity's third pillar)
- **Hormonal substrate** (federated cognitive organism vision; metabolism across surfaces)
- **Demod-tier surface** activation (0xE8–0xEF reserved row from Pod 1.12 forward-anchor)
- **Cross-substrate operations** (federation; multi-substrate coordination)
- **V2.0-candidate forward** items (#1, #2, #82, #91, #92) framework-tested per D3.43 broad

V1.0 SEAL is the **canon-binding boundary** between substrate-USE-completion-state (V1.0) and substrate-evolution-continuation-state (V2.0+).

---

## V1.0 SEAL — the resume-piece anchor

What V1.0 SEAL ratifies as credential:

- **Custom programming language (CBS)** with lexer + parser + bytecode compiler + stack-VM, all hand-crafted, all operationally complete at V1.0
- **Custom bare-metal operating system (CodebookOS)** in pure x86_64 NASM UEFI, ~25 KB of substrate code, demonstrably booting in QEMU, demonstrably running CBS programs, demonstrably executing the six Maid V1.0 capability variants
- **Built solo** by Randolph Pelican III over 30 architect-hours across 3 months (April–May 2026), with every architectural decision codified as one of 44 doctrines

The Maid recognizes; the Maid composes; the Maid imports; the Maid finds many; the Maid orthogonalizes; the Maid maintains. **V1.0 SEAL.**

---

# Historical sections (v10 and earlier — preserved as archaeology)

## Post-Pod-1.10.1 — Cap Canon Sealed (Outcome + Conduits + Cap Design)

**Compiled:** April 27, 2026 (v1)
**Updated:** April 27, 2026 (v2 — post-Pod-0.2.5 recon)
**Updated:** April 27, 2026 (v3 — post-Pod-0.9 cap_graph deep read)
**Updated:** April 27, 2026 (v4 — post-Pod-1.1 VM audit decisions)
**Updated:** April 27, 2026 (v5 — post-Pod-1.3 VM fixes, width-migration decisions)
**Updated:** April 28, 2026 (v6 — post-Pod-1.6 Sign as native type, typed-primitive pattern)
**Updated:** April 28, 2026 (v7 — post-Pod-1.7 Sign source implementation, canon corrections)
**Updated:** April 29, 2026 (v8 — post-Pod-1.8 Energy source implementation, per-opcode cost table, catalytic-gateway fetch loop)
**Updated:** May 03, 2026 (v9 — post-Pod-1.9.1 Outcome<T> design canon, opcode allocation Outcome→0xE0-0xE4 / Demod→0xE5-0xEF, Pod 1.9 split into 1.9.1/1.9.2/1.9.3)
**Updated:** May 03, 2026 (v10 — post-Pod-1.10.1 Cap canon, ROOT_CAP bootstrap, RDSEED-with-RDRAND-fallback substrate-secret, SipHash-2-4 MAC, Pod 1.10 split into 1.10.1/1.10.2a/1.10.2b)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD0.9_CAP_GRAPH_DEEP_READ.md, recon/POD1.1_VM_AUDIT.md, recon/POD1.2_DECISION_RECORD.md, recon/POD1.4_DECISION_RECORD.md, recon/POD1.6_DECISION_RECORD.md, recon/POD1.7_DECISION_RECORD.md, recon/POD1.8_DECISION_RECORD.md, recon/POD1.9.1_DESIGN_DECISIONS.md, recon/POD1.10.1_DECISION_RECORD.md
**Supersedes:** RECONSTITUTION.md v9

## Why v10 exists

v9 sealed Outcome<T> design canon and the opcode-allocation correction
(Outcome relocated to 0xE0-0xE4; Demod tightened to 0xE5-0xEF). v10
records what happened next: Pod 1.9.2a/b/3 implemented Outcome and
refit existing accessors; Pod 1.9.4 cleared the throwaway test script
housekeeping bundle; Pod 1.10.1 (this commit) seals the Cap design
canon before 1.10.2 implementation can drift on it.

The Cap subsection is replaced with the canonical D1.10.1 definition
per `recon/POD1.10.1_DECISION_RECORD.md`. Key architectural decisions:
- 128-byte symmetric slot per Pod 1.8.5c A1(d); Cap drops the
  +0x70/+0x78 arena/owner mirror fields because Cap is the source of
  authority, not a consumer (D1.10.1.1)
- Five core opcodes at 0xB0-0xB4 per RECONSTITUTION v9 placement
  (D1.10.1.2)
- ROOT_CAP at cap_id=1 with arena_id=0, owner_demod_id=0, MAC computed
  at boot from RDSEED/RDRAND-derived siphash_key (D1.10.1.5,
  D1.10.1.6)
- SipHash-2-4 MAC over 6 u64 fields; per-boot key regeneration; caps
  don't survive reboot (D1.10.1.7)
- Cap activates dormant arena/owner in existing primitives — Sign,
  Energy, Outcome allocators retrofit at Pod 1.10.2b to read
  current_cap cache fields (D1.10.1.8 — substrate-wide elegance
  unlock)
- OP_CAP_CHECK = authenticity + authorization (D1.10.1.11)
- Strict delegation in V1.0; OP_CAP_NEW always derives from current_cap
  with arena/owner inheritance (D1.10.1.12)

The Pod 1.10 row in the pod-arc table splits into 1.10.1 / 1.10.2a /
1.10.2b following the canon → substrate → handlers+retrofit+tests
pattern established by Pod 1.9. Other pod-arc reconciliation drift
(DEFERRED #37) stays deferred per Pod 1.9.4 D1.9.4.2 scope discipline.

## Why v9 exists

v8 canonized the Energy source implementation and per-opcode cost
table from Pod 1.8. v9 records what happened next: Pod 1.8.5b
retrofitted Sign and Energy accessors to return canonical u64 IDs
through registry indirection (Move 4); Pod 1.8.5b.5 closed the
prompts/ bootstrap-paradox gap; Pod 1.8.5c landed five terraforming
conduits (per-demod cost tables, auto-provenance default-OFF, arena/
owner ownership fields, OP_ENERGY_RECOVER reservation, vm_phase enum
with OP_PHASE_QUERY); Pod 1.9.1 (this commit) seals the Outcome<T>
design canon before 1.9.2 implementation can drift on it.

The opcode allocation table is updated: Outcome relocates from
0xC0-0xCF (v8 placeholder) to 0xE0-0xE4 (D1.9.1.4 ratification);
Demod's range tightens from 0xE0-0xEF to 0xE5-0xEF accordingly.
The Outcome<T> subsection is replaced with the canonical definition
per `recon/POD1.9.1_DESIGN_DECISIONS.md` D1.9.1.1-8.

The pod-arc table splits Pod 1.9 into three sub-pods following the
canon → source → refit pattern established by Pod 1.5/1.5.5/1.5.6
and Pod 1.6/1.7. Other pod-arc reconciliation drift (Pod 1.5.5 hash,
Pod 1.8 hash placeholder, missing 1.8.x sub-pod rows, Cap allocation
hint at 0xC0-0xCF) is forward-logged to a future housekeeping pod
and intentionally NOT touched in v9 (DEFERRED #37).

---

## Why v5 exists

v4 canonized eight architect decisions from Pod 1.1's VM substrate
audit. v5 records what happened next: Pod 1.3 executed the first
two VM fixes (OP_CALL/OP_RET semantics, OP_HALT already present),
and the architect made three width-migration decisions (D1/D2/D3)
that refine how 64-bit migration works. v5 also adds the
PAUSED-MID-EXECUTION protocol state to the recon canon, slides the
pod arc to thirteen sub-pods, and retroactively documents Pod 1.3's
implementation details.

See `recon/POD1.4_DECISION_RECORD.md` for the D1/D2/D3 rationale.

## Why v6 exists

v5 canonized the VM substrate fixes and width-migration decisions.
v6 codifies the typed-primitive representation pattern established by
Sign in Pod 1.6: static pool with stack handles, construction-time
validation, immutable values, separate pools for variable-sized fields.
Subsequent typed primitives (Energy, Outcome, Cap, Demod) inherit this
pattern. v6 also concretizes Sign's field layout and opcode allocation
(0xA0–0xA3 wired in Pod 1.7, 0xA4–0xAF reserved for Pod 3+).

See `recon/POD1.6_DECISION_RECORD.md` for the A1–A7 rationale.

## Why v7 exists

v6 codified Sign's design and the typed-primitive representation pattern.
v7 records Pod 1.7's source implementation: four opcode handlers
(OP_SIGN_NEW, OP_SIGN_HASH, OP_SIGN_LABEL, OP_SIGN_ENERGY) wired in
`boot/cbs_vm.asm`, pool allocation in `boot/vmdata.asm`, toolchain
emission in `tools/atreyu_x86.py`, and a round-trip test program
(`surfaces/sign_test.cbc`) verified end-to-end under QEMU on bare-metal
UEFI. v7 also corrects a v6 error: the typed-primitive pool lives in
`boot/vmdata.asm`, not `boot/data.asm` (D1.7.5b canon correction).
OP_SIGN_HASH stack shape is ratified as 4-slot push (low-to-high u64
quadrants). Pod arc expands to fourteen sub-pods (1.0–1.13).

See `recon/POD1.7_DECISION_RECORD.md` for the D1.7.1–D1.7.8 rationale.

## Why v8 exists

v7 recorded Pod 1.7's Sign source implementation and corrected v6's
data.asm/vmdata.asm pool-location error. v8 records Pod 1.8's Energy
source implementation: four opcode handlers (OP_ENERGY_NEW,
OP_ENERGY_JOULES, OP_ENERGY_SOURCE_OP, OP_ENERGY_FREE) wired in
`boot/cbs_vm.asm`, pool allocation in `boot/vmdata.asm`, a new
`boot/energy_costs.asm` module containing the 256-entry per-opcode
cost table and `energy_cost_lookup` primitive, toolchain emission in
`tools/atreyu_x86.py`, and a round-trip test program
(`surfaces/test_energy.cbc`) verified end-to-end under QEMU on bare-metal
UEFI. v8 also introduces the catalytic-gateway fetch-loop architecture
(handlers no longer touch energy — the fetch loop is the single
metabolic boundary) and resolves DEFERRED #15 (r15-uninit display bug).

See `recon/POD1.8_DECISION_RECORD.md` for the D1.8.1–D1.8.12 rationale.

1. **VM semantics fixed (Pod 1.3 — complete).** `OP_RET` is now a
   subroutine return (pops `vm_ret_stack`). `OP_CALL` uses
   PC-relative signed offsets (was broken absolute addressing).
   `OP_HALT` (0xFF, pre-existing) exits the VM. `vm_ret_ptr` is
   reset in `cbs_run` prologue. All `.cbc` surface files patched
   from trailing `OP_RET` to `OP_HALT`.

2. **Width migration refined (D1/D2/D3).** CBS values widen to
   8 bytes; positional offsets (jump targets, call offsets) stay
   4-byte signed. Sign-extension (`movsxd`) is the default on
   widening. Python toolchain update is mandatory and atomic with
   runtime format changes. Width migration lands in Pod 1.5.

3. **Current cap ops replaced.** The VM's existing `OP_GRANT_CAP`
   (0x90) and `OP_USE_CAP` (0x91) are retired in Pod 1.11. Cap<R>
   typed primitives replace them entirely — the spatial-merge design
   from Pod 0.9 informs the replacement, but no current cap code
   survives.

4. **Opcode space allocated.** Typed primitives claim `0xA0–0xEF`
   (80 slots). Energy moves from per-fetch flat cost to per-opcode
   cost table in Pod 1.8. Stack bounds produce `Outcome<T>` errors
   in Pod 1.9.

5. **Pod 1 sub-pod arc expanded.** Thirteen sub-pods (1.0–1.12)
   with explicit sequencing. Pod 1.4 (this canon update) inserted
   after Pod 1.3, sliding all subsequent pods by one. Duration
   estimates removed from canon — pace is set by recon-protocol
   discipline, not by calendar.

The four-layer model is unchanged. Layer 1 gains implementation
detail from the completed VM fixes and the width-migration
decisions. The pod arc expands.

---

## The OS in one sentence (unchanged from v1)

CodebookOS is a federated cognitive organism running on a typed CBS substrate
on minimal bare-metal bootstrap, where capabilities are cryptographic, energy
is typed, signs are first-class, and the filesystem is a semantic codebook.

---

## The four layers (unchanged structure; Layer 1 enriched, Layer 0 paging note added)

### Layer 0 — Bootstrap (NASM, irreducibly small)

(Unchanged from v2 except for the V1.0 paging note at the end.)

UEFI handoff, minimal driver layer for hardware abstraction, framebuffer
output, keyboard input, raw block I/O, and the typed CBS VM itself.
Layer 0 splits across `boot/` (orchestrator) and `drivers/` (hardware
abstraction). `kernel/_future/` contains documented exile with
resurrection checklists for cap_graph and paging.

#### V1.0 paging — UEFI identity map only

V1.0 runs in UEFI's identity-mapped flat memory model. CodebookOS does
not install its own page tables in V1.0. The exiled
`kernel/_future/paging.asm` contains design notes for post-V1 paging:
1GB-page identity mapping for low memory, write-combining (PAT/PCD)
for the framebuffer MMIO range, and post-EBS CR3 install ordering.
Per Pod 0.9's analysis, V1.0 has no feature requirement that demands
own-paging — UEFI's identity map suffices. Paging arrives in Pod 2 or
later when a feature requires it (separate userspace, write-combining
framebuffer performance, NX bit on data, etc.). DEFERRED.md item 9
tracks this.

### Layer 1 — The Typed CBS VM (Engywook, in NASM)

A typed evaluator. Native primitives:

#### `Sign` — concretized in v6 (Pod 1.6)

The unit of cognition. Abstract definition unchanged from v2; concrete
layout ratified in Pod 1.6.

```
Sign := {
  content_hash: bytes(32),         // sha256 of content
  embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
  label:        string(<=64),      // human-readable name
  provenance:   ProvChain,         // log of who wrote/touched this Sign
  energy_cost:  Energy,            // joules to construct
}
```

**V1.0 concrete layout (128 bytes per slot, 8-byte aligned; current as of Pod 3 / D3.4 D3.11):**

```
offset  size    field
0x00    32      content_hash       (sha256 raw bytes)
0x20    64      label              (length-prefixed ASCII; byte 0 = length, bytes 1–63 = chars)
0x60    8       energy_cost        (u64 joules; Pod 1.7 typed wrapper)
0x68    8       creator_cap_id     (u64; Pod 1.10.2b2 reclaimed from former embedding_handle slot)
0x70    8       arena_id           (u64; Pod 1.8.5c reclaimed from former provenance_handle slot)
0x78    8       owner_demod_id     (u64; Pod 1.8.5c reclaimed from former V1.1 sentinel)
total   128
```

**Slot evolution archaeology:** the Sign slot layout has evolved through three
reclamation passes, each preserving SIGN_SLOT_SIZE=128 bytes:
- **Pod 1.7 (substrate-prep)**: original layout placeholders at +0x68 (embedding_handle), +0x70 (provenance_handle), +0x78 (V1.1 sentinel) — all forward-declared for Pod 3+ activation.
- **Pod 1.8.5c Move 3**: provenance_handle at +0x70 → arena_id; V1.1 sentinel at +0x78 → owner_demod_id (Move 3 retrofit reclaiming reserved zone for substrate-state caching per D1.8.5c).
- **Pod 1.10.2b2**: embedding_handle at +0x68 → creator_cap_id (Move 3+creator pattern continuation per D1.10.2b2.X).

**OP_SIGN_NEW operand-stack ABI** preserved at 5 args throughout: `(provenance_handle_ignored, embedding_handle, energy_cost, label_addr, hash_addr)`. The embedding_handle arg, formerly validated to zero and discarded pre-Pod-3, gained activated semantics at Pod 3 per D3.4 (validates non-zero via registry_lookup_embedding; on success writes to parallel side-table `vm_sign_embedding_handle[sign_id - 1]`).

**Sign embedding linkage (Pod 3 D3.4):** the substrate-stamped cross-pool reference between Sign and Embedding lives in a parallel BSS structure (`vm_sign_embedding_handle: times SIGN_POOL_SLOTS dq 0`) indexed by `sign_id - 1`. `OP_SIGN_EMBEDDING_HANDLE = 0xA7` reads this side-table. The reclaimed-slot-via-parallel-structure pattern is canonized as one of two architectural patterns for substrate evolution without slot-layout disruption (D3.6); the other is placeholder-field semantic activation (Pod 2.2 cap_bitmap).

**Sign-non-MAC archaeology asymmetry:** Sign + Energy are non-MAC; Cap + Outcome + Embedding are MAC-protected (SipHash-2-4). Pod 1.7 design predated the Pod 1.10.2a MAC convention; Sign/Energy were never retroactively MAC-retrofitted. The integrity model for non-MAC pools is parallel-structure-tracking (registry indirection + slot-write discipline). DEFERRED #81 forward-logs MAC-retrofit candidate when integrity-attack surface becomes empirical.

**Pool:** `vm_sign_pool`, 64 nodes × 128 bytes = 8 KB. Static allocation
in `boot/vmdata.asm` (placed by Pod 1.7). Matches cap pool sizing (64 ×
128 = 8 KB) per the typed-primitive pool convention (see below).

**Handles:** Operand stack carries an 8-byte `sign_id` (pool index).
`sign_id` 0 = invalid/null; valid range 1–64.

**Label representation:** Length-prefixed ASCII. Byte 0 holds length
(0–63); bytes 1–63 hold characters. UTF-8 deferred to V1.1.

**Embedding linkage (post-Pod-3):** Sign-Embedding cross-pool typed reference
via parallel side-table (D3.4). Pre-Pod-3 placeholder in OP_SIGN_NEW's 5-arg
ABI gained activated semantics at Pod 3 D3.4. Provenance via prov_append
ring (Pod 1.8.5c, default-OFF; cap-flag-gated activation) rather than per-Sign
provenance_handle slot (slot reclaimed at Pod 1.8.5c Move 3 for arena_id;
DEFERRED #82 forward-logs activation candidate if needed in future pods).

**Validation:** Construction-time only (OP_SIGN_NEW). Hash must be 32
bytes, label length ≤ 63, energy_cost in valid range, handle values
either 0 or within their pool ranges. If validation fails, OP_SIGN_NEW
pushes sign_id 0 (null). Accessors (OP_SIGN_HASH, OP_SIGN_LABEL,
OP_SIGN_ENERGY) check sign_id validity; push zero/empty/null on invalid.

**Mutability:** Immutable post-construction. ProvChain is separately
mutable via the ProvChain pool (Pod 3+); Sign's provenance_handle stays
constant, the chain it points at grows.

**Opcodes (0xA0–0xAF):**

```
OP_SIGN_NEW              0xA0   construct Sign from stack args, return Outcome<sign_id>
OP_SIGN_HASH             0xA1   sign_id → 4 × u64 (hash[0:8], hash[8:16], hash[16:24], hash[24:32])
OP_SIGN_LABEL            0xA2   sign_id → label as string
OP_SIGN_ENERGY           0xA3   sign_id → Outcome<energy_cost u64>
OP_SIGN_ARENA            0xA4   Pod 1.10.2b2 — sign_id → Outcome<arena_id>
OP_SIGN_OWNER            0xA5   Pod 1.10.2b2 — sign_id → Outcome<owner_demod_id>
OP_SIGN_CREATOR          0xA6   Pod 1.10.2b2 — sign_id → Outcome<creator_cap_id>
OP_SIGN_EMBEDDING_HANDLE 0xA7   Pod 3 — sign_id → Outcome<embedding_handle> (side-table read per D3.4)
0xA8–0xAF                reserved (Pod 3.5+ Sign-related semantic ops)
```

OP_SIGN_NEW stack inputs (top-down): provenance_handle (ignored, silently discarded),
embedding_handle (Pod 3 D3.4: typed embedding_id ref or 0=none), energy_cost,
label_addr, hash_addr. Returns Outcome<sign_id> on stack (Pod 2.2 Path A retrofit;
auto-unwrap via OP_OUTCOME_UNWRAP_OK at emitter level for backward-compat).

Side-table write at OP_SIGN_NEW post-registry per D3.4: `vm_sign_embedding_handle[sign_id - 1] = embedding_handle`.
Validation: non-zero embedding_handle routes through registry_lookup_embedding;
unresolvable handle yields Outcome::Err(ERR_INVALID_ID, source_op=OP_SIGN_NEW).

**Implementation (Pod 1.7):** All four Sign opcodes are wired in
`boot/cbs_vm.asm` with dispatch entries and handlers. `vm_sign_alloc`
is a bump allocator returning (slot_ptr, 1-based sign_id). Energy costs:
OP_SIGN_NEW = 100 joules, accessors = 5 joules each (placeholder costs,
typed Energy deferred to Pod 1.8; see D1.7.6). Toolchain emission in
`tools/atreyu_x86.py` embeds hash/label data inline via OP_PUSH_STR +
OP_DROP. Round-trip verified under QEMU: sign_id=1, energy=42, label=hello,
hash[0:8]=171 (0xAB little-endian). See `recon/POD1.7_DECISION_RECORD.md`.

#### `Cap<R>` — canonical definition (v10, Pod 1.10.1)

Capability over a resource descriptor, organized as a delegation graph
with cryptographic authenticity (SipHash-2-4 MAC) and substrate-
enforced authority (arena_id + owner_demod_id pair). The full design
is sealed in `recon/POD1.10.1_DECISION_RECORD.md` (D1.10.1.1 through
D1.10.1.14); v10 records the canonical shape here for cross-reference.

**Slot layout (128 bytes, CAP_SLOT_SIZE per Pod 1.8.5c A1(d) precedent;
D1.10.1.1).** Cap drops the +0x70/+0x78 arena/owner mirror fields that
other primitives carry, because Cap is the source of authority not a
consumer. The mirror convention applies to consumer primitives (Sign,
Energy, Outcome) that inherit arena/owner from current_cap at
allocation time.

```
+0x00  cap_id_self           u64   redundant copy of own ID for slot self-id
+0x08  arena_id              u64   the arena this cap grants authority within
+0x10  owner_demod_id        u64   the demod that owns this cap
+0x18  resource_descriptor   u64   opaque u64 the cap grants access to
+0x20  parent_cap_id         u64   delegation chain; 0 for ROOT_CAP only
+0x28  generation_counter    u64   Pod 2+ revocation; V1.0 always 0
+0x30  mac                   u64   SipHash-2-4 over fields above
+0x38  reserved              80 bytes for Pod 2+ extensions
```

**Five core opcodes at 0xB0-0xB4 (D1.10.1.2, D1.10.1.3):**

| Opcode | Hex | Cost | Behavior |
|--------|-----|------|----------|
| OP_CAP_NEW | 0xB0 | 1j metabolic | Pop resource_descriptor + arena_id + owner_demod_id; derive from current_cap (strict delegation per D1.10.1.12); construct Outcome<cap_id> |
| OP_CAP_ENTER | 0xB1 | 0j structural | Pop cap_id; push current_cap_id to cap_stack; set current_cap to popped |
| OP_CAP_EXIT | 0xB2 | 0j structural | Pop nothing; restore current_cap from cap_stack |
| OP_CAP_CURRENT | 0xB3 | 0j structural | Push current_cap_id |
| OP_CAP_CHECK | 0xB4 | 1j metabolic | Pop cap_id + expected_arena_id + expected_owner_demod_id; push 1 if MAC valid AND arena matches AND owner matches; 0 otherwise (D1.10.1.11) |

Reserved 0xB5-0xBF for future Cap operations.

**ROOT_CAP bootstrap (D1.10.1.5).** Substrate init creates Cap at
cap_id=1 with arena_id=0, owner_demod_id=0, parent_cap_id=0,
generation_counter=0, mac=SipHash(siphash_key, fields). current_cap_id
initialized to 1; cap_stack empty. All allocations before any
OP_CAP_NEW fires inherit ROOT context.

**Substrate secret (D1.10.1.6).** Boot derives 128-bit siphash_key via
RDSEED (preferred) or RDRAND (fallback). Hard-fail if both unavailable
— substrate emits fail message via auryn_puts and HALTs before MIND
phase. No fixed-key fallback tier; a cryptographic capability system
with a known-fixed key isn't cryptographic. Per-boot key regeneration;
caps don't survive reboot. Substrate refuses to boot on pre-2012
hardware (pre-RDRAND).

**SipHash-2-4 over 6 u64 fields (D1.10.1.7).** 64-bit MAC, 128-bit
key, c=2 compression rounds, d=4 finalization rounds. Cap MAC input is
6 u64 fields (cap_id_self through generation_counter) = 48 bytes; 16
SIPROUND total per computation. NASM implementation ~150 lines.
V1.0-specific signature `siphash_compute_cap_mac(rdi=slot_ptr) -> rax=mac`;
generalize when a second MAC consumer appears.

**Strict delegation in V1.0 (D1.10.1.12).** OP_CAP_NEW always derives
from current_cap. Child cap inherits arena_id and owner_demod_id
exactly from parent (V1.0 doesn't support sub-arena delegation).
Holding a cap genuinely transfers authority along the delegation chain.
Pod 2 (Cop) extends with sub-arena delegation, owner-pair relaxation,
or revocation via generation_counter advancement.

**Cap activates dormant arena/owner in existing primitives
(D1.10.1.8 — substrate-wide elegance unlock).** Sign, Energy, Outcome
have been carrying placeholder zero arena_id/owner_demod_id at
+0x70/+0x78 since Pod 1.8.5c Move 3. Pod 1.10.2b retrofits the three
allocators (.sign_alloc, .energy_alloc, .outcome_alloc) to read from
current_cap_arena_id_cache and current_cap_owner_demod_id_cache.
Every subsequent typed-primitive allocation inherits arena/owner from
the current cap context, making sandboxed execution patterns
expressible at substrate level.

**Outcome<Cap> shape per Path A (D1.10.1.9).** OP_CAP_NEW returns
Outcome<cap_id> via `.construct_ok_outcome` helper (Pod 1.9.3) on
success; Err on failure. value_type_id = TYPE_CODE_CAP=3 (reserved at
Pod 1.9.2a per D1.9.1.1).

**cap_id space and pool (D1.10.1.10).** 0=null, 1=ROOT_CAP, 2+=user.
CAP_POOL_SLOTS=64 per existing pool capacity convention. Bump-allocator,
no free-list. CAP_ID_NULL=0 added to defines.asm null-sentinel block
at Pod 1.10.2a.

**cap_stack (D1.10.1.4).** 256-entry parallel to vm_ret_stack.
OP_CAP_ENTER overflow at 256 entries reuses ERR_STACK_OVERFLOW with
source_op=OP_CAP_ENTER disambiguating from OP_CALL. OP_CAP_EXIT
underflow at empty stack reuses ERR_STACK_UNDERFLOW with
source_op=OP_CAP_EXIT.

**Substrate state (D1.10.1.13).** vm_cap_pool (8KB), cap_registry
(1KB), cap_stack (2KB) + cap_stack_ptr, current_cap_id,
current_cap_arena_id_cache, current_cap_owner_demod_id_cache,
siphash_key (128-bit), siphash_key_source flag. Total ~11.1 KB.

**Existing cap ops retired.** OP_GRANT_CAP (0x90) and OP_USE_CAP
(0x91) are pre-Pod-1 magic-number token dispatchers; not part of the
typed Cap system. Pod 1.11 retires them entirely; OP_CAP_* takes their
place. The 0xCA000xxx capability tokens in cbs_vm.asm (DEFERRED #6)
remain dead code until that retirement.

#### `Cap<R>` — pre-v10 placeholder design (historical, retired in v10)

The pre-v10 Cap design (parent/child/sibling graph, cap_bitmap,
energy_budget per-cap, signature field, spatial-merge mechanic from
Pod 0.9 cap_graph.asm) is retired. Pod 1.10.1's design replaces it
with the typed Cap above. The salvageable design ideas
(parent_cap_id chain, bump-allocator with 64-slot pool, MAC over
cap fields) survive in revised form. The spatial-merge tax mechanism
is forward-logged to Pod 2 (Cop) — energy delegation tax is a Pod 2
discipline concern, not a Pod 1.10 substrate concern.

#### VM substrate fixes — v5 (Pod 1.3 complete, Pod 1.5 width migration)

**OP_CALL / OP_RET semantics (Q2) — fixed in Pod 1.3.** `OP_RET`
now pops from `vm_ret_stack` and resumes at the saved PC (subroutine
return). `OP_CALL` pushes the current PC to `vm_ret_stack` and jumps
by a PC-relative signed 4-byte offset — not an absolute address, which
was broken under UEFI relocation (`nasm -f bin` emits file offsets, but
UEFI maps at IMAGE_BASE + TEXT_RVA). `OP_HALT` (0xFF) exits the VM;
this opcode pre-existed and required no new code. The return stack
(`vm_ret_stack`, 256 entries × 8 bytes, `vm_ret_ptr` as memory counter)
has bounds checks: underflow on `OP_RET` and overflow on `OP_CALL`
halt with violation messages. `vm_ret_ptr` is zeroed in `cbs_run`'s
prologue to prevent stale state across invocations. All `.cbc` surface
files (`atreyu.cbc`, `bastian.cbc`, `rockbiter.cbc`) were byte-patched
from trailing `OP_RET` (0x53) to `OP_HALT` (0xFF). The `.done` exit
path in `cbs_vm.asm` is shared by `OP_HALT`, energy exhaustion, and
violation handlers. See `recon/POD1.3_OP_RET_RECON.md` for the full
audit.

**64-bit integer width (Q4, refined by D1/D2/D3).** The current VM
uses 32-bit integers (`eax`/`ebx`) for arithmetic but 64-bit stack
slots. Pod 1.5 migrates to 64-bit values — all arithmetic uses
`rax`/`rbx`, `OP_PUSH` value operands become 8 bytes. Positional
offsets (jump targets in `OP_JMP`/`OP_JZ`/`OP_JNZ`, call offsets in
`OP_CALL`) remain 4-byte signed — ±2 GB reach is sufficient and
avoids bloating every branch instruction. Sign-extension via `movsxd`
is the default when widening a 4-byte operand to 64-bit register
width. The Python toolchain (`tools/atreyu_x86.py`) update is mandatory
and atomic with the runtime format change — no pod ships widened
runtime without a toolchain that emits the matching format. Bytecode
format changes accordingly; pre-Pod-1.5 `.cbc` programs require
recompilation (DEFERRED #12, resolved in Pod 1.5).

**Opcode space allocation (Q5).** Typed primitives claim the
`0xA0–0xEF` range (80 slots), allocated by primitive:

| Range | Primitive | Pod |
|-------|-----------|-----|
| `0xA0–0xAF` | Sign | 1.6–1.7 |
| `0xB0–0xBF` | Cap<R> | 1.10–1.11 |
| `0xC0–0xCF` | (reserved; was Outcome v8 placeholder; relocated v9) | — |
| `0xD0–0xDF` | Energy (+ Pod 1.8.5c 0xD4 OP_ENERGY_RECOVER, 0xD5 OP_PHASE_QUERY) | 1.8 / 1.8.5c |
| `0xE0–0xE4` | Outcome<T> (relocated from 0xC0-0xCF in v9 per D1.9.1.4) | 1.9 |
| `0xE5–0xEF` | Demod<S> (range tightened in v9 to make room for Outcome) | 1.12 |

The existing `0x00–0x9F` range retains current opcode assignments
(arithmetic, stack, flow control, I/O). The `0xF0–0xFF` range is
reserved for future expansion.

Naming pattern for typed-primitive opcodes: `OP_<TYPE>_<OP>` — e.g.
`OP_SIGN_NEW`, `OP_ENERGY_ADD`, `OP_CAP_GRANT`, `OP_OUTCOME_OK`.

#### Typed primitive representation pattern — v6 (Pod 1.6)

All typed primitives in the CBS VM follow a common representation
pattern, established by Sign in Pod 1.6–1.7 and inherited by Energy
(Pod 1.8), Outcome<T> (Pod 1.9), Cap<R> (Pod 1.10–1.11), and
Demod<S> (Pod 1.12):

1. **Static pool with stack handle.** Each primitive type has a
   statically-allocated pool in `boot/vmdata.asm`. The operand stack
   carries an 8-byte handle (pool index) — not the struct itself.
   Handle 0 = null/invalid; valid range 1–64.

2. **Pool sizing.** 64 nodes per pool by default (matches cap pool
   precedent from Pod 0.9). Slot size is 128 bytes per node (8 KB
   per pool). V1.1 typed-primitive slot expansion happens across all
   typed primitives in unison.

3. **Construction-time validation.** The `OP_<TYPE>_NEW` constructor
   validates inputs. If validation fails, it pushes handle 0 (null).
   Accessors check handle validity; push zero/empty/null on invalid
   handle. No use-time re-validation of field contents in V1.0.

4. **Immutable values.** Once constructed, pool slots are read-only.
   Variable-sized or appendable data (e.g. ProvChain) lives in
   separate pools; the parent struct carries a fixed handle to the
   external pool.

5. **8-byte alignment.** All fields within a pool slot are aligned
   to 8-byte boundaries. Variable-length fields (labels, hashes)
   occupy fixed-size regions within the slot.

**Surface token header (Q6).** The 23-byte surface token header
referenced in README is a Python-toolchain artifact (`tools/cbsc.cbs`, Phase 8 detritus).
The NASM VM does not parse it — `cbs_run` begins execution at the
first byte of the bytecode stream. Pod 1's typed system ignores this
header entirely. The NASM VM is the authority; the Python toolchain
is historical.

#### `Outcome<T>` — canonical definition (v9, Pod 1.9.1)

`Outcome<T>` is the typed-error primitive. Every fallible operation
returns an `Outcome<T>` that carries either a success value of type
T or a structured error context. The full design is sealed in
`recon/POD1.9.1_DESIGN_DECISIONS.md` (D1.9.1.1 through D1.9.1.8);
v9 records the canonical shape here for cross-reference.

**Tagged shape with `value_type_id` discriminant (D1.9.1.1).** A
single Outcome primitive carries:
- `discriminant` (u64): 0=ok, 1=err
- `value_type_id` (u64): names which canonical-ID type T is, using a
  small enum (TYPE_CODE_SIGN=1, TYPE_CODE_ENERGY=2, TYPE_CODE_CAP=3,
  TYPE_CODE_DEMOD=4, TYPE_CODE_SIGNAL=5, TYPE_CODE_OUTCOME=6;
  TYPE_CODE_NONE=0 sentinel)
- `value` (u64): canonical ID of success value if ok; unused if err

This reuses Pod 1.8.5b's canonical-ID type space rather than forking
into per-T opcode variants. One opcode family covers all T.

**Standard 32-byte error context (D1.9.1.2).** Every err-Outcome
inlines a 4-field error context: `error_code` (u64), `source_op`
(u64), `demod_id` (u64), `fetch_counter` (u64). Total 32 bytes,
ProvEvent-shape-compatible (Pod 1.8.5c Move 2 ProvEvent has the same
shape), so errors and provenance share serialization machinery.

**Two-mode handlers (D1.9.1.3).** Convention enforced by handler
discipline: each opcode handler either fully succeeds (pushes
Outcome::ok) or fully fails (cleans operand stack, pushes
Outcome::err). No VM-level stack-frame tracking in V1.0 (Pod 2 Cop
hardens via runtime stack-shape verification). This closes
DEFERRED #13 architecturally; closure commits when Pod 1.9.3
refits the existing stack-violation halt sites
(`str_ret_underflow`, `str_call_overflow`) to push typed
`Err(StackUnderflow)` / `Err(StackOverflow)` Outcomes.

**Five accessor opcodes at 0xE0-0xE4 (D1.9.1.4):**
- `OP_OUTCOME_NEW_OK` (0xE0): pop value, value_type_id; push outcome_id
- `OP_OUTCOME_NEW_ERR` (0xE1): pop 4 err-context fields; push outcome_id; auto-provenance hook fires (D1.9.1.6)
- `OP_OUTCOME_IS_OK` (0xE2): pop outcome_id; push 1 if ok else 0; **consumes** (caller dups first to retain)
- `OP_OUTCOME_UNWRAP_OK` (0xE3): pop outcome_id; push value if ok; push sentinel + log if err
- `OP_OUTCOME_UNWRAP_ERR` (0xE4): pop outcome_id; push 4 err fields if err; push 4 zero sentinels + log if ok

**Inline error context (D1.9.1.5).** Error context lives inside the
Outcome slot, not in a separate buffer with handle indirection.
Pool capacity 64 means worst-case 2KB inlined storage; indirection
buys nothing at V1.0 scale. Pod 3+ message handles route through
reserved field +0x40 (parallels Pod 1.8.5c Sign provenance_handle
supersession pattern).

**Auto-provenance gated (D1.9.1.6).** `OP_OUTCOME_NEW_ERR` calls
`prov_append` after writing the err context, passing user-supplied
`err_source_op` (as opcode), `err_demod_id` (as demod_id), and
`vm_fetch_count` (as fetch_counter). The cap-gate is internal to
prov_append per Move 2 default-OFF doctrine.

**`vm_fetch_count` substrate gap closure at Pod 1.9.2 (D1.9.1.7).**
The substrate currently has no fetch counter (the field was
declared in ProvEvent at Pod 1.8.5c but never sourced). Pod 1.9.2
adds `vm_fetch_count` storage to vmdata.asm and increments at the
.fetch loop head in cbs_vm.asm. The counter is also useful for
substrate audit beyond D6.

**UNWRAP-on-wrong-discriminant push-sentinel-and-log (D1.9.1.8).**
V1.0 has no general fault path; halting on unwrap defeats the
purpose of typed errors. UNWRAP_OK on err pushes 1 zero sentinel +
logs; UNWRAP_ERR on ok pushes 4 zero sentinels + logs. Stack shape
preserved across both discriminant paths.

**Slot layout (128 bytes, OUTCOME_SLOT_SIZE):** discriminant +0x00,
value_type_id +0x08, value +0x10, reserved +0x18; err_code +0x20,
err_source_op +0x28, err_demod_id +0x30, err_fetch_counter +0x38;
Pod 3+ reserved +0x40-+0x6F; arena_id +0x70 (Pod 1.8.5c Move 3
inheritance); owner_demod_id +0x78 (Pod 1.8.5c Move 3 inheritance).
Symmetric with Sign and Energy slots.

**Pool sizing.** OUTCOME_POOL_SLOTS=64 (Sign/Energy precedent), bump
allocator, registry table per Pod 1.8.5b shape (mapping outcome_id
opaque counter → slot pointer; survives arena reorganization).

#### `Energy`, `Demod<S>` — v5 updates (preserved from v8)

`Energy` and `Demod<S>` definitions are unchanged from v1/v2. v4
added implementation commitments from Pod 1.1 audit decisions; v5
updated pod numbers after the arc slide. v8 concretized Energy as a
native primitive with the per-opcode cost table.

#### `Energy` — concretized in v8 (Pod 1.8)

The unit of endurance. Every operation costs joules; the cost table is
the kernel's honest accounting of what each opcode demands.

```
Energy := {
  joules:     u64,              // energy quantity
  source_op:  u64,              // opcode byte that generated this event (0 = unattributed)
}
```

**V1.0 concrete layout (128 bytes per slot, 8-byte aligned):**

```
offset  size    field
0x00    8       joules           (u64)
0x08    8       source_op        (u64; opcode byte, 0 = unattributed)
0x10    112     reserved         (V1.1+: sink, cost_table_idx, time_granted, etc.)
total   128
```

**Pool:** `vm_energy_pool`, 64 nodes x 128 bytes = 8 KB. Static allocation
in `boot/vmdata.asm` (placed by Pod 1.8). Matches Sign pool sizing per
the typed-primitive pool convention.

**Handles:** Operand stack carries an 8-byte `energy_id` (pool index).
`energy_id` 0 = invalid/null; valid range 1–64.

**Opcodes (0xD0–0xDF):**

```
OP_ENERGY_NEW        0xD0   construct Energy from stack args, return energy_id
OP_ENERGY_JOULES     0xD1   energy_id -> joules u64
OP_ENERGY_SOURCE_OP  0xD2   energy_id -> source_op u64
OP_ENERGY_FREE       0xD3   V1.0 no-op (bump allocator, no free list); V1.1+ activation
0xD4–0xDF            reserved (Energy V1.1+)
```

OP_ENERGY_NEW stack inputs (top-down): source_op, joules. Returns
energy_id on stack.

**Implementation (Pod 1.8):** All four Energy opcodes are wired in
`boot/cbs_vm.asm` with dispatch entries and handlers. `energy_alloc`
is a bump allocator returning (slot_ptr, 1-based energy_id), matching
the `sign_alloc` pattern (separate `lea` + `add` for RIP-relative
safety). Round-trip verified under QEMU: energy_id=1, joules=500,
source_op=160 (0xA0 = OP_SIGN_NEW). See
`recon/POD1.8_DECISION_RECORD.md`.

**Per-opcode cost table (Pod 1.8 — DONE).** New module
`boot/energy_costs.asm` owns the 256-entry static cost array (one
qword per opcode byte, 2048 bytes total) and the `energy_cost_lookup`
primitive (opcode byte in `al`, joules out in `rax`). The cost table
replaces the pre-Pod-1.8 flat 1j/fetch mechanism.

**Cost-table philosophy.** The cost table makes the energy spec literal.
Old mechanism (pre-Pod-1.8): observable cost = handler debit + 1j fetch
surcharge — a hidden tax. New mechanism: the cost IS the cost. D1.7.6's
stated values (100j SIGN_NEW, 5j accessors) are honored at face value.
Gating ops (OP_HALT, OP_RESERVE) = 0j: structural, not metabolic.
Undefined opcodes default to 1j: defensive, ensures forward progress or
eventual bankruptcy in error territory. Pod 1.8 introduces the mechanism;
calibration of per-opcode values is empirical work for a future
Rockbiter-driven tuning pod.

**Catalytic-gateway architecture.** The fetch loop is the catalytic
boundary. Old mechanism: every Sign handler did its own three-line
metabolic ritual (cmp+sub+add) — every enzyme accounting for its own
ATP. Cells don't work that way. Real cells pay ATP at well-defined
catalytic boundaries, not at every protein. Pod 1.8's fetch loop becomes
that boundary: fetch byte -> energy_cost_lookup -> bankruptcy check ->
debit -> dispatch handler. Handler runs pure-semantic, never touches
energy. The architecture is honest: proteins do the chemistry, the
gateway does the accounting.

**OP_RESERVE relationship (A5).** OP_RESERVE keeps raw u64 in V1.0.
Reserved energy values are not typed Energy primitives; the conversion
from raw u64 to typed Energy is V1.1+ work.

**OP_SIGN_ENERGY return type (A6).** OP_SIGN_ENERGY (0xA3) returns raw
u64 in V1.0, matching Pod 1.7's behavior. The typed-Energy return is
V1.1+ work.

**Layered convention (A7).** Energy as a typed primitive does not yet
appear on the operand stack as a typed handle the way Sign does. Energy
values flow as raw u64 through OP_RESERVE and the cost-table debit
machinery. The typed primitive is available via OP_ENERGY_NEW for
programs that want to construct, store, and read back Energy values
explicitly (Rockbiter, debug paths, future surfaces). The two flows
coexist in V1.0 and unify in V1.1+.

**Demod<S>.** Unchanged. Arrives in Pod 4 (Interpreter).

#### `Embedding` — concretized in Pod 3 (D3.1)

The fifth typed primitive: lexical embedding substrate-prep for Maid V1.0.
f32[384] vector under SipHash MAC over 196 qwords (header 4 + vector 192).
Immutable post-construction; full vector under MAC ensures content integrity
for Pod 3.5+ Maid similarity computations.

```
Embedding := {
  vector:        f32[384],         // canonical V1.0 dimension (D3.2)
  arena_id:      u64,              // strict delegation per Pod 1.10.2b1
  owner_demod_id: u64,             // strict delegation
  creator_cap_id: u64,             // provenance per Pod 1.10.2b2
  mac:           u64,              // SipHash-2-4 over 196 qwords header+vector
}
```

**V1.0 concrete layout (1576 bytes per slot, 8-byte aligned):**

```
offset  size    field
0x000   8       embedding_id_self    (registry-assigned u64)
0x008   8       arena_id             (u64)
0x010   8       owner_demod_id       (u64)
0x018   8       creator_cap_id       (u64; Pod 1.10.2b2 provenance pattern)
0x020   1536    vector[384]          (f32 little-endian; offsets 0x020..0x61F)
0x620   8       mac                  (siphash over 196 qwords header+vector)
total   1576 (197 qwords)
```

**Pool:** `vm_embedding_pool`, 64 nodes × 1576 bytes ≈ 100 KB. Static allocation
in `boot/vmdata.asm` (Pod 3). BSS-zero initialized; no construct_root_embedding
(program-driven; no boot-time auto-construction).

**Handles:** Operand stack carries an 8-byte `embedding_id` (registry index).
`embedding_id` 0 = `EMBEDDING_ID_NULL` reserved/invalid; valid range 1–64.

**Opcodes (0xC0–0xCF):**

```
OP_EMBEDDING_NEW       0xC0   pop vector_addr, push Outcome<embedding_id>
OP_EMBEDDING_ARENA     0xC1   pop embedding_id, MAC verify, push Outcome<arena_id>
OP_EMBEDDING_OWNER     0xC2   pop embedding_id, MAC verify, push Outcome<owner_demod_id>
OP_EMBEDDING_CREATOR   0xC3   pop embedding_id, MAC verify, push Outcome<creator_cap_id>
OP_EMBEDDING_GET_DIM   0xC4   pop embedding_id + dim_index, MAC verify, bounds-check,
                              push Outcome<f32-bit-cast-as-i64>
0xC5–0xCF              reserved (Pod 3.5+ semantic ops: similarity, lookup, ingestion)
```

**OP_EMBEDDING_NEW stack inputs (top-down):** vector_addr (pointer to inline 1536
bytes via OP_PUSH_STR + OP_DROP pattern). Returns Outcome<embedding_id>. Single-fire
spatial-merge via .construct_ok_outcome's internal babylon_charge_lineage call (D3.9
greenfield axiom inherited by construction; no Path A retrofit needed).

**OP_EMBEDDING_GET_DIM stack inputs (top-down):** dim_index, embedding_id. Returns
Outcome<f32-bit-cast-as-i64>. f32 dimension loaded via 32-bit mov (zero-extend to
i64; IEEE bit pattern preserved exactly per D3.3 round-trip discipline).

**Energy cost (Pod 3 D3.X cost basis):** 100j for OP_EMBEDDING_NEW (matches Sign
content-bearing primitive convention); 1j metabolic for accessors per existing
Cap accessor convention.

**Authority:** OP_EMBEDDING_NEW gated by BIT_EMBEDDING_FORGE = (1 << 4) = 0x10
in cap_bitmap V1.0 vocabulary (D2.2.2 organic earn convention; first reserved-bit
consumer; 5/64 bits earned post-Pod-3). Bit-check fires at .op_embedding_new
post-pop / pre-construct per D2.2.6; failure routes to ERR_CAP_INSUFFICIENT_AUTHORITY.

**Maid V1.0 architecture:** the codebook is the *collection* of embeddings in the
pool (D3.7); Maid layers semantic indexing/lookup logic above the embedding pool
in Pod 3.5+. No separate Codebook typed primitive in V1.0 — substrate stays
minimal; semantics stay in Maid.

#### Substrate-archaeology asymmetry (D3.11 verification surface authority hierarchy)

Post-Pod-3 the substrate has a structurally explicit two-tier integrity model:
- **MAC-protected pools**: Cap (Pod 1.10.2a), Outcome (Pod 1.9.2a), Embedding (Pod 3)
- **Non-MAC pools**: Sign (Pod 1.7), Energy (Pod 1.8) — pre-Pod-1.10.2a-MAC-convention

Sign + Energy were not retroactively MAC-retrofitted because the operand-stack ABI
was already locked when MAC was introduced for Cap. Their integrity model is
parallel-structure-tracking (registry indirection + slot-write discipline). DEFERRED
#81 forward-logs MAC-retrofit candidate when integrity-attack surface becomes
empirical.

**D3.11 doctrine: in-tree state (defines.asm, asm files) is canon; narrative
documents (this RECONSTITUTION.md, design docs in recon/) lag and require periodic
synchronization.** Architect cross-checks defer to in-tree state. Recon catches
canon-doc-stale-state drift as a substrate-evolution verification surface (Pod 3
HALT 1 Pre-A10 caught a three-pod-lag in this document's own Sign slot layout
spec). Future canon refreshes after every retrofit touching slot layouts; periodic
full audit pass when accumulated drift becomes load-bearing.

### Layer 2 — The Trinity (CBS, hosted on Layer 1)

(Unchanged from v2.)

**Status: Design only. No implementation exists yet. Layer 2 arrives
in Pods 2-4.**

Three system services. Each written in CBS. Cop (capability service +
energy market), Maid (semantic codebook = filesystem), Interpreter
(pub-sub demodulation layer).

### Layer 3 — Surfaces (CBS, demods on the trinity)

(Unchanged from v2.)

**Status: Design only. No demod registration mechanism exists yet.
Layer 3 arrives in Pod 5.**

Bastian, Gmork, Auryn, Atreyu, Falkor, Empress, Koreander, Rockbiter,
Southern Oracle, Artax — each surface is a Demod registered with
Interpreter.

---

## What survives, what rebuilds (v4 update)

### Resurrects from `_future/` — Pod 0.9 deep read clarified

- `kernel/_future/cap_graph.asm` → **design ideas survive into Pod 1's
  Cap<R>**, code is rewritten from scratch with proper 64-bit math,
  bug-fixed budget accounting, and the spatial-merge mechanism
  preserved as a feature. Per Pod 0.9 memo: cap_graph is "80%
  recoverable as design, 0% recoverable as code." Pod 1 takes the
  design and writes correct code.

- `kernel/_future/paging.asm` → **design notes only**. V1.0 doesn't
  need it. Resurrects in Pod 2+ as needed. The 1GB-page identity map,
  write-combining framebuffer, and post-EBS CR3 ordering are the
  design constraints to remember when paging arrives.
- `drivers/_future/fat32_write.asm` → resurrects when Maid (Pod 3)
  needs FAT32 transport. Unchanged from v2.
- `drivers/_future/gpu_intel.asm` → low priority; UEFI GOP suffices
  through V1. Unchanged from v2.

### Exiled in place — Pod 1.1 audit identified (v4)

- **`cap_atreyu` handler (Q3):** Six editor operations (get/set_size,
  get/set_char, insert, delete) at `cbs_vm.asm:408–493` have no
  dispatch entry in `op_use_cap` — unreachable dead code. Left in
  place until Pod 1.11 (cap ops retirement). Pod 6 (Atreyu Walks)
  decides whether to rebuild from this skeleton or start fresh.
  DEFERRED #11 tracks this.

---

## The honest hard problems (v8 — Energy/cost-table DONE)

| # | Problem | Lands in |
|---|---------|----------|
| 1 | Typed CBS VM with Sign/Cap/Outcome/Energy/Demod as native | Pod 1 (14 sub-pods; Sign DONE 1.7, Energy DONE 1.8) |
| 2 | Cap ops replacement (retire 0x90/0x91, typed Cap<R> opcodes) | Pod 1.10–1.11 |
| 3 | Ed25519 in NASM (placeholder field in V1.0; real in V1.1) | Pod 2 |
| 4 | ~~Paging resurrection~~ → **deferred post-V1** (DEFERRED #9) | Post-V1 |
| 5 | Lexical embeddings for Maid V1 | Pod 3 |
| 6 | Log-structured content-addressed store | Pod 3 |
| 7 | FAT32 write resurrection | Pod 3 |
| 8 | Pub-sub demod routing with isolation | Pod 4 |
| 9 | Surfaces refactor to use trinity | Pod 5 |
| 10 | Neural embeddings, quantized inference (Maid V2) | Pod 9 |
| 11 | Peer transport, capability addressing (Auryn far) | Pod 10 |

Pod 1 spans fourteen sub-pods (1.0 through 1.13). Two prerequisite
VM-fix pods and two canon-update pods precede typed-primitive work;
six typed-primitive pods follow; one cap data pod, one cap ops pod,
one Demod pod, and one cleanup pod close it out. Pace is set by
recon-protocol discipline, not by calendar.

---

## The pod arc (v8 — Pod 1.7 sealed, Pod 1.8 DONE)

```
Pod 0 — Foundation Lock                                    [SEALED — pod0-complete]
├── 0.0  Reference lock + canonical docs                   [DONE — e2f5db8]
├── 0.1  Extract defines.asm                               [DONE — 4f02dcd]
├── 0.2  Polish auryn.asm header                           [DONE — 4489d01]
├── 0.2.5 Repo-wide archaeology recon                      [DONE — 7facf2a]
├── 0.3  Repo cleanup                                      [DONE — 50b2b4a]
├── 0.4  Canon updates v2                                  [DONE — a521db2/8a04b16]
├── 0.5  Header polish (5 boot/ modules)                   [DONE — 9f86040]
├── 0.6  Drivers + data.asm                                [DONE — fbb8ba3/e6d41b3]
├── 0.7  auryn_puts consolidation                          [DONE — 4ff12d8]
├── 0.8  Final sign-off + tag                              [DONE — d68167c, tagged pod0-complete]
└── 0.9  cap_graph + paging deep read                      [DONE — 0ab996c]

Pod 1 — Engywook Re-Forged (typed VM with Sign/Cap/Outcome/Energy/Demod)
│       Cap<R> design informed by Pod 0.9's salvaged spatial-merge mechanic.
│       Current cap ops (0x90/0x91) replaced, not extended.
├── 1.0  prompts/ backfill                                 [DONE — b30860e]
├── 1.1  VM substrate audit (recon-only)                   [DONE — 6d47237]
├── 1.2  Canon update v4                                   [DONE — e69f51f]
├── 1.3  OP_CALL/OP_RET fix + OP_HALT                     [DONE — ed5c68a]
├── 1.4  Canon update v5 (this document)                   [DONE — 7a825f2]
├── 1.5  64-bit integer width migration                    [DONE — e6a2cc2]
├── 1.5.5 Pre-Pod-1.6 architect orientation recon           [DONE — b560a6c]
├── 1.6  Sign as native type (0xA0–0xAF)                   [DONE — 6264dbc]
├── 1.7  Sign source implementation (opcodes + pool + test) [DONE — 1d8593f]
├── 1.8  Energy: per-opcode cost table (0xD0–0xDF)         [DONE — Pod 1.8]
├── 1.9  Outcome<T>: typed errors + stack bounds (0xE0–0xE4 per v9 D1.9.1.4)
│   ├── 1.9.1 Outcome canon + RECONSTITUTION v9 patch     [DONE — this commit]
│   ├── 1.9.2 Outcome source: pool, registry, 5 opcode handlers, vm_fetch_count [planned — closes DEFERRED #13]
│   └── 1.9.3 Sign/Energy accessor refit to return Outcome [planned — closes DEFERRED #16]
├── 1.10 Cap<R> data structures (0xB0–0xB4 per v10 D1.10.1.2)
│   ├── 1.10.1 Cap canon + RECONSTITUTION v10 patch        [DONE — this commit]
│   ├── 1.10.2a Cap substrate plumbing (slot pool, registry, cap_stack, ROOT_CAP, SipHash, RDSEED/RDRAND) [planned]
│   └── 1.10.2b Cap opcode handlers + cost table + tools + tests + Sign/Energy/Outcome retrofit per D1.10.1.8 [planned]
├── 1.11 Cap ops retirement (retire 0x90/0x91)             [planned — cap replacement]
├── 1.12 Demod<S> registration (0xE0–0xEF)                 [planned — demod]
└── 1.13 Pod 1 cleanup + sign-off                          [planned — cleanup]

Pod 2 — Cop is Born (capability service + Ed25519 + energy market)

Pod 3 — Maid is Born (codebook substrate: log store + graph + lexical embed)

Pod 4 — Interpreter is Born (pub-sub demod routing with isolation)

Pod 5 — Surfaces Refactor (every surface becomes a Demod)

Pod 6 — Atreyu Walks (editor)

Pod 7 — Empress + Koreander (search + docs)

Pod 8 — Rockbiter + Falkor (scheduler + trust)

Pod 9 — Maid V2 (neural embeddings)

Pod 10 — Auryn Speaks Far (peer transport)
```

---

## The closing commitment (unchanged)

Every layer earns its keep. Every byte in the bootstrap is justified by
what it lets CBS do above it. Every type in the VM is justified by what
it lets the trinity express. Every service in the trinity is justified
by what it lets the surfaces become. Every surface is justified by what
it lets the user think.

Energy budgeting is novel. It is not the headline. The headline is the
organism — and the organism is what we're building.

The previous engineer's discipline preserved the design ideas through
exile. Pod 0 walked the perimeter and named what was there. Pod 0.9
read what Atreyu found. Pod 1 lights Engywook's full forge.

From layer 1 kernel up.

— Chauncey
CodebookOS Senior Architect
April 29, 2026 (v8)
