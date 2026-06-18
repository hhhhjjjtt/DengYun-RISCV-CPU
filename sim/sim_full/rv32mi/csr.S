# See LICENSE for license details.

#*****************************************************************************
# csr.S
#-----------------------------------------------------------------------------
#
# Test csr instruction
#

#include "riscv_test.h"
#include "test_macros.h"

#define __MACHINE_MODE

RVTEST_RV32U
RVTEST_CODE_BEGIN

  TEST_CASE(20, a0, 0,      csrw mscratch, zero; csrr a0, mscratch)
  TEST_CASE(21, a0, 0,      csrrwi a0, mscratch, 0; csrrwi a0, mscratch, 0xF)
  TEST_CASE(22, a0, 0x1f,   csrrsi x0, mscratch, 0x10; csrr a0, mscratch)
  csrwi mscratch, 3
  TEST_CASE( 2, a0, 3,      csrr a0, mscratch)
  TEST_CASE( 3, a1, 3,      csrrci a1, mscratch, 1)
  TEST_CASE( 4, a2, 2,      csrrsi a2, mscratch, 4)
  TEST_CASE( 5, a3, 6,      csrrwi a3, mscratch, 2)
  TEST_CASE( 6, a1, 2,      li a0, 0xbad1dea; csrrw a1, mscratch, a0)
  TEST_CASE( 7, a1, 0xbad1dea, li a0, 0x0001dea; csrrc a1, mscratch, a0)
  TEST_CASE( 8, a1, 0xbad0000, li a0, 0x000beef; csrrs a1, mscratch, a0)
  TEST_CASE( 9, a0, 0xbadbeef, li a0, 0xbad1dea; csrrw a0, mscratch, a0)
  TEST_CASE(10, a0, 0xbad1dea, li a0, 0x0001dea; csrrc a0, mscratch, a0)
  TEST_CASE(11, a0, 0xbad0000, li a0, 0x000beef; csrrs a0, mscratch, a0)
  TEST_CASE(12, a0, 0xbadbeef, csrr a0, mscratch)

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN
RVTEST_DATA_END
