# Pod 1.5 — Integer Width Migration to 64-bit

## Phase 1: Recon (R1-R12)

- R1: Verify entry contract hash
- R2: Read cbs_vm.asm opcode handlers for current integer widths
- R3: Read data.asm inline programs for operand widths (dd vs dq)
- R4: Read vmdata.asm for vm_vars, vm_stack slot sizes
- R5: Read gmork_cmds.asm for energy budget width
- R6: Read gmork.asm for print_dec/print_sdec register widths
- R7: Read toolchain (tools/atreyu_x86.py) for emission widths
- R8: Read .cbc files for binary format analysis
- R9: Read defines.asm for opcode constants
- R10: Read DEFERRED.md for related items
- R11: Read RECONSTITUTION.md for D1/D2/D3 decisions
- R12: Check skip_to_end scanner for operand-size assumptions

## Phase 2: Build (B1-B14)

### Locked Architecture (from Pod 1.4 canon)

- **D1:** CBS values widen to 8 bytes (dq/i64). Positional offsets (JMP/JIF/JBACK/LOAD/STORE) stay 4-byte signed.
- **D2:** Sign-extension via movsxd at widening boundaries (positional i32 read into 64-bit register).
- **D3:** Python toolchain (tools/atreyu_x86.py) update is atomic with runtime format change.

### Build Steps

- B1: Widen cbs_vm.asm — all value-handling opcodes from eax/ebx to rax/rbx
- B2: Widen OP_PUSH operand fetch from 4-byte to 8-byte
- B3: Widen OP_RESERVE operand fetch and energy registers to 64-bit
- B4: Apply movsxd for positional operands (JIF, JBACK, JMP, LOAD, STORE)
- B5: Widen vm_vars from dd to dq; update LOAD/STORE index arithmetic (*4 to *8)
- B6: Widen data.asm inline programs (dd to dq for PUSH/RESERVE operands)
- B6 augmented: Regenerate demo.cbc; hand-patch surface .cbc files
- B7: Widen gmork.asm print_dec/print_sdec to 64-bit; widen dec_buf
- B8: Build and hash: `nasm -f bin -o build/BOOTX64.EFI boot/boot.asm && sha256sum build/BOOTX64.EFI`
- B9: Append new hash to binary_contracts.md
- B10: Commit prompt file to prompts/
- B11: Update DEFERRED.md — mark #12 resolved, correct toolchain reference
- B12: Stage, commit, push — atomic commit
- B13: Verification report with verbatim command output
- B14: Canon correction — fix toolchain references from cbsc.cbs to atreyu_x86.py

### Critical Findings from Recon

- Actual toolchain is `tools/atreyu_x86.py`, not `tools/cbsc.cbs` (Phase 8 detritus)
- OP_CALL reads full qword from stack (not movsxd — stack values are already 64-bit)
- skip_to_end scanner split: .skip8 (PUSH, RESERVE) and .skip4 (JIF, JBACK, JMP, LOAD, STORE)
- Surface .cbc files are dead code (JMP over function bodies to HALT)
- NASM label arithmetic auto-adjusts when operand sizes change
