# forw_link.S
#-----------------------------------------------------------------------------
# jal and jalr link values into every value consumer at 0..3 nops.
#
# The consumer is the first instruction at the jump target (plus nops).
# The link is PC+4 of the jump, which comes from a different write-back
# source than the ALU result, so it can be right in the register file and
# wrong on a forward path.
#
# Producers (hundreds digit of the case number):
#   1 jal    2 jalr
# Consumers (tens digit): 1 rs1, 2 rs2, 3 I-type rs1, 4 store data,
#   5 taken branch, 6 not-taken branch
# Ones digit: nops between the jump target and the consumer.

#include "riscv_test.h"
#include "test_macros.h"
#include "forw_macros.h"

#define P_JAL_SET   la x8, 9f
#define P_JAL_DO    jal x1, 8f; 9: j fail; 8:
#define P_JALR_SET  la x8, 9f; la x5, 8f
#define P_JALR_DO   jalr x1, 0(x5); 9: j fail; 8:

RVTEST_RV32U
RVTEST_CODE_BEGIN

  la x9, tscratch

  FWD_VALUE_ROW( 100, P_JAL )
  FWD_VALUE_ROW( 200, P_JALR )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tscratch: .word 0

RVTEST_DATA_END
