# haz_mem.S
#-----------------------------------------------------------------------------
# Memory ordering with no gaps between accesses.
#
# st_ld and ld_st cover one store and one load of the same size. These mix
# sizes on one word, so each byte lane has to land before the next access
# reads it.
#
# Any correct RV32I core passes. A failing case number points at the hazard.

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  # Word, then byte, then halfword into the same word, read back at once.
  TEST_CASE( 2, x13, 0xbeefaa44, \
    la x6, tout; li x5, 0x11223344; li x8, 0xaa; li x9, 0xbeef; \
    sw x5, 0(x6); sb x8, 1(x6); sh x9, 2(x6); lw x13, 0(x6) )

  # Byte reads right after a word write.
  TEST_CASE( 3, x13, 0xffffffbe, \
    la x6, tout; li x5, 0xbe00aa00; sw x5, 4(x6); lb x13, 7(x6) )
  TEST_CASE( 4, x13, 0xaa, \
    la x6, tout; li x5, 0xbe00aa00; sw x5, 4(x6); lbu x13, 5(x6) )

  # Two stores to neighboring words. The load must see the first one.
  TEST_CASE( 5, x13, 0x1234, \
    la x6, tout; li x5, 0x1234; li x8, 0x5678; \
    sw x5, 0(x6); sw x8, 4(x6); lw x13, 0(x6) )

  # Load, store, load on one address.
  TEST_CASE( 6, x13, 0x77, \
    la x6, tout; li x5, 0x77; lw x1, 0(x6); sw x5, 0(x6); lw x13, 0(x6) )

  # The first load must still read the old value.
  TEST_CASE( 7, x13, 0x99, \
    la x6, tout; li x5, 0x99; li x8, 0x42; sw x5, 0(x6); \
    lw x13, 0(x6); sw x8, 0(x6) )

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

tout: .word 0
      .word 0

RVTEST_DATA_END
