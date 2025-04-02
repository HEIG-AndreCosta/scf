#include "hps.h"

void hps_setup()
{
	GPIO_REG(GPIO_PORT(GPIO_LED), GPIO_SWPORTA_DDR) |=
		1 << GPIO_PORT_BIT(GPIO_LED);

	GPIO_REG(GPIO_PORT(GPIO_BTN), GPIO_SWPORTA_DDR) &=
		~(1 << GPIO_PORT_BIT(GPIO_BTN));
}
bool hps_btn_pressed()
{
	return !(GPIO_REG(GPIO_PORT(GPIO_BTN), GPIO_EXT_PORTA) &
	       (1 << GPIO_PORT_BIT(GPIO_BTN)));
}
void hps_led_set_on()
{
	GPIO_REG(GPIO_PORT(GPIO_LED), GPIO_SWPORTA_DR) |=
		1 << GPIO_PORT_BIT(GPIO_LED);
}
void hps_led_set_off()
{
	GPIO_REG(GPIO_PORT(GPIO_LED), GPIO_SWPORTA_DR) &=
		~(1 << GPIO_PORT_BIT(GPIO_LED));
}
