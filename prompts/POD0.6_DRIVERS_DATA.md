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

# CodebookOS — Pod 0.6 Coder Prompt

## Drivers Polish + data.asm Sub-Split Decision

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.6 of 10.9 — Foundation Lock, Section 6
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`. Comment-only edits.
**Prerequisite:** Pod 0.5 committed (9f86040). boot/ headers polished.

---

## Mission

Two tasks:

### Task 1 — drivers/ header polish

Standardize headers for all driver files following the established
pattern. For active drivers (`kbd_ps2.asm`, `ide_pio.asm`, `fat32.asm`):
preserve existing technical documentation (inputs, outputs, error codes)
within the standardized header.

For exiled drivers (`drivers/_future/gpu_intel.asm`,
`drivers/_future/fat32_write.asm`): standardize to the EXILED template
with STATUS/ORIGINAL/ISSUES/RESURRECTION/DEPENDENCIES/PRIORITY sections.

### Task 2 — data.asm sub-split decision

Evaluate whether `boot/data.asm` (678 lines) should be split into
sub-files (font_data.asm, strings.asm, programs.asm, etc.) or kept as a
monolith with section markers.

**Decision: Path Y — monolith with section markers.** Cross-referencing
density between sections made sub-splitting net-negative. Six section
markers added:
1. UEFI State
2. GUIDs/Colors
3. String Literals
4. Program Bytecode
5. Surface Stubs
6. Font Data

---

## Key decisions

- **ide_pio.asm:** Preserved 24-line technical documentation block
  (inputs, outputs, error codes). Documented known NASM warnings
  (unsigned byte overflow) as non-blocking.

- **gpu_intel.asm:** Collapsed two stacked headers from prior edits into
  single standardized EXILED template with resurrection checklist.

- **fat32_write.asm:** Standardized to same EXILED template.

- **data.asm:** Sub-split was considered and decided against. Section
  markers provide navigability without the cross-reference complexity
  of splitting.

---

## Verification

- `tools/verify_binary.sh` must report `OK: binary matches reference`

---

## Commits

```
pod0.6a: drivers/ header polish + _future/ standardization  (fbb8ba3)
pod0.6b: data.asm header + section markers                  (e6d41b3)
```
