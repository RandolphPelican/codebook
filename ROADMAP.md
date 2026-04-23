# CodebookOS - Roadmap

**Launch: July 23, 2026 -- Ras Tafari's birthday.**

**Status:** V1.0 pre-release. Build is green. Week 1 merge-damage
cleanup complete. Moving to Week 2 (Bastian + Gmork polish).

---

## Mission

CodebookOS is a bare-metal UEFI operating system hand-written in pure
NASM assembly, programmable in its own language (CBS -- Codebook Script).
Every system call declares its energy cost in joules. Every capability
is granted explicitly by name. No C. No kernel modules. No external
runtime dependencies. 64KB of assembly and a VM named Auryn.

Named for The NeverEnding Story. Built in Boca Raton, Florida.

---

## Core Principles (Non-Negotiable)

- **Pure NASM + CBS.** No C anywhere. No third-party libraries.
  If we can't write it ourselves, we don't use it.
- **Energy accounting.** Every CBS function declares costs Nj.
  The VM enforces it. Bankruptcy is a runtime condition.
- **Capability tokens.** `grant_cap` and `use_cap` are first-class.
  No ambient authority. If code didn't ask for it, code can't do it.
- **NeverEnding Story naming.** Atreyu, Auryn, Bastian, Morla, Gmork,
  Rockbiter, Falkor, Artax, Engywook, Koreander, Sphinx, Empress.
  Load-bearing, not cosmetic.
- **Every byte is ours.** Every sector of the USB was compiled from
  source we wrote. No pre-built blobs. No attestation we don't control.

---

## The 12 Surfaces

| # | Surface | Role | Cap | Energy | Status (V1.0) |
|---|---------|------|-----|--------|---------------|
| 1 | Bastian | Home launcher | -- | 100j | Shipping |
| 2 | Gmork | Terminal shell | CONIN | 500j | Shipping |
| 3 | Morla | File manager (visual) | FS | 800j | Polish wk 3 |
| 4 | Atreyu | Text editor | ATREYU | 1000j | Polish wk 3 |
| 5 | Rockbiter | System + energy monitor | ROCKBITER | 300j | Polish wk 4 |
| 6 | Auryn | Identity + settings | AURYN | 400j | New wk 5 |
| 7 | Empress | Content search | FS | 600j | New wk 6 |
| 8 | Koreander | Manual / docs browser | FS | 200j | New wk 4 |
| 9 | Falkor | Inter-surface messenger | FALKOR | 300j | New wk 7 |
| 10 | Sphinx | Capability inspector | CAPGRAPH | 500j | New wk 6 |
| 11 | Artax | Recovery + journal | FS | 700j | New wk 5 |
| 12 | Engywook | Calculator + scientist | -- | 300j | New wk 7 |

Each is a CBS surface wrapping native capabilities. Full `.cbs` source
for each ships on the USB under `/surfaces/`.

---

## 14-Week Calendar

| Week | Dates | Focus | Exit criterion |
|------|-------|-------|----------------|
| 1 | Apr 23-29 | P0 build cleanup **(DONE)** | `nasm -f bin` clean; QEMU boots; ROADMAP committed |
| 2 | Apr 30-May 6 | Bastian + Gmork polish | 12-slot menu nav; history, help, quit cmds |
| 3 | May 7-13 | Atreyu + Morla | Editor saves to FAT; file browser lists+opens |
| 4 | May 14-20 | Rockbiter + Koreander | Live energy view; docs browser reads `/docs/*.cbd` |
| 5 | May 21-27 | Auryn + Artax | Settings persist to `/auryn.cfg`; snapshot/restore |
| 6 | May 28-Jun 3 | Empress + Sphinx | Content grep; cap list/revoke UI |
| 7 | Jun 4-10 | Falkor + Engywook | Local message queue; expression calc |
| 8 | Jun 11-17 | v0.9 integration freeze | All 12 boot clean; regression pass; hardware test |
| 9 | Jun 18-24 | Manual, docs, polish | Koreander content done; PDF manual draft |
| 10 | Jun 25-Jul 1 | v1.0 freeze, mastering | USB image locked; sha256 published; license finalized |
| 11 | Jul 2-8 | Landing page + demo video | StableTech page live; 2-min cinematic boot demo |
| 12 | Jul 9-15 | Pre-launch | HN preview, list building, pre-launch reach-outs |
| 13 | Jul 16-22 | Final polish | All SKU pipelines live; physical stock ordered |
| 14 | Jul 23-Aug 1 | **LAUNCH + SUSTAIN** | HN, Product Hunt, Lobsters, r/osdev, r/retrobattlestations |

Slippage budget: compress Jun 11-17 integration week or defer Falkor to
V1.1 before touching the launch date. **July 23 is a hard date.**

---

## Pricing + Funnel

Three SKUs on Gumroad:

- **$19 Digital Download** -- ISO + manual PDF + boot instructions.
  Primary SKU. ~80% of volume.
- **$49 Physical USB** -- everything digital + real USB stick
  (custom branded) + zine-style printed manual + sticker sheet.
  Ships from Boca. ~15% of volume.
- **$149 Developer Edition** -- everything physical + full source
  tarball + CBS SDK + 30-min consult call with Randolph. ~5% of volume.

Blended revenue approx $30/unit. Target: 340 units to hit $10,000.

HN front page routinely converts 500-2k on novel retro-OS posts.
Add r/osdev (80k subs), Product Hunt, Lobsters -- realistic odds.

---

## Marketing Hook

> **CodebookOS. Every opcode knows its cost.**
>
> A bare-metal UEFI operating system hand-written in NASM, where every
> system call declares its energy budget in joules, every capability is
> granted explicitly by name, and the whole thing is written in its own
> language, CBS. No C. No kernel modules. No dependencies. 64KB of
> assembly and a VM named Auryn.
>
> Named for The NeverEnding Story. Built in Boca Raton by one guy and
> an AI named Chauncey.

---

## Build Instructions

```bash
./build.sh                         # build/BOOTX64.EFI + build/codebook.img
./test_qemu.sh                     # interactive QEMU smoke test
./test_qemu.sh --headless          # CI-style 8s liveness probe
sudo dd if=build/codebook.img of=/dev/sdX bs=4M status=progress  # flash USB
```

### Dependencies

```bash
sudo apt install nasm mtools dosfstools qemu-system-x86 ovmf
```

---

## Repository Layout

```
boot/           NASM assembly -- kernel, surfaces, VM
drivers/        Hardware drivers (PS/2, IDE PIO, FAT32 read)
drivers/_future/  Write drivers, GPU lock -- RESERVED FOR V1.1
kernel/_future/   Paging, capability graph -- RESERVED FOR V1.1
surfaces/       CBS source for the 12 surfaces
tools/          CBS -> .cbc compiler (Python, dev-only)
build/          Build artifacts (EFI + disk image + reference)
```

---

## V1.1+ Roadmap (Post-Launch)

Preserved under `drivers/_future/` and `kernel/_future/`:

- **FAT32 Write** -- driver exists, needs smoke testing
- **Intel iGPU framebuffer lock** -- needs NASM-correct PCI enumeration
- **Identity-mapped page tables** -- needs memory allocator
- **Capability graph with energy budgeting** -- needs 64-bit pointer rewrite

Extensions planned:

- CBS language: struct, arrays, for...in, member access, lambdas
- USB HID keyboard driver (modern laptops without PS/2 emulation)
- Network stack (Ethernet + minimal TCP)
- Bullies Auto-Correct (separate product, CBS-based)

---

## Credits

**StableTech Enterprises LLC**

- Randolph Pelican III -- Architect / Author
- Chauncey (Anthropic Claude) -- Senior AI architect
- Terminal Boy (Claude Code) -- Execution

Based in Boca Raton, Florida.

---

*Atreyu named it.*
*The Nothing is receding.*
*Every opcode knows its cost.*
