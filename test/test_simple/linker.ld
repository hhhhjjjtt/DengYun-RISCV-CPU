MEMORY
{
  ROM (rx)  : ORIGIN = 0x0000, LENGTH = 0x2000
  RAM (rwx) : ORIGIN = 0x2000, LENGTH = 0x1000
}

SECTIONS
{
  . = ORIGIN(ROM);

  .text : {
    *(.text.init)
    *(.text.main)
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : {
    *(.data*)
  } > RAM AT > ROM

  .bss : {
    *(.bss*)
    *(COMMON)
  } > RAM

  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}