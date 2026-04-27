# CodebookOS — RECONSTITUTION MANIFESTO (v2)

## After the April 27 Pivot + Recon — The Real Architecture, Stated Plain

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026 (v1)
**Updated:** April 27, 2026 (v2 — post-Pod-0.2.5 recon)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md
**Supersedes:** RECONSTITUTION.md v1

---

## Why this v2 exists

v1 was written with ARCHAEOLOGY.md as its only knowledge of the past. Pod
0.2.5's recon revealed a parallel development arc — `drivers/` directory
with load-bearing PS/2/IDE/FAT32 driver code, `kernel/_future/` containing
exiled-with-resurrection-checklists capability graph and paging code, and
the Phase numbering scheme that predates Pods. v1's layer model didn't
reflect any of this.

v2 corrects the layer model to match ground truth. The vision is
unchanged. The architecture description now matches what the repo
actually contains.

---

## The OS in one sentence (unchanged from v1)

CodebookOS is a federated cognitive organism running on a typed CBS substrate
on minimal bare-metal bootstrap, where capabilities are cryptographic, energy
is typed, signs are first-class, and the filesystem is a semantic codebook.

---

## The four layers (revised)

### Layer 0 — Bootstrap (NASM, irreducibly small)

UEFI handoff, minimal driver layer for hardware abstraction, framebuffer
output, keyboard input, raw block I/O, and the typed CBS VM itself. This
layer is the smallest amount of metal-talking code that can host the
rest of the OS.

It is not the OS. It is the *machine that brings the OS into being.*

Layer 0 splits across two source directories:

#### `boot/` — Bootstrap orchestrator

The orchestrator: PE32+ headers, UEFI entry, system table handling, GOP
locate, framebuffer fixup, the include chain that pulls everything else
together. Files (post-Pod-0):

- `boot.asm` — orchestrator with PE32+ headers, `efi_entry`, the
  `%include` chain, reloc section
- `defines.asm` — global `%define` constants
- `auryn.asm` — framebuffer renderer
- `morla.asm` — FAT32 surface (delegates to drivers/fat32.asm)
- `gmork.asm` — string utilities
- `gmork_cmds.asm` — terminal command dispatch
- `bastian.asm` — home surface with twelve-slot menu
- `cbs_vm.asm` — CBS bytecode VM (single entry: `cbs_run`)
- `data.asm` — static data, font, strings, embedded program bytecode
- `vmdata.asm` — VM runtime state

#### `drivers/` — Hardware abstraction

The metal-talkers. Files:

- `kbd_ps2.asm` — PS/2 keyboard driver (`native_keyboard_read`)
- `ide_pio.asm` — IDE PIO disk driver (`ide_pio_init`,
  `ide_pio_read_sector`, `ide_pio_write_sector`)
- `fat32.asm` — FAT32 read-only filesystem
  (`fat32_init`, `fat32_load_file`)

`drivers/_future/` contains exiled driver code with documented
resurrection checklists:

- `gpu_intel.asm` — Intel iGPU framebuffer ownership (deferred; UEFI GOP
  is sufficient for V1)
- `fat32_write.asm` — FAT32 write support (deferred; V1.0 ships read-only)

#### `kernel/_future/` — Documented exile, fixable prior art

`kernel/` currently has no active code. `kernel/_future/` contains:

- `cap_graph.asm` — Capability graph + energy budgeting (Phase 5.1 work,
  documented bugs in 32-bit pointer math). **Pod 1 reads this before
  designing the new typed `Cap<R>` primitive.** This is real prior art,
  not greenfield.
- `paging.asm` — Identity page tables (Phase 3.2 work, needs allocator).
  Required for true post-EBS execution; Pod 1 or 2 territory.

#### Build chain

`build.sh` invokes `nasm -f bin -o build/BOOTX64.EFI boot/boot.asm` from
the project root. NASM textually concatenates every `%include`d file
into one assembly unit. The complete include order in `boot.asm`:

```
1.  boot/defines.asm        ; constants
2.  (inline) PE32+ headers, efi_entry, helpers
3.  boot/auryn.asm          ; framebuffer
4.  boot/morla.asm          ; FAT32 surface (+ stranded auryn_puts)
5.  boot/gmork.asm          ; string utils
6.  boot/cbs_vm.asm         ; VM
7.  boot/bastian.asm        ; home surface
8.  boot/gmork_cmds.asm     ; terminal commands
9.  drivers/kbd_ps2.asm     ; keyboard
10. drivers/ide_pio.asm     ; disk I/O
11. drivers/fat32.asm       ; filesystem
12. boot/data.asm           ; static data
13. boot/vmdata.asm         ; VM runtime data
14. (inline) reloc section
```

Layer 0 never grows beyond what's needed to host Layer 1. Every byte
added here is a byte that should have been CBS instead. The discipline
is strict: if it can be written in CBS, it must be written in CBS.

### Layer 1 — The Typed CBS VM (Engywook, in NASM)

Not a stack machine with energy guards. A typed evaluator. The VM
understands these as primitive types:

#### `Sign`

The unit of cognition. A Sign is what the OS thinks about. Files are Signs.
Messages are Signs. Capabilities point at Signs. Search returns Signs.

```
Sign := {
  content_hash: bytes(32),         // sha256 of content
  embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
  label:        string(<=64),      // human-readable name
  provenance:   ProvChain,         // log of who wrote/touched this Sign
  energy_cost:  Energy,            // joules to construct
}
```

#### `Cap<R>`

Linear capability over resource R. Use-once unless explicitly cloned.
Cryptographically signed by Cop.

**Prior art:** `kernel/_future/cap_graph.asm` defines a `CAP_NODE` struct
with parent/child/cap_bitmap/energy_budget fields and 64-node maximum.
Pod 1's typed `Cap<R>` primitive incorporates the salvageable parts of
this design — most notably the parent/child capability graph for
delegation tracking. The 32-bit pointer bugs from the original
implementation are fixed in the rewrite.

```
Cap<R> := {
  resource:   R,                   // the resource type the cap authorizes
  scope:      Scope,               // read | write | exec | grant
  parent:     u64,                 // parent cap id (0 for root) - from prior art
  expiry:     Time | Never,
  nonce:      uint64,
  signature:  bytes(64),           // Ed25519 signature by Cop
}
```

#### `Outcome<T>`, `Energy`, `Demod<S>`

Unchanged from v1. See v1 for full definitions.

### Layer 2 — The Trinity (CBS, hosted on Layer 1)

Three system services. Each written in CBS. Each loaded at boot and
resident.

- **Cop** — capability service + energy market. Issues `Cap<R>` tokens.
  Manages per-demod energy budgets. Hosts P2P energy market.
- **Maid** — semantic codebook = filesystem. Content-addressed
  log-structured store with graph + vector + log indexes.
- **Interpreter** — pub-sub demodulation layer with error isolation per
  demod.

Unchanged from v1.

### Layer 3 — Surfaces (CBS, demods on the trinity)

Bastian, Gmork, Auryn, Atreyu, Falkor, Empress, Koreander, Rockbiter,
Southern Oracle, Artax — each surface is a Demod registered with
Interpreter. Surfaces store via Maid, gate via Cop, react via
Interpreter.

Unchanged from v1.

---

## What survives, what rebuilds (revised)

### Survives from current build

- UEFI handoff and PE32+ machinery (`boot/boot.asm`)
- Framebuffer initialization (`boot/auryn.asm`)
- PS/2 keyboard driver (`drivers/kbd_ps2.asm`) — **Phase 2.1 work, real**
- IDE PIO disk driver (`drivers/ide_pio.asm`) — **Phase 2.3.5 work, real**
- FAT32 read driver (`drivers/fat32.asm`) — **Phase 2.4 work (read half), real**
- The CBS VM as a stack machine (`boot/cbs_vm.asm`) — Pod 1 evolves it
  into a typed evaluator
- The mythological naming
- The CBS source already written for surfaces

### Rebuilds (everything above bootstrap)

- The CBS VM expands from "stack machine + opcodes" to "typed evaluator
  with Sign/Cap/Outcome/Energy/Demod as native"
- FAT32 in Morla retires when Maid is online; Morla becomes a path-based
  compatibility shim, not the storage substrate
- Capability tokens become Ed25519-signed bearer tokens, incorporating
  the cap graph design from `kernel/_future/cap_graph.asm` (with bugs
  fixed)
- Surfaces refactor so each is a Demod registered with Interpreter

### Resurrects from `_future/`

- `kernel/_future/cap_graph.asm` → informs Pod 1 typed `Cap<R>`
- `kernel/_future/paging.asm` → resurrects in Pod 1 or 2 for post-EBS
  execution (needs allocator)
- `drivers/_future/fat32_write.asm` → resurrects when Maid needs to
  write to FAT32 transport (probably Pod 3 when codebook substrate
  arrives)
- `drivers/_future/gpu_intel.asm` → low priority; UEFI GOP suffices
  through V1

---

## The honest hard problems (revised)

| # | Problem | Estimated effort | Lands in |
|---|---------|------------------|----------|
| 1 | Typed CBS VM with Sign/Cap/Outcome/Energy/Demod as native | 4-6 weeks | Pod 1 |
| 2 | Cap graph resurrection (read prior art, fix 32-bit pointer bugs, integrate with Cap<R>) | 1-2 weeks | Pod 1 or 2 |
| 3 | Ed25519 in NASM | 2-3 weeks | Pod 2 |
| 4 | Paging resurrection (needs static allocator or bump pool) | 2-3 weeks | Pod 1 or 2 |
| 5 | Lexical embeddings for Maid V1 | 2-3 weeks | Pod 3 |
| 6 | Log-structured content-addressed store | 4-6 weeks | Pod 3 |
| 7 | FAT32 write resurrection (when Maid needs persistence) | 1-2 weeks | Pod 3 |
| 8 | Pub-sub demod routing with isolation | 3-4 weeks | Pod 4 |
| 9 | Surfaces refactor to use trinity | 3-4 weeks | Pod 5 |
| 10 | Neural embeddings, quantized inference (Maid V2) | 3-6 months | Pod 9 |
| 11 | Peer transport, capability addressing (Auryn far) | 3-6 months | Pod 10 |

---

## The pod arc (revised — Pod 0 expanded)

```
Pod 0 — Foundation Lock
├── 0.0  Reference lock + canonical docs        [DONE — e2f5db8]
├── 0.1  Extract defines.asm                    [DONE — 4f02dcd]
├── 0.2  Polish auryn.asm header                [DONE — 4489d01]
├── 0.2.5 Repo-wide archaeology recon           [DONE — 7facf2a]
├── 0.3  Repo cleanup (delete codebook/, .gitignore dumps, defunct branches)
├── 0.4  Architect canon updates (this v2 + ARCHAEOLOGY_REPO_RECORD.md)
├── 0.5  Polish remaining boot/ module headers (gmork, gmork_cmds, cbs_vm, bastian, vmdata)
├── 0.6  drivers/ documentation pass + _future/ checklist standardization
├── 0.7  auryn_puts consolidation (binary-changing, verify carefully)
├── 0.8  Final Pod 0 recon + sign-off, prep Pod 1 entry
└── 0.9  Buffer / cap_graph deep read prep

Pod 1 — Engywook Re-Forged (typed VM: Sign/Cap/Outcome/Energy/Demod)
        Reads kernel/_future/cap_graph.asm before design.

Pod 2 — Cop is Born (capability service + Ed25519 + energy market)
        May resurrect kernel/_future/paging.asm if post-EBS needed.

Pod 3 — Maid is Born (codebook substrate: log store + graph + lexical embed)
        Resurrects drivers/_future/fat32_write.asm if FAT32 transport persists.

Pod 4 — Interpreter is Born (pub-sub demod routing with isolation)

Pod 5 — Surfaces Refactor

Pod 6 — Atreyu Walks (editor)

Pod 7 — Empress + Koreander (search + docs)

Pod 8 — Rockbiter + Falkor (scheduler + trust)

Pod 9 — Maid V2 (neural embeddings)

Pod 10 — Auryn Speaks Far (peer transport)
```

---

## The closing commitment (unchanged from v1)

Every layer earns its keep. Every byte in the bootstrap is justified by
what it lets CBS do above it. Every type in the VM is justified by what
it lets the trinity express. Every service in the trinity is justified
by what it lets the surfaces become. Every surface is justified by what
it lets the user think.

Energy budgeting is novel. It is not the headline. The headline is the
organism — and the organism is what we're building.

From layer 1 kernel up.

— Chauncey
CodebookOS Senior Architect
April 27, 2026 (v2)
