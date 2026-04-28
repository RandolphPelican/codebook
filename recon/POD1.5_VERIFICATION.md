# Pod 1.5 Verification Report — Integer Width Migration to 64-bit

## Entry Contract

```
Entry contract (Pod 1.3 hash): fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28
```

## Build Output

```
$ nasm -f bin -o build/BOOTX64.EFI boot/boot.asm
drivers/ide_pio.asm:86: warning: implicit DEFAULT ABS is deprecated [-w+implicit-abs-deprecated]
drivers/ide_pio.asm:161: warning: unsigned byte exceeds bounds [-w+number-overflow]
drivers/ide_pio.asm:230: warning: unsigned byte exceeds bounds [-w+number-overflow]
drivers/ide_pio.asm:288: warning: unsigned byte exceeds bounds [-w+number-overflow]
```

Warnings: pre-existing (ide_pio.asm), unchanged from Pod 1.3. No new warnings.

## Exit Contract

```
$ sha256sum build/BOOTX64.EFI
32d404ed779fbc3ea9a06d44c0f3e7b801b8a04db7f67d9e549a12964344c0c6 *build/BOOTX64.EFI

$ wc -c build/BOOTX64.EFI
1049600 build/BOOTX64.EFI
```

Rebuild determinism verified: two consecutive builds produce identical hash.

## Toolchain Test

```
$ python tools/atreyu_x86.py --test
Demo: 457 bytes, vars: {'x': 0, 'y': 1, 'a': 2, 'b': 3, 'n': 4, 't': 5}
  0000: 40 00 00 00 00 02 19 00 3D 3D 3D 20 43 6F 64 65
  0010: 62 6F 6F 6B 53 63 72 69 70 74 20 56 4D 20 3D 3D
  0020: 3D 00 00 00 86 82 02 1C 00 52 75 6E 6E 69 6E 67
  0030: 20 6F 6E 20 62 61 72 65 20 6D 65 74 61 6C 20 78
First: 0x40 Last: 0xFF
```

Demo grew from 425 bytes (32-bit) to 457 bytes (64-bit). Delta = 32 bytes = 8 OP_PUSH
values widened from 4 to 8 bytes each (8 x 4 extra bytes = 32).

## .cbc File Widening

```
demo.cbc:      425 -> 457 bytes (+32)  — regenerated via atreyu_x86.py --build
atreyu.cbc:    645 -> 777 bytes (+132) — hand-patched (33 value ops x 4 = 132)
bastian.cbc:   189 -> 197 bytes (+8)   — hand-patched (2 value ops x 4 = 8)
rockbiter.cbc: 238 -> 258 bytes (+20)  — hand-patched (5 value ops x 4 = 20)
```

All .cbc files verified: first byte = 0x40 (OP_JMP), last byte = 0xFF (OP_HALT).
JMP target offsets recalculated to account for widened operands.

## Widening Site Summary

### boot/cbs_vm.asm (~55 sites)
- `.fetch`: energy test/dec widened to 64-bit (r14/r15)
- `.op_push`: 4-byte fetch -> 8-byte fetch; add r12, 4 -> add r12, 8
- `.op_reserve`: 8-byte operand fetch; r14/r15 64-bit throughout
- All arithmetic ops: eax/ebx -> rax/rbx
- `.op_mul`: imul eax,ebx -> imul rax,rbx
- `.op_div`: cdq;idiv ebx -> cqo;idiv rbx
- `.op_mod`: xor edx,edx;div ebx -> xor rdx,rdx;div rbx
- `.op_jif/.op_jback`: movsxd rax, dword [r12] (D2 sign-extension)
- `.op_load/.op_store`: movsxd for index; *4 -> *8 for var array
- `.op_call`: mov rax, [r13] (full qword from stack, not movsxd)
- `.op_print_num/.done`: edi -> rdi for 64-bit print_dec
- `.op_dup/.op_swap`: eax/ebx -> rax/rbx
- `.conin_none`: mov dword -> mov qword
- `.skip_to_end`: split into .skip8 (PUSH, RESERVE) and .skip4 (JIF, JBACK, JMP, LOAD, STORE)

### boot/gmork.asm
- `print_dec`: widened to full 64-bit division loop (rax/rdx/rcx)
- `print_sdec`: test rdi,rdi; neg rdi (64-bit sign handling)

### boot/data.asm
- `dec_buf`: 12 -> 22 bytes (64-bit numbers need up to 20 digits + sign + null)
- Programs 1-4, 8: all OP_PUSH `dd` -> `dq`; all OP_RESERVE `dd` -> `dq`
- Programs 5-7 (surface stubs): OP_RESERVE `dd` -> `dq` (already done earlier in Phase 2)
- Positional operands (STORE, LOAD, JIF, JBACK indices/offsets): remain `dd`
- NASM label arithmetic auto-adjusts for widened operand sizes

### boot/vmdata.asm
- `vm_vars`: times 64 dd 0 -> times 64 dq 0 (256 -> 512 bytes)

### boot/gmork_cmds.asm
- `.run_go`: mov r14d, 10000 -> mov r14, 10000

### tools/atreyu_x86.py
- Added `emit_i64` method to Emitter class
- `_func` OP_RESERVE cost: emit_i32 -> emit_i64
- `_func` return push: emit_i32(0) -> emit_i64(0)
- `_expr` int/bool/neg/not literals: emit_i32 -> emit_i64
- Positional emissions (JMP, JIF, STORE, LOAD) unchanged at emit_i32

## Canon Corrections (B14)

- RECONSTITUTION.md line 203: `tools/cbsc.cbs` -> `tools/atreyu_x86.py`
- RECONSTITUTION.md line 225: added "(Phase 8 detritus)" annotation
- DEFERRED.md #7: corrected toolchain reference, noted cbsc.cbs is Phase 8 detritus
- DEFERRED.md #12: marked RESOLVED
- recon/POD1.4_DECISION_RECORD.md D3: `tools/cbsc.cbs` -> `tools/atreyu_x86.py`

## D1/D2/D3 Compliance

- **D1 (value width):** All CBS values are 8 bytes (dq/i64). Positional offsets remain 4-byte signed. COMPLIANT.
- **D2 (sign extension):** movsxd used at all widening boundaries (JIF, JBACK, JMP, LOAD, STORE). COMPLIANT.
- **D3 (atomic toolchain):** atreyu_x86.py updated in same commit as runtime changes. COMPLIANT.
