# Codebook OS

---
## Context
- **ASM VM:** The bytecode is executed by `runtime.py` (a Python-based ASM VM). This VM expects bytecode in a specific format (e.g., `0x71` for `LOAD_CONST`, followed by a null-terminated string).
- **Test Files:** Example `.cbs` files like `hello.cbs` and `button.cbs` exist in the `surfaces/` directory. These are pre-written and should be used for testing:
  ```bash
  surfaces/
  ├── hello.cbs  # Prints "Hello, Codebook!"
  └── button.cbs # Placeholder for a button surface
  ```
- **Semantic Surfaces:** Surfaces are spatial, energy-budgeted tokens. The compiler must preserve metadata like (x,y) coordinates and energy budgets when generating bytecode.
- **Future Directory Structure:**
  After Phase 6, the toolchain will be reorganized as:
  ```text
  codebook_os/
  ├── tools/
  │   ├── cbsc.cbs       # Integrated compiler
  │   └── read_file.cbs  # Pure CBS file I/O
  └── surfaces/          # All .cbs files
  ```

---

# CodebookOS x86_64 — Phase 1 (UEFI)

**Pure NASM UEFI boot. Zero C. Zero dependencies. Every byte is ours.**

## What This Is

A 13KB hand-crafted PE32+ EFI application that boots any x86_64 UEFI machine into:
- Gold-on-black framebuffer display (Auryn renderer)
- Interactive Gmork terminal with keyboard input
- Color bar test, system info, screen clear

No gcc. No gnu-efi. No borrowed code. Just NASM and spite.

## Setup on Dell (one time)

```bash
# Install tools
sudo apt update
sudo apt install nasm mtools dosfstools

# Optional: QEMU for testing without rebooting
sudo apt install qemu-system-x86 ovmf
```

## Build

```bash
chmod +x build.sh test_qemu.sh
./build.sh
```

Output: `build/codebook.img` (64MB FAT32 bootable image)

## Test in QEMU

```bash
./test_qemu.sh
```

Opens a QEMU window booting CodebookOS. Type `help` in Gmork terminal.

## Flash to USB

```bash
# Find your USB device
lsblk

# Flash (CAREFUL: replace sdX with your actual device)
sudo dd if=build/codebook.img of=/dev/sdX bs=4M status=progress
sync
```

## Boot on Dell

1. Plug in USB
2. Reboot, hit F12 (Dell boot menu)
3. Select USB drive (UEFI mode)
4. CodebookOS boots

## Architecture

```
BOOTX64.EFI (13KB)
├── PE32+ Header (hand-crafted, 512 bytes)
├── UEFI Bootstrap
│   ├── Disable watchdog
│   ├── Locate GOP (framebuffer)
│   ├── ConOut banner (UCS-2)
│   └── ExitBootServices (future)
├── Auryn Renderer
│   ├── auryn_fill (screen clear)
│   ├── auryn_paint (pixel write)
│   ├── auryn_putc (glyph blit)
│   └── auryn_puts (string render)
├── Gmork Terminal
│   ├── UEFI ConIn keyboard
│   ├── Command dispatch
│   └── Input buffer + echo
├── 8x8 Bitmap Font (760 bytes)
└── .reloc (minimal, firmware compat)
```

## File Structure

```
codebook-x86/
├── boot/
│   └── boot.asm          # THE kernel. Everything in one file for now.
├── build/                 # Generated artifacts (gitignored)
│   ├── BOOTX64.EFI       # PE32+ EFI application
│   └── codebook.img      # Bootable FAT32 disk image
├── build.sh              # Assemble + create disk image
├── test_qemu.sh          # Boot in QEMU with OVMF
└── README.md             # This file
```

---

# Codebook OS: CBS Compiler (Phase 6)

### Pure CBS Toolchain
As of **v2.4-pure-cbs-workflow-test**, the CBS compiler and toolchain are fully self-contained in CBS:
- **File I/O:** `tools/read_file.cbs`, `tools/write_file.cbs`
- **Compiler Driver:** `cbsc.cbs`
- **No Python dependencies** required for compilation.

**Usage:**
```bash
# Compile a .cbs file to .cb
python cbsc.cbs surfaces/hello.cbs

# Run the bytecode in the ASM VM
python runtime.py surfaces/hello.cb
```

### Expected Output
- `surfaces/hello.cb` is created.
- Terminal prints: `Compiled surfaces/hello.cbs to surfaces/hello.cb`
- ASM VM outputs: `Hello, Codebook!`

### Self-Compilation Test
```bash
# Compile the compiler itself
python cbsc.cbs cbsc.cbs

# Verify the bytecode is valid and run it in the ASM VM
python runtime.py cbsc.cb
```

### Expected Output
- `cbsc.cb` is created in the root.
- Terminal prints: `Compiled cbsc.cbs to cbsc.cb`
- ASM VM outputs: `CBSC Bootstrap OK`

### Deprecation Notes
| File | Status | Replaced By |
|------|--------|-------------|
| `read_file.py` | ❌ Deprecated | `tools/read_file.cbs` |
| `write_file.py` | ❌ Deprecated | `tools/write_file.cbs` |
| `bootstrap.py` | ❌ Deprecated | `cbsc.cbs` |

**Note:** Python is still used for:
- The ASM VM (`runtime.py`).
- The `cbsc.cbs` driver (for now).

### Future Work
- Rewrite the ASM VM (`runtime.py`) in CBS.
- Integrate `cbsc.cbs` into the full toolchain (`tools/cbsc.cbs`).
- Add semantic file system and energy mechanics.

### Troubleshooting
- **Error: "File not found"**
  Ensure paths are relative (e.g., `surfaces/hello.cbs`).
- **ASM VM crashes**
  Check that `cbsc.cbs` generates valid bytecode (e.g., correct opcodes).
- **Silent failures**
  Look for `Error` messages in CBS functions.

### Next Steps
1. Replace Python wrappers with **pure CBS file I/O** in `cbsc.cbs`. (Completed in Phase 6.3)
2. Integrate `cbsc.cbs` into the full toolchain (move to `tools/cbsc.cbs`).
3. Test the compiler on all `.cbs` files in `surfaces/`.

---

StableTech Enterprises LLC  
Randolph Pelican III  
Atreyu named it.
