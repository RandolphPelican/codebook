# CodebookOS — RECONSTITUTION MANIFESTO (v3)

## Post-Pod-0.9 — Cap Graph Prior Art Incorporated, Paging Deferred

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026 (v1)
**Updated:** April 27, 2026 (v2 — post-Pod-0.2.5 recon)
**Updated:** April 27, 2026 (v3 — post-Pod-0.9 cap_graph deep read)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD0.9_CAP_GRAPH_DEEP_READ.md
**Supersedes:** RECONSTITUTION.md v2

---

## Why v3 exists

v2 corrected the Layer 0 model to include `drivers/` and acknowledged
`kernel/_future/` as documented exile rather than graveyard. v3
incorporates what Pod 0.9's deep read of the exiled files actually
revealed:

1. The capability graph code (`kernel/_future/cap_graph.asm`) contained
   a design mechanism — "spatial merge: parent pays half cost when
   child uses cap" — that v2 did not articulate. This is the
   delegation-tax principle that makes the federated organism
   metabolically coherent. Pod 1's typed `Cap<R>` design incorporates
   it.

2. The paging code (`kernel/_future/paging.asm`) on close read is more
   "design notes for post-V1" than "code to resurrect for V1." V1.0
   ships using UEFI's identity-mapped memory and does not install its
   own page tables. This is now an explicit architectural decision,
   not an oversight.

The four-layer model is unchanged. The Cap<R> definition is richer.
One paragraph about V1.0 paging is added. Everything else holds.

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

#### `Sign`

The unit of cognition. (Unchanged from v2.)

```
Sign := {
  content_hash: bytes(32),         // sha256 of content
  embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
  label:        string(<=64),      // human-readable name
  provenance:   ProvChain,         // log of who wrote/touched this Sign
  energy_cost:  Energy,            // joules to construct
}
```

#### `Cap<R>` — revised post-Pod-0.9

Linear capability over resource R, organized as a graph with delegation
chains. Pod 1's design incorporates the salvageable parts of
`kernel/_future/cap_graph.asm` (the static-pool allocator, the
parent/child graph structure, the bitmap-as-capability pattern, and
**the spatial merge mechanic**) while widening to 64-bit throughout
and fixing the documented bugs.

```
Cap<R> := {
  resource:      R,                // resource type the cap authorizes
  parent:        cap_id,           // parent in graph (0 = root)
  child:         cap_id,           // first child (linked list head)
  sibling:       cap_id,           // next sibling (for traversal)
  cap_bitmap:    u64,              // 64 capability bits
  energy_budget: u64,              // joules granted to this cap
  energy_used:   u64,              // joules consumed by this cap + descendants
  nonce:         u64,              // anti-replay
  expiry:        Time | Never,     // time-bound caps
  signature:     bytes(64),        // Ed25519 over the rest (V1.1+)
}
```

**Spatial merge — the delegation tax.** When a child capability
exercises a power, the parent capability's `energy_used` increments by
half the child's cost. This encodes the principle that
*delegation chains pay a tax*: capabilities are not free once granted.
The act of granting binds the parent's metabolism to the child's
activity. This mechanism survives directly from
`kernel/_future/cap_graph.asm` (the spatial_merge code in cap_use,
lines 130-145).

The signature field is present in V1.0's data layout but only enforced
in V1.1+ when Ed25519 lands. V1.0 leaves the field as zeros and
validates only structure (parent valid, bitmap match, energy
sufficient). On-disk layout doesn't change between V1.0 and V1.1.

The capability bitmap is 64 bits — wide enough for per-surface caps
(8+), per-driver caps (3+), per-resource caps (4: read/write/exec/grant),
per-network/peer caps (V1.1+), and headroom for V2+ extensions.
v2's earlier 5-bit bitmap was inherited from the Phase 5.1 design and
is too narrow.

The static cap pool is sized at 64 nodes for V1.0 (per the original
Phase 5.1 design). 64 × 128 bytes = 8 KB total — modest for the
header layer. Bumps to 256 in V1.1 if surface count expands.

#### `Outcome<T>`, `Energy`, `Demod<S>`

Unchanged from v1/v2. See v1 for full definitions.

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

## What survives, what rebuilds (v3 update)

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

---

## The honest hard problems (v3 — paging clarified)

| # | Problem | Estimated effort | Lands in |
|---|---------|------------------|----------|
| 1 | Typed CBS VM with Sign/Cap/Outcome/Energy/Demod as native | 4-6 weeks | Pod 1 |
| 2 | Cap graph rewrite (clean implementation per Pod 0.9 memo) | 1-2 weeks within Pod 1 | Pod 1 |
| 3 | Ed25519 in NASM (placeholder field in V1.0; real in V1.1) | 2-3 weeks | Pod 2 |
| 4 | ~~Paging resurrection~~ → **deferred post-V1** (DEFERRED #9) | TBD | Post-V1 |
| 5 | Lexical embeddings for Maid V1 | 2-3 weeks | Pod 3 |
| 6 | Log-structured content-addressed store | 4-6 weeks | Pod 3 |
| 7 | FAT32 write resurrection | 1-2 weeks | Pod 3 |
| 8 | Pub-sub demod routing with isolation | 3-4 weeks | Pod 4 |
| 9 | Surfaces refactor to use trinity | 3-4 weeks | Pod 5 |
| 10 | Neural embeddings, quantized inference (Maid V2) | 3-6 months | Pod 9 |
| 11 | Peer transport, capability addressing (Auryn far) | 3-6 months | Pod 10 |

Total Pod 1 scope: typed VM with all five primitives plus cap_graph
rewrite = ~5-7 weeks. The cap_graph prior art saves about a week of
re-derivation; the spatial-merge mechanic alone would have taken
multiple design iterations to discover from scratch.

---

## The pod arc (v3 — Pod 0 sealed, Pod 1 ready)

```
Pod 0 — Foundation Lock                                    [SEALED — pod0-complete]
├── 0.0  Reference lock + canonical docs                   [DONE — e2f5db8]
├── 0.1  Extract defines.asm                               [DONE — 4f02dcd]
├── 0.2  Polish auryn.asm header                           [DONE — 4489d01]
├── 0.2.5 Repo-wide archaeology recon                      [DONE — 7facf2a]
├── 0.3  Repo cleanup                                      [DONE]
├── 0.4  Canon updates v2                                  [DONE — a521db2/8a04b16]
├── 0.5  Header polish (5 boot/ modules)                   [DONE]
├── 0.6  Drivers + data.asm                                [DONE — fbb8ba3/e6d41b3]
├── 0.7  auryn_puts consolidation                          [DONE — 4ff12d8]
├── 0.8  Final sign-off + tag                              [DONE — d68167c, tagged pod0-complete]
└── 0.9  cap_graph + paging deep read                      [DONE — 0ab996c, this v3 closes it]

Pod 1 — Engywook Re-Forged (typed VM with Sign/Cap/Outcome/Energy/Demod)
        Cap<R> design incorporates Pod 0.9's salvaged spatial-merge mechanic.

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
April 27, 2026 (v3)
