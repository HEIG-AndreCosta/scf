#include <stdint.h>
#ifndef GIC_H
#define GIC_H

#define GIC_BASE_ADDR	     0xFFFE0000

#define GIC_ICCICR_REG	     0xC100
#define GIC_ICCPMR_REG	     0xC104
#define GIC_ICCIAR_REG	     0xC10C
#define GIC_ICCEOIR_REG	     0xC110

#define GIC_ICDDCR_REG	     0xD000
#define GIC_ICDISER_BASE_REG 0xD100

#define GIC_ICDIPTR_BASE_REG 0xD800

#define SPI_IRQ_OFFSET	     32

#define GIC_ICDISER_REG(interrupt) \
	(GIC_ICDISER_BASE_REG + interrupt * sizeof(uint32_t))

#define GIC_ICDIPTR_REG(interrupt) \
	(GIC_ICDIPTR_BASE_REG + interrupt * sizeof(uint32_t))

#define GIC_REG(_x_)                 \
	*(volatile uint32_t          \
		  *)(GIC_BASE_ADDR + \
		     _x_) // _x_ is an offset with respect to the base address
void gic_setup(void);
void gic_enable_spi_irq(int irq_no);
uint16_t gic_get_irq_id(void);
void gic_ack_irq(uint16_t);
#endif
