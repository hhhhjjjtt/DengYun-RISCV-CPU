    .section .text
    .globl _start

// ------------------------------------------------------------
// RV32I Euler Integrator in Q16.16
// Solves dy/dt = a*y with Euler: y <- y * FACTOR, FACTOR=(1+h*a)
// Stores N results (32-bit Q16.16) to OUTBUF
// Uses software 32x32->64 multiply; NO hardware M, NO FPU
//
// Registers:
//   s0 = y (current value, Q16.16)
//   s1 = FACTOR (Q16.16)
//   s2 = N (int)
//   s3 = &OUTBUF
//   t1,t2 inputs to qmul; t5 return from qmul
// ------------------------------------------------------------

_start:
    // load constants (using 'la' pseudo for addresses)
    la      t0, FACTOR
    lw      s1, 0(t0)              // s1 = FACTOR (Q16.16)

    la      t0, Y0
    lw      s0, 0(t0)              // s0 = y0 (Q16.16)

    la      t0, NSTEPS
    lw      s2, 0(t0)              // s2 = N

    la      s3, OUTBUF             // s3 = &OUTBUF

loop:
    beq     s2, x0, done           // if N==0, finish

    // y = qmul(y, FACTOR)
    addi    t1, s0, 0              // t1 = y
    addi    t2, s1, 0              // t2 = FACTOR
    jal     ra, qmul               // t5 = (t1*t2)>>16
    addi    s0, t5, 0              // y <- result

    // store and advance
    sw      s0, 0(s3)
    addi    s3, s3, 4
    addi    s2, s2, -1
    j       loop

done:
    j       done                   // spin forever

// ------------------------------------------------------------
// qmul: (t1 * t2) >> 16  (signed Q16.16)
// IN:  t1 = a (Q16.16), t2 = b (Q16.16)
// OUT: t5 = (a*b)>>16 (Q16.16)
// Clobbers: t0,t3,t4,t6,t5
// Steps:
//   sign = sign(a) xor sign(b)
//   ua = abs(a); ub = abs(b)
//   acc = ua*ub via shift-add (unsigned 32x32 -> 64)
//   res = (acc >> 16) = (acc_lo >> 16) | (acc_hi << 16)
//   if sign<0, negate
// ------------------------------------------------------------
qmul:
    // sign
    srai    t0, t1, 31             // sign(a)
    srai    t6, t2, 31             // sign(b)
    xor     t0, t0, t6             // combined sign in t0

    // ua = abs(a) in t1
    bge     t1, x0, 1f
    sub     t1, x0, t1
1:
    // ub = abs(b) in t2
    bge     t2, x0, 2f
    sub     t2, x0, t2
2:
    // acc = 0 (hi=t4, lo=t3), counter = 32
    addi    t3, x0, 0
    addi    t4, x0, 0
    addi    t6, x0, 32

3:  // mul_loop
    andi    t5, t2, 1              // if (ub & 1) acc += ua
    beq     t5, x0, 4f
    add     t5, t3, t1             // tmp = acc_lo + ua
    sltu    t5, t5, t3             // t5 = carry
    add     t3, t3, t1             // acc_lo += ua
    add     t4, t4, t5             // acc_hi += carry
4:
    slli    t1, t1, 1              // ua <<= 1
    srli    t2, t2, 1              // ub >>= 1 (logical)
    addi    t6, t6, -1
    bne     t6, x0, 3b

    // res32 = (acc >> 16) = (acc_lo >> 16) | (acc_hi << 16)
    srli    t5, t3, 16
    slli    t6, t4, 16
    or      t5, t5, t6

    // sign fix
    beq     t0, x0, 5f
    sub     t5, x0, t5
5:
    jr      ra

// ------------------------------------------------------------
// Data (Q16.16)
// ------------------------------------------------------------
    .section .data
FACTOR:   .word 0x0000E666        // (1 + h*a) ≈ 0.9 (h=0.1, a=-1)
Y0:       .word 0x00010000        // 1.0
NSTEPS:   .word 10                // do 10 steps

    .section .bss
    .align 2
OUTBUF:   .space 40               // 10 * 4B results
