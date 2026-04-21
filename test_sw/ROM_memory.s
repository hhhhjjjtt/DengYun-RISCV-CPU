    .text
    .globl _start

_start:
    jal x1, main



load_register_values:
    add  x31, x1, x0       # save return address in x31

    addi x1,  x0, 1
    add  x2,  x1, x1
    ori  x3,  x2, 1
    addi x4,  x3, 1
    add  x6,  x4, x2
    addi x5,  x6, -1
    ori  x7,  x4, 3
    addi x10, x7, 3

    sub  x8,  x0, x2
    add  x8,  x10, x8
    addi x9,  x10, -1

    addi x27, x7, 20
    add  x15, x9, x6
    and  x11, x15, x27

    sub  x16, x0, x1       # -1
    sub  x16, x16, x1      # -2
    srl  x17, x16, x1      # 0x7fffffff
    and  x18, x16, x17     # 0x7ffffffe
    xor  x19, x18, x16     # 0x80000000
    slli x20, x15, 28      # 0xf0000000
    sra  x21, x17, x8      # 0x007fffff
    srai x23, x19, 8       # 0xff800000
    or   x22, x21, x23     # 0xffffffff

    andi x12, x17, 12
    srli x13, x17, 29
    sll  x13, x13, x2
    add  x13, x13, x1

    sra  x14, x18, x27
    sub  x14, x14, x1

    slti x16, x15, 16
    add  x16, x16, x15

    sltiu x17, x16, 16
    add  x17, x16, x1

    slt  x18, x18, x19
    add  x18, x17, x1

    sltu x19, x19, x20
    add  x19, x19, x18

    slti x20, x21, 1
    add  x20, x19, x1

    addi x22, x22, 1       # 0xffffffff + 1 = 0
    sltiu x21, x22, 1
    add  x21, x21, x20

    slt  x22, x22, x1
    add  x22, x22, x21

    sltu x23, x23, x0
    add  x23, x22, x1

    sll  x24, x6, x2
    addi x25, x27, -2
    add  x26, x24, x2
    slli x28, x14, 1

    add  x1,  x31, x0      # restore return address
    ori  x31, x28, 3
    addi x29, x31, -2
    srli x30, x31, 1
    slli x30, x30, 1

    jalr x0, 0(x1)



test_load_store:
    addi x31, x0, 2
    slli x31, x31, 12      # x31 = 0x2000

    addi x6,  x0, 6        # ensure x6 really contains 6

    sb   x1,   4(x31)      # RAM[1]
    sh   x2,   8(x31)      # RAM[2]
    sw   x3,  12(x31)      # RAM[3]
    sb   x4,  16(x31)      # RAM[4]
    sh   x5,  20(x31)      # RAM[5]
    sw   x6,  24(x31)      # RAM[6]
    sb   x7,  28(x31)      # RAM[7]
    sh   x8,  32(x31)      # RAM[8]
    sw   x9,  36(x31)      # RAM[9]
    sb   x10, 40(x31)      # RAM[10]
    sh   x11, 44(x31)      # RAM[11]
    sw   x12, 48(x31)      # RAM[12]
    sb   x13, 52(x31)      # RAM[13]
    sh   x14, 56(x31)      # RAM[14]
    sw   x15, 60(x31)      # RAM[15]
    sb   x16, 64(x31)      # RAM[16]
    sh   x17, 68(x31)      # RAM[17]
    sw   x18, 72(x31)      # RAM[18]
    sb   x19, 76(x31)      # RAM[19]
    sh   x20, 80(x31)      # RAM[20]
    sw   x21, 84(x31)      # RAM[21]
    sb   x22, 88(x31)      # RAM[22]
    sh   x23, 92(x31)      # RAM[23]
    sw   x24, 96(x31)      # RAM[24]
    sb   x25,100(x31)      # RAM[25]
    sh   x26,104(x31)      # RAM[26]
    sw   x27,108(x31)      # RAM[27]
    sb   x28,112(x31)      # RAM[28]
    sh   x29,116(x31)      # RAM[29]
    sw   x30,120(x31)      # RAM[30]
    sw   x31,124(x31)      # RAM[31]

    addi x2,  x0, 0
    addi x3,  x0, 0
    addi x4,  x0, 0
    addi x5,  x0, 0
    addi x6,  x0, 0
    addi x7,  x0, 0
    addi x8,  x0, 0
    addi x9,  x0, 0
    addi x10, x0, 0
    addi x11, x0, 0
    addi x12, x0, 0
    addi x13, x0, 0
    addi x14, x0, 0
    addi x15, x0, 0
    addi x16, x0, 0
    addi x17, x0, 0
    addi x18, x0, 0
    addi x19, x0, 0
    addi x20, x0, 0
    addi x21, x0, 0
    addi x22, x0, 0
    addi x23, x0, 0
    addi x24, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x27, x0, 0
    addi x28, x0, 0
    addi x29, x0, 0
    addi x30, x0, 0

    jalr x0, 0(x1)



test_branch:
    addi x31, x0, 2
    slli x31, x31, 12      # x31 = 0x2000

    lbu  x2,   9(x31)      # byte 1 of RAM[2] = 0
    beq  x2,  x0, X2
    jal  x0, failed

X2:
    lb   x2,   8(x31)      # byte 0 of RAM[2] = 2
    beq  x2,  x0, X2       # not taken

    lh   x3,  14(x31)      # halfword 1 of RAM[3] = 0
    bne  x3,  x1, X3
    jal  x0, failed

X3:
    lh   x3,  12(x31)      # halfword 0 of RAM[3] = 3
    bne  x3,  x3, X3       # not taken

    lbu  x4,  16(x31)      # RAM[4] byte 0 = 4

X4:
    blt  x4,  x5, X4       # x5 still 0, not taken
    lhu  x5,  20(x31)      # RAM[5] halfword 0 = 5
    blt  x4,  x5, X6
    jal  x0, failed

X6:
    lw   x6,  24(x31)      # RAM[6] = 6

X7:
    bltu x6,  x7, X7       # x7 still 0, not taken
    lb   x7,  28(x31)      # RAM[7] byte 0 = 7
    bltu x6,  x7, X8
    jal  x0, failed

X8:
    lh   x8,  32(x31)      # RAM[8] halfword 0 = 8
    bge  x8,  x9, X9       # x9 still 0, taken
    jal  x0, failed

X9:
    lbu  x9,  36(x31)      # RAM[9] byte 0 = 9
    bge  x8,  x9, X9       # not taken

    lhu  x10, 40(x31)      # RAM[10] halfword 0 = 10
    bgeu x10, x11, X11     # x11 still 0, taken
    jal  x0, failed

X11:
    lw   x11, 44(x31)      # RAM[11] = 11
    bgeu x10, x11, X11     # not taken

    lb   x12, 48(x31)      # RAM[12] byte 0 = 12
    bge  x12, x11, X27     # 12 >= 11, taken
    jal  x0, failed

X13:
    lh   x13, 52(x31)      # RAM[13] halfword 0 = 13
    lbu  x14, 56(x31)      # RAM[14] byte 0 = 14
    beq  x13, x14, X13     # not taken

    lhu  x15, 60(x31)      # RAM[15] halfword 0 = 15
    lw   x16, 64(x31)      # RAM[16] = 16
    bne  x15, x16, X25     # taken

X17:
    lb   x17, 68(x31)      # RAM[17] byte 0 = 17
    lh   x18, 72(x31)      # RAM[18] halfword 0 = 18
    blt  x18, x17, X17     # not taken

    lbu  x19, 76(x31)      # RAM[19] byte 0 = 19
    lhu  x20, 80(x31)      # RAM[20] halfword 0 = 20
    bltu x19, x20, X23     # taken

X21:
    lw   x21, 84(x31)      # RAM[21] = 21
    lb   x22, 88(x31)      # RAM[22] byte 0 = 22
    bne  x21, x22, X31     # taken

X23:
    lh   x23, 92(x31)      # RAM[23] halfword 0 = 23
    lbu  x24, 96(x31)      # RAM[24] byte 0 = 24
    bne  x23, x24, X21     # taken

X25:
    lhu  x25,100(x31)      # RAM[25] halfword 0 = 25
    lw   x26,104(x31)      # RAM[26] = 26
    bgeu x26, x25, X17     # taken

X27:
    lb   x27,108(x31)      # RAM[27] byte 0 = 27
    lhu  x28,112(x31)      # RAM[28] halfword 0 = 28
    bgeu x28, x27, X13     # taken

X31:
    lbu  x29,116(x31)      # RAM[29] byte 0 = 29
    beq  x29, x0, failed   # not taken
    jal  x0, almost

failed:
    beq  x0,  x0, failed   # infinite loop on failure

almost:
    jal  x0, done

done:
    lw   x30,120(x31)      # RAM[30] = 30
    jalr x0, 0(x1)

main:
    jal x1, load_register_values
    jal x1, test_load_store
    jal x1, test_branch

end:
    beq x0, x0, end