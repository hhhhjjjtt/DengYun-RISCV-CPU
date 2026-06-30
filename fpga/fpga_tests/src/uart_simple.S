# uart_simple.S — Print "Hello World!\r\n" over UART

#define UART_BASE       0x21000
#define UART_TX_DATA    0x00
#define UART_STATUS     0x08
#define UART_BAUD_DIV   0x0C

#define CLINT_BASE      0x24000
#define MTIME_LO        0x00

#define BAUD_DIV_VAL    5208
#define DELAY_CYCLES    50000000

    .section .text
    .global _start

_start:
    li   sp, 0x20000

    /* set baud divisor for 50 MHz / 9600 */
    li   t0, UART_BASE
    li   t1, BAUD_DIV_VAL
    sw   t1, UART_BAUD_DIV(t0)

    /* s0 = CLINT_BASE (constant across loop) */
    li   s0, CLINT_BASE
    /* s1 = last_time */
    lw   s1, MTIME_LO(s0)
    /* s2 = delay (constant across loop) */
    li   s2, DELAY_CYCLES

main_loop:
    /* wait until 1 second has elapsed */
wait_1s:
    lw   t0, MTIME_LO(s0)
    sub  t1, t0, s1
    bltu t1, s2, wait_1s
    mv   s1, t0                  /* update reference time */

    /* send each byte of hello_str until null terminator */
    la   a0, hello_str
send_char:
    lbu  a1, 0(a0)
    beqz a1, main_loop           /* null terminator: done, wait for next second */

    li   t0, UART_BASE
wait_tx:
    lw   t1, UART_STATUS(t0)
    andi t1, t1, 1
    beqz t1, wait_tx

    sw   a1, UART_TX_DATA(t0)
    addi a0, a0, 1
    j    send_char

    .section .data
hello_str:
    .ascii "Hello World!\r\n"
    .byte  0
