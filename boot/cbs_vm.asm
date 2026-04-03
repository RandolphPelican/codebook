; =============================================================
; CBS VM — CodebookScript Bytecode Interpreter
; cbs_run: r12=bytecode ptr, r14=energy budget
; Stack: vm_stack[], vars: vm_vars[], energy: energy_budget
; Opcodes: see defines.asm OP_* constants
; =============================================================

; =============================================================
; CBS BYTECODE VM
; =============================================================
; Registers used:
;   r12 = program counter (bytecode pointer)
;   r13 = VM stack pointer (grows upward)
;   r14 = energy budget (signed 32-bit)
;   r15 = energy used
; VM stack at vm_stack[], 256 entries (1024 qwords for safety)
; Variables at vm_vars[], 64 entries
; =============================================================

; cbs_run: r12 = pointer to bytecode, r14d = energy budget
; Returns when HALT or RET
cbs_run:
    push    rbx
    push    rbp
    mov     rbp, rsp
    push    rcx
    push    rdx

    lea     r13, [rel vm_stack]     ; VM stack base
    mov     qword [rel energy_used], 0

    ; Print header
    lea     rsi, [rel str_vm_start]
    call    auryn_puts

.fetch:
    ; Metabolic energy check
    test    r14d, r14d
    jz      .fatigue
    dec     r14d
    inc     qword [rel energy_used]
    movzx   eax, byte [r12]
    inc     r12

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

; --- PUSH imm32 ---
.op_push:
    mov     eax, [r12]
    add     r12, 4
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

; --- Arithmetic (pop b, pop a, push result) ---
.op_add:
    sub     r13, 8
    mov     ebx, [r13]      ; b
    sub     r13, 8
    mov     eax, [r13]      ; a
    add     eax, ebx
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_sub:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    sub     eax, ebx
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_mul:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    imul    eax, ebx
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_mod:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    test    ebx, ebx
    jz      .mod_zero
    xor     edx, edx
    div     ebx
    mov     [r13], edx
    add     r13, 8
    jmp     .fetch
.mod_zero:
    mov     dword [r13], 0
    add     r13, 8
    jmp     .fetch

.op_div:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    test    ebx, ebx
    jz      .div_zero
    cdq
    idiv    ebx
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch
.div_zero:
    mov     dword [r13], 0
    add     r13, 8
    jmp     .fetch

; --- Comparisons ---
.op_eq:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    sete    al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_ne:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    setne   al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_lt:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    setl    al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_gt:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    setg    al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_le:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    setle   al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_ge:
    sub     r13, 8
    mov     ebx, [r13]
    sub     r13, 8
    mov     eax, [r13]
    cmp     eax, ebx
    setge   al
    movzx   eax, al
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

; --- RESERVE energy ---
.op_reserve:
    mov     eax, [r12]
    add     r12, 4
    cmp     r14d, eax
    jl      .reserve_fail
    sub     r14d, eax
    add     r15d, eax
    ; Print reservation
    lea     rsi, [rel str_vm_rsv]
    call    auryn_puts
    mov     edi, eax
    call    print_dec
    lea     rsi, [rel str_vm_jok]
    call    auryn_puts
    jmp     .fetch
.reserve_fail:
    lea     rsi, [rel str_vm_deg]
    call    auryn_puts
    ; Skip to HALT or RET
.skip_to_end:
    movzx   eax, byte [r12]
    inc     r12
    cmp     al, OP_HALT
    je      .op_halt
    cmp     al, OP_RET
    je      .op_ret
    ; Skip operands for known opcodes
    cmp     al, OP_PUSH
    je      .skip4
    cmp     al, OP_RESERVE
    je      .skip4
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

; --- RET ---
.op_ret:
    ; Pop result if stack non-empty
    lea     rax, [rel vm_stack]
    cmp     r13, rax
    jle     .ret_empty
    sub     r13, 8
    mov     edi, [r13]
    lea     rsi, [rel str_vm_ret]
    call    auryn_puts
    call    print_sdec
    lea     rsi, [rel str_nl]
    call    auryn_puts
    jmp     .done
.ret_empty:
    lea     rsi, [rel str_vm_ret]
    call    auryn_puts
    lea     rsi, [rel str_vm_void]
    call    auryn_puts
    jmp     .done

; --- JUMP_IF_FALSE ---
.op_jif:
    mov     eax, [r12]      ; offset (signed)
    add     r12, 4
    sub     r13, 8
    mov     ebx, [r13]      ; condition
    test    ebx, ebx
    jnz     .fetch           ; not zero = true, don't jump
    add     r12, rax         ; jump forward by offset
    jmp     .fetch

; --- JUMP_BACK ---
.op_jback:
    mov     eax, [r12]
    add     r12, 4
    sub     r12, rax         ; jump backward
    jmp     .fetch

; --- LOAD var ---
.op_load:
    mov     eax, [r12]
    add     r12, 4
    lea     rbx, [rel vm_vars]
    mov     eax, [rbx + rax*4]
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

; --- STORE var ---
.op_store:
    mov     eax, [r12]
    add     r12, 4
    sub     r13, 8
    mov     ebx, [r13]
    lea     rcx, [rel vm_vars]
    mov     [rcx + rax*4], ebx
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
    ; Call UEFI ReadKey
    push    rbp
    lea     rbx,[rel uefi_data]
    mov     rcx,[rbx+24]
    mov     rax,[rcx+CONIN_READKEY]
    lea     rdx,[rel key_data]
    call    rax
    pop     rbp
    test    rax,rax
    jnz     .conin_none
    movzx   eax,word [rel key_data+2] ; UnicodeChar
    mov     [r13], rax
    add     r13, 8
    jmp     .fetch
.conin_none:
    mov     dword [r13], 0
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
    mov     edi, [r13]
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

; --- Stack ops ---
.op_dup:
    mov     eax, [r13 - 8]
    mov     [r13], eax
    add     r13, 8
    jmp     .fetch

.op_drop:
    sub     r13, 8
    jmp     .fetch

.op_swap:
    mov     eax, [r13 - 8]
    mov     ebx, [r13 - 16]
    mov     [r13 - 16], eax
    mov     [r13 - 8], ebx
    jmp     .fetch

; --- JMP (unconditional, signed i32 offset from next instr) ---
.op_call:
    ; Pop target PC
    sub     r13, 8
    mov     rax, [r13]
    ; Save current r12 to vm_ret_stack
    push    rbx
    lea     rbx, [rel vm_ret_ptr]
    mov     rcx, [rbx]
    shl     rcx, 3
    lea     rdx, [rel vm_ret_stack]
    add     rdx, rcx
    mov     [rdx], r12
    inc     qword [rbx]
    pop     rbx
    mov     r12, rax
    jmp     .fetch

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

; --- HALT ---
.op_halt:
    lea     rsi, [rel str_vm_halt]
    call    auryn_puts

.done:
    ; Print energy summary
    lea     rsi, [rel str_vm_eu]
    call    auryn_puts
    mov     edi, r15d
    call    print_dec
    lea     rsi, [rel str_vm_jr]
    call    auryn_puts
    mov     edi, r14d
    call    print_dec
    lea     rsi, [rel str_vm_jl]
    call    auryn_puts

    pop     rdx
    pop     rcx
    pop     rbp
    pop     rbx
    ret
