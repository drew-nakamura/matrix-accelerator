# forw_addr.S
#-----------------------------------------------------------------------------
# Forwarded values used as addresses: load base, store base, jalr target.
#
# A wrong base here does not just give a wrong number; it reads, writes, or
# jumps somewhere else. tself holds its own address, so a load through x1
# returns x1 only when x1 pointed at tself.
#
# Producers 1..3 into address consumers (tens digit 1 load base,
# 2 store base):
#   1 addi    2 add    3 lw
# Producers 4..6 into a jalr target (tens digit 1):
#   4 addi    5 lw     6 jal link
# Ones digit: nops between producer and consumer.

#include "riscv_test.h"
#include "test_macros.h"
#include "forw_macros.h"

#define P_AADDI_SET  la x5, tself; la x8, tself
#define P_AADDI_DO   addi x1, x5, 0
#define P_AADD_SET   la x5, tself; la x8, tself
#define P_AADD_DO    add x1, x5, x0
#define P_ALW_SET    la x5, tselfp; la x8, tself
#define P_ALW_DO     lw x1, 0(x5)

#define C_LDA_DO     lw x13, 0(x1)
#define C_STA_DO     sw x8, 4(x1); lw x13, 4(x8)

#define FWD_ADDR_ROW( b, P ) \
    FWD_SWEEP( b+10, P, C_LDA ) \
    FWD_SWEEP( b+20, P, C_STA )

#define P_JADDI_SET  la x5, 7f
#define P_JADDI_DO   addi x1, x5, 0
#define P_JLW_SET    la x5, 7f; sw x5, 0(x9)
#define P_JLW_DO     lw x1, 0(x9)
#define P_JLINK_SET
#define P_JLINK_DO   jal x1, 8f; j 7f; 8:

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # x9 is tself+4, the word C_STA writes, so FWD_CASE clears it every case.
  la x9, tslot

  FWD_ADDR_ROW( 100, P_AADDI )
  FWD_ADDR_ROW( 200, P_AADD )
  FWD_ADDR_ROW( 300, P_ALW )

  JR_SWEEP( 410, P_JADDI )
  JR_SWEEP( 510, P_JLW )
  JR_SWEEP( 610, P_JLINK )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tself:  .word tself
tslot:  .word 0
tselfp: .word tself

RVTEST_DATA_END
