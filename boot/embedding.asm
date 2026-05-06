; =============================================================
; Embedding — canonical-ID registry for Embedding typed primitive
; Pod 3 — substrate plumbing for Embedding<f32[384]>
;
; V1.0 ships the typed pool + registry + accessors; semantic operations
; (similarity, lookup-by-meaning, codebook ingestion) deferred to
; Pod 3.5+ per D3.8 substrate-prep mode.
;
; Pattern matches boot/outcome.asm (Pod 1.9.2a) exactly — same calling
; convention, same linear scan, same null-return-on-not-found behavior.
; Embedding's MAC integrity (full vector under SipHash per D3.3) layers
; on top of this registry through the OP_EMBEDDING_NEW handler in
; cbs_vm.asm.
;
; Linear scan acceptable for V1.0 — pool capacity is 64.
; Hash-table or btree optimization deferred (DEFERRED #18 from Pod 1.8.5b
; applies here too). Free-list / invalidation deferred until
; OP_EMBEDDING_FREE primitive activates (post-V1).
;
; Internal calling convention (matches boot/registry.asm shape):
;   Input:    rdi = arg (slot_ptr for register, id for lookup)
;   Output:   rax = result (id from register, slot_ptr from lookup;
;             0 means failure: full registry on register, not-found on lookup)
;   Clobbers: rax, rcx, rdx, rsi
;   Preserves: r12 (instruction pointer), r13 (operand stack),
;              r14 (energy budget), r15, rbx, rbp, rdi
; =============================================================

; --- registry_register_embedding ---
; Allocates next embedding_id, appends {id, slot_ptr} to embedding_registry.
; Input:  rdi = slot_ptr
; Output: rax = embedding_id (>=1 on success, 0 if registry full)
registry_register_embedding:
    mov     rcx, [rel embedding_registry_count]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .reg_embedding_full
    ; Compute entry address: embedding_registry + count*16
    mov     rax, rcx
    shl     rax, 4                  ; count * 16
    lea     rsi, [rel embedding_registry]
    add     rsi, rax                ; rsi = entry pointer
    ; Allocate id
    mov     rax, [rel embedding_registry_next_id]
    mov     [rsi], rax              ; entry.id = next_id
    mov     [rsi + 8], rdi          ; entry.slot_ptr = arg
    ; Bump counters
    inc     qword [rel embedding_registry_next_id]
    inc     qword [rel embedding_registry_count]
    ; rax already holds the allocated id
    ret
.reg_embedding_full:
    xor     rax, rax
    ret

; --- registry_lookup_embedding ---
; Linear scan for embedding_id; returns slot_ptr or 0 if not found.
; Input:  rdi = embedding_id
; Output: rax = slot_ptr (0 if id not found or id == 0)
registry_lookup_embedding:
    test    rdi, rdi
    jz      .lookup_embedding_null  ; id 0 (EMBEDDING_ID_NULL) reserved
    mov     rcx, [rel embedding_registry_count]
    test    rcx, rcx
    jz      .lookup_embedding_null  ; empty registry
    lea     rsi, [rel embedding_registry]
.lookup_embedding_loop:
    mov     rax, [rsi]              ; entry.id
    cmp     rax, rdi
    je      .lookup_embedding_hit
    add     rsi, 16
    dec     rcx
    jnz     .lookup_embedding_loop
.lookup_embedding_null:
    xor     rax, rax
    ret
.lookup_embedding_hit:
    mov     rax, [rsi + 8]          ; entry.slot_ptr
    ret
