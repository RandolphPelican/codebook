## CodebookOS v1.1 — Metabolic Enforcement

A capability that can't afford its next opcode now dies — deterministically, with a banner, at the same fetch count every run. V1.0's energy budgets were bookkeeping; V1.1 makes them law, in 124 lines of hand-written NASM.

**Highlights**
- Per-fetch metabolic debit + bankruptcy check against the current capability (`energy_dispatched`, non-MAC, +0x48)
- Settlement-on-exit with watermark fold — a child's bill lands on whoever ran it, and re-entry can't double-bill
- `OP_CAP_DISPATCHED` (0xBB): read your own consumption (which costs consumption — the metabolic observer effect)
- Bounded caps can no longer forge unbounded children
- Babylon's ancestral-ripple ledger untouched: all 8 sealed `OP_CAP_USED` canary numbers hold verbatim

**SEAL chain** (chained, never overwritten):
```
V1.0  c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900
V1.1  58823aa9e9ad17c3fd0975cad557c934599c22588c38506d4454b6dbe1b5db6a
```
Verify: `sha256sum BOOTX64.EFI` — then build it twice from source and watch the sha not move.

**Assets**
- `codebookos_v1.1.img` — bootable USB image (demos preloaded)
- `BOOTX64.EFI` — the substrate itself
- `codebookos_v1.1_manifesto.pdf` — the story
- `test_b61..b64.cbc` — demo bytecode
- `SHA256SUMS`

Run in QEMU: `qemu-system-x86_64 -bios OVMF.fd -drive format=raw,file=codebookos_v1.1.img -m 512`

Full record: [`recon/POD5_DECISION_RECORD.md`](../blob/main/recon/POD5_DECISION_RECORD.md)
