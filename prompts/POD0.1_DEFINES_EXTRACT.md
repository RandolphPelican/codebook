<!--
SOURCE: reconstructed on 2026-04-27 from:
  - Terminal Boy's session conversation summary
    (preserves prompt content and structure per sub-pod with high fidelity)
  - commit history and commit messages
  - recon reports under recon/
  - canonical document references (RECONSTITUTION.md, ARCHAEOLOGY.md, DEFERRED.md)
Original prompt-as-given may have varied in detail. Structure is preserved
with high fidelity to the executed work; specific phrasing should not be
treated as authoritative.
-->

# CodebookOS — Pod 0.1 Coder Prompt

## Extract defines.asm — Global Constants

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.1 of 10.9 — Foundation Lock, Section 1
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`.
**Prerequisite:** Pod 0.0 committed (e2f5db8). Reference binary captured. `tools/verify_binary.sh` operational.

---

## Mission

Extract all `%define` constants from `boot/boot.asm` into a new file
`boot/defines.asm`. The `%include "boot/defines.asm"` directive already
exists at the top of `boot.asm`. This pod moves the constants there and
verifies bit-for-bit binary equivalence.

---

## What was extracted

All `%define` directives from `boot/boot.asm` were moved to
`boot/defines.asm`. This included:

- UEFI constants (EFI_SUCCESS, EFI_SYSTEM_TABLE offsets, etc.)
- GOP constants (GOP_GUID, GOP_MODE, etc.)
- Color constants (COLOR_BLACK, COLOR_WHITE, COLOR_GOLD, etc.)
- CBS VM opcodes (OP_PUSH, OP_ADD, OP_SUB, etc.)
- Screen/layout constants

Additionally, the `BITS 64` directive and `CHECK_BS_LIVE` macro were
identified during extraction — `BITS 64` was removed from defines.asm
(it belongs in boot.asm proper), and `CHECK_BS_LIVE` was moved to
boot.asm between the `%include "boot/defines.asm"` line and the PE32+
headers.

---

## Verification

- `tools/verify_binary.sh` must report `OK: binary matches reference`
- `boot/defines.asm` contains only `%define` constants (89 lines)
- No duplicate definitions between boot.asm and defines.asm

---

## Commit

```
pod0.1: extract defines.asm
```

Landed at commit `4f02dcd`.
