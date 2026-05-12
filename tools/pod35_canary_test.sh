#!/bin/bash
# Pod 3.5 — generic canary/test surface harness.
# Boot Bastian → press 2 (Gmork) → load <surface>.cbc → screendump.
# Throwaway test script (housekeeping bundle, DEFERRED #78).
#
# Usage: pod35_canary_test.sh <surface_basename> <screendump_basename>
#   surface_basename     e.g. test_cosine_45_degree
#   screendump_basename  e.g. pod35_b10_cosine_45_degree -> build/<base>.png

set -e
SURFACE="$1"
OUT="$2"
[ -z "$SURFACE" ] || [ -z "$OUT" ] && { echo "usage: $0 <surface_basename> <screendump_basename>"; exit 1; }

REPO=/mnt/c/Users/Rando/codebook
BUILD=$REPO/build
IMG=$BUILD/codebook.img
SRC=$REPO/surfaces/${SURFACE}.cbc
[ -f "$SRC" ] || { echo "missing $SRC"; exit 1; }

OVMF_CODE=/usr/share/OVMF/OVMF_CODE.fd
OVMF_VARS_TMPL=/usr/share/OVMF/OVMF_VARS.fd

# Inject test surface into FAT32 root so 'load <name>.cbc' from gmork finds it
mcopy -i "$IMG" -o "$SRC" ::/${SURFACE}.cbc

rm -f /tmp/qemu_can_mon.in /tmp/qemu_can_mon.out /tmp/${OUT}.ppm
mkfifo /tmp/qemu_can_mon.in /tmp/qemu_can_mon.out
OVMF_VARS=/tmp/codebook_OVMF_VARS_can.fd
cp "$OVMF_VARS_TMPL" "$OVMF_VARS"

qemu-system-x86_64 -machine q35 -m 256M -cpu max \
    -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE \
    -drive if=pflash,format=raw,file=$OVMF_VARS \
    -drive file=$IMG,format=raw,if=virtio \
    -display none \
    -serial file:/tmp/can_serial.log \
    -monitor pipe:/tmp/qemu_can_mon \
    -daemonize -no-reboot &
sleep 0.5
cat /tmp/qemu_can_mon.out > /tmp/can_mon.log &
DRAIN_PID=$!

# Wait for full UEFI + Bastian render
sleep 8

# Press '2' to enter Gmork Terminal
echo "sendkey 2" > /tmp/qemu_can_mon.in
sleep 1

# Match reference harness preamble: extra Enter before load (blank gmork> line)
echo "sendkey ret" > /tmp/qemu_can_mon.in
sleep 0.3

# Type "load <surface>.cbc<Enter>"
send_str() {
    local s="$1"
    local i ch key
    for ((i=0;i<${#s};i++)); do
        ch="${s:$i:1}"
        case "$ch" in
            ' ') key=spc ;;
            '.') key=dot ;;
            '_') key=shift-minus ;;
            [a-z]) key="$ch" ;;
            [A-Z]) key="shift-$(echo $ch | tr A-Z a-z)" ;;
            [0-9]) key="$ch" ;;
            *) key="$ch" ;;
        esac
        echo "sendkey $key" > /tmp/qemu_can_mon.in
    done
}

send_str "load ${SURFACE}.cbc"
echo "sendkey ret" > /tmp/qemu_can_mon.in

# Wait for surface execution + halt — Pod 3.5 lookup demos compute over 256 candidates
# × 384 dims; allow extra time for compute completion before screendump
sleep 6

# Screendump
echo "screendump /tmp/${OUT}.ppm" > /tmp/qemu_can_mon.in
sleep 2

if [ -f /tmp/${OUT}.ppm ]; then
    python3 -c "
from PIL import Image
img = Image.open('/tmp/${OUT}.ppm')
img.save('${BUILD}/${OUT}.png')
print('saved ${BUILD}/${OUT}.png')
"
fi

echo 'quit' > /tmp/qemu_can_mon.in
sleep 1
kill $DRAIN_PID 2>/dev/null || true
wait $DRAIN_PID 2>/dev/null || true

echo "=== ${OUT} COMPLETE ==="
ls -la $BUILD/${OUT}.png 2>&1 || echo "screendump missing"
