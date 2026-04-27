; This is a simple bootloader that demonstrates how to switch from real mode to protected mode and print a message on the screen.
; This code is written in x86 assembly and is intended to be compiled with NASM.
; The bootloader will be loaded at address 0x7C00 by the BIOS, and it will print a message
; The bootloader must be exactly 512 bytes in size, and the last two bytes must be 0xAA55 to indicate a valid boot sector.

; The CPU starts in real mode, so we need to use 16-bit instructions and segment registers.
[BITS 16]

; The ORG directive tells the assembler that the code will be loaded at address 0x7C00
[ORG 0x7C00]

start:
    ; 1. Set up the stack
    cli                  ; disable interrupts while we set up
    xor ax, ax           ; ax = 0
    mov ds, ax           ; data segment = 0
    mov es, ax           ; extra segment = 0
    mov ss, ax           ; stack segment = 0
    mov sp, 0x7C00       ; stack pointer starts just below our bootloader
                         ; NOTE: no sti here — we stay with interrupts disabled
                         ; since we are heading straight into the mode switch.
                         ; Re-enabling interrupts before the switch opens an unsafe
                         ; window where a BIOS interrupt could fire against an
                         ; already-invalid IVT.

    ; 2. Load the GDT
    lgdt [gdt_descriptor]   ; tell the CPU where the GDT is

    ; 3. Enable Protected Mode (flip CR0)
    mov eax, cr0            ; copy CR0 into eax (can't modify CR0 directly)
    or eax, 0x1             ; set bit 0 (Protected Mode Enable flag)
    mov cr0, eax            ; write it back — Protected Mode is now on

    ; 4. Far jump into 32-bit code
    ; The word prefix forces a 16-bit far jump encoding, which is correct
    ; since we are still in 16-bit Real Mode when this instruction executes.
    ; The far jump also flushes the CPU pipeline, forcing it to fully commit
    ; to Protected Mode before executing any 32-bit instruction.
    jmp word 0x08:protected_mode

; ── GDT lives here — after the executable 16-bit code ────────────────────────
; The GDT must be in memory before we execute lgdt, but it must not sit between
; the stack setup and the mode switch instructions, otherwise the CPU would fall
; into the GDT data bytes and try to execute them as instructions.

gdt_start:

gdt_null:               ; Entry 0 — mandatory null descriptor
    dd 0x00000000       ; first 4 bytes — all zero
    dd 0x00000000       ; next 4 bytes — all zero

gdt_code:               ; Entry 1 — code segment
    dw 0xFFFF           ; Limit (bits 0-15) = 0xFFFF
    dw 0x0000           ; Base  (bits 0-15) = 0x0000
    db 0x00             ; Base  (bits 16-23) = 0x00
    db 0x9A             ; Access byte (Ring 0, executable, readable)
    db 0xCF             ; Flags + Limit (bits 16-19): 32-bit, 4KB granularity
    db 0x00             ; Base  (bits 24-31) = 0x00

gdt_data:               ; Entry 2 — data segment
    dw 0xFFFF           ; Limit (bits 0-15) = 0xFFFF
    dw 0x0000           ; Base  (bits 0-15) = 0x0000
    db 0x00             ; Base  (bits 16-23) = 0x00
    db 0x92             ; Access byte (Ring 0, read/write)
    db 0xCF             ; Flags + Limit (bits 16-19): 32-bit, 4KB granularity
    db 0x00             ; Base  (bits 24-31) = 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1   ; size of GDT minus 1
    dd gdt_start                  ; address of GDT

; ── 32-bit Protected Mode ─────────────────────────────────────────────────────
; [BITS 32] must come before the label, not after it. If it came after,
; the label would be associated with the address before the switch and
; the first instruction would be assembled as 16-bit.
[BITS 32]
protected_mode:
    ; 5. Set up segment registers
    ; The far jump only updated CS. All other segment registers still contain
    ; their old 16-bit Real Mode values, which are now invalid in Protected Mode.
    ; We must reload them all manually with the data segment selector (0x10).
    mov ax, 0x10     ; 0x10 = GDT offset of data segment (entry 2, 8 bytes each)
    mov ds, ax       ; reload data segment
    mov es, ax       ; reload extra segment
    mov fs, ax       ; reload FS
    mov gs, ax       ; reload GS
    mov ss, ax       ; reload stack segment

    ; 6. Set up a fresh 32-bit stack
    ; 0x7C00 was fine for 16-bit Real Mode but we now have a full 32-bit
    ; address space. 0x90000 is a safe open region well above our bootloader.
    mov esp, 0x90000

    ; 7. Initialise COM1 serial port (0x3F8)
    ; We are writing to the serial port instead of the VGA buffer at 0xB8000
    ; because this environment is headless (GitHub Codespaces) and has no
    ; graphical display. Serial output via -serial stdio works in any terminal.
    ; This approach also applies directly to the Raspberry Pi later (UART).
    ; The serial port must be initialised before we can write to it —
    ; unlike the VGA buffer, you cannot just write bytes and expect output.
    mov dx, 0x3F9
    mov al, 0x00
    out dx, al        ; disable interrupts

    mov dx, 0x3FB
    mov al, 0x80
    out dx, al        ; enable DLAB to set baud rate divisor

    mov dx, 0x3F8
    mov al, 0x03
    out dx, al        ; baud rate low byte (38400 baud)

    mov dx, 0x3F9
    mov al, 0x00
    out dx, al        ; baud rate high byte

    mov dx, 0x3FB
    mov al, 0x03
    out dx, al        ; 8 bits, no parity, one stop bit

    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al        ; enable FIFO

    mov dx, 0x3FC
    mov al, 0x03
    out dx, al        ; enable RTS and DTR

    ; 8. Print message via serial port
    mov esi, pm_message       ; point ESI at our message string

print_loop_32:
    lodsb                     ; load byte at [ESI] into AL, increment ESI
    cmp al, 0                 ; null terminator?
    je done_32                ; if yes, we're done
    mov dx, 0x3F8             ; COM1 serial port
    out dx, al                ; write character to serial port
                              ; unlike int 0x10 which called BIOS code via the IVT,
                              ; out writes directly to hardware — no OS or BIOS needed,
                              ; which is why it works in Protected Mode.
    jmp print_loop_32

done_32:
    cli   ; disable interrupts — no IDT is set up yet, so any interrupt
          ; firing here would cause a triple fault and silent reboot.
    hlt   ; halt the CPU

; The message we want to print. Null-terminated so the print loop knows when to stop.
; 0x0D = carriage return, 0x0A = newline
pm_message db 'Hello from Protected Mode!', 0x0D, 0x0A, 0

; Pad the rest of the boot sector with zeros until we reach 510 bytes, then add the boot signature (0xAA55)
times 510 - ($ - $$) db 0
; The boot signature is a specific value that must be present at the end of the boot sector to indicate to the BIOS that this is a valid bootable device.
; Note: x86 is little-endian, so we write 0xAA55 and it gets stored in memory as 0x55 then 0xAA
dw 0xAA55