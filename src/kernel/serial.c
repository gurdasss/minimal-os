#include "serial.h"

// Helper functions for port I/O
// These are inline assembly functions that let us read/write to hardware ports
static inline void outb(unsigned short port, unsigned char value) {
    __asm__ __volatile__("outb %0, %1" : : "a"(value), "Nd"(port));
}

static inline unsigned char inb(unsigned short port) {
    unsigned char value;
    __asm__ __volatile__("inb %1, %0" : "=a"(value) : "Nd"(port));
    return value;
}

// Initialize COM1 serial port for output
void serial_init(void) {
    // Disable interrupts
    outb(SERIAL_COM1 + 1, 0x00);
    
    // Enable DLAB (set baud rate divisor)
    outb(SERIAL_COM1 + 3, 0x80);
    
    // Set divisor to 3 (38400 baud)
    outb(SERIAL_COM1 + 0, 0x03);
    outb(SERIAL_COM1 + 1, 0x00);
    
    // 8 bits, no parity, one stop bit
    outb(SERIAL_COM1 + 3, 0x03);
    
    // Enable FIFO, clear them, with 14-byte threshold
    outb(SERIAL_COM1 + 2, 0xC7);
    
    // IRQs enabled, RTS/DSR set
    outb(SERIAL_COM1 + 4, 0x0B);
}

// Write a single character to serial port
void serial_putchar(char c) {
    // Wait for transmit buffer to be empty
    while ((inb(SERIAL_COM1 + 5) & 0x20) == 0);
    
    // Send the character
    outb(SERIAL_COM1, c);
}

// Write a null-terminated string to serial port
void serial_print(const char* str) {
    while (*str != '\0') {
        // Convert \n to \r\n for proper terminal output
        if (*str == '\n') {
            serial_putchar('\r');
        }
        serial_putchar(*str);
        str++;
    }
}