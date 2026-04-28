# Pod 1.5 — Phase 1 Recon Report (R1–R12)

## Integer Width Migration to 64-bit

**Entry contract:** `fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28`
**Build determinism:** VERIFIED (R9)

---

## R1. Arithmetic handler enumeration

All 32-bit register usage in CBS value operations in `boot/cbs_vm.asm`:

| file:line | Handler | Register | Role | Action |
|-----------|---------|----------|------|--------|
| cbs_vm.asm:135 | .op_push | `eax` in `mov eax, [r12]` | value fetch | WIDEN to `mov rax, [r12]` (8-byte read) |
| cbs_vm.asm:137 | .op_push | `eax` in `mov [r13], eax` | value store | WIDEN to `mov [r13], rax` |
| cbs_vm.asm:136 | .op_push | `add r12, 4` | PC advance | WIDEN to `add r12, 8` |
| cbs_vm.asm:144 | .op_add | `ebx` in `mov ebx, [r13]` | value pop b | WIDEN to `rbx` |
| cbs_vm.asm:146 | .op_add | `eax` in `mov eax, [r13]` | value pop a | WIDEN to `rax` |
| cbs_vm.asm:147 | .op_add | `add eax, ebx` | arithmetic | WIDEN to `add rax, rbx` |
| cbs_vm.asm:148 | .op_add | `mov [r13], eax` | value store | WIDEN to `rax` |
| cbs_vm.asm:153-159 | .op_sub | same pattern as add | value | WIDEN all |
| cbs_vm.asm:163-168 | .op_mul | `imul eax, ebx` | arithmetic | WIDEN to `imul rax, rbx` |
| cbs_vm.asm:173-176 | .op_mod | `ebx`/`eax` pops | value | WIDEN |
| cbs_vm.asm:177 | .op_mod | `test ebx, ebx` | zero check | WIDEN to `test rbx, rbx` |
| cbs_vm.asm:179 | .op_mod | `xor edx, edx` | dividend high | WIDEN to `xor rdx, rdx` |
| cbs_vm.asm:180 | .op_mod | `div ebx` | unsigned div | WIDEN to `div rbx` |
| cbs_vm.asm:181 | .op_mod | `mov [r13], edx` | result store | WIDEN to `rdx` |
| cbs_vm.asm:185 | .mod_zero | `mov dword [r13], 0` | zero store | WIDEN to `mov qword [r13], 0` |
| cbs_vm.asm:191-193 | .op_div | `ebx`/`eax` pops | value | WIDEN |
| cbs_vm.asm:196 | .op_div | `cdq` | sign-extend | WIDEN to `cqo` |
| cbs_vm.asm:197 | .op_div | `idiv ebx` | signed div | WIDEN to `idiv rbx` |
| cbs_vm.asm:198 | .op_div | `mov [r13], eax` | result store | WIDEN |
| cbs_vm.asm:202 | .div_zero | `mov dword [r13], 0` | zero store | WIDEN to qword |
| cbs_vm.asm:209-216 | .op_eq | `ebx`/`eax` pops, `cmp eax,ebx` | comparison | WIDEN pops + cmp |
| cbs_vm.asm:215 | .op_eq | `mov [r13], eax` | bool result (0/1) | WIDEN to `mov [r13], rax` |
| cbs_vm.asm:220-228 | .op_ne | same pattern | comparison | WIDEN all |
| cbs_vm.asm:232-241 | .op_lt | same pattern | comparison | WIDEN all |
| cbs_vm.asm:244-253 | .op_gt | same pattern | comparison | WIDEN all |
| cbs_vm.asm:256-265 | .op_le | same pattern | comparison | WIDEN all |
| cbs_vm.asm:268-277 | .op_ge | same pattern | comparison | WIDEN all |
| cbs_vm.asm:281 | .op_reserve | `mov eax, [r12]` | energy value | WIDEN to 8-byte read |
| cbs_vm.asm:282 | .op_reserve | `add r12, 4` | PC advance | WIDEN to `add r12, 8` |
| cbs_vm.asm:283 | .op_reserve | `cmp r14d, eax` | energy cmp | WIDEN: `cmp r14, rax` |
| cbs_vm.asm:285 | .op_reserve | `sub r14d, eax` | energy debit | WIDEN: `sub r14, rax` |
| cbs_vm.asm:286 | .op_reserve | `add r15d, eax` | energy track | WIDEN: `add r15, rax` |
| cbs_vm.asm:290 | .op_reserve | `mov edi, eax` | print arg | WIDEN: `mov rdi, rax` |
| cbs_vm.asm:360 | .op_jif | `mov ebx, [r13]` | condition pop | WIDEN: value, not offset |
| cbs_vm.asm:364 | .op_jif | `test ebx, ebx` | truth check | WIDEN: `test rbx, rbx` |
| cbs_vm.asm:593 | .op_print_num | `mov edi, [r13]` | value pop | WIDEN: `mov rdi, [r13]` |
| cbs_vm.asm:610 | .op_dup | `mov eax, [r13 - 8]` | value peek | WIDEN to `rax` |
| cbs_vm.asm:611 | .op_dup | `mov [r13], eax` | value store | WIDEN to `rax` |
| cbs_vm.asm:620-623 | .op_swap | 4 × `eax`/`ebx` reads/writes | value | WIDEN all to `rax`/`rbx` |
| cbs_vm.asm:644 | .op_call | `movsxd rax, dword [r13]` | stack pop | WIDEN: `mov rax, [r13]` (full qword) |
| cbs_vm.asm:566 | .conin_none | `mov dword [r13], 0` | zero push | WIDEN to qword |
| cbs_vm.asm:49 | .fetch | `test r14d, r14d` | energy check | WIDEN: `test r14, r14` |
| cbs_vm.asm:51 | .fetch | `dec r14d` | energy dec | WIDEN: `dec r14` |
| cbs_vm.asm:716 | .done | `mov edi, r15d` | print energy | WIDEN: `mov rdi, r15` |
| cbs_vm.asm:720 | .done | `mov edi, r14d` | print energy | WIDEN: `mov rdi, r14` |

**Address-arithmetic sites (legitimately 32-bit, do NOT widen):**
- cbs_vm.asm:53: `movzx eax, byte [r12]` — opcode fetch, 1 byte
- cbs_vm.asm:300: `movzx eax, byte [r12]` — skip scanner opcode fetch
- cbs_vm.asm:326: `movzx eax, word [r12]` — PUSH_STR length field, 2 bytes
- cbs_vm.asm:329-334: string padding arithmetic — address ops
- cbs_vm.asm:544,549: `mov edi, [r13]` — character/color args to auryn_putc/fill (low 32 bits sufficient)
- cbs_vm.asm:599: `mov edi, [r13]` — character to auryn_putc
- cbs_vm.asm:691: `mov ecx, [r13 + 8]` — string length (16-bit value in low bytes)

**Total value-widening sites in cbs_vm.asm: ~55**

**Supporting function sites in gmork.asm:**
| file:line | Function | Issue |
|-----------|----------|-------|
| gmork.asm:161 | print_dec | `mov eax, edi` — 32-bit. Must widen to `mov rax, rdi` |
| gmork.asm:171 | print_dec | `div ecx` — 32-bit divide by 10. Must widen to `div rcx` |
| gmork.asm:170 | print_dec | `xor edx, edx` — must widen to `xor rdx, rdx` |
| gmork.asm:172 | print_dec | `mov ecx, 10` — must widen to `mov rcx, 10` |
| gmork.asm:164 | print_dec | `test eax, eax` — must widen to `test rax, rax` |
| gmork.asm:169 | print_dec | `test eax, eax` — same |
| gmork.asm:187 | print_sdec | `test edi, edi` — must widen to `test rdi, rdi` |
| gmork.asm:193 | print_sdec | `neg edi` — must widen to `neg rdi` |

**Buffer issue:** `dec_buf: times 12 db 0` (data.asm:40) — holds max 10 digits + sign +
null for 32-bit. A 64-bit number needs up to 20 digits. Must widen to `times 22 db 0`.

---

## R2. PUSH operand-fetch enumeration

Single site: `cbs_vm.asm:134-139`:
```nasm
.op_push:
    mov     eax, [r12]       ; fetches 4 bytes from bytecode stream
    add     r12, 4           ; advance PC past operand
    mov     [r13], eax       ; store as dword in 8-byte stack slot
    add     r13, 8
    jmp     .fetch
```

**Widening risk:** `mov eax, [r12]` implicitly zero-extends to rax (clears upper 32 bits).
Under D2, the widened form is `mov rax, [r12]` (reads full 8 bytes). No implicit
zero-extension trap because we read the full width. The only risk is reading past
the end of bytecode — but programs are embedded in static data, so there's always
backing memory. After widening, the bytecode itself encodes 8-byte operands (dq instead
of dd), so the read is correct.

**No other PUSH-like value-fetch sites exist.** OP_RESERVE uses the same pattern
(cbs_vm.asm:281-282).

---

## R3. JMP/CALL/JZ operand-site enumeration

| Opcode | file:line | Current fetch | Status |
|--------|-----------|---------------|--------|
| OP_JMP | cbs_vm.asm:663 | `movsxd rax, dword [r12]; add r12, 4` | Correct: 4-byte signed, movsxd. No change needed. |
| OP_JIF | cbs_vm.asm:360-361 | `mov eax, [r12]; add r12, 4` | **DRIFT:** zero-extends, not sign-extends. Must fix to `movsxd rax, dword [r12]` per D2. Currently works by accident (JIF only jumps forward = positive offsets). |
| OP_JBACK | cbs_vm.asm:371-372 | `mov eax, [r12]; add r12, 4` | **DRIFT:** zero-extends. Fix to `movsxd rax, dword [r12]` per D2. Currently works because operand is always positive (subtracted from PC). |
| OP_CALL | cbs_vm.asm:643-644 | `movsxd rax, dword [r13]` | **NOTE:** reads from operand STACK, not bytecode stream. Has no inline bytecode operand. After value widening, stack slots are 8-byte, so this should become `mov rax, [r13]`. See R1 entry. |
| OP_LOAD | cbs_vm.asm:378-379 | `mov eax, [r12]; add r12, 4` | Variable index. Per D2, fix to `movsxd rax, dword [r12]`. Index is inherently positive; sign-extend is safe. |
| OP_STORE | cbs_vm.asm:388-389 | `mov eax, [r12]; add r12, 4` | Same as LOAD. |

**Finding:** OP_JIF and OP_JBACK drift from the D2 movsxd standard. Both zero-extend
their operands. Neither has broken programs because JIF always jumps forward and JBACK
always has positive operands. Phase 2 normalizes all to movsxd.

**OP_CALL clarification:** OP_CALL has no bytecode-stream operand. It pops from the
operand stack. After PUSH widens to 8 bytes, the value on the stack is already a proper
qword. OP_CALL should read the full qword, not movsxd-from-dword.

---

## R4. vm_ret_stack slot-width enumeration

`boot/vmdata.asm:15`: `vm_ret_stack: times 256 dq 0`

Already 8-byte (qword) slots. The return stack stores INSTRUCTION POINTERS (raw r12
values), not CBS values. r12 is a 64-bit native pointer. These slots must remain 8 bytes
regardless of the value-width migration. **No change needed.**

Push/pop pair in cbs_vm.asm:
- Push (OP_CALL, line 640): `mov [rdx + rax], r12` — stores r12 (64-bit pointer). Correct.
- Pop (OP_RET, line 350): `mov r12, [rdx + rcx]` — loads 64-bit pointer. Correct.

**vm_ret_ptr** (vmdata.asm:14): `dq 0` — 8-byte counter. Used as qword throughout. Correct.

---

## R5. .cbs source program enumeration

| File | Location | Has arithmetic | Has caps | Notes |
|------|----------|---------------|----------|-------|
| boot/demo.cbs | boot/ | Yes (add, while, let) | No | Fibonacci demo. Source for demo.cbc via hardcoded AST in atreyu_x86.py |
| boot/atreyu.cbs | boot/ | Yes (add, sub, comparisons) | Yes (grant_cap, use_cap) | Editor surface. Complex: loops, if/else, cap operations |
| boot/bastian.cbs | boot/ | No | No | Home screen. Print-only. |
| boot/rockbiter.cbs | boot/ | No | Yes (grant_cap, use_cap) | Process manager. Cap queries for energy budget/used |
| hello.cbs | root | No | No | Phase 8 test. "Hello, Codebook!" |
| compiler.cbs | root | Unknown | Unknown | Phase 8 toolchain detritus |
| lexer.cbs | root | Unknown | Unknown | Phase 8 toolchain detritus |
| parser.cbs | root | Unknown | Unknown | Phase 8 toolchain detritus |
| test_*.cbs (3 files) | root | Unknown | Unknown | Phase 8 test files |
| tools/cbsc.cbs | tools/ | N/A | N/A | Phase 8 Python compiler (not CBS source) |
| tools/read_file.cbs | tools/ | N/A | N/A | Phase 8 helper |
| tools/write_file.cbs | tools/ | N/A | N/A | Phase 8 helper |
| tools/vm.cbs | tools/ | N/A | N/A | Phase 8 VM |
| surfaces/*.cbs (9 files) | surfaces/ | Various | Various | Phase 8 surface sources |

**Only boot/*.cbs are relevant** — they are the sources for the .cbc files consumed by the
NASM VM. All root/ and surfaces/ .cbs files are Phase 8 detritus (different toolchain,
different bytecode format). tools/cbsc.cbs is a Python file with .cbs extension.

---

## R6. .cbc binary file enumeration

| File | Size (bytes) | First byte | Last byte | Notes |
|------|-------------|------------|-----------|-------|
| boot/demo.cbc | 425 | 0x40 (OP_JMP) | 0xFF (OP_HALT) | Compiled from demo_full() AST |
| boot/atreyu.cbc | 645 | 0x40 (OP_JMP) | 0xFF (OP_HALT) | Patched Pod 1.3: 0x53→0xFF at offset 643 |
| boot/bastian.cbc | 189 | 0x40 (OP_JMP) | 0xFF (OP_HALT) | Patched Pod 1.3: 0x53→0xFF at offset 187 |
| boot/rockbiter.cbc | 238 | 0x40 (OP_JMP) | 0xFF (OP_HALT) | Patched Pod 1.3: 0x53→0xFF at offset 236 |

All 4 regenerate in Phase 2.

**Critical finding about surface .cbc execution:** The surface .cbc files (atreyu,
bastian, rockbiter) wrap all code inside `fn main()`, which the compiler emits as a
function body after a JMP-over-functions preamble. The JMP at byte 0 jumps to the
OP_HALT at the end. **The function body is dead code** — it's jumped over because the
compiler treats `fn main()` as a function definition, not as inline code. The only
executed instructions are JMP → HALT. The surface .cbc files are effectively no-ops
under the current toolchain.

---

## R7. Python toolchain emission-path enumeration

### CRITICAL FINDING: tools/cbsc.cbs is NOT the .cbc compiler

The pod prompt identifies `tools/cbsc.cbs` as the Python toolchain. **This is incorrect.**

- `tools/cbsc.cbs` is a Phase 8 Python program that compiles .cbs to .cb files using a
  completely different format: 23-byte surface token header + opcodes 0x73/0x78/0x79/0x74.
  It does NOT produce .cbc files. It does NOT use the OP_PUSH/OP_ADD/etc. opcode set.
  It is **irrelevant to the NASM VM**.

- `tools/atreyu_x86.py` is the **actual compiler** that produces .cbc files consumed by
  the NASM VM's `cbs_run`. Its opcodes match `boot/defines.asm` exactly.

- `tools/precompile_all.sh` calls `atreyu_x86.py` but **fails silently** because
  atreyu_x86.py has no parser — it only compiles from a hardcoded AST (`demo_full()`).
  `build.sh` catches the failure: `|| echo "[warn] precompile returned non-zero; using existing .cbc"`

- The 3 surface .cbc files (atreyu, bastian, rockbiter) were compiled by an older
  toolchain version that had a parser, or hand-assembled. The current toolchain cannot
  reproduce them from .cbs source.

### Emission paths in tools/atreyu_x86.py

**Value operands (MUST widen to 8-byte in Phase 2):**

| Line | Context | Current emit | Widened emit |
|------|---------|-------------|--------------|
| 84 | _func OP_RESERVE cost | `e.emit_i32(cost)` | `e.emit_i64(cost)` |
| 86 | _func return value | `e.emit(OP_PUSH); e.emit_i32(0)` | `e.emit_i64(0)` |
| 95 | _stmt let value | (via _expr → OP_PUSH) | via _expr |
| 144 | _expr int | `e.emit(OP_PUSH); e.emit_i32(n['value'])` | `e.emit_i64(n['value'])` |
| 145 | _expr bool | `e.emit(OP_PUSH); e.emit_i32(1/0)` | `e.emit_i64(1/0)` |
| 148 | _expr neg | `e.emit(OP_PUSH); e.emit_i32(0)` | `e.emit_i64(0)` |
| 149 | _expr not | `e.emit(OP_PUSH); e.emit_i32(0)` | `e.emit_i64(0)` |

**Positional operands (stay 4-byte):**

| Line | Context | Emit | Stays |
|------|---------|------|-------|
| 68 | compile: JMP over funcs | `e.emit_i32(0)` + patch | 4-byte |
| 81 | _func: STORE var index | `e.emit_i32(self.var_id(p))` | 4-byte |
| 95 | _stmt let: STORE var index | `e.emit_i32(self.var_id(n['name']))` | 4-byte |
| 121 | _if: JIF offset | `e.emit_i32(0)` + patch | 4-byte |
| 124 | _if: JMP offset (else) | `e.emit_i32(0)` + patch | 4-byte |
| 137 | _while: JIF offset | `e.emit_i32(0)` + patch | 4-byte |
| 139 | _while: JMP offset | `e.emit_i32(top - ...)` | 4-byte |
| 147 | _expr var: LOAD var index | `e.emit_i32(self.var_id(n['name']))` | 4-byte |

**Required toolchain changes:**
1. Add `emit_i64(self, v)` method: `self.code.extend(struct.pack('<q', v))`
2. Change all value-emitting `emit_i32` calls to `emit_i64`
3. All positional `emit_i32` calls stay as-is
4. `patch_i32` stays (only used for JMP/JIF forward-reference patches)

**Offset calculations in the toolchain auto-adjust** — the compiler uses `e.pos()` to track
byte positions. When PUSH operands grow from 5 bytes (1+4) to 9 bytes (1+8), `e.pos()`
reflects the new positions, and forward-reference patches via `patch_i32` calculate correct
offsets. No manual offset adjustment needed.

### Toolchain coupling beyond atreyu_x86.py

**None found.** `tools/precompile_all.sh` and `tools/precompile_*.sh` are wrapper scripts
that call atreyu_x86.py. No other tool emits .cbc bytecode. The Phase 8 tools
(cbsc.cbs, vm.cbs, etc.) are a separate system.

---

## R8. DEFERRED.md current state

| # | One-line summary | Pod 1.5 relevant? |
|---|-----------------|-------------------|
| 1 | LLC / signing entity rename | No |
| 2 | ide_pio.asm NASM warnings | No — Pod 1.5 does not touch drivers/ide_pio.asm |
| 3 | chauncey_test.md Legacy BIOS reference | No |
| 4 | Bastian slot expansion | No |
| 5 | Visual / banner refresh | No |
| 6 | Orphaned opcodes (OP_DUP2 dead code, cap token ghosts) | Tangentially — OP_DUP2 handler at cbs_vm.asm:653 already uses 64-bit (rax/rbx). No widening needed. |
| 7 | README full rewrite + token header cleanup | No |
| 9 | Paging implementation, post-V1 | No |
| 10 | build/BOOTX64.EFI dirty-status tracking | YES — see R9. |
| 11 | cap_atreyu dead code | No |
| 12 | Surface .cbc recompilation after 64-bit migration | YES — this IS Pod 1.5's scope. Text updated in Pod 1.4 to reference Pod 1.5. |
| 13 | Stack-error mechanism design | No |

**DEFERRED #2 (ide_pio NASM warnings):** Pod 1.5 does NOT touch any files in `drivers/`.
The warnings persist. Not incidentally resolved.

**DEFERRED #10 (BOOTX64.EFI tracking):** R9 investigation below. The committed binary
in git differs from on-disk. Can be resolved by `git rm --cached build/BOOTX64.EFI`
and `.gitignore` coverage — but that's a separate cleanup, not Pod 1.5's scope.

---

## R9. Build determinism check — entry contract reproduction

### Step 1: git diff investigation

```
$ git diff --stat build/BOOTX64.EFI
 build/BOOTX64.EFI | Bin 1049600 -> 1049600 bytes
 1 file changed, 0 insertions(+), 0 deletions(-)
```

**Diff is nonzero** — same file size (1,049,600 bytes) but different content.

```
$ git show HEAD:build/BOOTX64.EFI | sha256sum
8c8d8bc3e1bb7a55302cb54c1492f06297e4944087a89275e57d54505852a5ca

$ sha256sum build/BOOTX64.EFI
fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28
```

The **committed** binary (`8c8d8bc3...`) is stale — it dates from early Pod 0 history,
before Pod 1.3's source changes. The **on-disk** binary (`fedcd682...`) is the post-Pod-1.3
build. The binary contract has always referred to the on-disk file, not the git-committed
version.

**This is NOT HALTED-eligible** — the contract chain is consistent. The on-disk binary
matches the contract. The git-committed version is a tracking artifact (DEFERRED #10).

### Step 2: Rebuild from source

```
$ nasm -f bin -o build/BOOTX64.EFI.test boot/boot.asm
drivers/ide_pio.asm:86: warning: implicit DEFAULT ABS is deprecated [-w+implicit-abs-deprecated]
drivers/ide_pio.asm:161: warning: unsigned byte exceeds bounds [-w+number-overflow]
drivers/ide_pio.asm:230: warning: unsigned byte exceeds bounds [-w+number-overflow]
drivers/ide_pio.asm:288: warning: unsigned byte exceeds bounds [-w+number-overflow]

$ sha256sum build/BOOTX64.EFI.test
fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28
```

**BUILD IS DETERMINISTIC.** Clean rebuild from committed source produces the exact
same hash as the on-disk binary and the binary contract.

Entry contract: **VERIFIED.**

---

## R10. Test program enumeration

| Program | file:line | Tests | Has OP_PUSH | Has jumps | Survives width? | Notes |
|---------|-----------|-------|-------------|-----------|----------------|-------|
| prog1 (Hello) | data.asm:318-376 | Char emit | 18 × PUSH + 1 × RESERVE | None | Needs dd→dq for all 19 operands | No offset recalc needed |
| prog2 (Math) | data.asm:380-410 | Add, mul, sub | 8 × PUSH + 1 × RESERVE | None | Needs dd→dq for all 9 operands | No offset recalc needed |
| prog3 (Loop) | data.asm:414-454 | Loop, compare, store/load | 6 × PUSH + 1 × RESERVE | JIF + JBACK | Needs dd→dq for values; NASM recalculates jump offsets automatically via labels | JBACK uses `dd ($ + 4 - .loop3)` — stays dd, offset auto-adjusts |
| prog4 (Fibonacci) | data.asm:460-530 | Fib(10), loop, store/load | 12 × PUSH + 1 × RESERVE | JIF + JBACK | Same as prog3 | |
| surface_hello | data.asm:536-545 | Push_str, print_str | 1 × RESERVE | None | Needs dd→dq for RESERVE | |
| surface_sched_stub | data.asm:550-559 | Push_str, print_str | 1 × RESERVE | None | Same | |
| surface_compiler_stub | data.asm:564-572 | Push_str, print_str | 1 × RESERVE | None | Same | |
| prog8 (Call/Ret) | data.asm:580-598 | OP_CALL/OP_RET roundtrip | 3 × PUSH + 1 × RESERVE | OP_CALL (via stack) | Needs dd→dq for values. Call offset pushed via OP_PUSH — label arithmetic auto-adjusts. | Highest-value test post-migration |
| cbs_demo | data.asm:601 (incbin) | Full CBS demo | In .cbc file | In .cbc file | Regenerate from atreyu_x86.py | |
| atreyu_cbs_prog | data.asm:605 (incbin) | Editor surface | In .cbc file | In .cbc file | Regenerate (see R7 finding) | |
| rockbiter_cbs_prog | data.asm:609 (incbin) | System monitor | In .cbc file | In .cbc file | Regenerate (see R7 finding) | |

**Key finding for prog3/prog4:** These programs use OP_JBACK with `dd ($ + 4 - .loop3)`.
The `$ + 4` refers to the position after the 4-byte JBACK operand. Since JBACK operands
stay 4-byte (positional offset per D1), this expression is structurally correct. The
calculated value changes (because preceding OP_PUSH instructions grew from 5 to 9 bytes,
increasing the loop body size), but NASM recalculates automatically from labels. **No
manual offset adjustment needed.**

**Key finding for prog8:** The call offset `dd (prog8_sub - prog8_ret)` is pushed as a
VALUE via OP_PUSH. After widening, it becomes `dq (prog8_sub - prog8_ret)`. The value
changes (because prog8_ret and prog8_sub move due to wider operands), but NASM handles
the label arithmetic. OP_CALL reads it as a full qword from the stack (see R3 note).

---

## R11. Documentation surface enumeration

### README.md width-related references:
- **Line 15:** "The VM expects a 23-byte surface token header followed by bytecode payloads."
  — Describes cbsc.cbs's format, not the NASM VM. Misleading but covered by DEFERRED #7
  (README full rewrite). Not Pod 1.5's scope.
- No explicit "32-bit" or operand-width references.

### ROADMAP.md width-related references:
- **Line 156:** "Capability graph with energy budgeting — needs 64-bit pointer rewrite"
  — Refers to cap_graph in `kernel/_future/`, not the VM. Accurate as-is.
- No other width references.

**Recommendation:** No documentation changes needed in Phase 2. DEFERRED #7 covers the
README rewrite post-Pod-5.

---

## R12. Workflow leak — prompts/ inventory

```
$ ls prompts/
POD0.0_REFERENCE_LOCK.md    POD0.3_MORLA_EXTRACT.md      POD0.7_AURYN_PUTS_CONSOLIDATION.md
POD0.1_DEFINES_EXTRACT.md   POD0.5_HEADER_POLISH.md      POD0.8_FOUNDATION_SIGNOFF.md
POD0.2_AURYN_EXTRACT.md     POD0.6_DRIVERS_DATA.md       POD0_ORIGINAL_MONOLITH.md
POD0.2.5_RECON_PASS.md      POD0.3_CLEANUP.md            README.md
```

**Only Pod 0.x prompts are present.** Pods 1.0 through 1.4 have no prompt files in
prompts/. The architect's assessment is confirmed: "the handoff's claim that
'Pod 1.0 through Pod 1.4 prompts are present' is false by direct inspection."

Phase 2 commits this Pod 1.5 prompt to `prompts/POD1.5_INTEGER_WIDTH_64.md` per B10.
Pods 1.0–1.4 prompt files remain absent — that's a separate DEFERRED-eligible item
for archaeological reconstruction.

---

## What surprised me

**The toolchain identity.** The pod prompt — and multiple prior canon documents —
identify `tools/cbsc.cbs` as the Python toolchain for CBS compilation. It is not.
`tools/cbsc.cbs` is a Phase 8 relic that compiles to a different bytecode format
(23-byte header + opcodes 0x73/0x78/0x79/0x74) and has no relationship to the NASM
VM's opcode set. The actual compiler is `tools/atreyu_x86.py`, which emits bytecode
matching `boot/defines.asm`. This has been hiding in plain sight — the build script
calls `precompile_all.sh` which calls `atreyu_x86.py`, not `cbsc.cbs`.

This means D3 ("Python toolchain update is mandatory and atomic with runtime format
changes") applies to `atreyu_x86.py`, not to `cbsc.cbs`. The practical impact is
small — atreyu_x86.py is a simpler, more contained change (~5 lines) — but the
canon's identification of the wrong toolchain is a factual error that should be
corrected.

**The surface .cbc files are dead code.** The compiler wraps all code inside function
bodies, then JMP-jumps over them to OP_HALT. The atreyu/bastian/rockbiter .cbc files
execute as: JMP → HALT. No surface code runs. This isn't new — it predates this pod
— but it means regenerating these files is trivially safe: the before and after
behavior is identical (nothing).

**The toolchain has no parser.** `atreyu_x86.py` can only compile from a hardcoded
Python dict AST. It cannot parse .cbs files. `precompile_all.sh` fails every build,
and `build.sh` falls back to using existing .cbc files. For Pod 1.5, this means
demo.cbc can be recompiled (atreyu_x86.py's `demo_full()` AST), but the surface
.cbc files must be hand-patched: expand every 4-byte operand after OP_PUSH (0x01)
and OP_RESERVE (0x20) to 8 bytes (zero-extend since all values are small positive
integers).

---

## Proposed Phase 2 plan

Pending R7's toolchain finding and the architect's decision on how to handle it.

**Option A (minimal, recommended):** Update `atreyu_x86.py` to emit 8-byte value
operands (add `emit_i64`, change ~7 emission sites). Recompile `demo.cbc` from the
hardcoded AST. Hand-patch the 3 surface .cbc files by expanding dd→dq at each
OP_PUSH/OP_RESERVE operand. Widen all cbs_vm.asm handlers per R1. Widen print_dec/
print_sdec per R1. Widen dec_buf. Widen vm_vars to dq. Widen all data.asm programs
(dd→dq for value operands). Fix OP_JIF/OP_JBACK movsxd drift per R3. Split
skip_to_end scanner into skip8 (PUSH, RESERVE) and skip4 (others). Update
DEFERRED.md #12 to mark resolved. Build, hash, commit atomically.

**Option B (full):** Same as A, but also write a minimal .cbs parser for
atreyu_x86.py so surface .cbc files can be compiled from source. Higher risk,
larger scope, questionable value given the surfaces are dead code.

**Recommendation:** Option A. The parser is a separate concern (and the surfaces
are dead code regardless). D3 is satisfied by updating atreyu_x86.py atomically
with the runtime changes.

---

## Architect questions

1. **LOAD/STORE operand category:** Variable indices (OP_LOAD/OP_STORE operands)
   are currently 4-byte. They index into a 64-slot array. D1 says "CBS values widen;
   positional offsets stay 4-byte." Variable indices are neither values nor jump offsets
   — they're array indices. I've categorized them as positional (stay 4-byte). Confirm?

2. **D3 target correction:** D3 references "Python toolchain (tools/cbsc.cbs)."
   The actual toolchain is `tools/atreyu_x86.py`. Should Phase 2 update RECONSTITUTION.md
   and DEFERRED.md to reference the correct file, or is that a separate canon cleanup?

3. **Energy register width:** r14 (energy budget) and r15 (energy used) are currently
   32-bit (r14d/r15d). OP_RESERVE's operand widens to 8 bytes, which forces these to
   widen (can't `cmp r14d, rax` — operand size mismatch). I've included them in the
   widening plan. The energy budget passed to cbs_run (r14d = 10000 in gmork_cmds.asm:413)
   must also widen. Confirm this is expected?

4. **Surface .cbc hand-patching vs. regeneration:** Given R7's finding that the surface
   .cbc files are effectively dead code (JMP → HALT), is hand-patching acceptable, or
   does the architect prefer regeneration from manually-constructed ASTs? Hand-patching
   is mechanical but error-prone; AST construction is more work but produces verifiable
   output.
