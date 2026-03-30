#!/bin/bash
# =============================================================
# CodebookOS QEMU Test
# Boots codebook.img in QEMU with UEFI (OVMF)
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
IMG="$BUILD_DIR/codebook.img"

# ---- Check QEMU ----
if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "[!] QEMU not found. Install with:"
    echo "    sudo apt install qemu-system-x86"
    exit 1
fi

# ---- Find OVMF firmware ----
OVMF_CODE=""
for f in /usr/share/OVMF/OVMF_CODE_4M.fd \
         /usr/share/OVMF/OVMF_CODE.fd \
         /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
         /usr/share/qemu/OVMF.fd \
         /usr/share/ovmf/OVMF.fd; do
    if [ -f "$f" ]; then
        OVMF_CODE="$f"
        break
    fi
done

if [ -z "$OVMF_CODE" ]; then
    echo "[!] OVMF firmware not found. Install with:"
    echo "    sudo apt install ovmf"
    exit 1
fi

# Find matching VARS file, or use combined OVMF
OVMF_VARS=""
VARS_DIR="$(dirname "$OVMF_CODE")"
for f in "${VARS_DIR}/OVMF_VARS_4M.fd" \
         "${VARS_DIR}/OVMF_VARS.fd"; do
    if [ -f "$f" ]; then
        OVMF_VARS="$f"
        break
    fi
done

if [ ! -f "$IMG" ]; then
    echo "[!] $IMG not found. Run ./build.sh first."
    exit 1
fi

echo "=== CodebookOS QEMU Test ==="
echo "OVMF: $OVMF_CODE"
echo "Image: $IMG"
echo ""

if [ -n "$OVMF_VARS" ]; then
    # Split CODE+VARS mode (proper way)
    cp "$OVMF_VARS" "$BUILD_DIR/OVMF_VARS_tmp.fd"
    qemu-system-x86_64 \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$BUILD_DIR/OVMF_VARS_tmp.fd" \
        -drive file="$IMG",format=raw \
        -m 256M \
        -net none \
        -vga std \
        -serial stdio
else
    # Combined OVMF mode (fallback)
    qemu-system-x86_64 \
        -bios "$OVMF_CODE" \
        -drive file="$IMG",format=raw \
        -m 256M \
        -net none \
        -vga std \
        -serial stdio
fi
#..
