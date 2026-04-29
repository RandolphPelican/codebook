# Pod 1.7 Decision Record — Sign Source Implementation

**Pod:** 1.7 — Sign source implementation (opcodes + pool + test)
**Author:** Chauncey (Claude)
**Date:** April 28, 2026
**Entry contract:** 32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 (Pod 1.5)
**Exit contract:** 975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc

---

## Decisions

### D1.7.1 — Sign pool placement in vmdata.asm

`vm_sign_pool` (64 nodes x 128 bytes = 8 KB) and `vm_sign_next` (bump
allocator index) are placed in `boot/vmdata.asm` between `vm_vars` and
`mmap_buf`, with `align 16`. vmdata.asm was specifically created for
Pod 1 extensions to VM runtime data without touching opcode handlers.

**Rationale:** Follows vmdata.asm's design intent (header comment:
"kept separate from cbs_vm.asm so Pod 1 can extend without touching
opcode handlers"). data.asm is Layer 0 bootstrap data; vmdata.asm is
Layer 1 VM runtime data.

### D1.7.2 — vm_sign_alloc as widened reimplementation

`vm_sign_alloc` in `boot/cbs_vm.asm` is a widened reimplementation of
the `cap_alloc_node` shape from `kernel/_future/cap_graph.asm`, not a
code port. Uses `rcx`/`rax`/`qword` (64-bit) throughout, not
`ecx`/`eax`/`dword` (32-bit). Returns (slot_ptr in rax, 1-based
sign_id in rcx). Pool exhaustion pushes sign_id 0 (null).

**Rationale:** cap_graph.asm is "0% recoverable as code" (Pod 0.9
memo). The bump allocator *shape* (load next, compare max, compute
offset, increment) is reused; the register width and calling
convention are new.

### D1.7.3 — OP_SIGN_HASH 4-slot push (low-to-high)

OP_SIGN_HASH (0xA1) pushes the 32-byte content_hash as four u64 values
onto the operand stack: hash[0:8], hash[8:16], hash[16:24], hash[24:32],
low-to-high (slot 0 = bytes 0-7, slot 3 = bytes 24-31). This matches
x86 little-endian convention and avoids introducing variable-length
stack objects.

**Rationale:** Architect resolved AQ1 — 4-slot push confirmed. The CBS
VM operand stack is homogeneous 8-byte slots; a 32-byte hash must be
decomposed. Low-to-high ordering lets consumers index predictably.

### D1.7.4 — OP_SIGN_LABEL 2-slot push (addr, len)

OP_SIGN_LABEL (0xA2) pushes two values: (address of label chars at
slot+0x21, length from byte at slot+0x20). This is directly compatible
with OP_PRINT_STR's 2-slot (addr, len) convention. The address points
into the sign pool slot — no copy is made.

**Rationale:** Reuses the existing string representation convention
(OP_PUSH_STR pushes addr+len). Zero-copy avoids temporary buffers.
Confirmed as D1.7.7.

### D1.7.5 — Toolchain inline data via PUSH_STR + DROP

`tools/atreyu_x86.py` emits Sign construction data (32-byte hash,
64-byte label) inline in the bytecode stream using OP_PUSH_STR to get
the address onto the stack, then OP_DROP to discard the length (only
the address is needed for OP_SIGN_NEW's hash_addr and label_addr
arguments).

**Rationale:** The VM has no separate data segment or string table.
OP_PUSH_STR is the existing mechanism for embedding arbitrary byte
sequences with an address result. The DROP-length pattern is the
minimal adaptation for typed-primitive construction.

### D1.7.5b — Canon correction: data.asm to vmdata.asm

RECONSTITUTION v6 incorrectly referenced `boot/data.asm` as the
location for typed-primitive pools (Sign subsection line 147, typed-
primitive pattern point 1 line 299). The correct file is
`boot/vmdata.asm`. v7 corrects both references. This is an honest
error in v6 — data.asm exists but is Layer 0 bootstrap data (drivers,
string tables), not Layer 1 VM runtime state.

**Rationale:** Accurate canon is non-negotiable. The error was
discovered during Pod 1.7 recon sweep (R5 vmdata.asm read).

### D1.7.6 — Placeholder energy costs (100j / 5j)

Sign opcode energy costs are placeholder values: OP_SIGN_NEW = 100
joules, accessors (HASH/LABEL/ENERGY) = 5 joules each. These costs
are deducted from r14 (energy remaining) and added to
`[rel energy_used]` in memory. The per-opcode cost table (replacing
flat 1j/fetch) is deferred to Pod 1.8 (Energy typed primitive).

**Rationale:** Architect decision — typed Energy doesn't exist yet.
Placeholder costs exercise the energy-deduction code path and prevent
Sign operations from being "free" in the energy model. Real costs
arrive with typed Energy.

### D1.7.7 — OP_SIGN_LABEL confirmed as 2-slot push

OP_SIGN_LABEL pushes exactly 2 slots (addr, len), not a raw string
copy. This is compatible with OP_PRINT_STR and the existing string
convention. Confirmed by architect at Phase 2A ratification.

**Rationale:** See D1.7.4. This decision was raised as an architect
question during Phase 2A review and confirmed.

### D1.7.8 — Energy display bug forward-log (r15 uninitialized)

The CBS VM exit path displays r15 as "energy used" alongside r14 as
"energy remaining". However, `cbs_run` never initializes r15 — it
contains whatever stale value was in the register at VM entry (from
UEFI context). The Sign test showed "267057632j used" which is
obviously wrong. r14 (remaining=99838) is correct. The in-memory
`[rel energy_used]` counter is also correct (tracks per-opcode
deductions properly).

This is a pre-existing display bug, not introduced by Pod 1.7.
`OP_RESERVE` writes to r15 (`sub r14, rax` / `add r15, rax`), but
r15 is only meaningful for programs that use OP_RESERVE. Programs
without OP_RESERVE display garbage.

**Forward:** Fix in Pod 1.8 (Energy) when energy display is
redesigned. Either initialize r15 to 0 in `cbs_run`, or replace the
r15 display with `[rel energy_used]`, or both. DEFERRED #15 tracks.

---

## Files changed

| File | Change |
|------|--------|
| `boot/defines.asm` | Added 4 Sign opcode defines (0xA0-0xA3) |
| `boot/vmdata.asm` | Added vm_sign_pool (8KB) + vm_sign_next |
| `boot/cbs_vm.asm` | Added 4 dispatch entries, 4 handlers, vm_sign_alloc (+182 lines) |
| `tools/atreyu_x86.py` | Added Sign opcodes, _sign_new(), demo_sign(), CLI options (+46 lines) |
| `surfaces/sign_test.cbc` | Compiled Sign test bytecode (299 bytes, created) |

## Test evidence

Round-trip verified under QEMU (headless, WSL2 Ubuntu):
- Compiled `sign_test.cbc` via `atreyu_x86.py --sign-build`
- Injected into FAT32 image via `mcopy`
- Booted BOOTX64.EFI under QEMU, navigated Gmork shell, `load sign_test.cbc`
- Screendump captured and verified:
  - sign_id: 1
  - energy: 42
  - label: hello
  - hash[0:8]: 171 (0xAB little-endian, correct)
  - Energy remaining: 99838 (100000 - 1x100j - 3x5j - fetch costs)

---

## Pod 1.8 forward-looking ledger

Items forwarded from Pod 1.7 to Pod 1.8 (Energy typed primitive):

1. **D1.7.6** — Replace placeholder energy costs (100j/5j) with typed
   Energy values from per-opcode cost table.
2. **D1.7.8** — Fix r15 energy display bug (DEFERRED #15).
3. **Per-opcode cost table** — Replace flat 1j/fetch with per-opcode
   costs. OP_MUL > OP_ADD, OP_SIGN_NEW > OP_SIGN_ENERGY, etc.
4. **Energy typed primitive** — 0xD0-0xDF opcode range, pool in
   vmdata.asm, follows typed-primitive representation pattern from
   Pod 1.6/1.7.
