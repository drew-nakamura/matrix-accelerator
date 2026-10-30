# haz_alu.S
#-----------------------------------------------------------------------------
# ALU-to-ALU data hazards that rv32ui does not reach.
#
# rv32ui already sweeps 0..2 nops between one producer and one consumer.
# These cases put two producers of the same register in flight, feed both
# operands from different stages at once, and write x0 so that a nonzero
# value sits in the pipe under rd = 0.
#
# Any correct RV32I core passes. A failing case number points at the hazard.

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # Newest producer wins. With x1=1 in WB and x1=2 in MEM, EX must see 2.
  TEST_CASE( 2, x13, 2, li x1, 1; li x1, 2; add x13, x1, x0 )
  TEST_CASE( 3, x13, 2, li x1, 1; li x1, 2; add x13, x0, x1 )

  # Newest producer wins after one bubble: x1=1 retired, x1=2 in WB.
  TEST_CASE( 4, x13, 2, li x1, 1; li x1, 2; nop; add x13, x1, x0 )

  # rs1 and rs2 forwarded from different stages in the same cycle.
  # sub is not commutative, so a swapped forward path gives the wrong sign.
  TEST_CASE( 5, x13, 0x10, li x1, 0x10; li x2, 0x20; sub x13, x2, x1 )
  TEST_CASE( 6, x13, 0x10, li x2, 0x20; li x1, 0x10; sub x13, x2, x1 )

  # Each instruction consumes the one before it.
  TEST_CASE( 7, x13, 32, \
    li x1, 1; add x1, x1, x1; add x1, x1, x1; add x1, x1, x1; \
    add x1, x1, x1; add x1, x1, x1; mv x13, x1 )

  # Writes to x0 compute a nonzero ALU result with RF_WE set.
  # Forwarding that value would make the sum 19 instead of 7.
  TEST_CASE(  8, x13, 7, li x1, 7; addi x0, x1, 5; add x13, x0, x1 )
  TEST_CASE(  9, x13, 7, li x1, 7; addi x0, x1, 5; add x13, x1, x0 )
  TEST_CASE( 10, x13, 7, li x1, 7; addi x0, x1, 5; nop; add x13, x0, x1 )
  TEST_CASE( 11, x13, 7, li x1, 7; addi x0, x1, 5; nop; add x13, x1, x0 )
  TEST_CASE( 12, x13, 7, li x1, 7; lui x0, 0x12345; add x13, x1, x0 )

  # U-type producers forwarded from MEM.
  TEST_CASE( 13, x13, 0x12345678, lui x1, 0x12345; addi x13, x1, 0x678 )
  TEST_CASE( 14, x13, 0, la x2, 1f; 1: auipc x1, 0; sub x13, x1, x2 )

  # Branch operands from MEM and WB at once. The stale register values say
  # "not equal", so a missing forward falls through to fail.
  li  TESTNUM, 15
  li  x1, 0
  li  x2, 1
  nop
  nop
  nop
  li  x1, 5
  li  x2, 5
  bne x1, x2, fail

  # Store data from MEM, store address from WB.
  TEST_CASE( 16, x13, 0x5a, \
    la x6, tout; li x5, 0x5a; sw x5, 0(x6); lw x13, 0(x6) )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tout: .word 0

RVTEST_DATA_END
