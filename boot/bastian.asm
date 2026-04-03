; =============================================================
; Bastian — Home Surface
; bastian_home, bastian_main, surface_table
; Depends: auryn_puts, auryn_fill, morla_run_file, gmork_main
; =============================================================

bastian_home:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    mov dword [rel current_color], COLOR_GOLD
    lea rsi, [rel str_bh_pad]
    call auryn_puts
    lea rsi, [rel str_bh_title]
    call auryn_puts
    mov dword [rel current_color], COLOR_WHITE
    lea rsi, [rel str_bh_sub]
    call auryn_puts
    lea rsi, [rel str_bh_menu]
    call auryn_puts
    lea rsi, [rel str_bh_prompt]
    call auryn_puts

.key:
    cmp     byte [rel uefi_exited], 1
    je      .key_native
.key_uefi:
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
    jnz .key
    movzx eax,word [rel key_data+2]
    jmp     .key_dispatch
.key_native:
    ; TODO Phase 2.1: poll PS/2 port 0x60, translate scancode → key_data+2
    jmp     .key_native
.key_dispatch:
    cmp al,'1'
    je .go_gmork
    cmp al,'2'
    je .go_atreyu
    cmp al,'3'
    je .go_rockbiter
    cmp al,'4'
    je .go_run
    jmp .key

.go_gmork:
    jmp gmork_main

.go_atreyu:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    lea r12, [rel atreyu_cbs_prog]
    mov r14d, 100000
    call cbs_run
    jmp bastian_home

.go_rockbiter:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    lea r12, [rel rockbiter_cbs_prog]
    mov r14d, 100000
    call cbs_run
    jmp bastian_home

.go_run:
    lea rsi, [rel str_bh_run_prompt]
    call auryn_puts
.gr_key:
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
    jnz .gr_key
    movzx eax,word [rel key_data+2]
    cmp al,'0'
    jb .go_run
    cmp al,'7'
    ja .go_run
    movzx edi, al
    call auryn_putc
    mov edi, 10
    call auryn_putc
    sub eax, '0'
    lea rbx, [rel prog_table]
    mov r12, [rbx + rax*8]
    mov r14d, 100000
    call cbs_run
    jmp bastian_home

bastian_main:
    mov edi, COLOR_BLACK
    call auryn_fill
    mov dword [rel bastian_sel], 1

.redraw:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    lea rsi, [rel str_bastian_head]
    mov dword [rel current_color], COLOR_GOLD
    call auryn_puts

    mov ecx, 1
.sl:
    cmp ecx, [rel bastian_sel]
    jne .sn
    mov dword [rel current_color], COLOR_GOLD
    lea rsi, [rel str_sel_pre]
    call auryn_puts
    jmp .sp
.sn:
    mov dword [rel current_color], COLOR_WHITE
    lea rsi, [rel str_sel_none]
    call auryn_puts
.sp:
    lea rbx, [rel surface_table]
    mov rsi, [rbx + rcx*8 - 8]
    call auryn_puts
    lea rsi, [rel str_nl]
    call auryn_puts

    inc ecx
    cmp ecx, 13
    jl .sl

.rk:
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

    movzx eax,word [rel key_data]     ; ScanCode
    cmp eax, 0x01   ; UP
    je .up
    cmp eax, 0x02   ; DOWN
    je .down

    movzx eax,word [rel key_data+2]   ; UnicodeChar
    cmp al, 13      ; ENTER
    je .launch
    jmp .rk

.up:
    mov eax, [rel bastian_sel]
    dec eax
    test eax, eax
    jnz .up_ok
    mov eax, 12
.up_ok:
    mov [rel bastian_sel], eax
    jmp .redraw

.down:
    mov eax, [rel bastian_sel]
    inc eax
    cmp eax, 13
    jl .dn_ok
    mov eax, 1
.dn_ok:
    mov [rel bastian_sel], eax
    jmp .redraw

.launch:
    mov eax, [rel bastian_sel]
    cmp eax, 1
    je gmork_main
    ; Else, stub
    lea rsi, [rel str_stub]
    call auryn_puts
    call stall_1500
    jmp .redraw

surface_table:
    dq str_s1, str_s2, str_s3, str_s4, str_s5, str_s6, str_s7, str_s8, str_s9, str_s10, str_s11, str_s12

str_bastian_head: db '         --- BASTIAN HOME ---',10,10,0
str_sel_pre:  db '> ',0
str_sel_none: db '  ',0
str_stub:     db '  Surface stubbed. Coming soon...',10,0
str_s1: db 'Gmork (Terminal)',0
str_s2: db 'Auryn (Display)',0
str_s3: db 'Morla (Filesystem)',0
str_s4: db 'Atreyu (Editor)',0
str_s5: db 'Bastian (Home)',0
str_s6: db 'Empress (Search)',0
str_s7: db 'Falkor (Browser)',0
str_s8: db 'Auryn msg (Messenger)',0
str_s9: db 'Rockbiter (Processes)',0
str_s10: db 'Bullies (Security)',0
str_s11: db 'Artax (Recovery)',0
str_s12: db 'Koreander (Docs)',0
