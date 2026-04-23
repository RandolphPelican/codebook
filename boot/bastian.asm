; =============================================================
; Bastian — Home Surface
; bastian_home, bastian_main, surface_table
; Depends: auryn_puts, auryn_fill, morla_run_file, gmork_main
; =============================================================

show_coming_soon:
    ; In:  rsi = pointer to null-terminated flavor string
    ; Clobbers: rax, rbx, rcx, rdx, rsi, r8
    push rsi
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    mov dword [rel current_color], COLOR_GOLD
    lea rsi, [rel str_bh_pad]
    call auryn_puts
    pop rsi
    call auryn_puts
    mov dword [rel current_color], COLOR_WHITE
    lea rsi, [rel str_soon_press]
    call auryn_puts
.scs_wait:
    cmp byte [rel uefi_exited], 1
    je .scs_wait_native
.scs_wait_uefi:
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
    jnz .scs_wait_uefi
    ret
.scs_wait_native:
    call native_keyboard_read
    test rax, rax
    jnz .scs_wait_native
    ret

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
    call    native_keyboard_read
    test    rax, rax
    jnz     .key_native
    movzx   eax, word [rel key_data+2]
.key_dispatch:
    cmp al,'1'
    je bastian_home
    cmp al,'2'
    je .go_gmork
    cmp al,'3'
    je .soon_morla
    cmp al,'4'
    je .go_atreyu
    cmp al,'5'
    je .go_rockbiter
    cmp al,'6'
    je .soon_auryn
    cmp al,'7'
    je .soon_empress
    cmp al,'8'
    je .soon_koreander
    cmp al,'9'
    je .soon_falkor
    cmp al,'a'
    je .soon_sphinx
    cmp al,'A'
    je .soon_sphinx
    cmp al,'b'
    je .soon_artax
    cmp al,'B'
    je .soon_artax
    cmp al,'c'
    je .soon_engywook
    cmp al,'C'
    je .soon_engywook
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

.soon_morla:
    lea rsi, [rel str_soon_morla]
    call show_coming_soon
    jmp bastian_home
.soon_auryn:
    lea rsi, [rel str_soon_auryn]
    call show_coming_soon
    jmp bastian_home
.soon_empress:
    lea rsi, [rel str_soon_empress]
    call show_coming_soon
    jmp bastian_home
.soon_koreander:
    lea rsi, [rel str_soon_koreander]
    call show_coming_soon
    jmp bastian_home
.soon_falkor:
    lea rsi, [rel str_soon_falkor]
    call show_coming_soon
    jmp bastian_home
.soon_sphinx:
    lea rsi, [rel str_soon_sphinx]
    call show_coming_soon
    jmp bastian_home
.soon_artax:
    lea rsi, [rel str_soon_artax]
    call show_coming_soon
    jmp bastian_home
.soon_engywook:
    lea rsi, [rel str_soon_engywook]
    call show_coming_soon
    jmp bastian_home

bastian_main:
    mov dword [rel bastian_sel], 0

.redraw:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    mov dword [rel current_color], COLOR_GOLD
    lea rsi, [rel str_bh_pad]
    call auryn_puts
    lea rsi, [rel str_bastian_head]
    call auryn_puts
    mov dword [rel current_color], COLOR_WHITE
    xor ecx, ecx
.row:
    push rcx
    mov eax, [rel bastian_sel]
    cmp eax, ecx
    jne .row_no_sel
    mov dword [rel current_color], COLOR_GOLD
    lea rsi, [rel str_sel_pre]
    jmp .row_puts_pfx
.row_no_sel:
    lea rsi, [rel str_sel_none]
.row_puts_pfx:
    call auryn_puts
    pop rcx
    push rcx
    lea rbx, [rel surface_table]
    mov rsi, [rbx + rcx*8]
    call auryn_puts
    mov edi, 10
    call auryn_putc
    mov dword [rel current_color], COLOR_WHITE
    pop rcx
    inc ecx
    cmp ecx, 12
    jl .row

.key:
    cmp byte [rel uefi_exited], 1
    je .key_native
.key_uefi:
    lea rbx, [rel uefi_data]
    mov rax, [rbx+32]
    mov rax, [rax+BS_WAITFOREVENT]
    mov ecx, 1
    mov rdx, [rbx+24]
    lea rdx, [rdx+CONIN_WAITKEY]
    lea r8, [rel event_index]
    call rax
    lea rbx, [rel uefi_data]
    mov rcx, [rbx+24]
    mov rax, [rcx+CONIN_READKEY]
    lea rdx, [rel key_data]
    call rax
    test rax, rax
    jnz .key
    jmp .key_dispatch
.key_native:
    call native_keyboard_read
    test rax, rax
    jnz .key_native

.key_dispatch:
    ; key_data[0..1] = ScanCode, key_data[2..3] = UnicodeChar
    ; UEFI ScanCodes: 0x01=Up  0x02=Down  0x17=Esc
    movzx eax, word [rel key_data]
    movzx edx, word [rel key_data+2]
    cmp ax, 0x01
    je .up
    cmp ax, 0x02
    je .down
    cmp ax, 0x17
    je .exit
    cmp dl, 13
    je .launch
    cmp dl, 27
    je .exit
    jmp .key

.up:
    mov eax, [rel bastian_sel]
    test eax, eax
    jz .redraw
    dec eax
    mov [rel bastian_sel], eax
    jmp .redraw
.down:
    mov eax, [rel bastian_sel]
    cmp eax, 11
    jge .redraw
    inc eax
    mov [rel bastian_sel], eax
    jmp .redraw

.launch:
    mov eax, [rel bastian_sel]
    cmp eax, 0
    je .l_bastian
    cmp eax, 1
    je .l_gmork
    cmp eax, 2
    je .l_morla
    cmp eax, 3
    je .l_atreyu
    cmp eax, 4
    je .l_rockbiter
    cmp eax, 5
    je .l_auryn
    cmp eax, 6
    je .l_empress
    cmp eax, 7
    je .l_koreander
    cmp eax, 8
    je .l_falkor
    cmp eax, 9
    je .l_sphinx
    cmp eax, 10
    je .l_artax
    cmp eax, 11
    je .l_engywook
    jmp .redraw

.l_bastian:
    jmp bastian_home
.l_gmork:
    jmp gmork_main
.l_atreyu:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    lea r12, [rel atreyu_cbs_prog]
    mov r14d, 100000
    call cbs_run
    jmp .redraw
.l_rockbiter:
    mov edi, COLOR_BLACK
    call auryn_fill
    call cursor_home
    lea r12, [rel rockbiter_cbs_prog]
    mov r14d, 100000
    call cbs_run
    jmp .redraw
.l_morla:
    lea rsi, [rel str_soon_morla]
    call show_coming_soon
    jmp .redraw
.l_auryn:
    lea rsi, [rel str_soon_auryn]
    call show_coming_soon
    jmp .redraw
.l_empress:
    lea rsi, [rel str_soon_empress]
    call show_coming_soon
    jmp .redraw
.l_koreander:
    lea rsi, [rel str_soon_koreander]
    call show_coming_soon
    jmp .redraw
.l_falkor:
    lea rsi, [rel str_soon_falkor]
    call show_coming_soon
    jmp .redraw
.l_sphinx:
    lea rsi, [rel str_soon_sphinx]
    call show_coming_soon
    jmp .redraw
.l_artax:
    lea rsi, [rel str_soon_artax]
    call show_coming_soon
    jmp .redraw
.l_engywook:
    lea rsi, [rel str_soon_engywook]
    call show_coming_soon
    jmp .redraw

.exit:
    jmp bastian_home

surface_table:
    dq str_s1, str_s2, str_s3, str_s4, str_s5, str_s6, str_s7, str_s8, str_s9, str_s10, str_s11, str_s12

str_bastian_head: db '         --- BASTIAN HOME ---',10,10,0
str_sel_pre:  db '> ',0
str_sel_none: db '  ',0
str_stub:     db '  Surface stubbed. Coming soon...',10,0
str_s1: db 'Bastian (Home)',0
str_s2: db 'Gmork (Terminal)',0
str_s3: db 'Morla (Files)',0
str_s4: db 'Atreyu (Editor)',0
str_s5: db 'Rockbiter (Stats)',0
str_s6: db 'Auryn (Settings)',0
str_s7: db 'Empress (Search)',0
str_s8: db 'Koreander (Docs)',0
str_s9: db 'Falkor (Messenger)',0
str_s10: db 'Sphinx (Security)',0
str_s11: db 'Artax (Recovery)',0
str_s12: db 'Engywook (Calculator)',0
