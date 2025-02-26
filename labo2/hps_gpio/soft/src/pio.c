#include <stdint.h>
#include <stdbool.h>
#include "utils.h"
#include "pio.h"

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
