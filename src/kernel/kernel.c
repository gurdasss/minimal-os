// kernel.c
// Minimal C kernel for a bare-metal x86 operating system
// This kernel runs in 32-bit Protected Mode and prints to the serial port.

// ============================================================================
// Kernel Entry Point (MUST BE FIRST!)
// ============================================================================

// kernel_main() is the entry point for the C kernel.
// The bootloader will jump to this function after:
//   1. Switching to Protected Mode
//   2. Setting up the GDT
//   3. Initializing the serial port
//   4. Loading the kernel from disk into memory at 0x1000
//
// This function must NEVER return, because there's nothing to return to.
// If it returns, the CPU will try to execute whatever garbage is in memory
// after this function, which will cause a crash.
void kernel_main(void) {
    // Write directly to serial port without function call
    // The bootloader has initialized the serial port to COM1 (0x3F8)
    
    serial_print("Hello, Kernel!\n");
    // "H" = 0x48
    // asm volatile ("mov $0x3F8, %%edx; mov $0x48, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // "e" = 0x65
    // asm volatile ("mov $0x3F8, %%edx; mov $0x65, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // "l" = 0x6c
    // asm volatile ("mov $0x3F8, %%edx; mov $0x6c, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // "l" = 0x6c
    // asm volatile ("mov $0x3F8, %%edx; mov $0x6c, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // "o" = 0x6f
    // asm volatile ("mov $0x3F8, %%edx; mov $0x6f, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // " " = 0x20
    // asm volatile ("mov $0x3F8, %%edx; mov $0x20, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // "K" = 0x4b
    // asm volatile ("mov $0x3F8, %%edx; mov $0x4b, %%al; out %%al, (%%dx)" : : : "%edx", "%al");
    
    // Hang forever in an infinite loop.
    while(1) {
        asm volatile ("hlt");
    }
}

// ============================================================================
// Hardware Access Functions (after entry point)
// ============================================================================

// Write a byte to an I/O port using the x86 'out' instruction.
// This is needed because the serial port uses port-mapped I/O (not memory-mapped).
// The serial port is at I/O port 0x3F8, which is in a separate address space
// from memory, so we can't just write to it like a normal pointer.
static inline void outb(unsigned short port, unsigned char val) {
    // Inline assembly: "outb %0, %1" means "out AL, DX"
    // "a"(val) puts val into the AL register
    // "Nd"(port) puts port into the DX register
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}

// ============================================================================
// Serial Port Functions
// ============================================================================

// Write a single character to the COM1 serial port at 0x3F8.
// The bootloader already initialized the serial port, so we can write directly.
void serial_putchar(char c) {
    outb(0x3F8, c);
}

// Write a null-terminated string to the serial port.
// This is our kernel's equivalent of printf() — but much simpler!
void serial_print(const char* str) {
    while (*str) {
        serial_putchar(*str);
        str++;
    }
}