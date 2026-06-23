# gpio_test.S — GPIO output drive and falling-edge interrupt test
#
# Flow:
#   1. Zero s0/s1/s2 (ISR result registers)
#   2. Set DIR = 0x1 (pin 0 = output, pin 1 = input)
#   3. Set OUT_DATA = 0x1 (drive pin 0 high)
#   4. Enable INT_EN = 0x2 (falling-edge interrupt on pin 1)
#   5. Enable PLIC source 2 (GPIO), MEIE, MIE
#   6. Write setup_done = 1 (signals testbench to proceed)
#   7. Spin until s0 > 0  (ISR increments s0 directly)
#   8. Write pass sentinel 0x00c0ffee to a0; halt
#
# ISR flow:
#   - PLIC claim -> save claim ID directly to s2 (no memory write)
#   - Read INT_STATE -> save directly to s1 (no memory write), then W1C-clear
#   - Increment s0 directly (no memory write)
#   - PLIC complete
#   NOTE: s0/s1/s2 are intentionally NOT saved/restored by the ISR;
#         they carry the output values back to the main thread via registers.
#
# Testbench checks (all via register file — no D-cache stale read risk):
#   s0 (regs[8])  = int_count        (expect 1)
#   s1 (regs[9])  = isr_int_state    (expect 0x2 = bit1, pin1 fell)
#   s2 (regs[18]) = isr_claim_id     (expect 2   = GPIO source)
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

    /* zero ISR result registers before enabling interrupts */
    li   s0, 0                          /* int_count     */
    li   s1, 0                          /* isr_int_state */
    li   s2, 0                          /* isr_claim_id  */

    /* configure GPIO */
    li   t0, GPIO_BASE
    li   t1, 0x1
    sw   t1, GPIO_DIR(t0)               /* pin 0 = output, pin 1 = input */
    sw   t1, GPIO_OUT_DATA(t0)          /* drive pin 0 high */

    /* clear any stale/X INT_STATE bits caused by gpio_pins[0] floating
       (IOBUF is hi-Z before DIR is written; Z propagates through the 2-FF
       sync chain and infects INT_STATE via data_in_fall).
       Writing all-ones forces: (anything) & ~0xFFFF = 0 — annihilates X. */
    li   t1, -1
    sw   t1, GPIO_INT_STATE(t0)

    /* enable falling-edge interrupt on pin 1 */
    li   t1, 0x2
    sw   t1, GPIO_INT_EN(t0)

    /* enable PLIC source 2 (GPIO interrupt) */
    li   t0, PLIC_BASE
    li   t1, 0x4
    sw   t1, PLIC_ENABLE(t0)

    li   t0, 0x800
    csrw mie, t0                        /* MEIE: machine external interrupt enable */
    csrsi mstatus, 8                    /* mstatus.MIE = 1 */

    /* signal testbench: setup is complete, pin 0 is high, ready for edge */
    la   t0, setup_done
    li   t1, 1
    sw   t1, 0(t0)

wait_int:
    beqz s0, wait_int                   /* ISR sets s0 = 1 directly — no memory load */

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
    /* s0/s1/s2 intentionally NOT saved — ISR uses them as output registers */

    csrr t0, mcause
    bgez t0, trap_done                  /* bit 31 = 0 -> exception, not expected */

    /* claim interrupt from PLIC; t1 = source ID (expect 2 = GPIO) */
    li   t0, PLIC_BASE
    lw   t1, PLIC_CLAIM(t0)
    mv   s2, t1                         /* isr_claim_id -> s2 directly */

    /* read INT_STATE -> s1 directly, then W1C-clear */
    li   t0, GPIO_BASE
    lw   t2, GPIO_INT_STATE(t0)
    mv   s1, t2                         /* isr_int_state -> s1 directly */
    sw   t2, GPIO_INT_STATE(t0)         /* write 1s to clear the bits that fired */

    /* increment int_count directly in s0 */
    addi s0, s0, 1

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
