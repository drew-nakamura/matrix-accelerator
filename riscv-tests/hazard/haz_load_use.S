# haz_load_use.S
#-----------------------------------------------------------------------------
# Load-use hazards on every kind of consumer.
#
# rv32ui only follows a load with addi. Here the load feeds rs2, both
# operands, a load address, a store address, store data, a branch, and a
# jalr target. Where the consumer can act on a stale value (branch, jalr),
# the register is preloaded so the stale value takes the wrong path.
#
# Any correct RV32I core passes. A failing case number points at the hazard.

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # Load feeding rs1, rs2, and both.
  TEST_CASE( 2, x13, 0x12, la x2, tdat0; lw x1, 0(x2); addi x13, x1, 1 )
  TEST_CASE( 3, x13, 0xef, \
    li x5, 0x100; la x2, tdat0; lw x1, 0(x2); sub x13, x5, x1 )
  TEST_CASE( 4, x13, 0x22, la x2, tdat0; lw x1, 0(x2); add x13, x1, x1 )

  # Two loads back to back. The second stalls the consumer; the first must
  # still arrive, now from WB.
  TEST_CASE( 5, x13, 0x2ef, \
    la x2, tdat0; lw x1, 0(x2); lw x5, 4(x2); sub x13, x5, x1 )

  # Stall while the other operand is only in WB. The stalled consumer has to
  # hold on to that value, because next cycle it is gone from WB.
  TEST_CASE( 6, x13, 0x51, \
    la x2, tdat0; li x5, 0x40; lw x1, 0(x2); add x13, x1, x5 )
  TEST_CASE( 7, x13, 0x2f, \
    la x2, tdat0; li x5, 0x40; lw x1, 0(x2); sub x13, x5, x1 )

  # Load result is the next load's address.
  TEST_CASE( 8, x13, 0x300, la x2, tptr; lw x1, 0(x2); lw x13, 0(x1) )
  TEST_CASE( 9, x13, 0x300, \
    la x2, tptr2; lw x1, 0(x2); lw x5, 0(x1); lw x13, 0(x5) )

  # Load result is a store address.
  TEST_CASE( 10, x13, 0x5a5, \
    la x6, tout; sw x0, 0(x6); li x5, 0x5a5; la x2, toutp; \
    lw x1, 0(x2); sw x5, 0(x1); lw x13, 0(x6) )

  # Load result is store data.
  TEST_CASE( 11, x13, 0x11, \
    la x6, tout; la x2, tdat0; lw x1, 0(x2); sw x1, 4(x6); lw x13, 4(x6) )

  # Load into a branch. x1 starts at a value that takes the other path.
  li  TESTNUM, 12
  la  x2, tdat0
  li  x5, 0x11
  li  x1, 0
  lw  x1, 0(x2)
  bne x1, x5, fail

  li  TESTNUM, 13
  la  x2, tdat0
  li  x5, 0x11
  li  x1, 0
  lw  x1, 0(x2)
  beq x1, x5, 1f
  j   fail
1:

  li  TESTNUM, 14
  la  x2, tdat0
  li  x5, 0x11
  li  x1, 0
  lw  x1, 0(x2)
  bne x5, x1, fail

  li  TESTNUM, 15
  la  x2, tdat0
  li  x5, 0x12
  li  x1, 0x12
  lw  x1, 0(x2)
  beq x1, x5, fail

  li  TESTNUM, 16
  la  x2, tdat0
  li  x5, 0x11
  li  x1, 0
  lw  x1, 0(x2)
  nop
  bne x1, x5, fail

  # Load into a jalr target. x1 starts as the address of fail.
  li   TESTNUM, 17
  la   x1, fail
  la   x2, tjmp17
  lw   x1, 0(x2)
  jalr x0, 0(x1)
  j    fail
haz_tgt17:

  li   TESTNUM, 18
  la   x1, fail
  la   x2, tjmp18
  lw   x1, 0(x2)
  nop
  jalr x0, 0(x1)
  j    fail
haz_tgt18:

  # Load into x0. The stall is harmless; the value must not be forwarded.
  TEST_CASE( 19, x13, 7, li x1, 7; la x2, tdat0; lw x0, 0(x2); add x13, x1, x0 )
  TEST_CASE( 20, x13, 7, li x1, 7; la x2, tdat0; lw x0, 0(x2); add x13, x0, x1 )

  # After the stall, the next two instructions still depend on the load.
  TEST_CASE( 21, x13, 0x13, \
    la x2, tdat0; lw x1, 0(x2); addi x5, x1, 1; addi x13, x5, 1 )
  TEST_CASE( 22, x13, 0x33, \
    la x2, tdat0; lw x1, 0(x2); add x5, x1, x1; add x13, x5, x1 )

  # The instruction behind a stalled consumer keeps its own PC.
  TEST_CASE( 23, x13, 0, \
    la x2, tdat0; lw x1, 0(x2); add x6, x1, x1; 1: auipc x5, 0; \
    la x6, 1b; sub x13, x5, x6 )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tdat0:  .word 0x00000011
tdat1:  .word 0x00000300
tptr:   .word tdat1
tptr2:  .word tptr
toutp:  .word tout
tjmp17: .word haz_tgt17
tjmp18: .word haz_tgt18
tout:   .word 0
        .word 0

RVTEST_DATA_END
