/*****************************************************************************************
 * HEIG-VD
 * Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
 * School of Business and Engineering in Canton de Vaud
 *****************************************************************************************
 * REDS Institute
 * Reconfigurable Embedded Digital Systems
 *****************************************************************************************
 *
 * File                 : hps_gpio.c
 * Author               : 
 * Date                 : 
 *
 * Context              : SOCF tutorial lab
 *
 *****************************************************************************************
 * Brief: light HPS user LED up when HPS user button pressed, for DE1-SoC board
 *
 *****************************************************************************************
 * Modifications :
 * Ver    Date        Student      Comments
 * 
 *
*****************************************************************************************/


#include <stdio.h>
#include <stdbool.h>
#include "timer.h"
#include "hps.h"

int __auto_semihosting;

typedef enum { WAIT_PRESS, LED_ON, LED_OFF } state_t;

int main(void)
{
	int blink_count;
	int blink_duration;

	printf("Bonjour Michelle\n");
	printf("Indiquez de fois aimeriez-vous voir la led clignoter > \n");

	scanf("%d", &blink_count);
	printf("Indiquez le temps où la led doit rester allumé/éteinte > \n");
	scanf("%d", &blink_duration);
	printf("Merci Michelle\n");

	timer_setup();
	hps_setup();
	timer_enable();
	hps_led_set_off();

	state_t state = WAIT_PRESS;
	int count = 0;
	uint32_t last_timer_value = 0;


	while (1) {


		switch (state) {
		case WAIT_PRESS:
			if (hps_btn_pressed()) {
				printf("Button Pressed !\n");
				state = LED_ON;
				count = 1;
				last_timer_value = timer_ms();
			}
			break;
		case LED_ON:
			if (last_timer_value - timer_ms() > blink_duration) {
				state = LED_OFF;
				last_timer_value = timer_ms();
			}
			hps_led_set_on();
			break;
		case LED_OFF:
			if (last_timer_value - timer_ms() > blink_duration) {
				if (++count >= blink_count) {
					state = WAIT_PRESS;
				} else {
					state = LED_ON;
				}
				last_timer_value = timer_ms();
			}
			hps_led_set_off();
			break;
		}

	}
}
