; =============================================================
; PS/2 Keyboard Driver
; The hand at the gate. Translates scancodes into intent.
; Functions: native_keyboard_read, kbd_sc1_to_ascii
; Depends:   (none — pure hardware I/O via in/out)
; Layer:     Layer 0 — drivers/ (hardware abstraction)
; History:   Phase 2.1 work (per ARCHAEOLOGY_REPO_RECORD.md)
;
; Scancode Set 1, US QWERTY. Polls 8042 controller ports 0x60/0x64.
; No UEFI dependency. Requires ring 0 I/O access (UEFI loader runs ring 0).
; =============================================================

; native_keyboard_read
;   Polls port 0x64 status register, reads port 0x60 if data is ready,
;   discards key-release (break) events (bit 7 set), translates make
;   scancodes via kbd_sc1_to_ascii, and stores the result in key_data+2.
;
;   Returns: rax = 0  key is ready; key_data+2 holds the ASCII char
;            rax = 1  no key ready, buffer empty, release event, or
;                     unmapped scancode (modifier, Fn key, etc.)
;   Clobbers: rax, rcx
native_keyboard_read:
    in      al, 0x64                    ; read 8042 status register
    test    al, 1                       ; bit 0 = output buffer full
    jz      .no_key                     ; clear → nothing waiting
    in      al, 0x60                    ; read scancode from data port
    test    al, 0x80                    ; bit 7 = break (key-release) event
    jnz     .no_key                     ; set → discard, return 1
    movzx   eax, al                     ; zero-extend make scancode → index
    lea     rcx, [rel kbd_sc1_to_ascii]
    movzx   eax, byte [rcx + rax]       ; translate scancode → ASCII
    test    al, al
    jz      .no_key                     ; 0 → unmapped key, return 1
    mov     word [rel key_data+2], ax   ; store UnicodeChar slot
    xor     eax, eax                    ; return 0 = key ready
    ret
.no_key:
    mov     eax, 1                      ; return 1 = no key / discard
    ret

; =============================================================
; kbd_sc1_to_ascii — 128-byte US QWERTY Scancode Set 1 → ASCII
; Index = raw 7-bit make scancode (0x00-0x7F).
; 0x00 = unmapped (modifier, Fn key, numpad direction, etc.).
; Control chars: 0x08 Backspace, 0x09 Tab, 0x0D Enter, 0x1B Escape.
; =============================================================
kbd_sc1_to_ascii:
    ; 0x00-0x07: (undef), ESC, 1-6
    db 0,    0x1B, '1',  '2',  '3',  '4',  '5',  '6'
    ; 0x08-0x0F: 7-0, -, =, Backspace, Tab
    db '7',  '8',  '9',  '0',  '-',  '=',  0x08, 0x09
    ; 0x10-0x17: q w e r t y u i
    db 'q',  'w',  'e',  'r',  't',  'y',  'u',  'i'
    ; 0x18-0x1F: o p [ ] Enter LCtrl a s
    db 'o',  'p',  '[',  ']',  0x0D, 0,    'a',  's'
    ; 0x20-0x27: d f g h j k l ;
    db 'd',  'f',  'g',  'h',  'j',  'k',  'l',  ';'
    ; 0x28-0x2F: ' ` LShift \ z x c v
    db 0x27, 0x60, 0,    0x5C, 'z',  'x',  'c',  'v'
    ; 0x30-0x37: b n m , . / RShift Numpad-*
    db 'b',  'n',  'm',  ',',  '.',  '/',  0,    '*'
    ; 0x38-0x3F: LAlt Space CapsLk F1 F2 F3 F4 F5
    db 0,    ' ',  0,    0,    0,    0,    0,    0
    ; 0x40-0x47: F6 F7 F8 F9 F10 NumLk ScrlLk Num7/Home
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x48-0x4F: Num8/Up Num9/PgUp Num- Num4/Left Num5 Num6/Right Num+ Num1/End
    db 0,    0,    '-',  0,    0,    0,    '+',  0
    ; 0x50-0x57: Num2/Down Num3/PgDn Num0/Ins Num./Del (undef) (undef) (intl) F11
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x58-0x5F: F12, unused
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x60-0x67: unused
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x68-0x6F: unused
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x70-0x77: unused
    db 0,    0,    0,    0,    0,    0,    0,    0
    ; 0x78-0x7F: unused
    db 0,    0,    0,    0,    0,    0,    0,    0
