#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>
#include <stdbool.h>

#define TIMER0_BASE_ADDR 0xFFD00000

#define TIMER0_REG(_x_)                 \
	*(volatile uint32_t             \
		  *)(TIMER0_BASE_ADDR + \
		     _x_) // _x_ is an offset with respect to the base address

#define OSC1_CLOCK	      25e6
#define TIMER_LOAD_COUNT_REG  0x0
#define TIMER_CURRENT_VAL_REG 0x4
#define TIMER_CTRL_REG	      0x8
#define TIMER_EOI_REG	      0xC
#define TIMER_INT_STAT_REG    0x10

#define TIMER_IRQ_LINE_NO     201

void timer_setup(void);
void timer_irq_clear(void);
void timer_enable(void);
void timer_disable(void);
uint32_t timer_value(void);
uint32_t timer_ms(void);

#endif
