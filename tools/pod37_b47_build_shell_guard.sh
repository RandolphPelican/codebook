#!/bin/bash
# Pod 3.7 B47 — build-shell guard host-side meta-test.
#
# Surface-distinct from substrate canaries: this is a build-system canary class
# (Pod 3.7 D3.29 / DEFERRED #89 RESOLVED). Verifies build.sh's dual-layer
# pinning fails loud when toolchain version drifts. Artifact is a text log,
# not a screendump; not run via QEMU harness.
#
# Test 1: fake nasm reports wrong version → build.sh must exit non-zero with
#         "nasm version mismatch" in the captured log.
# Test 2: fake mcopy reports wrong version → build.sh must exit non-zero with
#         "mcopy version mismatch" in the captured log.

set -u   # NOT set -e: we want to inspect non-zero exits, not die on them
cd /mnt/c/Users/Rando/codebook

REPO_DIR="$(pwd)"
FAKE_NASM=/tmp/fake_nasm
FAKE_MCOPY=/tmp/fake_mcopy
NASM_LOG=/tmp/b47_nasm.log
MCOPY_LOG=/tmp/b47_mcopy.log

cleanup() {
    rm -f "$FAKE_NASM" "$FAKE_MCOPY"
}
trap cleanup EXIT

PASS_COUNT=0
FAIL_COUNT=0

echo "=== Pod 3.7 B47 — build-shell guard host-side meta-test ==="
echo

# --- Test 1: fake nasm with wrong version ---
echo "--- Test 1: fake nasm reports NASM version 1.99.99 ---"
cat > "$FAKE_NASM" <<'EOF'
#!/bin/bash
# Fake nasm for B47 build-shell guard test
echo "NASM version 1.99.99 compiled on Jan  1 1970"
exit 0
EOF
chmod +x "$FAKE_NASM"

NASM="$FAKE_NASM" ./build.sh > "$NASM_LOG" 2>&1
RC1=$?

if [ $RC1 -ne 0 ] && grep -q "nasm version mismatch" "$NASM_LOG"; then
    echo "PASS  fake-nasm guard fired (exit code $RC1; mismatch message present)"
    echo "  captured: $(grep 'nasm version mismatch' "$NASM_LOG" | head -1)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL  fake-nasm guard did NOT fire as expected"
    echo "  exit code: $RC1 (expected non-zero)"
    echo "  log tail:"
    tail -5 "$NASM_LOG" | sed 's/^/    /'
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo

# --- Test 2: fake mcopy with wrong version ---
echo "--- Test 2: fake mcopy reports mtools 1.99.99 ---"
cat > "$FAKE_MCOPY" <<'EOF'
#!/bin/bash
# Fake mcopy for B47 build-shell guard test
echo "mcopy (GNU mtools) 1.99.99"
echo "configured with the following options: enable-xdf enable-vold ..."
exit 0
EOF
chmod +x "$FAKE_MCOPY"

# Need real nasm for Test 2 (we're testing mcopy guard, not nasm guard)
MCOPY="$FAKE_MCOPY" ./build.sh > "$MCOPY_LOG" 2>&1
RC2=$?

if [ $RC2 -ne 0 ] && grep -q "mcopy version mismatch" "$MCOPY_LOG"; then
    echo "PASS  fake-mcopy guard fired (exit code $RC2; mismatch message present)"
    echo "  captured: $(grep 'mcopy version mismatch' "$MCOPY_LOG" | head -1)"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "FAIL  fake-mcopy guard did NOT fire as expected"
    echo "  exit code: $RC2 (expected non-zero)"
    echo "  log tail:"
    tail -5 "$MCOPY_LOG" | sed 's/^/    /'
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo

# --- Summary ---
echo "=== B47 summary ==="
echo "PASS: $PASS_COUNT / 2"
echo "FAIL: $FAIL_COUNT / 2"
echo "Logs preserved at $NASM_LOG and $MCOPY_LOG"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "=== B47 OVERALL: PASS — build-shell determinism guards fire loud on toolchain drift ==="
    exit 0
else
    echo "=== B47 OVERALL: FAIL ==="
    exit 1
fi
