; =============================================================
; Auryn — Framebuffer Renderer
; The amulet of Fantastica. Turns memory into visible reality.
; Functions: auryn_fill, auryn_scroll, auryn_paint, auryn_putc, auryn_puts
; Depends: fb_base, fb_width, fb_height, fb_ppsl, cursor_x, cursor_y,
;          current_color, font_data (in data.asm)
; Extracted from boot.asm (Pod 0.2)
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
