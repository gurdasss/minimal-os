; Kernel entry point — called from bootloader
; This stub sets up the stack and calls the C kernel

[BITS 32]               ; We're in 32-bit protected mode
[EXTERN kernel_main]    ; Declare that kernel_main exists (defined in kernel.c)

[GLOBAL kernel_entry]   ; Make kernel_entry visible to the linker

kernel_entry:
    ; 1. Set up stack pointer
    ; The bootloader already set ESP to 0x90000, but we'll be explicit here
    mov esp, 0x90000
    
    ; 2. Call the C kernel
    call kernel_main
    
    ; 3. If kernel_main somehow returns (it shouldn't), halt
    cli
    hlt