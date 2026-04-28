# Pod 1.3 — OP_RET Fix Recon Report

**Date:** 2026-04-27
**Pod:** 1.3 (first source pod of Pod 1)
**Files in scope:** `boot/cbs_vm.asm`, `boot/defines.asm`,
`boot/vmdata.asm`, `boot/data.asm`, `boot/*.cbc`
**Binary contract entering:** `cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a`

---

## R1 — OP_RET location

**defines.asm:68:** `%define OP_RET 0x53`

**cbs_vm.asm:89–90** (dispatch entry):
```nasm
    cmp     al, OP_RET
    je      .op_ret
```

**cbs_vm.asm:339–357** (handler):
```nasm
.op_ret:
    ; Pop result if stack non-empty
    lea     rax, [rel vm_stack]
    cmp     r13, rax
    jle     .ret_empty
    sub     r13, 8
    mov     edi, [r13]
    lea     rsi, [rel str_vm_ret]
    call    auryn_puts
    call    print_sdec
    lea     rsi, [rel str_nl]
    call    auryn_puts
    jmp     .done
.ret_empty:
    lea     rsi, [rel str_vm_ret]
    call    auryn_puts
    lea     rsi, [rel str_vm_void]
    call    auryn_puts
    jmp     .done
```

**Current behavior:** Pops top of operand stack (if non-empty), prints
`"  Return: <value>"` or `"  Return: (void)"`, then falls through to
`.done` which prints energy summary and returns to caller. This is a
**VM-exit** primitive, not a subroutine return. It does NOT read
`vm_ret_stack`.

---

## R2 — OP_CALL location

**defines.asm:83:** `%define OP_CALL 0x50`

**cbs_vm.asm:81–82** (dispatch entry):
```nasm
    cmp     al, OP_CALL
    je      .op_call
```

**cbs_vm.asm:628–643** (handler):
```nasm
.op_call:
    ; Pop target PC
    sub     r13, 8
    mov     rax, [r13]
    ; Save current r12 to vm_ret_stack
    push    rbx
    lea     rbx, [rel vm_ret_ptr]
    mov     rcx, [rbx]
    shl     rcx, 3
    lea     rdx, [rel vm_ret_stack]
    add     rdx, rcx
    mov     [rdx], r12
    inc     qword [rbx]
    pop     rbx
    mov     r12, rax
    jmp     .fetch
```

**What gets pushed:** The current `r12` (program counter) — this is the
address of the instruction **after** the OP_CALL, since `r12` was
already incremented past the opcode byte at fetch time (`:53`). OP_CALL
has **no operand** — the target PC comes from the operand stack, not
from inline bytes. So `r12` at push time points to the next opcode
after OP_CALL. This is correct: when OP_RET pops this value and sets
`r12` to it, execution resumes at the instruction after the call site.

**Operand width:** N/A — OP_CALL takes its target from the operand
stack, not from inline bytes. No width change needed for Pod 1.3.

**No bounds check** on `vm_ret_ptr` before push. If `vm_ret_ptr >= 256`,
the write overflows `vm_ret_stack` into `vm_stack`. This is the overflow
bug that Part C must fix.

---

## R3 — vm_ret_stack location

**vmdata.asm:14–15:**
```nasm
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
```

- **Label:** `vm_ret_stack`
- **Depth:** 256 entries
- **Slot width:** 8 bytes (`dq`)
- **Pointer:** `vm_ret_ptr` is a **memory counter** (not a register).
  Holds the current index (0 = empty). NOT the same as the host RSP.
- **Growth direction:** Upward. Push writes to `[vm_ret_stack + vm_ret_ptr*8]`,
  then increments `vm_ret_ptr`.
- **Empty state:** `vm_ret_ptr == 0`

**No register holds vm_ret_ptr persistently.** OP_CALL loads it from
memory each time via `lea rbx, [rel vm_ret_ptr]; mov rcx, [rbx]`.
OP_RET (after fix) must do the same in reverse: load vm_ret_ptr,
check for zero, decrement, read from `[vm_ret_stack + (ptr-1)*8]`.

---

## R4 — cbs_run entry and exit

**Entry (cbs_vm.asm:32–44):**
```nasm
cbs_run:
    push    rbx
    push    rbp
    mov     rbp, rsp
    push    rcx
    push    rdx
    lea     r13, [rel vm_stack]     ; VM stack base
    mov     qword [rel energy_used], 0
    lea     rsi, [rel str_vm_start]
    call    auryn_puts
```

**Exit (.done, cbs_vm.asm:704–721):**
```nasm
.done:
    lea     rsi, [rel str_vm_eu]
    call    auryn_puts
    mov     edi, r15d
    call    print_dec
    lea     rsi, [rel str_vm_jr]
    call    auryn_puts
    mov     edi, r14d
    call    print_dec
    lea     rsi, [rel str_vm_jl]
    call    auryn_puts
    pop     rdx
    pop     rcx
    pop     rbp
    pop     rbx
    ret
```

**Return convention:** None. No register carries a return value to the
caller. The host stack (rbx, rbp, rcx, rdx) is restored. Callers
simply resume their own flow.

**BUG: `vm_ret_ptr` is not reset on entry.** `cbs_run` resets `r13`
(operand stack) and `energy_used`, but does NOT reset `vm_ret_ptr`.
If a previous invocation left dirty entries, the next invocation
inherits them. Phase 2 must add `mov qword [rel vm_ret_ptr], 0` to
the prologue.

---

## R5 — Callers of cbs_run

Eight call sites found. None expect specific register state on return:

| File | Line | After return |
|------|------|-------------|
| `morla.asm` | 177 | falls through to `.f_close` (close file handle) |
| `morla.asm` | 191 | `jmp .d` (done, pop and return) |
| `morla.asm` | 240 | falls through to `.f_close` |
| `gmork_cmds.asm` | 410 | `jmp .prompt` (return to terminal) |
| `bastian.asm` | 137 | `jmp bastian_home` (redraw home) |
| `bastian.asm` | 146 | `jmp bastian_home` |
| `bastian.asm` | 316 | `jmp .redraw` |
| `bastian.asm` | 324 | `jmp .redraw` |

**Conclusion:** OP_HALT's exit path can use the exact same `.done`
path as current OP_RET. No caller convention changes needed.

---

## R6 — OP_RET-as-VM-exit usages

### Embedded programs in `boot/data.asm`

| Program | Label | Line | Final opcode | Migration needed |
|---------|-------|------|-------------|-----------------|
| 1 (Hello) | `prog1` | 372 | `OP_HALT` | No |
| 2 (Math) | `prog2` | 404 | `OP_RET ; return 42` | **Yes** |
| 3 (Loop) | `prog3` | 448 | `OP_HALT` | No |
| 4 (Fibonacci) | `prog4` | 522 | `OP_RET` | **Yes** |
| 5 (Hello Surface) | `surface_hello` | 537 | `OP_HALT` | No |
| 6 (Sched Stub) | `surface_sched_stub` | 551 | `OP_HALT` | No |
| 7 (Compiler Stub) | `surface_compiler_stub` | 564 | `OP_HALT` | No |

**prog2 migration:** Currently pushes 42, then `OP_RET` to print
`"Return: 42"` and exit. After fix: replace `OP_RET` with
`OP_PRINT_NUM` + `OP_NEWLINE` + `OP_HALT` to preserve the visible
output, then exit cleanly.

**prog4 migration:** Currently loads var1 (fibonacci result), then
`OP_RET`. Same pattern: replace with `OP_PRINT_NUM` + `OP_NEWLINE` +
`OP_HALT`.

### External .cbc files

| File | Last bytes | Pattern | Migration needed |
|------|-----------|---------|-----------------|
| `boot/atreyu.cbc` | `...01 0000 0000 53 FF` | PUSH 0, OP_RET, OP_HALT | **Yes** |
| `boot/bastian.cbc` | `...01 0000 0000 53 FF` | PUSH 0, OP_RET, OP_HALT | **Yes** |
| `boot/demo.cbc` | `...86 82 FF` | PRINT_STR, NEWLINE, OP_HALT | No |
| `boot/rockbiter.cbc` | `...01 0000 0000 53 FF` | PUSH 0, OP_RET, OP_HALT | **Yes** |

Three .cbc files end with `PUSH 0, OP_RET, OP_HALT`. After the fix,
OP_RET would try to pop an empty `vm_ret_stack` and halt-on-violation
— the trailing OP_HALT would never execute.

**Binary patch approach:** Replace the `0x53` byte (OP_RET) with
`0x84` (OP_DROP — discards the pushed 0) in each file. The trailing
`0xFF` (OP_HALT) then executes and cleanly exits the VM. This
preserves the file size and alignment. The PUSH 0 + DROP is a no-op
pair, harmless.

Alternative: replace `0x53` directly with `0xFF` (OP_HALT). Then
the sequence is `PUSH 0, OP_HALT, OP_HALT` — first HALT exits,
second never reached. Slightly wasteful (leaves value on stack) but
functionally identical since HALT doesn't inspect the stack.

**Recommendation:** Use the `0x53` → `0x84` (OP_DROP) patch. It's
semantically cleaner (no orphaned stack value) and doesn't create
redundant OP_HALTs.

**Total OP_RET-as-exit count: 5** (2 embedded + 3 .cbc files).

### .cbs source files

No `.cbs` source files contain a `call` keyword. The `.cbs` files
are Python-toolchain source; the NASM VM's embedded programs in
`data.asm` are hand-assembled bytecode. The `.cbc` files are compiled
Python-toolchain artifacts. Migration is binary-level for `.cbc` and
source-level for `data.asm`.

---

## R7 — OP_HALT opcode value

**OP_HALT already exists.**

- **defines.asm:87:** `%define OP_HALT 0xFF`
- **cbs_vm.asm:55–56** (dispatch entry):
  ```nasm
      cmp     al, OP_HALT
      je      .op_halt
  ```
- **cbs_vm.asm:700–703** (handler):
  ```nasm
  .op_halt:
      lea     rsi, [rel str_vm_halt]
      call    auryn_puts
  ```
  Falls through to `.done`.

**This is the biggest recon finding.** The prompt assumed OP_HALT
needed to be created. It already exists at 0xFF, is in the dispatch
chain (first comparison, line 55), prints `"  HALT"` and exits via
`.done`. It does exactly what Part A specifies.

**Phase 2 impact:** Part A is already done. No new opcode needed. No
new dispatch entry needed. No new handler needed. The existing
OP_HALT handler is the correct VM-exit primitive.

**Additional finding:** The `.skip_to_end` handler (`:298–304`) also
already checks for OP_HALT:
```nasm
.skip_to_end:
    movzx   eax, byte [r12]
    inc     r12
    cmp     al, OP_HALT
    je      .op_halt
    cmp     al, OP_RET
    je      .op_ret
```

After the fix, this needs updating. OP_RET is no longer a termination
primitive at the top level. The `cmp al, OP_RET / je .op_ret` lines
in `.skip_to_end` should be removed — scanning for OP_HALT alone is
correct. If a program reaches OP_RET during skip_to_end with an
empty vm_ret_stack, it should fall through to halt-on-violation, which
is the correct degraded behavior.

---

## R8 — Empty vm_ret_stack OP_RET behavior

**Proposed mechanism for underflow (OP_RET with empty stack):**

```nasm
.op_ret:
    ; Check vm_ret_stack for underflow
    lea     rax, [rel vm_ret_ptr]
    mov     rcx, [rax]
    test    rcx, rcx
    jz      .ret_underflow          ; empty stack = violation
    ; Pop return address
    dec     rcx
    mov     [rax], rcx              ; update vm_ret_ptr
    shl     rcx, 3
    lea     rdx, [rel vm_ret_stack]
    mov     r12, [rdx + rcx]        ; restore PC
    jmp     .fetch

.ret_underflow:
    lea     rsi, [rel str_ret_underflow]
    call    auryn_puts
    jmp     .done
```

**New string needed:** `str_ret_underflow: db '  VIOLATION: return stack underflow',10,0`

**Proposed mechanism for overflow (OP_CALL with full stack):**

```nasm
; In .op_call, before the push:
    lea     rbx, [rel vm_ret_ptr]
    mov     rcx, [rbx]
    cmp     rcx, 256                ; vm_ret_stack depth
    jge     .call_overflow
    ; ... existing push logic ...

.call_overflow:
    lea     rsi, [rel str_call_overflow]
    call    auryn_puts
    jmp     .done
```

**New string needed:** `str_call_overflow: db '  VIOLATION: return stack overflow',10,0`

Both violations fall through to `.done` (energy summary + exit). This
is the simplest halt-on-violation placeholder. Pod 1.7 replaces these
with typed `Outcome<T>` errors.

---

## R9 — Test infrastructure

**No existing test exercises OP_CALL.** Confirmed:
- `grep` for `OP_CALL` in `boot/data.asm`: zero matches.
- `grep` for `call` in all `.cbs` files: zero matches.
- No `tests/` directory exists in the repo.

**Proposed minimum test program** (to be added as embedded bytecode
in `data.asm`, alongside existing prog1–prog7):

```
; Program 8: Call/Ret test
; Main: push return sentinel (99), push target addr, CALL sub
; Sub:  push 42, PRINT_NUM, NEWLINE, RET
; Main resumes: PRINT_NUM (prints 99), NEWLINE, HALT
;
; Expected output:
;   42
;   99
;   HALT
;
; If OP_CALL/OP_RET are broken, output will differ.
```

The test proves:
1. OP_CALL transfers control to the target.
2. The target's OP_RET returns to the instruction after OP_CALL.
3. The operand stack is preserved across the call (99 is still there).

The test runs via `gmork> run 8` using the existing `run` command
infrastructure in `gmork_cmds.asm`.

---

## R10 — Standard sweeps A–G

### Sweep A — File inventory
18 files in `boot/`: 10 `.asm`, 4 `.cbc`, 4 `.cbs`. All expected per
canon. No unexpected files.

### Sweep B — Symbol inventory
Key symbols in scope:
- `cbs_run` (cbs_vm.asm:32) — single entry point
- `vm_ret_ptr` (vmdata.asm:14) — return stack pointer
- `vm_ret_stack` (vmdata.asm:15) — return stack storage
- `vm_stack` (vmdata.asm:16) — operand stack
- `energy_budget`, `energy_used` (vmdata.asm:12–13)
No unexpected symbols.

### Sweep C — Cross-module dependencies
cbs_vm.asm calls: `auryn_puts`, `auryn_putc`, `auryn_fill`,
`print_sdec`, `print_dec`, `print_hex32`, `native_keyboard_read`,
`morla_ls`, `morla_write_file`, `morla_run_file_main`.
All expected per header comment.

### Sweep D — Unexpected directories
Top-level: `boot/`, `build/`, `drivers/`, `kernel/`, `prompts/`,
`recon/`, `surfaces/`, `tools/`. All accounted for in canon.

### Sweep E — Recent git history
Most recent commits touching scope: `e6d41b3` (data.asm header),
`9f86040` (header polish), `4f02dcd` (defines extract), `a031226`
(12-slot bastian). No surprises.

### Sweep F — Documentation
Canon docs present: RECONSTITUTION.md (v4), ARCHAEOLOGY.md,
RECON_PROTOCOL.md, ROADMAP.md, README.md, DEFERRED.md. No unexpected
markdown files.

### Sweep G — _future/ cemeteries
`kernel/_future/`: cap_graph.asm, paging.asm (documented exile).
`drivers/_future/`: fat32_write.asm, gpu_intel.asm (documented exile).
No changes since Pod 0.6. No surprises.

**No anomalies detected in standard sweeps.**

---

## R11 — binary_contracts.md

**Confirmed:** `binary_contracts.md` does not exist at repo root or
under `recon/`. No surprise. Phase 2 creates it.

Pod 1.2 committed at `e69f51f`. The table will include:
- Pod 0.x sealed at `d68167c`
- Pods 0.9, 1.0, 1.1, 1.2 preserved the contract
- Pod 1.3 produces the new hash

---

## Summary of Phase 2 impact

| Part | Prompt assumption | Actual state | Impact |
|------|-------------------|-------------|--------|
| A | OP_HALT must be created | **Already exists at 0xFF** | Part A is a no-op |
| B | Rewrite OP_RET | Confirmed needed | Full rewrite per R8 |
| C | Bounds-check OP_CALL | Confirmed needed | Add overflow check |
| D | Migrate callers | 5 usages found (2 data.asm + 3 .cbc) | Binary patch .cbc files |
| E | Add test | No test exists | Add prog8 to data.asm |
| F | Capture new binary | Contract changes here | New hash captured |
| G | Commit | — | Single atomic commit |

**Additional Phase 2 work not in prompt:**
1. Reset `vm_ret_ptr` to 0 in `cbs_run` prologue (R4 bug).
2. Update `.skip_to_end` to remove OP_RET scan (R7 finding).
3. Update `cbs_vm.asm` header comment line 31 ("Returns when HALT or
   RET" → "Returns when HALT").
4. Add two error strings to `data.asm` (R8).
5. Update prog_table and `run` command to support prog8 (R9).
6. For prog2 and prog4 migration: replace `OP_RET` with
   `OP_PRINT_NUM` + `OP_NEWLINE` + `OP_HALT` to preserve visible
   output behavior.

---

## HALT — Awaiting AUTHORIZED
