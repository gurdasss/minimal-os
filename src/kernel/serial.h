#ifndef SERIAL_H
#define SERIAL_H

// COM1 serial port base address
#define SERIAL_COM1 0x3F8

// Function prototypes
void serial_init(void);
void serial_putchar(char c);
void serial_print(const char* str);

#endif // SERIAL_H