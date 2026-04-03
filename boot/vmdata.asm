; =============================================================
; VM Runtime Data — Stack, variables, energy, memory map buffer
; Kept separate from static data for Pod 1 VM hardening
; =============================================================

    align 16
energy_budget: dq 100000
energy_used:   dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dd 0      ; 256 bytes variables

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0
