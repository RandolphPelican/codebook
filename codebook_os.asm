; =============================================================
; CodebookOS — Surface Token VM Stubs (Phase 1)
; Implementation of the ASM VM for the 23-byte Surface Token
; "Atreyu named it."
; =============================================================

section .data
    ; --- Surface Hello Token (Compiled from hello.cbs) ---
    surface_hello:
        dd 1                    ; capability_id = 1 (HelloWorld)
        dw 10                   ; x = 10
        dw 20                   ; y = 20
        dw 1000                 ; energy_budget = 1000
        dq hello_bytecode       ; data_ptr (points to bytecode)
        db 0                    ; revoke_flag = 0 (false)
        dd 0xCAFEBABE           ; checksum (placeholder)

    ; Compiled bytecode from hello.cbs (LOAD_CONST "Hello, Codebook!", STORE 'm', PRINT 'm', RETURN)
    hello_bytecode:
        db 0x71, "Hello, Codebook!", 0x00, 0x72, 0x6d, 0x73, 0x6d, 0x74

section .text
    global _start

_start:
    ; --- Test VM: spawn_surface ---
    lea rsi, [rel surface_hello]
    call spawn_surface
    
    ; --- Test VM: energy_query ---
    lea rsi, [rel surface_hello]
    call energy_query
    ; RAX now contains 1000

    ; --- Test VM: revoke_surface ---
    lea rsi, [rel surface_hello]
    call revoke_surface
    ; Surface is now revoked (flag=1)

    ; Exit (Linux 64-bit)
    mov eax, 60
    xor edi, edi
    syscall

; -------------------------------------------------------------
; spawn_surface
; Load a surface token into the spatial context.
; IN:  RSI = Pointer to surface token
; OUT: EAX = 0 (success)
; -------------------------------------------------------------
spawn_surface:
    ; For now, we simulate "spawning" by printing the data_ptr content
    push rsi
    mov rsi, [rsi + 10]         ; Offset 10 is data_ptr (dq)
    call print_string
    pop rsi
    xor eax, eax
    ret

; -------------------------------------------------------------
; revoke_surface
; Set revoke_flag=1 and zero out the token (stub).
; IN:  RSI = Pointer to surface token
; OUT: EAX = 0 (revoked)
; -------------------------------------------------------------
revoke_surface:
    mov byte [rsi + 18], 1      ; Set revoke_flag = 1
    ; In a full implementation, we would zero out the token here.
    xor eax, eax
    ret

; -------------------------------------------------------------
; energy_query
; Return the energy_budget field.
; IN:  RSI = Pointer to surface token
; OUT: EAX = Remaining energy budget
; -------------------------------------------------------------
energy_query:
    movzx eax, word [rsi + 8]   ; Offset 8 is energy_budget (2 bytes)
    ret

; --- Helper: print_string (Linux x64) ---
print_string:
    push rsi
    push rdx
    push rax
    push rdi
    
    mov rdi, rsi                ; Start of string
    xor rdx, rdx
.len:
    cmp byte [rdi + rdx], 0
    je .done
    inc rdx
    jmp .len
.done:
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; stdout
    syscall
    
    pop rdi
    pop rax
    pop rdx
    pop rsi
    ret
