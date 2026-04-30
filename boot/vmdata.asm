; =============================================================
; VM Runtime Data — Stack, Vars, Energy, Memory Map
; Engywook's notebook. The state he keeps to know whether the
; rules are being honored.
; Labels: energy_budget, energy_used, vm_ret_ptr, vm_ret_stack,
;         vm_stack, vm_vars, vm_sign_pool, vm_sign_next,
;         vm_energy_pool, vm_energy_next, mmap_buf
; Layer:  Layer 1 — VM runtime (kept separate from cbs_vm.asm so
;         Pod 1 can extend without touching opcode handlers)
; =============================================================

    align 16
energy_budget: dq 100000
energy_used:   dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dq 0      ; 512 bytes variables (64-bit, Pod 1.5)

; Sign pool (64 nodes × 128 bytes = 8KB, Pod 1.7)
    align 16
vm_sign_pool:   times 64 * 128 db 0
vm_sign_next:   dq 0            ; bump allocator index (next free slot)

; Energy pool (64 nodes x 128 bytes = 8KB, Pod 1.8)
    align 16
vm_energy_pool:  times ENERGY_POOL_SLOTS * ENERGY_SLOT_SIZE db 0
vm_energy_next:  dq 0            ; bump allocator index (next free slot)

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0
