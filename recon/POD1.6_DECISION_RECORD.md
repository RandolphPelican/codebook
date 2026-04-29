# Pod 1.6 — Decision Record

## Canon-Only Pod: Sign as Native Type (RECONSTITUTION v5 → v6)

**Pod type:** Canon-only (no source changes, binary contract preserved)
**Binary contract:** `32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6`
**Companion to:** RECONSTITUTION.md v6, recon/POD1.6_RECON_REPORT.md

---

## Decisions Ratified

### A1 — Sign representation in VM memory

**Question:** How does the VM represent Sign structs at runtime?

**Options enumerated:**

1. **Fixed-size on the operand stack.** Sign fields inline in stack
   slots. Rejected: too large (32 + 64 + 8 + 8 + 8 = 120 bytes
   minimum) for an 8-byte stack slot.
2. **Heap-allocated with stack reference.** Sign structs on a
   dynamic heap. Rejected: V1.0 has no heap allocator.
3. **Static pool with stack handle.** Fixed-size pool in
   `boot/data.asm`; stack carries 8-byte index. Cap_graph precedent
   (Pod 0.9).
4. **Inline in bytecode with stack handle.** Sign data lives in the
   bytecode stream. Rejected: Signs must outlive their bytecode
   (Pod 2 capability grants, Pod 3 persistence).

**Ratified answer:** Option 3 — static pool with stack handle.

Sign structs live in a static pool (`vm_sign_pool`) sized at 64
nodes × 128 bytes = 8 KB. Pool location in `boot/data.asm`, placed
by Pod 1.7. Operand stack carries an 8-byte `sign_id` (pool index).
`sign_id` 0 = invalid/null; valid range 1–64.

**Rationale:** Consistency with cap pool precedent. V1.1
typed-primitive slot expansion happens across all typed primitives
in unison; Sign at 256B while Cap stays at 128B creates divergent
expansion stories. 8KB matches the per-typed-primitive pool budget
convention. Sign's V1.1 expansion (likely Ed25519 signature per Cap
precedent) requires a slot resize regardless of whether reserved
space is 8 bytes or 136 bytes — so reserving more now buys nothing.

**Cross-references:** A2 (slot layout depends on pool size), A4
(validation at construction writes to pool), A6 (immutability
applies to pool slots), A7 (single-slot handle means OP_DUP2
not needed).

### A2 — Sign field layout and alignment

**Question:** What is the concrete byte layout of a Sign pool slot?

**Options enumerated:**

1. **256-byte slot with 136 bytes reserved.** Original architect
   instinct. Rejected after R3 reconciliation: diverges from cap
   pool's 128-byte slot convention.
2. **128-byte slot with 8 bytes reserved.** Matches cap pool
   precedent exactly.
3. **Variable-size slot.** Rejected: defeats static pool's
   determinism guarantee.

**Ratified answer:** Option 2 — 128-byte slot.

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

**Rationale:** Largest fixed-size fields first (32B hash, 64B
label). Variable-sized fields (embedding, provenance) as 8-byte
handles into separate pools defined Pod 3+. 8 bytes reserved at end
as expansion sentinel; full V1.1 expansion requires slot-resize
across typed primitives.

**Label representation:** Length-prefixed ASCII. Byte 0 holds length
(0–63); bytes 1–63 hold characters. UTF-8 deferred to V1.1.

**Embedding and ProvChain:** Forward-declared handles to pools
landing in Pod 3 / Pod 9. Handle value 0 = no embedding / no
provenance, valid in V1.0.

**Cross-references:** A1 (pool sizing constrains slot size), A5
(energy_cost reserved as raw u64), A6 (immutability means no
in-place field updates).

### A3 — Sign opcode allocation

**Question:** Which opcodes does Pod 1.6 allocate from the 0xA0–0xAF
range?

**Options enumerated:**

1. **Full V1.0 set (8+ opcodes).** Includes provenance, embedding,
   comparison, serialization. Rejected: provenance/embedding pools
   don't exist until Pod 3.
2. **Lean V1.0 set (4 opcodes).** Constructor + three accessors.
   Minimum viable for Sign to exist as a typed primitive.
3. **Constructor only (1 opcode).** Accessors deferred. Rejected:
   Sign without accessors is untestable.

**Ratified answer:** Option 2 — lean set, four opcodes.

```
OP_SIGN_NEW      0xA0   construct Sign from stack args, return sign_id
OP_SIGN_HASH     0xA1   sign_id → content_hash
OP_SIGN_LABEL    0xA2   sign_id → label as string
OP_SIGN_ENERGY   0xA3   sign_id → energy_cost u64
0xA4–0xAF        reserved for Pod 3+ (provenance, embedding ops)
```

**OP_SIGN_NEW construction signature:** Stack inputs (top-down):
provenance_handle, embedding_handle, energy_cost, label_addr,
hash_addr. Returns sign_id on stack.

**OP_SIGN_HASH stack shape:** 32-byte hash doesn't fit in one
8-byte stack slot. Pod 1.7 ratifies during implementation: either
(a) push 4 slots (low 8B through high 8B), or (b) push hash to a
dedicated buffer and push buffer pointer. Pod 1.6 reserves the
opcode and the question.

**Cross-references:** A1 (opcodes operate on pool handles), A4
(OP_SIGN_NEW validates; accessors check handle only).

### A4 — Validation timing

**Question:** When does the VM validate Sign data — at construction,
at use, or both?

**Options enumerated:**

1. **Construction-time only.** OP_SIGN_NEW validates; accessors
   trust pool contents.
2. **Use-time only.** Constructor accepts anything; accessors
   validate before returning.
3. **Both.** Full validation at construction and every access.
   Rejected: unnecessary overhead in V1.0's single-user,
   local-bytecode trust model.

**Ratified answer:** Option 1 — construction-time only.

OP_SIGN_NEW validates: hash is 32 bytes, label length ≤ 63,
energy_cost in valid range, embedding_handle and provenance_handle
either 0 or within their pool ranges. If validation fails,
OP_SIGN_NEW pushes sign_id 0 (null). Accessors check sign_id is in
valid range (1–64) and pool slot is allocated; do not re-validate
field contents. If sign_id is invalid, accessor pushes
zero/empty/null.

**Rationale:** V1.0 has no peer transport (Pod 10). Sign source is
local bytecode the user compiled. Trust boundary is narrow. Use-time
validation is Pod 9 work when Maid V2 hits untrusted peers.

**Cross-references:** A1 (validation writes to pool slot), A3
(OP_SIGN_NEW is the validation site).

### A5 — Energy ordering question

**Question:** Does Sign's energy_cost field require the Energy typed
primitive to be defined first, forcing a pod reorder?

**Options enumerated:**

1. **Reorder: Energy before Sign.** Rejected: Sign is the
   foundational typed primitive; Energy depends on Sign's
   existence (energy is *spent on* Signs).
2. **Defer energy_cost field entirely.** Rejected: field is part of
   Sign's abstract definition since v2.
3. **Reserve raw u64 bytes; Energy wrapper lands later.** Energy
   primitive doesn't change Sign's on-disk layout.

**Ratified answer:** Option 3 — defer Energy representation, reserve
8 bytes.

Sign's layout (A2) reserves bytes 0x60–0x67 for energy_cost as a
raw u64. Pod 1.7 lands Energy as a typed primitive (u64 joules under
the hood, with accessor opcodes 0xD0–0xDF). Pod 1.7's typed wrapper
does NOT change Sign's on-disk byte layout.

**No pod renumbering.** 1.6 Sign, 1.7 Energy, 1.8 Outcome, etc.

**Cross-references:** A2 (energy_cost field position), A3
(OP_SIGN_ENERGY reads the raw u64).

### A6 — Mutability

**Question:** Can Sign pool slots be modified after construction?

**Options enumerated:**

1. **Mutable.** Any field can be updated in place. Rejected:
   complicates value semantics, creates allocate-on-touch pressure.
2. **Immutable post-construction.** Pool slot is read-only once
   OP_SIGN_NEW returns. ProvChain grows separately.
3. **Copy-on-write.** Modifications create new pool entries.
   Rejected: V1.0 pool is 64 slots — COW burns through them.

**Ratified answer:** Option 2 — immutable post-construction.

Once OP_SIGN_NEW returns a sign_id, the Sign's pool slot is
read-only. Provenance is appended via the ProvChain pool (Pod 3+)
without touching the Sign's slot — Sign's provenance_handle stays
constant, the chain it points at grows.

**Rationale:** Cleaner value semantics. No allocate-on-touch
pressure on the 64-slot Sign pool. Provenance growth happens in a
pool sized for write pressure (Pod 3 design surface).

**Cross-references:** A1 (pool slots are fixed), A2 (no mutable
field markers needed in layout), A4 (validation at construction is
the only write).

### A7 — OP_DUP2 fate

**Question:** Does Sign's representation require OP_DUP2 to be wired
into the dispatch chain?

**Options enumerated:**

1. **Wire OP_DUP2 now.** If Sign operations produce multi-slot
   values.
2. **Keep orphaned, exile in Pod 1.12.** If Sign is single-slot.

**Ratified answer:** Option 2 — stays orphaned, exiles in Pod 1.12.

A1's static-pool answer means Sign is single-slot (8-byte handle).
DUP2 (which would duplicate a 2-slot top-of-stack pair) isn't needed
for Sign. DEFERRED #6 resolves in Pod 1.12 cleanup by removing
OP_DUP2 from `boot/defines.asm` and the orphaned handler from
`boot/cbs_vm.asm`.

**Cross-references:** A1 (single-slot handle), DEFERRED #6.

### Pod-arc self-referential edit

**Question:** How does Pod 1.6's own pod-arc row get updated?

**Ratified answer:** Pod 1.7's commit flips Pod 1.6's row from
`[planned — typed primitives]` to `[DONE — <1.6-commit-hash>]`.
Pod 1.5.6 established this convention (successor pod flips
predecessor's row). Pod 1.6's row intentionally stays `[planned]`
in this commit.

---

## Pod 1.7 Forward-Looking Ledger

Items for Pod 1.7 (Sign source implementation) to resolve:

1. **OP_SIGN_HASH stack-shape question.** 32-byte hash doesn't fit
   in one 8-byte stack slot. Pod 1.7 ratifies: either (a) push 4
   slots (low 8B, mid-low 8B, mid-high 8B, high 8B), or (b) push
   hash to a dedicated hash-output buffer in `vm_data` and push
   buffer pointer. Decision affects toolchain emission and any
   program that reads Sign hashes.

2. **vm_sign_pool placement in boot/data.asm.** Pod 1.7 adds
   `vm_sign_pool: times 64 * 128 db 0` (8,192 bytes) to
   `boot/vmdata.asm` or `boot/data.asm`, with `align 16` prefix.
   Placement after `vm_vars` and before `mmap_buf` is natural but
   Pod 1.7 confirms.

3. **Pod 1.6 pod-arc row.** Pod 1.7's commit flips Pod 1.6's row
   to `[DONE — <Pod-1.6-commit-hash>]` per the Pod 1.5.6
   convention.

4. **atreyu_x86.py stale "push i32" comment.** Per Pod 1.5.5 §AQ2
   disposition: fix encountered stale width comments while modifying
   the toolchain for Sign opcode emission.

---

*From layer 1 kernel up.*
