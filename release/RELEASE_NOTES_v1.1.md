# CodebookOS V1.1 — Metabolic Enforcement — Release Notes (DRAFT)

**Tag:** `v1.1-ship`
**Predecessor:** [`v1.0-ship`](https://github.com/RandolphPelican/codebook/releases/tag/v1.0-ship)
**Date:** July 2026
**Author:** Randolph Pelican III / StableTech Enterprises LLC

---

## What this release is

V1.0 shipped capabilities that *carried* energy budgets. V1.1 makes the
substrate *enforce* them. Every opcode fetched under a capability's
authority now debits that capability's metabolic ledger; a capability
that cannot afford its next opcode dies at a deterministic fetch count
with a CAP BANKRUPT banner from the substrate itself. The budget field
stops being a promise and starts being a law.

Eight hand-written substrate chunks, one decision record (Pod 5), one
new demo, and a reseal — the first exercise of the supersession
convention: the SEAL is chained, never overwritten.

SEAL chain:
```
V1.0  c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900
V1.1  58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a
```

---

## Headline anchors

| Anchor | Value | Verification |
|---|---|---|
| New substrate lines | 124 under `boot/` | `git diff v1.0-ship v1.1-ship -- boot/` |
| New per-cap ledger fields | `energy_dispatched` (+0x48), `energy_settled` (+0x50), non-MAC | `boot/defines.asm` |
| New accessor | `OP_CAP_DISPATCHED` 0xBB, 1j | `boot/defines.asm`, cost table |
| Bankruptcy demo | B61: 600j child dies mid-loop, banner names cap_id=2 | `tools/v11_runtwice.sh` |
| Invocation reset canary | run-twice passes; surface 2 clean after nested death | `tools/v11_runtwice.sh` |
| Babylon ledger blast radius | ZERO — all 8 OP_CAP_USED canaries hold verbatim | `energy_used` untouched by Pod 5 |
| Two-build determinism | Preserved | `sha256sum build/BOOTX64.EFI` ×2 |
| V1.1 SEAL substrate contract | `58823aa9…b5db6a` | `sha256sum build/BOOTX64.EFI` |

## What landed (Pod 5, 8 chunks)

1–2. Metabolic ledger constants + current-cap slot/budget cache plumbing.
3. Per-cap energy debit + overflow-safe bankruptcy check in `.fetch`;
   `.cap_fatigue` diagnostic halt.
4. Settlement-on-exit: watermark fold (`parent.dispatched +=
   child.dispatched − child.settled`) — re-entry cannot double-bill.
5. `OP_CAP_DISPATCHED` accessor.
6. Per-invocation lifecycle reset (`cap_stack`, `current_cap`, caches)
   at `cbs_run` entry.
7. Sentinel-grant closure: a bounded cap cannot forge an UNBOUNDED
   child (`ERR_CAP_AUTHORITY_EXCEEDED`, parallel to subset-on-grant).
8. atreyu raises on unknown expression nodes (was a silent
   fallthrough).

Full rationale, review corrections, and doctrine lineage:
`recon/POD5_DECISION_RECORD.md`.

## Demo suite additions

- **B61 — cap bankruptcy** (`demos/b61_cap_bankruptcy.py`): the
  substrate executes a deterministic metabolic death sentence.
- **B62 — f32-bits ordering canary**, **B63 — energy golf (GCD
  showdown, receipts in joules)**, **B64 — surprise-gated agent
  (predict → compare → broadcast only on surprise, savings measured by
  the ISA)** (`demos/pelican_demos.py`). Demo-tier, AI-assisted,
  outside the credential boundary — the substrate's first external
  users.

## Compiler exposure (post-chunk-8 follow-up, landed)

atreyu exposes `cap_dispatched` (OP_CAP_DISPATCHED 0xBB); sealed
bytecode verified unchanged before commit. B61 prints both ledgers —
`cap_used` (Babylon ripples) and `cap_dispatched` (metabolic law) —
side by side, making the ledger-separation axiom visible in a single
framebuffer capture.

## Frozen artifacts

`release/RELEASE_NOTES.md`, `release/v1.0-ship_TAG_MESSAGE.txt`,
`release/codebookos_v1.0_manifesto.pdf`, `release/codebookos_v1.0.img`,
`drafts/*`, and all V1.0-era `recon/` records describe what shipped in
May 2026 and are not edited to match later code — supersession is
chained, never rewritten.
