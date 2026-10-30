# forw_load.S
#-----------------------------------------------------------------------------
# Load producers into every value consumer at 0..3 nops.
#
# At 0 nops the consumer has to stall one cycle, then take the load from WB.
# The byte and halfword loads check that the forwarded value is the
# extended one, not the raw memory word.
#
# Producers (hundreds digit of the case number):
#   1 lw     2 lb     3 lbu    4 lh     5 lhu
# Consumers (tens digit): 1 rs1, 2 rs2, 3 I-type rs1, 4 store data,
#   5 taken branch, 6 not-taken branch
# Ones digit: nops between producer and consumer.

#include "riscv_test.h"
#include "test_macros.h"
#include "forw_macros.h"

#define P_LW_SET   la x5, tld; li x8, 0x9abc80f1
#define P_LW_DO    lw x1, 0(x5)
#define P_LB_SET   la x5, tld; li x8, 0xffffff80
#define P_LB_DO    lb x1, 1(x5)
#define P_LBU_SET  la x5, tld; li x8, 0x80
#define P_LBU_DO   lbu x1, 1(x5)
#define P_LH_SET   la x5, tld; li x8, 0xffff9abc
#define P_LH_DO    lh x1, 2(x5)
#define P_LHU_SET  la x5, tld; li x8, 0x9abc
#define P_LHU_DO   lhu x1, 2(x5)

RVTEST_RV32U
RVTEST_CODE_BEGIN

  la x9, tscratch

  FWD_VALUE_ROW( 100, P_LW )
  FWD_VALUE_ROW( 200, P_LB )
  FWD_VALUE_ROW( 300, P_LBU )
  FWD_VALUE_ROW( 400, P_LH )
  FWD_VALUE_ROW( 500, P_LHU )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tscratch: .word 0
tld:      .word 0x9abc80f1

RVTEST_DATA_END
