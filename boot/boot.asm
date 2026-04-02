; =============================================================
; CodebookOS Phase 1 + CBS VM — x86_64 UEFI
; Pure NASM, zero dependencies
; "Atreyu named it."
; =============================================================

BITS 64

%define FILE_ALIGN   0x200
%define SECT_ALIGN   0x1000
%define IMAGE_BASE   0x100000
%define HEADER_SZ    0x200

%define TEXT_RVA     0x1000
%define TEXT_RAW     0x200
%define TEXT_RAWSZ   0x100000      ; 64KB for code+VM+programs
%define TEXT_VSZ     0x100000

%define RELOC_RVA    0x101000
%define RELOC_RAW    0x100200
%define RELOC_RAWSZ  0x200
%define RELOC_VSZ    0x200
%define IMAGE_SZ     0x102000

%define ST_CONIN     0x30
%define ST_CONOUT    0x40
%define ST_RUNTIME   0x58
%define ST_BOOTSERV  0x60
%define CONOUT_OUTPUTSTR 0x08
%define CONOUT_CLEARSCR  0x30
%define CONIN_READKEY    0x08
%define CONIN_WAITKEY    0x10
%define BS_GETMEMMAP     0x38
%define BS_WAITFOREVENT  0x60
%define BS_EXITBOOTSERV  0xE8
%define BS_STALL         0xF8
%define BS_SETWATCHDOG   0x100
%define BS_LOCATEPROTOCOL 0x140
%define RS_RESETSYSTEM   0x68
%define GOP_MODE         0x18
%define GOPMODE_FBBASE   0x18
%define GOPMODE_FBSIZE   0x20
%define GOPMODE_INFO     0x08
%define GOPINFO_HRES     0x04
%define GOPINFO_VRES     0x08
%define GOPINFO_PIXFMT   0x0C
%define GOPINFO_PPSL     0x20

%define COLOR_GOLD   0x00FFD700
%define COLOR_BLACK  0x00000000
%define COLOR_WHITE  0x00FFFFFF
%define COLOR_RED    0x00FF0000
%define COLOR_GREEN  0x0000FF00
%define COLOR_BLUE   0x000000FF
%define COLOR_CYAN   0x0000FFFF

; --- CBS VM Opcodes ---
%define OP_PUSH       0x01
%define OP_ADD        0x10
%define OP_SUB        0x11
%define OP_MUL        0x12
%define OP_DIV        0x13
%define OP_EQ         0x14
%define OP_NE         0x15
%define OP_LT         0x16
%define OP_GT         0x17
%define OP_LE         0x18
%define OP_GE         0x19
%define OP_RESERVE    0x20
%define OP_RET        0x53
%define OP_JIF        0x55
%define OP_JBACK      0x56
%define OP_LOAD       0x70
%define OP_STORE      0x71
%define OP_PRINT_NUM  0x80
%define OP_EMIT       0x81
%define OP_NEWLINE    0x82
%define OP_DUP        0x83
%define OP_DROP       0x84
%define OP_SWAP       0x85
%define OP_PRINT_STR  0x86
%define OP_JMP        0x40
%define OP_PUSH_STR   0x02
%define OP_MOD        0x1A
%define OP_CALL       0x50
%define OP_DUP2       0x87
%define OP_GRANT_CAP  0x90
%define OP_USE_CAP    0x91
%define OP_HALT       0xFF

; =============================================================
; PE32+ Headers
; =============================================================
dos_header:
    dw 0x5A4D
    times 29 dw 0
    dd pe_sig - dos_header
pe_sig:
    dd 0x00004550
    dw 0x8664, 2
    dd 0, 0, 0
    dw opt_hdr_end - opt_hdr
    dw 0x0022
opt_hdr:
    dw 0x020B
    db 1, 0
    dd TEXT_RAWSZ, 0, 0
    dd TEXT_RVA, TEXT_RVA
    dq IMAGE_BASE
    dd SECT_ALIGN, FILE_ALIGN
    dw 0,0,0,0,0,0
    dd 0, IMAGE_SZ, HEADER_SZ, 0
    dw 10, 0
    dq 0x10000, 0x10000, 0x10000, 0
    dd 0, 6
    dd 0,0, 0,0, 0,0, 0,0, 0,0
    dd RELOC_RVA, RELOC_RAWSZ
opt_hdr_end:
    db '.text',0,0,0
    dd TEXT_VSZ, TEXT_RVA, TEXT_RAWSZ, TEXT_RAW
    dd 0,0
    dw 0,0
    dd 0xE0000060
    db '.reloc',0,0
    dd RELOC_VSZ, RELOC_RVA, RELOC_RAWSZ, RELOC_RAW
    dd 0,0
    dw 0,0
    dd 0x42000040
    times TEXT_RAW - ($ - $$) db 0

; =============================================================
text_start:
; =============================================================

; =============================================================
; Entry Point
; =============================================================
efi_entry:
    push    rbx
    push    rbp
    push    rdi
    push    rsi
    push    r12
    push    r13
    push    r14
    push    r15
    sub     rsp, 104

    lea     rbx, [rel uefi_data]
    mov     [rbx],      rcx
    mov     [rbx + 8],  rdx
    mov     rax, [rdx + ST_CONOUT]
    mov     [rbx + 16], rax
    mov     rax, [rdx + ST_CONIN]
    mov     [rbx + 24], rax
    mov     rax, [rdx + ST_BOOTSERV]
    mov     [rbx + 32], rax
    mov     rax, [rdx + ST_RUNTIME]
    mov     [rbx + 40], rax

    ; Disable watchdog
    mov     rax, [rbx + 32]
    mov     rax, [rax + BS_SETWATCHDOG]
    xor     ecx, ecx
    xor     edx, edx
    xor     r8d, r8d
    xor     r9d, r9d
    call    rax

    lea     rbx, [rel uefi_data]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_CLEARSCR]
    call    rax

    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_locating]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax

    call    locate_sfsp
    call    locate_gop
    test    rax, rax
    jnz     .no_gop

    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_gop_ok]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax

    ; === BOOT SPLASH ===
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    call    stall_500
    lea     rsi, [rel str_spad]
    call    auryn_puts
    lea     rsi, [rel str_sname]
    call    auryn_puts
    call    stall_1500
    lea     rsi, [rel str_spres]
    call    auryn_puts
    call    stall_1000
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    lea     rsi, [rel str_spad]
    call    auryn_puts
    lea     rsi, [rel str_stitle]
    call    auryn_puts
    lea     rsi, [rel str_sphase]
    call    auryn_puts
    call    stall_2000
    mov     edi, COLOR_BLACK
    call    auryn_fill
    call    cursor_home
    jmp     bastian_home

.no_gop:
    lea     rbx, [rel uefi_data]
    lea     rdx, [rel ucs_no_gop]
    mov     rcx, [rbx + 16]
    mov     rax, [rcx + CONOUT_OUTPUTSTR]
    call    rax
.hang:  hlt
    jmp     .hang

; =============================================================
; Stall helpers
; =============================================================
stall_500:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,500000
    call rax
    pop rbx
    ret
stall_1000:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,1000000
    call rax
    pop rbx
    ret
stall_1500:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,1500000
    call rax
    pop rbx
    ret
stall_2000:
    push rbx
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_STALL]
    mov ecx,2000000
    call rax
    pop rbx
    ret

cursor_home:
    mov dword [rel cursor_x], 0
    mov dword [rel cursor_y], 0
    ret

; =============================================================
; locate_gop
; =============================================================

locate_sfsp:
    push rbx
    push rbp
    mov rbp,rsp
    sub rsp,32
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_LOCATEPROTOCOL]
    lea rcx,[rel sfsp_guid]
    xor edx,edx
    lea r8,[rel sfsp_ptr]
    call rax
    test rax,rax
    jnz .f
    
    ; Store SFSP in uefi_data
    lea rbx,[rel uefi_data]
    mov rax,[rel sfsp_ptr]
    mov [rbx+48],rax

    mov rbx,[rel sfsp_ptr]
    mov rax,[rbx+0x08] ; OpenVolume
    mov rcx,rbx
    lea rdx,[rel root_ptr]
    call rax
    test rax,rax
    jnz .f
    xor eax,eax
    jmp .d
.f: mov eax,1
.d: leave
    pop rbx
    ret

locate_gop:
    push rbx
    push rbp
    mov rbp,rsp
    sub rsp,48
    lea rbx,[rel uefi_data]
    mov rax,[rbx+32]
    mov rax,[rax+BS_LOCATEPROTOCOL]
    lea rcx,[rel gop_guid]
    xor edx,edx
    lea r8,[rel gop_ptr]
    call rax
    test rax,rax
    jnz .f
    mov rax,[rel gop_ptr]
    mov rax,[rax+GOP_MODE]
    mov [rel gop_mode_ptr],rax
    mov rcx,[rax+GOPMODE_FBBASE]
    mov [rel fb_base],rcx
    mov rcx,[rax+GOPMODE_FBSIZE]
    mov [rel fb_size],rcx
    mov rax,[rel gop_mode_ptr]
    mov rax,[rax+GOPMODE_INFO]
    mov ecx,[rax+GOPINFO_HRES]
    mov [rel fb_width],ecx
    mov ecx,[rax+GOPINFO_VRES]
    mov [rel fb_height],ecx
    mov ecx,[rax+GOPINFO_PPSL]
    mov [rel fb_ppsl],ecx
    mov ecx,[rax+GOPINFO_PIXFMT]
    mov [rel fb_pixfmt],ecx
    xor eax,eax
    jmp .d
.f: mov eax,1
.d: leave
    pop rbx
    ret

; =============================================================
; fixup_color: swap R and B bytes if pixfmt != 1 (BGRX)
; in:  eax = color (BGRX format)
; out: eax = color adjusted for current fb_pixfmt
; clobbers ecx only
; =============================================================
fixup_color:
    cmp dword [rel fb_pixfmt], 1
    je .fc_done
    mov ecx, eax
    and ecx, 0x00FF00FF
    rol ecx, 16
    and eax, 0xFF00FF00
    or  eax, ecx
.fc_done:
    ret

; =============================================================
; AURYN — Framebuffer
; =============================================================
auryn_fill:
    push rbx
    push rcx
    push rax
    mov rbx,[rel fb_base]
    test rbx,rbx
    jz .d
    mov eax, edi
    call fixup_color
    mov edi, eax
    mov ecx,[rel fb_ppsl]
    imul ecx,[rel fb_height]
.l: test ecx,ecx
    jz .d
    mov [rbx],edi
    add rbx,4
    dec ecx
    jmp .l
.d: pop rax
    pop rcx
    pop rbx
    ret

auryn_scroll:
    push rsi
    push rdi
    push rcx
    push rax
    push rdx
    mov rdi, [rel fb_base]
    mov rsi, rdi
    mov eax, [rel fb_ppsl]
    imul eax, 8 * 4
    add rsi, rax
    
    mov ecx, [rel fb_ppsl]
    mov edx, [rel fb_height]
    sub edx, 8
    imul ecx, edx
    
    cld
    rep movsd
    
    mov ecx, [rel fb_ppsl]
    imul ecx, 8
    mov eax, 0 ; COLOR_BLACK
    rep stosd
    
    pop rdx
    pop rax
    pop rcx
    pop rdi
    pop rsi
    ret

auryn_paint:
    push rax
    push rbx
    mov rbx,[rel fb_base]
    test rbx,rbx
    jz .d
    mov eax,[rel fb_ppsl]
    imul eax,esi
    add eax,edi
    shl eax,2
    mov [rbx+rax],edx
.d: pop rbx
    pop rax
    ret

auryn_putc:
    push rbp
    mov rbp,rsp
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    movzx eax,dil
    cmp al,10
    je .nl
    cmp al,13
    je .out
    cmp al,8
    je .bs
    sub al,32
    cmp al,95
    ja .out
    movzx ecx,al
    shl ecx,3
    lea r8,[rel font_data]
    add r8,rcx
    mov edi,[rel cursor_x]
    shl edi,3
    mov esi,[rel cursor_y]
    shl esi,3
    xor r9d,r9d
.row: cmp r9d,8
    jge .blit
    movzx r10d,byte [r8+r9]
    xor r11d,r11d
.col: cmp r11d,8
    jge .ce
    mov ecx,7
    sub ecx,r11d
    bt r10d,ecx
    jnc .sk
    push rdi
    push rsi
    push rdx
    lea edi,[edi+r11d]
    lea esi,[esi+r9d]
    mov edx,[rel current_color]
    mov eax, edx
    call fixup_color
    mov edx, eax
    call auryn_paint
    pop rdx
    pop rsi
    pop rdi
.sk: inc r11d
    jmp .col
.ce: inc r9d
    jmp .row
.blit:
    mov eax,[rel cursor_x]
    inc eax
    mov ecx,[rel fb_width]
    shr ecx,3
    cmp eax,ecx
    jl .sx
    xor eax,eax
    jmp .nl2
.sx: mov [rel cursor_x],eax
    jmp .out
.nl: mov dword [rel cursor_x],0
.nl2:
    mov eax,[rel cursor_y]
    inc eax
    mov ecx,[rel fb_height]
    shr ecx,3
    cmp eax,ecx
    jl .sy
    push rax
    push rcx
    push rdx
    call auryn_scroll
    pop rdx
    pop rcx
    pop rax
    mov eax, [rel fb_height]
    shr eax, 3
    dec eax
.sy: mov [rel cursor_y],eax
    mov dword [rel cursor_x],0
    jmp .out
.bs: mov eax,[rel cursor_x]
    test eax,eax
    jz .out
    dec eax
    mov [rel cursor_x],eax
    push rdi
    push rsi
    push rdx
    mov edi,eax
    shl edi,3
    mov esi,[rel cursor_y]
    shl esi,3
    xor r9d,r9d
.br: cmp r9d,8
    jge .bd
    xor r11d,r11d
.bc: cmp r11d,8
    jge .be
    push rdi
    push rsi
    lea edi,[edi+r11d]
    lea esi,[esi+r9d]
    mov edx,COLOR_BLACK
    mov eax, edx
    call fixup_color
    mov edx, eax
    call auryn_paint
    pop rsi
    pop rdi
    inc r11d
    jmp .bc
.be: inc r9d
    jmp .br
.bd: pop rdx
    pop rsi
    pop rdi
.out:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret



morla_write_file:
    ; rdi = filename (ascii), rsi = buffer, rdx = size
    push rbx
    push r12
    push r13
    push rdx ; save size
    push rsi ; save buffer
    
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

.err_pop:
    add rsp, 16 ; pop saved buffer and size
.err:
    lea rsi, [rel str_ls_err]
    call auryn_puts
.d: pop r13
    pop r12
    pop rbx
    ret

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

auryn_puts:
    push rsi
.al: movzx edi,byte [rsi]
    test dil,dil
    jz .ad
    call auryn_putc
    inc rsi
    jmp .al
.ad: pop rsi
    ret

; =============================================================
; String utilities
; =============================================================
str_eq:
    push rdi
    push rsi
.el: mov al,[rdi]
    mov cl,[rsi]
    cmp al,cl
    jne .en
    test al,al
    jz .ey
    inc rdi
    inc rsi
    jmp .el
.ey: mov eax,1
    jmp .ed
.en: xor eax,eax
.ed: pop rsi
    pop rdi
    ret

starts_with:
    push rdi
    push rsi
    push rcx
.wl: mov cl,[rsi]
    test cl,cl
    jz .wy
    mov al,[rdi]
    cmp al,cl
    jne .wn
    inc rdi
    inc rsi
    jmp .wl
.wy: mov rax,rdi
    pop rcx
    pop rsi
    pop rdi
    ret
.wn: xor eax,eax
    pop rcx
    pop rsi
    pop rdi
    ret

parse_hex:
    push rdx
    push rsi
    xor eax,eax
    cmp byte [rsi],'0'
    jne .hl
    cmp byte [rsi+1],'x'
    je .hs
    cmp byte [rsi+1],'X'
    je .hs
    jmp .hl
.hs: add rsi,2
.hl: movzx edx,byte [rsi]
    cmp dl,'0'
    jb .hd
    cmp dl,'9'
    jbe .hg
    cmp dl,'a'
    jb .hu
    cmp dl,'f'
    jbe .hx
    jmp .hu
.hg: sub dl,'0'
    jmp .ha
.hx: sub dl,'a'
    add dl,10
    jmp .ha
.hu: cmp dl,'A'
    jb .hd
    cmp dl,'F'
    ja .hd
    sub dl,'A'
    add dl,10
.ha: shl rax,4
    or al,dl
    inc rsi
    jmp .hl
.hd: pop rsi
    pop rdx
    ret

; =============================================================
; Number printing
; =============================================================
print_hex32:
    push rbx
    push rcx
    push rsi
    mov ebx,edi
    lea rsi,[rel hex_buf]
    mov byte [rsi],'0'
    mov byte [rsi+1],'x'
    mov ecx,28
    add rsi,2
.l: mov eax,ebx
    shr eax,cl
    and eax,0xF
    cmp al,10
    jb .d
    add al,'A'-10
    jmp .s
.d: add al,'0'
.s: mov [rsi],al
    inc rsi
    sub ecx,4
    jge .l
    mov byte [rsi],0
    lea rsi,[rel hex_buf]
    call auryn_puts
    pop rsi
    pop rcx
    pop rbx
    ret

print_hex64:
    push rbx
    push rcx
    push rsi
    mov rbx,rdi
    lea rsi,[rel hex_buf]
    mov byte [rsi],'0'
    mov byte [rsi+1],'x'
    mov ecx,60
    add rsi,2
.l: mov rax,rbx
    shr rax,cl
    and eax,0xF
    cmp al,10
    jb .d
    add al,'A'-10
    jmp .s
.d: add al,'0'
.s: mov [rsi],al
    inc rsi
    sub ecx,4
    jge .l
    mov byte [rsi],0
    lea rsi,[rel hex_buf]
    call auryn_puts
    pop rsi
    pop rcx
    pop rbx
    ret

print_dec:
    push rax
    push rcx
    push rdx
    push rsi
    mov eax,edi
    lea rsi,[rel dec_buf+11]
    mov byte [rsi],0
    test eax,eax
    jnz .l
    dec rsi
    mov byte [rsi],'0'
    jmp .p
.l: test eax,eax
    jz .p
    xor edx,edx
    mov ecx,10
    div ecx
    add dl,'0'
    dec rsi
    mov [rsi],dl
    jmp .l
.p: call auryn_puts
    pop rsi
    pop rdx
    pop rcx
    pop rax
    ret

; print signed 32-bit
print_sdec:
    test edi,edi
    jns print_dec
    push rdi
    mov edi,'-'
    call auryn_putc
    pop rdi
    neg edi
    jmp print_dec


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


; =============================================================
; Gmork Terminal
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
    cmp al,'4'
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

gmork_main:
    lea rsi,[rel str_banner]
    call auryn_puts

.prompt:
    lea rsi,[rel str_prompt]
    call auryn_puts
    lea r12,[rel input_buf]
    xor r13d,r13d

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
    movzx eax,word [rel key_data+2]
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


; =============================================================
; DATA
; =============================================================
uefi_data:  dq 0,0,0,0,0,0,0
gop_ptr:    dq 0
gop_mode_ptr: dq 0
fb_base:    dq 0
fb_size:    dq 0
fb_width:   dd 0
fb_height:  dd 0
fb_ppsl:    dd 0
fb_pixfmt:  dd 0
current_color: dd 0x00FFD700
bastian_sel:   dd 1
temp_size: dq 0
ascii_buf: times 256 db 0
atreyu_size:    dq 0
external_prog_buf: times 65536 db 0
cursor_x:   dd 0
cursor_y:   dd 0
input_buf:  times 128 db 0
key_data:   dd 0
event_index: dq 0
hex_buf:    times 20 db 0
dec_buf:    times 12 db 0
mmap_size:  dq 0
mmap_key:   dq 0
mmap_desc_sz: dd 0
mmap_desc_ver: dd 0


sfsp_guid:
    dd 0x964e5b22
    dw 0x6459, 0x11d2
    db 0x8e,0x39,0x00,0xa0,0xc9,0x69,0x72,0x3b
sfsp_ptr: dq 0
root_ptr: dq 0
file_ptr: dq 0
filename_ucs2: times 256 dw 0
file_info_buf: times 512 db 0

gop_guid:
    dd 0x9042a9de
    dw 0x23dc, 0x4a38
    db 0x96,0xfb,0x7a,0xde,0xd0,0x80,0x51,0x6a

color_table:
    dd COLOR_RED, 0x000080FF, 0x0000FFFF, COLOR_GREEN
    dd COLOR_CYAN, COLOR_BLUE, 0x00800080, COLOR_WHITE

mtypes:
    dq mt0,mt1,mt2,mt3,mt4,mt5,mt6,mt7,mt8,mt9,mt10,mt11,mt12,mt13,mt14
mt0:  db 'Reserved  ',0
mt1:  db 'LdrCode   ',0
mt2:  db 'LdrData   ',0
mt3:  db 'BSCode    ',0
mt4:  db 'BSData    ',0
mt5:  db 'RSCode    ',0
mt6:  db 'RSData    ',0
mt7:  db 'Convent   ',0
mt8:  db 'Unusable  ',0
mt9:  db 'ACPIRecl  ',0
mt10: db 'ACPINVS   ',0
mt11: db 'MMIO      ',0
mt12: db 'MMIOPort  ',0
mt13: db 'PalCode   ',0
mt14: db 'Persist   ',0

; Commands
c_help:     db 'help',0
c_about:    db 'about',0
c_clear:    db 'clear',0
c_colors:   db 'colors',0
c_fb:       db 'fb',0
c_mem:      db 'mem',0
c_reboot:   db 'reboot',0
c_progs:    db 'programs',0
c_ls:        db 'ls',0
c_load:      db 'load ',0
c_exit:     db 'exit',0
c_home:     db 'home',0
p_run:      db 'run ',0
p_echo:     db 'echo ',0
p_peek:     db 'peek ',0
p_dump:     db 'dump ',0
p_fill:     db 'fill ',0

; UCS-2
ucs_locating:
    dw 0x0D,0x0A
    db 'C',0,'o',0,'d',0,'e',0,'b',0,'o',0,'o',0,'k',0,'O',0,'S',0
    db ' ',0,'+',0,' ',0,'C',0,'B',0,'S',0,' ',0,'V',0,'M',0
    dw 0x0D,0x0A
    db 'L',0,'o',0,'c',0,'a',0,'t',0,'i',0,'n',0,'g',0,' ',0
    db 'G',0,'O',0,'P',0,'.',0,'.',0,'.',0
    dw 0x0D,0x0A,0x0000
ucs_gop_ok:
    db 'G',0,'O',0,'P',0,' ',0,'f',0,'o',0,'u',0,'n',0,'d',0,'.',0
    db ' ',0,'A',0,'u',0,'r',0,'y',0,'n',0,' ',0,'a',0,'w',0,'a',0,'k',0,'e',0,'.',0
    dw 0x0D,0x0A,0x0000
ucs_no_gop:
    db 'E',0,'R',0,'R',0,':',0,' ',0,'N',0,'o',0,' ',0,'G',0,'O',0,'P',0
    dw 0x0D,0x0A,0x0000

str_ls_err: db '  FS not available.',10,0
str_bh_pad:   db 10,10,10,10,10,0
str_bh_title: db '     C O D E B O O K  O S',10,10,0
str_bh_sub:   db '  Metabolic Computing -- StableTech Enterprises LLC',10,10,0
str_bh_menu:
    db '  1. Gmork Terminal',10
    db '  2. Atreyu Editor',10
    db '  3. Rockbiter System Stats',10
    db '  4. Run CBS Program',10,10,0
str_bh_prompt:     db 'Select [1-4]: ',0
str_bh_run_prompt: db 'Program [0-4]: ',0

str_nl:     db 10,0
str_sp:     db ' ',0
str_col:    db ': ',0
str_spad:   db 10,10,10,10,10,10,10,10,10,10,10,10,0
str_sname:  db '        RANDOLPH PELICAN III',10,0
str_spres:  db '              presents',10,0
str_stitle: db '         C O D E B O O K   O S',10,0
str_sphase: db '       Phase 1 + CBS VM',10,0
str_prompt: db 'gmork> ',0
str_unk:    db 'Unknown: ',0

str_banner:
    db '  CodebookOS Phase 1 -- Gmork Terminal',10
    db '  Randolph Pelican III',10
    db '  StableTech Enterprises LLC',10,10
    db '  UEFI x86_64 + CBS Bytecode VM',10
    db '  Type help.',10,10,0

str_help:
    db 'Gmork Terminal -- CodebookOS',10
    db '  help           commands',10
    db '  about          system info',10
    db '  clear          clear screen',10
    db '  ls             list root files',10
    db '  load <file>    load and run CBS',10
    db '  fb             framebuffer info',10
    db '  mem            memory map',10
    db '  colors         color bars',10
    db '  echo <text>    echo',10
    db '  peek <addr>    read memory',10
    db '  dump <addr>    hex dump',10
    db '  fill <hex>     fill screen',10
    db '  reboot         reset',10,
    db '  home           home screen',10
    db '  programs       list CBS demos',10
    db '  run <0-4>      execute CBS program',10
    db '                 0=full demo',10,10,0

str_about:
    db '  CodebookOS -- Bare Metal x86_64',10
    db '  UEFI Direct, Zero Dependencies',10
    db '  Pure NASM + CBS Bytecode VM',10
    db '  Author: Randolph Pelican III',10
    db '  StableTech Enterprises LLC',10,10,0

str_fb1:    db '  Framebuffer:',10,0
str_fb_b:   db '  Base: ',0
str_fb_r:   db '  Res:  ',0
str_bars_ok: db 'Color bars painted.',10,0
str_pk1:    db '  [',0
str_pk2:    db '] = ',0
str_fill_ok: db '  Filled.',10,0
str_reboot: db '  Rebooting...',10,0

str_mhdr:   db '  Type       PhysStart          Pages',10,0
str_mt_unk: db 'Type?',0
str_pg:     db ' pg',10,0
str_mtot:   db '  Total: ',0
str_ment:   db ' entries',10,0
str_mfail:  db '  GetMemoryMap failed.',10,0

; CBS VM strings
str_vm_start: db '  --- CBS VM executing ---',10,0
str_vm_halt:  db '  HALT',10,0
str_vm_ret:   db '  Return: ',0
str_vm_void:  db '(void)',10,0
str_vm_eu:    db '  Energy: ',0
str_vm_jr:    db 'j used, ',0
str_vm_jl:    db 'j remaining',10,0
str_vm_rsv:   db '  Reserve ',0
str_vm_jok:   db 'j: OK',10,0
str_vm_deg:   db '  DEGRADED: insufficient energy',10,0
str_vm_unk:   db '  Unknown opcode: ',0
str_run_bad:  db '  Usage: run <0-4>',10,0

str_prog_list:
    db '  CBS Demo Programs:',10
    db '  1  Hello     print greeting',10
    db '  2  Math      42 + 8 with energy',10
    db '  3  Loop      count 1 to 10',10
    db '  4  Fibonacci fib(10) = 55',10,10,0


; =============================================================
; CBS DEMO PROGRAMS (raw bytecode)
; =============================================================

; Program table (0-indexed internally, user sees 1-4)
prog_table:
    dq cbs_demo              ; 0 = full CBS demo
    dq prog1                ; run 1
    dq prog2                ; run 2
    dq prog3                ; run 3
    dq prog4                ; run 4

; --- Program 1: Hello ---
; Prints "Hello CodebookOS!" char by char
prog1:
    db OP_RESERVE
    dd 100                  ; 100j
    ; H=72 e=101 l=108 l=108 o=111 ' '=32
    ; C=67 o=111 d=100 e=101 b=98 o=111 o=111 k=107
    ; O=79 S=83 !=33
    db OP_PUSH
    dd 72
    db OP_EMIT              ; H
    db OP_PUSH
    dd 101
    db OP_EMIT              ; e
    db OP_PUSH
    dd 108
    db OP_EMIT              ; l
    db OP_PUSH
    dd 108
    db OP_EMIT              ; l
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 32
    db OP_EMIT              ; ' '
    db OP_PUSH
    dd 67
    db OP_EMIT              ; C
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 100
    db OP_EMIT              ; d
    db OP_PUSH
    dd 101
    db OP_EMIT              ; e
    db OP_PUSH
    dd 98
    db OP_EMIT              ; b
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 111
    db OP_EMIT              ; o
    db OP_PUSH
    dd 107
    db OP_EMIT              ; k
    db OP_PUSH
    dd 79
    db OP_EMIT              ; O
    db OP_PUSH
    dd 83
    db OP_EMIT              ; S
    db OP_PUSH
    dd 33
    db OP_EMIT              ; !
    db OP_NEWLINE
    db OP_HALT

; --- Program 2: Math with energy ---
; reserve 300j, push 42, push 8, add, print result
prog2:
    db OP_RESERVE
    dd 300
    db OP_PUSH
    dd 42
    db OP_PUSH
    dd 8
    db OP_ADD
    db OP_PRINT_NUM         ; prints 50
    db OP_NEWLINE
    ; Now multiply: 50 is consumed, redo
    db OP_PUSH
    dd 6
    db OP_PUSH
    dd 7
    db OP_MUL
    db OP_PRINT_NUM         ; prints 42
    db OP_NEWLINE
    ; Subtraction
    db OP_PUSH
    dd 100
    db OP_PUSH
    dd 58
    db OP_SUB
    db OP_PRINT_NUM         ; prints 42
    db OP_NEWLINE
    db OP_PUSH
    dd 42
    db OP_RET               ; return 42

; --- Program 3: Loop 1 to 10 ---
; var0 = 1, while var0 <= 10: print var0, var0 += 1
prog3:
    db OP_RESERVE
    dd 500
    ; var0 = 1
    db OP_PUSH
    dd 1
    db OP_STORE
    dd 0
    ; loop start (offset from here)
.loop3:
    ; load var0, push 10, compare LE
    db OP_LOAD
    dd 0
    db OP_PUSH
    dd 10
    db OP_LE
    ; if false, jump past loop body
    db OP_JIF
    dd (.loop3_end - .loop3_body)
.loop3_body:
    ; print var0
    db OP_LOAD
    dd 0
    db OP_PRINT_NUM
    db OP_PUSH
    dd 32              ; space
    db OP_EMIT
    ; var0 = var0 + 1
    db OP_LOAD
    dd 0
    db OP_PUSH
    dd 1
    db OP_ADD
    db OP_STORE
    dd 0
    ; jump back to loop start
    db OP_JBACK
    dd ($ + 4 - .loop3)
.loop3_end:
    db OP_NEWLINE
    db OP_HALT

; --- Program 4: Fibonacci fib(10) ---
; var0 = a = 0, var1 = b = 1, var2 = counter = 10
; loop: tmp=a+b, a=b, b=tmp, counter--, if counter>0 loop
; print b
prog4:
    db OP_RESERVE
    dd 800
    ; a = 0
    db OP_PUSH
    dd 0
    db OP_STORE
    dd 0
    ; b = 1
    db OP_PUSH
    dd 1
    db OP_STORE
    dd 1
    ; counter = 10
    db OP_PUSH
    dd 10
    db OP_STORE
    dd 2
.fib_loop:
    ; print current b
    db OP_LOAD
    dd 1
    db OP_PRINT_NUM
    db OP_PUSH
    dd 32
    db OP_EMIT
    ; tmp = a + b -> var3
    db OP_LOAD
    dd 0
    db OP_LOAD
    dd 1
    db OP_ADD
    db OP_STORE
    dd 3        ; var3 = tmp
    ; a = b
    db OP_LOAD
    dd 1
    db OP_STORE
    dd 0
    ; b = tmp
    db OP_LOAD
    dd 3
    db OP_STORE
    dd 1
    ; counter--
    db OP_LOAD
    dd 2
    db OP_PUSH
    dd 1
    db OP_SUB
    db OP_STORE
    dd 2
    ; if counter > 0, loop
    db OP_LOAD
    dd 2
    db OP_PUSH
    dd 0
    db OP_GT
    db OP_JIF
    dd (.fib_end - .fib_cont)
.fib_cont:
    db OP_JBACK
    dd ($ + 4 - .fib_loop)
.fib_end:
    db OP_NEWLINE
    ; final result = b
    db OP_LOAD
    dd 1
    db OP_RET

; =============================================================
; CBS Demo — compiled bytecode (from atreyu_x86.py)
; =============================================================
cbs_demo:
    incbin "boot/demo.cbc"
cbs_demo_end:

atreyu_cbs_prog:
    incbin "boot/atreyu.cbc"
atreyu_cbs_prog_end:

rockbiter_cbs_prog:
    incbin "boot/rockbiter.cbc"
rockbiter_cbs_prog_end:



; =============================================================
; Font (ASCII 32-126)
; =============================================================
font_data:
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    db 0x18,0x18,0x18,0x18,0x18,0x00,0x18,0x00
    db 0x6C,0x6C,0x6C,0x00,0x00,0x00,0x00,0x00
    db 0x6C,0x6C,0xFE,0x6C,0xFE,0x6C,0x6C,0x00
    db 0x18,0x7E,0xC0,0x7C,0x06,0xFC,0x18,0x00
    db 0x00,0xC6,0xCC,0x18,0x30,0x66,0xC6,0x00
    db 0x38,0x6C,0x38,0x76,0xDC,0xCC,0x76,0x00
    db 0x18,0x18,0x30,0x00,0x00,0x00,0x00,0x00
    db 0x0C,0x18,0x30,0x30,0x30,0x18,0x0C,0x00
    db 0x30,0x18,0x0C,0x0C,0x0C,0x18,0x30,0x00
    db 0x00,0x66,0x3C,0xFF,0x3C,0x66,0x00,0x00
    db 0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x30
    db 0x00,0x00,0x00,0x7E,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x18,0x18,0x00
    db 0x06,0x0C,0x18,0x30,0x60,0xC0,0x80,0x00
    db 0x7C,0xC6,0xCE,0xDE,0xF6,0xE6,0x7C,0x00
    db 0x18,0x38,0x78,0x18,0x18,0x18,0x7E,0x00
    db 0x7C,0xC6,0x06,0x1C,0x30,0x60,0xFE,0x00
    db 0x7C,0xC6,0x06,0x3C,0x06,0xC6,0x7C,0x00
    db 0x1C,0x3C,0x6C,0xCC,0xFE,0x0C,0x1E,0x00
    db 0xFE,0xC0,0xFC,0x06,0x06,0xC6,0x7C,0x00
    db 0x38,0x60,0xC0,0xFC,0xC6,0xC6,0x7C,0x00
    db 0xFE,0xC6,0x0C,0x18,0x30,0x30,0x30,0x00
    db 0x7C,0xC6,0xC6,0x7C,0xC6,0xC6,0x7C,0x00
    db 0x7C,0xC6,0xC6,0x7E,0x06,0x0C,0x78,0x00
    db 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x00
    db 0x00,0x18,0x18,0x00,0x00,0x18,0x18,0x30
    db 0x0C,0x18,0x30,0x60,0x30,0x18,0x0C,0x00
    db 0x00,0x00,0x7E,0x00,0x7E,0x00,0x00,0x00
    db 0x30,0x18,0x0C,0x06,0x0C,0x18,0x30,0x00
    db 0x7C,0xC6,0x0C,0x18,0x18,0x00,0x18,0x00
    db 0x7C,0xC6,0xDE,0xDE,0xDE,0xC0,0x78,0x00
    db 0x38,0x6C,0xC6,0xC6,0xFE,0xC6,0xC6,0x00
    db 0xFC,0x66,0x66,0x7C,0x66,0x66,0xFC,0x00
    db 0x3C,0x66,0xC0,0xC0,0xC0,0x66,0x3C,0x00
    db 0xF8,0x6C,0x66,0x66,0x66,0x6C,0xF8,0x00
    db 0xFE,0x62,0x68,0x78,0x68,0x62,0xFE,0x00
    db 0xFE,0x62,0x68,0x78,0x68,0x60,0xF0,0x00
    db 0x3C,0x66,0xC0,0xC0,0xCE,0x66,0x3E,0x00
    db 0xC6,0xC6,0xC6,0xFE,0xC6,0xC6,0xC6,0x00
    db 0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0x1E,0x0C,0x0C,0x0C,0xCC,0xCC,0x78,0x00
    db 0xE6,0x66,0x6C,0x78,0x6C,0x66,0xE6,0x00
    db 0xF0,0x60,0x60,0x60,0x62,0x66,0xFE,0x00
    db 0xC6,0xEE,0xFE,0xFE,0xD6,0xC6,0xC6,0x00
    db 0xC6,0xE6,0xF6,0xDE,0xCE,0xC6,0xC6,0x00
    db 0x7C,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00
    db 0xFC,0x66,0x66,0x7C,0x60,0x60,0xF0,0x00
    db 0x7C,0xC6,0xC6,0xC6,0xD6,0xDE,0x7C,0x06
    db 0xFC,0x66,0x66,0x7C,0x6C,0x66,0xE6,0x00
    db 0x7C,0xC6,0xE0,0x7C,0x0E,0xC6,0x7C,0x00
    db 0x7E,0x5A,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0xC6,0xC6,0xC6,0xC6,0xC6,0xC6,0x7C,0x00
    db 0xC6,0xC6,0xC6,0xC6,0x6C,0x38,0x10,0x00
    db 0xC6,0xC6,0xC6,0xD6,0xFE,0xEE,0xC6,0x00
    db 0xC6,0xC6,0x6C,0x38,0x6C,0xC6,0xC6,0x00
    db 0x66,0x66,0x66,0x3C,0x18,0x18,0x3C,0x00
    db 0xFE,0xC6,0x8C,0x18,0x32,0x66,0xFE,0x00
    db 0x3C,0x30,0x30,0x30,0x30,0x30,0x3C,0x00
    db 0xC0,0x60,0x30,0x18,0x0C,0x06,0x02,0x00
    db 0x3C,0x0C,0x0C,0x0C,0x0C,0x0C,0x3C,0x00
    db 0x10,0x38,0x6C,0xC6,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFF
    db 0x30,0x18,0x0C,0x00,0x00,0x00,0x00,0x00
    db 0x00,0x00,0x78,0x0C,0x7C,0xCC,0x76,0x00
    db 0xE0,0x60,0x60,0x7C,0x66,0x66,0xDC,0x00
    db 0x00,0x00,0x7C,0xC6,0xC0,0xC6,0x7C,0x00
    db 0x1C,0x0C,0x0C,0x7C,0xCC,0xCC,0x76,0x00
    db 0x00,0x00,0x7C,0xC6,0xFE,0xC0,0x7C,0x00
    db 0x38,0x6C,0x60,0xF0,0x60,0x60,0xF0,0x00
    db 0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0xF8
    db 0xE0,0x60,0x6C,0x76,0x66,0x66,0xE6,0x00
    db 0x18,0x00,0x38,0x18,0x18,0x18,0x3C,0x00
    db 0x06,0x00,0x06,0x06,0x06,0x66,0x66,0x3C
    db 0xE0,0x60,0x66,0x6C,0x78,0x6C,0xE6,0x00
    db 0x38,0x18,0x18,0x18,0x18,0x18,0x3C,0x00
    db 0x00,0x00,0xCC,0xFE,0xFE,0xD6,0xC6,0x00
    db 0x00,0x00,0xDC,0x66,0x66,0x66,0x66,0x00
    db 0x00,0x00,0x7C,0xC6,0xC6,0xC6,0x7C,0x00
    db 0x00,0x00,0xDC,0x66,0x66,0x7C,0x60,0xF0
    db 0x00,0x00,0x76,0xCC,0xCC,0x7C,0x0C,0x1E
    db 0x00,0x00,0xDC,0x76,0x66,0x60,0xF0,0x00
    db 0x00,0x00,0x7C,0xC0,0x7C,0x06,0xFC,0x00
    db 0x10,0x30,0x7C,0x30,0x30,0x34,0x18,0x00
    db 0x00,0x00,0xCC,0xCC,0xCC,0xCC,0x76,0x00
    db 0x00,0x00,0xC6,0xC6,0xC6,0x6C,0x38,0x00
    db 0x00,0x00,0xC6,0xD6,0xFE,0xFE,0x6C,0x00
    db 0x00,0x00,0xC6,0x6C,0x38,0x6C,0xC6,0x00
    db 0x00,0x00,0xC6,0xC6,0xCE,0x76,0x06,0xFE
    db 0x00,0x00,0xFE,0x0C,0x38,0x60,0xFE,0x00
    db 0x0E,0x18,0x18,0x70,0x18,0x18,0x0E,0x00
    db 0x18,0x18,0x18,0x00,0x18,0x18,0x18,0x00
    db 0x70,0x18,0x18,0x0E,0x18,0x18,0x70,0x00
    db 0x76,0xDC,0x00,0x00,0x00,0x00,0x00,0x00


; =============================================================
; VM runtime data
; =============================================================
    align 16
energy_budget: dq 100000
energy_used:   dq 0
vm_ret_ptr:     dq 0
vm_ret_stack:   times 256 dq 0
vm_stack:   times 512 dq 0     ; 4KB VM stack
vm_vars:    times 64 dd 0      ; 256 bytes variables

; Memory map buffer (8KB)
    align 16
mmap_buf:   times 8192 db 0

; =============================================================
    times TEXT_RAWSZ - ($ - text_start) db 0
reloc_start:
    dd 0, 10
    dw 0
    times RELOC_RAWSZ - ($ - reloc_start) db 0
;..
