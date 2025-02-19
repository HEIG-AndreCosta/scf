
#ifndef HPS_H
#define HPS_H

#include <stdbool.h>
#include <stdint.h>

#define GPIO_BASE	  0xFF708000
#define GPIO_REG_SIZE	  0x00001000
#define GPIO(x)		  (GPIO_BASE + x * GPIO_REG_SIZE)

#define GPIO_REG(x, reg)  (*(volatile uint32_t *)(GPIO(x) + reg))

#define GPIO_SWPORTA_DR	  0x00
#define GPIO_SWPORTA_DDR  0x04

#define GPIO_LED	  53
#define GPIO_BTN	  54

#define GPIO_PORT(nr)	  (nr / 29)
#define GPIO_PORT_BIT(nr) (nr % 29)

void hps_setup();
bool hps_btn_pressed();
void hps_led_set_on();
void hps_led_set_off();

#endif
