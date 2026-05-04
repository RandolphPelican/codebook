# CodebookOS — RECONSTITUTION MANIFESTO (v9)

## Post-Pod-1.9.1 — Outcome<T> Canon Sealed (Pod 1.8.5b/c Conduits in Place)

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
**Updated:** April 28, 2026 (v7 — post-Pod-1.7 Sign source implementation, canon corrections)
**Updated:** April 29, 2026 (v8 — post-Pod-1.8 Energy source implementation, per-opcode cost table, catalytic-gateway fetch loop)
**Updated:** May 03, 2026 (v9 — post-Pod-1.9.1 Outcome<T> design canon, opcode allocation Outcome→0xE0-0xE4 / Demod→0xE5-0xEF, Pod 1.9 split into 1.9.1/1.9.2/1.9.3)
**Companion to:** ARCHAEOLOGY.md, ARCHAEOLOGY_REPO_RECORD.md, RECON_PROTOCOL.md, recon/POD0.9_CAP_GRAPH_DEEP_READ.md, recon/POD1.1_VM_AUDIT.md, recon/POD1.2_DECISION_RECORD.md, recon/POD1.4_DECISION_RECORD.md, recon/POD1.6_DECISION_RECORD.md, recon/POD1.7_DECISION_RECORD.md, recon/POD1.8_DECISION_RECORD.md, recon/POD1.9.1_DESIGN_DECISIONS.md
**Supersedes:** RECONSTITUTION.md v8

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
in `boot/vmdata.asm` (placed by Pod 1.7). Matches cap pool sizing (64 ×
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
OP_SIGN_HASH     0xA1   sign_id → 4 × u64 (hash[0:8], hash[8:16], hash[16:24], hash[24:32])
OP_SIGN_LABEL    0xA2   sign_id → label as string
OP_SIGN_ENERGY   0xA3   sign_id → energy_cost u64
0xA4–0xAF        reserved (Pod 3+ provenance, embedding ops)
```

OP_SIGN_NEW stack inputs (top-down): provenance_handle, embedding_handle,
energy_cost, label_addr, hash_addr. Returns sign_id on stack.

**Implementation (Pod 1.7):** All four Sign opcodes are wired in
`boot/cbs_vm.asm` with dispatch entries and handlers. `vm_sign_alloc`
is a bump allocator returning (slot_ptr, 1-based sign_id). Energy costs:
OP_SIGN_NEW = 100 joules, accessors = 5 joules each (placeholder costs,
typed Energy deferred to Pod 1.8; see D1.7.6). Toolchain emission in
`tools/atreyu_x86.py` embeds hash/label data inline via OP_PUSH_STR +
OP_DROP. Round-trip verified under QEMU: sign_id=1, energy=42, label=hello,
hash[0:8]=171 (0xAB little-endian). See `recon/POD1.7_DECISION_RECORD.md`.

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
do not implement Cap<R> as described here. Pod 1.11 retires them
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
├── 1.10 Cap<R> data structures (0xB0–0xBF)                [planned — cap replacement]
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
