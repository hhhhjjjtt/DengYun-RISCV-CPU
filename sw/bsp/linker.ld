OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS {
    . = 0x00000000;

    .text : {
        KEEP(*(.text.start))    /* crt0 _start first */
        *(.text*)
    }

    . = 0x00010000;

    .data : {
        *(.rodata*)             /* rodata in RAM: ROM space has no D-cache path */
        *(.data*)
        *(.sdata*)
    }

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(.sbss*)
        *(COMMON)
        _bss_end = .;
    }

    _stack_top = 0x00020000;   /* top of RAM; stack grows down */
}
