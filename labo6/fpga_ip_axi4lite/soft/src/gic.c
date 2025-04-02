#include "gic.h"
void gic_setup()
{
	// Setup prios
	GIC_REG(GIC_ICCPMR_REG) = 0xFFFF;
	// Activate cpu interface
	GIC_REG(GIC_ICCICR_REG) = 0x1;
	// Activate distributor
	GIC_REG(GIC_ICDDCR_REG) = 0x1;
}

void gic_enable_spi_irq(int irq_no)
{
	long int reg_offset, index, value, address;
	/* Configure the Interrupt Set-Enable Registers (ICDISERn).
	* reg_offset = (integer_div(N / 32) * 4
	* value = 1 << (N mod 32) */
	reg_offset = (irq_no >> 3) & 0xFFFFFFFC;
	index = irq_no & 0x1F;
	value = 0x1 << index;
	address = GIC_BASE_ADDR + GIC_ICDISER_BASE_REG + reg_offset;
	/* Now that we know the register address and value, set the appropriate bit */
	*(int *)address |= value;
	/* Configure the Interrupt Processor Targets Register (ICDIPTRn)
	* reg_offset = integer_div(N / 4) * 4
	* index = N mod 4 */
	reg_offset = (irq_no & 0xFFFFFFFC);
	index = irq_no & 0x3;
	address = GIC_BASE_ADDR + GIC_ICDIPTR_BASE_REG + reg_offset + index;
	/* Now that we know the register address and value, write to (only) the
	* appropriate byte */
	*(char *)address = 1;
}
uint16_t gic_get_irq_id(void)
{
	return GIC_REG(GIC_ICCIAR_REG) & 0x3FF;
}
void gic_ack_irq(uint16_t irq_id)
{
	GIC_REG(GIC_ICCEOIR_REG) = (irq_id & 0x3FF);
}
