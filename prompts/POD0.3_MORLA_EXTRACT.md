<!--
STATUS: RETIRED before execution.
SUPERSEDED BY: POD0.3_CLEANUP.md.
REASON: Pod 0.2.5 recon revealed morla code was already extracted in earlier
work. Original plan obsolete on arrival. Preserved as historical artifact for
project archaeology. DO NOT EXECUTE.
-->
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

# CodebookOS — Pod 0.3 Coder Prompt (RETIRED)

## Morla Extraction — Extract FAT32 Surface from boot.asm

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.3 of 10.9 — Foundation Lock, Section 3 (original plan)
**Constraint:** Binary must remain bit-for-bit identical to `build/BOOTX64_reference.EFI`.
**Prerequisite:** Pod 0.2 committed (4489d01).

---

## Mission (NEVER EXECUTED)

Extract the morla FAT32 surface code from `boot/boot.asm` into
`boot/morla.asm`. This included `morla_write_file`, `morla_ls`,
`ucs2_to_ascii`, `ascii_to_ucs2`, `morla_run_file`, `auryn_puts`,
`boot_bastian`, and `morla_run_file_main`.

---

## Why this was retired

Pod 0.2.5's repo-wide archaeology recon (commit `7facf2a`) revealed that
the morla extraction had already been performed in earlier work sessions.
`boot/morla.asm` already existed with the correct content. The original
Pod 0.3 plan was obsolete on arrival.

The Pod 0.3 slot was reassigned to repo cleanup work (see
`POD0.3_CLEANUP.md`), which addressed cruft surfaced during the Pod
0.2.5 recon: nested `codebook/` directory, text dump files, and stale
git branches.
