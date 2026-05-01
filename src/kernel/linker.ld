/* Linker script for minimal-os kernel */

ENTRY(kernel_entry)     /* Tell the linker the entry point symbol */

SECTIONS
{
    /* Kernel starts at 0x1000 (4KB) - loaded by bootloader */
    . = 0x1000;

    /* Code section */
    .text : {
        *(.text)        /* All .text sections from all object files */
    }

    /* Read-only data (string literals, const variables) */
    .rodata : {
        *(.rodata)
    }

    /* Initialized data */
    .data : {
        *(.data)
    }

    /* Uninitialized data */
    .bss : {
        *(.bss)
    }
}
