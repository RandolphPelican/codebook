#!/bin/bash
# =============================================================
# CodebookOS x86 Build Script
# Assembles boot.asm → BOOTX64.EFI
# Creates bootable FAT32 disk image → codebook.img
#
# Usage: ./build.sh
# Then:  sudo dd if=build/codebook.img of=/dev/sdX bs=4M status=progress
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DIR="$SCRIPT_DIR/boot"
BUILD_DIR="$SCRIPT_DIR/build"
IMG_NAME="codebook.img"
EFI_NAME="BOOTX64.EFI"
IMG_SIZE_MB=64

echo "=== CodebookOS x86 Build ==="
echo ""

# ---- Create build dir ----
mkdir -p "$BUILD_DIR"

# ---- Check for NASM ----
if ! command -v nasm &>/dev/null; then
    echo "[!] NASM not found. Install with:"
    echo "    sudo apt install nasm"
    exit 1
fi

# ---- Check for mtools ----
if ! command -v mcopy &>/dev/null; then
    echo "[!] mtools not found. Install with:"
    echo "    sudo apt install mtools"
    exit 1
fi

# ---- Compile CBS demo bytecode ----
echo "[1/5] Compiling CBS Surfaces..."
if command -v python3 &>/dev/null && [ -f "$SCRIPT_DIR/tools/atreyu_x86.py" ]; then
    python3 "$SCRIPT_DIR/tools/atreyu_x86.py" --build "$BOOT_DIR/demo.cbc"
else
    echo "      [skip] No python3 or atreyu_x86.py — using existing demo.cbc"
fi

# ---- Assemble ----
echo "[2/5] Assembling boot.asm..."
nasm -f bin -o "$BUILD_DIR/$EFI_NAME" "$BOOT_DIR/boot.asm"
SIZE=$(stat -c %s "$BUILD_DIR/$EFI_NAME" 2>/dev/null || stat -f %z "$BUILD_DIR/$EFI_NAME")
echo "      $EFI_NAME: $SIZE bytes"

# ---- Verify PE32+ header ----
MAGIC=$(od -A n -t x1 -N 2 "$BUILD_DIR/$EFI_NAME" | tr -d ' ')
if [ "$MAGIC" != "4d5a" ]; then
    echo "[!] ERROR: Not a valid MZ executable (got: $MAGIC)"
    exit 1
fi
echo "      PE32+ header: OK"

# ---- Create FAT32 disk image ----
echo "[3/5] Creating ${IMG_SIZE_MB}MB FAT32 disk image..."
dd if=/dev/zero of="$BUILD_DIR/$IMG_NAME" bs=1M count=$IMG_SIZE_MB status=none

# ---- Format as FAT32 ----
echo "[4/5] Formatting FAT32..."
/sbin/mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1 || \
    mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1

# ---- Copy EFI file to correct path ----
echo "[5/5] Installing BOOTX64.EFI..."
mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI
mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI/BOOT
mcopy -i "$BUILD_DIR/$IMG_NAME" "$BUILD_DIR/$EFI_NAME" ::/EFI/BOOT/BOOTX64.EFI

echo ""
echo "=== Build complete ==="
echo "Image: $BUILD_DIR/$IMG_NAME"
echo "EFI:   /EFI/BOOT/BOOTX64.EFI ($SIZE bytes)"
echo ""
echo "To flash to USB:"
echo "  sudo dd if=$BUILD_DIR/$IMG_NAME of=/dev/sdX bs=4M status=progress"
echo "  (replace /dev/sdX with your USB device)"
echo ""
echo "To test in QEMU:"
echo "  ./test_qemu.sh"
echo ""
echo "Atreyu named it."
#..
