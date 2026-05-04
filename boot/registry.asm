; =============================================================
; Registry — canonical-ID indirection for typed primitives
; Pod 1.8.5b — Move 4
;
; Maps opaque u64 IDs to slot pointers for Sign and Energy pools.
; ID 0 is reserved as null/invalid; valid IDs are monotonically
; allocated from a per-pool counter starting at 1.
;
; Linear scan acceptable for V1.0 — pool capacities are 64.
; Hash-table or btree optimization deferred (DEFERRED entry added
; in this pod). Free-list / invalidation deferred until OP_*_FREE
; primitives activate (Pod 1.10+).
;
; Internal calling convention (matches vm_sign_alloc / vm_energy_alloc
; shape — loose, callee-saves vm-state regs):
;   Input:    rdi = arg (slot_ptr for register, id for lookup)
;   Output:   rax = result (id from register, slot_ptr from lookup;
;             0 means failure: full registry on register, not-found on lookup)
;   Clobbers: rax, rcx, rdx, rsi
;   Preserves: r12 (instruction pointer), r13 (operand stack),
;              r14 (energy budget), r15, rbx, rbp, rdi
; =============================================================

; --- registry_register_sign ---
; Allocates next sign_id, appends {id, slot_ptr} to sign_registry.
; Input:  rdi = slot_ptr
; Output: rax = sign_id (>=1 on success, 0 if registry full)
registry_register_sign:
    mov     rcx, [rel sign_registry_count]
    cmp     rcx, SIGN_POOL_SLOTS
    jge     .reg_sign_full
    ; Compute entry address: sign_registry + count*16
    mov     rax, rcx
    shl     rax, 4                  ; count * 16
    lea     rsi, [rel sign_registry]
    add     rsi, rax                ; rsi = entry pointer
    ; Allocate id
    mov     rax, [rel sign_registry_next_id]
    mov     [rsi], rax              ; entry.id = next_id
    mov     [rsi + 8], rdi          ; entry.slot_ptr = arg
    ; Bump counters
    inc     qword [rel sign_registry_next_id]
    inc     qword [rel sign_registry_count]
    ; rax already holds the allocated id
    ret
.reg_sign_full:
    xor     rax, rax
    ret

; --- registry_lookup_sign ---
; Linear scan for sign_id; returns slot_ptr or 0 if not found.
; Input:  rdi = sign_id
; Output: rax = slot_ptr (0 if id not found or id == 0)
registry_lookup_sign:
    test    rdi, rdi
    jz      .lookup_sign_null       ; id 0 is reserved as null
    mov     rcx, [rel sign_registry_count]
    test    rcx, rcx
    jz      .lookup_sign_null       ; empty registry
    lea     rsi, [rel sign_registry]
.lookup_sign_loop:
    mov     rax, [rsi]              ; entry.id
    cmp     rax, rdi
    je      .lookup_sign_hit
    add     rsi, 16
    dec     rcx
    jnz     .lookup_sign_loop
.lookup_sign_null:
    xor     rax, rax
    ret
.lookup_sign_hit:
    mov     rax, [rsi + 8]          ; entry.slot_ptr
    ret

; --- registry_register_energy ---
; Mirrors registry_register_sign for energy_registry.
; Input:  rdi = slot_ptr
; Output: rax = energy_id (>=1 on success, 0 if registry full)
registry_register_energy:
    mov     rcx, [rel energy_registry_count]
    cmp     rcx, ENERGY_POOL_SLOTS
    jge     .reg_energy_full
    mov     rax, rcx
    shl     rax, 4
    lea     rsi, [rel energy_registry]
    add     rsi, rax
    mov     rax, [rel energy_registry_next_id]
    mov     [rsi], rax
    mov     [rsi + 8], rdi
    inc     qword [rel energy_registry_next_id]
    inc     qword [rel energy_registry_count]
    ret
.reg_energy_full:
    xor     rax, rax
    ret

; --- registry_lookup_energy ---
; Mirrors registry_lookup_sign for energy_registry.
; Input:  rdi = energy_id
; Output: rax = slot_ptr (0 if id not found or id == 0)
registry_lookup_energy:
    test    rdi, rdi
    jz      .lookup_energy_null
    mov     rcx, [rel energy_registry_count]
    test    rcx, rcx
    jz      .lookup_energy_null
    lea     rsi, [rel energy_registry]
.lookup_energy_loop:
    mov     rax, [rsi]
    cmp     rax, rdi
    je      .lookup_energy_hit
    add     rsi, 16
    dec     rcx
    jnz     .lookup_energy_loop
.lookup_energy_null:
    xor     rax, rax
    ret
.lookup_energy_hit:
    mov     rax, [rsi + 8]
    ret
