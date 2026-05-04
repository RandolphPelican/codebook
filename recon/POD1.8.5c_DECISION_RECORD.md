# Pod 1.8.5c Decision Record — Conduits (Moves 1, 2, 3, 6, 7)

**Pod:** 1.8.5c — substrate-terraforming source pod (5 conduits)
**Author:** Terminal Boy (Claude Opus 4.7)
**Date:** May 03 2026
**Entry contract:** a6b8c0f16a148058a41c33601123a7eb7941473b9a828982378473fe46d84a75 (Pod 1.8.5b BOOTX64.EFI)
**Exit contract:** 03d2642998f41c4ce2080267b41033a78bdafafb96aded360396338f30fe8199
**Entry HEAD:** 7a82fc3befccb0a72351577e4d65807882ce6305 (Pod 1.8.5b.5 final commit)

---

## D1.8.5c.1 — A1(d) Sign slot reclamation (no expansion)

R1 surfaced that the 128-byte Sign slot was fully consumed: hash[32],
label[64], energy_cost, embedding_handle, provenance_handle, V1.1
sentinel. Move 3's required 16 new bytes (arena_id + owner_demod_id)
did not fit without slot expansion.

A1(a) would have expanded both slots to 144 bytes for symmetric
lockstep retrofit. A1(d) reclaims `provenance_handle` (+0x70) and the
V1.1 sentinel (+0x78) for `arena_id` and `owner_demod_id` respectively,
preserving the 128-byte slot size and the symmetric slot convention
across all typed primitives.

The reclamation is justified architecturally:
- `provenance_handle` was reserved for per-Sign provenance chains;
  Move 2's auto-provenance ring buffer (ProvEvent + prov_ring_buf)
  absorbs that role at the substrate level rather than per-binding.
- The V1.1 sentinel was a generic placeholder with no specific
  reservation.
- `embedding_handle` (+0x68) stays reserved — semantic embeddings are
  a Pod 3+ concern with no in-pod alternative routing.

**Why:** symmetric slot convention preserved permanently; zero binary
growth; Move 2 absorbs the per-Sign provenance role naturally.

## D1.8.5c.2 — A2 collapse: MODES enum-reserved-but-unwritten in V1.0

The V1.0 boot sequence has no structural distinction between "VM
ready" and "user interactive." MODES is enum-defined (= 3) but never
written by V1.0 boot code. vm_phase steps SEED → FORM → CHANNELS → MIND
with the CHANNELS → MIND transition happening at the bastian_home jmp.

**Why:** design-fiction phase advancements muddy the audit signal
vm_phase exists to provide. MODES becomes honest only when actual
mode-switching machinery exists (Pod 5 Surfaces). DEFERRED #28 captures
the refinement window.

## D1.8.5c.3 — A3: CHANNELS unconditional, regardless of NATIVE_KBD

`exit_boot_services` is wrapped in `%ifdef NATIVE_KBD`. If NATIVE_KBD
is undefined, EBS never fires — UEFI services stay live. The CHANNELS
phase write is placed *outside* the `%ifdef` block, so vm_phase
advances to CHANNELS regardless of EBS state.

**Why:** the phase model reflects "EBS-eligible boot done" rather than
literal EBS state. If a build configuration leaves UEFI services live,
the substrate is still semantically "in CHANNELS" — direct hardware is
ready, the boot phase has progressed past the EBS decision point. The
audit signal stays meaningful across build configurations.

## D1.8.5c.4 — A4: ProvEvent at 32 bytes, cache-aligned

ProvEvent layout: opcode (u8) + 7 bytes pad at +0x00; demod_id (u64)
at +0x08; fetch_counter (u64) at +0x10; reserved (u64) at +0x18.
Total 32 bytes, power-of-2 stride.

Ring buffer `prov_ring_buf` is 4KB / 32B = exactly 128 entries with
`PROV_RING_MASK = 0x7F` for one-instruction modulo (`and rax, MASK`).
Reserved 8 bytes future-proof against the "ProvEvent fields finalized
when first consumer lands" deferred entry (#25).

**Why:** cache-line-aligned struct + power-of-2 ring stride =
predictable performance characteristics for whatever prov_append
consumer Pod 2 (Cop) wires up. 24-byte minimum-pack would have given
170 entries with `imul`-required ring math — chose alignment over
density.

## D1.8.5c.5 — A5: boot/provenance.asm as new file

`prov_append` and the ProvEvent semantics live in a new file
`boot/provenance.asm` rather than inline in `boot/cbs_vm.asm`.
Inserted in `boot/boot.asm` between `boot/registry.asm` (Pod 1.8.5b)
and `boot/bastian.asm`, matching the precedent set by
`boot/registry.asm`'s introduction.

**Why:** provenance is a distinct concern that grows substantially
under Pod 2 (Cop) and beyond — auto-invocation hooks, cap-grant
machinery, ring-overflow policy, retention rules. Keeping it isolated
from the VM dispatch loop makes future work additive rather than
intermixed.

## D1.8.5c.6 — Cost-table pointer initialization is runtime, not static

Mid-Phase-2B finding that required source touch outside the HALT 2A
ratification window. Capturing per architect's instruction.

**Pre-fix symptom:** B2 Sign round-trip showed `Energy: 0j used,
100000j remaining` instead of the expected `174j used, 99826j
remaining`. All field round-trip values (sign_id, energy, label, hash)
matched correctly; only the energy accounting was zero.

**Diagnosis:** Move 1's S8 indirection introduced
`current_demod_cost_table_ptr: dq energy_cost_table` in
`boot/vmdata.asm`. NASM under `-f bin` mode (the build uses raw binary
output, not PE32+ relocations) resolves `dq <symbol>` to the symbol's
file offset, not its runtime virtual address. At runtime,
`mov rax, [rel current_demod_cost_table_ptr]` loaded the file offset
(e.g. `0x4xxx`), and `mov rax, [rax + rbx*8]` dereferenced low-memory
garbage — returning 0 for every opcode cost. Energy debit became a
no-op.

**Fix:** Initialize `current_demod_cost_table_ptr` at runtime in
`efi_entry`. Stored statically as `dq 0`; written via
`lea rax, [rel energy_cost_table]; mov [rel current_demod_cost_table_ptr], rax`
early in efi_entry, before any cbs_run can be invoked. RIP-relative
`lea` computes the actual VA regardless of load address.

**Provenance:** Protocol-bypassed mid-Phase-2B. Retroactively ratified
because the diagnosis was correct, the fix was minimal (one declaration
change + four-instruction init block), and there was no alternative
design to halt for — `dq <symbol>` simply does not produce a runtime
VA in `-f bin` mode, so static init via `dq` was not a viable path.
Two-build determinism re-verified post-fix.

## D1.8.5c.7 — Doctrine note: mid-Phase-2 source touches

Established by D1.8.5c.6 and explicitly captured for next pod:

**Within-scope (continue):** Mid-Phase-2 source touches that are
bug-fixes within an already-authorized move's implementation. Test:
"is the fix unique, with no design alternative to choose between?"
If yes, the fix is mechanical and continues without halt.

**Out-of-scope (PAUSED-MID-EXECUTION required):** Mid-Phase-2 source
touches that change move shape, expand authorized scope, or commit to
a substrate-shape decision. Test: "did the fix surface a design choice
between alternatives?" If multiple correct alternatives exist, halt
and surface the choice for ratification before fix executes.

The cost-table fix in D1.8.5c.6 was within-scope by this rule:
`dq <symbol>` does not work in `-f bin`; runtime init via `lea` is the
only path; no alternative substrate shape to choose between.

## D1.8.5c.8 — Opcode cost classification: structural 0j, metabolic-pending 1j

`OP_PHASE_QUERY` (0xD5) costs 0j in `boot/energy_costs.asm`, matching
the precedent set by HALT (0xFF) and OP_RESERVE (0x20). Substrate
state queries are not work; reading vm_phase from memory and pushing
it on the operand stack is a structural primitive, not a metabolic
operation.

`OP_ENERGY_RECOVER` (0xD4) costs 1j as a default placeholder. Pod 2
(Cop) prices the recovery curve when it implements the actual recovery
mechanics. The 1j is not principled — it is the default-for-unallocated
slot that the cost table inherits. When Pod 2 lands, the recovery
energy semantics determine whether the opcode itself costs joules or
whether the cost is computed from the recovered amount.

**Why:** structural opcodes (HALT, RESERVE, PHASE_QUERY) participate
in substrate accounting without consuming energy, so they can fire
even when bankruptcy is approaching — querying state to make a recovery
decision must be cheaper than the recovery itself.

## D1.8.5c.9 — Strings, cost-table comment, dispatch entries: scope additions

Three small additions to source files not enumerated in the original
prompt's S1-S9 file list:

- `boot/data.asm` gained `str_op_energy_recover_noop` for the OP_ENERGY_RECOVER
  no-op log line. The string-literals convention already lived in
  `data.asm`; adding one more entry there matches the existing pattern.
- `boot/energy_costs.asm` cost-table comment for row 0xD0-0xDF was
  updated to reflect 0xD4 = OP_ENERGY_RECOVER and 0xD5 = OP_PHASE_QUERY,
  re-classifying 0xD5 from "Energy V1.1+" to "structural" per
  D1.8.5c.8.
- `boot/cbs_vm.asm` dispatch chain gained two new `cmp al, OP_X / je
  .op_x` entries for OP_ENERGY_RECOVER and OP_PHASE_QUERY.

All three are within the authorized opcode-add scope; called out for
explicit scope-tracking discipline.

## D1.8.5c.10 — OP_SIGN_NEW signature decision: 5-arg ABI preserved

Per the S6 amendment surfaced upfront in Phase 2A: OP_SIGN_NEW
continues to pop 5 args. The topmost arg (formerly `provenance_handle`,
validated as 0) is now silently discarded; the validation check was
removed; the slot field at +0x70 is reclaimed for `arena_id`.

**Why:** ABI preservation. The only existing caller is
`tools/atreyu_x86.py` demo_sign() which pushes 5 args; preserving the
5-arg shape means no test regeneration and no caller updates.

The trade-off recorded at HALT 2A: dead-pop in handler is misleading
to future readers. DEFERRED #32 tracks the disposition — Pod 3+
handle-pool work may rebind the 5th arg to a real handle or commit to
the ABI break with an explicit 4-arg signature change.

## D1.8.5c.11 — Atreyu test surfaces: phase + energy_recover land in surfaces/

Two new compiled .cbc files committed: `surfaces/test_phase.cbc` (104
bytes) and `surfaces/test_energy_recover.cbc` (152 bytes). Generated
by new build flags `--phase-build` and `--energy-recover-build` in
`tools/atreyu_x86.py`.

**Why:** the test surfaces become permanent regression-test inputs
for any future pod that touches OP_PHASE_QUERY semantics
(particularly Pod 5 Surfaces when it activates MODES) or
OP_ENERGY_RECOVER semantics (Pod 2 Cop when it implements the
recovery curve). Committing them makes regression testing reproducible
without re-running atreyu_x86.py.

---

## Summary

| Decision | Resolution |
|----------|-----------|
| D1.8.5c.1 | A1(d) Sign reclamation — 128-byte slot preserved |
| D1.8.5c.2 | A2 collapse — MODES enum-reserved-but-unwritten |
| D1.8.5c.3 | A3 CHANNELS unconditional — phase model survives NATIVE_KBD undef |
| D1.8.5c.4 | A4 ProvEvent 32-byte cache-aligned, 128-entry ring |
| D1.8.5c.5 | A5 boot/provenance.asm as new file |
| D1.8.5c.6 | Cost-table pointer init at runtime — NASM -f bin dq-symbol fix |
| D1.8.5c.7 | Doctrine: mid-Phase-2 fix-vs-halt rule |
| D1.8.5c.8 | OP cost classification: structural 0j, metabolic-pending 1j |
| D1.8.5c.9 | Scope additions: data.asm string, cost-table comment, dispatch |
| D1.8.5c.10 | OP_SIGN_NEW 5-arg ABI preserved |
| D1.8.5c.11 | test_phase.cbc + test_energy_recover.cbc committed |

Architect ratified A1(d) explicitly mid-Phase-2A (slot-reclaim path);
A2/A3/A4/A5 ratified at AUTHORIZED-1; D1.8.5c.6 ratified retroactively
at AUTHORIZED-2B per D1.8.5c.7 doctrine.

— Terminal Boy
May 03 2026
