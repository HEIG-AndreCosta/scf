#include <stdint.h>

#ifndef AXI_LW_H
#define AXI_LW_H

#define AXI_LW_HPS_FPGA_BASE_ADD 0xFF200000
#define AXI_LW_USER_CONSTANT	 0xBADB100D

#define AXI_LW_REG(x)		 *(volatile uint32_t *)(AXI_LW_HPS_FPGA_BASE_ADD + x)

#define AXI_LW_CONSTANT_REG	 AXI_LW_REG(0x00)
#define AXI_LW_TEST_REG		 AXI_LW_REG(0x04)

uint32_t axi_lw_read_constant(void);
void axi_lw_test_reg_write(uint32_t value);
uint32_t axi_lw_test_reg_read(void);

#endif
