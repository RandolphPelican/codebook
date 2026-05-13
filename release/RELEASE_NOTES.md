# CodebookOS V1.0 — Release Notes

**Tag:** `v1.0-ship`
**Predecessor:** [`v1.0-seal`](https://github.com/RandolphPelican/codebook/releases/tag/v1.0-seal) (substrate canon-binding moment)
**Date:** May 2026
**Author:** Randolph Pelican III / StableTech Enterprises LLC

---

## What this release is

CodebookOS is a bare-metal x86_64 operating system built from scratch in 25.4 KB of hand-written NASM UEFI assembly, with its own programming language (CBS) implemented in a custom compiler and stack-VM. Built solo in 30 architect-hours across April-May 2026.

This release marks **V1.0 SHIP** — the public-flip moment. The substrate is byte-locked at the V1.0 SEAL contract sha; the polish layer is rendered; the demo video is composed; the manifesto is written; the documentation is complete.

---

## Headline anchors

| Anchor | Value | Verification |
|---|---|---|
| Substrate size | 25.4 KB | `wc -c < BOOTX64.EFI` (non-zero) |
| Doctrines codified | 44 + 8 | `recon/POD*_DECISION_RECORD.md` |
| Canary-verified demos | 6 | `surfaces/test_pod40f_b53..b58.cbc` |
| Two-build determinism | Preserved | sha verified at every chunk SEAL |
| Build effort | 30 architect-hours | git log |
| V1.0 SEAL substrate contract | `c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900` | `sha256sum build/BOOTX64.EFI` |

---

## What's in this release

### Release artifacts (`release/` directory)

| Artifact | Purpose | Size |
|---|---|---|
| `codebookos_v1.0.img` | Bootable FAT32 USB image; `dd` to USB stick or boot in QEMU | ~64 MB |
| `codebookos_v1.0_demo.mp4` | 90-second demonstration video; h264+yuv420p; 1280x720 | ~9.4 MB |
| `codebookos_v1.0_manifesto.pdf` | 22-page depth-doc PDF for the fortnight-auditor audience | ~32 KB |
| `SHA256SUMS` | Integrity checksums for the three artifacts above | < 1 KB |
| `RELEASE_NOTES.md` | This file | — |

### Repository contents (clone for the full credential)

- **`boot/`** — 37 NASM source files, ~25 KB of substrate. The credential.
- **`surfaces/`** — 6 canary-verified CBS bytecode demos + human-readable .cbs sources.
- **`tools/atreyu_x86.py`** — CBS compiler (~4,200 lines Python).
- **`recon/`** — 44 + 8 architectural decision records.
- **`polish/`** — Python presentation layer (animations, demo video composition, manifesto PDF builder).
- **`README.md`** + **`GETTING_STARTED.md`** + **`CBS_LANGUAGE.md`** + **`ARCHITECTURE.md`** + **`CONTRIBUTING.md`** — five public-facing docs at repo root.

---

## What V1.0 IS

A bare-metal operating system with five typed primitive pools (Sign / Energy / Outcome / Cap / Embedding), each MAC-protected where applicable, each with bounded capacity. A custom programming language (CBS) with energy-accounted opcodes; the substrate cannot execute beyond an authorized energy budget. F32 IEEE 754 byte-exact determinism per Form A canonical evaluation order. Capability-tokenized I/O surface with subset-on-grant enforcement from layer 1. 44 codified architectural doctrines forming a complete audit trail.

The Maid V1.0 capability surface — the lexical-computation pole of the substrate's planned cognitive trinity — is complete across six capability variants (housekeeper / composer / importer / finder-of-many / orthogonalizer / maintainer).

---

## What V1.0 is NOT

- Not a general-purpose OS. No process scheduler, no virtual memory, no multi-user. Capability-tokenized I/O is the only user-program surface beyond CBS execution.
- Not a networked system. No TCP/IP, no Ethernet driver. The substrate runs entirely on the bare metal that boots it.
- Not self-hosted at runtime. CBS demos compile on a host (Linux/macOS/WSL2 with Python); the substrate runs them but does not compile them at runtime. (Runtime IMPORT is V2.0 carry-forward #91.)
- Not the cognitive trinity. V1.0 ships one of three pillars complete (Maid). Cop (capability inspector) and Interpreter (text-to-bytecode runtime) carry forward to V2.0 framework-tested per the deferral discipline (D3.43).

V1.0 ships exactly what's built. V2.0 carry-forward items are honestly named in [DEFERRED.md](https://github.com/RandolphPelican/codebook/blob/main/DEFERRED.md).

---

## Quick start (5 commands, ~5 minutes)

```bash
git clone https://github.com/RandolphPelican/codebook.git
cd codebook
sudo apt install nasm mtools dosfstools qemu-system-x86 ovmf   # Ubuntu/Debian
./build.sh
./test_qemu.sh
```

Full hands-on guide: [GETTING_STARTED.md](https://github.com/RandolphPelican/codebook/blob/main/GETTING_STARTED.md).

### Flash to USB (real hardware)

```bash
# Identify USB device first; replace sdX with the actual letter.
lsblk
sudo dd if=codebookos_v1.0.img of=/dev/sdX bs=4M status=progress oflag=sync
```

Boot the target machine with UEFI mode enabled (CSM disabled). Select the USB stick from the firmware boot menu. Press `2` at Bastian (home screen) to enter Gmork (terminal). Type `help` for command list; `programs` to list bundled CBS demos; `run 0` to execute the full demo.

---

## Verifying release-artifact integrity

```bash
# After downloading all artifacts:
sha256sum -c SHA256SUMS
```

Expected output:
```
codebookos_v1.0.img: OK
codebookos_v1.0_demo.mp4: OK
codebookos_v1.0_manifesto.pdf: OK
```

The substrate sha inside the image (the `BOOTX64.EFI` payload) is independently verifiable:
```bash
# Mount the image or use mtools:
mcopy -i codebookos_v1.0.img ::/EFI/BOOT/BOOTX64.EFI ./BOOTX64.EFI
sha256sum BOOTX64.EFI
# Expected: c9923b8cf9fb6caf4c195e2d0d0ea2ed4a8e51e4e9f827b1fc24dd0b28c1d900
```

---

## The doctrinal corpus

44 codified architectural doctrines through V1.0 SEAL, plus 8 D4.X doctrines through V1.0 SHIP. Each doctrine numbered globally (D1.X / D2.X / D3.X / D4.X), each preserved in `recon/POD*_DECISION_RECORD.md` with rationale, alternatives considered, and empirical evidence that ratified it.

Load-bearing doctrines surfaced in [ARCHITECTURE.md](https://github.com/RandolphPelican/codebook/blob/main/ARCHITECTURE.md). The full corpus is the substrate's audit trail.

---

## Empirical verification

- **Two-build determinism**: Preserved across 16+ substrate-evolution pods.
- **F32 byte-exact determinism**: Per Form A canonical evaluation order (D3.14); verified per canary across the Maid V1.0 surface.
- **D4.1 byte-lock**: Substrate sha unchanged across 10 consecutive Pod 4.0 polish chunks (the polish layer can be deleted entirely and the substrate still builds, boots, and passes all canaries).
- **6/6 canary demos PASS**: B53 fib-energy, B54 similarity browser, B55 vector composer, B56 cap lifecycle, B57 press-X interactive, B58 drift anchor.

---

## License

License selection deferred to post-V1.0-SHIP. Contributors who land work after the public flip will need to agree to the chosen license at PR-merge time.

Mythology naming follows fair-use literary reference; no commercial relationship with the Michael Ende estate (*The Neverending Story*) is implied.

---

## Acknowledgments

Built by Randolph Pelican III ([StableTech Enterprises LLC](https://github.com/RandolphPelican)) solo, with collaborator-architect "Chauncey" (the Claude model lineage providing recon + chunk-execution assistance under chunked-pod methodology). The substrate is the architect's; the discipline is the team's.

Mythology characters honor Michael Ende's *The Neverending Story* (1979).

---

## What's next

- **V2.0** — Cop (capability inspector) and Interpreter (text-to-bytecode runtime) — the remaining two pillars of the cognitive trinity. Cap revocation. Federation_total ripple. Demod-tier surfaces (0xE8-0xEF row reserved). Runtime IMPORT. Multi-codebook. Each V2.0 candidate framework-tested per D3.43 at activation time.
- **Community input** — Issues + PRs welcome at the repo URL. Contributing guide: [CONTRIBUTING.md](https://github.com/RandolphPelican/codebook/blob/main/CONTRIBUTING.md).

---

*Every opcode declares its cost. Every grant declares its parent. Every doctrine declares its scope.*

— V1.0 SHIP, May 2026
