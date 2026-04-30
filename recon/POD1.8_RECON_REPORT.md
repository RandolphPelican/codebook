# Pod 1.8 Recon Report — Energy as Native Type

**Pod:** 1.8 — Energy as native type (per-opcode cost table + DEFERRED #15)
**Author:** Terminal Boy (Claude)
**Date:** April 29, 2026
**Entry contract:** 975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc
**Scope:** boot/, tools/, surfaces/, recon/ (most recent five), repo root markdown

---

## Section 1 — Sweep Findings

### R1 — Entry contract verification

Pod 1.7 row in binary_contracts.md confirmed:
`975a7f809c350d09b2031b9f5490261986d878d5a04e66709f97fae7083b05dc`
Verbatim pasted to chat.

### R2 — Hardcoded energy constants inventory

Six sites identified in boot/cbs_vm.asm:

| Line | Context | Current cost | Mechanism |
|------|---------|-------------|-----------|
| 53–54 | `.fetch` loop (every opcode) | 1 (flat) | `dec r14` + `inc [energy_used]` |
| 730–733 | `.op_sign_new` handler | 100 | `cmp r14,100` / `sub r14,100` / `add [energy_used],100` |
| 790–793 | `.op_sign_hash` handler | 5 | `cmp r14,5` / `sub r14,5` / `add [energy_used],5` |
| 828–831 | `.op_sign_label` handler | 5 | `cmp r14,5` / `sub r14,5` / `add [energy_used],5` |
| 860–863 | `.op_sign_energy` handler | 5 | `cmp r14,5` / `sub r14,5` / `add [energy_used],5` |

Note: Each Sign handler does THREE things — bankruptcy check (`cmp r14, N` / `jl .fatigue`),
r14 debit (`sub r14, N`), and energy_used increment (`add [energy_used], N`). All three must be
removed per B4b when the fetch-loop cost-table debit replaces them.

Additionally: OP_RESERVE at line 295–296 does `sub r14, rax` / `add r15, rax`. The `sub r14`
is correct (explicit energy reservation). The `add r15, rax` writes to r15, which per A4 is
freed — this line becomes dead code after the DEFERRED #15 fix. See Section 2 Surprise S2.

### R3 — Opcode range verification

`grep -nE "0x[Dd][0-9A-Fa-f]" boot/defines.asm` returned no output.
**0xD0–0xDF is completely unallocated.** Clean for Energy opcodes.

### R4 — DEFERRED #15 ground truth

Lines 147–156 of DEFERRED.md confirmed verbatim. `.done` block at lines 910–927
confirmed: `mov rdi, r15` is the bug, `[rel energy_used]` is the fix per A4.

### R5 — Symbol collision check

No `vm_energy_pool`, `vm_energy_next`, or `energy_cost_*` symbols exist in
boot/vmdata.asm, boot/defines.asm, or boot/cbs_vm.asm. Four grep hits are Sign
field comments (`energy_cost` in cbs_vm.asm), not symbol definitions.

### R6 — Test infrastructure pattern

`tools/atreyu_x86.py` lines 232–256 (`demo_sign()`) and 272–284 (`--sign-build`
/ `--sign-test`) provide the pattern. Pod 1.8 mirrors with `demo_energy()` +
`--energy-build` / `--energy-test`.

The compiler also needs Energy opcode constants added to the opcode table
(lines 8–45) and expression type handlers in `_expr()` for `energy_new`,
`energy_joules`, `energy_source_op`.

### R7 — Standard sweeps A–G

**Sweep A (file inventory):** 55 files in scope. No unexpected files.

**Sweep B (symbol inventory):** All symbols in boot/*.asm accounted for.
`cbs_run` is the only exported symbol from cbs_vm.asm. vmdata.asm exports
energy_budget, energy_used, vm_ret_ptr, vm_ret_stack, vm_stack, vm_vars,
vm_sign_pool, vm_sign_next, mmap_buf. All expected.

**Sweep C (cross-module dependencies):** cbs_vm.asm calls auryn_puts, print_dec,
print_hex32, morla_run_file_main. These are defined in auryn.asm, gmork.asm,
morla.asm respectively. All in the %include chain in boot.asm. No unexpected
cross-module calls.

**Sweep D (directories):** .claude, boot, drivers, drivers/_future, kernel,
kernel/_future, recon, surfaces, tools. All known. No surprises.

**Sweep E (git history):** Last source-touching commit in scope is 1d8593f
(Pod 1.7). History is clean.

**Sweep F (documentation):** 8 markdown files in repo root. All accounted for:
ARCHAEOLOGY, ARCHAEOLOGY_REPO_RECORD, DEFERRED, README, RECONSTITUTION,
RECON_PROTOCOL, ROADMAP, binary_contracts. No stray docs.

**Sweep G (cemeteries):** drivers/_future and kernel/_future. Both known,
documented in RECONSTITUTION v7. No new cemetery directories.

### R8 — Forward-logged items audit

Pod 1.7 Decision Record "Forward-looking ledger" (lines 154–165) logged four
items for Pod 1.8:

1. D1.7.6 — Replace placeholder energy costs → covered by A2 (cost table)
2. D1.7.8 — Fix r15 display bug → covered by A4
3. Per-opcode cost table → covered by A2 + B1 + B4a
4. Energy typed primitive → covered by A1 + A3 + B4c

All four items are directly resolved by Pod 1.8's scope. No orphaned forwards.

### R9 — QEMU sendkey methodology check

**ABSENT from recon/POD1.7_RECON_REPORT.md.** The report references
`test_qemu.sh` at line 382 as an existing file but does not document the
working named-pipe + sendkey + screendump + PIL methodology actually used
in Pod 1.7's bare-metal test.

Screenshot artifacts proving the methodology was used:
- build/sign_test_final.png (7194 bytes, Apr 29 06:12)
- build/sign_test_result.png (5306 bytes, Apr 29 06:10)
- build/sign_test_screen.png (6837 bytes, Apr 29 06:09)
- build/gmork_prompt.png (4799 bytes, Apr 29 06:10)

Pod 1.8 captures the methodology as recon/POD1.8_QEMU_AUTOMATION.md before B7.

---

## Section 2 — Surprises

### S1 — QEMU automation methodology undocumented

**What:** The working sendkey + screendump + PIL pipeline used in Pod 1.7's
bare-metal test was not captured in the recon report or any other doc.
**Where:** Absent from recon/POD1.7_RECON_REPORT.md; evidenced by screenshot
artifacts in build/.
**Possible significance:** Pod 1.8 (B7) needs this methodology. Without a doc,
the technique must be reconstructed from Pod 1.7 chat history or the existing
test_qemu.sh. Pod 1.8 captures it as recon/POD1.8_QEMU_AUTOMATION.md before B7.

### S2 — OP_RESERVE writes to r15 (dead code after A4 fix)

**What:** OP_RESERVE handler at cbs_vm.asm line 296 does `add r15, rax` after
`sub r14, rax`. After the A4 fix (r15 display replaced with [rel energy_used]),
this `add r15, rax` becomes dead code — its output is never consumed.
**Where:** boot/cbs_vm.asm line 296.
**Possible significance:** The line should be removed as part of B4d (A4
implementation). The `sub r14, rax` at line 295 is correct and must remain —
OP_RESERVE genuinely debits energy from r14. Only the r15 accumulation is dead.

### S3 — boot.asm %include chain needs energy_costs.asm insertion

**What:** boot.asm assembles via a %include chain (lines 366–376). The new
boot/energy_costs.asm module must be added to this chain.
**Where:** boot/boot.asm lines 366–376.
**Possible significance:** energy_cost_lookup is called from cbs_vm.asm's fetch
loop. The %include must appear before cbs_vm.asm (line 369) or after it —
NASM resolves forward references, so order doesn't strictly matter for label
resolution. Recommended: insert `%include "boot/energy_costs.asm"` between
vmdata.asm (line 376) and data.asm (line 375), since it's data-heavy. Or
immediately before cbs_vm.asm at line 369 since cbs_vm.asm is the consumer.
Architect ratifies placement.

### S4 — Sign handler energy checks: THREE lines each, not one

**What:** The R2 inventory shows each Sign handler has THREE energy-related
lines (cmp, sub, add), not just the `add qword [rel energy_used]` line. B4b
must remove all three per handler (12 lines total across 4 Sign handlers),
plus the two lines in the fetch loop (dec r14 + inc [energy_used]).
**Where:** cbs_vm.asm lines 730–733, 790–793, 828–831, 860–863.
**Possible significance:** If only the `add` lines are removed but the `cmp`
and `sub` remain, energy gets double-debited (once in handler, once in fetch
loop). B4b must remove all handler-side energy lines. The fetch-loop cost-table
debit at B4a is the single source of energy deduction for all opcodes.

---

## Section 3 — Architect Questions

### AQ1 — Opcode byte granularity within 0xD0–0xDF

**Pre-ratified default:** 4 opcodes (0xD0–0xD3).

Recon surfaces no reason to add more accessors for V1.0. Energy has two
fields (joules, source_op); two accessors suffice. Typed-equality and
accumulator semantics are V1.1+ concerns per A7.

**0xD3 (OP_ENERGY_FREE) allocation question:** The prompt pre-ratifies 0xD3 as
a V1.0 no-op that "sets symmetry precedent for future typed-primitives'
allocator pairs." An alternative is to defer 0xD3 allocation entirely to V1.1
and keep the V1.0 set at 3 opcodes (0xD0–0xD2). The symmetry argument favors
allocation now; the minimalism argument favors deferral.

**TB recommendation:** Allocate 0xD3 now per the prompt's pre-ratified default.
The no-op implementation is 5 lines of assembly (pop slot pointer, jmp .fetch).
The symmetry with Sign (4 opcodes: NEW + 3 accessors) is clean. Cost: one byte
of opcode space consumed. Benefit: future typed primitives (Outcome, Cap, Demod)
inherit the pattern with a FREE slot.

**Options:**
1. Allocate 0xD0–0xD3 (4 opcodes, pre-ratified default)
2. Allocate 0xD0–0xD2 only (3 opcodes, defer FREE to V1.1)

### AQ2 — Initial cost values for 256-entry table

Conservative table preserving current observable behavior. All values in joules.

| Opcode byte | Name | Proposed cost | Rationale |
|-------------|------|--------------|-----------|
| 0x00 | (unused) | 0 | never dispatched |
| 0x01 | OP_PUSH | 1 | data load, cheap |
| 0x02 | OP_PUSH_STR | 1 | data load, cheap |
| 0x10 | OP_ADD | 1 | arithmetic, baseline |
| 0x11 | OP_SUB | 1 | arithmetic, baseline |
| 0x12 | OP_MUL | 2 | multiplication > addition |
| 0x13 | OP_DIV | 3 | division > multiplication |
| 0x14–0x19 | OP_EQ..OP_GE | 1 | comparison, baseline |
| 0x1A | OP_MOD | 3 | modulo = division cost |
| 0x20 | OP_RESERVE | 0 | explicit energy reservation, not consumption |
| 0x40 | OP_JMP | 1 | control flow, baseline |
| 0x50 | OP_CALL | 2 | subroutine overhead |
| 0x53 | OP_RET | 1 | return, baseline |
| 0x55 | OP_JIF | 1 | conditional jump, baseline |
| 0x56 | OP_JBACK | 1 | jump back, baseline |
| 0x70 | OP_LOAD | 1 | variable access, baseline |
| 0x71 | OP_STORE | 1 | variable write, baseline |
| 0x80 | OP_PRINT_NUM | 2 | I/O |
| 0x81 | OP_EMIT | 2 | I/O |
| 0x82 | OP_NEWLINE | 1 | I/O, trivial |
| 0x83 | OP_DUP | 1 | stack manipulation, baseline |
| 0x84 | OP_DROP | 1 | stack manipulation, baseline |
| 0x85 | OP_SWAP | 1 | stack manipulation, baseline |
| 0x86 | OP_PRINT_STR | 3 | I/O, string processing |
| 0x87 | OP_DUP2 | 1 | stack manipulation (orphaned, still defined) |
| 0x90 | OP_GRANT_CAP | 5 | capability operation |
| 0x91 | OP_USE_CAP | 5 | capability operation |
| 0xA0 | OP_SIGN_NEW | 100 | preserves Pod 1.7 D1.7.6 value |
| 0xA1 | OP_SIGN_HASH | 5 | preserves Pod 1.7 D1.7.6 value |
| 0xA2 | OP_SIGN_LABEL | 5 | preserves Pod 1.7 D1.7.6 value |
| 0xA3 | OP_SIGN_ENERGY | 5 | preserves Pod 1.7 D1.7.6 value |
| 0xD0 | OP_ENERGY_NEW | 10 | typed primitive construction, lighter than Sign |
| 0xD1 | OP_ENERGY_JOULES | 1 | accessor, cheap |
| 0xD2 | OP_ENERGY_SOURCE_OP | 1 | accessor, cheap |
| 0xD3 | OP_ENERGY_FREE | 0 | V1.0 no-op |
| 0xFF | OP_HALT | 0 | termination, free |
| all others | (unallocated) | 1 | default per A2 |

**Design notes:**
- OP_RESERVE cost = 0: it debits r14 by its own operand (explicit reservation).
  The cost table should not double-charge for the reservation itself.
- Sign opcode costs match D1.7.6 exactly, preserving Pod 1.7 observable behavior.
- Energy accessor costs are 1j (baseline), lower than Sign's 5j — Energy has
  fewer fields and simpler access patterns.
- OP_ENERGY_NEW = 10j: lighter than OP_SIGN_NEW (100j) because Energy is a
  simpler struct (2 fields vs 5).
- OP_MUL/OP_DIV/OP_MOD slightly elevated to reflect computational cost.
- I/O ops (PRINT_NUM, EMIT, PRINT_STR) slightly elevated to reflect side effects.

**Important behavioral change:** The current fetch loop charges 1j per fetch PLUS
handler-side costs. The new model charges ONLY the cost-table value per opcode.
This means observable energy consumption changes:
- OP_SIGN_NEW was 1 (fetch) + 100 (handler) = 101j total. Now 100j.
- OP_SIGN_HASH was 1 + 5 = 6j. Now 5j.
- Simple opcodes (ADD, SUB, etc.) were 1j total. Stay 1j.

### AQ3 — Test program AST for surfaces/test_energy.cbc

Proposed `demo_energy()` AST:

```python
def demo_energy():
    """Pod 1.8 Energy typed primitive test — hardcoded AST demo"""
    return {'type':'program','body':[
        {'type':'print','value':{'type':'str','value':'=== Energy Test (Pod 1.8) ==='}},
        # Create an Energy: joules=500, source_op=0xA0 (OP_SIGN_NEW)
        {'type':'let','name':'e','value':{
            'type':'energy_new',
            'joules': 500,
            'source_op': 0xA0,
        }},
        # Print energy_id (expect: 1)
        {'type':'print','value':{'type':'str','value':'energy_id:'}},
        {'type':'print','value':{'type':'var','name':'e'}},
        # Read back joules (expect: 500)
        {'type':'print','value':{'type':'str','value':'joules:'}},
        {'type':'print','value':{'type':'energy_joules','operand':{'type':'var','name':'e'}}},
        # Read back source_op (expect: 160 = 0xA0)
        {'type':'print','value':{'type':'str','value':'source_op:'}},
        {'type':'print','value':{'type':'energy_source_op','operand':{'type':'var','name':'e'}}},
        {'type':'print','value':{'type':'str','value':'=== Energy test complete ==='}},
    ]}
```

Test values: joules=500, source_op=0xA0 (160 decimal). Expected QEMU output:
```
=== Energy Test (Pod 1.8) ===
energy_id:
1
joules:
500
source_op:
160
=== Energy test complete ===
```

Energy remaining after test (approximate): 100000 - (sum of per-opcode costs
for ~20 opcodes in test program) ≈ 99900–99950 depending on final cost table.

### AQ4 — boot.asm %include placement for energy_costs.asm

**Where in the %include chain should boot/energy_costs.asm be inserted?**

Current chain (boot.asm lines 366–376):
```nasm
%include "boot/auryn.asm"
%include "boot/morla.asm"
%include "boot/gmork.asm"
%include "boot/cbs_vm.asm"
%include "boot/bastian.asm"
%include "boot/gmork_cmds.asm"
%include "drivers/kbd_ps2.asm"
%include "drivers/ide_pio.asm"
%include "drivers/fat32.asm"
%include "boot/data.asm"
%include "boot/vmdata.asm"
```

**Options:**
1. Before cbs_vm.asm (line 369): `%include "boot/energy_costs.asm"` — logical
   since cbs_vm.asm is the consumer. Keeps cost table near its caller.
2. After vmdata.asm (line 376, at end): data-heavy module grouped with data.
3. Between data.asm and vmdata.asm: grouped with other data modules.

**TB recommendation:** Option 1 — before cbs_vm.asm. The energy_cost_lookup
function is code, not just data; placing it near the call site follows the
existing pattern (gmork.asm string utils before gmork_cmds.asm, auryn.asm
before morla.asm). NASM resolves forward references so order doesn't matter
for correctness, but proximity aids readability.

### AQ5 — OP_RESERVE r15 dead code cleanup

**Should `add r15, rax` at cbs_vm.asm line 296 be removed as part of B4d?**

A4 says "r15 is freed for general handler use." OP_RESERVE is the only handler
that writes to r15. After the display fix, this write is dead — nothing reads
r15. Removing it is consistent with A4. Leaving it is harmless but misleading
(implies r15 has semantics).

**TB recommendation:** Remove line 296 (`add r15, rax`) as part of B4d. Add a
comment: `; r15 freed (Pod 1.8 A4); energy tracking via [rel energy_used]`.

---

## Section 4 — Proposed Phase 2 Plan

### Files to create:
1. `boot/energy_costs.asm` — cost table (256×8 bytes) + energy_cost_lookup (B1)
2. `surfaces/test_energy.cbc` — compiled energy test bytecode (B5 output)
3. `recon/POD1.8_QEMU_AUTOMATION.md` — QEMU sendkey methodology capture (R9 gap)
4. `recon/POD1.8_DECISION_RECORD.md` — decision record (B10c)

### Files to modify:
5. `boot/defines.asm` — add OP_ENERGY_* defines + struct offsets (B2)
6. `boot/vmdata.asm` — add vm_energy_pool + vm_energy_next (B3)
7. `boot/cbs_vm.asm` — B4a (fetch-loop), B4b (handler removal), B4c (handlers), B4d (display fix)
8. `boot/boot.asm` — add %include for energy_costs.asm (per AQ4 ratification)
9. `tools/atreyu_x86.py` — add Energy opcodes + demo_energy() + CLI flags (B5)
10. `RECONSTITUTION.md` — v7→v8 (B10b)
11. `DEFERRED.md` — strikethrough #15 (B10e)
12. `binary_contracts.md` — append Pod 1.8 row (B10d)

### Execution order:
B1 → B2 → B3 → B4 → B5 → B6 (build) → B7 (QEMU test) → HALT 2A → B6/B7
verbatim → HALT 2B → B10 (canon) → HALT 2C → B11 (commit+push) → B12 → B13

### Risk assessment:
- **Highest risk:** B4b (handler-side cost removal). 12+ lines across 4 handlers
  plus the fetch loop. Double-debit or missed-debit is the primary failure mode.
- **Medium risk:** B4a (fetch-loop integration). The bankruptcy check semantics
  must be preserved — the cost-table value can exceed r14, and the check must
  trigger .fatigue before the debit, not after.
- **Low risk:** Everything else follows established patterns from Pod 1.7.
