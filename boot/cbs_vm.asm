; =============================================================
; CBS VM — Stack Machine + Energy Budgets (V1)
; Engywook's first incarnation. Watches the borders. Knows when they break.
;
; This V1 is a stack machine with energy metering — the proof that
; bytecode can carry a thermodynamic accounting at the opcode level.
; Pod 1 evolves this into the typed evaluator with Sign/Cap/Outcome/
; Energy/Demod as native primitives.
;
; Functions: cbs_run (single entry; all else .local labels)
; Depends:   auryn_putc, auryn_puts, morla_run_file_main,
;            energy_budget, energy_used, vm_stack, vm_vars,
;            vm_ret_stack, vm_ret_ptr, vm_sign_pool,
;            vm_sign_next, vm_energy_pool, vm_energy_next
;            (all in vmdata.asm)
;            energy_cost_lookup, energy_cost_table
;            (in energy_costs.asm)
; Layer:     Layer 1 — Typed CBS VM (V1; reforged in Pod 1)
;
; --- Register allocation (preserve when extending) ---
;   r12 = PC (program counter, points into bytecode)
;   r13 = SP (CBS stack pointer, points into vm_stack)
;   r14 = energy budget (joules remaining for current run)
;   r15 = (freed, Pod 1.8 A4; no cross-handler invariant)
;
; Stack layout:    vm_stack[]  — operand stack, grows up
; Variable layout: vm_vars[]   — addressable slots
; Return stack:    vm_ret_stack[] — function call frames
;
; See kernel/_future/cap_graph.asm for prior art on capability graph
; (Phase 5.1 work, exiled with documented bugs, salvageable for Pod 1).
; =============================================================

; cbs_run: r12 = pointer to bytecode, r14 = energy budget (64-bit)
; Returns when HALT (OP_RET is subroutine return, not VM exit)
; Pod 1.5: all CBS values are 64-bit; positional offsets stay 4-byte signed
cbs_run:
    push    rbx
    push    rbp
    mov     rbp, rsp
    push    rcx
    push    rdx

    lea     r13, [rel vm_stack]     ; VM stack base
    mov     qword [rel energy_used], 0
    mov     qword [rel vm_ret_ptr], 0   ; reset return stack per invocation

    ; Print header
    lea     rsi, [rel str_vm_start]
    call    auryn_puts

.fetch:
    ; Fetch opcode byte
    movzx   eax, byte [r12]
    inc     r12
    ; Pod 1.9.2a D1.9.1.7 — substrate fetch counter for ProvEvent.
    inc     qword [rel vm_fetch_count]
    ; Per-opcode energy cost (Pod 1.8: cost table replaces flat 1j/fetch)
    push    rax                     ; preserve opcode across call
    call    energy_cost_lookup      ; al = opcode byte → rax = joules
    mov     rbx, rax                ; rbx = cost
    pop     rax                     ; restore opcode byte
    ; Bankruptcy check: can we afford this opcode?
    cmp     r14, rbx
    jl      .fatigue
    ; V1.1 per-cap affordability - all checks precede mutation; unsigned cmp
    ; (ENERGY_BUDGET_UNBOUNDED = -1 signed); rax holds live opcode - no calls
    mov     rcx, [rel current_cap_budget_cache]
    mov     rdx, ENERGY_BUDGET_UNBOUNDED
    cmp     rcx, rdx
    je      .cap_afford_ok
    mov     rdx, [rel current_cap_slot_ptr_cache]
    test    rdx, rdx
    jz      .cap_afford_ok
    mov     rdx, [rdx + CAP_OFF_ENERGY_DISPATCHED]
    cmp     rdx, rcx
    jae     .cap_fatigue
    sub     rcx, rdx
    cmp     rcx, rbx
    jb      .cap_fatigue
.cap_afford_ok:
    ; Debit energy
    sub     r14, rbx
    add     [rel energy_used], rbx
    ; Pod 2.1 — Babylon cost stash (R3.2: after cost lookup, before dispatch).
    ; Construction-site spatial-merge reads this to charge ancestors with
    ; the dispatching opcode's cost.
    ; V1.1 - debit current cap via cached slot ptr (0j bookkeeping per D2.2.9)
    mov     rcx, [rel current_cap_slot_ptr_cache]
    test    rcx, rcx
    jz      .cap_debit_skip
    add     [rcx + CAP_OFF_ENERGY_DISPATCHED], rbx
.cap_debit_skip:
    mov     [rel current_dispatch_cost], rbx

    cmp     al, OP_HALT
    je      .op_halt
    cmp     al, OP_PUSH
    je      .op_push
    cmp     al, OP_ADD
    je      .op_add
    cmp     al, OP_SUB
    je      .op_sub
    cmp     al, OP_MUL
    je      .op_mul
    cmp     al, OP_DIV
    je      .op_div
    cmp     al, OP_EQ
    je      .op_eq
    cmp     al, OP_NE
    je      .op_ne
    cmp     al, OP_LT
    je      .op_lt
    cmp     al, OP_GT
    je      .op_gt
    cmp     al, OP_LE
    je      .op_le
    cmp     al, OP_GE
    je      .op_ge
    cmp     al, OP_MOD
    je      .op_mod
    cmp     al, OP_CALL
    je      .op_call
    cmp     al, OP_GRANT_CAP
    je      .op_grant_cap
    cmp     al, OP_USE_CAP
    je      .op_use_cap
    cmp     al, OP_RESERVE
    je      .op_reserve
    cmp     al, OP_RET
    je      .op_ret
    cmp     al, OP_JIF
    je      .op_jif
    cmp     al, OP_JBACK
    je      .op_jback
    cmp     al, OP_LOAD
    je      .op_load
    cmp     al, OP_STORE
    je      .op_store
    cmp     al, OP_PRINT_NUM
    je      .op_print_num
    cmp     al, OP_EMIT
    je      .op_emit
    cmp     al, OP_NEWLINE
    je      .op_newline
    cmp     al, OP_DUP
    je      .op_dup
    cmp     al, OP_DROP
    je      .op_drop
    cmp     al, OP_SWAP
    je      .op_swap
    cmp     al, OP_JMP
    je      .op_jmp
    cmp     al, OP_PUSH_STR
    je      .op_push_str
    cmp     al, OP_PRINT_STR
    je      .op_print_str
    cmp     al, OP_SIGN_NEW
    je      .op_sign_new
    cmp     al, OP_SIGN_HASH
    je      .op_sign_hash
    cmp     al, OP_SIGN_LABEL
    je      .op_sign_label
    cmp     al, OP_SIGN_ENERGY
    je      .op_sign_energy
    cmp     al, OP_ENERGY_NEW
    je      .op_energy_new
    cmp     al, OP_ENERGY_JOULES
    je      .op_energy_joules
    cmp     al, OP_ENERGY_SOURCE_OP
    je      .op_energy_source_op
    cmp     al, OP_ENERGY_FREE
    je      .op_energy_free
    cmp     al, OP_ENERGY_RECOVER
    je      .op_energy_recover
    cmp     al, OP_PHASE_QUERY
    je      .op_phase_query
    cmp     al, OP_OUTCOME_NEW_OK
    je      .op_outcome_new_ok
    cmp     al, OP_OUTCOME_NEW_ERR
    je      .op_outcome_new_err
    cmp     al, OP_OUTCOME_IS_OK
    je      .op_outcome_is_ok
    cmp     al, OP_OUTCOME_UNWRAP_OK
    je      .op_outcome_unwrap_ok
    cmp     al, OP_OUTCOME_UNWRAP_ERR
    je      .op_outcome_unwrap_err
    cmp     al, OP_CAP_NEW
    je      .op_cap_new
    cmp     al, OP_CAP_ENTER
    je      .op_cap_enter
    cmp     al, OP_CAP_EXIT
    je      .op_cap_exit
    cmp     al, OP_CAP_CURRENT
    je      .op_cap_current
    cmp     al, OP_CAP_ARENA
    je      .op_cap_arena
    cmp     al, OP_CAP_OWNER
    je      .op_cap_owner
    ; Pod 2.2 — OP_CAP_RESOURCE (0xB6) retired; replaced by OP_CAP_BITMAP at 0xBA per D2.2.4
    ; Pod 1.10.2b2 — substrate-wide accessors + OP_CAP_PARENT
    cmp     al, OP_SIGN_ARENA
    je      .op_sign_arena
    cmp     al, OP_SIGN_OWNER
    je      .op_sign_owner
    cmp     al, OP_SIGN_CREATOR
    je      .op_sign_creator
    ; Pod 3 — Sign embedding-handle accessor (D3.4 side-table read)
    cmp     al, OP_SIGN_EMBEDDING_HANDLE
    je      .op_sign_embedding_handle
    cmp     al, OP_ENERGY_ARENA
    je      .op_energy_arena
    cmp     al, OP_ENERGY_OWNER
    je      .op_energy_owner
    cmp     al, OP_ENERGY_CREATOR
    je      .op_energy_creator
    cmp     al, OP_OUTCOME_ARENA
    je      .op_outcome_arena
    cmp     al, OP_OUTCOME_OWNER
    je      .op_outcome_owner
    cmp     al, OP_OUTCOME_CREATOR
    je      .op_outcome_creator
    cmp     al, OP_CAP_PARENT
    je      .op_cap_parent
    ; Pod 1.10.3 — Cap metabolic accessors
    cmp     al, OP_CAP_BUDGET
    je      .op_cap_budget
    cmp     al, OP_CAP_USED
    je      .op_cap_used
    ; Pod 2.2 — Cap texture accessor
    cmp     al, OP_CAP_BITMAP
    je      .op_cap_bitmap
    ; Pod 3 — Embedding typed primitive (fifth typed pool; substrate-prep mode)
    cmp     al, OP_EMBEDDING_NEW
    je      .op_embedding_new
    cmp     al, OP_EMBEDDING_ARENA
    je      .op_embedding_arena
    cmp     al, OP_EMBEDDING_OWNER
    je      .op_embedding_owner
    cmp     al, OP_EMBEDDING_CREATOR
    je      .op_embedding_creator
    cmp     al, OP_EMBEDDING_GET_DIM
    je      .op_embedding_get_dim
    ; Pod 3.5 — Maid speaks: semantic operations
    cmp     al, OP_EMBEDDING_SIGN_HANDLE
    je      .op_embedding_sign_handle
    cmp     al, OP_EMBEDDING_COSINE
    je      .op_embedding_cosine
    cmp     al, OP_EMBEDDING_DOT_PRODUCT
    je      .op_embedding_dot_product
    cmp     al, OP_EMBEDDING_L2_DISTANCE
    je      .op_embedding_l2_distance
    cmp     al, OP_EMBEDDING_LOOKUP_TOP1
    je      .op_embedding_lookup_top1
    ; Pod 3.6 — Maid composes: synthesis (forge-tier; D3.25/D3.26/D3.27)
    cmp     al, OP_EMBEDDING_ADD
    je      .op_embedding_add
    cmp     al, OP_EMBEDDING_SUBTRACT
    je      .op_embedding_subtract
    cmp     al, OP_EMBEDDING_SCALE
    je      .op_embedding_scale
    cmp     al, OP_EMBEDDING_NORMALIZE
    je      .op_embedding_normalize
    cmp     al, OP_EMBEDDING_LERP
    je      .op_embedding_lerp
    cmp     al, OP_EMBEDDING_SYNTHESIS_HANDLE
    je      .op_embedding_synthesis_handle
    ; Pod 3.8 — codebook-tier (Q5 0xF0-0xFE row; D3.31)
    ; OP_EMBEDDING_IMPORT (0xF0) handler lands at Pod 3.8.F (paired with
    ; build.sh codebook integration). 0xF1 IMPORTED_HANDLE accessor here.
    cmp     al, OP_EMBEDDING_IMPORTED_HANDLE
    je      .op_embedding_imported_handle
    ; Pod 3.9 — Maid finds many: top-K + threshold (D3.35; 0xF2 in embedding-tier-extensions row)
    cmp     al, OP_EMBEDDING_LOOKUP_TOP_K
    je      .op_embedding_lookup_top_k
    ; Pod 3.10 — Maid orthogonalizes: project + reject (D3.38; 0xF3/0xF4 in embedding-tier-extensions row)
    cmp     al, OP_EMBEDDING_PROJECT
    je      .op_embedding_project
    cmp     al, OP_EMBEDDING_REJECT
    je      .op_embedding_reject
    ; Pod 3.11 — Maid maintains: codebook metadata witness (D3.42; 0xF5 in embedding-tier-extensions row)
    cmp     al, OP_EMBEDDING_CODEBOOK_META
    je      .op_embedding_codebook_meta

    ; Unknown opcode
    lea     rsi, [rel str_vm_unk]
    call    auryn_puts
    movzx   edi, al
    call    print_hex32
    lea     rsi, [rel str_nl]
    call    auryn_puts
    jmp     .done

.cap_fatigue:
    ; V1.1 - cap bankruptcy. No Outcome::Err: the fetch loop is not at an
    ; Outcome boundary and arbitrary opcodes have no error path. Deterministic
    ; death, named cap. Banner is 0j (off-ledger, post-decision).
    lea     rsi, [rel str_vm_cap_deg]
    call    auryn_puts
    mov     edi, [rel current_cap_id]
    call    print_hex32
    lea     rsi, [rel str_nl]
    call    auryn_puts
    jmp     .done

.fatigue:
    lea     rsi, [rel str_vm_deg]
    call    auryn_puts
    jmp     .done

; --- PUSH imm64 ---
.op_push:
    mov     rax, [r12]
    add     r12, 8
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- Arithmetic (pop b, pop a, push result) — 64-bit (Pod 1.5) ---
.op_add:
    sub     r13, 8
    mov     rbx, [r13]      ; b
    sub     r13, 8
    mov     rax, [r13]      ; a
    add     rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_sub:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    sub     rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_mul:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    imul    rax, rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_mod:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    test    rbx, rbx
    jz      .mod_zero
    xor     rdx, rdx
    div     rbx
    mov     [r13], rdx
    add     r13, 8
    jmp     .fetch
.mod_zero:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.op_div:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    test    rbx, rbx
    jz      .div_zero
    cqo
    idiv    rbx
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.div_zero:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

; --- Comparisons — 64-bit (Pod 1.5) ---
.op_eq:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    sete    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_ne:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setne   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_lt:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setl    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_gt:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setg    al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_le:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setle   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_ge:
    sub     r13, 8
    mov     rbx, [r13]
    sub     r13, 8
    mov     rax, [r13]
    cmp     rax, rbx
    setge   al
    movzx   eax, al
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- RESERVE energy (64-bit operand, Pod 1.5) ---
.op_reserve:
    mov     rax, [r12]
    add     r12, 8
    cmp     r14, rax
    jl      .reserve_fail
    sub     r14, rax
    ; r15 freed (Pod 1.8 A4); energy tracking via [rel energy_used]
    ; Print reservation
    push    rax
    lea     rsi, [rel str_vm_rsv]
    call    auryn_puts
    pop     rdi
    call    print_dec
    lea     rsi, [rel str_vm_jok]
    call    auryn_puts
    jmp     .fetch
.reserve_fail:
    lea     rsi, [rel str_vm_deg]
    call    auryn_puts
    ; Skip to HALT (OP_RET is subroutine return, not terminator)
.skip_to_end:
    movzx   eax, byte [r12]
    inc     r12
    cmp     al, OP_HALT
    je      .op_halt
    ; Skip operands for known opcodes
    ; Value operands: 8 bytes (Pod 1.5 widened)
    cmp     al, OP_PUSH
    je      .skip8
    cmp     al, OP_RESERVE
    je      .skip8
    ; Positional operands: 4 bytes (D1)
    cmp     al, OP_JIF
    je      .skip4
    cmp     al, OP_JBACK
    je      .skip4
    cmp     al, OP_JMP
    je      .skip4
    cmp     al, OP_LOAD
    je      .skip4
    cmp     al, OP_STORE
    je      .skip4
    cmp     al, OP_PUSH_STR
    je      .skip_str
    jmp     .skip_to_end
.skip8:
    add     r12, 8
    jmp     .skip_to_end
.skip4:
    add     r12, 4
    jmp     .skip_to_end
.skip_str:
    movzx   eax, word [r12]
    add     r12, 2
    add     r12, rax
    mov     ecx, eax
    and     ecx, 3
    jz      .skip_to_end
    mov     edx, 4
    sub     edx, ecx
    add     r12, rdx
    jmp     .skip_to_end

; --- RET (subroutine return — pops vm_ret_stack) ---
; Pod 1.3: OP_RET is now a proper subroutine return.
; VM exit is OP_HALT. Underflow = halt-on-violation (Pod 1.7 replaces
; with typed Outcome).
.op_ret:
    lea     rax, [rel vm_ret_ptr]
    mov     rcx, [rax]
    test    rcx, rcx
    jz      .ret_underflow          ; empty return stack = violation
    dec     rcx
    mov     [rax], rcx              ; update vm_ret_ptr
    shl     rcx, 3
    lea     rdx, [rel vm_ret_stack]
    mov     r12, [rdx + rcx]        ; restore PC from return stack
    jmp     .fetch

.ret_underflow:
    ; Pod 1.9.3 D1.9.3.2 (Pre-A2 option b): tag-the-halt-with-typed-context.
    ; Construct Err Outcome before existing diagnostic emit + halt.
    ; The Err is observable on operand stack at halt time (post-mortem).
    mov     rdi, ERR_STACK_UNDERFLOW
    mov     rsi, OP_RET
    xor     rdx, rdx                ; demod_id
    xor     rcx, rcx                ; fetch_counter (no user supplied at violation)
    mov     r8, TYPE_CODE_NONE      ; D1.9.3.3: stack violations have no expected-T
    call    .construct_err_outcome
    mov     [r13], rax              ; push outcome_id (or 0 if Outcome pool full)
    add     r13, 8
    ; Existing diagnostic + halt preserved
    lea     rsi, [rel str_ret_underflow]
    call    auryn_puts
    jmp     .done

; --- JUMP_IF_FALSE (4-byte signed offset per D1, movsxd per D2) ---
.op_jif:
    movsxd  rax, dword [r12] ; offset (signed, 4-byte per D1)
    add     r12, 4
    sub     r13, 8
    mov     rbx, [r13]       ; condition (64-bit value)
    test    rbx, rbx
    jnz     .fetch            ; not zero = true, don't jump
    add     r12, rax          ; jump forward by offset
    jmp     .fetch

; --- JUMP_BACK (4-byte signed offset per D1, movsxd per D2) ---
.op_jback:
    movsxd  rax, dword [r12]
    add     r12, 4
    sub     r12, rax          ; jump backward
    jmp     .fetch

; --- LOAD var (index 4-byte per D1, value 64-bit, vm_vars qword slots) ---
.op_load:
    movsxd  rax, dword [r12]
    add     r12, 4
    lea     rbx, [rel vm_vars]
    mov     rax, [rbx + rax*8]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- STORE var (index 4-byte per D1, value 64-bit, vm_vars qword slots) ---
.op_store:
    movsxd  rax, dword [r12]
    add     r12, 4
    sub     r13, 8
    mov     rbx, [r13]
    lea     rcx, [rel vm_vars]
    mov     [rcx + rax*8], rbx
    jmp     .fetch

.op_grant_cap:
    ; Pop resource ID
    sub     r13, 8
    mov     rax, [r13]
    ; Simple: token = ID + 0xCA000000
    add     eax, 0xCA000000
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch


.cap_atreyu:
    cmp     rcx, 1
    je      .atreyu_get_size
    cmp     rcx, 2
    je      .atreyu_set_size
    cmp     rcx, 3
    je      .atreyu_get_char
    cmp     rcx, 4
    je      .atreyu_set_char
    cmp     rcx, 5
    je      .atreyu_insert
    cmp     rcx, 6
    je      .atreyu_delete
    jmp     .fetch

.atreyu_get_size:
    mov     rax, [rel atreyu_size]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.atreyu_set_size:
    sub     r13, 8
    mov     rax, [r13]
    mov     [rel atreyu_size], rax
    jmp     .fetch

.atreyu_get_char:
    sub     r13, 8
    mov     rax, [r13] ; pos
    lea     rbx, [rel external_prog_buf]
    movzx   rax, byte [rbx + rax]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.atreyu_set_char:
    sub     r13, 8
    mov     rax, [r13] ; char
    sub     r13, 8
    mov     rbx, [r13] ; pos
    lea     rcx, [rel external_prog_buf]
    mov     [rcx + rbx], al
    jmp     .fetch

.atreyu_insert:
    ; Pop char, then pos
    sub     r13, 8
    mov     rax, [r13] ; char
    sub     r13, 8
    mov     rbx, [r13] ; pos

    ; Shift right: from atreyu_size down to pos
    mov     rcx, [rel atreyu_size]
    lea     rdx, [rel external_prog_buf]
.atreyu_ins_loop:
    cmp     rcx, rbx
    jle     .atreyu_ins_done
    mov     dl, [rdx + rcx - 1]
    mov     [rdx + rcx], dl
    dec     rcx
    jmp     .atreyu_ins_loop
.atreyu_ins_done:
    mov     [rdx + rbx], al
    inc     qword [rel atreyu_size]
    jmp     .fetch

.atreyu_delete:
    sub     r13, 8
    mov     rbx, [r13] ; pos

    ; Shift left: from pos+1 up to atreyu_size
    mov     rcx, rbx
    lea     rdx, [rel external_prog_buf]
.atreyu_del_loop:
    mov     rax, rcx
    inc     rax
    cmp     rax, [rel atreyu_size]
    jge     .atreyu_del_done
    mov     al, [rdx + rcx + 1]
    mov     [rdx + rcx], al
    inc     rcx
    jmp     .atreyu_del_loop
.atreyu_del_done:
    dec     qword [rel atreyu_size]
    jmp     .fetch

.cap_rockbiter:
    cmp     rcx, 1
    je      .get_energy_budget
    cmp     rcx, 2
    je      .get_energy_used
    jmp     .fetch
.get_energy_budget:
    mov     rax, [rel energy_budget]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.get_energy_used:
    mov     rax, [rel energy_used]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_use_cap:
    ; Pop token, then cmd
    sub     r13, 8
    mov     rax, [r13]      ; token
    sub     r13, 8
    mov     rcx, [r13]      ; cmd

    mov     rdx, 0xCA000001 ; AURYN_DISPLAY
    cmp     rax, rdx
    je      .cap_auryn
    mov     rdx, 0xCA000002 ; GMORK_CONIN
    cmp     rax, rdx
    je      .cap_conin
    mov     rdx, 0xCA000003 ; MORLA_FS
    cmp     rax, rdx
    je      .cap_morla
    mov rdx, 0xCA000004 ; ROCKBITER
    cmp     rax, rdx
    je      .cap_rockbiter

    ; Invalid cap
    lea     rsi, [rel str_vm_unk]
    call    auryn_puts
    jmp     .fetch

.cap_auryn:
    cmp     rcx, 1
    je      .auryn_putc
    cmp     rcx, 2
    je      .auryn_fill
    jmp     .fetch
.auryn_putc:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_putc
    jmp     .fetch
.auryn_fill:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_fill
    jmp     .fetch

.cap_conin:
    cmp     rcx, 1
    je      .conin_read
    jmp     .fetch
.conin_read:
    call    native_keyboard_read
    test    rax,rax
    jnz     .conin_none
    movzx   eax,word [rel key_data+2] ; UnicodeChar
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.conin_none:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.cap_morla:
    cmp     rcx, 1
    je      .morla_ls
    cmp     rcx, 2
    je      .morla_write
    jmp     .fetch
.morla_ls:
    call    morla_ls
    jmp     .fetch
.morla_write:
    ; Pop filename_ref, buffer_ref, size
    sub     r13, 8
    mov     rdx, [r13]      ; size
    sub     r13, 8
    mov     rsi, [r13]      ; buffer (ref)
    sub     r13, 8
    mov     rdi, [r13]      ; filename (ref)
    call    morla_write_file
    jmp     .fetch


.op_print_num:
    sub     r13, 8
    mov     rdi, [r13]
    call    print_sdec
    jmp     .fetch

.op_emit:
    sub     r13, 8
    mov     edi, [r13]
    call    auryn_putc
    jmp     .fetch

.op_newline:
    mov     edi, 10
    call    auryn_putc
    jmp     .fetch

; --- Stack ops (64-bit values, Pod 1.5) ---
.op_dup:
    mov     rax, [r13 - 8]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_drop:
    sub     r13, 8
    jmp     .fetch

.op_swap:
    mov     rax, [r13 - 8]
    mov     rbx, [r13 - 16]
    mov     [r13 - 16], rax
    mov     [r13 - 8], rbx
    jmp     .fetch

; --- CALL (pop signed offset, save return addr, jump) ---
; Pod 1.3: target is PC-relative offset (matching OP_JMP convention).
; Pre-1.3 used absolute address but no program ever exercised it.
; Overflow = halt-on-violation (Pod 1.7 replaces with typed Outcome).
.op_call:
    ; Bounds check: is vm_ret_stack full?
    lea     rbx, [rel vm_ret_ptr]
    mov     rcx, [rbx]
    cmp     rcx, 256
    jge     .call_overflow
    ; Save current r12 (return address) to vm_ret_stack
    mov     rax, rcx
    shl     rax, 3
    lea     rdx, [rel vm_ret_stack]
    mov     [rdx + rax], r12
    inc     qword [rbx]
    ; Pop offset from operand stack (qword after Pod 1.5 widening), jump PC-relative
    sub     r13, 8
    mov     rax, [r13]
    add     r12, rax
    jmp     .fetch

.call_overflow:
    ; Pod 1.9.3 D1.9.3.2 (Pre-A2 option b): tag-the-halt-with-typed-context.
    ; Note: r13 still has the call_offset from operand stack (OP_CALL bounds check
    ; fired before the offset pop). Err outcome_id pushed on top of it; post-mortem
    ; sees [..., call_offset, outcome_id]. Both visible.
    mov     rdi, ERR_STACK_OVERFLOW
    mov     rsi, OP_CALL
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_NONE
    call    .construct_err_outcome
    mov     [r13], rax              ; push outcome_id
    add     r13, 8
    ; Existing diagnostic + halt preserved
    lea     rsi, [rel str_call_overflow]
    call    auryn_puts
    jmp     .done

.op_dup2:
    sub     r13, 16
    mov     rax, [r13]
    mov     rbx, [r13 + 8]
    mov     [r13 + 16], rax
    mov     [r13 + 24], rbx
    add     r13, 32
    jmp     .fetch

.op_jmp:
    movsxd  rax, dword [r12]
    add     r12, 4
    add     r12, rax
    jmp     .fetch

; --- PUSH_STR (2-byte len + raw bytes + pad to 4-align) ---
; Pushes the ADDRESS of the string data onto the VM stack
; The string bytes live inline in the bytecode
.op_push_str:
    movzx   eax, word [r12]     ; string length
    add     r12, 2              ; skip length field
    mov     [r13], r12          ; push pointer to string data
    mov     [r13 + 8], eax      ; push length in next slot
    add     r13, 16             ; advance VM stack by 2 slots (ptr + len)
    add     r12, rax            ; skip string bytes
    ; Pad to 4-byte alignment
    mov     ecx, eax
    and     ecx, 3
    jz      .ps_nopad
    mov     edx, 4
    sub     edx, ecx
    add     r12, rdx
.ps_nopad:
    jmp     .fetch

; --- PRINT_STR (pop string ptr+len from stack, print chars) ---
.op_print_str:
    sub     r13, 16             ; pop len + ptr
    mov     ecx, [r13 + 8]     ; length
    mov     rsi, [r13]          ; pointer to string data
    ; Print each byte as a character
    test    ecx, ecx
    jz      .pstr_done
.pstr_loop:
    movzx   edi, byte [rsi]
    test    dil, dil
    jz      .pstr_done
    call    auryn_putc
    inc     rsi
    dec     ecx
    jnz     .pstr_loop
.pstr_done:
    jmp     .fetch

; --- Sign typed primitive (Pod 1.7; canonical-ID retrofit Pod 1.8.5b; arena/owner retrofit Pod 1.8.5c) ---
; D1.7.6 energy costs are placeholders; Pod 1.8 supersedes.
; vm_sign_alloc inherits cap_alloc_node shape (Pod 0.9) with 64-bit
; width discipline (rcx/rax/qword, not ecx/eax/dword).
;
; Sign slot layout (128 bytes, SIGN_SLOT_SIZE):
;   +0x00 hash[32]              — full content hash
;   +0x20 label[64]             — byte 0 = length, bytes 1-63 = chars
;   +0x60 energy_cost (u64)
;   +0x68 embedding_handle (u64) — V1.0 = 0; reserved for handle pools (Pod 3+)
;   +0x70 arena_id (u64)        — Pod 1.8.5c Move 3; V1.0 = 0 (single global arena;
;                                 Pod 1.10 Cap introduces real arenas);
;                                 reclaimed from former provenance_handle slot per A1(d)
;   +0x78 owner_demod_id (u64)  — Pod 1.8.5c Move 3; V1.0 = 0 (no demod ownership tracking;
;                                 Pod 1.12 Demod introduces real ownership);
;                                 reclaimed from former V1.1 sentinel slot per A1(d)
;
; OP_SIGN_NEW signature preserved at 5 args (Pod 1.8.5c S6 decision):
; the topmost arg (formerly provenance_handle, validated as 0) is now
; silently discarded. ABI unchanged for callers; field at +0x70 reclaimed
; for arena_id under Move 3.

.op_sign_new:
    ; Energy: handled by fetch-loop cost table (Pod 1.8)
    ; Pop 5 args: <ignored>, embedding_handle, energy_cost,
    ;             label_addr, hash_addr (top-down).
    ; Pod 1.8.5c S6/A1(d): the topmost arg (formerly provenance_handle)
    ; is silently discarded; the slot at +0x70 is reclaimed for arena_id.
    ; ABI preserved at 5 args; callers do not need updating.
    sub     r13, 8
    mov     r8, [r13]           ; (formerly provenance_handle; now ignored)
    sub     r13, 8
    mov     r9, [r13]           ; embedding_handle
    sub     r13, 8
    mov     r10, [r13]          ; energy_cost
    sub     r13, 8
    mov     r11, [r13]          ; label_addr
    sub     r13, 8
    mov     rbx, [r13]          ; hash_addr
    ; Pod 2.2 — bit-check: current_cap must carry BIT_SIGN_FORGE per D2.2.6
    push    rbx
    push    r11
    push    r10
    push    r9
    push    r8
    mov     rdi, BIT_SIGN_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     r8
    pop     r9
    pop     r10
    pop     r11
    pop     rbx
    jnz     .sign_new_insufficient_authority
    ; Validate label length <= 63 (A4)
    movzx   eax, byte [r11]
    cmp     eax, 63
    ja      .sign_new_fail_invalid_arg
    ; Pod 3 — embedding_handle validation (D3.4 / DEFERRED #65 resolution).
    ; Pre-Pod-3: rejected non-zero (handle pools didn't exist).
    ; Pod 3: zero = no embedding linked (backward-compat); non-zero = typed
    ; embedding_id reference, validated via registry_lookup_embedding.
    test    r9, r9
    jz      .sign_new_embedding_check_done   ; 0: skip validation
    push    rbx
    push    r11
    push    r10
    push    r9
    push    r8
    mov     rdi, r9
    call    registry_lookup_embedding
    pop     r8
    pop     r9
    pop     r10
    pop     r11
    pop     rbx
    test    rax, rax
    jz      .sign_new_invalid_embedding      ; non-zero but unresolvable → ERR_INVALID_ID
.sign_new_embedding_check_done:
    ; (provenance_handle check removed Pod 1.8.5c; field reclaimed for arena_id)
    ; Allocate pool slot
    call    .sign_alloc
    test    rax, rax
    jz      .sign_new_fail_pool_full
    ; rax = slot pointer; rcx (bump-index sign_id) discarded under Move 4
    push    rax                 ; save slot_ptr across memcpy + register
    ; Copy hash (32 bytes) from hash_addr to slot+0x00
    mov     rdi, rax            ; dest = slot base
    mov     rsi, rbx            ; src = hash_addr
    mov     rcx, 32
    cld
    rep     movsb
    ; Copy label (64 bytes) from label_addr to slot+0x20
    ; rdi already at slot+0x20 after 32-byte copy
    mov     rsi, r11            ; src = label_addr
    mov     rcx, 64
    rep     movsb
    ; rdi now at slot+0x60; write remaining fields
    mov     [rdi], r10          ; energy_cost at +0x60
    ; Pod 1.10.2b2 retrofit — slot at +0x68 reclaimed from embedding_handle
    ; for creator_cap_id (Pod 1.8.5c reclamation pattern continued).
    ; arena_id and owner_demod_id read from substrate state per D1.10.1.8.
    mov     rax, [rel current_cap_id]
    mov     [rdi + 8], rax      ; creator_cap_id at +0x68 (was embedding_handle, now reclaimed)
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rdi + 16], rax     ; arena_id at +0x70 (D1.10.1.8 retrofit)
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rdi + 24], rax     ; owner_demod_id at +0x78 (D1.10.1.8 retrofit)
    ; Pod 1.8.5b Move 4: register slot in canonical-ID registry.
    pop     rdi                 ; restore slot_ptr as registry input
    call    registry_register_sign
    test    rax, rax
    jz      .sign_new_fail_pool_full   ; registry full (capacities matched, should not occur in V1.0)
    ; Pod 3 — write embedding_handle to side-table at index (sign_id - 1) per D3.4.
    ; r9 holds embedding_handle (preserved through .sign_alloc + rep movsb +
    ; registry_register_sign — none of those touch r9). Side-table indexing:
    ; vm_sign_embedding_handle[sign_id - 1]; sign_ids are 1-based per registry.
    push    rax                                 ; preserve sign_id across calc
    mov     rcx, rax
    dec     rcx                                 ; rcx = sign_id - 1
    lea     rdx, [rel vm_sign_embedding_handle]
    mov     [rdx + rcx*8], r9                   ; write embedding_handle to side-table
    pop     rax                                 ; restore sign_id
    ; Pod 3.5 — D3.20 reverse side-table conditional store.
    ; If embedding_handle != 0 (Sign created with linked Embedding), record
    ; reverse linkage: vm_embedding_sign_handle[embedding_handle - 1] = sign_id.
    ; r9 holds embedding_handle through this point (siphash inside
    ; .construct_ok_outcome will clobber r9; reverse-write must precede wrap).
    test    r9, r9
    jz      .sign_new_skip_reverse_link
    mov     rcx, r9
    dec     rcx                                 ; rcx = embedding_handle - 1
    lea     rdx, [rel vm_embedding_sign_handle]
    mov     [rdx + rcx*8], rax                  ; write sign_id to reverse side-table
.sign_new_skip_reverse_link:
    ; Pod 2.2 Path A retrofit (D2.2.7) — wrap sign_id in Outcome::Ok via helper.
    ; .construct_ok_outcome internally fires babylon_charge_lineage for spatial-
    ; merge per D2.1; single fire site for the originating cap's lineage.
    ; Pod 2.1's handler-explicit babylon fire was removed at this retrofit to
    ; avoid double-fire; substrate axiom "every successful primitive
    ; construction fires babylon" relocates to .construct_ok_outcome boundary.
    mov     rdi, rax                            ; value = sign_id
    mov     r8, TYPE_CODE_SIGN
    call    .construct_ok_outcome
    mov     [r13], rax                          ; push outcome_id
    add     r13, 8
    jmp     .fetch
; Pod 1.9.3 A2: split fail labels with distinguished err_codes.
.sign_new_fail_invalid_arg:
    ; Err(InvalidSignArg, source_op=OP_SIGN_NEW, value_type_id=TYPE_CODE_SIGN)
    mov     rdi, ERR_INVALID_SIGN_ARG
    mov     rsi, OP_SIGN_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.sign_new_fail_pool_full:
    ; Err(PoolFull, source_op=OP_SIGN_NEW, value_type_id=TYPE_CODE_SIGN)
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_SIGN_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
; Pod 2.2 (D2.2.6) — bit-check failure: current_cap lacks BIT_SIGN_FORGE.
.sign_new_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_SIGN_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
; Pod 3 (D3.4) — embedding_handle non-zero but unresolvable via registry.
.sign_new_invalid_embedding:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_SIGN_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_sign_hash:
    ; Energy: handled by fetch-loop cost table (Pod 1.8)
    ; Pod 1.8.5b Move 4: resolve sign_id via registry indirection.
    ; Pop sign_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_sign    ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .sign_hash_null
    mov     rbx, rax                ; slot_ptr in rbx (matches downstream layout)
    ; Push 4 slots (32 bytes of hash, low-to-high)
    mov     rax, [rbx]
    mov     [r13], rax
    mov     rax, [rbx + 8]
    mov     [r13 + 8], rax
    mov     rax, [rbx + 16]
    mov     [r13 + 16], rax
    mov     rax, [rbx + 24]
    mov     [r13 + 24], rax
    add     r13, 32
    jmp     .fetch
.sign_hash_null:
    mov     qword [r13], 0
    mov     qword [r13 + 8], 0
    mov     qword [r13 + 16], 0
    mov     qword [r13 + 24], 0
    add     r13, 32
    jmp     .fetch

.op_sign_label:
    ; Energy: handled by fetch-loop cost table (Pod 1.8)
    ; Pod 1.8.5b Move 4: resolve sign_id via registry indirection.
    ; Pop sign_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_sign    ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .sign_label_null
    mov     rbx, rax
    ; Label at slot+0x20: byte 0 = length, bytes 1-63 = chars
    ; Push (addr of chars, length) — matches PUSH_STR/PRINT_STR convention
    lea     rax, [rbx + 0x21]      ; pointer to char data (skip length byte)
    mov     [r13], rax
    movzx   eax, byte [rbx + 0x20] ; length from byte 0
    mov     [r13 + 8], rax
    add     r13, 16
    jmp     .fetch
.sign_label_null:
    mov     qword [r13], 0
    mov     qword [r13 + 8], 0
    add     r13, 16
    jmp     .fetch

.op_sign_energy:
    ; Energy: handled by fetch-loop cost table (Pod 1.8)
    ; Pod 1.8.5b Move 4: resolve sign_id via registry indirection.
    ; Pod 1.9.3 (D1.9.3.5): both paths construct Outcome<u64>.
    ; Per-opcode cost (5j) covers either path; handler internal Outcome
    ; construction is free relative to flat cost-table accounting.
    ; Pop sign_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_sign    ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .sign_energy_invalid_id
    mov     rbx, rax
    ; energy_cost at slot+0x60 — wrap in Ok outcome
    mov     rdi, [rbx + 0x60]       ; value = energy_cost
    mov     r8, TYPE_CODE_SIGN
    call    .construct_ok_outcome
    mov     [r13], rax              ; push outcome_id
    add     r13, 8
    jmp     .fetch
.sign_energy_invalid_id:
    ; Pod 1.9.3 — push Err(InvalidId, source_op=OP_SIGN_ENERGY, value_type_id=TYPE_CODE_SIGN)
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_SIGN_ENERGY
    xor     rdx, rdx                ; demod_id (current_demod placeholder = 0)
    xor     rcx, rcx                ; fetch_counter (no user supplied)
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    ; rax = outcome_id (or 0 if Outcome pool full — same sentinel shape as legacy)
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- Energy typed primitive (Pod 1.8; arena/owner retrofit Pod 1.8.5c) ---
; Energy slot layout (128 bytes, ENERGY_SLOT_SIZE):
;   +0x00 joules (u64)            — ENERGY_OFF_JOULES
;   +0x08 source_op (u64)         — ENERGY_OFF_SOURCE_OP
;   +0x10 arena_id (u64)          — Pod 1.8.5c Move 3; V1.0 = 0 (Pod 1.10 Cap)
;   +0x18 owner_demod_id (u64)    — Pod 1.8.5c Move 3; V1.0 = 0 (Pod 1.12 Demod)
;   +0x20-0x7F reserved (96 bytes) — explicitly zeroed at construction
; Energy: handled by fetch-loop cost table.

.op_energy_new:
    ; Pop source_op (u64), then joules (u64) — top-down
    sub     r13, 8
    mov     rbx, [r13]              ; source_op
    sub     r13, 8
    mov     rcx, [r13]              ; joules
    ; Pod 2.2 — bit-check: current_cap must carry BIT_ENERGY_FORGE per D2.2.6
    push    rcx                                 ; preserve joules (helper clobbers rcx)
    mov     rdi, BIT_ENERGY_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     rcx
    jnz     .energy_new_insufficient_authority
    ; Allocate pool slot
    call    .energy_alloc
    test    rax, rax
    jz      .energy_new_fail
    ; rax = slot pointer; rdx (bump-index energy_id) discarded under Move 4
    mov     [rax + ENERGY_OFF_JOULES], rcx      ; joules at +0x00
    mov     [rax + ENERGY_OFF_SOURCE_OP], rbx   ; source_op at +0x08
    ; Pod 1.10.2b2 retrofit per D1.10.1.8 — arena/owner from substrate caches;
    ; creator_cap_id at +0x20 (first qword of former reserved zone).
    mov     rcx, [rel current_cap_arena_id_cache]
    mov     [rax + 0x10], rcx                   ; arena_id (Move 3 retrofit)
    mov     rcx, [rel current_cap_owner_demod_id_cache]
    mov     [rax + 0x18], rcx                   ; owner_demod_id (Move 3 retrofit)
    mov     rcx, [rel current_cap_id]
    mov     [rax + ENERGY_OFF_CREATOR_CAP_ID], rcx ; creator_cap_id at +0x20
    ; Zero remaining reserved area (88 bytes at +0x28; was 96 at +0x20 pre-retrofit)
    push    rax                                 ; save slot_ptr across stosq + register
    lea     rdi, [rax + 0x28]
    xor     eax, eax
    mov     rcx, 11                             ; 11 * 8 = 88 bytes
    rep     stosq
    pop     rdi                     ; restore slot_ptr as registry input
    ; Pod 1.8.5b Move 4: register slot in canonical-ID registry.
    call    registry_register_energy
    test    rax, rax
    jz      .energy_new_fail        ; registry full (capacities matched, should not occur in V1.0)
    ; Pod 2.2 Path A retrofit (D2.2.7) — wrap energy_id in Outcome::Ok via helper.
    ; .construct_ok_outcome internally fires babylon_charge_lineage; single fire
    ; site per D2.2.7. Pod 2.1's handler-explicit babylon fire removed.
    mov     rdi, rax                            ; value = energy_id
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_ok_outcome
    mov     [r13], rax                          ; push outcome_id
    add     r13, 8
    jmp     .fetch
; Pod 1.9.3 A3: single fail label, ERR_POOL_FULL only
; (joules/source_op not validated yet; ERR_INVALID_ENERGY_ARG defined but unused).
.energy_new_fail:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_ENERGY_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
; Pod 2.2 (D2.2.6) — bit-check failure: current_cap lacks BIT_ENERGY_FORGE.
.energy_new_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_ENERGY_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_energy_joules:
    ; Pod 1.8.5b Move 4: resolve energy_id via registry indirection.
    ; Pod 1.9.3 (D1.9.3.5): both paths construct Outcome<u64>.
    ; Pop energy_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_energy  ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .energy_joules_invalid_id
    mov     rbx, rax
    ; Read joules at +0x00 — wrap in Ok outcome
    mov     rdi, [rbx + ENERGY_OFF_JOULES]
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.energy_joules_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_ENERGY_JOULES
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_energy_source_op:
    ; Pod 1.8.5b Move 4: resolve energy_id via registry indirection.
    ; Pod 1.9.3 (D1.9.3.5): both paths construct Outcome<u64>.
    ; Pop energy_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_energy  ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .energy_source_op_invalid_id
    mov     rbx, rax
    ; Read source_op at +0x08 — wrap in Ok outcome
    mov     rdi, [rbx + ENERGY_OFF_SOURCE_OP]
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.energy_source_op_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_ENERGY_SOURCE_OP
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_energy_free:
    ; V1.0 no-op: consume stack arg but don't modify pool state.
    ; V1.1+ activates free-list recycling here.
    sub     r13, 8                  ; pop energy_id (discard)
    jmp     .fetch

; --- Pod 1.8.5c Move 6: OP_ENERGY_RECOVER (0xD4) ---
; V1.0 no-op-with-log. Pod 2 (Cop) implements the recovery curve.
; Stack effect: pop 1 u64 (recovery argument; shape TBD by Pod 2);
; push nothing.
.op_energy_recover:
    sub     r13, 8                  ; pop recovery argument (discard V1.0)
    lea     rsi, [rel str_op_energy_recover_noop]
    call    auryn_puts
    jmp     .fetch

; --- Pod 1.8.5c Move 7: OP_PHASE_QUERY (0xD5) ---
; Push current vm_phase (u64) onto operand stack.
.op_phase_query:
    mov     rax, [rel vm_phase]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; ============================================================
; Outcome typed primitive (Pod 1.9.2b — D1.9.1.1-8 + D1.9.2b.1-6)
; ============================================================
; Outcome slot layout (128 bytes, OUTCOME_SLOT_SIZE):
;   +0x00 discriminant (u64)        — 0=ok, 1=err
;   +0x08 value_type_id (u64)       — TYPE_CODE_* per D1.9.1.1
;   +0x10 value (u64)               — canonical ID of success value (ok); 0 if err
;   +0x18 reserved (u64)            — Pod 3+ handle pool extension
;   +0x20 err_code (u64)            — D1.9.1.2 err context; unused if ok
;   +0x28 err_source_op (u64)
;   +0x30 err_demod_id (u64)
;   +0x38 err_fetch_counter (u64)   — program-domain (A1 bifurcation)
;   +0x40-+0x6F reserved (48 bytes) — Pod 3+ message handle, etc.
;   +0x70 arena_id (u64)            — Move 3 inheritance; V1.0 = 0
;   +0x78 owner_demod_id (u64)      — Move 3 inheritance; V1.0 = 0

; --- OP_OUTCOME_NEW_OK (0xE0) ---
; Pop value, pop value_type_id; push outcome_id.
.op_outcome_new_ok:
    sub     r13, 8
    mov     r10, [r13]              ; value (TOS)
    sub     r13, 8
    mov     r11, [r13]              ; value_type_id
    ; Pod 2.2 — bit-check: current_cap must carry BIT_OUTCOME_FORGE per D2.2.6
    push    r11
    push    r10
    mov     rdi, BIT_OUTCOME_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     r10
    pop     r11
    jnz     .outcome_new_ok_insufficient_authority
    call    .outcome_alloc
    test    rax, rax
    jz      .outcome_new_ok_fail
    mov     rbx, rax                ; slot_ptr (rbx preserved across registry call)
    ; Write named fields
    mov     qword [rbx + 0x00], 0   ; discriminant = ok
    mov     [rbx + 0x08], r11       ; value_type_id
    mov     [rbx + 0x10], r10       ; value
    mov     qword [rbx + 0x18], 0   ; reserved
    ; Zero +0x20 through +0x7F (12 qwords = 96 bytes; covers err fields,
    ; Pod 3+ reserved, arena_id, owner_demod_id, creator_cap_id)
    lea     rdi, [rbx + 0x20]
    xor     eax, eax
    mov     rcx, 12
    rep     stosq
    ; Pod 1.10.2b2 retrofit per D1.10.1.8 — overwrite three Move-3+creator
    ; fields with substrate state after stosq zeroed them.
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + 0x70], rax       ; arena_id
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + 0x78], rax       ; owner_demod_id
    mov     rax, [rel current_cap_id]
    mov     [rbx + OUTCOME_OFF_CREATOR_CAP_ID], rax  ; creator_cap_id at +0x68
    ; Register
    mov     rdi, rbx
    call    registry_register_outcome
    test    rax, rax
    jz      .outcome_new_ok_fail
    ; Pod 2.1 spatial-merge — Babylon charges lineage with OP_OUTCOME_NEW_OK cost (1j)
    push    rax                                 ; preserve outcome_id
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rax                                 ; restore outcome_id
    mov     [r13], rax              ; push outcome_id
    add     r13, 8
    jmp     .fetch
.outcome_new_ok_fail:
    mov     qword [r13], 0          ; sentinel (A2: pool-full or registry-full)
    add     r13, 8
    jmp     .fetch
; Pod 2.2 (D2.2.6) — bit-check failure: current_cap lacks BIT_OUTCOME_FORGE.
; Routes through .construct_err_outcome (NOT sentinel-0) per R5 directive;
; the failure mode is distinct from pool-full and warrants typed Outcome::Err.
.outcome_new_ok_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_OUTCOME_NEW_OK
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_OUTCOME
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_OUTCOME_NEW_ERR (0xE1) ---
; Pop 5 args (top-down): err_fetch_counter, err_demod_id, err_source_op,
; err_code, value_type_id. Push outcome_id. Fires prov_append hook
; per D1.9.1.6 with A1 fetch_counter bifurcation (substrate counter
; from [rel vm_fetch_count] for prov event; user-supplied
; err_fetch_counter into Outcome inline context at +0x38).
.op_outcome_new_err:
    sub     r13, 8
    mov     r8, [r13]               ; err_fetch_counter (program-domain, into slot)
    sub     r13, 8
    mov     r9, [r13]               ; err_demod_id
    sub     r13, 8
    mov     r10, [r13]              ; err_source_op
    sub     r13, 8
    mov     r11, [r13]              ; err_code
    sub     r13, 8
    mov     rcx, [r13]              ; value_type_id
    ; Pod 2.2 — bit-check: current_cap must carry BIT_OUTCOME_FORGE per D2.2.6
    push    rcx
    push    r11
    push    r10
    push    r9
    push    r8
    mov     rdi, BIT_OUTCOME_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     r8
    pop     r9
    pop     r10
    pop     r11
    pop     rcx
    jnz     .outcome_new_err_insufficient_authority
    call    .outcome_alloc
    test    rax, rax
    jz      .outcome_new_err_fail
    mov     rbx, rax                ; slot_ptr
    ; Write named fields
    mov     qword [rbx + 0x00], 1   ; discriminant = err
    mov     [rbx + 0x08], rcx       ; value_type_id (expected-T-on-error per A2)
    mov     qword [rbx + 0x10], 0   ; value (unused for err)
    mov     qword [rbx + 0x18], 0   ; reserved
    mov     [rbx + 0x20], r11       ; err_code
    mov     [rbx + 0x28], r10       ; err_source_op
    mov     [rbx + 0x30], r9        ; err_demod_id
    mov     [rbx + 0x38], r8        ; err_fetch_counter (A1 program-domain)
    ; Save err_source_op + err_demod_id on cpu stack across stosq +
    ; registry call + prov_append (R3.3 register state preservation).
    push    r10                     ; -> [rsp+8] after one more push
    push    r9                      ; -> [rsp+0]
    ; Zero Pod 3+ reserved + Move 3 fields + creator_cap_id (8 qwords at +0x40)
    lea     rdi, [rbx + 0x40]
    xor     eax, eax
    mov     rcx, 8
    rep     stosq
    ; Pod 1.10.2b2 retrofit per D1.10.1.8 — overwrite Move-3+creator fields
    ; with substrate state after stosq zeroed them.
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + 0x70], rax       ; arena_id
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + 0x78], rax       ; owner_demod_id
    mov     rax, [rel current_cap_id]
    mov     [rbx + OUTCOME_OFF_CREATOR_CAP_ID], rax  ; creator_cap_id at +0x68
    ; Register
    mov     rdi, rbx
    call    registry_register_outcome
    test    rax, rax
    jz      .outcome_new_err_pop2_fail
    push    rax                     ; save outcome_id (-> [rsp+0]; saved args at [rsp+8],[rsp+16])
    ; D1.9.1.6 + A1 — auto-provenance hook. Cap-gate is internal to
    ; prov_append; default-OFF in V1.0.
    mov     rdi, [rsp + 16]         ; opcode = err_source_op (A4.b)
    mov     rsi, [rsp + 8]          ; demod_id = err_demod_id (A4.c)
    mov     rdx, [rel vm_fetch_count] ; fetch_counter = substrate value (A1)
    call    prov_append
    pop     rax                     ; outcome_id
    add     rsp, 16                 ; discard saved args
    ; Pod 2.1 spatial-merge — Babylon charges lineage with OP_OUTCOME_NEW_ERR cost (1j)
    push    rax                                 ; preserve outcome_id
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rax                                 ; restore outcome_id
    mov     [r13], rax              ; push outcome_id
    add     r13, 8
    jmp     .fetch
.outcome_new_err_pop2_fail:
    add     rsp, 16                 ; discard saved args
.outcome_new_err_fail:
    mov     qword [r13], 0          ; sentinel
    add     r13, 8
    jmp     .fetch
; Pod 2.2 (D2.2.6) — bit-check failure: current_cap lacks BIT_OUTCOME_FORGE.
; Routes through .construct_err_outcome (NOT sentinel-0) per R5 directive.
.outcome_new_err_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_OUTCOME_NEW_ERR
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_OUTCOME
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_OUTCOME_IS_OK (0xE2) ---
; Consume outcome_id; push 1 if ok, 0 if err. A3: invalid id pushes 0.
.op_outcome_is_ok:
    sub     r13, 8
    mov     rdi, [r13]              ; outcome_id
    call    registry_lookup_outcome
    test    rax, rax
    jz      .outcome_is_ok_zero     ; A3: invalid id → 0
    mov     rax, [rax + 0x00]       ; discriminant
    test    rax, rax
    jnz     .outcome_is_ok_zero     ; err → 0
    mov     qword [r13], 1          ; ok → 1
    add     r13, 8
    jmp     .fetch
.outcome_is_ok_zero:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

; --- OP_OUTCOME_UNWRAP_OK (0xE3) ---
; Consume outcome_id; on ok push value; on err (or invalid id) push 0
; sentinel + emit str_unwrap_ok_on_err (D1.9.1.8).
.op_outcome_unwrap_ok:
    sub     r13, 8
    mov     rdi, [r13]              ; outcome_id
    call    registry_lookup_outcome
    test    rax, rax
    jz      .outcome_unwrap_ok_log  ; invalid id → sentinel + log
    mov     rbx, rax                ; slot_ptr
    mov     rax, [rbx + 0x00]       ; discriminant
    test    rax, rax
    jnz     .outcome_unwrap_ok_log  ; err → sentinel + log
    ; ok: push value
    mov     rax, [rbx + 0x10]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.outcome_unwrap_ok_log:
    mov     qword [r13], 0
    add     r13, 8
    lea     rsi, [rel str_unwrap_ok_on_err]
    call    auryn_puts
    jmp     .fetch

; --- OP_OUTCOME_UNWRAP_ERR (0xE4) ---
; Consume outcome_id; on err push 4 fields (A1 verbatim spec — err_code
; first/bottom, err_fetch_counter last/TOS); on ok (or invalid id) push
; 4 zero sentinels + emit str_unwrap_err_on_ok (D1.9.1.8).
.op_outcome_unwrap_err:
    sub     r13, 8
    mov     rdi, [r13]              ; outcome_id
    call    registry_lookup_outcome
    test    rax, rax
    jz      .outcome_unwrap_err_log ; invalid id → 4 sentinels + log
    mov     rbx, rax                ; slot_ptr
    mov     rax, [rbx + 0x00]       ; discriminant
    test    rax, rax
    jz      .outcome_unwrap_err_log ; ok-discriminant on UNWRAP_ERR → log
    ; err: push 4 fields per A1 verbatim — err_code at bottom, ..., err_fetch_counter at TOS
    mov     rax, [rbx + 0x20]       ; err_code
    mov     [r13], rax
    mov     rax, [rbx + 0x28]       ; err_source_op
    mov     [r13 + 8], rax
    mov     rax, [rbx + 0x30]       ; err_demod_id
    mov     [r13 + 16], rax
    mov     rax, [rbx + 0x38]       ; err_fetch_counter (TOS after add)
    mov     [r13 + 24], rax
    add     r13, 32
    jmp     .fetch
.outcome_unwrap_err_log:
    mov     qword [r13], 0
    mov     qword [r13 + 8], 0
    mov     qword [r13 + 16], 0
    mov     qword [r13 + 24], 0
    add     r13, 32
    lea     rsi, [rel str_unwrap_err_on_ok]
    call    auryn_puts
    jmp     .fetch

; =============================================================
; Pod 1.10.2b1 — Cap operations + Cap accessors
; D1.10.2b1.1 supersession: OP_CAP_CHECK retired; three accessors
; (ARENA, OWNER, RESOURCE) ship instead. Substrate is witness, not
; police. Programs read slot fields with MAC-verified authenticity;
; substrate does not enforce match-against-expected.
; Pod 2.2 supersession (D2.2.4): OP_CAP_RESOURCE retired; accessor at
; same byte position (+0x18) becomes OP_CAP_BITMAP at 0xBA with
; structured forge-bit interpretation per D2.2.1. Texture-as-physics
; replaces resource_descriptor placeholder.
; =============================================================

; --- OP_CAP_NEW (0xB0) ---
; Pop (granted_bitmap, energy_budget) — Pod 2.2 D2.2.4 semantic amendment.
; Pod 1.10.3 D1.10.3.2 had resource_descriptor where granted_bitmap now
; sits; same byte position (+0x18), structured forge-bit semantics now
; load-bearing per D2.2.1. Signature shape unchanged (still pops two
; args; bytecode-shape preserved); semantic interpretation shifts.
;
; Pod 2.2 D2.2.5 — two pre-construction bit-checks:
;   (1) parent must carry BIT_CAP_FORGE (exercise-site check; ROOT has
;       it; users who clear it on grant produce leaf caps that can't
;       make children)
;   (2) subset-on-grant: (granted_bitmap & parent_bitmap) == granted_bitmap
;       (no privilege escalation across delegation; activates DEFERRED
;       #61 forward-anchor from Pod 1.10.2b1 after four pods)
;
; energy_budget joins MAC-input range (immutable identity); energy_used
; initialized to 0 (non-MAC, mutable, substrate-managed). Construct Cap
; slot under strict delegation (arena/owner inherited from current_cap;
; parent_cap_id = current_cap_id). MAC computed over 7 qwords after
; cap_id_self assignment from registry. Push Outcome::Ok wrapping cap_id
; (Pod 1.9.3 Path A semantics).
.op_cap_new:
    sub     r13, 8
    mov     r9, [r13]                       ; energy_budget (top of stack; Pod 1.10.3)
    sub     r13, 8
    mov     r10, [r13]                      ; granted_bitmap (Pod 2.2; was resource_descriptor pre-2.2)

    ; Pod 2.2 — bit-check stage 1: parent has BIT_CAP_FORGE per D2.2.5
    push    r9
    push    r10
    mov     rdi, BIT_CAP_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     r10
    pop     r9
    jnz     .cap_new_insufficient_authority

    ; Pod 2.2 — bit-check stage 2: subset-on-grant per D2.2.5
    ;   (granted_bitmap & parent_bitmap) == granted_bitmap
    push    r9
    push    r10
    mov     rdi, [rel current_cap_id]
    call    registry_lookup_cap             ; rax = parent slot_ptr
    pop     r10
    pop     r9
    test    rax, rax
    jz      .cap_new_subset_lookup_fail     ; defensive — current_cap_id should always resolve
    mov     r11, [rax + CAP_OFF_BITMAP]     ; parent's bitmap
    mov     rcx, r10
    and     rcx, r11                        ; granted & parent
    cmp     rcx, r10                        ; == granted? (subset rule)
    jne     .cap_new_authority_exceeded

    ; Pool capacity check
    mov     rcx, [rel vm_cap_next]
    cmp     rcx, CAP_POOL_SLOTS
    jge     .op_cap_new_pool_full

    ; Compute slot pointer for this allocation (vm_cap_pool + index*128)
    lea     rbx, [rel vm_cap_pool]
    mov     rax, rcx
    shl     rax, 7                          ; * CAP_SLOT_SIZE
    add     rbx, rax

    ; Write Cap slot fields (cap_id_self placeholder=0 until registry assigns id)
    mov     qword [rbx + CAP_OFF_CAP_ID_SELF], 0
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + CAP_OFF_ARENA_ID], rax
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + CAP_OFF_OWNER_DEMOD_ID], rax
    mov     [rbx + CAP_OFF_BITMAP], r10     ; Pod 2.2 — granted_bitmap (was resource_descriptor pre-2.2)
    mov     rax, [rel current_cap_id]
    mov     [rbx + CAP_OFF_PARENT_CAP_ID], rax
    mov     qword [rbx + CAP_OFF_GENERATION_COUNTER], 0
    ; Pod 1.10.3 metabolic fields — energy_budget in MAC-input range,
    ; energy_used (non-MAC) initialized to 0; substrate prep only,
    ; Pod 2 Cop activates incrementing via spatial-merge.
    mov     [rbx + CAP_OFF_ENERGY_BUDGET], r9
    mov     qword [rbx + CAP_OFF_ENERGY_USED], 0

    ; Register slot to obtain cap_id (registry preserves r12-r15, rbx, rbp, rdi)
    mov     rdi, rbx
    call    registry_register_cap           ; rax = assigned cap_id (0 if registry full)
    test    rax, rax
    jz      .op_cap_new_pool_full           ; pool & registry capacities matched → same Err

    ; Stamp cap_id_self with assigned id; bump pool counter
    mov     [rbx + CAP_OFF_CAP_ID_SELF], rax
    inc     qword [rel vm_cap_next]

    ; Compute MAC over 7 input fields (Pod 1.10.3 — was 6 pre-1.10.3;
    ; cap_id_self through energy_budget; constant propagates).
    push    rax                             ; preserve cap_id across siphash_compute
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute                 ; rax = MAC (preserves r12-r15, rbx, rbp, rdi)
    pop     rcx                             ; cap_id back in rcx
    mov     [rbx + CAP_OFF_MAC], rax        ; stamp MAC at +0x38 (Pod 1.10.3; constant)

    ; Pod 2.1 spatial-merge — Babylon charges lineage with OP_CAP_NEW cost (1j)
    ; Note R3.1 / D2.1: this fires twice per OP_CAP_NEW success (here at Cap
    ; slot stamp, then again at .construct_ok_outcome wrapping cap_id).
    ; Both at 1j; floor-divide neutralizes (1/2=0; no actual ripple).
    push    rcx                                 ; preserve cap_id
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rcx                                 ; restore cap_id

    ; Wrap cap_id in Outcome::Ok per Path A
    mov     rdi, rcx                        ; value = cap_id
    mov     r8, TYPE_CODE_CAP
    call    .construct_ok_outcome
    mov     [r13], rax                      ; push outcome_id
    add     r13, 8
    jmp     .fetch

.op_cap_new_pool_full:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_CAP_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; Pod 2.2 (D2.2.5/D2.2.6) — three OP_CAP_NEW failure paths.
; Bit-check failure (parent lacks BIT_CAP_FORGE):
.cap_new_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_CAP_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; Subset-on-grant violation (granted_bitmap exceeds parent_bitmap):
; activates DEFERRED #61 forward-anchor from Pod 1.10.2b1 D1.10.2b1.2.
.cap_new_authority_exceeded:
    mov     rdi, ERR_CAP_AUTHORITY_EXCEEDED
    mov     rsi, OP_CAP_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; Defensive — current_cap_id failed registry_lookup_cap (should never
; fire since current_cap_id is canonical and validated at OP_CAP_ENTER).
; Fail-safe to ERR_INVALID_ID per .op_cap_enter_invalid pattern.
.cap_new_subset_lookup_fail:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_CAP_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_ENTER (0xB1) ---
; Pop cap_id; MAC-verify (forgery detection per A1); push current_cap_id to
; cap_stack; update current_cap_id and arena/owner caches from new cap's slot.
; Returns Outcome<NONE> on every path (A2 ratification — Path A consistency
; for fallible operations; success uses TYPE_CODE_NONE sentinel pattern).
.op_cap_enter:
    sub     r13, 8
    mov     rdi, [r13]                      ; new_cap_id

    test    rdi, rdi
    jz      .op_cap_enter_invalid

    call    registry_lookup_cap             ; rax = slot_ptr (0 if not found)
    test    rax, rax
    jz      .op_cap_enter_invalid
    mov     rbx, rax                        ; slot_ptr

    ; MAC verify — load-bearing forgery detection (A1)
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute                 ; rax = recomputed MAC; rbx preserved
    cmp     rax, [rbx + CAP_OFF_MAC]
    jne     .op_cap_enter_invalid

    ; cap_stack overflow check
    mov     rcx, [rel cap_stack_ptr]
    cmp     rcx, CAP_STACK_DEPTH
    jge     .op_cap_enter_overflow

    ; Push current_cap_id onto cap_stack
    ; (RIP-relative + indexed addressing not valid x86-64; lea base then index)
    lea     rdx, [rel cap_stack]
    mov     rax, [rel current_cap_id]
    mov     [rdx + rcx*8], rax
    inc     qword [rel cap_stack_ptr]

    ; Update current_cap state from new cap's slot
    mov     rax, [rbx + CAP_OFF_CAP_ID_SELF]
    mov     [rel current_cap_id], rax
    mov     rax, [rbx + CAP_OFF_ARENA_ID]
    mov     [rel current_cap_arena_id_cache], rax
    mov     rax, [rbx + CAP_OFF_OWNER_DEMOD_ID]
    mov     [rel current_cap_owner_demod_id_cache], rax
    ; V1.1 - cache slot ptr + budget; rbx holds slot ptr (budget is MAC-covered = immutable)
    mov     [rel current_cap_slot_ptr_cache], rbx
    mov     rax, [rbx + CAP_OFF_ENERGY_BUDGET]
    mov     [rel current_cap_budget_cache], rax

    ; Outcome::Ok with TYPE_CODE_NONE (succeeded, no meaningful value)
    xor     edi, edi
    mov     r8, TYPE_CODE_NONE
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_enter_invalid:
    mov     rdi, ERR_INVALID_ID             ; A3: MAC mismatch collapses to ERR_INVALID_ID
    mov     rsi, OP_CAP_ENTER
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_enter_overflow:
    ; Pod 1.9.3 D1.9.3.2 tag-the-halt — push Err, emit diagnostic, halt
    mov     rdi, ERR_STACK_OVERFLOW
    mov     rsi, OP_CAP_ENTER
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_NONE              ; D1.9.3.3: stack violations have no expected-T
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    lea     rsi, [rel str_call_overflow]    ; reuse Pod 1.3 string per architect spec
    call    auryn_puts
    jmp     .done

; --- OP_CAP_EXIT (0xB2) ---
; Pop cap_stack; restore current_cap_id and caches from prior cap's slot.
; No MAC verify on exit — restored cap was authenticated at its prior ENTER.
; Returns Outcome<NONE> on every path (A2). Underflow tags-the-halt.
.op_cap_exit:
    mov     rcx, [rel cap_stack_ptr]
    test    rcx, rcx
    jz      .op_cap_exit_underflow

    ; Pop cap_stack (lea base then index — RIP-relative + index not valid)
    dec     rcx
    mov     [rel cap_stack_ptr], rcx
    lea     rdx, [rel cap_stack]
    mov     rdi, [rdx + rcx*8]              ; restored cap_id

    ; Look up restored cap to refresh cache fields (cap was registered at its ENTER)
    call    registry_lookup_cap
    test    rax, rax
    jz      .op_cap_exit_underflow          ; defensive — should not fire if substrate consistent
    mov     rbx, rax

    ; Restore current_cap state from slot
    mov     rax, [rbx + CAP_OFF_CAP_ID_SELF]
    mov     [rel current_cap_id], rax
    mov     rax, [rbx + CAP_OFF_ARENA_ID]
    mov     [rel current_cap_arena_id_cache], rax
    mov     rax, [rbx + CAP_OFF_OWNER_DEMOD_ID]
    mov     [rel current_cap_owner_demod_id_cache], rax
    ; V1.1 - cache slot ptr + budget; rbx holds slot ptr (budget is MAC-covered = immutable)
    mov     [rel current_cap_slot_ptr_cache], rbx
    mov     rax, [rbx + CAP_OFF_ENERGY_BUDGET]
    mov     [rel current_cap_budget_cache], rax

    ; Outcome::Ok with TYPE_CODE_NONE
    xor     edi, edi
    mov     r8, TYPE_CODE_NONE
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_cap_exit_underflow:
    mov     rdi, ERR_STACK_UNDERFLOW
    mov     rsi, OP_CAP_EXIT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_NONE              ; D1.9.3.3
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    lea     rsi, [rel str_ret_underflow]    ; reuse Pod 1.3 string per architect spec
    call    auryn_puts
    jmp     .done

; --- OP_CAP_CURRENT (0xB3) ---
; Push current_cap_id. No Outcome wrap — substrate state always valid
; (current_cap_id ≥ ROOT_CAP_ID since boot init). Parallel to OP_PHASE_QUERY.
.op_cap_current:
    mov     rax, [rel current_cap_id]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_ARENA (0xB4) ---
; Pop cap_id; MAC-verify; push Outcome::Ok wrapping arena_id (or Err on
; invalid id / MAC mismatch). Calls .cap_accessor_common with field offset.
.op_cap_arena:
    sub     r13, 8
    mov     rdi, [r13]                      ; cap_id
    mov     rcx, CAP_OFF_ARENA_ID
    mov     rsi, OP_CAP_ARENA
    call    .cap_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_OWNER (0xB5) ---
.op_cap_owner:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, CAP_OFF_OWNER_DEMOD_ID
    mov     rsi, OP_CAP_OWNER
    call    .cap_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- 0xB6 retired Pod 2.2 (was OP_CAP_RESOURCE; replaced by OP_CAP_BITMAP at 0xBA per D2.2.4) ---

; --- .cap_accessor_common (Pod 1.10.2b1 helper, D1.10.2b1.5) ---
; Shared lookup-verify-read for the three Cap accessors. Factored to keep
; the MAC-verification site singular. Helper signatures follow Pod 1.9.3
; r8=value_type_id convention (architect's R6/R9 outline used rsi; recon
; corrected against in-tree code per A4 / D1.10.2b1.5 forward-anchor).
;
; Internal calling convention:
;   Input:    rdi = cap_id, rcx = field offset in Cap slot, rsi = source_op
;   Output:   rax = outcome_id (Ok wrapping field value, or Err)
;   Clobbers: rax, rbx, rcx, rdx, rsi, rdi, r8
;   Preserves: r12, r13, r14, r15, rbp (caller-side VM state survives)
.cap_accessor_common:
    push    rsi                             ; preserve source_op (for Err path)
    push    rcx                             ; preserve field offset

    test    rdi, rdi
    jz      .accessor_invalid               ; cap_id=0 invalid

    call    registry_lookup_cap             ; rax = slot_ptr (0 if not found)
    test    rax, rax
    jz      .accessor_invalid
    mov     rbx, rax                        ; slot_ptr

    ; MAC verify (forgery detection per A1)
    mov     rdi, rbx
    mov     rsi, CAP_MAC_INPUT_QWORDS
    call    siphash_compute                 ; rax = recomputed MAC; rbx preserved
    cmp     rax, [rbx + CAP_OFF_MAC]
    jne     .accessor_invalid               ; A3: MAC mismatch collapses to ERR_INVALID_ID

    ; Read requested field, wrap in Outcome::Ok
    pop     rcx                             ; restore offset
    pop     rsi                             ; (source_op unused on success)
    mov     rdi, [rbx + rcx]                ; value = slot field
    mov     r8, TYPE_CODE_CAP
    call    .construct_ok_outcome
    ret

.accessor_invalid:
    pop     rcx                             ; discard offset
    pop     rsi                             ; restore source_op
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_CAP
    call    .construct_err_outcome
    ret

; =============================================================
; Pod 1.10.2b2 — Witness substrate-wide + provenance anchoring
; Three per-type accessor helpers (D1.10.2b2.4 — per-type pattern
; preserved over polymorphic dispatch) plus OP_CAP_PARENT reusing
; Pod 1.10.2b1's .cap_accessor_common (D1.10.2b2.6).
;
; Sign/Energy/Outcome accessors do registry lookup + slot read
; with NO MAC verify (these primitives don't carry SipHash MACs).
; Cost 0j structural per D1.10.2b2.5 / D1.9.2b.1 work-matches-cost
; doctrine. OP_CAP_PARENT does MAC verify per Pod 1.10.2b1 Cap
; accessor convention; cost 1j metabolic.
; =============================================================

; --- OP_SIGN_ARENA / OP_SIGN_OWNER / OP_SIGN_CREATOR (0xA4-0xA6) ---
.op_sign_arena:
    sub     r13, 8
    mov     rdi, [r13]                      ; sign_id
    mov     rcx, 0x70                       ; SIGN arena_id offset
    mov     rsi, OP_SIGN_ARENA
    call    .sign_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_sign_owner:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, 0x78                       ; SIGN owner_demod_id offset
    mov     rsi, OP_SIGN_OWNER
    call    .sign_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_sign_creator:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, SIGN_OFF_CREATOR_CAP_ID    ; 0x68
    mov     rsi, OP_SIGN_CREATOR
    call    .sign_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_SIGN_EMBEDDING_HANDLE (0xA7) Pod 3 — D3.4 side-table read ---
; Pop sign_id; validate resolves via registry_lookup_sign; read embedding_handle
; from vm_sign_embedding_handle[sign_id - 1]; push Outcome::Ok wrapping value.
; Reads from parallel BSS structure, not slot field (the slot field at +0x68
; was reclaimed at Pod 1.10.2b2 for creator_cap_id; embedding linkage lives
; in side-table per DEFERRED #65 resolution).
.op_sign_embedding_handle:
    sub     r13, 8
    mov     rdi, [r13]                      ; sign_id
    test    rdi, rdi
    jz      .op_sign_embedding_handle_invalid
    push    rdi                             ; preserve sign_id across registry call
    call    registry_lookup_sign            ; rax = slot_ptr (0 if not found)
    pop     rdi
    test    rax, rax
    jz      .op_sign_embedding_handle_invalid
    ; Read side-table at index (sign_id - 1)
    mov     rcx, rdi
    dec     rcx                             ; rcx = sign_id - 1
    lea     rdx, [rel vm_sign_embedding_handle]
    mov     rdi, [rdx + rcx*8]              ; rdi = embedding_handle (value to wrap)
    mov     r8, TYPE_CODE_SIGN
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_sign_embedding_handle_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_SIGN_EMBEDDING_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_ENERGY_ARENA / OP_ENERGY_OWNER / OP_ENERGY_CREATOR (0xD6-0xD8) ---
.op_energy_arena:
    sub     r13, 8
    mov     rdi, [r13]                      ; energy_id
    mov     rcx, 0x10                       ; ENERGY arena_id offset
    mov     rsi, OP_ENERGY_ARENA
    call    .energy_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_energy_owner:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, 0x18                       ; ENERGY owner_demod_id offset
    mov     rsi, OP_ENERGY_OWNER
    call    .energy_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_energy_creator:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, ENERGY_OFF_CREATOR_CAP_ID  ; 0x20
    mov     rsi, OP_ENERGY_CREATOR
    call    .energy_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_OUTCOME_ARENA / OP_OUTCOME_OWNER / OP_OUTCOME_CREATOR (0xE5-0xE7) ---
.op_outcome_arena:
    sub     r13, 8
    mov     rdi, [r13]                      ; outcome_id
    mov     rcx, 0x70                       ; OUTCOME arena_id offset
    mov     rsi, OP_OUTCOME_ARENA
    call    .outcome_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_outcome_owner:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, 0x78                       ; OUTCOME owner_demod_id offset
    mov     rsi, OP_OUTCOME_OWNER
    call    .outcome_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_outcome_creator:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, OUTCOME_OFF_CREATOR_CAP_ID ; 0x68
    mov     rsi, OP_OUTCOME_CREATOR
    call    .outcome_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_PARENT (0xB7) ---
; Reuses Pod 1.10.2b1 .cap_accessor_common (which already does MAC verify);
; just passes CAP_OFF_PARENT_CAP_ID = 0x20 as the field offset. Zero new
; helper code per D1.10.2b2.6 / S5.2 surprise.
.op_cap_parent:
    sub     r13, 8
    mov     rdi, [r13]                      ; cap_id
    mov     rcx, CAP_OFF_PARENT_CAP_ID      ; 0x20
    mov     rsi, OP_CAP_PARENT
    call    .cap_accessor_common            ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_BUDGET (0xB8) Pod 1.10.3 — third consumer of .cap_accessor_common ---
.op_cap_budget:
    sub     r13, 8
    mov     rdi, [r13]                      ; cap_id
    mov     rcx, CAP_OFF_ENERGY_BUDGET      ; 0x30
    mov     rsi, OP_CAP_BUDGET
    call    .cap_accessor_common            ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_USED (0xB9) Pod 1.10.3 — fourth consumer of .cap_accessor_common ---
.op_cap_used:
    sub     r13, 8
    mov     rdi, [r13]                      ; cap_id
    mov     rcx, CAP_OFF_ENERGY_USED        ; 0x40
    mov     rsi, OP_CAP_USED
    call    .cap_accessor_common            ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_CAP_BITMAP (0xBA) Pod 2.2 — seventh consumer of .cap_accessor_common ---
; Reads cap_bitmap field (+0x18; structured forge-bit vocabulary per D2.2.1).
; 1j metabolic per Cap accessor convention. MAC-verified read; refit of
; the retired OP_CAP_RESOURCE accessor at same byte position.
.op_cap_bitmap:
    sub     r13, 8
    mov     rdi, [r13]                      ; cap_id
    mov     rcx, CAP_OFF_BITMAP             ; 0x18
    mov     rsi, OP_CAP_BITMAP
    call    .cap_accessor_common            ; existing 1.10.2b1 helper
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; =============================================================
; Pod 3 — Embedding typed primitive (D3.1; substrate-prep mode)
; Fifth typed primitive: f32[384] vector substrate-prep matching
; Pod 1.7 Sign / Pod 1.8 Energy pacing. Slot is MAC-protected
; (full vector under SipHash per D3.3). Single-fire substrate
; axiom inherited at greenfield (D3.9): success path uses
; .construct_ok_outcome from start; no Path A retrofit needed.
; =============================================================

; --- OP_EMBEDDING_NEW (0xC0) Pod 3 — D3.1 ---
; Pop vector_addr; bit-check BIT_EMBEDDING_FORGE; allocate slot;
; copy 1536-byte vector; SipHash MAC over 196 qwords; register;
; wrap in Outcome::Ok via .construct_ok_outcome. Step ordering
; mirrors .op_cap_new (placeholder id 0 → content writes →
; registry → stamp assigned id → siphash) per R7-corrected.
.op_embedding_new:
    sub     r13, 8
    mov     rbx, [r13]                              ; vector_addr (rbx callee-saved)

    ; Pod 3 — bit-check: current_cap must carry BIT_EMBEDDING_FORGE
    push    rbx
    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    pop     rbx
    jnz     .embedding_new_insufficient_authority

    ; Pool capacity check
    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .embedding_new_pool_full

    ; Allocate slot
    push    rbx                                     ; preserve vector_addr
    call    .embedding_alloc                        ; rax = slot_ptr (0 if full; defensive)
    pop     rbx
    test    rax, rax
    jz      .embedding_new_pool_full

    ; Write placeholder id (0) + arena/owner/creator from substrate state
    mov     qword [rax + EMBEDDING_OFF_ID_SELF], 0  ; placeholder until registry assigns
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rax + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rax + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rax + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; Copy 1536-byte vector from [vector_addr] to slot+EMBEDDING_OFF_VECTOR
    push    rax                                     ; preserve slot_ptr across rep movsb
    lea     rdi, [rax + EMBEDDING_OFF_VECTOR]
    mov     rsi, rbx                                ; rsi = vector_addr
    mov     rcx, EMBEDDING_VECTOR_BYTES             ; 1536
    cld
    rep     movsb

    ; Register slot to obtain embedding_id
    pop     rdi                                     ; restore slot_ptr as registry input
    push    rdi                                     ; preserve slot_ptr across registry call
    call    registry_register_embedding             ; rax = embedding_id (0 if registry full)
    pop     rbx                                     ; rbx = slot_ptr
    test    rax, rax
    jz      .embedding_new_pool_full

    ; Stamp embedding_id_self with assigned id (post-registry per R7-corrected ordering)
    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    ; SipHash MAC over 196 qwords (header 4 + vector 192) per D3.3
    push    rax                                     ; preserve embedding_id
    mov     rdi, rbx                                ; siphash input = slot_ptr
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS         ; 196
    call    siphash_compute                         ; rax = MAC; rbx preserved (callee-saved)
    mov     [rbx + EMBEDDING_OFF_MAC], rax          ; stamp MAC at +0x620
    pop     rax                                     ; restore embedding_id

    ; Path A — single-fire babylon via .construct_ok_outcome (D3.9 greenfield axiom)
    mov     rdi, rax                                ; value = embedding_id
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax                              ; push outcome_id
    add     r13, 8
    jmp     .fetch

.embedding_new_pool_full:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.embedding_new_insufficient_authority:
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_NEW
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_ARENA (0xC1) ---
.op_embedding_arena:
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id
    mov     rcx, EMBEDDING_OFF_ARENA_ID             ; 0x008
    mov     rsi, OP_EMBEDDING_ARENA
    call    .embedding_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_OWNER (0xC2) ---
.op_embedding_owner:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, EMBEDDING_OFF_OWNER_DEMOD_ID       ; 0x010
    mov     rsi, OP_EMBEDDING_OWNER
    call    .embedding_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_CREATOR (0xC3) ---
.op_embedding_creator:
    sub     r13, 8
    mov     rdi, [r13]
    mov     rcx, EMBEDDING_OFF_CREATOR_CAP_ID       ; 0x018
    mov     rsi, OP_EMBEDDING_CREATOR
    call    .embedding_accessor_common
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_GET_DIM (0xC4) Pod 3 ---
; Pop dim_index (TOS), embedding_id. Bounds-check dim_index < 384;
; lookup + MAC verify; load f32 from vector[dim_index]; bit-cast to
; i64 via zero-extend (preserves IEEE bit pattern); push Outcome.
.op_embedding_get_dim:
    sub     r13, 8
    mov     rcx, [r13]                              ; dim_index (top-of-stack)
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id

    ; Bounds check: dim_index < EMBEDDING_DIM (unsigned compare catches negatives too)
    cmp     rcx, EMBEDDING_DIM
    jae     .embedding_get_dim_oob

    test    rdi, rdi
    jz      .embedding_get_dim_invalid_id
    push    rcx                                     ; preserve dim_index across registry call
    call    registry_lookup_embedding
    pop     rcx
    test    rax, rax
    jz      .embedding_get_dim_invalid_id
    mov     rbx, rax                                ; slot_ptr

    ; MAC verify
    push    rcx                                     ; preserve dim_index across siphash
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    pop     rcx
    cmp     rax, [rbx + EMBEDDING_OFF_MAC]
    jne     .embedding_get_dim_invalid_id           ; MAC mismatch → ERR_INVALID_ID

    ; Load f32 dimension; zero-extend 32→64 via 32-bit mov (IEEE bit pattern preserved)
    lea     rdx, [rbx + EMBEDDING_OFF_VECTOR]
    mov     eax, [rdx + rcx*4]                      ; 32-bit load; rax upper 32 zeroed
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.embedding_get_dim_oob:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_GET_DIM
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.embedding_get_dim_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_GET_DIM
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; =============================================================
; Pod 3.5 — Maid speaks: semantic operations on Embedding pool
; D3.13 witness doctrine: compute-over-substrate-state bypasses bit-check.
; D3.18 lookup MAC-verify-each-candidate convention.
; D3.9 single-fire greenfield axiom: handlers wrap via .construct_ok_outcome.
; =============================================================

; --- OP_EMBEDDING_SIGN_HANDLE (0xC5) Pod 3.5 — D3.20 reverse side-table read ---
; Pop embedding_id; validate via registry_lookup_embedding; read
; vm_embedding_sign_handle[embedding_id-1]; push Outcome<sign_id>.
; Returns 0 if no Sign linked (BSS-zero default state).
.op_embedding_sign_handle:
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id
    test    rdi, rdi
    jz      .op_embedding_sign_handle_invalid
    push    rdi                                     ; preserve embedding_id across registry call
    call    registry_lookup_embedding
    pop     rdi
    test    rax, rax
    jz      .op_embedding_sign_handle_invalid
    ; Read reverse side-table at index (embedding_id - 1)
    mov     rcx, rdi
    dec     rcx                                     ; rcx = embedding_id - 1
    lea     rdx, [rel vm_embedding_sign_handle]
    mov     rdi, [rdx + rcx*8]                      ; rdi = sign_id (or 0)
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_sign_handle_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_SIGN_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- .embedding_two_resolve_verify (Pod 3.5 internal helper) ---
; Resolves two embedding_ids and MAC-verifies both slots. Used by
; cosine/dot/l2 handlers to avoid 25-line duplication per handler.
;
; Input:    r10 = id_a, r11 = id_b
; Output:   rdi = slot_a_ptr, rsi = slot_b_ptr (on success)
;           rax = 0 (success) or 1 (any of: id=0, lookup miss, MAC mismatch)
; Clobbers: rax, rcx, rdx, r8, r9, r10, r11 (consumed; siphash clobbers r8-r11)
;           Plus stack discipline (cleanup paths discard appropriate save slots).
; Preserves: r12-r15, rbx, rbp; xmm0-xmm15 untouched.
.embedding_two_resolve_verify:
    ; Stack-based id storage across siphash calls (siphash clobbers r10/r11)
    push    r11                                     ; [rsp+8] = id_b after next push
    push    r10                                     ; [rsp+0] = id_a, [rsp+8] = id_b

    ; Resolve A
    mov     rdi, [rsp + 0]                          ; id_a
    test    rdi, rdi
    jz      .etrv_fail_pop2
    call    registry_lookup_embedding               ; rax = slot_a or 0; preserves rdi
    test    rax, rax
    jz      .etrv_fail_pop2

    ; MAC verify A
    mov     rdi, rax                                ; slot_a
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rdi preserved per siphash contract
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .etrv_fail_pop2

    ; Save slot_a on stack across slot_b resolve+verify
    push    rdi                                     ; [rsp+0]=slot_a, [rsp+8]=id_a, [rsp+16]=id_b

    ; Resolve B
    mov     rdi, [rsp + 16]                         ; id_b
    test    rdi, rdi
    jz      .etrv_fail_pop3
    call    registry_lookup_embedding
    test    rax, rax
    jz      .etrv_fail_pop3

    ; MAC verify B
    mov     rdi, rax                                ; slot_b
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .etrv_fail_pop3

    ; Success — return slot_a in rdi, slot_b in rsi
    mov     rsi, rdi                                ; rsi = slot_b
    pop     rdi                                     ; rdi = slot_a; rsp += 8
    add     rsp, 16                                 ; discard id_a + id_b
    xor     rax, rax                                ; success
    ret

.etrv_fail_pop3:
    add     rsp, 24                                 ; discard slot_a + id_a + id_b
    jmp     .etrv_fail_done
.etrv_fail_pop2:
    add     rsp, 16                                 ; discard id_a + id_b
.etrv_fail_done:
    mov     rax, 1                                  ; failure
    ret

; --- .embedding_one_resolve_verify (Pod 3.6 helper; paired with two_resolve_verify) ---
; Single-id resolve+MAC-verify variant. Establishes helper-arity-pair convention
; (one_/two_) for synthesis tier; future Pod 3.7+ unary forge ops inherit by
; construction. Used by Pod 3.6 .op_embedding_normalize (unary) and
; .op_embedding_scale (single embedding_id + scalar; scalar pop is inline).
;
; ABI rationale: single argument fits naturally in rdi (conventional first-arg);
; output overwrites input rdi with slot_ptr. Distinct from two_resolve_verify's
; r10/r11 input convention which is forced by needing two clobberable inputs
; while rdi/rsi are reserved for outputs.
;
; Input:    rdi = embedding_id
; Output:   rdi = slot_ptr (on success); rax = 0 (success) or 1 (failure)
; Clobbers: rax, rcx, rdx, rsi, r8, r9, r10, r11 (siphash compute internal)
; Preserves: r12-r15, rbx, rbp; xmm0-xmm15 untouched
.embedding_one_resolve_verify:
    test    rdi, rdi
    jz      .eorv_fail
    call    registry_lookup_embedding               ; rax = slot_ptr or 0; rdi preserved
    test    rax, rax
    jz      .eorv_fail

    ; MAC verify
    mov     rdi, rax                                ; rdi = slot_ptr
    push    rdi                                     ; preserve slot_ptr across siphash (defensive)
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rdi preserved per siphash contract
    pop     rdi                                     ; restore slot_ptr
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .eorv_fail

    xor     rax, rax                                ; success
    ret

.eorv_fail:
    mov     rax, 1                                  ; failure
    ret

; --- OP_EMBEDDING_COSINE (0xC6) Pod 3.5 — D3.14 cosine via Form A ---
; Pop two embedding_ids; resolve+verify both; call compute_cosine_raw;
; wrap in Outcome::Ok or route to err on zero-norm rejection.
.op_embedding_cosine:
    sub     r13, 8
    mov     r11, [r13]                              ; id_b (top)
    sub     r13, 8
    mov     r10, [r13]                              ; id_a
    call    .embedding_two_resolve_verify           ; rdi=slot_a, rsi=slot_b; rax=0 or 1
    test    rax, rax
    jnz     .op_embedding_cosine_invalid
    call    compute_cosine_raw                      ; rax = f32-as-i64; CF=1 on zero-norm
    jc      .op_embedding_cosine_zero_norm
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_cosine_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_COSINE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_cosine_zero_norm:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_COSINE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_DOT_PRODUCT (0xC7) Pod 3.5 ---
.op_embedding_dot_product:
    sub     r13, 8
    mov     r11, [r13]
    sub     r13, 8
    mov     r10, [r13]
    call    .embedding_two_resolve_verify
    test    rax, rax
    jnz     .op_embedding_dot_product_invalid
    call    compute_dot_product                     ; rax = f32-as-i64
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_dot_product_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_DOT_PRODUCT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_L2_DISTANCE (0xC8) Pod 3.5 ---
.op_embedding_l2_distance:
    sub     r13, 8
    mov     r11, [r13]
    sub     r13, 8
    mov     r10, [r13]
    call    .embedding_two_resolve_verify
    test    rax, rax
    jnz     .op_embedding_l2_distance_invalid
    call    compute_l2_distance                     ; rax = f32-as-i64
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_l2_distance_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_L2_DISTANCE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_LOOKUP_TOP1 (0xC9) Pod 3.5 — D3.18 ---
; Pop query embedding_id; resolve+verify query; call lookup_top1;
; if returns 0 (empty/all-corrupt/only-self), return Err; else wrap in Ok.
.op_embedding_lookup_top1:
    sub     r13, 8
    mov     rdi, [r13]                              ; query_id
    test    rdi, rdi
    jz      .op_embedding_lookup_top1_invalid
    push    rdi                                     ; preserve query_id (defensive; registry preserves rdi)
    call    registry_lookup_embedding               ; rax = query_slot_ptr or 0
    pop     rdi
    test    rax, rax
    jz      .op_embedding_lookup_top1_invalid
    mov     rdi, rax                                ; rdi = query_slot_ptr
    ; MAC verify query
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rdi preserved
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .op_embedding_lookup_top1_invalid
    ; rdi = verified query_slot_ptr; call lookup_top1
    call    lookup_top1                             ; rax = best_match_embedding_id (0 if none)
    test    rax, rax
    jz      .op_embedding_lookup_top1_empty
    ; Wrap best_id in Outcome::Ok
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_lookup_top1_invalid:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_LOOKUP_TOP1
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.op_embedding_lookup_top1_empty:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_LOOKUP_TOP1
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; =============================================================
; Pod 3.6 — Maid composes: synthesis operations (forge-tier)
; D3.25 Maid as lexical-computation pole (housekeeper + composer).
; D3.26 D3.20 generalized: non-MAC parallel linkage; vm_embedding_synthesis
;       is forge-written and witness-read.
; D3.27 Layout 2 quad-tuple (op, source_a, source_b, scalar) at 32 bytes.
; D3.28 FP-precision-prediction discipline; ADD has no drift surface
;       (single addss per element; no accumulator depth).
; D3.9/D3.23 single-fire babylon by construction via .construct_ok_outcome.
; R4 step 9.5 — synthesis-tuple write post-siphash, pre-Outcome-wrap;
;       same architectural moment as OP_SIGN_NEW reverse-table-write.
; =============================================================

; --- OP_EMBEDDING_ADD (0xCA) Pod 3.6 — first composition: result = a + b ---
; Pop two embedding_ids; bit-check BIT_EMBEDDING_FORGE; resolve+verify both;
; alloc dest slot; copy provenance; compute_add_raw fills vector;
; register; id-stamp; siphash MAC; synthesis-tuple write; Outcome wrap.
; Stack discipline: id_a + id_b live on call stack from pop until tuple write.
.op_embedding_add:
    sub     r13, 8
    mov     r11, [r13]                              ; id_b (top of operand stack)
    sub     r13, 8
    mov     r10, [r13]                              ; id_a

    push    r10                                     ; [rsp+0] = id_a (preserved through handler body)
    push    r11                                     ; [rsp+0] = id_b, [rsp+8] = id_a

    ; Bit-check: current_cap must carry BIT_EMBEDDING_FORGE (R9 inheritance)
    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority                 ; rax=0 ok / 1 fail; preserves r10/r11
    test    rax, rax
    jnz     .op_embedding_add_insufficient_authority_drop2

    ; Resolve + MAC verify both source slots (clobbers r10/r11)
    mov     r10, [rsp + 8]                          ; reload id_a
    mov     r11, [rsp + 0]                          ; reload id_b
    call    .embedding_two_resolve_verify           ; rdi=slot_a, rsi=slot_b on success; rax=0/1
    test    rax, rax
    jnz     .op_embedding_add_invalid_drop2

    ; Save source slot pointers across pool-cap / alloc / cap-cache writes
    push    rdi                                     ; [rsp+0] = slot_a, [rsp+8] = id_b, [rsp+16] = id_a
    push    rsi                                     ; [rsp+0] = slot_b, [rsp+8] = slot_a, [rsp+16] = id_b, [rsp+24] = id_a

    ; Pool capacity check
    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_add_pool_full_drop4

    ; Allocate dest slot
    call    .embedding_alloc                        ; rax = dest slot_ptr (0 if full; defensive)
    test    rax, rax
    jz      .op_embedding_add_pool_full_drop4
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved across compute/siphash)

    ; Write placeholder id (0) + arena/owner/creator from substrate state
    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; compute_add_raw(rdi=slot_a, rsi=slot_b, rdx=dest_slot=rbx)
    pop     rsi                                     ; slot_b
    pop     rdi                                     ; slot_a
    mov     rdx, rbx                                ; dest = new slot
    call    compute_add_raw                         ; fills [rbx + EMBEDDING_OFF_VECTOR..]; preserves rdi/rsi/rdx/rbx

    ; Register dest slot to obtain new embedding_id
    mov     rdi, rbx                                ; reset rdi to dest slot_ptr
    call    registry_register_embedding             ; rax = new_id (0 if registry full; defensive)
    test    rax, rax
    jz      .op_embedding_add_pool_full_drop2

    ; Stamp embedding_id_self post-registry (R7-corrected ordering)
    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    ; SipHash MAC over 196 qwords (header 4 + vector 192) per D3.3
    push    rax                                     ; preserve new_id across siphash
    mov     rdi, rbx                                ; siphash input = slot_ptr
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rbx preserved
    mov     [rbx + EMBEDDING_OFF_MAC], rax          ; stamp MAC at +0x620
    pop     rax                                     ; restore new_id

    ; Synthesis-tuple write (D3.27 Layout 2; R4 step 9.5)
    ; Stack at this point: [rsp+0] = id_b, [rsp+8] = id_a
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax                                ; new_id
    dec     rcx                                     ; new_id - 1
    shl     rcx, 5                                  ; * SYNTHESIS_TUPLE_BYTES (32)
    add     rdx, rcx                                ; tuple base addr
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_ADD
    mov     rcx, [rsp + 8]                          ; id_a from stack
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 0]                          ; id_b from stack
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0

    add     rsp, 16                                 ; discard id_a + id_b

    ; Outcome wrap — D3.9/D3.23 single-fire babylon via .construct_ok_outcome
    mov     rdi, rax                                ; value = new_id
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax                              ; push outcome_id
    add     r13, 8
    jmp     .fetch

.op_embedding_add_pool_full_drop4:
    add     rsp, 32                                 ; discard slot_a + slot_b + id_a + id_b
    jmp     .op_embedding_add_pool_full_emit

.op_embedding_add_pool_full_drop2:
    add     rsp, 16                                 ; discard id_a + id_b (slot_a/slot_b already popped)

.op_embedding_add_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_ADD
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_add_invalid_drop2:
    add     rsp, 16                                 ; discard id_a + id_b
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_ADD
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_add_insufficient_authority_drop2:
    add     rsp, 16                                 ; discard id_a + id_b
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_ADD
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_SUBTRACT (0xCB) Pod 3.6 — Phase 2.1 ADD's twin ---
; Inherits .op_embedding_add shape verbatim: same stack discipline (4 cleanup
; labels), same R4 sequence with R4 step 9.5 synthesis-tuple write, same
; D3.9/D3.23 single-fire via Outcome wrap. Differs only in compute helper
; (compute_subtract_raw) and tuple op code (SYNTHESIS_OP_SUBTRACT).
.op_embedding_subtract:
    sub     r13, 8
    mov     r11, [r13]                              ; id_b (top)
    sub     r13, 8
    mov     r10, [r13]                              ; id_a

    push    r10                                     ; [rsp+0] = id_a
    push    r11                                     ; [rsp+0] = id_b, [rsp+8] = id_a

    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_subtract_insufficient_authority_drop2

    mov     r10, [rsp + 8]
    mov     r11, [rsp + 0]
    call    .embedding_two_resolve_verify           ; rdi=slot_a, rsi=slot_b on success
    test    rax, rax
    jnz     .op_embedding_subtract_invalid_drop2

    push    rdi                                     ; slot_a
    push    rsi                                     ; slot_b

    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_subtract_pool_full_drop4

    call    .embedding_alloc                        ; rax = dest slot_ptr
    test    rax, rax
    jz      .op_embedding_subtract_pool_full_drop4
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved)

    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    pop     rsi                                     ; slot_b
    pop     rdi                                     ; slot_a
    mov     rdx, rbx                                ; dest = new slot
    call    compute_subtract_raw                    ; fills [rbx + EMBEDDING_OFF_VECTOR..]

    mov     rdi, rbx
    call    registry_register_embedding             ; rax = new_id
    test    rax, rax
    jz      .op_embedding_subtract_pool_full_drop2

    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    push    rax                                     ; preserve new_id
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    ; Synthesis-tuple write (D3.27 Layout 2; R4 step 9.5)
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_SUBTRACT
    mov     rcx, [rsp + 8]                          ; id_a
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 0]                          ; id_b
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0

    add     rsp, 16                                 ; discard id_a + id_b

    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_subtract_pool_full_drop4:
    add     rsp, 32
    jmp     .op_embedding_subtract_pool_full_emit

.op_embedding_subtract_pool_full_drop2:
    add     rsp, 16

.op_embedding_subtract_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_SUBTRACT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_subtract_invalid_drop2:
    add     rsp, 16
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_SUBTRACT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_subtract_insufficient_authority_drop2:
    add     rsp, 16
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_SUBTRACT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_SCALE (0xCC) Pod 3.6 — Phase 2.2 scalar-mixed forge ---
; Pop scalar (top of operand stack, f32-as-i64) + embedding_id; bit-check;
; one_resolve_verify on embedding_id; alloc dest; cap-cache writes;
; compute_scale_raw with scalar broadcast; register; id-stamp; siphash;
; tuple write (op=SCALE, source_a=id, source_b=scalar, scalar=0); Outcome wrap.
; Stack order: [..., embedding_id, scalar] per GET_DIM TOS-is-rightmost-arg convention.
.op_embedding_scale:
    sub     r13, 8
    mov     r11, [r13]                              ; scalar (top, f32-as-i64)
    sub     r13, 8
    mov     r10, [r13]                              ; embedding_id

    push    r10                                     ; [rsp+0] = embedding_id
    push    r11                                     ; [rsp+0] = scalar, [rsp+8] = embedding_id

    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_scale_insufficient_authority_drop2

    mov     rdi, [rsp + 8]                          ; reload embedding_id
    call    .embedding_one_resolve_verify           ; rdi = slot_a_ptr; rax = 0/1
    test    rax, rax
    jnz     .op_embedding_scale_invalid_drop2

    push    rdi                                     ; [rsp+0] = slot_a, [rsp+8] = scalar, [rsp+16] = embedding_id

    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_scale_pool_full_drop3

    call    .embedding_alloc                        ; rax = dest slot_ptr
    test    rax, rax
    jz      .op_embedding_scale_pool_full_drop3
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved)

    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; compute_scale_raw(rdi=slot_a, rsi=scalar, rdx=dest)
    pop     rdi                                     ; slot_a; [rsp+0] = scalar, [rsp+8] = embedding_id
    mov     rsi, [rsp + 0]                          ; scalar
    mov     rdx, rbx                                ; dest = new slot
    call    compute_scale_raw

    mov     rdi, rbx
    call    registry_register_embedding             ; rax = new_id
    test    rax, rax
    jz      .op_embedding_scale_pool_full_drop2

    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    push    rax                                     ; preserve new_id across siphash
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    ; Synthesis-tuple write (D3.27 Layout 2; op=SCALE, source_b=scalar)
    ; Stack: [rsp+0] = scalar, [rsp+8] = embedding_id
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_SCALE
    mov     rcx, [rsp + 8]                          ; embedding_id
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 0]                          ; scalar (f32-as-i64)
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0

    add     rsp, 16                                 ; discard embedding_id + scalar

    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_scale_pool_full_drop3:
    add     rsp, 24                                 ; discard slot_a + scalar + embedding_id
    jmp     .op_embedding_scale_pool_full_emit

.op_embedding_scale_pool_full_drop2:
    add     rsp, 16                                 ; discard scalar + embedding_id (slot_a popped pre-compute)

.op_embedding_scale_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_SCALE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_scale_invalid_drop2:
    add     rsp, 16
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_SCALE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_scale_insufficient_authority_drop2:
    add     rsp, 16
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_SCALE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_NORMALIZE (0xCD) Pod 3.6 — Phase 2.2 first unary forge ---
; Pop one embedding_id; bit-check; one_resolve_verify; alloc dest; cap-cache;
; compute_normalize_raw → on CF=1 route to zero-norm err path; register;
; id-stamp; siphash; tuple write (op=NORMALIZE, source_a=id only); Outcome wrap.
; First synthesis-tier zero-norm rejection (mirrors compute_cosine_raw shape).
.op_embedding_normalize:
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id

    push    rdi                                     ; [rsp+0] = embedding_id

    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_normalize_insufficient_authority_drop1

    mov     rdi, [rsp + 0]                          ; reload embedding_id
    call    .embedding_one_resolve_verify           ; rdi = slot_a_ptr; rax = 0/1
    test    rax, rax
    jnz     .op_embedding_normalize_invalid_drop1

    push    rdi                                     ; [rsp+0] = slot_a, [rsp+8] = embedding_id

    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_normalize_pool_full_drop2

    call    .embedding_alloc                        ; rax = dest slot_ptr
    test    rax, rax
    jz      .op_embedding_normalize_pool_full_drop2
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved)

    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; compute_normalize_raw(rdi=slot_a, rdx=dest); CF=1 on zero-norm
    pop     rdi                                     ; slot_a; [rsp+0] = embedding_id (still)
    mov     rdx, rbx                                ; dest = new slot
    call    compute_normalize_raw
    jc      .op_embedding_normalize_zero_norm_drop1

    mov     rdi, rbx
    call    registry_register_embedding             ; rax = new_id
    test    rax, rax
    jz      .op_embedding_normalize_pool_full_drop1

    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    push    rax                                     ; preserve new_id across siphash
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    ; Synthesis-tuple write (D3.27 Layout 2; op=NORMALIZE, source_a only)
    ; Stack: [rsp+0] = embedding_id
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_NORMALIZE
    mov     rcx, [rsp + 0]                          ; embedding_id
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], 0
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0

    add     rsp, 8                                  ; discard embedding_id

    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_normalize_pool_full_drop2:
    add     rsp, 16                                 ; discard slot_a + embedding_id
    jmp     .op_embedding_normalize_pool_full_emit

.op_embedding_normalize_pool_full_drop1:
    add     rsp, 8                                  ; discard embedding_id (slot_a popped pre-compute)

.op_embedding_normalize_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_NORMALIZE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_normalize_zero_norm_drop1:
    add     rsp, 8                                  ; discard embedding_id (slot_a popped pre-compute)
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_NORMALIZE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_normalize_invalid_drop1:
    add     rsp, 8                                  ; discard embedding_id
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_NORMALIZE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_normalize_insufficient_authority_drop1:
    add     rsp, 8                                  ; discard embedding_id
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_NORMALIZE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_LERP (0xCE) Pod 3.6 — Phase 3.1 first ternary forge ---
; Pop t (top), id_b, id_a; bit-check; two_resolve_verify on (id_a, id_b);
; alloc dest; cap-cache writes; compute_lerp_raw with t as f32-as-i64 in r8;
; register; id-stamp; siphash; tuple write (op=LERP, id_a, id_b, t — first
; non-zero scalar field); Outcome wrap. Stack discipline: 3 stack values
; pushed; 4 cleanup variants (drop3 × 3 + drop5 × 1).
.op_embedding_lerp:
    sub     r13, 8
    mov     rax, [r13]                              ; t (top, f32-as-i64)
    sub     r13, 8
    mov     r11, [r13]                              ; id_b
    sub     r13, 8
    mov     r10, [r13]                              ; id_a

    push    r10                                     ; [rsp+0] = id_a
    push    r11                                     ; [rsp+0] = id_b, [rsp+8] = id_a
    push    rax                                     ; [rsp+0] = t, [rsp+8] = id_b, [rsp+16] = id_a

    ; Bit-check
    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_lerp_insufficient_authority_drop3

    ; Resolve+verify both source slots
    mov     r10, [rsp + 16]                         ; reload id_a
    mov     r11, [rsp + 8]                          ; reload id_b
    call    .embedding_two_resolve_verify           ; rdi=slot_a, rsi=slot_b
    test    rax, rax
    jnz     .op_embedding_lerp_invalid_drop3

    ; Save source slot pointers
    push    rdi                                     ; [rsp+0] = slot_a, [rsp+8] = t, [rsp+16] = id_b, [rsp+24] = id_a
    push    rsi                                     ; [rsp+0] = slot_b, [rsp+8] = slot_a, [rsp+16] = t, [rsp+24] = id_b, [rsp+32] = id_a

    ; Pool capacity check
    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_lerp_pool_full_drop5

    ; Allocate dest slot
    call    .embedding_alloc                        ; rax = dest slot_ptr
    test    rax, rax
    jz      .op_embedding_lerp_pool_full_drop5
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved)

    ; Placeholder + cap caches
    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; compute_lerp_raw(rdi=slot_a, rsi=slot_b, rdx=dest, r8=t)
    pop     rsi                                     ; slot_b; [rsp+0] = slot_a, [rsp+8] = t, [rsp+16] = id_b, [rsp+24] = id_a
    pop     rdi                                     ; slot_a; [rsp+0] = t, [rsp+8] = id_b, [rsp+16] = id_a
    mov     rdx, rbx                                ; dest
    mov     r8, [rsp + 0]                           ; t (don't pop; needed for tuple write)
    call    compute_lerp_raw

    ; Register
    mov     rdi, rbx
    call    registry_register_embedding             ; rax = new_id
    test    rax, rax
    jz      .op_embedding_lerp_pool_full_drop3

    ; Id stamp
    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    ; siphash MAC
    push    rax                                     ; preserve new_id across siphash
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    ; Synthesis-tuple write (D3.27 Layout 2; first non-zero scalar field)
    ; Stack: [rsp+0] = t, [rsp+8] = id_b, [rsp+16] = id_a
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_LERP
    mov     rcx, [rsp + 16]                         ; id_a
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 8]                          ; id_b
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     rcx, [rsp + 0]                          ; t (f32-as-i64)
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SCALAR], rcx

    add     rsp, 24                                 ; discard t + id_b + id_a

    ; Outcome wrap
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_lerp_pool_full_drop5:
    add     rsp, 40                                 ; slot_a + slot_b + t + id_b + id_a
    jmp     .op_embedding_lerp_pool_full_emit

.op_embedding_lerp_pool_full_drop3:
    add     rsp, 24                                 ; t + id_b + id_a (slot_a/slot_b popped pre-compute)

.op_embedding_lerp_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_LERP
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_lerp_invalid_drop3:
    add     rsp, 24
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_LERP
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_lerp_insufficient_authority_drop3:
    add     rsp, 24
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_LERP
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_SYNTHESIS_HANDLE (0xCF) Pod 3.6 — Phase 3.2 witness accessor ---
; GET_DIM-style parameterized accessor: pop field_index (0..3) + embedding_id;
; validate field range; registry_lookup_embedding (no MAC verify per D3.20
; generalized — synthesis tuple is non-MAC parallel structure mirroring
; vm_embedding_sign_handle access pattern); read tuple[field_index]; wrap in
; Outcome::Ok. Witness op (D3.13): no bit-check; no forge bit required.
.op_embedding_synthesis_handle:
    sub     r13, 8
    mov     rcx, [r13]                              ; field_index (top)
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id

    cmp     rcx, 4
    jae     .op_embedding_synthesis_handle_invalid_field

    test    rdi, rdi
    jz      .op_embedding_synthesis_handle_invalid_id

    push    rcx                                     ; preserve field_index across registry call
    call    registry_lookup_embedding               ; rax = slot_ptr or 0; rdi preserved
    pop     rcx
    test    rax, rax
    jz      .op_embedding_synthesis_handle_invalid_id

    ; Read tuple[field_index] at vm_embedding_synthesis + (embedding_id - 1) * 32 + field_index * 8
    dec     rdi                                     ; embedding_id - 1
    shl     rdi, 5                                  ; * SYNTHESIS_TUPLE_BYTES (32)
    lea     rax, [rel vm_embedding_synthesis]
    add     rax, rdi                                ; tuple base addr
    mov     rdi, [rax + rcx * 8]                    ; tuple[field_index]

    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_synthesis_handle_invalid_field:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_SYNTHESIS_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_synthesis_handle_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_SYNTHESIS_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_IMPORTED_HANDLE (0xF1) Pod 3.8 — Phase 3.8.E witness accessor ---
; Mirror of .op_embedding_synthesis_handle shape (D3.27 Layout-2 quad-tuple,
; same shift, same accessor convention) but reads vm_embedding_imported instead
; of vm_embedding_synthesis. Substrate-runtime dispatched (NOT substrate-private
; — D3.31 distinction holds; this surface participates in dispatch loop, fires
; Outcomes via .construct_ok_outcome, drains r14, increments fetch counter).
;
; Pop field_index (top of operand stack) + embedding_id; validate field range;
; registry_lookup_embedding (no MAC verify per D3.20-generalized — imported
; tuple is non-MAC parallel structure mirroring vm_embedding_synthesis pattern);
; read tuple[field_index]; wrap in Outcome::Ok. Witness op (D3.13): no bit-check;
; no forge bit required (matches SYNTHESIS_HANDLE authority pattern).
.op_embedding_imported_handle:
    sub     r13, 8
    mov     rcx, [r13]                              ; field_index (top)
    sub     r13, 8
    mov     rdi, [r13]                              ; embedding_id

    cmp     rcx, 4
    jae     .op_embedding_imported_handle_invalid_field

    test    rdi, rdi
    jz      .op_embedding_imported_handle_invalid_id

    push    rcx                                     ; preserve field_index across registry call
    call    registry_lookup_embedding               ; rax = slot_ptr or 0; rdi preserved
    pop     rcx
    test    rax, rax
    jz      .op_embedding_imported_handle_invalid_id

    ; Read tuple[field_index] at vm_embedding_imported + (embedding_id - 1) * 32 + field_index * 8
    dec     rdi                                     ; embedding_id - 1
    shl     rdi, 5                                  ; * IMPORTED_TUPLE_BYTES (32)
    lea     rax, [rel vm_embedding_imported]
    add     rax, rdi                                ; tuple base addr
    mov     rdi, [rax + rcx * 8]                    ; tuple[field_index]

    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_imported_handle_invalid_field:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_IMPORTED_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_imported_handle_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_IMPORTED_HANDLE
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_LOOKUP_TOP_K (0xF2) Pod 3.9 — D3.35 housekeeper-tier top-K ---
; Pop threshold + K + query_id from operand stack; validate K range + query_id;
; resolve query slot via registry + MAC verify; call compute_top_k_raw helper;
; push K' embedding_ids in [worst..best] order (best ends up TOS-most-recent
; among ids); wrap K' count as Outcome::Ok (full dispatch-runtime semantics —
; D3.9 single-fire babylon, fetch counter, r14 drain at 100,000j per D3.X cost
; matching D3.17 lookup_top1 anticipated-worst-case).
;
; Stack output protocol (novel K'+1 multi-output shape; D3.X documented):
;   ..., id_{K'-1} (worst), id_{K'-2}, ..., id_0 (best), outcome_id_at_TOS
;   User: outcome_unwrap_ok → K' on TOS → pop K' → loop K' times popping ids
;   best-to-worst.
;
; Witness op (D3.13): no bit-check; recognition surface, not forge.
.op_embedding_lookup_top_k:
    sub     r13, 8
    mov     rdx, [r13]                              ; threshold (top of operand stack; f32-as-i64 in low 32 bits)
    sub     r13, 8
    mov     rsi, [r13]                              ; K
    sub     r13, 8
    mov     rdi, [r13]                              ; query_id

    ; Validate K ∈ [1, MAX_K]
    test    rsi, rsi
    jz      .op_embedding_lookup_top_k_invalid_arg   ; K=0 → ERR_INVALID_EMBEDDING_ARG
    cmp     rsi, MAX_K
    ja      .op_embedding_lookup_top_k_invalid_arg   ; K > MAX_K → ERR_INVALID_EMBEDDING_ARG

    ; Validate query_id non-zero (preliminary; full validation via registry below)
    test    rdi, rdi
    jz      .op_embedding_lookup_top_k_invalid_id

    ; Stash K + threshold across registry/MAC calls (both clobber rsi/rdx; preserve rdi)
    push    rsi                                     ; K
    push    rdx                                     ; threshold

    ; Resolve query slot via registry_lookup_embedding (preserves rdi)
    call    registry_lookup_embedding               ; rax = slot_ptr or 0
    test    rax, rax
    jz      .op_embedding_lookup_top_k_invalid_id_drop2

    ; MAC verify query slot (D3.18 / D3.X convention)
    mov     rdi, rax                                ; rdi = query slot_ptr
    push    rdi                                     ; preserve slot_ptr across siphash
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute                         ; rax = MAC; rdi preserved
    pop     rdi                                     ; rdi = query slot_ptr
    cmp     rax, [rdi + EMBEDDING_OFF_MAC]
    jne     .op_embedding_lookup_top_k_invalid_id_drop2

    ; Restore K + threshold for compute_top_k_raw
    pop     rdx                                     ; threshold
    pop     rsi                                     ; K
    ; rdi = query slot_ptr (preserved from MAC verify)

    ; Call compute_top_k_raw(rdi=query_slot, rsi=K, rdx=threshold) → rax = K'
    call    compute_top_k_raw

    ; Push K' embedding_ids onto operand stack in reverse [worst..best] order
    ; (best ends up TOS-most-recent so user pops best-first per ratified protocol)
    push    rax                                     ; preserve K' across push loop
    mov     rcx, rax                                ; rcx = K' (loop counter init)
    test    rcx, rcx
    jz      .op_embedding_lookup_top_k_skip_push     ; K' = 0; no ids
    dec     rcx                                     ; rcx = K' - 1 (initial loop index, descending)
    lea     r10, [rel top_k_scratch_ids]             ; r10 = ids base (NASM `[rel sym + idx*scale]` is broken; use lea+base)
.op_embedding_lookup_top_k_push_ids_loop:
    mov     rdx, [r10 + rcx*8]                       ; rdx = scratch_ids[i]
    mov     [r13], rdx
    add     r13, 8
    test    rcx, rcx
    jz      .op_embedding_lookup_top_k_skip_push
    dec     rcx
    jmp     .op_embedding_lookup_top_k_push_ids_loop
.op_embedding_lookup_top_k_skip_push:
    pop     rax                                     ; restore K'

    ; Wrap K' count as Outcome::Ok (D3.9/D3.23 single-fire babylon via .construct_ok_outcome)
    mov     rdi, rax                                ; value = K'
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax                              ; push outcome_id (TOS-final; ids sit below)
    add     r13, 8
    jmp     .fetch

.op_embedding_lookup_top_k_invalid_id_drop2:
    add     rsp, 16                                 ; discard K + threshold pushed earlier

.op_embedding_lookup_top_k_invalid_id:
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_LOOKUP_TOP_K
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_lookup_top_k_invalid_arg:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_LOOKUP_TOP_K
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_PROJECT (0xF3) Pod 3.10 D3.38 — Maid orthogonalizes ---
; Inherits .op_embedding_add shape: same stack discipline (push id_a, push id_b →
; resolve+verify → push slot_a, push slot_b → pop slot_b/slot_a pre-compute →
; tuple write reads id_a/id_b from stack). Differs from add: compute_project_raw
; can return CF=1 (zero-norm rejection on dot(B,B)==0 per D3.40); fifth cleanup
; label .op_embedding_project_zero_norm_drop2 returns Err(InvalidEmbeddingArg)
; when this fires (matches normalize's zero-norm path shape).
.op_embedding_project:
    sub     r13, 8
    mov     r11, [r13]                              ; id_b (top of operand stack)
    sub     r13, 8
    mov     r10, [r13]                              ; id_a

    push    r10                                     ; [rsp+0] = id_a
    push    r11                                     ; [rsp+0] = id_b, [rsp+8] = id_a

    ; Bit-check: BIT_EMBEDDING_FORGE
    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_project_insufficient_authority_drop2

    ; Resolve + MAC verify both source slots
    mov     r10, [rsp + 8]                          ; reload id_a
    mov     r11, [rsp + 0]                          ; reload id_b
    call    .embedding_two_resolve_verify           ; rdi=slot_a, rsi=slot_b on success
    test    rax, rax
    jnz     .op_embedding_project_invalid_drop2

    ; Save source slot pointers across pool-cap / alloc / cap-cache writes
    push    rdi                                     ; [rsp+0] = slot_a, [rsp+8] = id_b, [rsp+16] = id_a
    push    rsi                                     ; [rsp+0] = slot_b, [rsp+8] = slot_a, [rsp+16] = id_b, [rsp+24] = id_a

    ; Pool capacity check
    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_project_pool_full_drop4

    ; Allocate dest slot
    call    .embedding_alloc                        ; rax = dest slot_ptr (0 if full; defensive)
    test    rax, rax
    jz      .op_embedding_project_pool_full_drop4
    mov     rbx, rax                                ; rbx = dest slot_ptr (callee-saved)

    ; Write placeholder id (0) + cap-cache (arena/owner/creator from substrate state)
    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    ; compute_project_raw(rdi=slot_a, rsi=slot_b, rdx=dest_slot=rbx); CF=1 on zero-norm
    pop     rsi                                     ; slot_b
    pop     rdi                                     ; slot_a
    mov     rdx, rbx                                ; dest = new slot
    call    compute_project_raw
    jc      .op_embedding_project_zero_norm_drop2

    ; Register dest slot to obtain new embedding_id
    mov     rdi, rbx
    call    registry_register_embedding             ; rax = new_id (0 if registry full; defensive)
    test    rax, rax
    jz      .op_embedding_project_pool_full_drop2

    ; Stamp embedding_id_self post-registry
    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    ; SipHash MAC over 196 qwords
    push    rax                                     ; preserve new_id across siphash
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    ; Synthesis-tuple write (D3.27 Layout 2; D3.39 internally-derived-scalar → scalar=0)
    ; Stack: [rsp+0] = id_b, [rsp+8] = id_a
    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5                                  ; * SYNTHESIS_TUPLE_BYTES (32)
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_PROJECT
    mov     rcx, [rsp + 8]                          ; id_a
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 0]                          ; id_b
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0   ; D3.39 scalar=0 for binary internally-derived-scalar ops

    add     rsp, 16                                 ; discard id_a + id_b

    ; Outcome wrap — D3.9/D3.23 single-fire babylon
    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_project_pool_full_drop4:
    add     rsp, 32                                 ; discard slot_a + slot_b + id_a + id_b
    jmp     .op_embedding_project_pool_full_emit

.op_embedding_project_pool_full_drop2:
    add     rsp, 16                                 ; discard id_a + id_b (slot_a/slot_b already popped)

.op_embedding_project_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_PROJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_project_invalid_drop2:
    add     rsp, 16                                 ; discard id_a + id_b
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_PROJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_project_insufficient_authority_drop2:
    add     rsp, 16                                 ; discard id_a + id_b
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_PROJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_project_zero_norm_drop2:
    add     rsp, 16                                 ; discard id_a + id_b (slot_a/slot_b already popped pre-compute)
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_PROJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_REJECT (0xF4) Pod 3.10 D3.38 — project's twin ---
; Inherits .op_embedding_project shape verbatim (same stack discipline; same
; 5 cleanup labels; same R4 sequence). Differs only in compute helper
; (compute_reject_raw) and tuple op code (SYNTHESIS_OP_REJECT=0x07).
.op_embedding_reject:
    sub     r13, 8
    mov     r11, [r13]                              ; id_b (top)
    sub     r13, 8
    mov     r10, [r13]                              ; id_a

    push    r10
    push    r11

    mov     rdi, BIT_EMBEDDING_FORGE
    mov     rsi, [rel current_cap_id]
    call    babylon_check_authority
    test    rax, rax
    jnz     .op_embedding_reject_insufficient_authority_drop2

    mov     r10, [rsp + 8]
    mov     r11, [rsp + 0]
    call    .embedding_two_resolve_verify
    test    rax, rax
    jnz     .op_embedding_reject_invalid_drop2

    push    rdi
    push    rsi

    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .op_embedding_reject_pool_full_drop4

    call    .embedding_alloc
    test    rax, rax
    jz      .op_embedding_reject_pool_full_drop4
    mov     rbx, rax

    mov     qword [rbx + EMBEDDING_OFF_ID_SELF], 0
    mov     rdx, [rel current_cap_arena_id_cache]
    mov     [rbx + EMBEDDING_OFF_ARENA_ID], rdx
    mov     rdx, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + EMBEDDING_OFF_OWNER_DEMOD_ID], rdx
    mov     rdx, [rel current_cap_id]
    mov     [rbx + EMBEDDING_OFF_CREATOR_CAP_ID], rdx

    pop     rsi
    pop     rdi
    mov     rdx, rbx
    call    compute_reject_raw
    jc      .op_embedding_reject_zero_norm_drop2

    mov     rdi, rbx
    call    registry_register_embedding
    test    rax, rax
    jz      .op_embedding_reject_pool_full_drop2

    mov     [rbx + EMBEDDING_OFF_ID_SELF], rax

    push    rax
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS
    call    siphash_compute
    mov     [rbx + EMBEDDING_OFF_MAC], rax
    pop     rax

    lea     rdx, [rel vm_embedding_synthesis]
    mov     rcx, rax
    dec     rcx
    shl     rcx, 5
    add     rdx, rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_OP],       SYNTHESIS_OP_REJECT
    mov     rcx, [rsp + 8]
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_A], rcx
    mov     rcx, [rsp + 0]
    mov     [rdx + SYNTHESIS_TUPLE_OFF_SOURCE_B], rcx
    mov     qword [rdx + SYNTHESIS_TUPLE_OFF_SCALAR],   0

    add     rsp, 16

    mov     rdi, rax
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_reject_pool_full_drop4:
    add     rsp, 32
    jmp     .op_embedding_reject_pool_full_emit

.op_embedding_reject_pool_full_drop2:
    add     rsp, 16

.op_embedding_reject_pool_full_emit:
    mov     rdi, ERR_POOL_FULL
    mov     rsi, OP_EMBEDDING_REJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_reject_invalid_drop2:
    add     rsp, 16
    mov     rdi, ERR_INVALID_ID
    mov     rsi, OP_EMBEDDING_REJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_reject_insufficient_authority_drop2:
    add     rsp, 16
    mov     rdi, ERR_CAP_INSUFFICIENT_AUTHORITY
    mov     rsi, OP_EMBEDDING_REJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_reject_zero_norm_drop2:
    add     rsp, 16
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_REJECT
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- OP_EMBEDDING_CODEBOOK_META (0xF5) Pod 3.11 D3.42 — Maid maintains ---
; Substrate-private singleton state accessor; pop field_index (0..3); read qword
; at vm_codebook_meta + field_index*8; wrap as Outcome::Ok. Simplest handler in
; the codebase: no embedding_id axis (codebook is singular at V1.0 per Q4 / Pod 3.8
; D3.32); no registry lookup; no MAC verify; no allocation.
;
; D3.37 NASM RIP-relative discipline: lea base into reg, then [reg + idx*8]
; (NOT [rel vm_codebook_meta + rcx*8] which silently miscompiles).
;
; Out-of-range field_index → Err(InvalidEmbeddingArg) per D3.40 hybrid validation.
.op_embedding_codebook_meta:
    sub     r13, 8
    mov     rcx, [r13]                              ; field_index (top of operand stack)

    cmp     rcx, 4
    jae     .op_embedding_codebook_meta_invalid_field

    ; Read vm_codebook_meta[field_index] — D3.37 discipline (lea base + indexed read)
    lea     rax, [rel vm_codebook_meta]
    mov     rdi, [rax + rcx*8]                      ; field value (qword)

    ; Wrap as Outcome::Ok
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

.op_embedding_codebook_meta_invalid_field:
    mov     rdi, ERR_INVALID_EMBEDDING_ARG
    mov     rsi, OP_EMBEDDING_CODEBOOK_META
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch

; --- .embedding_accessor_common (Pod 3 helper) ---
; Mirrors .cap_accessor_common pattern (Pod 1.10.2b1 D1.10.2b1.5).
; Embeddings ARE MAC-protected (full vector under SipHash per D3.3) —
; matches Cap's MAC verify pattern, distinct from Sign/Energy/Outcome
; non-MAC accessor patterns.
;
; Internal calling convention:
;   Input:    rdi = embedding_id, rcx = field offset, rsi = source_op
;   Output:   rax = outcome_id (Ok wrapping field value, or Err)
.embedding_accessor_common:
    push    rsi                             ; preserve source_op
    push    rcx                             ; preserve field offset

    test    rdi, rdi
    jz      .embedding_accessor_invalid

    call    registry_lookup_embedding       ; rax = slot_ptr or 0
    test    rax, rax
    jz      .embedding_accessor_invalid
    mov     rbx, rax                        ; slot_ptr

    ; MAC verify (forgery detection per D3.3)
    mov     rdi, rbx
    mov     rsi, EMBEDDING_MAC_INPUT_QWORDS ; 196
    call    siphash_compute                 ; rax = recomputed MAC; rbx preserved
    cmp     rax, [rbx + EMBEDDING_OFF_MAC]
    jne     .embedding_accessor_invalid     ; MAC mismatch → ERR_INVALID_ID

    pop     rcx                             ; restore offset
    pop     rsi                             ; (source_op unused on success)
    mov     rdi, [rbx + rcx]                ; value = slot field
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_ok_outcome
    ret

.embedding_accessor_invalid:
    pop     rcx                             ; discard offset
    pop     rsi                             ; restore source_op
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_EMBEDDING
    call    .construct_err_outcome
    ret

; --- .sign_accessor_common (Pod 1.10.2b2 helper) ---
; Input:  rdi = sign_id, rcx = field offset, rsi = source_op
; Output: rax = outcome_id (Ok wrapping field value, or Err)
; No MAC verify — Sign slots don't carry MACs.
.sign_accessor_common:
    push    rsi                             ; preserve source_op
    push    rcx                             ; preserve offset

    test    rdi, rdi
    jz      .sign_accessor_invalid          ; sign_id=0 invalid

    call    registry_lookup_sign            ; rax = slot_ptr (0 if not found)
    test    rax, rax
    jz      .sign_accessor_invalid

    pop     rcx                             ; restore offset
    pop     rsi                             ; (source_op unused on success)
    mov     rdi, [rax + rcx]                ; field value
    mov     r8, TYPE_CODE_SIGN
    call    .construct_ok_outcome
    ret

.sign_accessor_invalid:
    pop     rcx
    pop     rsi
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_SIGN
    call    .construct_err_outcome
    ret

; --- .energy_accessor_common (Pod 1.10.2b2 helper) ---
.energy_accessor_common:
    push    rsi
    push    rcx

    test    rdi, rdi
    jz      .energy_accessor_invalid

    call    registry_lookup_energy
    test    rax, rax
    jz      .energy_accessor_invalid

    pop     rcx
    pop     rsi
    mov     rdi, [rax + rcx]
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_ok_outcome
    ret

.energy_accessor_invalid:
    pop     rcx
    pop     rsi
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_ENERGY
    call    .construct_err_outcome
    ret

; --- .outcome_accessor_common (Pod 1.10.2b2 helper) ---
.outcome_accessor_common:
    push    rsi
    push    rcx

    test    rdi, rdi
    jz      .outcome_accessor_invalid

    call    registry_lookup_outcome
    test    rax, rax
    jz      .outcome_accessor_invalid

    pop     rcx
    pop     rsi
    mov     rdi, [rax + rcx]
    mov     r8, TYPE_CODE_OUTCOME
    call    .construct_ok_outcome
    ret

.outcome_accessor_invalid:
    pop     rcx
    pop     rsi
    mov     rdi, ERR_INVALID_ID
    xor     rdx, rdx
    xor     rcx, rcx
    mov     r8, TYPE_CODE_OUTCOME
    call    .construct_err_outcome
    ret

; --- Pod 1.9.3: inline Ok Outcome construction helper ---
; Constructs an Ok Outcome directly via slot-write + registry-register
; (no dispatch roundtrip through OP_OUTCOME_NEW_OK). Used by refitted
; accessor success paths so they consistently return Outcome<T>.
; Per-opcode cost table is flat-per-opcode (debited at .fetch); handler
; internal Outcome construction is free relative to cost accounting.
;
; Internal calling convention (mirrors .construct_err_outcome):
;   Input:    rdi = value, r8 = value_type_id
;   Output:   rax = outcome_id (>=1 on success, 0 if Outcome pool full)
;   Clobbers: rax, rbx, rcx, rdx, rsi, rdi
;   Preserves: r12, r13, r14, r15, rbp, r8, r9, r10, r11
.construct_ok_outcome:
    push    r8                      ; value_type_id
    push    rdi                     ; value
    call    .outcome_alloc          ; rax = slot_ptr (0 if pool full)
    test    rax, rax
    jz      .construct_ok_outcome_fail
    mov     rbx, rax                ; slot_ptr
    pop     rdi                     ; value
    pop     r8                      ; value_type_id
    ; Write slot fields
    mov     qword [rbx + 0x00], 0   ; discriminant = ok
    mov     [rbx + 0x08], r8        ; value_type_id
    mov     [rbx + 0x10], rdi       ; value
    mov     qword [rbx + 0x18], 0   ; reserved
    ; Zero err context + Pod 3+ reserved + Move 3 fields + creator_cap_id
    ; (12 qwords at +0x20)
    push    r8
    push    rdi
    lea     rdi, [rbx + 0x20]
    xor     eax, eax
    mov     rcx, 12
    rep     stosq
    pop     rdi
    pop     r8
    ; Pod 1.10.2b2 retrofit per D1.10.1.8 — overwrite Move-3+creator fields
    ; with substrate state after stosq zeroed them.
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + 0x70], rax       ; arena_id
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + 0x78], rax       ; owner_demod_id
    mov     rax, [rel current_cap_id]
    mov     [rbx + OUTCOME_OFF_CREATOR_CAP_ID], rax  ; creator_cap_id at +0x68
    ; Register
    mov     rdi, rbx
    call    registry_register_outcome
    ; Pod 2.1 spatial-merge — Babylon charges lineage with dispatching opcode's cost.
    ; Helpers are called from many opcodes (Sign/Energy/Outcome/Cap accessors,
    ; Cap construction, etc.); current_dispatch_cost stash from fetch loop is
    ; the source of truth for the dispatching opcode's cost (per A1 / D2.1).
    push    rax                                 ; preserve outcome_id
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rax                                 ; restore outcome_id
    ret
.construct_ok_outcome_fail:
    add     rsp, 16                 ; discard 2 saved registers
    xor     rax, rax
    ret

; --- Pod 1.9.3: inline Err Outcome construction helper (D1.9.3.5) ---
; Constructs an Err Outcome directly via slot-write + registry-register
; (no dispatch roundtrip through OP_OUTCOME_NEW_ERR). Used by accessor
; failure paths and stack-violation refits.
;
; Internal calling convention:
;   Input:    rdi = err_code, rsi = source_op, rdx = demod_id,
;             rcx = fetch_counter, r8 = value_type_id
;   Output:   rax = outcome_id (>=1 on success, 0 if Outcome pool full)
;   Clobbers: rax, rbx, rcx, rdx, rsi, rdi
;   Preserves: r12, r13, r14, r15, rbp, r8, r9, r10, r11
;              (caller-side vm-state regs survive the call)
.construct_err_outcome:
    ; Save inputs across .outcome_alloc + registry_register_outcome
    push    r8                      ; value_type_id
    push    rcx                     ; fetch_counter
    push    rdx                     ; demod_id
    push    rsi                     ; source_op
    push    rdi                     ; err_code
    call    .outcome_alloc          ; rax = slot_ptr (0 if pool full)
    test    rax, rax
    jz      .construct_err_outcome_fail
    mov     rbx, rax                ; slot_ptr (preserved across registry_register_outcome)
    ; Restore inputs
    pop     rdi                     ; err_code
    pop     rsi                     ; source_op
    pop     rdx                     ; demod_id
    pop     rcx                     ; fetch_counter
    pop     r8                      ; value_type_id
    ; Write slot fields
    mov     qword [rbx + 0x00], 1   ; discriminant = err
    mov     [rbx + 0x08], r8        ; value_type_id
    mov     qword [rbx + 0x10], 0   ; value (unused for err)
    mov     qword [rbx + 0x18], 0   ; reserved
    mov     [rbx + 0x20], rdi       ; err_code
    mov     [rbx + 0x28], rsi       ; err_source_op
    mov     [rbx + 0x30], rdx       ; err_demod_id
    mov     [rbx + 0x38], rcx       ; err_fetch_counter
    mov     qword [rbx + 0x40], 0   ; Pod 3+ reserved
    mov     qword [rbx + 0x48], 0
    mov     qword [rbx + 0x50], 0
    mov     qword [rbx + 0x58], 0
    mov     qword [rbx + 0x60], 0
    ; Pod 1.10.2b2 retrofit per D1.10.1.8 — Move-3+creator fields written from
    ; substrate state instead of V1.0=0 placeholders.
    mov     rax, [rel current_cap_id]
    mov     [rbx + OUTCOME_OFF_CREATOR_CAP_ID], rax  ; creator_cap_id at +0x68
    mov     rax, [rel current_cap_arena_id_cache]
    mov     [rbx + 0x70], rax       ; arena_id
    mov     rax, [rel current_cap_owner_demod_id_cache]
    mov     [rbx + 0x78], rax       ; owner_demod_id
    ; Register
    mov     rdi, rbx
    call    registry_register_outcome  ; rax = outcome_id (0 if registry full)
    ; Pod 2.1 spatial-merge — Babylon charges lineage with dispatching opcode's cost.
    ; Per A1 / D2.1: current_dispatch_cost stash from fetch loop carries cost.
    push    rax                                 ; preserve outcome_id
    mov     rdi, [rel current_dispatch_cost]
    mov     rsi, [rel current_cap_id]
    call    babylon_charge_lineage
    pop     rax                                 ; restore outcome_id
    ret
.construct_err_outcome_fail:
    ; .outcome_alloc returned 0 — Outcome pool full. Restore stack and
    ; return 0 sentinel. Caller falls back to legacy 0 push.
    add     rsp, 40                 ; discard 5 saved registers
    xor     rax, rax
    ret

; vm_outcome_alloc: bump allocator for Outcome pool (matches sign_alloc/
; energy_alloc shape; no rcx/rdx 1-based id since registry assigns id).
; Output: rax = slot pointer (0 if pool full)
; Clobbers: rcx, rdx
.outcome_alloc:
    mov     rcx, [rel vm_outcome_next]
    cmp     rcx, OUTCOME_POOL_SLOTS
    jge     .outcome_alloc_full
    mov     rdx, rcx
    shl     rdx, 7                  ; index * 128 bytes per slot
    lea     rax, [rel vm_outcome_pool]
    add     rax, rdx
    inc     qword [rel vm_outcome_next]
    ret
.outcome_alloc_full:
    xor     rax, rax
    ret

; vm_energy_alloc: bump allocator for Energy pool (mirrors sign_alloc shape)
; Output: rax = slot pointer (0 if full), rdx = 1-based energy_id (0 if full)
; Clobbers: none beyond rax, rdx
.energy_alloc:
    mov     rdx, [rel vm_energy_next]
    cmp     rdx, ENERGY_POOL_SLOTS
    jge     .energy_alloc_full
    mov     rax, rdx
    shl     rax, 7                  ; index * 128 bytes per slot
    push    rdx                     ; save index across lea
    lea     rdx, [rel vm_energy_pool]
    add     rax, rdx                ; rax = pool base + byte offset
    pop     rdx                     ; restore index
    inc     qword [rel vm_energy_next]
    inc     rdx                     ; 1-based energy_id
    ret
.energy_alloc_full:
    xor     rax, rax
    xor     rdx, rdx
    ret

; vm_sign_alloc: bump allocator for Sign pool (widened cap_alloc_node shape)
; Output: rax = slot pointer (0 if pool full), rcx = 1-based sign_id (0 if full)
; Clobbers: rdx
.sign_alloc:
    mov     rcx, [rel vm_sign_next]
    cmp     rcx, 64                 ; 64 nodes max (A1)
    jge     .sign_alloc_full
    mov     rdx, rcx
    shl     rdx, 7                  ; index * 128 bytes per slot
    lea     rax, [rel vm_sign_pool]
    add     rax, rdx
    inc     qword [rel vm_sign_next]
    inc     rcx                     ; 1-based sign_id
    ret
.sign_alloc_full:
    xor     rax, rax
    xor     rcx, rcx
    ret

; vm_embedding_alloc: bump allocator for Embedding pool (Pod 3)
; Slot is 1576 bytes (197 qwords); not a power of 2 — uses imul.
; Output: rax = slot pointer (0 if pool full)
; Clobbers: rcx, rdx
.embedding_alloc:
    mov     rcx, [rel vm_embedding_next]
    cmp     rcx, EMBEDDING_POOL_SLOTS
    jge     .embedding_alloc_full
    mov     rax, rcx
    imul    rax, rax, EMBEDDING_SLOT_BYTES   ; index * 1576
    lea     rdx, [rel vm_embedding_pool]
    add     rax, rdx
    inc     qword [rel vm_embedding_next]
    ret
.embedding_alloc_full:
    xor     rax, rax
    ret

; --- HALT ---
.op_halt:
    lea     rsi, [rel str_vm_halt]
    call    auryn_puts

.done:
    ; Print energy summary (Pod 1.8: reads [rel energy_used], not r15)
    lea     rsi, [rel str_vm_eu]
    call    auryn_puts
    mov     rdi, [rel energy_used]
    call    print_dec
    lea     rsi, [rel str_vm_jr]
    call    auryn_puts
    mov     rdi, r14
    call    print_dec
    lea     rsi, [rel str_vm_jl]
    call    auryn_puts

    pop     rdx
    pop     rcx
    pop     rbp
    pop     rbx
    ret
