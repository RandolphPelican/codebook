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

# CodebookOS — Pod 0.8 Coder Prompt

## Final Foundation Lock — Doc-vs-Code Audit + Pod 0 Sign-Off

**Project:** CodebookOS x86_64 UEFI
**Repo:** github.com/RandolphPelican/codebook
**Author:** Randolph Pelican III / StableTech Enterprises LLC
**Pod:** 0.8 of 10.9 — Foundation Lock, Section 8 (final sign-off)
**Constraint:** Binary must remain bit-for-bit identical to the post-Pod-0.7
  reference binary (sha256: `cee5c4fc71045edde0a5fd5ef9625a479014bc6ecb4b5cf5d820ead622369e3a`).
  Comment-only edits expected.
**Prerequisite:** Pod 0.7 committed (4ff12d8). New reference binary is the
  contract.

---

## Mission

Doc-vs-code consistency audit across the entire canon, followed by Pod 0
milestone tag. The recon protocol's central premise — verify before
naming — applies to the canon itself.

---

## Phase 1 — Recon (seven sweeps)

- **Sweep Z:** Bastian slot count — confirmed twelve-slot infrastructure
  with 4 wired (Bastian, Gmork, Atreyu, Rockbiter) and 8 coming-soon
  stubs
- **Sweep AA:** Opcode audit — 33 defined, 31 handled, 3 orphaned
  (OP_DUP2, OP_GRANT_CAP_NEW, OP_USE_CAP_NEW)
- **Sweep BB:** Surface files vs. dispatchable surfaces — 3 .cbc
  embedded, 12 named, gap expected per ROADMAP
- **Sweep CC:** Layer 2/3 verification — design only, no implementation
- **Sweep DD:** Pod 0 commitment audit — all deliverables present
- **Sweep EE:** Reference binary contract — sha256 matches, pre-0.7
  backup gitignored
- **Sweep FF:** README state — stale, from Python-era, no canon refs

---

## Phase 2 — Doc reconciliation

### RECONSTITUTION.md updates
- Bastian: twelve-slot framing (4 wired, 8 stubs, Pods 5-8 wire them)
- Include chain: removed stale "stranded auryn_puts" reference
- Layers 2-3: explicitly marked as design-only with Pod pointers

### README.md
- Added "Where to start" section pointing at canon docs

### DEFERRED.md
- Created with 8 items: LLC rename, ide_pio warnings, chauncey_test
  BIOS ref, Bastian slots, visual refresh, orphaned opcodes, README
  rewrite, prompts backfill

### Pod 0 milestone tag
- `pod0-complete` annotated tag listing all Pod 0 sections with commit
  hashes

---

## Verification (five checks)

1. Binary equivalence against post-0.7 reference
2. All Pod 0 deliverables present and non-empty
3. `pod0-complete` tag created and pushed
4. DEFERRED.md contains all known items
5. QEMU boot test (architect-side)

---

## Commits

```
pod0.8: doc-vs-code reconciliation + deferred tasks  (d68167c)
tag: pod0-complete                                    (at d68167c)
```
