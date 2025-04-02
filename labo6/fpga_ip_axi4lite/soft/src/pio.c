#include <stdint.h>
#include <stdbool.h>
#include "utils.h"
#include "pio.h"
#include "gic.h"

static void *cb_data;
static irq_cb irq_cb_fn;

void pio_switchs_init(void)
{
	SWITCH_PIO(4) &= ~SWITCH_REGISTER_MASK;
}
void pio_leds_init(void)
{
	LED_PIO(4) |= LED_REGISTER_MASK;
}
void pio_key_init(void)
{
	KEY_PIO(4) &= ~KEY_REGISTER_MASK;
}
void pio_seg7_init(void)
{
	HEX_PIO(4) |= HEX_FULL_MASK;
}
uint32_t pio_switchs_read(void)
{
	return (SWITCH_PIO(0) & SWITCH_REGISTER_MASK) >> SWITCH_SHIFT;
}

void pio_leds_write(uint32_t value)
{
	LED_PIO(0) = (value & LED_MASK) << LED_SHIFT;
}

void pio_leds_set(uint32_t maskleds)
{
	LED_PIO(0) |= ((maskleds & LED_MASK) << LED_SHIFT);
}

void pio_leds_clear(uint32_t maskleds)
{
	LED_PIO(0) &= ~((maskleds & LED_MASK) << LED_SHIFT);
}

void pio_leds_toggle(uint32_t maskleds)
{
	LED_PIO(0) ^= ((maskleds & LED_MASK) << LED_SHIFT);
}

bool pio_key_read(int key_number)
{
	return (((KEY_PIO(0) & KEY_REGISTER_MASK) >> KEY_SHIFT) &
		(1 << key_number)) == 0;
}

void pio_seg7_write(int seg7_number, uint32_t value)
{
	HEX_PIO(0) &= ~(HEX_MASK << (seg7_number * HEX_BITS));
	HEX_PIO(0) |= ((~value & HEX_MASK) << (seg7_number * HEX_BITS));
}

void pio_seg7_write_hex(int seg7_number, uint32_t value)
{
	pio_seg7_write(seg7_number, value_to_7_seg(value));
}
void pio_key_enable_irq(int key_number)
{
	KEY_PIO(0xc) |= (1 << key_number);
	KEY_PIO(0x8) |= (1 << key_number);
}

void pio_set_key_irq_cb(irq_cb cb, void *data)
{
	cb_data = data;
	irq_cb_fn = cb;
}


void pio_isr(void)
{
	uint32_t irq_status = KEY_PIO(0xc);

	if (irq_cb_fn) {
		for (uint8_t i = 0; i < NB_KEYS; ++i) {
			if (irq_status & (1 << i)) {
				irq_cb_fn(i, cb_data);
			}
		}
	}
	KEY_PIO(0xc) |= irq_status;
}
void pio_enable_irqs(void)
{
	gic_enable_spi_irq(FPGA_IRQ0_LINE_NO);
}
