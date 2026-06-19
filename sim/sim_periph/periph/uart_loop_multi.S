# uart_loop_multi.S — UART continuous echo test
#
# Flow:
#   1. Set baud rate, enable UART RX interrupt via PLIC, enable MIE.
#   2. Spin on rx_ready (set by ISR when a byte arrives).
#   3. On rx_ready: save the byte, clear rx_ready, wait TX idle, echo byte, repeat.
#   4. Runs forever — no pass sentinel.
#      Testbench sends N bytes and verifies N frames echoed on o_tx_serial.
#
# Only RX interrupt (PLIC source 0) is used. TX is polled via UART_STAT[0].
# rx_ready is cleared BEFORE entering the TX-idle poll so a new byte can be
# received into rx_buf while we are still transmitting the previous one.
# The ISR saves/restores t0-t2 and ra, so t1 (holding the byte to echo) is
# safe across interrupt entry during the wait_tx_idle loop.

#define PLIC_BASE       0x4000
#define UART_BASE       0x6000
#define BAUD_DIV_SIM    10

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
    li   sp, 0x4000

    la   t0, trap_handler
    csrw mtvec, t0

    li   t0, UART_BASE
    li   t1, BAUD_DIV_SIM
    sw   t1, UART_BDIV(t0)

    li   t0, PLIC_BASE
    li   t1, 0x1                   # enable source 0 (RX) only
    sw   t1, PLIC_ENABLE(t0)

    li   t0, 0x800
    csrw mie, t0                   # mie.MEIE = 1
    csrsi mstatus, 8               # mstatus.MIE = 1

echo_loop:
    la   t0, rx_ready
    lw   t0, 0(t0)
    beqz t0, echo_loop             # spin until ISR signals byte ready

    la   t0, rx_buf
    lw   t1, 0(t0)                 # t1 = received byte (ISR saves/restores t1, so this is stable)

    la   t0, rx_ready
    sw   zero, 0(t0)               # clear flag before TX poll so ISR can queue next byte

wait_tx_idle:
    li   t0, UART_BASE
    lw   t2, UART_STAT(t0)
    andi t2, t2, 1                 # STAT[0] = tx_idle
    beqz t2, wait_tx_idle

    sw   t1, UART_TX(t0)          # echo byte

    j    echo_loop

/* ---- trap handler: handles UART RX (PLIC source 0) ---- */
    .balign 4
trap_handler:
    addi sp, sp, -16
    sw   ra,  0(sp)
    sw   t0,  4(sp)
    sw   t1,  8(sp)
    sw   t2, 12(sp)

    csrr t0, mcause
    bgez t0, trap_done             # bit31=0 → exception, ignore

    li   t0, PLIC_BASE
    lw   t1, PLIC_CLAIM(t0)        # claim; t1 = source ID

    bnez t1, isr_complete          # only handle source 0 (RX)

isr_rx:
    li   t0, UART_BASE
    lw   t2, UART_RX(t0)           # read byte, clears rx_valid in UART
    la   t0, rx_buf
    sw   t2, 0(t0)
    la   t0, rx_ready
    li   t2, 1
    sw   t2, 0(t0)

isr_complete:
    li   t0, PLIC_BASE
    sw   t1, PLIC_COMPLT(t0)       # complete: re-arm the source

trap_done:
    lw   ra,  0(sp)
    lw   t0,  4(sp)
    lw   t1,  8(sp)
    lw   t2, 12(sp)
    addi sp, sp, 16
    mret

    .section .data
rx_buf:   .word 0
rx_ready: .word 0
