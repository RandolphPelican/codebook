; =============================================================
; Gmork — Terminal Commands + System Info
; gmork_main, get_mmap, show_memmap, paint_bars
; Included after bastian.asm to preserve original assembly order.
; Depends: auryn_*, morla_*, cbs_run, bastian_home, bastian_main
; =============================================================

gmork_main:
    lea rsi,[rel str_banner]
    call auryn_puts

.prompt:
    lea rsi,[rel str_prompt]
    call auryn_puts
    lea r12,[rel input_buf]
    xor r13d,r13d

.rk:
    cmp     byte [rel uefi_exited], 1
    je      .rk_native
.rk_uefi:
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_WAITFOREVENT]
    mov ecx,1
    mov rdx,[rbx+24]
    lea rdx,[rdx+CONIN_WAITKEY]
    lea r8,[rel event_index]
    call rax
    lea rbx,[rel uefi_data]
    mov rcx,[rbx+24]
    mov rax,[rcx+CONIN_READKEY]
    lea rdx,[rel key_data]
    call rax
    test rax,rax
    jnz .rk
    movzx eax,word [rel key_data+2]
    jmp     .rk_got_char
.rk_native:
    call    native_keyboard_read        ; poll PS/2 port 0x60 via kbd_ps2.asm
    test    rax, rax                    ; rax=0 → key ready, rax=1 → not yet
    jnz     .rk_native                  ; spin until a make event lands
    movzx   eax, word [rel key_data+2]  ; pick up translated ASCII char
.rk_got_char:
    cmp al,13
    je .exec
    cmp al,8
    je .kbs
    cmp al,32
    jb .rk
    cmp al,126
    ja .rk
    cmp r13d,126
    jge .rk
    mov [r12+r13],al
    inc r13d
    movzx edi,al
    call auryn_putc
    jmp .rk
.kbs:
    test r13d,r13d
    jz .rk
    dec r13d
    mov edi,8
    call auryn_putc
    jmp .rk
.exec:
    mov byte [r12+r13],0
    mov edi,10
    call auryn_putc
    test r13d,r13d
    jz .prompt

    lea rdi,[rel input_buf]

    ; === Command dispatch ===
    lea rsi,[rel c_help]
    call str_eq
    test eax,eax
    jnz .c_help

    lea rsi,[rel c_about]
    call str_eq
    test eax,eax
    jnz .c_about

    lea rsi,[rel c_clear]
    call str_eq
    test eax,eax
    jnz .c_clear

    lea rsi,[rel c_colors]
    call str_eq
    test eax,eax
    jnz .c_colors

    lea rsi,[rel c_fb]
    call str_eq
    test eax,eax
    jnz .c_fb

    lea rsi,[rel c_mem]
    call str_eq
    test eax,eax
    jnz .c_mem

    lea rsi,[rel c_ls]
    call str_eq
    test eax,eax
    jnz .c_ls

    lea rsi,[rel c_load]
    call starts_with
    test rax,rax
    jnz .c_load

    lea rsi,[rel c_reboot]
    call str_eq
    test eax,eax
    jnz .c_reboot

    lea rsi,[rel c_progs]
    call str_eq
    test eax,eax
    jnz .c_programs

    lea rsi,[rel c_exit]
    call str_eq
    test eax,eax
    jnz bastian_main

    lea rsi,[rel c_home]
    call str_eq
    test eax,eax
    jnz bastian_home

    ; Prefix: run N
    lea rdi,[rel input_buf]
    lea rsi,[rel p_run]
    call starts_with
    test rax,rax
    jnz .c_run

    ; Prefix: echo
    lea rdi,[rel input_buf]
    lea rsi,[rel p_echo]
    call starts_with
    test rax,rax
    jnz .c_echo

    ; Prefix: peek
    lea rdi,[rel input_buf]
    lea rsi,[rel p_peek]
    call starts_with
    test rax,rax
    jnz .c_peek

    ; Prefix: dump
    lea rdi,[rel input_buf]
    lea rsi,[rel p_dump]
    call starts_with
    test rax,rax
    jnz .c_dump

    ; Prefix: fill
    lea rdi,[rel input_buf]
    lea rsi,[rel p_fill]
    call starts_with
    test rax,rax
    jnz .c_fill

    ; Unknown
    lea rsi,[rel str_unk]
    call auryn_puts
    lea rsi,[rel input_buf]
    call auryn_puts
    lea rsi,[rel str_nl]
    call auryn_puts
    jmp .prompt

; ---- Commands ----
.c_help:
    lea rsi,[rel str_help]
    call auryn_puts
    jmp .prompt

.c_ls:
    call morla_ls
    jmp .prompt

.c_load:
    mov rdi, rax ; rax points to filename after 'load '
    call morla_run_file
    jmp .prompt

.c_about:
    lea rsi,[rel str_about]
    call auryn_puts
    jmp .prompt

.c_clear:
    mov edi,COLOR_BLACK
    call auryn_fill
    call cursor_home
    jmp .prompt

.c_colors:
    call paint_bars
    lea rsi,[rel str_bars_ok]
    call auryn_puts
    jmp .prompt

.c_fb:
    lea rsi,[rel str_fb1]
    call auryn_puts
    lea rsi,[rel str_fb_b]
    call auryn_puts
    mov rdi,[rel fb_base]
    call print_hex64
    lea rsi,[rel str_nl]
    call auryn_puts
    lea rsi,[rel str_fb_r]
    call auryn_puts
    mov edi,[rel fb_width]
    call print_dec
    mov edi,'x'
    call auryn_putc
    mov edi,[rel fb_height]
    call print_dec
    lea rsi,[rel str_nl]
    call auryn_puts
    jmp .prompt

.c_echo:
    mov rsi,rax
    call auryn_puts
    lea rsi,[rel str_nl]
    call auryn_puts
    jmp .prompt

.c_peek:
    mov rsi,rax
    call parse_hex
    push rax
    lea rsi,[rel str_pk1]
    call auryn_puts
    pop rax
    push rax
    mov rdi,rax
    call print_hex64
    lea rsi,[rel str_pk2]
    call auryn_puts
    pop rax
    mov edi,[rax]
    call print_hex32
    lea rsi,[rel str_nl]
    call auryn_puts
    jmp .prompt

.c_dump:
    mov rsi,rax
    call parse_hex
    mov r14,rax
    xor r15d,r15d
.dr: cmp r15d,16
    jge .prompt
    mov rdi,r14
    mov rax,r15
    shl rax,4
    add rdi,rax
    push rdi
    call print_hex64
    lea rsi,[rel str_col]
    call auryn_puts
    pop rdi
    xor ecx,ecx
.db: cmp ecx,16
    jge .dn
    push rcx
    push rdi
    movzx eax,byte [rdi+rcx]
    push rax
    shr al,4
    cmp al,10
    jb .hd
    add al,'A'-10
    jmp .hp
.hd: add al,'0'
.hp: movzx edi,al
    call auryn_putc
    pop rax
    and al,0xF
    cmp al,10
    jb .ld
    add al,'A'-10
    jmp .lp
.ld: add al,'0'
.lp: movzx edi,al
    call auryn_putc
    mov edi,' '
    call auryn_putc
    pop rdi
    pop rcx
    inc ecx
    jmp .db
.dn: mov edi,10
    call auryn_putc
    inc r15d
    jmp .dr

.c_fill:
    mov rsi,rax
    call parse_hex
    mov edi,eax
    call auryn_fill
    call cursor_home
    lea rsi,[rel str_fill_ok]
    call auryn_puts
    jmp .prompt

.c_mem:
    call show_memmap
    jmp .prompt

.c_reboot:
    lea rsi,[rel str_reboot]
    call auryn_puts
    call stall_1000
    lea rbx,[rel uefi_data]
    mov rax,[rbx+40]
    mov rax,[rax+RS_RESETSYSTEM]
    xor ecx,ecx
    xor edx,edx
    xor r8d,r8d
    xor r9d,r9d
    call rax
    jmp .prompt

; ---- PROGRAMS (list CBS demos) ----
.c_programs:
    lea rsi,[rel str_prog_list]
    call auryn_puts
    jmp .prompt

; ---- RUN N (execute CBS bytecode) ----
.c_run:
    ; rax = pointer to char after "run "
    mov rsi, rax
    movzx eax, byte [rsi]
    sub al, '0'

    cmp al, 0
    je .run_0
    cmp al, 1
    je .run_1
    cmp al, 2
    je .run_2
    cmp al, 3
    je .run_3
    cmp al, 4
    je .run_4
    cmp al, 5
    je .run_5
    cmp al, 6
    je .run_6
    cmp al, 7
    je .run_7
    jmp .run_bad

.run_0: lea r12, [rel cbs_demo]
    jmp .run_go
.run_1: lea r12, [rel prog1]
    jmp .run_go
.run_2: lea r12, [rel prog2]
    jmp .run_go
.run_3: lea r12, [rel prog3]
    jmp .run_go
.run_4: lea r12, [rel prog4]
    jmp .run_go
.run_5: lea r12, [rel surface_hello]
    jmp .run_go
.run_6: lea r12, [rel surface_sched_stub]
    jmp .run_go
.run_7: lea r12, [rel surface_compiler_stub]
    jmp .run_go

.run_go:
    mov r14d, 10000             ; energy budget = 10000j
    call cbs_run
    jmp .prompt

.run_bad:
    lea rsi,[rel str_run_bad]
    call auryn_puts
    jmp .prompt


; =============================================================
; get_mmap / show_memmap
; =============================================================
get_mmap:
    push rbx
    push rbp
    mov rbp,rsp
    sub rsp,48
    mov qword [rel mmap_size],8192
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_GETMEMMAP]
    lea rcx,[rel mmap_size]
    lea rdx,[rel mmap_buf]
    lea r8,[rel mmap_key]
    lea r9,[rel mmap_desc_sz]
    lea rax,[rel mmap_desc_ver]
    mov [rsp+32],rax
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_GETMEMMAP]
    call rax
    leave
    pop rbx
    ret

show_memmap:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp,rsp
    sub rsp,48
    call get_mmap
    test rax,rax
    jnz .f
    lea rsi,[rel str_mhdr]
    call auryn_puts
    lea r12,[rel mmap_buf]
    mov r13,[rel mmap_size]
    add r13,r12
    mov r14d,[rel mmap_desc_sz]
    xor r15d,r15d
.l: cmp r12,r13
    jge .d
    mov edi,[r12]
    cmp edi,15
    jae .u
    lea rax,[rel mtypes]
    mov rsi,[rax+rdi*8]
    call auryn_puts
    jmp .p
.u: lea rsi,[rel str_mt_unk]
    call auryn_puts
    mov edi,[r12]
    call print_dec
.p: lea rsi,[rel str_sp]
    call auryn_puts
    mov rdi,[r12+8]
    call print_hex64
    lea rsi,[rel str_sp]
    call auryn_puts
    mov edi,[r12+24]
    call print_dec
    lea rsi,[rel str_pg]
    call auryn_puts
    movzx eax,r14w
    add r12,rax
    inc r15d
    jmp .l
.d: lea rsi,[rel str_mtot]
    call auryn_puts
    mov edi,r15d
    call print_dec
    lea rsi,[rel str_ment]
    call auryn_puts
    jmp .o
.f: lea rsi,[rel str_mfail]
    call auryn_puts
.o: leave
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

paint_bars:
    push rbx
    push r12
    push r13
    push r14
    push rcx
    mov r12d,[rel fb_height]
    mov r13d,[rel fb_ppsl]
    mov rbx,[rel fb_base]
    test rbx,rbx
    jz .d
    shr r12d,3
    lea r14,[rel color_table]
    xor ecx,ecx
.b: cmp ecx,8
    jge .d
    mov edi,[r14+rcx*4]
    push rcx
    push rax
    mov eax, edi
    call fixup_color
    mov edi, eax
    pop rax
    mov edx,r12d
    imul edx,r13d
.f: test edx,edx
    jz .n
    mov [rbx],edi
    add rbx,4
    dec edx
    jmp .f
.n: pop rcx
    inc ecx
    jmp .b
.d: pop rcx
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
