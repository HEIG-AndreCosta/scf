#include <stdint.h>
#include <stdbool.h>
#include "axi_lw.h"

#define LED_PIO(x)	     AXI_LW_REG(0x10 + x)
#define SWITCH_PIO(x)	     AXI_LW_REG(0x20 + x)
#define HEX_PIO(x)	     AXI_LW_REG(0x30 + x)
#define KEY_PIO(x)	     AXI_LW_REG(0x40 + x)

#define NB_KEYS		     4
#define KEY_SHIFT	     0
#define KEY_MASK	     ((1 << NB_KEYS) - 1)
#define KEY_REGISTER_MASK    (KEY_MASK << KEY_SHIFT)

#define NB_SWITCH	     10
#define SWITCH_SHIFT	     0
#define SWITCH_MASK	     ((1 << NB_SWITCH) - 1)
#define SWITCH_REGISTER_MASK (SWITCH_MASK << SWITCH_SHIFT)

#define NB_LEDS		     10
#define LED_SHIFT	     0
#define LED_MASK	     ((1 << NB_LEDS) - 1)
#define LED_REGISTER_MASK    (LED_MASK << LED_SHIFT)

#define NB_SEGS		     4
#define HEX_BITS	     7
#define HEX_FULL_MASK	     ((1 << (NB_SEGS * HEX_BITS)) - 1)
#define HEX_MASK	     ((1 << HEX_BITS) - 1)

// Initializes the switches as input
void pio_switchs_init(void);

// Initializes the leds as output
void pio_leds_init(void);

// Initializes the keys as input
void pio_key_init(void);

// Initializes the 7 segments as output
void pio_seg7_init(void);

// Switchs_read function : Read the switchs value
// Parameter : None
// Return : Value of all Switchs (SW9 to SW0)
uint32_t pio_switchs_read(void);

// Leds_write function : Write a value to all Leds (LED9 to LED0)
// Parameter : "value"= data to be applied to all Leds
// Return : None
void pio_leds_write(uint32_t value);

// Leds_set function : Set to ON some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a set (maximum 0x3FF)
// Return : None
void pio_leds_set(uint32_t maskleds);

// Leds_clear function : Clear to OFF some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a clear (maximum 0x3FF)
// Return : None
void pio_leds_clear(uint32_t maskleds);

// Leds_toggle function : Toggle the curent value of some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a toggle (maximum 0x3FF)
// Return : None
void pio_leds_toggle(uint32_t maskleds);

// Key_read function : Read one Key status, pressed or not (KEY0 or KEY1 or KEY2 or KEY3)
// Parameter : "key_number"= select the key number to read, from 0 to 3
// Return : True(1) if key is pressed, and False(0) if key is not pressed
bool pio_key_read(int key_number);

// Seg7_write function : Write digit segment value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= digit segment value to be applied on the selected 7-segments (maximum 0x7F to switch ON all segments)
// Return : None
void pio_seg7_write(int seg7_number, uint32_t value);

// Seg7_write_hex function : Write an Hexadecimal value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= Hexadecimal value to be display on the selected 7-segments, form 0x0 to 0xF
// Return : None
void pio_seg7_write_hex(int seg7_number, uint32_t value);
