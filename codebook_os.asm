section .text
    global _start

_start:
    ; Exit
    mov eax, 60
    xor edi, edi
    syscall