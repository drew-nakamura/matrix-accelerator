# forw_macros.h
#-----------------------------------------------------------------------------
# Producer x consumer x distance sweep for the forwarding tests.
#
# A producer is a pair of macros: P_<name>_SET puts the value x1 should end
# up with in x8, and P_<name>_DO is the instruction that writes x1.
# A consumer C_<name>_DO reads x1 and leaves x8 in x13 when x1 was right.
#
# Before every producer x1 is loaded with STALE, so a consumer that reads
# the register file instead of the forward path sees the wrong value.
#
# Case number = 100 * producer + 10 * consumer + nops between them.
#   nops 0: the producer is one stage ahead (MEM, or a load-use stall)
#   nops 1: the producer is in WB
#   nops 2: the producer wrote the register file as the consumer read it
#   nops 3: plain register file read
#
# x9 holds a scratch word address for the whole program. Do not write it.

#define STALE 0x5a5a5a5a

#define FWD_CASE( n, P, d, C ) \
    li  TESTNUM, n; \
    sw  x0, 0(x9); \
    P ## _SET; \
    li  x1, STALE; \
    P ## _DO; \
    TEST_INSERT_NOPS_ ## d; \
    C ## _DO; \
    bne x13, x8, fail;

#define FWD_SWEEP( n, P, C ) \
    FWD_CASE( n+0, P, 0, C ) \
    FWD_CASE( n+1, P, 1, C ) \
    FWD_CASE( n+2, P, 2, C ) \
    FWD_CASE( n+3, P, 3, C )

# Value consumers, numbered 1..6 in FWD_VALUE_ROW.
#define C_RS1_DO  add  x13, x1, x0
#define C_RS2_DO  add  x13, x0, x1
#define C_IMM_DO  addi x13, x1, 0
#define C_STD_DO  sw   x1, 0(x9); lw x13, 0(x9)
#define C_BR1_DO  beq  x1, x8, 1f; j fail; 1: mv x13, x8
#define C_BR2_DO  bne  x8, x1, fail; mv x13, x8

#define FWD_VALUE_ROW( b, P ) \
    FWD_SWEEP( b+10, P, C_RS1 ) \
    FWD_SWEEP( b+20, P, C_RS2 ) \
    FWD_SWEEP( b+30, P, C_IMM ) \
    FWD_SWEEP( b+40, P, C_STD ) \
    FWD_SWEEP( b+50, P, C_BR1 ) \
    FWD_SWEEP( b+60, P, C_BR2 )

# jalr target consumer. x1 starts as the address of fail, and the landing
# label 7 sits right after the jump's shadow.
#define JR_CASE( n, P, d ) \
    li  TESTNUM, n; \
    P ## _SET; \
    la  x1, fail; \
    P ## _DO; \
    TEST_INSERT_NOPS_ ## d; \
    jalr x0, 0(x1); \
    j   fail; \
7:

#define JR_SWEEP( n, P ) \
    JR_CASE( n+0, P, 0 ) \
    JR_CASE( n+1, P, 1 ) \
    JR_CASE( n+2, P, 2 ) \
    JR_CASE( n+3, P, 3 )
