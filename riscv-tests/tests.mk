# One program per RV32I instruction, except FENCE, ECALL, and EBREAK.
# Those three are the rest of the 40. FENCE is a nop on this pipeline.
# ECALL and EBREAK raise a trap; this core freezes instead of handling it.
INST_TESTS := \
	add addi sub \
	and andi or ori xor xori \
	sll slli srl srli sra srai \
	slt slti sltu sltiu \
	lui auipc \
	beq bne blt bge bltu bgeu \
	jal jalr \
	lb lbu lh lhu lw \
	sb sh sw

# Pipeline hazards. simple, ld_st, and st_ld are upstream rv32ui programs.
# The haz_* programs live in hazard/.
# fence_i is left out: it rewrites code through DMEM, and IMEM is a separate ROM.
HAZ_TESTS := \
	simple ld_st st_ld \
	haz_alu haz_load_use haz_control haz_mem

# Forwarding: every producer into every consumer at 0..3 nops.
# The forw_* programs live in forward/.
FORW_TESTS := \
	forw_alu forw_load forw_link forw_addr

TESTS := $(INST_TESTS) $(HAZ_TESTS) $(FORW_TESTS)
