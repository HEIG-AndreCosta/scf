#include <stdint.h>

#ifndef AXI_LW_H
#define AXI_LW_H

#define AXI_LW_HPS_FPGA_BASE_ADD 0xFF200000

#define AXI_LW_REG(x)		 *(volatile uint32_t *)(AXI_LW_HPS_FPGA_BASE_ADD + x)

#endif
