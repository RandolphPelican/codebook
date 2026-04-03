; = =============================================================
; CodebookOS — Surface Token VM (Phase 2)
; Merging, Hashing, and Collision Detection
; "Atreyu named it."
; =============================================================

section .data
    ; --- Surface Hello Token ---
    surface_hello:
        dd 1                    ; capability_id = 1
        dw 10                   ; x = 10
        dw 20                   ; y = 20
        dw 1000                 ; energy_budget = 1000
        dq hello_bytecode       ; data_ptr
        db 0                    ; revoke_flag = 0
        dd 0xCAFEBABE           ; checksum

    ; --- Surface Hello Token 2 (to be merged) ---
    surface_hello_alt:
        dd 1                    ; capability_id = 1 (Match)
        dw 10                   ; x = 10 (Collision)
        dw 20                   ; y = 20 (Collision)
        dw 500                  ; energy_budget = 500
        dq hello_bytecode       ; data_ptr
        db 0                    ; revoke_flag = 0
        dd 0xFEEDFACE           ; checksum

    ; --- Surface Button Token ---
    surface_button:
        dd 2                    ; capability_id = 2
        dw 50                   ; x = 50
        dw 100                  ; y = 100
        dw 500                  ; energy_budget = 500
        dq button_bytecode      ; data_ptr
        db 0                    ; revoke_flag = 0
        dd 0xDEADBEEF           ; checksum

    hello_bytecode:  db "Hello, Codebook!", 0
    button_bytecode: db "Click Me", 0

    str_merged: db "Surfaces merged. New energy: ", 0
    str_nl:     db 10, 0

section .text
    global _start

_start:
    ; --- Test Case: Merge surface_hello and surface_hello_alt ---
    lea rsi, [rel surface_hello]
    lea rdi, [rel surface_hello_alt]
    call merge_surfaces
    
    test eax, eax
    jnz .fail

    ; Output new energy (should be 1500)
    lea rsi, [rel str_merged]
    call print_string
    lea rsi, [rel surface_hello]
    call energy_query
    mov edi, eax
    call print_num
    lea rsi, [rel str_nl]
    call print_string

.fail:
    ; Exit (Linux 64-bit)
    mov eax, 60
    xor edi, edi
    syscall

; -------------------------------------------------------------
; merge_surfaces
; Combine two surface tokens if capability_id and (x,y) match.
; IN:  RSI, RDI = pointers to two surface tokens
; OUT: EAX = 0 (merged) or error code (1)
; -------------------------------------------------------------
merge_surfaces:
    push rbx
    push rcx
    
    ; 1. Check Spatial Collision
    call check_collision
    test eax, eax
    jz .no_match
    
    ; 2. Check Capability ID (Offset 0)
    mov eax, [rsi]
    cmp eax, [rdi]
    jne .no_match
    
    ; 3. Merge Logic: Combine energy_budget (Offset 8)
    movzx ax, word [rdi + 8]
    movzx bx, word [rsi + 8]
    add ax, bx
    mov [rsi + 8], ax
    
    ; 4. Update Checksum
    call hash_token
    mov [rsi + 19], eax
    
    ; 5. Revoke second token
    mov byte [rdi + 18], 1
    
    xor eax, eax
    jmp .done

.no_match:
    mov eax, 1
.done:
    pop rcx
    pop rbx
    ret

; -------------------------------------------------------------
; hash_token
; Compute SHA-256 checksum (Placeholder: returns current + xor)
; IN:  RSI = pointer to surface token
; OUT: EAX = checksum (4 bytes)
; -------------------------------------------------------------
hash_token:
    mov eax, [rsi + 19]
    xor eax, 0x55555555         ; Simulate a hash update
    ret

; -------------------------------------------------------------
; check_collision
; Detect if two surfaces occupy the same (x,y)
; IN:  RSI, RDI = pointers to two surface tokens
; OUT: EAX = 1 (collision) or 0 (no collision)
; -------------------------------------------------------------
check_collision:
    mov ax, [rsi + 4]           ; x1
    cmp ax, [rdi + 4]           ; x2
    jne .no_collision
    mov ax, [rsi + 6]           ; y1
    cmp ax, [rdi + 6]           ; y2
    jne .no_collision
    mov eax, 1
    ret
.no_collision:
    xor eax, eax
    ret

; --- Helper: energy_query (from previous task) ---
energy_query:
    movzx eax, word [rsi + 8]
    ret

; --- Helper: print_string ---
print_string:
    push rsi
    push rdx
    push rax
    push rdi
    mov rdi, rsi
    xor rdx, rdx
.len:
    cmp byte [rdi + rdx], 0
    je .done
    inc rdx
    jmp .len
.done:
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    pop rax
    pop rdx
    pop rsi
    ret

; --- Helper: print_num (Simple decimal printer) ---
print_num:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    mov rax, rdi
    mov rbx, 10
    mov rcx, 0
.div:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .div
.print:
    pop rdx
    add dl, '0'
    mov [rsp-1], dl
    mov rax, 1
    mov rdi, 1
    lea rsi, [rsp-1]
    mov rdx, 1
    syscall
    loop .print
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
