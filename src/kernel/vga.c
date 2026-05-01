#include "vga.h"

// Static variables to track cursor position
// 'static' means these are private to this file only
static int cursor_row = 0;
static int cursor_col = 0;

// Clear the entire screen by writing spaces with default color
void vga_clear(void) {
    char* vga = (char*)VGA_MEMORY;
    
    // Loop through all 80*25 = 2000 character cells
    for (int i = 0; i < VGA_WIDTH * VGA_HEIGHT; i++) {
        vga[i * 2] = ' ';              // Character: space
        vga[i * 2 + 1] = VGA_DEFAULT_COLOR;  // Attribute: white on black
    }
    
    // Reset cursor to top-left
    cursor_row = 0;
    cursor_col = 0;
}

// Write a single character at the current cursor position
void vga_putchar(char c) {
    // Handle newline character
    if (c == '\n') {
        cursor_col = 0;           // Move to start of line
        cursor_row++;             // Move to next row
        
        // If we've gone past the bottom, stop (no scrolling yet)
        if (cursor_row >= VGA_HEIGHT) {
            cursor_row = VGA_HEIGHT - 1;
        }
        return;
    }
    
    // Calculate memory offset for current cursor position
    int offset = (cursor_row * VGA_WIDTH + cursor_col) * 2;
    char* position = (char*)(VGA_MEMORY + offset);
    
    // Write character and attribute
    position[0] = c;
    position[1] = VGA_DEFAULT_COLOR;
    
    // Advance cursor to next column
    cursor_col++;
    
    // If we've reached the end of the row, wrap to next line
    if (cursor_col >= VGA_WIDTH) {
        cursor_col = 0;
        cursor_row++;
        
        // If we've gone past the bottom, stop
        if (cursor_row >= VGA_HEIGHT) {
            cursor_row = VGA_HEIGHT - 1;
        }
    }
}

// Print a null-terminated string
void vga_print(const char* str) {
    // Loop until we hit the null terminator
    while (*str != '\0') {
        vga_putchar(*str);
        str++;  // Move to next character
    }
}