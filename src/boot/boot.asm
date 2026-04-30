; Updated bootloader for Project 3: Load the Kernel
; This bootloader:
; 1. Loads the kernel from disk (sector 1) into memory at 0x1000
; 2. Switches to Protected Mode
; 3. Jumps to the kernel

[BITS 16]
[ORG 0x7C00]

start:
    ; 1. Set up the stack
    cli                  ; disable interrupts while we set up
    xor ax, ax           ; ax = 0
    mov ds, ax           ; data segment = 0
    mov es, ax           ; extra segment = 0
    mov ss, ax           ; stack segment = 0
    mov sp, 0x7C00       ; stack pointer starts just below our bootloader
    
    ; Save the boot drive number that BIOS passed to us in DL
    ; We need this for the disk read operation
    mov [boot_drive], dl

    ; 2. Load the kernel from disk
    ; We'll use BIOS interrupt 0x13, function 0x02 (Read Sectors)
    ; This must happen BEFORE switching to Protected Mode because
    ; BIOS interrupts only work in Real Mode (they use the IVT)
    
    mov bx, 0x1000       ; ES:BX = 0x0000:0x1000 (destination address)
    mov al, 1            ; number of sectors to read (1 sector = 512 bytes)
    mov ch, 0            ; cylinder 0
    mov cl, 2            ; sector 2 (sector 1 is boot sector, kernel starts at sector 2)
    mov dh, 0            ; head 0
    mov dl, [boot_drive] ; drive number (saved from BIOS)
    mov ah, 0x02         ; BIOS function 0x02 = Read Sectors
    
    int 0x13             ; Call BIOS disk services
    
    ; Check if read was successful (CF = 0 means success)
    jc disk_error        ; if CF = 1, jump to error handler
    
    ; Disk read succeeded! Continue with bootloader

    ; 3. Load the GDT
    lgdt [gdt_descriptor]

    ; 4. Enable Protected Mode (flip CR0)
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; 5. Far jump into 32-bit code
    jmp word 0x08:protected_mode

; ── Error Handler (still in Real Mode) ───────────────────────────────────────
disk_error:
    ; If disk read fails, print an error message using BIOS interrupt 0x10
    ; then hang (we can't continue without the kernel)
    mov si, disk_error_msg
    
.print_loop:
    lodsb                     ; load byte from [SI] into AL, increment SI
    cmp al, 0                 ; null terminator?
    je .hang                  ; if yes, stop printing
    mov ah, 0x0E              ; BIOS function 0x0E = teletype output
    int 0x10                  ; print character in AL
    jmp .print_loop
    
.hang:
    cli
    hlt
    jmp .hang                 ; if hlt returns (shouldn't), loop forever

; ── Data ──────────────────────────────────────────────────────────────────────
boot_drive db 0
disk_error_msg db 'Disk read error!', 0x0D, 0x0A, 0

; ── GDT ───────────────────────────────────────────────────────────────────────
gdt_start:

gdt_null:
    dd 0x00000000
    dd 0x00000000

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A
    db 0xCF
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92
    db 0xCF
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

; ── 32-bit Protected Mode ─────────────────────────────────────────────────────
[BITS 32]
protected_mode:
    ; Set up segment registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Set up 32-bit stack
    mov esp, 0x90000

    ; Initialize COM1 serial port
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al

    mov dx, 0x3FB
    mov al, 0x80
    out dx, al

    mov dx, 0x3F8
    mov al, 0x03
    out dx, al

    mov dx, 0x3F9
    mov al, 0x00
    out dx, al

    mov dx, 0x3FB
    mov al, 0x03
    out dx, al

    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al

    mov dx, 0x3FC
    mov al, 0x03
    out dx, al

    ; Print bootloader message
    mov esi, boot_message

.print_loop:
    lodsb
    cmp al, 0
    je jump_to_kernel
    mov dx, 0x3F8
    out dx, al
    jmp .print_loop

jump_to_kernel:
    ; Jump to the kernel entry point at 0x1000
    ; The kernel is now loaded in memory and ready to run!
    jmp 0x1000

; Bootloader message (printed before jumping to kernel)
boot_message db 'Bootloader: Kernel loaded. Jumping to kernel...', 0x0D, 0x0A, 0

; Pad and add boot signature
times 510 - ($ - $$) db 0
dw 0xAA55