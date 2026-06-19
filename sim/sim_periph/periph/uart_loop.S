# uart_loop.S — UART loopback test
#
# Flow:
#   1. Testbench sends TEST_BYTE on i_rx_serial (UART frame).
#   2. RX interrupt fires: ISR reads byte, stores to rx_data, sets rx_ready.
#   3. Main validates rx_data == TEST_BYTE, then echoes byte via TX.
#   4. TX-done interrupt fires: ISR sets tx_done flag.
#   5. Main waits for tx_done, then writes pass sentinel (0x00c0ffee) to a0.
#   6. Testbench captures the TX frame on o_tx_serial and checks it.
#
# BAUD_DIV_SIM must match the localparam in uart_loop_tb.sv.

#define PLIC_BASE       0x4000
#define UART_BASE       0x6000
#define BAUD_DIV_SIM    10          /* simulation baud divisor */
#define TEST_BYTE       0x42        /* 'B' — must match uart_loop_tb.sv */

#define PLIC_ENABLE     0x00
#define PLIC_CLAIM      0x08
#define PLIC_COMPLT     0x0C

#define UART_TX         0x00
#define UART_RX         0x04
#define UART_STAT       0x08
#define UART_BDIV       0x0C

    .section .text
    .global _start

_start:
    li   sp, 0x4000                 /* stack at top of RAM (grows down) */

    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, UART_BASE
    li   t1, BAUD_DIV_SIM
    sw   t1, UART_BDIV(t0)         /* set simulation baud rate */

    li   t0, PLIC_BASE
    li   t1, 0x3                   /* enable source 0 (RX) + source 1 (TX done) */
    sw   t1, PLIC_ENABLE(t0)

    li   t0, 0x800
    csrw mie, t0                   /* MEIE: machine external interrupt enable */
    csrsi mstatus, 8               /* mstatus.MIE = 1 */

/* --- wait for RX byte from testbench --- */
wait_rx:
    la   t0, rx_ready
    lw   t0, 0(t0)
    beqz t0, wait_rx

/* --- validate received byte --- */
    la   t0, rx_data
    lw   t0, 0(t0)
    li   t1, TEST_BYTE
    bne  t0, t1, fail

/* --- echo byte back via TX --- */
wait_tx_idle:
    li   t0, UART_BASE
    lw   t1, UART_STAT(t0)
    andi t1, t1, 1                 /* STATUS[0] = tx_idle */
    beqz t1, wait_tx_idle

    li   t1, TEST_BYTE
    sw   t1, UART_TX(t0)

/* --- wait for TX-done interrupt --- */
wait_tx_done:
    la   t0, tx_done
    lw   t0, 0(t0)
    beqz t0, wait_tx_done

    li   a0, 0x00c0ffee            /* pass sentinel */
    j    halt
fail:
    li   a0, 0xdeaddead
halt:
    j    halt

/* ---- trap handler ---- */
    .balign 4
trap_handler:
    addi sp, sp, -16
    sw   ra,  0(sp)
    sw   t0,  4(sp)
    sw   t1,  8(sp)
    sw   t2, 12(sp)

    csrr t0, mcause
    bgez t0, trap_done             /* bit 31 = 0 → exception, not expected here */

    li   t0, PLIC_BASE
    lw   t1, PLIC_CLAIM(t0)        /* claim interrupt; t1 = source ID */

    beqz t1, isr_rx                /* source 0 → UART RX */
    li   t2, 1
    beq  t1, t2, isr_tx            /* source 1 → UART TX done */
    j    isr_complete

isr_rx:
    li   t0, UART_BASE
    lw   t2, UART_RX(t0)           /* read byte (clears rx_valid) */
    la   t0, rx_data
    sw   t2, 0(t0)                 /* store received byte */
    la   t0, rx_ready
    li   t2, 1
    sw   t2, 0(t0)                 /* signal main loop */
    /* t1 = 0 from CLAIM — use as COMPLETE source ID */
    j    isr_complete

isr_tx:
    la   t0, tx_done
    li   t2, 1
    sw   t2, 0(t0)                 /* signal main loop */
    /* t1 = 1 from CLAIM — use as COMPLETE source ID */

isr_complete:
    li   t0, PLIC_BASE
    sw   t1, PLIC_COMPLT(t0)       /* COMPLETE: re-arm source */

trap_done:
    lw   ra,  0(sp)
    lw   t0,  4(sp)
    lw   t1,  8(sp)
    lw   t2, 12(sp)
    addi sp, sp, 16
    mret

/* ---- data ---- */
    .section .data
rx_data:  .word 0
rx_ready: .word 0
tx_done:  .word 0
