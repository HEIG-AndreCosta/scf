#include "timer.h"
void timer_setup(uint32_t timer_duration)
{
	//Disable the timer by writing a 0 to the timer1 enable bit (timer1_enable) of the
	//timer1controlreg register.
	TIMER0_REG(TIMER_CTRL_REG) &= ~0x1;

	//Program the timer mode—user-defined count or free-running—by writing a 0 or 1, respectively, to
	//the timer1 mode bit (timer1_mode) of the timer1controlreg register.
	TIMER0_REG(TIMER_CTRL_REG) |= 0x2;

	//Set the interrupt mask as either masked or not masked by writing a 1 or 0, respectively, to the
	//timer1_interrupt_mask bit of the timer1controlreg register.
	TIMER0_REG(TIMER_CTRL_REG) &= ~0x4;

	//Load the timer counter value into the timer1loadcount register.
	TIMER0_REG(TIMER_LOAD_COUNT_REG) =
		(uint32_t)(OSC1_CLOCK * timer_duration);
}

void timer_irq_clear(void)
{
	// To clear an active timer interrupt, read the timer1eoi register
	int val = TIMER0_REG(TIMER_EOI_REG);
	(void)val;
}
void timer_enable(void)
{
	TIMER0_REG(TIMER_CTRL_REG) |= 0x1;
}
void timer_disable(void)
{
	TIMER0_REG(TIMER_CTRL_REG) &= ~0x1;
}
bool timer_elapsed(void)
{
	return TIMER0_REG(TIMER_CURRENT_VAL_REG) == 0;
}
