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

typedef enum { WAIT_PRESS, LED_ON, LED_OFF } state_t;

int main(void)
{
	int blink_count;
	int blink_duration;

	printf("Bonjour Michelle\n");
	printf("Indiquez de fois aimeriez-vous voir la led clignoter > ");
	scanf("%d", &blink_count);
	printf("Indiquez le temps où la led doit rester allumé/éteinte > ");
	scanf("%d", &blink_duration);
	printf("Merci Michelle\n");

	timer_setup(blink_duration);
	hps_setup();
	timer_enable();

	state_t state = WAIT_PRESS;
	int count = 0;
	while (1) {
		switch (state) {
		case WAIT_PRESS:
			if (hps_btn_pressed()) {
				state = LED_ON;
				count = 0;
				timer_enable();
			}
			break;
		case LED_ON:
			if (timer_elapsed()) {
				state = LED_OFF;
			}
			hps_led_set_on();
			break;
		case LED_OFF:
			if (timer_elapsed()) {
				--count;
				if (count == 0) {
					state = WAIT_PRESS;
					timer_disable();
				} else {
					state = LED_ON;
				}
			}
			hps_led_set_off();
			break;
		}
	}
}
