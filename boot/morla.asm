; =============================================================
; Morla — FAT32 Filesystem Driver
; morla_write_file, morla_ls, morla_run_file, boot_bastian,
; morla_run_file_main
; Depends: sfsp_ptr, root_ptr, file_ptr, auryn_puts, cbs_run
; History: auryn_puts originally sat here from the monolith
;          split; consolidated into auryn.asm in Pod 0.7.
; =============================================================

morla_write_file:
    ; rdi = filename (ascii), rsi = buffer, rdx = size
    push rbx
    push r12
    push r13
    push rdx ; save size
    push rsi ; save buffer

    cmp byte [rel uefi_exited], 1
    je .native_fat32

    ; UEFI path
    mov rsi, rdi
    lea rdi, [rel filename_ucs2]
    call ascii_to_ucs2

    sub rsp, 48
    mov rcx, [rel root_ptr]
    test rcx, rcx
    jz .err

    lea rdx, [rel file_ptr]
    lea r8, [rel filename_ucs2]
    ; Open for Create (0x80...0) + Read (0x1) + Write (0x2)
    mov r9, 0x8000000000000000 | 0x0000000000000001 | 0x0000000000000002
    mov qword [rsp + 32], 0 ; Attributes
    mov rax, [rcx + 0x08]
    call rax
    add rsp, 48
    test rax, rax
    jnz .err_pop

    mov rbx, [rel file_ptr]
    pop r8  ; buffer
    pop rdx ; size ptr (we need a pointer to size)
    lea r9, [rel temp_size]
    mov [r9], rdx
    mov rdx, r9

    mov rax, [rbx + 0x28] ; Write
    mov rcx, rbx
    call rax

    ; Close
    mov rax, [rbx + 0x10]
    mov rcx, rbx
    call rax
    jmp .d

.native_fat32:
    ; Native FAT32 write deferred to V1.1 -- driver in
    ; drivers/_future/fat32_write.asm pending smoke-testing.
    ; Route to .err_pop which pops saved buffer/size (16 bytes).
    jmp .err_pop

.d: pop r13
    pop r12
    pop rbx
    ret

.err_pop:
    add rsp, 16 ; pop saved buffer and size
.err:
    lea rsi, [rel str_ls_err]
    call auryn_puts
    jmp .d

morla_ls:
    push rbx
    push r12
    push r13
    mov rbx, [rel root_ptr]
    test rbx, rbx
    jz .f
    mov rax, [rbx + 0x38] ; SetPosition
    mov rcx, rbx
    xor rdx, rdx
    call rax
.l:
    mov qword [rel temp_size], 512
    mov rax, [rbx + 0x20]
    mov rcx, rbx
    lea rdx, [rel temp_size]
    lea r8, [rel file_info_buf]
    call rax
    test rax,rax
    jnz .f
    mov rax, [rel temp_size]
    test rax, rax
    jz .d
    lea rsi, [rel file_info_buf + 80]
    call ucs2_to_ascii
    lea rsi, [rel ascii_buf]
    call auryn_puts
    lea rsi, [rel str_nl]
    call auryn_puts
    jmp .l
.f: lea rsi, [rel str_ls_err]
    call auryn_puts
.d: pop r13
    pop r12
    pop rbx
    ret

ucs2_to_ascii:
    push rsi
    push rdi
    lea rdi, [rel ascii_buf]
.l: mov ax, [rsi]
    mov [rdi], al
    test ax, ax
    jz .d
    add rsi, 2
    inc rdi
    jmp .l
.d: pop rdi
    pop rsi
    ret

ascii_to_ucs2:
    push rsi
    push rdi
.l: movzx eax,byte [rsi]
    mov [rdi],ax
    test al,al
    jz .d
    add rdi,2
    inc rsi
    jmp .l
.d: pop rdi
    pop rsi
    ret

morla_run_file:
    push rbx
    push r12
    push rsi
    mov rsi, rdi
    cmp byte [rel uefi_exited], 1
    je .native_fat32
    ; UEFI path
    lea rdi, [rel filename_ucs2]
    call ascii_to_ucs2
    sub rsp, 48
    mov rcx, [rel root_ptr]
    test rcx, rcx
    jz .f
    lea rdx, [rel file_ptr]
    lea r8, [rel filename_ucs2]
    mov r9, 1
    mov qword [rsp + 32], 0
    mov rax, [rcx + 0x08]
    call rax
    add rsp, 48
    test rax, rax
    jnz .f
    mov rbx, [rel file_ptr]
    mov qword [rel temp_size], 65536
    mov rax, [rbx + 0x20]
    mov rcx, rbx
    lea rdx, [rel temp_size]
    lea r8, [rel external_prog_buf]
    call rax
    test rax, rax
    jnz .f_close
    lea r12, [rel external_prog_buf]
    mov r14d, 100000
    call cbs_run
.f_close:
    mov rbx, [rel file_ptr]
    mov rax, [rbx + 0x10]
    mov rcx, rbx
    call rax
    jmp .d
.native_fat32:
    ; Native FAT32 path
    call fat32_load_file
    cmp rax, -1
    je .f
    lea r12, [rel external_prog_buf]
    mov r14d, 100000
    call cbs_run
    jmp .d
.f: lea rsi, [rel str_run_bad]
    call auryn_puts
.d: pop rsi
    pop r12
    pop rbx
    ret

boot_bastian:
    lea rsi, [rel str_bastian_filename]
    call morla_run_file_main
    jmp .hang
.hang: hlt
    jmp .hang

str_bastian_filename: db 'bastian.cbc',0

morla_run_file_main:
    push rbx
    push r12
    push rsi
    mov rsi, rdi
    lea rdi, [rel filename_ucs2]
    call ascii_to_ucs2
    sub rsp, 48
    mov rcx, [rel root_ptr]
    test rcx, rcx
    jz .f
    lea rdx, [rel file_ptr]
    lea r8, [rel filename_ucs2]
    mov r9, 1
    mov qword [rsp + 32], 0
    mov rax, [rcx + 0x08]
    call rax
    add rsp, 48
    test rax, rax
    jnz .f
    mov rbx, [rel file_ptr]
    mov qword [rel temp_size], 65536
    mov rax, [rbx + 0x20]
    mov rcx, rbx
    lea rdx, [rel temp_size]
    lea r8, [rel external_prog_buf]
    call rax
    test rax, rax
    jnz .f_close
    lea r12, [rel external_prog_buf]
    mov r14d, 100000 ; Initial energy for home surface
    call cbs_run
.f_close:
    mov rbx, [rel file_ptr]
    mov rax, [rbx + 0x10]
    mov rcx, rbx
    call rax
    jmp .d
.f: lea rsi, [rel str_run_bad]
    call auryn_puts
.d: pop rsi
    pop r12
    pop rbx
    ret
