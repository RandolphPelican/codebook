; =============================================================
; CodebookOS — Surface Token System (Phase 1)
; Implementation of the 23-byte Revised Surface Spec
; "Atreyu named it."
; =============================================================

section .data
    ; --- Surface Hello Token ---
    surface_hello:
        dd 1                    ; capability_id = 1 (HelloWorld)
        dw 10                   ; x = 10
        dw 20                   ; y = 20
        dw 1000                 ; energy_budget = 1000
        dq hello_data           ; data_ptr
        db 0                    ; revoke_flag = 0 (false)
        dd 0xCAFEBABE           ; checksum (placeholder)

    ; --- Surface Button Token ---
    surface_button:
        dd 2                    ; capability_id = 2 (Button)
        dw 50                   ; x = 50
        dw 100                  ; y = 100
        dw 500                  ; energy_budget = 500
        dq button_data          ; data_ptr
        db 0                    ; revoke_flag = 0 (false)
        dd 0xDEADBEEF           ; checksum (placeholder)

    hello_data:  db "Hello, Codebook!", 0
    button_data: db "Click Me", 0

section .text
    global _start

_start:
    ; Placeholder: In a real CodebookOS environment, this would
    ; initialize the spatial context engine and begin surface orchestration.
    
    ; Exit for now (Linux 64-bit)
    mov eax, 60
    xor edi, edi
    syscall

; -------------------------------------------------------------
; spawn_surface
; Load token into spatial context (stub)
; IN:  RDI = Pointer to surface token
; OUT: RAX = Status (0 = success)
; -------------------------------------------------------------
spawn_surface:
    ; TODO: Implement spatial context registration
    xor rax, rax
    ret

; -------------------------------------------------------------
; revoke_surface
; Set revoke_flag = 1
; IN:  RDI = Pointer to surface token
; OUT: None
; -------------------------------------------------------------
revoke_surface:
    mov byte [rdi + 18], 1      ; Offset 18 is revoke_flag
    ret

; -------------------------------------------------------------
; energy_query
; Return energy_budget from token
; IN:  RDI = Pointer to surface token
; OUT: RAX = Current energy budget
; -------------------------------------------------------------
energy_query:
    movzx rax, word [rdi + 8]   ; Offset 8 is energy_budget (2 bytes)
    ret
