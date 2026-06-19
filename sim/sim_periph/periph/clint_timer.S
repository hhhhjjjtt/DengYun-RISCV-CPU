# clint_timer.S — CLINT timer interrupt test
#
# Flow:
#   1. Setup: mtvec, arm mtimecmp = mtime + TICK_CYCLES, enable MTIE + MIE
#   2. Spin until mscratch (interrupt counter) reaches NUM_TICKS
#   3. ISR: verify mcause=7, increment mscratch, re-arm mtimecmp += TICK_CYCLES
#   4. Copy final count to s0, write pass sentinel 0x00c0ffee to a0
#
# Counter is kept in mscratch to avoid D-Cache stale-read between
# ISR writes and main-loop reads of a shared memory variable.
#
# TICK_CYCLES and NUM_TICKS must match localparams in tb_clint_timer.sv

#define CLINT_BASE       0xC000
#define MTIME_OFFSET     0x0
#define MTIMECMP_OFFSET  0x4

#define TICK_CYCLES      200
#define NUM_TICKS        3

    .section .text
    .global _start

_start:
    li   sp, 0x4000

    la   t0, trap_handler
    csrw mtvec, t0

    csrw mscratch, zero         # interrupt counter = 0

    # arm: mtimecmp = mtime + TICK_CYCLES
    li   t0, CLINT_BASE
    lw   t1, MTIME_OFFSET(t0)
    addi t1, t1, TICK_CYCLES
    sw   t1, MTIMECMP_OFFSET(t0)

    li   t0, 0x80               # mie.MTIE = bit 7
    csrw mie, t0
    csrsi mstatus, 8            # mstatus.MIE = 1

wait_loop:
    csrr t0, mscratch           # read counter — no D-Cache
    li   t1, NUM_TICKS
    blt  t0, t1, wait_loop

    csrr s0, mscratch           # expose final count in s0 for testbench
    li   a0, 0x00c0ffee
    j    halt
halt:
    j    halt

    .balign 4
trap_handler:
    addi sp, sp, -16
    sw   ra,  0(sp)
    sw   t0,  4(sp)
    sw   t1,  8(sp)
    sw   t2, 12(sp)

    csrr t0, mcause
    bgez t0, trap_done          # bit31=0 → exception, not interrupt

    andi t0, t0, 0x1f
    li   t1, 7                  # machine timer interrupt code
    bne  t0, t1, trap_done

    # increment counter in mscratch
    csrr t2, mscratch
    addi t2, t2, 1
    csrw mscratch, t2

    # re-arm: read mtimecmp, add TICK_CYCLES, write back (drift-free)
    li   t0, CLINT_BASE
    lw   t1, MTIMECMP_OFFSET(t0)
    addi t1, t1, TICK_CYCLES
    sw   t1, MTIMECMP_OFFSET(t0)

trap_done:
    lw   ra,  0(sp)
    lw   t0,  4(sp)
    lw   t1,  8(sp)
    lw   t2, 12(sp)
    addi sp, sp, 16
    mret
