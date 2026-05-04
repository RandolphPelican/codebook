; =============================================================
; Outcome — canonical-ID registry for Outcome<T> primitive
; Pod 1.9.2a — substrate plumbing for Outcome<T>
;
; V1.0 ships the registry; opcode handlers land in 1.9.2b.
; Pattern matches boot/registry.asm (Pod 1.8.5b) exactly — same
; calling convention, same linear scan, same null-return-on-not-found
; behavior. Outcome's typed-error semantics (D1.9.1.1-8) layer on
; top of this registry through the 1.9.2b opcode handlers.
;
; Linear scan acceptable for V1.0 — pool capacity is 64.
; Hash-table or btree optimization deferred (DEFERRED #18 from
; Pod 1.8.5b applies here too). Free-list / invalidation deferred
; until OP_OUTCOME_FREE primitive activates (post-V1; DEFERRED #19).
;
; Internal calling convention (matches boot/registry.asm shape):
;   Input:    rdi = arg (slot_ptr for register, id for lookup)
;   Output:   rax = result (id from register, slot_ptr from lookup;
;             0 means failure: full registry on register, not-found on lookup)
;   Clobbers: rax, rcx, rdx, rsi
;   Preserves: r12 (instruction pointer), r13 (operand stack),
;              r14 (energy budget), r15, rbx, rbp, rdi
; =============================================================

; --- registry_register_outcome ---
; Allocates next outcome_id, appends {id, slot_ptr} to outcome_registry.
; Input:  rdi = slot_ptr
; Output: rax = outcome_id (>=1 on success, 0 if registry full)
registry_register_outcome:
    mov     rcx, [rel outcome_registry_count]
    cmp     rcx, OUTCOME_POOL_SLOTS
    jge     .reg_outcome_full
    ; Compute entry address: outcome_registry + count*16
    mov     rax, rcx
    shl     rax, 4                  ; count * 16
    lea     rsi, [rel outcome_registry]
    add     rsi, rax                ; rsi = entry pointer
    ; Allocate id
    mov     rax, [rel outcome_registry_next_id]
    mov     [rsi], rax              ; entry.id = next_id
    mov     [rsi + 8], rdi          ; entry.slot_ptr = arg
    ; Bump counters
    inc     qword [rel outcome_registry_next_id]
    inc     qword [rel outcome_registry_count]
    ; rax already holds the allocated id
    ret
.reg_outcome_full:
    xor     rax, rax
    ret

; --- registry_lookup_outcome ---
; Linear scan for outcome_id; returns slot_ptr or 0 if not found.
; Input:  rdi = outcome_id
; Output: rax = slot_ptr (0 if id not found or id == 0)
registry_lookup_outcome:
    test    rdi, rdi
    jz      .lookup_outcome_null    ; id 0 (OUTCOME_ID_NULL) reserved
    mov     rcx, [rel outcome_registry_count]
    test    rcx, rcx
    jz      .lookup_outcome_null    ; empty registry
    lea     rsi, [rel outcome_registry]
.lookup_outcome_loop:
    mov     rax, [rsi]              ; entry.id
    cmp     rax, rdi
    je      .lookup_outcome_hit
    add     rsi, 16
    dec     rcx
    jnz     .lookup_outcome_loop
.lookup_outcome_null:
    xor     rax, rax
    ret
.lookup_outcome_hit:
    mov     rax, [rsi + 8]          ; entry.slot_ptr
    ret
