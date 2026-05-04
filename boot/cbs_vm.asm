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
    ; Debit energy
    sub     r14, rbx
    add     [rel energy_used], rbx

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

    ; Unknown opcode
    lea     rsi, [rel str_vm_unk]
    call    auryn_puts
    movzx   edi, al
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
    ; Validate label length <= 63 (A4)
    movzx   eax, byte [r11]
    cmp     eax, 63
    ja      .sign_new_fail
    ; Validate embedding_handle: must be 0 in V1.0 (handle pools land Pod 3+)
    test    r9, r9
    jnz     .sign_new_fail
    ; (provenance_handle check removed Pod 1.8.5c; field reclaimed for arena_id)
    ; Allocate pool slot
    call    .sign_alloc
    test    rax, rax
    jz      .sign_new_fail
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
    mov     qword [rdi + 8], 0  ; embedding_handle at +0x68 (reserved Pod 3+)
    mov     qword [rdi + 16], 0 ; arena_id at +0x70 (Pod 1.8.5c Move 3; V1.0 = 0)
    mov     qword [rdi + 24], 0 ; owner_demod_id at +0x78 (Pod 1.8.5c Move 3; V1.0 = 0)
    ; Pod 1.8.5b Move 4: register slot in canonical-ID registry.
    pop     rdi                 ; restore slot_ptr as registry input
    call    registry_register_sign
    test    rax, rax
    jz      .sign_new_fail      ; registry full (capacities matched, should not occur in V1.0)
    ; Push sign_id (rax) on operand stack
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.sign_new_fail:
    ; Validation failed or pool full: push null handle (0)
    mov     qword [r13], 0
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
    ; Pop sign_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_sign    ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .sign_energy_null
    mov     rbx, rax
    ; energy_cost at slot+0x60
    mov     rax, [rbx + 0x60]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.sign_energy_null:
    mov     qword [r13], 0
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
    ; Allocate pool slot
    call    .energy_alloc
    test    rax, rax
    jz      .energy_new_fail
    ; rax = slot pointer; rdx (bump-index energy_id) discarded under Move 4
    mov     [rax + ENERGY_OFF_JOULES], rcx      ; joules at +0x00
    mov     [rax + ENERGY_OFF_SOURCE_OP], rbx   ; source_op at +0x08
    ; Pod 1.8.5c Move 3: arena_id at +0x10, owner_demod_id at +0x18
    mov     qword [rax + 0x10], 0   ; arena_id (V1.0 = 0)
    mov     qword [rax + 0x18], 0   ; owner_demod_id (V1.0 = 0)
    ; Zero reserved area (96 bytes at +0x20)
    push    rax                     ; save slot_ptr across stosq + register
    lea     rdi, [rax + 0x20]
    xor     eax, eax
    mov     rcx, 12                 ; 12 * 8 = 96 bytes
    rep     stosq
    pop     rdi                     ; restore slot_ptr as registry input
    ; Pod 1.8.5b Move 4: register slot in canonical-ID registry.
    call    registry_register_energy
    test    rax, rax
    jz      .energy_new_fail        ; registry full (capacities matched, should not occur in V1.0)
    ; Push energy_id (rax) on operand stack
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.energy_new_fail:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.op_energy_joules:
    ; Pod 1.8.5b Move 4: resolve energy_id via registry indirection.
    ; Pop energy_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_energy  ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .energy_joules_null
    mov     rbx, rax
    ; Read joules at +0x00
    mov     rax, [rbx + ENERGY_OFF_JOULES]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.energy_joules_null:
    mov     qword [r13], 0
    add     r13, 8
    jmp     .fetch

.op_energy_source_op:
    ; Pod 1.8.5b Move 4: resolve energy_id via registry indirection.
    ; Pop energy_id
    sub     r13, 8
    mov     rdi, [r13]
    call    registry_lookup_energy  ; rax = slot_ptr (0 if invalid)
    test    rax, rax
    jz      .energy_source_op_null
    mov     rbx, rax
    ; Read source_op at +0x08
    mov     rax, [rbx + ENERGY_OFF_SOURCE_OP]
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.energy_source_op_null:
    mov     qword [r13], 0
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
