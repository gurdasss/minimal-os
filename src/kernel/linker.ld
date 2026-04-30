/* Linker Script for the kernel
 * 
 * This script tells the linker how to arrange the kernel code and data
 * in memory. The kernel will be loaded at 0x1000 by the bootloader.
 */

/* Entry point - where execution begins */
ENTRY(kernel_main)

SECTIONS
{
    /* Load address: 0x1000 (after the bootloader at 0x7C00 and some reserved space) */
    . = 0x1000;
    
    /* Text section: executable code */
    .text : {
        *(.text*)
        *(.rodata*)
    }
    
    /* Data section: initialized data */
    .data : {
        *(.data*)
    }
    
    /* BSS section: uninitialized data (doesn't take space in binary, only in memory) */
    .bss : {
        *(.bss*)
    }
}

