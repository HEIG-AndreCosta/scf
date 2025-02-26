
#include "pio.h"
#include <stdint.h>

int __auto_semihosting;

void update_hex(uint16_t led_value)
{
	pio_seg7_write_hex(0, led_value & 0xF);
	pio_seg7_write_hex(1, (led_value >> 4) & 0xF);
	pio_seg7_write_hex(2, (led_value >> 8) & 0x1);
	pio_seg7_write_hex(3, (led_value >> 9) & 0x1);
}
void update_leds(uint16_t value)
{
	pio_leds_write(value);
}
void update_output(uint16_t new_value)
{
	update_hex(new_value);
	update_leds(new_value);
}
int main(void)
{
	pio_switchs_init();
	pio_leds_init();
	pio_key_init();
	pio_seg7_init();
	uint8_t old_key_pressed = 0;
	while (1) {
		uint8_t key_pressed = pio_key_read(0) | (pio_key_read(1) << 1);
		if ((key_pressed & 0x1) && !(old_key_pressed & 0x1)) {
			uint16_t led_value = pio_switchs_read() & 0x3FF;
			update_output(led_value);

		} else if ((key_pressed & 0x2) && !(old_key_pressed & 0x2)) {
			uint16_t led_value = ~pio_switchs_read() & 0x3FF;
			update_output(led_value);
		}
		old_key_pressed = key_pressed;
	}
}
