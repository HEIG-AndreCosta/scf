#include <stdint.h>
#include <stdbool.h>
#include "utils.h"
#include "axi_io.h"
#include "gic.h"

uint32_t axi_io_switchs_read(void)
{
	return (AXI_SWITCH_READ & SWITCH_REGISTER_MASK) >> SWITCH_SHIFT;
}

void axi_io_leds_write(uint32_t value)
{
	AXI_LED_WRITE = value;
}

void axi_io_leds_set(uint32_t maskleds)
{
	AXI_LED_SET = maskleds;
}

void axi_io_leds_clear(uint32_t maskleds)
{
	AXI_LED_CLEAR = maskleds;
}

void axi_io_leds_toggle(uint32_t maskleds)
{
	AXI_LED_WRITE ^= ((maskleds & LED_MASK) << LED_SHIFT);
}

bool axi_io_key_read(int key_number)
{
	return (((AXI_KEY_READ & KEY_REGISTER_MASK) >> KEY_SHIFT) &
		(1 << key_number)) == 0;
}

bool axi_io_key_rising_edge(int key_number)
{
	return (((AXI_KEY_EDGE_CAPTURE & KEY_REGISTER_MASK) >> KEY_SHIFT) &
		(1 << key_number));
}

void axi_io_ack_key_rising_edge(int key_number)
{
	AXI_KEY_EDGE_CAPTURE = (1 << key_number);
}

void axi_io_seg7_write(int seg7_number, uint32_t value)
{
	if (seg7_number < 4) {
		AXI_HEX_3_0_WRITE &= ~(HEX_MASK << (seg7_number * HEX_BITS));
		AXI_HEX_3_0_WRITE |=
			((~value & HEX_MASK) << (seg7_number * HEX_BITS));

	} else if (seg7_number < 6) {
		seg7_number -= 4;
		AXI_HEX_5_4_WRITE &= ~(HEX_MASK << (seg7_number * HEX_BITS));
		AXI_HEX_5_4_WRITE |=
			((~value & HEX_MASK) << (seg7_number * HEX_BITS));
	}
}

void axi_io_seg7_write_hex(int seg7_number, uint32_t value)
{
	axi_io_seg7_write(seg7_number, value_to_7_seg(value));
}
