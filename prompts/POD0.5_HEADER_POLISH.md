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

# CodebookOS — Pod 0.5 Coder Prompt

## Header Polish — Five Remaining boot/ Modules

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.5 of 10.9 — Foundation Lock, Section 5
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`. Comment-only edits.
**Prerequisite:** Pod 0.3 committed (50b2b4a). Repo cleanup complete.

---

## Mission

Polish headers across the five remaining boot/ modules that had not yet
received standardized headers: `gmork.asm`, `gmork_cmds.asm`,
`cbs_vm.asm`, `bastian.asm`, `vmdata.asm`.

Each header follows the established pattern:
```nasm
; =============================================================
; Name — Description
; Thematic tagline (NeverEnding Story reference).
; Functions: list
; Depends: list
; Layer: Layer N — description
; =============================================================
```

---

## Key decisions

- **gmork.asm:** Previous header was factually wrong — it listed
  `gmork_cmds.asm` functions by mistake (copy-paste error). Fully
  replaced with correct function list: `str_eq`, `starts_with`,
  `parse_hex`, `print_hex32`, `print_hex64`, `print_dec`, `print_sdec`.
  Tagline: "The wolf of the Nothing. Knows what words are, knows when
  they are not."

- **gmork_cmds.asm:** Tagline: "Where words become contracts." Functions:
  `gmork_main`, `get_mmap`, `show_memmap`, `paint_bars`.

- **cbs_vm.asm:** Header merged preserved register documentation block
  (r12=PC, r13=SP, r14=energy budget, r15=energy used). Single entry
  point: `cbs_run`.

- **bastian.asm:** Tagline: "The boy who climbs into the attic."
  Functions: `show_coming_soon`, `bastian_home`, `bastian_main`,
  `surface_table`.

- **vmdata.asm:** Tagline: "Engywook's notebook." Labels: `energy_budget`,
  `energy_used`, `vm_ret_ptr`, `vm_ret_stack`, `vm_stack`, `vm_vars`,
  `mmap_buf`.

---

## Verification

- `tools/verify_binary.sh` must report `OK: binary matches reference`
- All five files have standardized headers

---

## Commit

```
pod0.5: header polish across five remaining boot/ modules
```

Landed at commit `9f86040`.
