# Pod 1.4 — Decision Record

## Canon-Only Pod: RECONSTITUTION v4 → v5

**Pod type:** Canon-only (no source changes, binary contract preserved)
**Binary contract:** `fedcd682031e8cab36dcd8a9a519cb47ffea34c047c80d2d4db20f561196dc28`
**Companion to:** RECONSTITUTION.md v5, RECON_PROTOCOL.md, DEFERRED.md

---

## Decisions Canonized

### D1 — CBS value width vs. positional offset width

**Decision:** CBS values (operand stack entries, `OP_PUSH` data operands)
widen to 8 bytes. Positional offsets (jump targets in `OP_JMP`/`OP_JZ`/
`OP_JNZ`, call offsets in `OP_CALL`) remain 4-byte signed.

**Rationale:** Values must be 64-bit to hold pointers, capability IDs,
and energy budgets without truncation. Positional offsets encode
distances within a bytecode stream — ±2 GB reach is more than
sufficient for any CBS program and avoids bloating every branch
instruction from 5 bytes to 9 bytes. The two categories serve
different purposes and deserve different widths.

**Impact:** `OP_PUSH` grows from 5 bytes (1 opcode + 4 data) to 9 bytes
(1 opcode + 8 data). `OP_JMP`/`OP_JZ`/`OP_JNZ`/`OP_CALL` remain at
5 bytes (1 opcode + 4 offset). The Python toolchain must emit the
correct width per opcode class.

### D2 — Sign-extension default on widening

**Decision:** `movsxd` (sign-extending move) is the default when
widening a 4-byte operand to 64-bit register width.

**Rationale:** Jump offsets are signed (backward jumps are negative).
Zero-extension would break backward branches. Sign-extension is
correct for both positive and negative values. This matches the
existing `OP_CALL` implementation from Pod 1.3, which already uses
`movsxd rax, dword [r13]`.

**Impact:** All fetch paths that read 4-byte operands and load them
into 64-bit registers must use `movsxd`, not `mov eax, [...]`
(which implicitly zero-extends in x86_64).

### D3 — Python toolchain coupling

**Decision:** The Python toolchain update (`tools/cbsc.cbs`) is
mandatory and atomic with the runtime format change. No pod ships
a widened runtime without a toolchain that emits the matching format.

**Rationale:** A format mismatch between compiler output and VM
expectations produces silent corruption — the VM reads 8 bytes where
the compiler wrote 4, or vice versa. This is not a "fix later" item;
it is a ship-blocker for the width migration pod.

**Impact:** Pod 1.5 (width migration) includes both the NASM runtime
changes and the Python toolchain changes in a single atomic commit.
DEFERRED #12 (surface .cbc recompilation) is part of the same gate.

---

## Retroactive Changes Documented (Pod 1.3)

Pod 1.3 was the first source pod under the recon protocol. v5
retroactively canonizes implementation details that v4 described
only as future work:

- **OP_CALL PC-relative addressing:** Changed from broken absolute
  (`mov r12, rax`) to PC-relative (`movsxd rax, dword [r13]; add r12, rax`).
  Absolute addressing was fundamentally broken under UEFI relocation.
- **OP_HALT pre-existed:** `OP_HALT` (0xFF) was already defined and
  handled in the VM. Pod 1.3 required no new opcode — only rewiring
  `OP_RET` from VM-exit to subroutine-return.
- **vm_ret_ptr prologue reset:** Added `mov qword [rel vm_ret_ptr], 0`
  to `cbs_run` prologue. Without this, stale return-stack state from
  a previous invocation could cause incorrect behavior.
- **.cbc surface patching:** `atreyu.cbc` (offset 643), `bastian.cbc`
  (offset 187), `rockbiter.cbc` (offset 236) — byte at (filesize - 2)
  changed from 0x53 (OP_RET) to 0xFF (OP_HALT). The trailing 0xFF is
  real bytecode, not file padding.
- **.done shared exit path:** `OP_HALT`, energy exhaustion, and all
  violation handlers converge on the `.done` label in `cbs_vm.asm`.
- **.skip_to_end cleanup:** Removed `OP_RET` from the reserve-fail
  skip scanner — only `OP_HALT` terminates the scan now.
- **prog8 call/ret test:** Added test program exercising
  `OP_CALL`/`OP_RET` with PC-relative offset calculation.

---

## Protocol Addition

**PAUSED-MID-EXECUTION** added as a fourth architect response state
in RECON_PROTOCOL.md. This state records partial Phase 2 execution
when context limits are reached, enabling disciplined resumption
without re-running Phase 1 or re-requesting authorization.

---

## Pod Arc Slide

Pod 1.4 (this canon update) inserted after Pod 1.3, sliding all
subsequent sub-pods by one. Pod 1 now spans thirteen sub-pods
(1.0 through 1.12). All cross-references in RECONSTITUTION.md,
DEFERRED.md, and RECON_PROTOCOL.md updated to reflect the new
numbering.

| Old | New | Description |
|-----|-----|-------------|
| 1.4 | 1.5 | 64-bit integer width migration |
| 1.5 | 1.6 | Sign as native type |
| 1.6 | 1.7 | Energy: per-opcode cost table |
| 1.7 | 1.8 | Outcome<T>: typed errors |
| 1.8 | 1.9 | Cap<R> data structures |
| 1.9 | 1.10 | Cap ops retirement |
| 1.10 | 1.11 | Demod<S> registration |
| 1.11 | 1.12 | Pod 1 cleanup + sign-off |

---

## Binary Contracts Schema Cleanup

Dropped the `Commit` column from `binary_contracts.md`. The column
created a chicken-and-egg cycle: recording the commit hash changed
the file, which changed the commit hash. Pod number + sha256 is
sufficient for contract tracking. The commit can always be recovered
via `git log --all -- binary_contracts.md`.
