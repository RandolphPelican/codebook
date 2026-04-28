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

# CodebookOS — Pod 0.7 Coder Prompt

## auryn_puts Consolidation — The One Binary-Changing Pod 0 Section

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.7 of 10.9 — Foundation Lock, Section 7
**Constraint:** Binary WILL change. This is the sole binary-changing Pod 0
  operation. All prior pods maintained bit-for-bit equivalence; this one
  intentionally breaks it because moving code across %include boundaries
  shifts instruction offsets.
**Prerequisite:** Pod 0.6 committed (e6d41b3). All headers polished.

---

## Mission

Move `auryn_puts` from `boot/morla.asm` (line 198) to `boot/auryn.asm`,
placing it directly after `auryn_putc` — its only dependency. This
consolidates the auryn family: `auryn_fill`, `auryn_scroll`,
`auryn_paint`, `auryn_putc`, `auryn_puts` — all five in one file.

---

## Two-phase execution

### Phase 1 — Recon (four sweeps)

- **Sweep V:** Confirmed auryn_puts at morla.asm:198, not in auryn.asm
- **Sweep W:** Exact function body — 10 lines from `auryn_puts:` through
  `ret`
- **Sweep X:** 70+ callers across boot.asm, bastian.asm, cbs_vm.asm,
  gmork.asm, gmork_cmds.asm, morla.asm
- **Sweep Y:** Pre-move sha256 documented

### Phase 2 — The move

1. Cut auryn_puts (10 lines) from morla.asm
2. Paste after auryn_putc at end of auryn.asm
3. Update auryn.asm header to list auryn_puts as 5th function
4. Update morla.asm header with history note: "auryn_puts originally sat
   here from the monolith split; consolidated into auryn.asm in Pod 0.7"
5. Build and verify
6. Capture new reference binary

---

## Six-point verification

1. Build succeeds (exit 0)
2. Binary diverges from old reference (expected — offsets shift)
3. `auryn_puts:` absent from morla.asm (`grep -c` = 0)
4. `auryn_puts:` present in auryn.asm (`grep -c` = 1)
5. All caller sites resolve (clean build)
6. Binary size unchanged (1,049,600 bytes)

---

## Reference binary transition

- Pre-move sha256: `0dda9aa2036c97a373766ff02b9983091da7c821609d1d924d407ff01064f597`
- Post-move sha256: `cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a`

The post-move hash becomes the new permanent contract anchor.

---

## Commit

```
pod0.7: consolidate auryn_puts from morla.asm into auryn.asm
```

Landed at commit `4ff12d8`.
