
#include "axi_lw.h"

uint32_t axi_lw_read_constant(void)
{
	return AXI_LW_CONSTANT_REG;
}
void axi_lw_test_reg_write(uint32_t value)
{
	AXI_LW_TEST_REG = value;
}
uint32_t axi_lw_test_reg_read(void)
{
	return AXI_LW_TEST_REG;
}
