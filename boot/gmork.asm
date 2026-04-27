; =============================================================
; Gmork — String Utilities
; The wolf of the Nothing. Knows what words are, knows when they are not.
; Functions: str_eq, starts_with, parse_hex, print_hex32, print_hex64,
;            print_dec, print_sdec
; Depends:   auryn_putc (for hex/dec output), data.asm labels
; Layer:     Layer 0 — boot/ orchestrator
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
