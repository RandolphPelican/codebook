# Deferred Tasks

Items surfaced during Pod 0 that deserve future attention but didn't
warrant their own Pod 0 section.

---

## 1. LLC / signing entity rename

Banner, file headers, and canonical doc author lines all read
"Randolph Pelican III / StableTech Enterprises LLC". When the
software-signing entity name is finalized (may differ from
StableTech), a single cleanup pod replaces all instances repo-wide.
Awaiting architect decision on entity name.

## 2. ide_pio.asm NASM warnings

`drivers/ide_pio.asm:86` emits "implicit DEFAULT ABS is deprecated"
and `drivers/ide_pio.asm:161,230,288` emit "unsigned byte exceeds
bounds". Both are non-fatal; binary builds correctly. Cleanup pod in
Pod 1 or later when VM hardening touches I/O paths.

## 3. chauncey_test.md Legacy BIOS reference

`tools/chauncey_test.md` says "Boot Mode: Legacy BIOS (disable UEFI)"
but the project is UEFI-native. Architect to verify Chauncey hardware
supports UEFI; if so, doc gets corrected. If not, project has a real
hardware testing constraint to address.

## 4. Bastian slot expansion

V1 ships four slots wired (Bastian, Gmork, Atreyu, Rockbiter). Slots
5-12 are stubs routing to coming-soon cards. Each slot gets wired as
its surface comes online (Pods 5-8 per RECONSTITUTION pod arc).

## 5. Visual / banner refresh

Current banner styling is functional but provisional. Refresh deferred
until V1 surfaces are complete and a coherent visual identity is
designed.

## 6. Orphaned opcodes in defines.asm

Three opcodes defined but not handled in `cbs_vm.asm`:

- `OP_DUP2` (0x87) — simple stack operation, defined but never wired.
- `OP_GRANT_CAP_NEW` (0xCA000003) — Phase 5.1 ghost from the exiled
  `cap_graph.asm` integration attempt. 4-byte value, not a 1-byte
  opcode like the existing `OP_GRANT_CAP`.
- `OP_USE_CAP_NEW` (0xCA000004) — same provenance as above.

Pod 1 either wires `OP_GRANT_CAP_NEW`/`OP_USE_CAP_NEW` properly or
removes them, decision per the cap_graph deep-read in Pod 0.9.
`OP_DUP2` gets wired or removed in Pod 1 when the VM instruction set
is finalized.

## 7. README full rewrite

Current README.md body describes the Python-era CBS toolchain (Phase 8,
`tools/cbsc.cbs`, `v4.0-reorganized-structure`). Pod 0.8 patched it
with a "Where to start" section pointing at canon docs, but the body
still describes an earlier project state. Full rewrite deferred to
when V1 surfaces are far enough along to describe accurately.

## 8. prompts/ directory backfill

Most Pod 0 prompts were delivered conversationally and not saved to
the repo. Only `POD0.0_REFERENCE_LOCK.md` and `POD0.3_CLEANUP.md`
exist in `prompts/`. Saving the remaining Pod 0 prompts for posterity
is low-priority — possibly Pod 1's first housekeeping task.
