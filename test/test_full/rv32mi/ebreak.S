# See LICENSE for license details.

#*****************************************************************************
# ebreak.S
#-----------------------------------------------------------------------------
#
# Test ebreak trap: verifies mcause==3 and mepc points at the ebreak inst.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

    # Point mtvec at our handler before triggering any trap
    la   t0, trap_handler
    csrw mtvec, t0

    li   TESTNUM, 1

do_ebreak:
    ebreak
    j    fail           # should never reach here

    TEST_PASSFAIL

    .align 2
    .global trap_handler
trap_handler:
    # Check mcause == 3 (breakpoint)
    csrr t0, mcause
    li   t1, 3
    bne  t0, t1, fail
    # Check mepc == address of ebreak instruction
    csrr t0, mepc
    la   t1, do_ebreak
    bne  t0, t1, fail
    j    pass

RVTEST_CODE_END

    .data
RVTEST_DATA_BEGIN

    TEST_DATA

RVTEST_DATA_END
