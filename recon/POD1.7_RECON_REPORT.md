# Pod 1.7 — Sign Source Implementation — Recon Report

**Date:** 2026-04-28
**Pod:** 1.7 (source pod — heaviest since Pod 1.5 width migration)
**Author:** Terminal Boy (Claude)
**Entry contract:** `32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6`
**Predecessor:** Pod 1.6 (canon-only, sealed at 6264dbc)

---

## Section 1 — Sweep Findings

### Sweep A — File Inventory (5 target files)

| File | sha256 (pre-edit baseline) |
|------|--------|
| boot/data.asm | `84941ab9a8f7ee262b3e9a1b495f4895b4bcbc468d6760065a286fb121d8437d` |
| boot/defines.asm | `65ecc7bfc409bb9e2ead603deb4c6aeb5663b7b6a7e9c73f875f7724bbb7efff` |
| boot/cbs_vm.asm | `9b1c20aa6b75252f009ab79195b5ae8abc45831208c18c7c6fbbab858af4fb59` |
| tools/atreyu_x86.py | `3a418b13ff7368118258bad3f4ff79411a9ecedda68e561f7358dd853d339663` |
| RECONSTITUTION.md | `13bd933c31cce1425a48edd41719efd3e00c74c9410f853a0219dc675ec9ef1b` |

### Sweep B — Symbol Inventory

**Existing OP_SIGN_* or vm_sign_pool references in source files:** None.
Grep across entire repo found references only in recon/canon markdown files
(POD1.6_DECISION_RECORD.md, POD1.6_RECON_REPORT.md, POD1.5.5_PRE_POD16_RECON.md,
RECONSTITUTION.md). No .asm or .py source files reference these symbols.
Clean insertion — no rename/collision risk.

### Sweep C — Cross-Module Dependencies

**boot/vmdata.asm** (22 lines): Contains all VM runtime data. Labels:
energy_budget, energy_used, vm_ret_ptr, vm_ret_stack, vm_stack, vm_vars,
mmap_buf. vm_sign_pool insertion goes after vm_vars (line 17) and before
the mmap_buf alignment (line 19).

**boot/defines.asm** (89 lines): Opcode section lines 55–89. Highest
single-byte opcode: 0x91 (OP_USE_CAP). 0xA0–0xAF entirely free. Four new
defines: OP_SIGN_NEW 0xA0, OP_SIGN_HASH 0xA1, OP_SIGN_LABEL 0xA2,
OP_SIGN_ENERGY 0xA3.

**boot/cbs_vm.asm** (737 lines): Dispatch chain lines 57–118 (31 opcodes).
No OP_SIGN entries. OP_DUP2 handler at line 660 still orphaned (no dispatch
entry). cap_atreyu dead code at lines 414–499.

**tools/atreyu_x86.py** (213 lines): Line 9 has stale comment `# push i32`
(should be i64, per Pod 1.5.5 §AQ2). Has emit_i64 method from Pod 1.5.
Opcode constants at lines 7–27. Emission methods at lines 52+.

### Sweep D — Unexpected Directories

No new directories since Pod 1.6.

### Sweep E — Git Log + Ref State

Last 5 commits:

```
6264dbc Pod 1.6: Sign as native type — canon patch + decision record
ea23a8f Pod 1.5.6 — RECONSTITUTION v5 pod-arc reconciliation + MEMO_VERIFICATION_PROVENANCE commit
b560a6c Pod 1.5.5 — pre-Pod-1.6 architect orientation recon
e6a2cc2 Pod 1.5: 64-bit integer width migration — runtime, toolchain, bytecode
eabf160 Pod 1.5: Phase 1 recon report (R1-R12)
```

Three-oracle ref check:

```
git rev-parse HEAD:        6264dbc6e06847d5360e81bd31f284466dcd1735
git rev-parse origin/main: 6264dbc6e06847d5360e81bd31f284466dcd1735
git ls-remote origin main: 6264dbc6e06847d5360e81bd31f284466dcd1735
```

All three match. Pod 1.6 seal confirmed at HEAD.

### Sweep F — Markdown Inventory

RECONSTITUTION.md: sha256 `13bd933c31cce1425a48edd41719efd3e00c74c9410f853a0219dc675ec9ef1b`

### Sweep G — Cemetery Verification

`kernel/_future/` contains 2 files: `paging.asm`, `cap_graph.asm`. Unchanged
from Pod 1.6. cap_graph.asm is referenced in R7 (prior art) but not modified.

---

## R1 — RECONSTITUTION v6 Sign Subsection (verbatim, lines 118–181)

```markdown
#### `Sign` — concretized in v6 (Pod 1.6)

The unit of cognition. Abstract definition unchanged from v2; concrete
layout ratified in Pod 1.6.

Sign := {
  content_hash: bytes(32),         // sha256 of content
  embedding:    vector(N),         // semantic fingerprint, N=64 for V1 lexical
  label:        string(<=64),      // human-readable name
  provenance:   ProvChain,         // log of who wrote/touched this Sign
  energy_cost:  Energy,            // joules to construct
}

V1.0 concrete layout (128 bytes per slot, 8-byte aligned):

offset  size    field
0x00    32      content_hash       (sha256 raw bytes)
0x20    64      label              (length-prefixed ASCII; byte 0 = length, bytes 1–63 = chars)
0x60    8       energy_cost        (u64 joules; Pod 1.7 typed wrapper)
0x68    8       embedding_handle   (u64; index into vm_embed_pool, defined Pod 3+)
0x70    8       provenance_handle  (u64; index into vm_provchain_pool, defined Pod 3+)
0x78    8       reserved           (V1.1 expansion sentinel)
total   128

Pool: vm_sign_pool, 64 nodes × 128 bytes = 8 KB. Static allocation
in boot/data.asm (placed by Pod 1.7). Matches cap pool sizing (64 ×
128 = 8 KB) per the typed-primitive pool convention (see below).

Handles: Operand stack carries an 8-byte sign_id (pool index).
sign_id 0 = invalid/null; valid range 1–64.

Label representation: Length-prefixed ASCII. Byte 0 holds length
(0–63); bytes 1–63 hold characters. UTF-8 deferred to V1.1.

Embedding and ProvChain: Forward-declared 8-byte handles to pools
landing in Pod 3 (Maid) and Pod 9 (Maid V2). Handle value 0 = no
embedding / no provenance, valid in V1.0.

Validation: Construction-time only (OP_SIGN_NEW). Hash must be 32
bytes, label length ≤ 63, energy_cost in valid range, handle values
either 0 or within their pool ranges. If validation fails, OP_SIGN_NEW
pushes sign_id 0 (null). Accessors (OP_SIGN_HASH, OP_SIGN_LABEL,
OP_SIGN_ENERGY) check sign_id validity; push zero/empty/null on invalid.

Mutability: Immutable post-construction. ProvChain is separately
mutable via the ProvChain pool (Pod 3+); Sign's provenance_handle stays
constant, the chain it points at grows.

Opcodes (0xA0–0xAF):

OP_SIGN_NEW      0xA0   construct Sign from stack args, return sign_id
OP_SIGN_HASH     0xA1   sign_id → content_hash (stack shape TBD Pod 1.7)
OP_SIGN_LABEL    0xA2   sign_id → label as string
OP_SIGN_ENERGY   0xA3   sign_id → energy_cost u64
0xA4–0xAF        reserved (Pod 3+ provenance, embedding ops)

OP_SIGN_NEW stack inputs (top-down): provenance_handle, embedding_handle,
energy_cost, label_addr, hash_addr. Returns sign_id on stack.
```

---

## R2 — Typed Primitive Representation Pattern (verbatim, lines 291–320)

```markdown
#### Typed primitive representation pattern — v6 (Pod 1.6)

All typed primitives in the CBS VM follow a common representation
pattern, established by Sign in Pod 1.6 and inherited by Energy
(Pod 1.7), Outcome<T> (Pod 1.8), Cap<R> (Pod 1.9–1.10), and
Demod<S> (Pod 1.11):

1. Static pool with stack handle. Each primitive type has a
   statically-allocated pool in boot/data.asm. The operand stack
   carries an 8-byte handle (pool index) — not the struct itself.
   Handle 0 = null/invalid; valid range 1–64.

2. Pool sizing. 64 nodes per pool by default (matches cap pool
   precedent from Pod 0.9). Slot size is 128 bytes per node (8 KB
   per pool). V1.1 typed-primitive slot expansion happens across all
   typed primitives in unison.

3. Construction-time validation. The OP_<TYPE>_NEW constructor
   validates inputs. If validation fails, it pushes handle 0 (null).
   Accessors check handle validity; push zero/empty/null on invalid
   handle. No use-time re-validation of field contents in V1.0.

4. Immutable values. Once constructed, pool slots are read-only.
   Variable-sized or appendable data (e.g. ProvChain) lives in
   separate pools; the parent struct carries a fixed handle to the
   external pool.

5. 8-byte alignment. All fields within a pool slot are aligned
   to 8-byte boundaries. Variable-length fields (labels, hashes)
   occupy fixed-size regions within the slot.
```

---

## R3 — boot/vmdata.asm (verbatim, 22 lines)

```nasm
; =============================================================
; VM Runtime Data — Stack, Vars, Energy, Memory Map
; Engywook's notebook. The state he keeps to know whether the
; rules are being honored.
; Labels: energy_budget, energy_used, vm_ret_ptr, vm_ret_stack,
;         vm_stack, vm_vars, mmap_buf
; Layer:  Layer 1 — VM runtime (kept separate from cbs_vm.asm so
;         Pod 1 can extend without touching opcode handlers)
; =============================================================

    align 16
energy_budget: dq 100000
energy_used:   dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dq 0      ; 512 bytes variables (64-bit, Pod 1.5)

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0
```

**Insertion point for vm_sign_pool:** After vm_vars (line 17), before the
mmap_buf alignment (line 19). New block:

```nasm
; Sign pool (64 nodes × 128 bytes = 8KB, Pod 1.7)
    align 16
vm_sign_pool:   times 64 * 128 db 0
vm_sign_next:   dq 0            ; bump allocator index (next free slot)
```

---

## R4 — boot/defines.asm opcode section (verbatim, lines 55–89)

```nasm
; --- CBS VM Opcodes ---
%define OP_PUSH       0x01
%define OP_ADD        0x10
%define OP_SUB        0x11
%define OP_MUL        0x12
%define OP_DIV        0x13
%define OP_EQ         0x14
%define OP_NE         0x15
%define OP_LT         0x16
%define OP_GT         0x17
%define OP_LE         0x18
%define OP_GE         0x19
%define OP_RESERVE    0x20
%define OP_RET        0x53
%define OP_JIF        0x55
%define OP_JBACK      0x56
%define OP_LOAD       0x70
%define OP_STORE      0x71
%define OP_PRINT_NUM  0x80
%define OP_EMIT       0x81
%define OP_NEWLINE    0x82
%define OP_DUP        0x83
%define OP_DROP       0x84
%define OP_SWAP       0x85
%define OP_PRINT_STR  0x86
%define OP_JMP        0x40
%define OP_PUSH_STR   0x02
%define OP_MOD        0x1A
%define OP_CALL       0x50
%define OP_DUP2       0x87
%define OP_GRANT_CAP  0x90
%define OP_USE_CAP    0x91
%define OP_HALT       0xFF
%define OP_GRANT_CAP_NEW 0xCA000003
%define OP_USE_CAP_NEW 0xCA000004
```

0xA0–0xA3 free. Confirmed.

---

## R5 — Dispatch Chain (verbatim, lines 57–118)

```nasm
    cmp     al, OP_HALT
    je      .op_halt
    cmp     al, OP_PUSH
    je      .op_push
    cmp     al, OP_ADD
    je      .op_add
    cmp     al, OP_SUB
    je      .op_sub
    cmp     al, OP_MUL
    je      .op_mul
    cmp     al, OP_DIV
    je      .op_div
    cmp     al, OP_EQ
    je      .op_eq
    cmp     al, OP_NE
    je      .op_ne
    cmp     al, OP_LT
    je      .op_lt
    cmp     al, OP_GT
    je      .op_gt
    cmp     al, OP_LE
    je      .op_le
    cmp     al, OP_GE
    je      .op_ge
    cmp     al, OP_MOD
    je      .op_mod
    cmp     al, OP_CALL
    je      .op_call
    cmp     al, OP_GRANT_CAP
    je      .op_grant_cap
    cmp     al, OP_USE_CAP
    je      .op_use_cap
    cmp     al, OP_RESERVE
    je      .op_reserve
    cmp     al, OP_RET
    je      .op_ret
    cmp     al, OP_JIF
    je      .op_jif
    cmp     al, OP_JBACK
    je      .op_jback
    cmp     al, OP_LOAD
    je      .op_load
    cmp     al, OP_STORE
    je      .op_store
    cmp     al, OP_PRINT_NUM
    je      .op_print_num
    cmp     al, OP_EMIT
    je      .op_emit
    cmp     al, OP_NEWLINE
    je      .op_newline
    cmp     al, OP_DUP
    je      .op_dup
    cmp     al, OP_DROP
    je      .op_drop
    cmp     al, OP_SWAP
    je      .op_swap
    cmp     al, OP_JMP
    je      .op_jmp
    cmp     al, OP_PUSH_STR
    je      .op_push_str
    cmp     al, OP_PRINT_STR
    je      .op_print_str
```

31 dispatched opcodes. No OP_SIGN entries. 4 new dispatch pairs needed.

---

## R7 — cap_alloc_node Prior Art (verbatim, lines 191–204)

```nasm
; =============================================================================
; cap_alloc_node: Allocates a new node in cap_graph.
; Output: EAX = node pointer, or 0 if no space.
; =============================================================================
cap_alloc_node:
    mov ecx, [cap_next_index]
    cmp ecx, MAX_CAP_NODES
    jge .error_no_space

    lea eax, [cap_graph + ecx * CAP_NODE_size]
    inc dword [cap_next_index]
    ret
.error_no_space:
    xor eax, eax
```

**Pattern for vm_sign_alloc:** Mirror this bump allocator. Differences:
- 64-bit registers (rcx, rax) per Pod 1.5 width migration
- `vm_sign_next` instead of `cap_next_index`
- `vm_sign_pool` instead of `cap_graph`
- Multiply by 128 (slot size) instead of `CAP_NODE_size`
- Return 1-based sign_id (index+1), not raw pointer, per A1 handle convention
- Return 0 on failure (null handle)

---

## R8 — Existing Test Infrastructure (summary)

| File | Type | Notes |
|------|------|-------|
| test_vm.py | Python unit tests | Tests raw bytecode arrays against a Python VM class |
| test_compiler.py | Python unit tests | Tests CBS→bytecode compilation |
| test_parser.py | Python unit tests | Tests CBS parser |
| test_lexer.cbs | CBS source | Lexer test program |
| test_parser.cbs | CBS source | Parser test program |
| test_compiler.cbs | CBS source | Compiler test program |
| test_qemu.sh | Shell script | QEMU-based integration test |
| tools/chauncey_test.md | Markdown | Test specification doc |

Pod 1.7 test program: a .cbs file compiled via atreyu_x86.py that exercises
OP_SIGN_NEW and accessor opcodes, printing results to verify correct behavior.

---

## Section 2 — Surprises

### S1 — OP_SIGN_HASH stack shape still TBD

RECONSTITUTION.md line 174 reads: `sign_id → content_hash (stack shape TBD
Pod 1.7)`. Pod 1.6 Decision Record A3 deferred this question with two
options: (a) push 4 slots (32 bytes across 4×8B slots), or (b) push hash
to a buffer and push buffer pointer.

This is the D1.7.1 decision from the Pod 1.7 prompt. Not a surprise per se
— it was explicitly forward-declared — but it IS the single highest-risk
design question in this pod. The stack shape decision affects toolchain
emission, any program that reads Sign hashes, and the accessor handler's
register usage.

### S2 — atreyu_x86.py stale "push i32" comment

Line 9 reads `# push i32`. Should be `# push i64` per Pod 1.5 width
migration. Forward-declared in Pod 1.5.5 §AQ2 and Pod 1.6 forward-looking
ledger item 4. Will be fixed as part of this pod's toolchain changes.

### S3 — boot/vmdata.asm header label list will need updating

Line 5 lists `; Labels: energy_budget, energy_used, vm_ret_ptr, vm_ret_stack,`
and line 6 lists `;         vm_stack, vm_vars, mmap_buf`. After adding
vm_sign_pool and vm_sign_next, the label list should be updated.

---

## Section 3 — Architect Questions

### AQ1 — D1.7.1: OP_SIGN_HASH stack shape

The Pod 1.7 prompt pre-ratified D1.7.1 as **option (a): push 4 slots**
(low 8B, mid-low 8B, mid-high 8B, high 8B). This avoids introducing a
hash-output buffer and keeps hash data on the operand stack where existing
opcodes can manipulate it.

**Verification question:** The architect's prompt says "push 4×8-byte
slots." Confirm this is the ratified answer, or does the architect want
to revisit after seeing the recon?

### AQ2 — Energy deduction for OP_SIGN_NEW

The Pod 1.7 prompt does not specify an energy cost for OP_SIGN_NEW. The
existing energy model (energy_budget / energy_used in vmdata.asm, OP_RESERVE
sets the budget) has no per-opcode cost table — that's Pod 1.8 (Energy
typed primitive). Should OP_SIGN_NEW deduct a fixed energy cost from
energy_used, or should energy accounting be deferred entirely to Pod 1.8?

**Recommendation:** Defer. OP_RESERVE sets the budget; the VM currently
burns no energy per-opcode. Adding per-opcode costs piecemeal before the
Energy primitive exists creates an inconsistent model.

### AQ3 — vm_sign_pool placement: vmdata.asm vs data.asm

RECONSTITUTION.md line 147 says "Static allocation in `boot/data.asm`
(placed by Pod 1.7)." But actual VM runtime data lives in `boot/vmdata.asm`
(which was split from cbs_vm.asm exactly so Pod 1 extensions wouldn't touch
opcode handlers). The Pod 1.6 forward-looking ledger item 2 says
"`boot/vmdata.asm` or `boot/data.asm`" and asks Pod 1.7 to confirm.

**Recommendation:** `boot/vmdata.asm`. It's the VM runtime data file. The
header comment says "kept separate from cbs_vm.asm so Pod 1 can extend
without touching opcode handlers." vm_sign_pool is VM runtime data. data.asm
is the static data warehouse (strings, bytecode, fonts, UEFI state).

---

## Section 4 — Proposed Phase 2 Plan

Pending architect AUTHORIZED and AQ resolution. Phase 2 has four sub-phases
per the Pod 1.7 prompt:

**2A — Code changes (4 files):**
1. boot/defines.asm: Add OP_SIGN_NEW/HASH/LABEL/ENERGY defines
2. boot/vmdata.asm: Add vm_sign_pool (64×128=8KB) + vm_sign_next
3. boot/cbs_vm.asm: Add 4 dispatch entries + 4 handlers + vm_sign_alloc
4. tools/atreyu_x86.py: Add OP_SIGN_* constants + emission support + fix stale comment

**2B — Build + test:**
Build with nasm + test program execution

**2C — Canon edits:**
RECONSTITUTION.md: flip Pod 1.6 row, add Pod 1.5.6 row if missing,
renumber 1.7→1.13 per prompt, update "placed by Pod 1.7" line

**2D — Commit + push:**
Per MEMO_VERIFICATION_PROVENANCE discipline

---

*Phase 1 complete. Halting for architect AUTHORIZED.*

*From layer 1 kernel up.*
