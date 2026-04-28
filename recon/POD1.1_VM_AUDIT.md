# Pod 1.1 — VM Substrate Audit

**Date:** 2026-04-27
**Pod:** 1.1 (recon-only, no source changes)
**Files audited:** `boot/cbs_vm.asm` (721 lines), `boot/defines.asm`
(89 lines), `boot/vmdata.asm` (21 lines), `boot/data.asm` (secondary)
**Binary contract:** Preserved (no source touched).

---

## T1 — Dispatch Loop Shape

### Main loop: `cbs_vm.asm:46–125`

**Fetch:** Single-byte opcode fetch at `:46–53`.
```nasm
.fetch:
    test    r14d, r14d          ; energy check
    jz      .fatigue
    dec     r14d                ; debit 1 joule per fetch cycle
    inc     qword [rel energy_used]
    movzx   eax, byte [r12]    ; fetch opcode (single byte)
    inc     r12                 ; advance PC
```

**Decode/dispatch:** Linear `cmp al, OP_X / je .op_x` chain, 31
comparisons (`:55–116`). Not a jump table. Chain length = 31. Falls
through to unknown-opcode handler at `:118–125`.

**PC advancement:** `r12` is the program counter. Incremented by 1 at
fetch (`:53`). Opcodes with operands advance `r12` further in their
handlers (e.g., `OP_PUSH` adds 4 at `:135`, `OP_PUSH_STR` adds
2 + strlen + padding at `:664–677`).

**Jump/call PC modification:**
- `OP_JIF` (`:360–368`): signed 32-bit offset added to `r12`
  (forward jump)
- `OP_JBACK` (`:371–375`): unsigned 32-bit value subtracted from `r12`
  (backward jump)
- `OP_JMP` (`:654–658`): `movsxd` signed 32-bit offset added to `r12`
- `OP_CALL` (`:628–643`): pops absolute PC from stack, saves current
  `r12` to `vm_ret_stack`, sets `r12` to target

**Reserved registers:**

| Register | Purpose | Scope |
|----------|---------|-------|
| `r12` | PC (program counter) | Bytecode pointer |
| `r13` | SP (CBS stack pointer) | Points into `vm_stack` |
| `r14` / `r14d` | Energy budget | Joules remaining |
| `r15` / `r15d` | Energy used | Cumulative joules consumed |

**Free for handler use:** `rax`, `rbx`, `rcx`, `rdx`, `rsi`, `rdi`,
`r8`–`r11`. Handlers use `eax`/`ebx` freely for operand manipulation.

### Performance note

The 31-comparison linear chain is O(n) per opcode. A jump table
(256-entry, indexed by opcode byte) would be O(1). Not a correctness
issue — performance optimization for Pod 1 if needed.

---

## T2 — Stack Discipline

**Operand stack:**
- **Label:** `vm_stack` (in `vmdata.asm:16`)
- **Slot width:** 8 bytes (`dq` slots), but most handlers use 32-bit
  `mov eax, [r13]` / `mov [r13], eax` — only 4 bytes of each 8-byte
  slot are used for integer operations. Pointer operations (cap tokens,
  string pointers) use full 64-bit `mov rax`.
- **Maximum depth:** 512 slots × 8 bytes = 4 KB (`times 512 dq 0`)
- **SP register:** `r13` — initialized to `lea r13, [rel vm_stack]`
  at `:39`
- **Growth direction:** Upward. Push = `mov [r13], eax; add r13, 8`.
  Pop = `sub r13, 8; mov eax, [r13]`.
- **Underflow detection:** Only in `OP_RET` (`:341–342`):
  `cmp r13, rax / jle .ret_empty`. All other handlers pop blindly.
  **No general underflow guard.**
- **Overflow detection:** **None.** No bounds check before push. Stack
  overflow silently corrupts memory beyond `vm_stack`.

**Return stack (separate):**
- **Label:** `vm_ret_stack` (in `vmdata.asm:15`)
- **Size:** 256 slots × 8 bytes = 2 KB
- **Pointer:** `vm_ret_ptr` (in `vmdata.asm:14`) — index into
  `vm_ret_stack`
- **Used by:** `OP_CALL` only (`:628–643`). Saves `r12` (current PC).
- **Note:** `OP_RET` (`:338–357`) does NOT pop from `vm_ret_stack` —
  it prints the top-of-stack value and exits the VM entirely. There is
  no "return from subroutine" implementation. `OP_CALL` saves the
  return address but nothing reads it back. **This is a latent bug or
  incomplete feature.**

**Variable slots:**
- **Label:** `vm_vars` (in `vmdata.asm:17`)
- **Size:** 64 slots × 4 bytes = 256 bytes (`times 64 dd 0`)
- **Access:** `OP_LOAD` (`:378–385`) and `OP_STORE` (`:388–395`) use
  `[rbx + rax*4]` — 32-bit indexing into 32-bit slots.
- **Bounds check:** **None.** Out-of-range index silently reads/writes
  beyond `vm_vars`.

---

## T3 — Opcode Inventory

### Opcodes by category

#### Data (2 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_PUSH | 0x01 | Yes `:56` | Yes `:133` | imm32 | Push 32-bit value |
| OP_PUSH_STR | 0x02 | Yes `:81` | Yes `:663` | u16 len + bytes + pad | Push string ptr+len (2 stack slots) |

#### Arithmetic (8 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_ADD | 0x10 | Yes `:57` | Yes `:141` | |
| OP_SUB | 0x11 | Yes `:58` | Yes `:151` | |
| OP_MUL | 0x12 | Yes `:59` | Yes `:161` | Uses `imul` (signed) |
| OP_DIV | 0x13 | Yes `:60` | Yes `:188` | Uses `idiv` (signed), div-by-zero → push 0 |
| OP_EQ | 0x14 | Yes `:61` | Yes `:206` | |
| OP_NE | 0x15 | Yes `:62` | Yes `:218` | |
| OP_LT | 0x16 | Yes `:63` | Yes `:230` | Signed comparison |
| OP_GT | 0x17 | Yes `:64` | Yes `:242` | Signed comparison |
| OP_LE | 0x18 | Yes `:65` | Yes `:254` | |
| OP_GE | 0x19 | Yes `:66` | Yes `:266` | |
| OP_MOD | 0x1A | Yes `:82` | Yes `:171` | Uses `div` (unsigned!), zero → push 0 |

#### Energy (1 opcode)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_RESERVE | 0x20 | Yes `:67` | Yes `:279` | imm32 | Reserve energy; fail → skip to end |

#### Control flow (5 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_JMP | 0x40 | Yes `:80` | Yes `:654` | signed i32 | Unconditional relative jump |
| OP_CALL | 0x50 | Yes `:83` | Yes `:628` | (stack) | Pops absolute PC; saves return addr (never used) |
| OP_RET | 0x53 | Yes `:68` | Yes `:339` | — | **Exits VM**, does not return from call |
| OP_JIF | 0x55 | Yes `:69` | Yes `:360` | signed i32 | Jump if false (TOS == 0) |
| OP_JBACK | 0x56 | Yes `:70` | Yes `:371` | u32 | Jump backward by offset |

#### Memory (2 opcodes)

| Opcode | Hex | Defined | Handled | Operand | Notes |
|--------|-----|---------|---------|---------|-------|
| OP_LOAD | 0x70 | Yes `:71` | Yes `:378` | u32 index | Load from vm_vars |
| OP_STORE | 0x71 | Yes `:72` | Yes `:388` | u32 index | Store to vm_vars |

#### I/O (4 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_PRINT_NUM | 0x80 | Yes `:73` | Yes `:592` | Prints as signed decimal |
| OP_EMIT | 0x81 | Yes `:74` | Yes `:598` | Emits single char via auryn_putc |
| OP_NEWLINE | 0x82 | Yes `:75` | Yes `:604` | Emits `\n` |
| OP_PRINT_STR | 0x86 | Yes `:79` | Yes `:681` | Pops ptr+len, prints chars |

#### Stack manipulation (4 opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_DUP | 0x83 | Yes `:76` | Yes `:610` | |
| OP_DROP | 0x84 | Yes `:77` | Yes `:616` | |
| OP_SWAP | 0x85 | Yes `:78` | Yes `:620` | |
| OP_DUP2 | 0x87 | Yes `:84` | **YES** `:645` | **Not in dispatch chain!** See ghost analysis below |

#### Capability (2 live opcodes)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_GRANT_CAP | 0x90 | Yes `:85` | Yes `:397` | Live — creates token from resource ID |
| OP_USE_CAP | 0x91 | Yes `:86` | Yes `:512` | Live — dispatches on token to surface caps |

#### Special (1 opcode)

| Opcode | Hex | Defined | Handled | Notes |
|--------|-----|---------|---------|-------|
| OP_HALT | 0xFF | Yes `:87` | Yes `:700` | Prints energy summary, exits VM |

### Ghost analysis

#### OP_DUP2 (0x87) — Handler exists, dispatch missing

**Surprise:** `OP_DUP2` has a fully implemented handler at `:645–652`
but is **not in the dispatch chain** (no `cmp al, OP_DUP2 / je .op_dup2`
in the `:55–116` cmp/je sequence). The handler is unreachable dead code.
Any bytecode containing `0x87` hits the unknown-opcode error path.

To wire it: add `cmp al, OP_DUP2 / je .op_dup2` to the dispatch chain
(between `OP_SWAP` at `:110` and the unknown-opcode handler at `:118`).

#### OP_GRANT_CAP_NEW (0xCA000003) — Define is a token value, not an opcode

**Not a real opcode.** The value `0xCA000003` is used at `cbs_vm.asm:525`
as a capability **token value** (`MORLA_FS`) compared against `rax` in
`op_use_cap`'s dispatch. It is unreachable as an opcode because dispatch
fetches a single byte (`movzx eax, byte [r12]`) — `0xCA000003` would
require 4 bytes. The `%define` is misleadingly named; the value is a cap
token constant, not an opcode.

#### OP_USE_CAP_NEW (0xCA000004) — Same situation

`0xCA000004` is used at `cbs_vm.asm:528` as the `ROCKBITER` capability
token value. Same analysis as above: cap token constant, not an opcode.
Misleadingly named with `OP_` prefix.

#### Wild handlers: None

Every handled label in the dispatch chain corresponds to a defined
`OP_*` constant. No undocumented opcodes.

### Summary

| Category | Count |
|----------|-------|
| Defined in defines.asm | 34 |
| In dispatch chain (reachable) | 31 |
| Handler exists, not dispatched (OP_DUP2) | 1 |
| Cap token constants misnamed as OP_* | 2 |
| Wild (handled but undefined) | 0 |

---

## T4 — Data Segment Layout

### Mutable VM state in `boot/vmdata.asm`

| Label | Declaration | Size | Purpose |
|-------|-------------|------|---------|
| `energy_budget` | `dq 100000` | 8 bytes | Global energy budget (not per-VM-instance) |
| `energy_used` | `dq 0` | 8 bytes | Cumulative energy consumed |
| `vm_ret_ptr` | `dq 0` | 8 bytes | Return stack index |
| `vm_ret_stack` | `times 256 dq 0` | 2 KB | Return address stack |
| `vm_stack` | `times 512 dq 0` | 4 KB | Operand stack |
| `vm_vars` | `times 64 dd 0` | 256 bytes | Addressable variable slots |
| `mmap_buf` | `times 8192 db 0` | 8 KB | UEFI memory map (not VM-specific) |

**Scope:** All labels are global (single static allocation). The VM is
**not reentrant** — there is one stack, one variable bank, one energy
counter. Concurrent or nested VM invocations would corrupt state.

### VM-relevant state in `boot/data.asm`

| Label | Declaration | Size | Purpose |
|-------|-------------|------|---------|
| `atreyu_size` | `dq 0` | 8 bytes | Editor buffer length (Atreyu surface) |
| `external_prog_buf` | `times 65536 db 0` | 64 KB | Buffer for loaded .cbc programs |
| `key_data` | `dd 0` | 4 bytes | Keyboard scancode (shared with keyboard driver) |
| `str_vm_*` | Various `db` | ~200 bytes | VM output strings (start, halt, ret, etc.) |
| `prog_table` | `dq × 8 entries` | 64 bytes | Embedded program dispatch table |
| `cbs_demo` | Bytecode | ~300 bytes | Inline demo bytecode |
| `prog1`–`prog4` | Bytecode | ~500 bytes total | Inline demo programs |
| `atreyu_cbs_prog` | `incbin "boot/atreyu.cbc"` | 645 bytes | Atreyu surface bytecode |
| `rockbiter_cbs_prog` | `incbin "boot/rockbiter.cbc"` | 238 bytes | Rockbiter surface bytecode |

### Capability storage

**None.** There is no cap pool, cap table, or cap graph in the live VM.
`OP_GRANT_CAP` creates tokens by adding `0xCA000000` to a resource ID
at runtime — pure arithmetic, no persistent storage. `OP_USE_CAP`
dispatches on the token value via hardcoded `cmp` comparisons. Caps are
ephemeral stack values, not stored objects.

### Heap / arena

**None.** The VM has no dynamic allocation. All storage is statically
sized at assembly time.

---

## T5 — Surface Token Format

### The 23-byte header: Python toolchain only, not in the NASM VM

The "23-byte surface token header" described in `README.md` exists
**only in the Python-era CBS toolchain** (`tools/cbsc.cbs:40–52`):

```
Bytes 0-3:   capability_id (u32 LE)
Bytes 4-5:   x coordinate (u16 LE)
Bytes 6-7:   y coordinate (u16 LE)
Bytes 8-9:   energy (u16 LE)
Bytes 10-17: data_ptr (u64 LE)
Byte 18:     revoke_flag (u8)
Bytes 19-22: checksum (4 bytes, placeholder 0xCAFEBABA)
```

**The NASM VM (`cbs_vm.asm`) does not parse this header.** It receives a
raw pointer to bytecode in `r12` and begins executing at byte 0. No
header parsing, no checksum validation, no capability_id extraction.

The embedded `.cbc` files (`boot/atreyu.cbc`, `boot/rockbiter.cbc`,
etc.) are compiled by the Python toolchain and presumably contain this
header. But `cbs_run` treats them as raw bytecode starting from the
pointer given — it doesn't skip 23 bytes.

**Implication:** Either the `.cbc` files don't actually contain the
23-byte header (the Python compiler may strip it for NASM targets), or
the NASM VM is accidentally executing header bytes as opcodes. Needs
verification by hex-dumping a .cbc file. Either way, the README's claim
about the VM does not match the NASM VM's behavior.

---

## T6 — Energy Accounting Plumbing

### What's real

Energy accounting is **partially implemented and functional**.

**Budget initialization:**
- Callers set `r14d` before calling `cbs_run` (e.g., `mov r14d, 100000`
  at `bastian.asm:136`, `mov r14d, 10000` at `gmork_cmds.asm:409`)
- `energy_used` is zeroed at entry (`cbs_vm.asm:40`)
- `energy_budget` in `vmdata.asm:12` is a static `dq 100000` — but
  `cbs_run` ignores it, using `r14d` instead

**Per-fetch debit:**
- Every fetch cycle costs 1 joule: `dec r14d` at `:50`
- Energy used is tracked: `inc qword [rel energy_used]` at `:51`

**OP_RESERVE (`:279–336`):**
- Bytecode declares energy cost via `OP_RESERVE imm32`
- If `r14d < imm32`: prints "DEGRADED" and skips to HALT/RET
  (`:294–336`)
- If sufficient: deducts from `r14d`, adds to `r15d` (`:284–285`)
- This is the "every CBS function declares costs Nj" mechanism

**Energy summary at exit (`:704–715`):**
- Prints "Energy: Nj used, Mj remaining" on every VM exit

### What's real but inconsistent

- `r14d` (32-bit) is the live budget register, but `energy_budget` in
  vmdata.asm is `dq` (64-bit). The static `energy_budget` label appears
  to be read only by the `cap_rockbiter` handler (`:501–502`) which
  pushes it onto the CBS stack for the Rockbiter surface to display.
- `r15d` tracks OP_RESERVE reservations, while `energy_used` tracks
  fetch cycles. These are two separate energy counters counting different
  things. The exit summary prints `r15d` as "used" (`:708`) and `r14d`
  as "remaining" (`:712`).
- Per-opcode cost is flat (1 joule per fetch). `OP_RESERVE` cost is
  per-program-declaration. There is no per-opcode-type cost table.

### What's aspirational

- No per-opcode-type cost differentiation (every opcode costs 1j at
  fetch regardless of complexity)
- No per-surface energy isolation (all programs share the single `r14d`
  budget)
- No "energy market" or P2P energy trading
- `energy_budget` label is not used as the VM's budget — it's a display
  value for Rockbiter
- Bankruptcy is real (DEGRADED path works) but recovery is not — the VM
  just skips to end

---

## T7 — Capability Hooks

### Live single-byte cap ops

#### OP_GRANT_CAP (0x90) — `cbs_vm.asm:397–405`

```nasm
.op_grant_cap:
    sub     r13, 8
    mov     rax, [r13]          ; pop resource ID
    add     eax, 0xCA000000     ; token = ID + magic
    mov     [r13], rax
    add     r13, 8              ; push token
    jmp     .fetch
```

**What it does:** Pops a resource ID from the stack, adds `0xCA000000`
to create a "capability token," pushes the token back. No cryptography,
no signature, no cap pool, no persistence. The token is an integer
encoding: `0xCA000001` = Auryn display, `0xCA000002` = Gmork CONIN,
`0xCA000003` = Morla FS, `0xCA000004` = Rockbiter.

This is a **token-as-magic-number** system, not a capability system.
Any bytecode can forge any token by pushing the right integer and adding
`0xCA000000`.

#### OP_USE_CAP (0x91) — `cbs_vm.asm:512–589`

```nasm
.op_use_cap:
    sub     r13, 8
    mov     rax, [r13]          ; pop token
    sub     r13, 8
    mov     rcx, [r13]          ; pop cmd
    ; Dispatch on token value:
    cmp rax, 0xCA000001         ; AURYN_DISPLAY
    je .cap_auryn
    cmp rax, 0xCA000002         ; GMORK_CONIN
    je .cap_conin
    cmp rax, 0xCA000003         ; MORLA_FS
    je .cap_morla
    cmp rax, 0xCA000004         ; ROCKBITER
    je .cap_rockbiter
```

**What it does:** Pops a token and a command ID from the stack.
Dispatches on the token value to surface-specific handlers. Each surface
has sub-commands:

| Token | Value | Surface | Sub-commands |
|-------|-------|---------|-------------|
| AURYN_DISPLAY | 0xCA000001 | Auryn | 1=putc, 2=fill |
| GMORK_CONIN | 0xCA000002 | Gmork | 1=read key |
| MORLA_FS | 0xCA000003 | Morla | 1=ls, 2=write_file |
| ROCKBITER | 0xCA000004 | Rockbiter | 1=get_energy_budget, 2=get_energy_used |
| ATREYU | (inline) | Atreyu | 1-6: get/set_size, get/set_char, insert, delete |

**Atreyu note:** The Atreyu cap handler (`:408–493`) exists as code but
has **no token dispatch entry** in `op_use_cap`. There is no
`cmp rax, 0xCA000005 / je .cap_atreyu`. The Atreyu editor operations
are **unreachable dead code** unless called through some other mechanism
not visible in the audit.

### Ghost multi-byte cap ops (unreachable)

| Define | Value | Status |
|--------|-------|--------|
| OP_GRANT_CAP_NEW | 0xCA000003 | **Not an opcode.** Value is the Morla FS cap token. Misleadingly named. Unreachable via single-byte dispatch. |
| OP_USE_CAP_NEW | 0xCA000004 | **Not an opcode.** Value is the Rockbiter cap token. Same analysis. |

These defines should be renamed or removed. They are cap token constants,
not opcodes. Suggested rename: `CAP_TOKEN_MORLA` and `CAP_TOKEN_ROCKBITER`
(or remove entirely, since the values are hardcoded in `op_use_cap`).

### Cap pool / storage

**None in the live VM.** No `cap_*` labels. No cap table. No cap graph
structure. All capability state exists as ephemeral stack values during
bytecode execution. The exiled `kernel/_future/cap_graph.asm` has a
64-node static pool, but nothing in the live build references it.

---

## T8 — Build Pipeline

### Include path

`boot/boot.asm:369`: `%include "boot/cbs_vm.asm"`

### Order of inclusion

```
 1. boot/defines.asm         ← OP_* constants
 2. (inline) PE32+ headers, efi_entry
 3. boot/auryn.asm           ← auryn_putc, auryn_puts (called by VM)
 4. boot/morla.asm           ← morla_ls, morla_write_file (called by VM)
 5. boot/gmork.asm           ← print_dec, print_sdec, print_hex32 (called by VM)
 6. boot/cbs_vm.asm          ← THE VM
 7. boot/bastian.asm         ← calls cbs_run
 8. boot/gmork_cmds.asm      ← calls cbs_run
 9. drivers/kbd_ps2.asm      ← native_keyboard_read (called by VM)
10. drivers/ide_pio.asm
11. drivers/fat32.asm
12. boot/data.asm            ← VM strings, prog_table, bytecode
13. boot/vmdata.asm          ← VM stack, vars, energy
```

The VM is included after all modules it calls into (auryn, morla, gmork)
and before all modules that call it (bastian, gmork_cmds). Data it
references (strings, prog_table, vm_stack) comes after — resolved by
NASM's two-pass assembly.

### Conditional assembly

**None.** Zero `%ifdef` / `%ifndef` / `%if` directives in `cbs_vm.asm`.
The VM compiles identically regardless of build configuration.

### build.sh

```bash
nasm -f bin -o build/BOOTX64.EFI boot/boot.asm
```

Single invocation, flat binary output. No linker, no object files, no
separate compilation units.

---

## T9 — Entry/Exit Conventions

### Entry point

**Label:** `cbs_run` (`cbs_vm.asm:32`)

**Register state on entry:**

| Register | Expected | Set by callers |
|----------|----------|---------------|
| `r12` | Pointer to bytecode | `lea r12, [rel atreyu_cbs_prog]` etc. |
| `r14d` | Energy budget (32-bit) | `mov r14d, 100000` etc. |

No other registers carry VM-meaningful state. `rdi`, `rsi`, `rcx`,
`rdx` are not used as VM inputs.

**ABI note:** This is not System V or Microsoft x64 ABI for parameter
passing. The VM uses a custom convention: `r12` = bytecode pointer,
`r14d` = energy. These registers are callee-saved in both x64 ABIs,
so the caller expects them preserved — but `cbs_run` modifies both
(and does not restore them). This is fine because callers don't use
the post-call values of `r12`/`r14d`.

### Preserved registers

`cbs_run` saves/restores `rbx`, `rbp`, `rcx`, `rdx` (`:33–37`,
`:717–720`). It does NOT save/restore `r12`–`r15` (the VM state
registers), `rsi`, `rdi`, `r8`–`r11`.

### Return

`cbs_run` returns via `ret` (`:721`) after restoring saved registers.
Return value: none in `rax` — the VM communicates results via screen
output, not return values.

### Reentrancy

**Not reentrant.** Global mutable state (`vm_stack`, `vm_vars`,
`vm_ret_ptr`, `energy_used`) would be corrupted by nested calls.
However, `cbs_run` IS called from multiple sites (bastian, morla,
gmork_cmds) — this is safe because calls are sequential, not nested.

---

## T10 — Error Paths

| Error condition | Handler | Location | Action | Recovery? |
|----------------|---------|----------|--------|-----------|
| Unknown opcode | `:118–125` | After dispatch chain | Prints "Unknown opcode: 0xNN", jumps to `.done` | No — VM exits |
| Energy exhausted (fetch) | `.fatigue` `:127–130` | At fetch | Prints "DEGRADED: insufficient energy", jumps to `.done` | No — VM exits |
| OP_RESERVE fail | `.reserve_fail` `:294–336` | In handler | Prints "DEGRADED", skips to HALT/RET | Partial — skips to clean exit |
| Division by zero | `.div_zero` `:200–203` | OP_DIV handler | Pushes 0, continues | Yes — silent recovery |
| Modulo by zero | `.mod_zero` `:183–186` | OP_MOD handler | Pushes 0, continues | Yes — silent recovery |
| Invalid cap token | `:532–535` | OP_USE_CAP | Prints "Unknown opcode:" (reuses wrong string), continues | Yes — continues |
| RET with empty stack | `.ret_empty` `:352–357` | OP_RET | Prints "Return: (void)", exits VM | No — VM exits |
| Stack underflow | **None** | — | Silent corruption | No guard exists |
| Stack overflow | **None** | — | Silent corruption | No guard exists |
| Bad PC (past bytecode) | **None** | — | Reads garbage, UB | No guard exists |
| Token header malformed | **N/A** | — | NASM VM doesn't parse token headers | — |

**Severity assessment:** Stack underflow/overflow and bad-PC are the
most dangerous — they produce silent memory corruption rather than
error messages. For V1 embedded programs this is acceptable (bytecode
is trusted), but Pod 1's typed VM should add bounds checking.

---

## T11 — 32-bit Pointer Residue

### Findings

| Location | Pattern | Severity | Description |
|----------|---------|----------|-------------|
| `:134` | `mov eax, [r12]` | **Cosmetic** | Reads 4-byte immediate from bytecode — intentionally 32-bit (opcodes use imm32 operands) |
| `:136` | `mov [r13], eax` | **Latent** | Stores 32-bit value to 8-byte stack slot. Upper 4 bytes are stale from previous slot content. |
| `:382` | `mov eax, [rbx + rax*4]` | **Cosmetic** | `vm_vars` is `dd` (32-bit) — 32-bit access is correct for 32-bit slots |
| `:394` | `mov [rcx + rax*4], ebx` | **Cosmetic** | Same — correct for 32-bit var slots |
| `:400` | `mov rax, [r13]` | **OK** | Full 64-bit read for cap token |
| `:403` | `mov [r13], rax` | **OK** | Full 64-bit write for cap token |
| `:438–439` | `movzx rax, byte [rbx + rax]` | **OK** | Correctly zero-extends |
| `:611` | `mov eax, [r13 - 8]` | **Latent** | OP_DUP reads 32-bit from 64-bit slot |

### Assessment

The VM operates on 32-bit values for integer arithmetic (intentional —
CBS integers are 32-bit) but uses 8-byte stack slots. This creates a
**mixed-width discipline**: most handlers write `eax` (4 bytes) to an
8-byte slot, leaving the upper 4 bytes as garbage. Handlers that read
back with `mov eax` get the correct 4 bytes. But handlers that read
with `mov rax` (cap ops at `:400`, `:515`) pick up stale upper bits.

**No active bugs found** — the mixed-width pattern is consistent enough
to work. But it's fragile: any handler that accidentally writes `rax`
and then reads `eax` (or vice versa) will see wrong values. Pod 1
should choose one width and enforce it.

---

## T12 — Metrics

| Metric | Value |
|--------|-------|
| Total LoC in `boot/cbs_vm.asm` | 721 (including header, comments, blank lines) |
| Code lines (non-blank, non-comment) | ~620 |
| Total opcodes defined in `defines.asm` | 34 (including 2 misnamed cap tokens) |
| Total opcodes in dispatch chain (reachable) | 31 |
| Unreachable handlers (OP_DUP2) | 1 |
| Ghost defines (misnamed cap tokens) | 2 |
| VM stack size | 4 KB (512 × 8-byte slots) |
| Variable slots | 256 bytes (64 × 4-byte slots) |
| Return stack size | 2 KB (256 × 8-byte slots) |
| BOOTX64.EFI total size | 1,049,600 bytes |
| VM approximate binary contribution | ~2.5–3 KB (estimated from instruction count × avg 4 bytes/instr) |
| Energy model | Per-fetch (1j/cycle) + per-RESERVE (declared) |
| Cap tokens implemented | 4 surface caps (Auryn, Gmork, Morla, Rockbiter) |
| Atreyu cap handler | Exists but unreachable (no dispatch entry) |

### Estimated complexity for typed-primitive replacement

The current VM is a well-structured single-file stack machine with clean
dispatch flow. The complexity for typed-primitive work is **moderate**:

- **Sign:** The VM has no concept of Sign today. This is greenfield —
  new type, new opcodes, new storage. Data representation needs
  designing from scratch.
- **Energy:** Partially implemented. The per-fetch debit and OP_RESERVE
  mechanism work. Typing Energy means adding per-opcode-type cost
  tables, per-surface isolation, and possibly the energy market. Medium
  effort — extend existing plumbing rather than replace it.
- **Cap<R>:** The token-as-magic-number system needs full replacement.
  The `op_grant_cap` / `op_use_cap` handlers work but are not real
  capabilities — they're a dispatch mechanism cosplaying as caps.
  Replacing this with the typed `Cap<R>` from RECONSTITUTION v3
  (64-node pool, parent/child graph, spatial merge, bitmap-based
  permissions) is the largest single piece of Pod 1 work.
- **Outcome<T>:** No prior art in the VM. Greenfield.
- **Demod<S>:** No prior art in the VM. Greenfield.

---

## Open Questions for the Architect

### Q1 — Cap op replacement strategy (blocks Pod 1.6)

Live untyped cap ops exist at 0x90-0x91. Pod 1.6 (typed Cap<R> with
spatial-merge) can:
- **(a) Replace entirely** with new typed opcodes, killing the untyped
  path. Existing .cbc bytecode using `grant_cap`/`use_cap` breaks and
  must be recompiled.
- **(b) Coexist** — keep 0x90-0x91 as legacy and add typed ops in a new
  opcode range. Two cap systems running in parallel, migration over
  time.
- **(c) Extend in place** — modify 0x90-0x91's handlers to be
  typed-aware. Same opcodes, new semantics. Bytecode format changes
  (operands differ).

Each has tradeoffs (correctness, migration, opcode space pressure,
bytecode compat). Architect to choose.

### Q2 — OP_RET semantics: exit VM or return from call?

Currently `OP_RET` exits the VM entirely. `OP_CALL` saves a return
address to `vm_ret_stack` but nothing reads it back. Two possible
intents:
- **(a)** `OP_RET` should pop from `vm_ret_stack` and resume at saved
  PC (subroutine return). `OP_HALT` exits the VM. This makes `OP_CALL`
  useful.
- **(b)** `OP_CALL` is a "tail call" / goto-with-breadcrumbs and the
  return stack is vestigial. `OP_RET` correctly exits.

Pod 1 needs to know which semantics to implement. If (a), the current
`OP_RET` is a bug. If (b), the return stack is dead code.

### Q3 — Atreyu cap handler: dead code or missing dispatch?

`cap_atreyu` (`:408–493`) implements 6 editor operations (get/set_size,
get/set_char, insert, delete) but has no token dispatch entry in
`op_use_cap`. Should Pod 1:
- **(a)** Wire it at `0xCA000005` (add the missing `cmp` in `op_use_cap`)
- **(b)** Leave it dead until Atreyu surface is rebuilt in Pod 6
- **(c)** Remove the dead code now, rebuild from scratch in Pod 6

### Q4 — Integer width: 32-bit or 64-bit?

The VM uses 32-bit integers (`eax`/`ebx`) for arithmetic but 64-bit
stack slots. Pod 1's typed primitives (especially `Cap<R>` with 64-bit
fields) need full 64-bit values. Should the VM:
- **(a)** Widen to 64-bit throughout (all arithmetic uses `rax`/`rbx`).
  Simpler, consistent, but changes bytecode format (PUSH operand
  becomes 8 bytes instead of 4).
- **(b)** Keep 32-bit integers for CBS user code, use 64-bit only for
  typed primitives. Dual-width, but preserves bytecode compat.

### Q5 — Opcode space allocation for Pod 1 types

31 of 256 possible single-byte opcodes are used. Available ranges:
- `0x03–0x0F` (13 slots, near PUSH/PUSH_STR)
- `0x1B–0x1F` (5 slots, after arithmetic)
- `0x21–0x3F` (31 slots, after RESERVE)
- `0x41–0x4F` (15 slots, after JMP)
- `0x51–0x52`, `0x54`, `0x57–0x6F` (27 slots)
- `0x72–0x7F` (14 slots, after LOAD/STORE)
- `0x88–0x8F` (8 slots, after DUP2)
- `0x92–0xFE` (109 slots, after USE_CAP)

RECONSTITUTION v3 suggests `0x40+` for Pod 1 kernel opcodes. That range
is partially occupied (`OP_JMP` at 0x40, `OP_CALL` at 0x50, etc.). The
largest contiguous free block is `0x92–0xFE` (109 slots). Architect to
confirm preferred allocation range for Sign/Cap/Energy/Outcome/Demod
opcodes.

### Q6 — Surface token header alignment

README claims "23-byte surface token header" but the NASM VM doesn't
parse it. The Python toolchain (`tools/cbsc.cbs`) does. For Pod 1.2
(Sign as native type), the Sign struct layout should either:
- **(a)** Replace the 23-byte token header entirely (new format)
- **(b)** Extend the 23-byte header with Sign fields (backward compat
  with Python toolchain)
- **(c)** Ignore the Python toolchain header entirely (NASM VM is the
  authority)

### Q7 — Energy: per-fetch or per-opcode-type?

Current energy model debits 1j per fetch cycle regardless of opcode
complexity. Pod 1.3 (typed Energy) could:
- **(a)** Keep per-fetch flat cost, add OP_RESERVE as the only
  variable-cost mechanism
- **(b)** Introduce per-opcode-type cost table (e.g., OP_MUL costs 3j,
  OP_EMIT costs 5j, OP_GRANT_CAP costs 10j)
- **(c)** Both — per-fetch base cost + per-opcode surcharge

Option (b) is what ROADMAP.md describes ("every CBS function declares
costs Nj"). Option (a) is what exists.

### Q8 — Stack bounds checking

The current VM has no stack underflow or overflow guards (except in
OP_RET). Pod 1 should add bounds checking. Question: should stack
violation be:
- **(a)** Fatal — print error, halt VM
- **(b)** Degraded — set an error flag, energy penalty, continue
- **(c)** Outcome<T> — push `Err(StackOverflow)` as a typed result

This is also a design input for Pod 1.4 (Outcome<T>).
