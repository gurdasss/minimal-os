#include "serial.h"
#include "vga.h"

// kernel.c
// Minimal C kernel for a bare-metal x86 operating system
// This kernel runs in 32-bit Protected Mode and demonstrates VGA text output.

// ============================================================================
// Helper Functions
// ============================================================================

// Helper function to print a byte as hex (for debugging)
void print_hex_byte(unsigned char byte) {
    const char hex_chars[] = "0123456789ABCDEF";
    serial_putchar(hex_chars[byte >> 4]);    // High nibble
    serial_putchar(hex_chars[byte & 0x0F]);  // Low nibble
}

// ============================================================================
// Kernel Entry Point
// ============================================================================

// kernel_main() is the entry point for the C kernel.
// The bootloader will jump to this function after:
//   1. Switching to Protected Mode
//   2. Setting up the GDT
//   3. Loading the kernel from disk into memory at 0x1000
//
// This function must NEVER return, because there's nothing to return to.
void kernel_main(void) {
    // Initialize serial port for debug output
    serial_init();
    
    serial_print("\n===========================================\n");
    serial_print("  minimal-os v0.1 - Kernel Boot Sequence\n");
    serial_print("===========================================\n\n");
    
    // Test 1: Clear VGA screen
    serial_print("[TEST 1] Clearing VGA screen...\n");
    vga_clear();
    serial_print("[PASS] VGA clear completed\n\n");
    
    // Test 2: Write to VGA
    serial_print("[TEST 2] Writing to VGA buffer...\n");
    vga_print("Welcome to minimal-os v0.1!\n");
    vga_print("Kernel loaded successfully.\n");
    vga_print("\nHello from Protected Mode with VGA output!");
    serial_print("[PASS] VGA write completed\n\n");
    
    // Test 3: Verify VGA contents by reading back
    serial_print("[TEST 3] Verifying VGA memory contents...\n");
    char* vga_memory = (char*)VGA_MEMORY;
    
    // Read back the first line: "Welcome to minimal-os v0.1!"
    // Check a few key characters
    if (vga_memory[0] == 'W' &&      // First char
        vga_memory[2] == 'e' &&      // Second char (skip attribute byte)
        vga_memory[4] == 'l' &&      // Third char
        vga_memory[6] == 'c') {      // Fourth char
        
        serial_print("[PASS] VGA memory verification successful!\n");
        serial_print("       First 4 chars: ");
        serial_putchar(vga_memory[0]);
        serial_putchar(vga_memory[2]);
        serial_putchar(vga_memory[4]);
        serial_putchar(vga_memory[6]);
        serial_print("\n");
        
        // Show the attribute byte too
        serial_print("       Attribute byte: 0x");
        print_hex_byte(vga_memory[1]);
        serial_print("\n");
        
    } else {
        serial_print("[FAIL] VGA memory verification failed!\n");
        serial_print("       Expected: 'Welc...'\n");
        serial_print("       Got: ");
        serial_putchar(vga_memory[0]);
        serial_putchar(vga_memory[2]);
        serial_putchar(vga_memory[4]);
        serial_putchar(vga_memory[6]);
        serial_print("\n");
    }
    
    serial_print("\n===========================================\n");
    serial_print("  Boot Complete - System Halted\n");
    serial_print("===========================================\n\n");
    
    // Halt the CPU
    // We use inline assembly here because there's no standard C function for 'hlt'
    while (1) {
        __asm__ __volatile__("hlt");
    }
}