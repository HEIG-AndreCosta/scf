#include <inttypes.h>
#include "gic.h"
#include "axi_io.h"
#include <stdint.h>
#include <stdio.h>

int __auto_semihosting;

#define MAX_HEX_VALUE 0xffff
static uint16_t current_value = 0;

static void update_hex(void)
{
	for (size_t i = 0; i < 4; ++i) {
		const uint16_t mask = 0xf << (i * 4);
		const uint16_t shift = 4 * i;
		axi_io_seg7_write_hex(i, ((current_value & mask) >> shift));
	}
}

static void set_error(void)
{
	axi_io_leds_set(0x3ff);
}

static void unset_error(void)
{
	axi_io_leds_clear(0x3ff);
}

static void halt(void)
{
	printf("Halting\n");

	while (1)
		;
}

static void on_key0_press(void)
{
	current_value = axi_io_switchs_read();
	update_hex();
}

static void on_key1_press(void)
{
	if (current_value == 0) {
		set_error();
		return;
	}
	current_value--;
	unset_error();
	update_hex();

}

static void on_key2_press(void)
{
	if(current_value == MAX_HEX_VALUE)
	{
		set_error();
		return;
	}
	current_value++;
	unset_error();
	update_hex();
}

static void on_key3_press(void)
{
	current_value = 0;
	update_hex();
}

typedef void (*on_key_press_fn)(void);

on_key_press_fn on_key_press_fns[] = {
	on_key0_press,
	on_key1_press,
	on_key2_press,
	on_key3_press,
};
int main(void)
{
	const uint32_t axi_id = axi_lw_read_constant();
	if (axi_id != AXI_LW_USER_CONSTANT) {
		printf("Invalid AXI_LW_USER_CONSTANT. Expected %" PRIx32
		       " Got %" PRIx32 "\n.",
		       AXI_LW_USER_CONSTANT, axi_id);
		halt();
	}

	axi_lw_test_reg_write(axi_id);
	const uint32_t read_id = axi_lw_test_reg_read();

	if (axi_id != read_id) {
		printf("Invalid result when writing to test register. Expected %" PRIx32
		       " Got %" PRIx32 "\n.",
		       axi_id, read_id);
		halt();
	}
	update_hex();
	unset_error();
	while (1) {
		for (size_t i = 0; i < NB_KEYS; ++i) {
			if (axi_io_key_rising_edge(i)) {
				on_key_press_fns[i]();
				axi_io_ack_key_rising_edge(i);
			}
		}
	}
}
