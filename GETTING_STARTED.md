# Getting Started with CodebookOS

Boot CodebookOS in QEMU in 5 commands. ~10 minutes from clone to working OS.

## Prerequisites

| Package | Purpose |
|---|---|
| `nasm` 2.16+ | Assembles NASM x86_64 UEFI substrate |
| `mtools` 4.0+ | Builds FAT32 disk image (`mformat`, `mcopy`) |
| `dosfstools` | `mkfs.fat` for the image filesystem |
| `qemu-system-x86` | Runs the EFI image |
| `ovmf` | UEFI firmware for QEMU |
| Python 3.10+ | Builds CBS bytecode (`tools/atreyu_x86.py`) |

### Ubuntu / Debian (including WSL2)

```bash
sudo apt update
sudo apt install nasm mtools dosfstools qemu-system-x86 ovmf python3
```

### macOS

```bash
brew install nasm mtools qemu
# OVMF: brew install qemu installs it; path is /usr/local/share/qemu/edk2-x86_64-code.fd
# Adjust test_qemu.sh if your OVMF path differs.
```

### Windows

Use WSL2 with Ubuntu — same commands as the Ubuntu section. CodebookOS development happens primarily on WSL2 Ubuntu; that's the canonical path.

---

## The 5-command path

```bash
git clone https://github.com/RandolphPelican/codebook.git
cd codebook
./build.sh
./test_qemu.sh
# (when done) press Ctrl+A then X in QEMU to quit
```

Step-by-step:

1. **Clone**: standard git clone; ~10 MB repo (includes the demo video MP4 at `polish/dist/codebookos_v1.0_demo.mp4`).
2. **`./build.sh`**: assembles `boot/boot.asm` (which `%include`s all 37 NASM source files in `boot/`) → produces `build/BOOTX64.EFI`. Then constructs a FAT32 image and copies the EFI into it → `build/codebook.img`. Build takes ~5 seconds on modern hardware. Verifies the V1.0 SEAL contract sha automatically.
3. **`./test_qemu.sh`**: launches QEMU with OVMF firmware against `build/codebook.img`. QEMU window opens; substrate boots.

### Expected boot sequence

```
1. UEFI firmware initialization (~1s; OVMF logos)
2. CodebookOS substrate starts; capability/sign/energy pools initialize
3. Bastian — the home screen — renders. Mythology icons + menu.
4. Press 2 to enter Gmork (the shell).
```

---

## Gmork tour

```
Gmork Terminal -- CodebookOS
  help           commands
  about          system info
  clear          clear screen
  ls             list root files
  load <file>    load and run CBS
  fb             framebuffer info
  mem            memory map
  colors         color bars
  echo <text>    echo
  peek <addr>    read memory
  dump <addr>    hex dump
  fill <hex>     fill screen
  reboot         reset
  home           home screen
  programs       list CBS demos
  run <0-4>      execute CBS program
                 0=full demo
```

Try:

```
help                                          # see commands
ls                                            # list bundled CBS files
load test_pod40f_b53_fib_energy.cbc           # the Fibonacci-with-energy-trace demo
```

Each `load <file>.cbc` runs a compiled CBS program. The substrate dispatches every opcode, drains the metabolic budget, and prints the program's output via the auryn render primitives.

## The six canary CBS demos

| Demo | File | What it proves |
|---|---|---|
| Fibonacci with energy trace | `test_pod40f_b53_fib_energy.cbc` | Per-opcode energy accounting visible at user-program scale (D3.17) |
| Drift anchor | `test_pod40f_b58_drift_anchor.cbc` | D3.28 self-verifying canon: 0xB4000000 drift byte-exact at runtime |
| Press-X interactive | `test_pod40f_b57_press_x.cbc` | First V1.0 CBS interactive program; polling on use_cap(CAP_GMORK_CONIN, 1) |
| Vector composer | `test_pod40f_b55_vector_composer.cbc` | 5-doctrine cross-composition; halving magnitudes; orthogonality byte-exact |
| Similarity browser | `test_pod40f_b54_similarity_browser.cbc` | Maid top-K cosine ranking against boot-ingested codebook |
| Cap lifecycle | `test_pod40f_b56_cap_lifecycle.cbc` | Capability grant + use + accounting; V2.0 revoke deferral honest |

(Some demos use auxiliary substrate builds with a codebook input; see `tools/pod40f_b54_runner.sh` for the auxiliary-substrate canary pattern.)

---

## Flash to USB (run on real hardware)

```bash
# Identify your USB device first; replace sdX with the actual letter.
lsblk
sudo dd if=build/codebook.img of=/dev/sdX bs=4M status=progress oflag=sync
```

**Caveats**:
- `dd` is unforgiving — `of=/dev/sda` on the wrong device wipes your boot drive. Verify with `lsblk` first.
- The image is ~64 MB (BOOTX64.EFI + FAT32 overhead); any USB stick works.
- Boot the target machine with UEFI mode enabled (CSM disabled). Select the USB stick from the firmware boot menu.

---

## Building from source — how it works under the hood

```
./build.sh internally:

  nasm -f bin boot/boot.asm -o build/BOOTX64.EFI    # one flat-binary EFI image
  mkfs.fat -F 32 -C build/codebook.img 65536        # 64 MB FAT32
  mmd -i build/codebook.img ::/EFI                  # FAT32 layout
  mmd -i build/codebook.img ::/EFI/BOOT
  mcopy -i build/codebook.img build/BOOTX64.EFI ::/EFI/BOOT/
  mcopy -i build/codebook.img surfaces/*.cbc ::/    # bundle compiled CBS demos
```

`boot/boot.asm` is a PE32+ EFI binary hand-coded in NASM. It `%include`s every other NASM file in `boot/`. No linker; no C; no gnu-efi. The image is byte-exact reproducible across two clean rebuilds — verified at every SEAL contract sha.

Build chain: NASM 2.16.01 + mtools 4.0.43 + QEMU 8.2.2 (pinned per D3.29 axis-1 build-shell discipline; substrate-canon-immune to dev-environment drift).

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `nasm: not found` | `sudo apt install nasm` (or `brew install nasm` on macOS) |
| `mformat: not found` | `sudo apt install mtools dosfstools` |
| QEMU starts but no display | Check OVMF path in `test_qemu.sh`; differs per OS |
| Boot hangs at firmware splash | OVMF mismatch — try `ovmf` package update or `apt install ovmf` |
| QEMU sound buzzing | Substrate has no audio output; QEMU's default audio backend complaints are cosmetic |
| `./build.sh` fails with "permission denied" | `chmod +x build.sh test_qemu.sh` |

---

## What's next

- Read [CBS_LANGUAGE.md](CBS_LANGUAGE.md) to learn the language. Write your own CBS demo against the existing substrate.
- Read [ARCHITECTURE.md](ARCHITECTURE.md) for the doctrinal depth. 44 codified decisions; auditable in a fortnight.
- Read [CONTRIBUTING.md](CONTRIBUTING.md) if you want to extend the substrate or land a new surface.

---

*Every opcode declares its cost. Every grant declares its parent. Every doctrine declares its scope.*
