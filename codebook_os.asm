; CodebookOS Scheduler
; Updated to execute .cb surfaces

section .data
    scheduler_msg db "CodebookOS Scheduler v0.1", 0

section .text
    global _start

_start:
    ; Initialize the scheduler
    call init_scheduler
    
    ; Load and execute .cb surfaces
    call load_and_execute_surfaces
    
    ; Exit
    mov eax, 1
    xor ebx, ebx
    int 0x80

init_scheduler:
    ; Initialize capabilities and energy budget
    ret

load_and_execute_surfaces:
    ; Load .cb surfaces and execute them
    ; Example: load_surface("hello.cb")
    ret
