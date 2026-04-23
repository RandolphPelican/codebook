#!/bin/bash
# =============================================================
# CodebookOS QEMU Smoke Test
# UEFI boot via OVMF firmware. Interactive by default.
# Usage:
#   ./test_qemu.sh            # interactive GTK display
#   ./test_qemu.sh --headless # no display, 8s timeout (CI mode)
# =============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
IMG="$BUILD_DIR/codebook.img"

[ -f "$IMG" ] || { echo "[!] $IMG not found. Run ./build.sh first."; exit 1; }
command -v qemu-system-x86_64 >/dev/null || {
    echo "[!] qemu-system-x86_64 not found. sudo apt install qemu-system-x86"
    exit 1
}

# Locate OVMF firmware (distro paths vary).
OVMF_CODE=""
for p in /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF.fd /usr/share/ovmf/OVMF.fd; do
    [ -f "$p" ] && OVMF_CODE="$p" && break
done
[ -n "$OVMF_CODE" ] || { echo "[!] OVMF firmware not found. sudo apt install ovmf"; exit 1; }

# Writable OVMF_VARS template (copy to /tmp so build/ stays pristine).
OVMF_VARS_TMPL=""
for p in /usr/share/OVMF/OVMF_VARS.fd /usr/share/qemu/OVMF_VARS.fd /usr/share/ovmf/OVMF_VARS.fd; do
    [ -f "$p" ] && OVMF_VARS_TMPL="$p" && break
done

OVMF_VARS="/tmp/codebook_OVMF_VARS.fd"
if [ -n "$OVMF_VARS_TMPL" ]; then
    cp "$OVMF_VARS_TMPL" "$OVMF_VARS"
    PFLASH=(-drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
            -drive "if=pflash,format=raw,file=$OVMF_VARS")
else
    # Older combined OVMF.fd — no separate vars file
    PFLASH=(-bios "$OVMF_CODE")
fi

COMMON=(-machine q35 -m 256M "${PFLASH[@]}"
        -drive "file=$IMG,format=raw,if=virtio")

echo "=== CodebookOS QEMU Smoke Test ==="
echo "OVMF: $OVMF_CODE"
echo "IMG:  $IMG"
echo ""

if [ "$1" = "--headless" ]; then
    echo "Headless mode: 8-second liveness probe..."
    qemu-system-x86_64 "${COMMON[@]}" -display none -serial file:/tmp/qemu_serial.log -no-reboot &
    QPID=$!
    sleep 8
    if kill -0 "$QPID" 2>/dev/null; then
        echo "PASS: VM alive at t+8s (in event loop)"
        kill "$QPID" 2>/dev/null
        sleep 2
        kill -9 "$QPID" 2>/dev/null || true
        wait "$QPID" 2>/dev/null || true
        exit 0
    else
        echo "FAIL: VM exited before t+8s"
        wait "$QPID" 2>/dev/null
        exit 1
    fi
else
    echo "Interactive mode. Quit QEMU window (or Ctrl+C) to exit."
    echo ""
    echo "You should see: splash -> Bastian home -> '1' enters Gmork terminal."
    echo ""
    exec qemu-system-x86_64 "${COMMON[@]}" -display gtk -serial stdio
fi
