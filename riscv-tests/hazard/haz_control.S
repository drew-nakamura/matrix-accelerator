# haz_control.S
#-----------------------------------------------------------------------------
# Control hazards: wrong-path squash, back-to-back transfers, and link
# registers used right at the jump target.
#
# The shadow of a taken branch or jump holds instructions that write a
# register, write memory, or jump to fail. None of them may take effect.
#
# Any correct RV32I core passes. A failing case number points at the hazard.

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # Taken branch, jal, and jalr: shadow must not write a register.
  TEST_CASE( 2, x13, 0, \
    li x13, 0; beq x0, x0, 1f; li x13, 1; li x13, 2; li x13, 3; 1: )
  TEST_CASE( 3, x13, 0, \
    li x13, 0; jal x0, 1f; li x13, 1; li x13, 2; li x13, 3; 1: )
  TEST_CASE( 4, x13, 0, \
    la x6, 1f; li x13, 0; jalr x0, 0(x6); li x13, 1; li x13, 2; li x13, 3; 1: )

  # Same three, but the shadow is stores.
  TEST_CASE( 5, x13, 0, \
    la x6, tout; sw x0, 0(x6); li x5, 0xbad; beq x0, x0, 1f; \
    sw x5, 0(x6); sw x5, 0(x6); 1: lw x13, 0(x6) )
  TEST_CASE( 6, x13, 0, \
    la x6, tout; sw x0, 0(x6); li x5, 0xbad; jal x0, 1f; \
    sw x5, 0(x6); sw x5, 0(x6); 1: lw x13, 0(x6) )
  TEST_CASE( 7, x13, 0, \
    la x6, tout; sw x0, 0(x6); li x5, 0xbad; la x8, 1f; jalr x0, 0(x8); \
    sw x5, 0(x6); sw x5, 0(x6); 1: lw x13, 0(x6) )

  # Not-taken branch: the next instructions run, in order.
  TEST_CASE( 8, x13, 10, \
    li x1, 1; li x13, 0; bne x1, x1, fail; addi x13, x13, 5; addi x13, x13, 5 )

  # A branch or jal in the shadow must be squashed, not resolved.
  li  TESTNUM, 9
  beq x0, x0, 1f
  beq x0, x0, fail
  jal x0, fail
1:

  # The target of a transfer is itself a transfer.
  li  TESTNUM, 10
  beq x0, x0, 1f
  j   fail
1:
  beq x0, x0, 2f
  j   fail
2:

  li  TESTNUM, 11
  jal x0, 1f
  j   fail
1:
  jal x0, 2f
  j   fail
2:

  # Not-taken branch followed directly by a taken one.
  li  TESTNUM, 12
  li  x1, 1
  beq x1, x0, fail
  bne x1, x0, 1f
  j   fail
1:

  # Link register read by the first instruction at the target.
  TEST_CASE( 13, x13, 0, \
    la x5, 1f; jal x1, 2f; 1: j fail; 2: sub x13, x1, x5 )
  TEST_CASE( 14, x13, 0, \
    la x1, 2f; la x5, 1f; jalr x1, 0(x1); 1: j fail; 2: sub x13, x1, x5 )

  # Return straight from the target: jal writes ra, the target jalrs on it.
  TEST_CASE( 15, x13, 0x11, \
    li x13, 0; jal x1, 3f; addi x13, x13, 0x10; j 4f; \
    3: jalr x0, 0(x1); 4: addi x13, x13, 1 )

  # PC of a jump target must be the target, not the old fall-through.
  TEST_CASE( 16, x13, 0, \
    jal x0, 1f; nop; nop; 1: auipc x5, 0; la x6, 1b; sub x13, x5, x6 )

  # Backward loop. Each bnez reads a counter written one instruction earlier.
  TEST_CASE( 17, x13, 55, \
    li x1, 0; li x2, 10; 1: add x1, x1, x2; addi x2, x2, -1; bnez x2, 1b; \
    mv x13, x1 )

  # Loop with a load-use inside it.
  TEST_CASE( 18, x13, 0x1111, \
    la x2, tarr; li x5, 4; li x1, 0; \
    1: lw x6, 0(x2); add x1, x1, x6; addi x2, x2, 4; addi x5, x5, -1; \
    bnez x5, 1b; mv x13, x1 )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tout: .word 0
tarr: .word 0x0001
      .word 0x0010
      .word 0x0100
      .word 0x1000

RVTEST_DATA_END
