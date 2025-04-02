#include <stdint.h>
#include <stdbool.h>
#include "axi_lw.h"

/* Address map
 * Offset (idx) | Data                           | RW
 * -------------|--------------------------------|-----
 * 0x00	    (0) | Constant (0xBADB100D)          | R
 * 0x04	    (1) | Test Register                  | RW
 * 0x08	    (2) | Input Register 1 (Keys)        | R
 * 0x0C	    (3) | Edge Capture Register (Keys)   | RW 
 * 0x10	    (4) | Input Register 2 (Switch)	 | R
 * 0x14	    (5) | Output Register 1 (Led)        | RW
 * 0x18	    (6) | Set Register (Led)             | W
 * 0x1C     (7) | Clear Register (Led)           | W
 * 0x20     (8) | Output Register 2 (Hex3-0)     | RW 
 * 0x24     (9) | Output Register 3 (Hex5-4)     | RW 
*/

#define AXI_KEY_READ	     AXI_LW_REG(0x08)
#define AXI_KEY_EDGE_CAPTURE AXI_LW_REG(0x0C)
#define AXI_SWITCH_READ	     AXI_LW_REG(0x10)
#define AXI_LED_WRITE	     AXI_LW_REG(0x14)
#define AXI_LED_SET	     AXI_LW_REG(0x18)
#define AXI_LED_CLEAR	     AXI_LW_REG(0x1C)
#define AXI_HEX_3_0_WRITE    AXI_LW_REG(0x20)
#define AXI_HEX_5_4_WRITE    AXI_LW_REG(0x24)

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

typedef void (*irq_cb)(uint8_t key, void *);

// Initializes the switches as input
void axi_io_switchs_init(void);

// Initializes the leds as output
void axi_io_leds_init(void);

// Initializes the keys as input
void axi_io_key_init(void);

// Initializes the 7 segments as output
void axi_io_seg7_init(void);

// Switchs_read functaxi_ion : Read the switchs value
// Parameter : None
// Return : Value of all Switchs (SW9 to SW0)
uint32_t axi_io_switchs_read(void);

// Leds_write functaxi_ion : Write a value to all Leds (LED9 to LED0)
// Parameter : "value"= data to be applied to all Leds
// Return : None
void axi_io_leds_write(uint32_t value);

// Leds_set functaxi_ion : Set to ON some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a set (maximum 0x3FF)
// Return : None
void axi_io_leds_set(uint32_t maskleds);

// Leds_clear functaxi_ion : Clear to OFF some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a clear (maximum 0x3FF)
// Return : None
void axi_io_leds_clear(uint32_t maskleds);

// Leds_toggle functaxi_ion : Toggle the curent value of some or all Leds (LED9 to LED0)
// Parameter : "maskleds"= Leds selected to apply a toggle (maximum 0x3FF)
// Return : None
void axi_io_leds_toggle(uint32_t maskleds);

// Key_read functaxi_ion : Read one Key status, pressed or not (KEY0 or KEY1 or KEY2 or KEY3)
// Parameter : "key_number"= select the key number to read, from 0 to 3
// Return : True(1) if key is pressed, and False(0) if key is not pressed
bool axi_io_key_read(int key_number);

bool axi_io_key_rising_edge(int key_number);

void axi_io_ack_key_rising_edge(int key_number);

// Seg7_write functaxi_ion : Write digit segment value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= digit segment value to be applied on the selected 7-segments (maximum 0x7F to switch ON all segments)
// Return : None
void axi_io_seg7_write(int seg7_number, uint32_t value);

// Seg7_write_hex functaxi_ion : Write an Hexadecimal value to one 7-segments display (HEX0 or HEX1 or HEX2 or HEX3)
// Parameter : "seg7_number"= select the 7-segments number, from 0 to 3
// Parameter : "value"= Hexadecimal value to be display on the selected 7-segments, form 0x0 to 0xF
// Return : None
void axi_io_seg7_write_hex(int seg7_number, uint32_t value);
