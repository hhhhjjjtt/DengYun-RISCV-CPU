# gpio_test.S — GPIO output drive and falling-edge interrupt test
#
# Flow:
#   1. Set DIR = 0x1 (pin 0 = output, pin 1 = input)
#   2. Set OUT_DATA = 0x1 (drive pin 0 high)
#   3. Enable INT_EN = 0x2 (falling-edge interrupt on pin 1)
#   4. Enable PLIC source 0 (GPIO), MEIE, MIE
#   5. Write setup_done = 1 (signals testbench to proceed)
#   6. Spin until int_count > 0 (ISR will set it)
#   7. Copy isr_int_state -> s1, isr_claim_id -> s2, int_count -> s0
#   8. Write pass sentinel 0x00c0ffee to a0; halt
#
# ISR flow:
#   - PLIC claim -> expect source ID 0 (GPIO is src[0])
#   - Read INT_STATE, snapshot to isr_int_state, then W1C-clear
#   - Increment int_count
#   - PLIC complete
#
# Testbench checks (via registers, avoiding D-cache stale reads):
#   s0 (regs[8])  = int_count        (expect 1)
#   s1 (regs[9])  = isr_int_state    (expect 0x2 = bit1, pin1 fell)
#   s2 (regs[18]) = isr_claim_id     (expect 0   = GPIO source)
#   a0 (regs[10]) = pass sentinel    (expect 0x00c0ffee)

#define GPIO_BASE       0x8000
#define PLIC_BASE       0x4000

#define GPIO_OUT_DATA   0x00
#define GPIO_IN_DATA    0x04
#define GPIO_DIR        0x08
#define GPIO_INT_EN     0x0C
#define GPIO_INT_STATE  0x10

#define PLIC_ENABLE     0x00
#define PLIC_CLAIM      0x08
#define PLIC_COMPLT     0x0C

    .section .text
    .global _start

_start:
    li   sp, 0x4000

    la   t0, trap_handler
    csrw mtvec, t0

    /* configure GPIO */
    li   t0, GPIO_BASE
    li   t1, 0x1
    sw   t1, GPIO_DIR(t0)          /* pin 0 = output, pin 1 = input */
    sw   t1, GPIO_OUT_DATA(t0)     /* drive pin 0 high */

    /* clear any stale/X INT_STATE bits caused by gpio_pins[0] floating
       (IOBUF is hi-Z before DIR is written; Z propagates through the 2-FF
       sync chain and infects INT_STATE via data_in_fall).
       Writing all-ones forces: (anything) & ~0xFFFF = 0 — annihilates X. */
    li   t1, -1
    sw   t1, GPIO_INT_STATE(t0)

    /* enable falling-edge interrupt on pin 1 */
    li   t1, 0x2
    sw   t1, GPIO_INT_EN(t0)

    /* enable PLIC source 0 (GPIO interrupt) */
    li   t0, PLIC_BASE
    li   t1, 0x1
    sw   t1, PLIC_ENABLE(t0)

    li   t0, 0x800
    csrw mie, t0                   /* MEIE: machine external interrupt enable */
    csrsi mstatus, 8               /* mstatus.MIE = 1 */

    /* signal testbench: setup is complete, pin 0 is high, ready for edge */
    la   t0, setup_done
    li   t1, 1
    sw   t1, 0(t0)

wait_int:
    la   t0, int_count
    lw   s0, 0(t0)
    beqz s0, wait_int

    /* copy ISR results to saved registers for testbench inspection */
    la   t0, isr_int_state
    lw   s1, 0(t0)
    la   t0, isr_claim_id
    lw   s2, 0(t0)

    li   a0, 0x00c0ffee
    j    halt
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
    bgez t0, trap_done             /* bit 31 = 0 -> exception, not expected */

    /* claim interrupt from PLIC; t1 = source ID (expect 0 = GPIO) */
    li   t0, PLIC_BASE
    lw   t1, PLIC_CLAIM(t0)

    /* save claim ID */
    la   t0, isr_claim_id
    sw   t1, 0(t0)

    /* read INT_STATE, snapshot it, then W1C-clear */
    li   t0, GPIO_BASE
    lw   t2, GPIO_INT_STATE(t0)
    la   t0, isr_int_state
    sw   t2, 0(t0)
    li   t0, GPIO_BASE
    sw   t2, GPIO_INT_STATE(t0)    /* write 1s to clear the bits that fired */

    /* increment int_count */
    la   t0, int_count
    lw   t2, 0(t0)
    addi t2, t2, 1
    sw   t2, 0(t0)

    /* PLIC complete: re-arm source */
    li   t0, PLIC_BASE
    sw   t1, PLIC_COMPLT(t0)

trap_done:
    lw   ra,  0(sp)
    lw   t0,  4(sp)
    lw   t1,  8(sp)
    lw   t2, 12(sp)
    addi sp, sp, 16
    mret

/* ---- data ---- */
    .section .data
setup_done:    .word 0
int_count:     .word 0
isr_int_state: .word 0
isr_claim_id:  .word 0
