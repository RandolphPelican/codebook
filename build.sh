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

# ---- Pod 3.7 build-shell determinism (D3.29 + DEFERRED #89 RESOLVED) ----
# Dual-layer pinning: absolute-path bypasses $PATH (defense against Git-Bash-
# on-Windows or other shells with different binaries on PATH); version-grep
# guards against silent toolchain drift. NASM/MCOPY env vars are override-
# friendly for testability (Pod 3.7 B47 host-side guard test fakes a wrong
# nasm via NASM=/tmp/fake_nasm to verify fail-loud behavior).
NASM="${NASM:-/usr/bin/nasm}"
MCOPY="${MCOPY:-/usr/bin/mcopy}"
EXPECTED_NASM_VERSION="2.16.01"
EXPECTED_MCOPY_VERSION="4.0.43"

[ -x "$NASM" ]  || { echo "BUILD-SHELL: $NASM not found or not executable";  exit 1; }
[ -x "$MCOPY" ] || { echo "BUILD-SHELL: $MCOPY not found or not executable"; exit 1; }

"$NASM"  --version | grep -q "$EXPECTED_NASM_VERSION"  || { echo "BUILD-SHELL: nasm version mismatch (expected $EXPECTED_NASM_VERSION); got: $("$NASM" --version)"; exit 1; }
"$MCOPY" --version 2>&1 | grep -q "$EXPECTED_MCOPY_VERSION" || { echo "BUILD-SHELL: mcopy version mismatch (expected $EXPECTED_MCOPY_VERSION); got: $("$MCOPY" --version 2>&1 | head -1)"; exit 1; }
# ---- end Pod 3.7 dependency check ----

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

# ---- [3/6] Generate codebook image (Pod 3.8.F; D3.31) ----
# Auto-generates boot/codebook_data.asm + boot/codebook.bin via codebook_builder.py.
# Source: $CODEBOOK_INPUT (default inputs/codebook.txt). Graceful empty fallback
# when no input file present — substrate boots normally with vm_codebook_meta.count=0
# and vm_embedding_next staying at 0 (prior-pod canary embedding IDs unaffected).
echo "[3/6] Generating codebook image..."
CODEBOOK_INPUT="${CODEBOOK_INPUT:-inputs/codebook.txt}"
if [ -f "$SCRIPT_DIR/$CODEBOOK_INPUT" ]; then
    python3 "$SCRIPT_DIR/tools/codebook_builder.py" \
        --expected-dim 384 \
        "$SCRIPT_DIR/$CODEBOOK_INPUT" "$BOOT_DIR/codebook_data"
    echo "      codebook: $CODEBOOK_INPUT"
else
    python3 "$SCRIPT_DIR/tools/codebook_builder.py" --empty "$BOOT_DIR/codebook_data"
    echo "      codebook: empty (no $CODEBOOK_INPUT)"
fi

# ---- [4/6] Assemble boot.asm ----
echo "[4/6] Assembling boot.asm..."
"$NASM" -f bin -o "$BUILD_DIR/$EFI_NAME" "$BOOT_DIR/boot.asm"
SIZE=$(stat -c %s "$BUILD_DIR/$EFI_NAME" 2>/dev/null || stat -f %z "$BUILD_DIR/$EFI_NAME")
echo "      $EFI_NAME: $SIZE bytes"

# ---- [5/6] Verify PE32+ MZ magic ----
MAGIC=$(od -A n -t x1 -N 2 "$BUILD_DIR/$EFI_NAME" | tr -d ' ')
if [ "$MAGIC" != "4d5a" ]; then
    echo "[!] ERROR: Not a valid MZ executable (got: $MAGIC)"
    exit 1
fi
echo "      PE32+ MZ header: OK"

# ---- [6/6] Build FAT32 image and install EFI ----
echo "[6/6] Building ${IMG_SIZE_MB}MB FAT32 image..."
dd if=/dev/zero of="$BUILD_DIR/$IMG_NAME" bs=1M count=$IMG_SIZE_MB status=none
/sbin/mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1 || \
    mkfs.vfat -F 32 -n "CODEBOOK" "$BUILD_DIR/$IMG_NAME" >/dev/null 2>&1

mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI
mmd -i "$BUILD_DIR/$IMG_NAME" ::/EFI/BOOT
"$MCOPY" -i "$BUILD_DIR/$IMG_NAME" "$BUILD_DIR/$EFI_NAME" ::/EFI/BOOT/BOOTX64.EFI

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
