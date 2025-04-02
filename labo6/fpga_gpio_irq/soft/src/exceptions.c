/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : execptions.c
 * Author               : Sébastien Masle
 * Date                 : 16.02.2018
 *
 * Context              : SOCF class
 *
 *****************************************************************************************
 * Brief: defines exception vectors for the A9 processor
 *        provides code that sets the IRQ mode stack, and that dis/enables interrupts
 *        provides code that initializes the generic interrupt controller
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Engineer      Comments
 * 0.0    16.02.2018  SMS           Initial version.
 *
*****************************************************************************************/
#include <stdint.h>

#include "address_map_arm.h"
#include "defines.h"

#include "gic.h"
#include "pio.h"
// Define the IRQ exception handler
void __attribute__((interrupt)) __cs3_isr_irq(void)
{
	// Read CPU Interface registers to determine which peripheral has caused an interrupt
	uint16_t irq_id = gic_get_irq_id();
	// Handle the interrupt if it comes from the fpga
	if (irq_id == FPGA_IRQ0_LINE_NO) {
		pio_isr();
	}
	// Clear interrupt from the CPU Interface
	gic_ack_irq(irq_id);

	return;
}

// Define the remaining exception handlers
void __attribute__((interrupt)) __cs3_reset(void)
{
	while (1)
		;
}

void __attribute__((interrupt)) __cs3_isr_undef(void)
{
	while (1)
		;
}

void __attribute__((interrupt)) __cs3_isr_swi(void)
{
	while (1)
		;
}

void __attribute__((interrupt)) __cs3_isr_pabort(void)
{
	while (1)
		;
}

void __attribute__((interrupt)) __cs3_isr_dabort(void)
{
	while (1)
		;
}

void __attribute__((interrupt)) __cs3_isr_fiq(void)
{
	while (1)
		;
}
