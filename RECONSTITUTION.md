# CodebookOS — RECONSTITUTION MANIFESTO (v6)

## Post-Pod-1.6 — Sign as Native Type, Typed Primitive Pattern Established

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Compiled by:** Chauncey (Claude)
**Compiled:** April 27, 2026 (v1)
**Updated:** April 27, 2026 (v2 — post-Pod-0.2.5 recon)
**Updated:** April 27, 2026 (v3 — post-Pod-0.9 cap_graph deep read)
**Updated:** April 27, 2026 (v4 — post-Pod-1.1 VM audit decisions)
**Updated:** April 27, 2026 (v5 — post-Pod-1.3 VM fixes, width-migration decisions)
**Updated:** April 28, 2026 (v6 — post-Pod-1.6 Sign as native type, typed-primitive pattern)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD0.9_CAP_GRAPH_DEEP_READ.md, recon/POD1.1_VM_AUDIT.md, recon/POD1.2_DECISION_RECORD.md, recon/POD1.4_DECISION_RECORD.md, recon/POD1.6_DECISION_RECORD.md
**Supersedes:** RECONSTITUTION.md v5

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
   (0x90) and `OP_USE_CAP` (0x91) are retired in Pod 1.10. Cap<R>
   typed primitives replace them entirely — the spatial-merge design
   from Pod 0.9 informs the replacement, but no current cap code
   survives.

4. **Opcode space allocated.** Typed primitives claim `0xA0–0xEF`
   (80 slots). Energy moves from per-fetch flat cost to per-opcode
   cost table in Pod 1.7. Stack bounds produce `Outcome<T>` errors
   in Pod 1.8.

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

**V1.0 concrete layout (128 bytes per slot, 8-byte aligned):**

```
offset  size    field
0x00    32      content_hash       (sha256 raw bytes)
0x20    64      label              (length-prefixed ASCII; byte 0 = length, bytes 1–63 = chars)
0x60    8       energy_cost        (u64 joules; Pod 1.7 typed wrapper)
0x68    8       embedding_handle   (u64; index into vm_embed_pool, defined Pod 3+)
0x70    8       provenance_handle  (u64; index into vm_provchain_pool, defined Pod 3+)
0x78    8       reserved           (V1.1 expansion sentinel)
total   128
```

**Pool:** `vm_sign_pool`, 64 nodes × 128 bytes = 8 KB. Static allocation
in `boot/data.asm` (placed by Pod 1.7). Matches cap pool sizing (64 ×
128 = 8 KB) per the typed-primitive pool convention (see below).

**Handles:** Operand stack carries an 8-byte `sign_id` (pool index).
`sign_id` 0 = invalid/null; valid range 1–64.

**Label representation:** Length-prefixed ASCII. Byte 0 holds length
(0–63); bytes 1–63 hold characters. UTF-8 deferred to V1.1.

**Embedding and ProvChain:** Forward-declared 8-byte handles to pools
landing in Pod 3 (Maid) and Pod 9 (Maid V2). Handle value 0 = no
embedding / no provenance, valid in V1.0.

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
OP_SIGN_NEW      0xA0   construct Sign from stack args, return sign_id
OP_SIGN_HASH     0xA1   sign_id → content_hash (stack shape TBD Pod 1.7)
OP_SIGN_LABEL    0xA2   sign_id → label as string
OP_SIGN_ENERGY   0xA3   sign_id → energy_cost u64
0xA4–0xAF        reserved (Pod 3+ provenance, embedding ops)
```

OP_SIGN_NEW stack inputs (top-down): provenance_handle, embedding_handle,
energy_cost, label_addr, hash_addr. Returns sign_id on stack.

#### `Cap<R>` — revised post-Pod-0.9, cap ops replaced post-Pod-1.1

Linear capability over resource R, organized as a graph with delegation
chains. Pod 1's design incorporates the salvageable *design ideas* of
`kernel/_future/cap_graph.asm` (the static-pool allocator, the
parent/child graph structure, the bitmap-as-capability pattern, and
**the spatial merge mechanic**) while widening data fields to 64-bit
and fixing the documented bugs.

**v4 — current cap ops retired (Q1).** The existing `OP_GRANT_CAP`
(0x90) and `OP_USE_CAP` (0x91) in `boot/cbs_vm.asm` are
magic-number token dispatchers — they create and consume untyped
`0xCA000000 + resource_id` tokens via hardcoded comparisons. These
do not implement Cap<R> as described here. Pod 1.10 retires them
entirely and replaces them with typed capability opcodes in the
`0xA0–0xEF` range (see opcode allocation below). No current cap
code survives into the typed system.

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
| `0xA0–0xAF` | Sign | 1.6 |
| `0xB0–0xBF` | Cap<R> | 1.9–1.10 |
| `0xC0–0xCF` | Outcome<T> | 1.8 |
| `0xD0–0xDF` | Energy | 1.7 |
| `0xE0–0xEF` | Demod<S> | 1.11 |

The existing `0x00–0x9F` range retains current opcode assignments
(arithmetic, stack, flow control, I/O). The `0xF0–0xFF` range is
reserved for future expansion.

Naming pattern for typed-primitive opcodes: `OP_<TYPE>_<OP>` — e.g.
`OP_SIGN_NEW`, `OP_ENERGY_ADD`, `OP_CAP_GRANT`, `OP_OUTCOME_OK`.

#### Typed primitive representation pattern — v6 (Pod 1.6)

All typed primitives in the CBS VM follow a common representation
pattern, established by Sign in Pod 1.6 and inherited by Energy
(Pod 1.7), Outcome<T> (Pod 1.8), Cap<R> (Pod 1.9–1.10), and
Demod<S> (Pod 1.11):

1. **Static pool with stack handle.** Each primitive type has a
   statically-allocated pool in `boot/data.asm`. The operand stack
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

#### `Outcome<T>`, `Energy`, `Demod<S>` — v5 updates

`Outcome<T>`, `Energy`, and `Demod<S>` definitions are unchanged from
v1/v2. v4 added implementation commitments from Pod 1.1 audit decisions;
v5 updates pod numbers after the arc slide.

**Outcome<T> as stack-error mechanism (Q8).** Stack underflow and
overflow produce `Outcome<T>` typed errors rather than halting the VM
or silently corrupting state. The specific error representation
(error codes, stack-frame tagging, etc.) is deferred to Pod 1.8 when
`Outcome<T>` becomes a native VM type. The principle is decided: stack
violations are typed results, not fatal traps. (Pod 1.3's interim
implementation uses halt-on-violation with diagnostic messages;
Pod 1.8 replaces these with typed `Outcome<T>` results.)

**Energy: per-opcode cost table (Q7).** The current VM debits 1 joule
per fetch cycle regardless of opcode. Pod 1.7 introduces a per-opcode
cost table — `OP_MUL` costs more than `OP_NOP`, `OP_GRANT_CAP` costs
more than `OP_ADD`. `OP_RESERVE` remains the per-program budget
mechanism. The flat per-fetch base cost is replaced, not supplemented.

**Demod<S>.** Unchanged. Arrives in Pod 4 (Interpreter).

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
  place until Pod 1.10 (cap ops retirement). Pod 6 (Atreyu Walks)
  decides whether to rebuild from this skeleton or start fresh.
  DEFERRED #11 tracks this.

---

## The honest hard problems (v5 — durations removed, cap ops reframed)

| # | Problem | Lands in |
|---|---------|----------|
| 1 | Typed CBS VM with Sign/Cap/Outcome/Energy/Demod as native | Pod 1 (13 sub-pods) |
| 2 | Cap ops replacement (retire 0x90/0x91, typed Cap<R> opcodes) | Pod 1.9–1.10 |
| 3 | Ed25519 in NASM (placeholder field in V1.0; real in V1.1) | Pod 2 |
| 4 | ~~Paging resurrection~~ → **deferred post-V1** (DEFERRED #9) | Post-V1 |
| 5 | Lexical embeddings for Maid V1 | Pod 3 |
| 6 | Log-structured content-addressed store | Pod 3 |
| 7 | FAT32 write resurrection | Pod 3 |
| 8 | Pub-sub demod routing with isolation | Pod 4 |
| 9 | Surfaces refactor to use trinity | Pod 5 |
| 10 | Neural embeddings, quantized inference (Maid V2) | Pod 9 |
| 11 | Peer transport, capability addressing (Auryn far) | Pod 10 |

Pod 1 spans thirteen sub-pods (1.0 through 1.12). Two prerequisite
VM-fix pods and two canon-update pods precede typed-primitive work;
five typed-primitive pods follow; one cap data pod, one cap ops pod,
one Demod pod, and one cleanup pod close it out. Pace is set by
recon-protocol discipline, not by calendar.

---

## The pod arc (v5 — Pod 1 sub-pods expanded to 13)

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
├── 1.6  Sign as native type (0xA0–0xAF)                   [planned — typed primitives]
├── 1.7  Energy: per-opcode cost table (0xD0–0xDF)         [planned — typed primitives]
├── 1.8  Outcome<T>: typed errors + stack bounds (0xC0–0xCF) [planned — typed primitives]
├── 1.9  Cap<R> data structures (0xB0–0xBF)                [planned — cap replacement]
├── 1.10 Cap ops retirement (retire 0x90/0x91)             [planned — cap replacement]
├── 1.11 Demod<S> registration (0xE0–0xEF)                 [planned — demod]
└── 1.12 Pod 1 cleanup + sign-off                          [planned — cleanup]

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
April 27, 2026 (v5)
