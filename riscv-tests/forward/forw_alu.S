# forw_alu.S
#-----------------------------------------------------------------------------
# ALU and U-type producers into every value consumer at 0..3 nops.
#
# Producers (hundreds digit of the case number):
#   1 add     2 sub (all ones, so every bit of the path is driven)
#   3 addi    4 lui    5 auipc
# Consumers (tens digit): 1 rs1, 2 rs2, 3 I-type rs1, 4 store data,
#   5 taken branch, 6 not-taken branch
# Ones digit: nops between producer and consumer.

#include "riscv_test.h"
#include "test_macros.h"
#include "forw_macros.h"

#define P_ADD_SET    li x5, 0x1000; li x6, 0x234; li x8, 0x1234
#define P_ADD_DO     add x1, x5, x6
#define P_SUB_SET    li x5, 0x10; li x6, 0x11; li x8, -1
#define P_SUB_DO     sub x1, x5, x6
#define P_ADDI_SET   li x5, 0x1200; li x8, 0x1234
#define P_ADDI_DO    addi x1, x5, 0x34
#define P_LUI_SET    li x8, 0x12345000
#define P_LUI_DO     lui x1, 0x12345
#define P_AUIPC_SET  la x8, 9f
#define P_AUIPC_DO   9: auipc x1, 0

RVTEST_RV32U
RVTEST_CODE_BEGIN

  la x9, tscratch

  FWD_VALUE_ROW( 100, P_ADD )
  FWD_VALUE_ROW( 200, P_SUB )
  FWD_VALUE_ROW( 300, P_ADDI )
  FWD_VALUE_ROW( 400, P_LUI )
  FWD_VALUE_ROW( 500, P_AUIPC )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tscratch: .word 0

RVTEST_DATA_END
