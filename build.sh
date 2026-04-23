#!/bin/bash
# =============================================================
# CodebookOS x86_64 Build Script
# Pure NASM UEFI. Zero dependencies. Every byte is ours.
# =============================================================
# Assembles boot.asm -> BOOTX64.EFI
# Creates bootable FAT32 disk image -> codebook.img
#
# Usage:
#   ./build.sh
# Then:
#   sudo dd if=build/codebook.img of=/dev/sdX bs=4M status=progress
#
# Author: Randolph Pelican III / StableTech Enterprises LLC
# Atreyu named it.
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BOOT_DIR="$SCRIPT_DIR/boot"
BUILD_DIR="$SCRIPT_DIR/build"
IMG_NAME="codebook.img"
EFI_NAME="BOOTX64.EFI"
IMG_SIZE_MB=64

echo "=== CodebookOS Build ==="
echo ""

mkdir -p "$BUILD_DIR"

# ---- Dependency check ----
command -v nasm  >/dev/null || { echo "[!] NASM not found. sudo apt install nasm"; exit 1; }
command -v mcopy >/dev/null || { echo "[!] mtools not found. sudo apt install mtools"; exit 1; }

# ---- [1/5] Pre-compile CBS surfaces (best-effort, dev-only) ----
echo "[1/5] Pre-compiling CBS surfaces..."
if command -v python3 >/dev/null && [ -f "$SCRIPT_DIR/tools/precompile_all.sh" ]; then
    bash "$SCRIPT_DIR/tools/precompile_all.sh" || echo "      [warn] precompile returned non-zero; using existing .cbc"
else
    echo "      [skip] python3 or precompile_all.sh missing; using existing .cbc"
fi

# ---- [2/5] Clean Python runtime droppings ----
echo "[2/5] Cleaning __pycache__ ..."
rm -rf "$SCRIPT_DIR/__pycache__/"
find "$SCRIPT_DIR" -name "*.pyc" -delete 2>/dev/null || true
find "$SCRIPT_DIR" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# ---- [3/5] Assemble boot.asm ----
echo "[3/5] Assembling boot.asm..."
nasm -f bin -o "$BUILD_DIR/$EFI_NAME" "$BOOT_DIR/boot.asm"
SIZE=$(stat -c %s "$BUILD_DIR/$EFI_NAME" 2>/dev/null || stat -f %z "$BUILD_DIR/$EFI_NAME")
echo "      $EFI_NAME: $SIZE bytes"

# ---- [4/5] Verify PE32+ MZ magic ----
MAGIC=$(od -A n -t x1 -N 2 "$BUILD_DIR/$EFI_NAME" | tr -d ' ')
if [ "$MAGIC" != "4d5a" ]; then
    echo "[!] ERROR: Not a valid MZ executable (got: $MAGIC)"
    exit 1
fi
echo "      PE32+ MZ header: OK"

# ---- [5/5] Build FAT32 image and install EFI ----
echo "[5/5] Building ${IMG_SIZE_MB}MB FAT32 image..."
dd if=/dev/zero of="$BUILD_DIR/$IMG_NAME" bs=1M count=$IMG_SIZE_MB status=none
/sbin/mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1 || \
    mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1

mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI
mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI/BOOT
mcopy -i "$BUILD_DIR/$IMG_NAME" "$BUILD_DIR/$EFI_NAME" ::/EFI/BOOT/BOOTX64.EFI

echo ""
echo "=== Build complete ==="
echo "Image: $BUILD_DIR/$IMG_NAME"
echo "EFI:   /EFI/BOOT/BOOTX64.EFI ($SIZE bytes)"
echo ""
echo "Flash to USB:"
echo "  sudo dd if=$BUILD_DIR/$IMG_NAME of=/dev/sdX bs=4M status=progress"
echo ""
echo "Test in QEMU:"
echo "  ./test_qemu.sh"
echo ""
echo "Atreyu named it."
