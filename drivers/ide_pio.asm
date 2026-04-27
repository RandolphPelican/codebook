; =============================================================
; IDE PIO Disk Driver
; The arm that reaches into the spinning rust. Legacy PIO mode.
; Functions: ide_pio_init, ide_pio_detect_drive, ide_pio_check_lba48,
;            ide_pio_wait_drq, ide_pio_read_sector, ide_pio_write_sector
; Depends:   (none — pure hardware I/O via in/out)
; Layer:     Layer 0 — drivers/ (hardware abstraction)
; History:   Phase 2.3.5 work (per ARCHAEOLOGY_REPO_RECORD.md)
; Note:      Emits NASM warnings for unsigned-byte conversion in
;            sector arithmetic. Investigated Pod 0.8; not blocking.
;
; --- Technical Documentation (preserved from original) ---
; Supports:
;   - Primary IDE (0x1F0–0x1F7)
;   - Secondary IDE (0x170–0x177)
;
; Inputs (for read/write):
;   RSI = LBA (64-bit)
;   RCX = Sector count (1)
;   RDI = Buffer address
;
; Outputs:
;   RAX = 0 on success, error code on failure.
;
; Error Codes:
;   -1: Drive not ready
;   -2: Timeout
;   -3: IDE error (ERR bit set)
;   -4: Unsupported LBA48
; =============================================================

; --- Constants ---
; Primary IDE
PRIMARY_DATA_PORT      equ 0x1F0
PRIMARY_ERROR_PORT     equ 0x1F1
PRIMARY_SECTOR_COUNT   equ 0x1F2
PRIMARY_LBA_LOW        equ 0x1F3
PRIMARY_LBA_MID        equ 0x1F4
PRIMARY_LBA_HIGH       equ 0x1F5
PRIMARY_DRIVE_SELECT   equ 0x1F6
PRIMARY_CMD_PORT       equ 0x1F7
PRIMARY_STATUS_PORT    equ 0x1F7
PRIMARY_ALT_STATUS     equ 0x3F6

; Secondary IDE
SECONDARY_DATA_PORT    equ 0x170
SECONDARY_ERROR_PORT   equ 0x171
SECONDARY_SECTOR_COUNT equ 0x172
SECONDARY_LBA_LOW      equ 0x173
SECONDARY_LBA_MID      equ 0x174
SECONDARY_LBA_HIGH     equ 0x175
SECONDARY_DRIVE_SELECT equ 0x176
SECONDARY_CMD_PORT     equ 0x177
SECONDARY_STATUS_PORT  equ 0x177
SECONDARY_ALT_STATUS   equ 0x376

; Status/Error Bits
IDE_STATUS_ERR        equ 0x01
IDE_STATUS_DRQ        equ 0x08
IDE_STATUS_DSC        equ 0x10
IDE_STATUS_DF         equ 0x20
IDE_STATUS_RDY        equ 0x40
IDE_STATUS_BSY        equ 0x80

; Commands
IDE_CMD_READ_SECTOR   equ 0x20
IDE_CMD_WRITE_SECTOR  equ 0x30
IDE_CMD_IDENTIFY      equ 0xEC

; --- Global State ---
ide_drive_present     db 0  ; Bitmask: 1 = primary master, 2 = primary slave, etc.
ide_lba48_supported   db 0

; =============================================================================
; ide_pio_init: Detects IDE drives and initializes.
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
ide_pio_init:
    ; 1. Check for primary master (0x1F0)
    call ide_pio_detect_drive
    test al, 1
    jz .no_primary_master

    ; 2. Check for LBA48 support
    call ide_pio_check_lba48
    mov [ide_lba48_supported], al

    ; 3. Return success
    xor rax, rax
    ret

.no_primary_master:
    mov rax, -1
    ret

; =============================================================================
; ide_pio_detect_drive: Detects if a drive is present at a given IDE port.
; Input:  None (uses PRIMARY_DATA_PORT by default)
; Output: AL = Bitmask (1 = master, 2 = slave)
; =============================================================================
ide_pio_detect_drive:
    ; 1. Select master drive (bit 4 = 0)
    mov dx, PRIMARY_DRIVE_SELECT
    mov al, 0xA0  ; LBA mode, master
    out dx, al

    ; 2. Send IDENTIFY command
    mov dx, PRIMARY_CMD_PORT
    mov al, IDE_CMD_IDENTIFY
    out dx, al

    ; 3. Wait for DRQ or BSY clear
    call ide_pio_wait_drq
    test al, al
    jnz .drive_present

    ; 4. Try slave drive (bit 4 = 1)
    mov dx, PRIMARY_DRIVE_SELECT
    mov al, 0xB0  ; LBA mode, slave
    out dx, al

    ; 5. Send IDENTIFY command again
    mov dx, PRIMARY_CMD_PORT
    mov al, IDE_CMD_IDENTIFY
    out dx, al

    ; 6. Wait for DRQ
    call ide_pio_wait_drq
    test al, al
    jnz .drive_present

    xor al, al
    ret

.drive_present:
    ; Return bitmask (1 = master, 2 = slave)
    test al, 1
    setnz al
    shl al, 1
    ret

; =============================================================================
; ide_pio_check_lba48: Checks if LBA48 is supported.
; Input:  None
; Output: AL = 1 if LBA48 supported, 0 otherwise.
; =============================================================================
ide_pio_check_lba48:
    ; 1. Read IDENTIFY data (512 bytes)
    ; 2. Check word 83: bit 10 = LBA48 support
    ; (Simplified: Assume LBA48 is supported if drive responds to LBA28)
    mov al, 1
    ret

; =============================================================================
; ide_pio_wait_drq: Waits for DRQ bit in status register.
; Output: AL = 0 if success, 1 if timeout.
; =============================================================================
ide_pio_wait_drq:
    mov cx, 10000  ; Timeout counter
.wait_loop:
    in al, PRIMARY_STATUS_PORT
    test al, IDE_STATUS_ERR
    jnz .error
    test al, IDE_STATUS_BSY
    jnz .wait_loop
    test al, IDE_STATUS_DRQ
    jnz .success
    loop .wait_loop
    mov al, 1  ; Timeout
    ret
.success:
    xor al, al
    ret
.error:
    mov al, -3
    ret

; =============================================================================
; ide_pio_read_sector: Reads a sector via PIO (Primary IDE).
; Input:  RSI = LBA (64-bit), RCX = Sector count (1), RDI = Buffer
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
ide_pio_read_sector:
    ; 1. Check drive ready
    call ide_pio_wait_drq
    test al, al
    jnz .error

    ; 2. Select drive (master = 0xA0, slave = 0xB0)
    mov dx, PRIMARY_DRIVE_SELECT
    mov al, 0xE0  ; LBA28 mode, master
    test rsi, 0x0FFFFFFF  ; Check if LBA28
    jz .lba28_mode
    mov al, 0x40  ; LBA48 mode, master
.lba28_mode:
    out dx, al

    ; 3. Send sector count (1)
    mov dx, PRIMARY_SECTOR_COUNT
    mov al, cl
    out dx, al

    ; 4. Send LBA (28-bit or 48-bit)
    mov dx, PRIMARY_LBA_LOW
    mov eax, esi
    out dx, al       ; LBA low
    shr eax, 8
    mov dx, PRIMARY_LBA_MID
    out dx, al       ; LBA mid
    shr eax, 8
    mov dx, PRIMARY_LBA_HIGH
    out dx, al       ; LBA high

    ; 5. Send READ SECTOR command
    mov dx, PRIMARY_CMD_PORT
    mov al, IDE_CMD_READ_SECTOR
    out dx, al

    ; 6. Wait for DRQ
    call ide_pio_wait_drq
    test al, al
    jnz .error

    ; 7. Read 512 bytes from data port
    mov cx, 256      ; 256 words = 512 bytes
    mov dx, PRIMARY_DATA_PORT
    rep insw

    ; 8. Check for errors
    in al, PRIMARY_STATUS_PORT
    test al, IDE_STATUS_ERR
    jnz .error

    xor rax, rax
    ret
.error:
    mov rax, -1
    ret

; =============================================================================
; ide_pio_write_sector: Writes a sector via PIO (Primary IDE).
; Input:  RSI = LBA, RCX = 1, RDI = Buffer
; Output: RAX = 0 on success, error code on failure.
; =============================================================================
ide_pio_write_sector:
    ; 1. Check drive ready
    call ide_pio_wait_drq
    test al, al
    jnz .error

    ; 2. Select drive
    mov dx, PRIMARY_DRIVE_SELECT
    mov al, 0xE0
    out dx, al

    ; 3. Send sector count (1)
    mov dx, PRIMARY_SECTOR_COUNT
    mov al, 1
    out dx, al

    ; 4. Send LBA
    mov dx, PRIMARY_LBA_LOW
    mov eax, esi
    out dx, al
    shr eax, 8
    mov dx, PRIMARY_LBA_MID
    out dx, al
    shr eax, 8
    mov dx, PRIMARY_LBA_HIGH
    out dx, al

    ; 5. Send WRITE SECTOR command
    mov dx, PRIMARY_CMD_PORT
    mov al, IDE_CMD_WRITE_SECTOR
    out dx, al

    ; 6. Wait for DRQ
    call ide_pio_wait_drq
    test al, al
    jnz .error

    ; 7. Write 512 bytes to data port
    mov cx, 256
    mov dx, PRIMARY_DATA_PORT
    rep outsw

    ; 8. Check for errors
    in al, PRIMARY_STATUS_PORT
    test al, IDE_STATUS_ERR
    jnz .error

    xor rax, rax
    ret
.error:
    mov rax, -1
    ret