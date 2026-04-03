#!/bin/bash
# Audits boot.asm for UEFI runtime calls after ExitBootServices
# Usage: ./tools/audit_uefi_calls.sh

echo "=== Auditing UEFI Runtime Calls ==="
echo ""

# 1. Check for UEFI runtime service calls (after ExitBootServices)
echo "UEFI Runtime Calls (after ExitBootServices):"
grep -n "call \[uefi_" boot/boot.asm | grep -A5 "ExitBootServices"

# 2. Check for lingering GOP/SFSP references after ExitBootServices
echo ""
echo "Lingering GOP/SFSP References:"
grep -n "call \[." boot/boot.asm | grep -i "gop\|sfsp" | grep -v "BeforeExitBootServices"

# 3. Check for EFI system table or protocol usage after ExitBootServices
echo ""
echo "EFI System Table/Protocol Usage:"
grep -n "mov \[rsp" boot/boot.asm | grep -i "efi_"

# 4. Generate a summary
echo ""
echo "=== Summary ==="
echo "If any UEFI calls appear after ExitBootServices, patch them to use native drivers."
echo "Allowed UEFI calls:"
echo "  - ExitBootServices"
echo "  - Initial GOP/SFSP locate (before ExitBootServices)"