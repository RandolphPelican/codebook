#!/bin/bash
# Tests Phase 4.4: In-OS Compile Loop
# Usage: ./test_qemu.sh

echo "=== Phase 4.4 Integration Test ==="

# 1. Boot QEMU with Codebook image
echo "Booting CodebookOS in QEMU..."
qemu-system-x86_64 -drive file=codebook.img,format=raw -serial stdio &

# 2. Wait for terminal (give QEMU 5s to start)
sleep 5

# 3. Send commands via serial
echo "Sending test commands..."
echo "compile hello.cbs" > /dev/pts/0
sleep 2
echo "run" > /dev/pts/0
sleep 2

echo "Test complete. Check QEMU output for success/failure."