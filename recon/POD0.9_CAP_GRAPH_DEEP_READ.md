# Pod 0.9 — cap_graph + paging Deep-Read Memo

**Date:** April 27, 2026
**Author:** Chauncey (Claude) — architect-side
**Scope:** Deep read of `kernel/_future/cap_graph.asm` (204 lines) and
`kernel/_future/paging.asm` (156 lines). Synthesis into Pod 1 design
inputs.
**Status:** Architect work product. Pod 1's typed VM design draws from
this memo. No source code changes in Pod 0.9.

---

## Why this memo exists

`kernel/_future/cap_graph.asm` and `kernel/_future/paging.asm` were
exiled in commit `b0fe54d` with documented bugs and resurrection
checklists. They are real prior art from Phase 5.1 and Phase 3.2 work,
not greenfield. Before Pod 1 designs the typed `Cap<R>` primitive and
makes any decisions about post-EBS execution, the architect reads these
files carefully and extracts:

- What design ideas survive (incorporate into Pod 1)
- What was tried and why it didn't work (avoid the same pit)
- What was implicitly assumed but never declared (decide explicitly)

Pod 1 is months of work. The hour spent on this memo saves multiple
days of re-deriving what the previous engineer already worked out.

---

## Part I — cap_graph.asm

### What's there

A 204-line capability graph with the following components:

**Constants:**
- `MAX_CAP_NODES = 64` — fixed pool size
- `CAP_ROOT_TOKEN = 0xFFFFFFFF` — sentinel for the root capability
- `CAP_READ`, `CAP_WRITE`, `CAP_EXEC`, `CAP_GPU`, `CAP_NETWORK` — 5-bit
  capability bitmap (bits 0-4)

**Data structures:**
- `CAP_NODE` struct: 5 dwords (parent_token, child_token, cap_bitmap,
  energy_budget, energy_used) = 20 bytes per node
- `cap_graph[]` — static pool of 64 nodes
- `cap_next_index` — bump pointer for allocation
- `cap_root` — singleton root node, separate from the pool

**Functions:**
- `cap_init` — initializes root with all caps, 10000 energy budget
- `cap_grant(parent, child, bitmap, budget)` — allocates child node,
  links parent→child, deducts budget from parent
- `cap_use(token, cap_bit)` — checks token has capability and energy,
  deducts energy from this node *and from parent at half cost*
- `cap_get_node(token)` — currently a stub that only handles root;
  comment says "real implementation scans cap_graph"
- `cap_alloc_node` — bump-allocates from cap_graph[] using cap_next_index

### Documented bugs (from the exile header)

1. `cap_root: CAP_NODE` is invalid NASM struct instantiation. Correct
   form is `cap_root: istruc CAP_NODE ... iend`.
2. All pointer math uses 32-bit registers (`eax`, `ebx`, `ecx`) in long
   mode. In x86_64, 32-bit ops zero-extend the upper 32 bits of the
   destination register, which means *every pointer dereference is
   silently corrupted*.
3. `lea eax, [cap_graph + ecx * CAP_NODE_size]` uses 32-bit effective
   addressing in 64-bit mode — same problem.

### What I noticed beyond the documented bugs

**The "spatial merge" mechanic is the most interesting design here.**
Lines 130-145 of `cap_use` — when a child capability is exercised, the
parent's energy_used also increments by half cost. The comment reads:
"if parent has same cap, deduct from parent too. Half cost for spatial
merge."

This isn't a bug. This is the previous engineer encoding **delegation
chains pay a tax**. When a child cap exercises a power, the parent that
granted it loses budget too. Capabilities are not "free once granted" —
the act of granting binds the parent's metabolism to the child's
activity. This is *much closer to the federated cognitive organism
metaphor* than what RECONSTITUTION v2 currently describes. I should
have put it in v2; I didn't, because I didn't know about it. Pod 1
incorporates this.

**The bitmap-as-capability is correct in shape, narrow in width.**
Five capability bits is too few — V1 needs at least: per-surface caps
(Bastian, Gmork, Auryn, Atreyu, Morla, etc.), per-driver caps (kbd,
disk, framebuffer), per-resource caps (read, write, exec, grant), and
per-network/peer caps (V1.1+). That's 32-64 distinct bits at minimum.
Pod 1 widens to 64 bits. The bitmap idea — multiple resources combinable
in one cap, AND'd at use site — is sound. Just wider.

**Energy is 32-bit in cap_graph, 64-bit in cbs_vm.** Live VM tracks
energy as `dq` (Pod 0.2.5 recon: `energy_budget`, `energy_used` are
64-bit), and Fibonacci burns 267,057,632 joules — already a value that
needs >24 bits to express comfortably and is approaching the int32 max.
cap_graph's 32-bit budget would overflow within a few CBS programs.
Pod 1 unifies on 64-bit energy throughout.

**The "real cap_get_node implementation" was never written.** The
current stub only handles root. The comment says "real implementation
scans cap_graph" but there's no scan loop. This means the entire
non-root portion of the design is unverified — the `cap_grant` /
`cap_use` paths assume `cap_get_node` works for arbitrary tokens, but
it doesn't. The previous engineer hit a wall here too, not just at the
register width.

**`cap_grant` step 4 has a bug independent of register width.** Line:
`mov [ebx + CAP_NODE.energy_budget], eax`. At this point `eax` holds
the *return value* `0` (zeroed by step 5's `xor eax, eax` was supposed
to come after, but it's already xor'd from the cap_alloc_node return).
What was *meant* was: deduct ECX (the child's budget) from the parent's
budget, store the result. But the code stores 0 (or the new node
pointer, depending on which line you read carefully). Either way: the
parent's budget gets corrupted on every grant. This is a real
correctness bug, not just a porting bug.

**Token allocation strategy is opaque.** `cap_alloc_node` returns a
node pointer; the calling convention seems to imply that "token" is
the index into `cap_graph[]`. But the input parameters to `cap_grant`
take `parent token` and `child token` as separate things, and
`cap_alloc_node` doesn't return a token — it returns a node pointer.
The mapping between "token" (what the bytecode passes) and "node
pointer" (what the implementation works with) is not defined anywhere.
Pod 1 needs to make this explicit: tokens are indices, nodes are
pointers, and `cap_get_node(token)` is the only function that converts
between them.

### What survives into Pod 1

**Survives directly (with widening / fixing):**
- `CAP_NODE` struct shape: parent, child, cap_bitmap, energy_budget,
  energy_used. Pod 1 widens to 64-bit for pointers and energy, expands
  bitmap to 64-bit, and adds: `signature` (Ed25519 over the rest of
  the node), `nonce` (anti-replay), and `expiry` (time-bound caps).
- The capability bitmap pattern with multi-resource AND'ing at use
  site.
- The "spatial merge" parent-tax mechanism in `cap_use`. This is the
  best idea in the file.
- Static-pool allocation with bump pointer (no malloc, deterministic).
  Pod 1 keeps this.
- The 64-node maximum is tight for the trinity-organism design but
  fine for V1 (Bastian + Gmork + 8 stub surfaces + drivers fits well
  under 64). Pod 1 keeps `MAX_CAP_NODES = 64` for V1 and bumps it
  later if needed.

**Salvageable as design notes (rewrite from scratch):**
- The functions themselves: `cap_init`, `cap_grant`, `cap_use`,
  `cap_get_node`, `cap_alloc_node`. The 32-bit pointer issue makes
  every line untrustworthy; better to rewrite with the correct shape
  in hand than to patch line-by-line and hope nothing was missed.

**Discarded:**
- The `CAP_ROOT_TOKEN = 0xFFFFFFFF` sentinel. Pod 1 uses `0` as the
  root token (consistent with C tradition where 0 is a special pointer
  value, and avoids the `0xFFFFFFFF == -1` confusion that long-mode
  signed/unsigned comparisons can produce).
- The unreachable `OP_GRANT_CAP_NEW` (0xCA000003) and `OP_USE_CAP_NEW`
  (0xCA000004) opcodes in defines.asm. Pod 1 wires capability ops as
  single-byte opcodes in the regular dispatch range (probably 0x40+
  alongside the other Pod 1 kernel opcodes from the original POD 1
  prompt — OP_KEY_READ etc.). The 4-byte ghosts get removed from
  defines.asm in Pod 1.

### Pod 1 inputs from cap_graph

```
struct CapNode {
    u64 parent;           // index into cap_pool, 0 = root
    u64 child;             // first child index (linked list head)
    u64 sibling;           // next sibling (for traversal)
    u64 cap_bitmap;       // 64 bits of capability resources
    u64 energy_budget;    // joules granted
    u64 energy_used;      // joules consumed
    u64 nonce;             // anti-replay
    u64 expiry;            // time-bound (0 = never)
    u8  signature[64];   // Ed25519 over the above
}
// Total: 8*8 + 64 = 128 bytes per node, 16x the original 20 bytes
// At 64 nodes, total cap graph storage = 8 KB
```

The signature field is the V1.1 add (Ed25519 isn't ready in V1, but the
field is present so the on-disk layout doesn't change when we wire it).

The mechanics:
- `cap_grant`: same shape as original, but with proper 64-bit math,
  bug-fixed budget accounting, and the parent-tax spatial merge.
- `cap_use`: same shape, with the spatial merge preserved as a feature.
- `cap_get_node`: real implementation, linear scan through cap_pool[]
  for matching token (acceptable at N=64).

---

## Part II — paging.asm

### What's there

A 156-line identity-page-table builder with these pieces:

**Constants:**
- Page size, level entry counts (PML4/PDP/PD/PT all 512)
- PTE flags: PRESENT, WRITABLE, PAT, PS

**Functions:**
- `paging_setup_identity` — allocates PML4, identity-maps 0-4GB with
  1GB pages, identity-maps the framebuffer MMIO range, installs CR3
- `paging_map_mmio_range` — adds PAT/PCD flags for a given range
- `paging_install_cr3` — sets CR3, enables paging in CR0, flushes TLB
- `paging_get_pt_entry` — stub (`ret` only)

**Storage:**
- `new_cr3 dq 0` — declared in code section (NASM bug)

### Documented bugs (from the exile header)

1. `call memory_allocate` — symbol undefined anywhere in the tree
2. `paging_get_pt_entry(rcx)` uses C-call syntax that NASM doesn't parse
3. `PTE_PCD` referenced but never `equ`'d
4. `new_cr3` data declaration in code section

### What I noticed beyond the documented bugs

**The 1GB-page identity map is the right call for V1.** Identity
mapping the first 4GB with four PDP entries (each covering 1GB via
PS=1) costs 4 entries × 8 bytes = 32 bytes of PDP, plus a single PML4
table to point at the PDP. Total ~12KB of page tables for 4GB of
memory. A naive 4K-page identity map would need ~8MB of tables. The
1GB-page choice is enormous and correct.

**The framebuffer MMIO mapping is conceptually right but mechanically
broken.** Setting PAT and PCD flags on the framebuffer pages enables
write-combining (good — fast pixel writes without thrashing the L1).
But:
- `PTE_PCD` is undefined (should be 0x10)
- The MMIO range mapping uses 4K pages, but the conventional memory
  uses 1GB pages — these collide. If the framebuffer happens to fall
  inside the first 4GB (which it usually does on UEFI with GOP), then
  the existing 1GB PS=1 entry covers it, and trying to add a 4K-mapping
  for the same physical addresses requires *splitting* the 1GB page —
  which the code doesn't do.
- The right pattern is: identity-map low 4GB with 1GB pages but *skip
  any PDP entry that covers the framebuffer*, then map the framebuffer
  range separately with 4K pages and PAT flags. The current code maps
  conventional first then framebuffer second; the second mapping silently
  doesn't take effect because the 1GB entry "wins."

**The CR3 switch ordering is dangerous.** `paging_setup_identity` is
called *while UEFI Boot Services are alive*. It allocates page tables
(via the missing `memory_allocate`), builds the identity map, and then
installs CR3 — *before* `ExitBootServices()`. UEFI's own page tables
also identity-map but include various firmware regions our map doesn't
include (ACPI tables, runtime services, etc.). Switching to our CR3
mid-EBS can break Boot Services calls that occur after the switch.

The right pattern:
1. Call UEFI to get the memory map and reserved regions
2. Build our page tables in memory (don't install yet)
3. `ExitBootServices()` — UEFI is now dormant
4. *Now* install CR3
5. Continue with our paging in effect

The current code violates this. Resurrection requires re-ordering.

**`paging_get_pt_entry` is a stub.** Walking PML4→PDP→PD→PT for a given
virtual address is ~30 lines of real code (extract bits 39-47, 30-38,
21-29, 12-20 of vaddr; index into each level; check PRESENT; descend
or return). The stub means nothing actually works — the entire
`paging_map_mmio_range` function is broken because its core helper
returns garbage.

**No allocator means no real implementation.** `memory_allocate` is the
linchpin. The paging code can't function without somewhere to put the
page tables. Two options:
- Static reservation: declare a `page_pool: times 16384 db 0` in
  data.asm, take a bump pointer through it. Simple, fixed-size, fine
  for V1.
- UEFI BS allocation: call `BS->AllocatePages()` while BS is alive,
  store the result, switch CR3 only after EBS. More elegant, requires
  proper UEFI plumbing.

For V1, static reservation is the right call. Pod 1 declares
`page_pool` in data.asm with enough space for the identity map plus
~1MB of slack for small pages.

### What survives into Pod 1 (or Pod 2)

**Survives as design pattern:**
- 1GB-page identity mapping for low 4GB
- PAT/PCD flags for framebuffer write-combining
- CR3 install + CR0.PG enable + TLB flush sequence

**Discarded — must be redesigned, not patched:**
- The function-by-function code. Too many missing pieces (allocator,
  PT walker, ordering) to call this "salvage."

**Architectural decisions Pod 1 must make explicitly:**

1. **Does V1 even need its own paging?** UEFI's identity-map is
   already in effect. If V1 doesn't need paging features (write-combine
   for framebuffer, no-execute for data, separate userspace), we can
   defer paging to Pod 2 or later. The current build doesn't enable
   any paging features beyond what UEFI gives us, and it works.
   Recommendation: **defer paging to post-V1.** V1.0 ships using UEFI's
   identity map, no own paging.

2. **When paging arrives, static page pool or UEFI BS allocation?**
   Recommendation: **static pool.** Simplicity, determinism, no UEFI
   coupling.

3. **CR3 switch timing?** Recommendation: **after ExitBootServices
   only.** No mid-EBS CR3 changes ever.

### Pod 1 inputs from paging

Honestly: minimal. paging is more "things to remember when we get
there" than "code we resurrect now." The notes above become a section
in `kernel/paging.asm` (when it gets written, probably Pod 2 or later)
documenting the design constraints.

The decision to defer paging to post-V1 is itself the most important
output. **DEFERRED.md gets a ninth item: paging implementation, post
V1.** This means V1.0 ships with UEFI's identity map and no own page
tables — totally fine; the OS runs from a flat-binary PE32+ in
identity-mapped memory and that's exactly what Bastian, Gmork, and the
CBS VM all assume.

---

## Part III — Implications for RECONSTITUTION and Pod 1

### RECONSTITUTION updates needed (Pod 0.9 → architect-side commit)

**Cap<R> design block** in Layer 1 description — extend with:

```
Cap<R> := {
  resource:     R,                  // resource type
  parent:       cap_id,             // parent in graph (0 = root)
  cap_bitmap:   u64,                // 64 capability bits
  energy_budget: u64,               // joules granted
  energy_used:   u64,               // joules consumed by this cap + descendants
  nonce:         u64,               // anti-replay
  expiry:        Time | Never,      // time-bound caps
  signature:     bytes(64),         // Ed25519 over the rest (V1.1+)
}

Spatial merge: when a child cap exercises a power, the parent's
energy_used increments by half cost. This encodes the design principle
that delegation chains pay a tax — capabilities are not "free once
granted."
```

**Layer 0 paging note** — Add a single paragraph:

> V1.0 runs in UEFI's identity-mapped flat memory model. CodebookOS
> does not install its own page tables in V1. paging.asm
> (`kernel/_future/paging.asm`) contains design notes for post-V1
> paging including 1GB-page identity mapping, write-combining
> framebuffer, and post-EBS CR3 install ordering. Resurrects in Pod
> 2 or later when post-EBS execution becomes a feature requirement.

**Pod 1 scope updated** — The pod arc table currently says Pod 1 reads
cap_graph "before designing Cap<R>." That's correct; Pod 0.9 has now
done the reading. Pod 1's design starts from the synthesized notes in
this memo, not from the raw exiled file.

### DEFERRED.md additions

Item 9: **Paging implementation, post-V1.**
> kernel/_future/paging.asm contains design notes (see
> recon/POD0.9_CAP_GRAPH_DEEP_READ.md). V1.0 ships using UEFI's
> identity-mapped memory. Post-V1 paging is deferred until a feature
> requires it (separate userspace, write-combining framebuffer
> performance, NX bit on data, etc.).

### Pod 1 entry conditions

Pod 1 begins when:

1. RECONSTITUTION updated with Cap<R> design block (architect commit)
2. DEFERRED.md updated with paging deferral (architect commit)
3. This memo committed to repo at `recon/POD0.9_CAP_GRAPH_DEEP_READ.md`
4. Architect drafts Pod 1's prompt incorporating:
   - Capability graph rewrite (using cap_graph design notes above)
   - Sign type (new Pod 1 work; no prior art)
   - Outcome<T> type (new Pod 1 work; design from RECONSTITUTION)
   - Energy as typed value (extends current 64-bit budget mechanic)
   - Demod<S> type (new Pod 1 work; design from RECONSTITUTION)
   - Typed evaluator dispatch (rewrite of cbs_run from `cbs_vm.asm`)

Pod 1 is realistic 4-6 weeks of TB work given the scope. With the
prior-art savings from cap_graph, possibly 3-5 weeks.

---

## Part IV — Notes on the Previous Engineer's Process

Reading these two files, I see the same engineer hit two different
walls and made the same call both times: exile with documented
checklist, keep moving on the active build. That's discipline.

The cap_graph wall was *register width across mode transition* — they
designed in 32-bit habit and didn't fully internalize that long-mode
breaks 32-bit pointer math. That's a once-burned, twice-shy lesson;
Pod 1's typed VM rewrite gets all 64-bit math from the start.

The paging wall was *ordering and allocator* — they designed the right
tables but tried to install CR3 mid-EBS and assumed an allocator
existed. Both fixable, but the fix is "rewrite with the constraint
order done right," not "patch the existing code." Pod 1 (or wherever
paging lands) does that rewrite.

Both files preserve the design ideas. That's why the exile worked.
This memo is the recovery of those ideas in context.

Atreyu named it. Engywook is the one who reads what Atreyu found.

---

## Part V — Status

**This memo committed to:** `recon/POD0.9_CAP_GRAPH_DEEP_READ.md`

**Companion architect commits:**
- RECONSTITUTION update (Cap<R> design block + paging deferral note)
- DEFERRED.md update (item 9: paging post-V1)

**Pod 1 prompt drafting:** begins after this memo lands and the
architect commits the canon updates.

**Pod 0 status:** Sealed at tag `pod0-complete`. Pod 0.9 is recon-only;
the foundation tag is unchanged.

---

*StableTech Enterprises LLC — Engywook reads what Atreyu found.*

— Chauncey
CodebookOS Senior Architect
April 27, 2026
