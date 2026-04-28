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

# CodebookOS — Pod 0.2.5 Coder Prompt

## Repo-Wide Archaeology Pass

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.2.5 of 10.9 — Foundation Lock, Section 2.5
**Constraint:** Read-only recon sweep. No source changes.
**Prerequisite:** Pod 0.2 committed (4489d01). auryn.asm extracted.

---

## Mission

Full repo-wide archaeology pass. Read-only. No source changes. The goal
is to verify ARCHAEOLOGY.md's claims against the actual repo state and
surface anything the archaeology missed.

This pod also established `RECON_PROTOCOL.md` — the verify-before-build
canon that mandates Phase 1 recon sweeps before any Phase 2 build work
for all pods from 0.2.5 forward.

---

## Sweeps executed

The recon covered:

- **Sweep A:** `boot/boot.asm` current structure and include chain
- **Sweep B:** All files in `boot/` — verify each module's scope
- **Sweep C:** `drivers/` directory — discovered load-bearing PS/2, IDE
  PIO, FAT32 driver code not captured in ARCHAEOLOGY.md
- **Sweep D:** `kernel/_future/` — discovered exiled cap_graph.asm and
  paging.asm with resurrection checklists
- **Sweep E:** `drivers/_future/` — discovered exiled gpu_intel.asm and
  fat32_write.asm
- **Sweep F:** `surfaces/` and `tools/` directories
- **Sweep G:** Git branch history — identified stale branches

Key discovery: `drivers/` was a parallel development arc with real,
load-bearing code that ARCHAEOLOGY.md had not captured. This discovery
prompted RECONSTITUTION.md v2.

---

## Deliverables

1. `RECON_PROTOCOL.md` — the verify-before-build canon (committed at
   `f1b223a`)
2. `recon/POD0.2.5_RECON_REPORT.md` — full archaeology report (committed
   at `7facf2a`)

---

## Commits

```
pod0.2.5: add RECON_PROTOCOL.md — verify-before-build canon  (f1b223a)
pod0.2.5: repo-wide archaeology pass                          (7facf2a)
```
