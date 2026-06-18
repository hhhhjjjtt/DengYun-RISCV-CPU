# See LICENSE for license details.

#*****************************************************************************
# ecall.S
#-----------------------------------------------------------------------------
#
# Test ecall trap: verifies mcause==11, mepc points at ecall, and mret returns.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

    # Point mtvec at our handler
    la   t0, trap_handler
    csrw mtvec, t0

    li   TESTNUM, 1

do_ecall:
    ecall
    # mret should return here (mepc+4)
    # when we reach here, mret worked correctly -> pass
    j    pass

    j    fail           # should never reach here

    TEST_PASSFAIL

    .align 2
    .global trap_handler
trap_handler:
    # Check mcause == 11 (M-mode ecall)
    csrr t0, mcause
    li   t1, 11
    bne  t0, t1, fail
    # Check mepc == address of ecall instruction
    csrr t0, mepc
    la   t1, do_ecall
    bne  t0, t1, fail
    # Advance mepc by 4 so mret returns past the ecall
    addi t0, t0, 4
    csrw mepc, t0
    mret

RVTEST_CODE_END

    .data
RVTEST_DATA_BEGIN

    TEST_DATA

RVTEST_DATA_END
