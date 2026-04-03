# CodebookOS x86_64 — Phase 1

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

## Commands (Gmork Terminal)

| Command  | Description           |
|----------|-----------------------|
| help     | Show commands         |
| about    | System info           |
| clear    | Clear screen          |
| fb       | Framebuffer info      |
| colors   | Paint color test bars |

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

## Next Phases

- **Phase 2**: ExitBootServices → own the machine bare metal
- **Phase 3**: Native USB/xHCI keyboard (replace UEFI ConIn)  
- **Phase 4**: Native GPU driver (replace GOP)
- **Phase 5**: Morla filesystem, Falkor network stack
- **Phase 6**: CBS interpreter on bare metal
- **Ship**: Bootable USB product

## CBS Compiler (CodebookScript)

The CBS compiler translates high-level CodebookScript into bytecode for the CodebookOS VM.

### Usage

1. **Write CBS code** (e.g., `test_compiler.cbs`):
   ```cbs
   print "Hello, Codebook!"
   ```

2. **Compile to bytecode**:
   ```bash
   python bootstrap.py test_compiler.cbs
   ```
   This generates `test_compiler.cb`.

3. **Run on CodebookOS**:
   Load the `.cb` file into the spatial context or run via the `load` command in the Gmork terminal.

### Architecture

The compiler is written in CBS itself (Phase 4 complete) and follows a functional pipeline:
- `lexer.cbs`: Tokenizes source code.
- `parser.cbs`: Builds the Abstract Syntax Tree (AST).
- `compiler.cbs`: Emits Codebook VM bytecode (0x71-0x74).

---

StableTech Enterprises LLC  
Randolph Pelican III  
Atreyu named it.
