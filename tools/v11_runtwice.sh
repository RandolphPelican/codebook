#!/bin/bash
# V1.1 reset canary — loads TWO surfaces back to back in one QEMU session.
#
# Purpose: prove that cbs_run resets cap_stack and current_cap to ROOT on
# every invocation (V1.1 chunk 6). B61 halts while still nested inside a
# bankrupt cap — cap_exit is never reached. Without the reset, current_cap_id
# stays pointed at the dead cap and the SECOND surface instant-fatigues with
# a CAP BANKRUPT banner naming a cap it never entered.
#
# PASS: surface 2 runs normally and prints its own expected output.
# FAIL: surface 2 dies immediately with CAP BANKRUPT cap_id=0x00000002.
#
# Derived from tools/pod35_canary_test.sh (DEFERRED #78 throwaway bundle).
#
# Usage: v11_runtwice.sh <surface1> <surface2> <screendump_basename>

set -e
S1="$1"
S2="$2"
OUT="$3"
[ -z "$S1" ] || [ -z "$S2" ] || [ -z "$OUT" ] && {
    echo "usage: $0 <surface1> <surface2> <screendump_basename>"; exit 1; }

REPO=/mnt/c/Users/Rando/codebook
BUILD=$REPO/build
IMG=$BUILD/codebook.img

for S in "$S1" "$S2"; do
    [ -f "$REPO/surfaces/${S}.cbc" ] || { echo "missing $REPO/surfaces/${S}.cbc"; exit 1; }
done

OVMF_CODE=/usr/share/OVMF/OVMF_CODE.fd
OVMF_VARS_TMPL=/usr/share/OVMF/OVMF_VARS.fd

mcopy -i "$IMG" -o "$REPO/surfaces/${S1}.cbc" ::/${S1}.cbc
mcopy -i "$IMG" -o "$REPO/surfaces/${S2}.cbc" ::/${S2}.cbc

rm -f /tmp/qemu_rt_mon.in /tmp/qemu_rt_mon.out /tmp/${OUT}.ppm
mkfifo /tmp/qemu_rt_mon.in /tmp/qemu_rt_mon.out
OVMF_VARS=/tmp/codebook_OVMF_VARS_rt.fd
cp "$OVMF_VARS_TMPL" "$OVMF_VARS"

qemu-system-x86_64 -machine q35 -m 256M -cpu max \
    -drive if=pflash,format=raw,readonly=on,file=$OVMF_CODE \
    -drive if=pflash,format=raw,file=$OVMF_VARS \
    -drive file=$IMG,format=raw,if=virtio \
    -display none \
    -serial file:/tmp/rt_serial.log \
    -monitor pipe:/tmp/qemu_rt_mon \
    -daemonize -no-reboot &
sleep 0.5
cat /tmp/qemu_rt_mon.out > /tmp/rt_mon.log &
DRAIN_PID=$!

sleep 8
echo "sendkey 2" > /tmp/qemu_rt_mon.in
sleep 1
echo "sendkey ret" > /tmp/qemu_rt_mon.in
sleep 0.3

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
        echo "sendkey $key" > /tmp/qemu_rt_mon.in
    done
}

echo "--- run 1: ${S1} ---"
send_str "load ${S1}.cbc"
echo "sendkey ret" > /tmp/qemu_rt_mon.in
sleep 6

echo "--- run 2: ${S2} ---"
send_str "load ${S2}.cbc"
echo "sendkey ret" > /tmp/qemu_rt_mon.in
sleep 6

echo "screendump /tmp/${OUT}.ppm" > /tmp/qemu_rt_mon.in
sleep 2

if [ -f /tmp/${OUT}.ppm ]; then
    python3 -c "
from PIL import Image
img = Image.open('/tmp/${OUT}.ppm')
img.save('${BUILD}/${OUT}.png')
print('saved ${BUILD}/${OUT}.png')
"
fi

echo 'quit' > /tmp/qemu_rt_mon.in
sleep 1
kill $DRAIN_PID 2>/dev/null || true
wait $DRAIN_PID 2>/dev/null || true

echo "=== ${OUT} COMPLETE ==="
ls -la $BUILD/${OUT}.png 2>&1 || echo "screendump missing"
