
; CodebookOS Scheduler (Updated)
; Loads and executes .cb surfaces

section .data
    scheduler_msg db "CodebookOS Scheduler v0.1", 0
    surface_msg db "Executing surface: ", 0

section .text
    global _start

_start:
    ; Print scheduler message
    mov eax, 4
    mov ebx, 1
    mov ecx, scheduler_msg
    mov edx, 24
    int 0x80

    ; Load and execute .cb surfaces
    call load_and_execute_surfaces

    ; Exit
    mov eax, 1
    xor ebx, eb