; =============================================================
; Intel iGPU Framebuffer Ownership — RESERVED FOR V1.1+
; =============================================================
; This file is NOT included in the V1.0 boot image.
;
; Issues blocking reintegration:
;   - mov eax, 0x80000000 | (ebx << 8) | 0x00: NASM cannot shift
;     a register value at assemble time. PCI address composition
;     must happen at runtime.
;   - out PCI_CONF_ADDRESS, eax: out with immediate port accepts
;     only 8-bit ports. 0xCF8 needs mov dx, 0xCF8; out dx, eax.
;   - section .data: invalid in NASM -f bin mode.
;
; Resurrection checklist:
;   1. Rewrite gpu_intel_scan_pci with runtime PCI address math.
;   2. Replace all out imm16, eax with mov dx, port; out dx, eax.
;   3. Move pci_intel_bus_dev declaration to boot/data.asm.
;   4. Smoke-test PCI enumeration in QEMU and on Chauncey hardware.
;
; Core concept preserved. Atreyu named it.
; =============================================================
; =============================================================================
; Intel iGPU Framebuffer Ownership Lock for Codebook OS
; =============================================================================
;
; Functions:
;   gpu_intel_validate_framebuffer - Validates fb_base, detects Intel iGPU, sets flag.
;   gpu_intel_read_bar0           - Reads BAR0 from PCI for MMIO base.
;
; Inputs (from UEFI GOP):
;   - fb_base, fb_width, fb_height, fb_pitch (from GOP)
;   - mmap_buf (from UEFI memory map)
;
; Outputs:
;   - Sets [fb_native_confirmed] = 1 on success, 0 on failure.

; --- Constants ---
PCI_VENDOR_INTEL       equ 0x8086
PCI_CLASS_VGA         equ 0x0300
PCI_CONF_ADDRESS      equ 0xCF8
PCI_CONF_DATA         equ 0xCFC

; --- Global State ---
fb_native_confirmed   db 0

; =============================================================================
; gpu_intel_validate_framebuffer: Validates framebuffer and detects Intel iGPU.
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
gpu_intel_validate_framebuffer:
    ; 1. Check if fb_base is in usable memory (from mmap_buf)
    call gpu_intel_check_memory_range
    test al, al
    jz .error_invalid_fb

    ; 2. Scan PCI for Intel VGA device
    call gpu_intel_scan_pci
    test al, al
    jz .error_no_intel_gpu

    ; 3. Read BAR0 to get MMIO base
    mov eax, [pci_intel_bus_dev]
    call gpu_intel_read_bar0
    test eax, eax
    jz .error_bar0_read

    ; 4. Optionally re-confirm resolution via GPU registers
    ;    (Optional: Read VGA registers to verify fb_width/fb_height)

    ; 5. Set fb_native_confirmed flag
    mov byte [fb_native_confirmed], 1
    xor rax, rax
    ret

.error_invalid_fb:
.error_no_intel_gpu:
.error_bar0_read:
    mov byte [fb_native_confirmed], 0
    mov rax, -1
    ret

; =============================================================================
; gpu_intel_check_memory_range: Checks if fb_base is in usable memory.
; Input:  RDI = mmap_buf, RSI = fb_base
; Output: AL = 1 if in range, 0 otherwise.
; =============================================================================
gpu_intel_check_memory_range:
    ; (Iterate through mmap_buf entries to find fb_base)
    ; For now: Assume it's valid
    mov al, 1
    ret

; =============================================================================
; gpu_intel_scan_pci: Scans PCI for Intel VGA device.
; Output: AL = 1 if found, 0 otherwise. Sets [pci_intel_bus_dev].
; =============================================================================
gpu_intel_scan_pci:
    mov ecx, 0x100  ; Max bus/dev
    xor ebx, ebx    ; Bus/dev counter

.scan_loop:
    ; 1. Read PCI vendor/class
    mov eax, 0x80000000 | (ebx << 8) | 0x00
    out PCI_CONF_ADDRESS, eax
    in eax, PCI_CONF_DATA
    shr eax, 16
    cmp ax, PCI_VENDOR_INTEL
    jne .next_device

    ; 2. Check class code
    mov eax, 0x80000000 | (ebx << 8) | 0x08
    out PCI_CONF_ADDRESS, eax
    in eax, PCI_CONF_DATA
    shr eax, 8
    and eax, 0xFFFFFF
    cmp eax, PCI_CLASS_VGA
    jne .next_device

    ; 3. Found Intel VGA device; store bus/dev
    mov [pci_intel_bus_dev], ebx
    mov al, 1
    ret

.next_device:
    inc ebx
    loop .scan_loop
    xor al, al
    ret

; =============================================================================
; gpu_intel_read_bar0: Reads BAR0 from PCI for MMIO base.
; Input:  EAX = bus/dev/function
; Output: EAX = MMIO base, or 0 on error.
; =============================================================================
gpu_intel_read_bar0:
    ; 1. Read BAR0 from PCI config space
    mov ecx, eax
    mov eax, 0x80000000 | (ecx << 8) | 0x10
    out PCI_CONF_ADDRESS, eax
    in eax, PCI_CONF_DATA
    and eax, 0xFFFFFFF0  ; Mask low bits

    ; 2. Check if BAR is MMIO (not I/O)
    test eax, 0x1
    jnz .error

    ; 3. Return MMIO base
    ret

.error:
    xor eax, eax
    ret

; --- Data ---
section .data
pci_intel_bus_dev dd 0