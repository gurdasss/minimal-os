; A simple bootloader that prints a message to the screen
; This code is written in x86 assembly and is intended to be compiled with NASM.
; The bootloader will be loaded at address 0x7C00 by the BIOS, and it will print a message
; The bootloader must be exactly 512 bytes in size, and the last two bytes must be 0xAA55 to indicate a valid boot sector.

; The CPU starts in real mode, so we need to use 16-bit instructions and segment registers.
[BITS 16]

; The ORG directive tells the assembler that the code will be loaded at address 0x7C00
[ORG 0x7C00]

start:
    ; Load the memory address of our string into the SI register (Source Index). 
    ; SI is a register traditionally used for pointing to a source of data.
    mov si, message

    ; Set up the BIOS teletype print function — before we enter the print loop
    mov bh, 0x00 ; BH = 0x00 is the page number (for text mode, this is usually 0)
    mov bl, 0x07 ; BL = 0x07 sets the text attribute (white on black)

print_loop:
    lodsb ; Load the byte at [SI] into AL and increment SI. This is used to read each character of the message.
    cmp al, 0 ; Check if the character is the null terminator (0), which indicates the end of the string.
    je  done ; If we have reached the end of the string, jump to the done label to halt the CPU.
    mov ah, 0x0E ; AH = 0x0E is the BIOS teletype output function. We reload it here because int 0x10 may clobber AH.
    int 0x10 ; Call the BIOS video interrupt to print the character in AL to the screen using the teletype function.
    jmp print_loop

done:
    cli ; Clear interrupts to prevent any further interrupt handling, as we are about to halt the CPU.
    hlt

; The message we want to print. It must be null-terminated (end with 0) so that our print loop knows when to stop.
message db 'Hello from the Boot Sector!', 0x0D, 0x0A, 0

; Pad the rest of the boot sector with zeros until we reach 510 bytes, then add the boot signature (0xAA55)
times 510 - ($ - $$) db 0
; The boot signature is a specific value that must be present at the end of the boot sector to indicate to the BIOS that this is a valid bootable device.
; Note: x86 is little-endian, so we write 0xAA55 and it gets stored in memory as 0x55 then 0xAA
dw 0xAA55