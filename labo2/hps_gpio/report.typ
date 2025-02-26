
= SCF 2025 

== Laboratoire 02 
== Utilisation des I/O de la partie FPGA via le HPS

=== André Costa


== Objectifs 

Ce laboratoire a pour but d’accéder à des I/O câblés sur la partie FPGA. Il s’agira
d’ajouter des blocs PIO pour interfacer ces I/O sur le HPS. Vous devrez comprendre
comment ajouter des IP disponibles dans Qsys pour construire des interfaces permettant
d’accéder aux I/O de la FPGA depuis le HPS



== Configuration QSYS

=== PIO

La configuration des PIOs est assez simple. Une fois défini le nombre de bits,
on peut alors séléctionner des propriètes comme `Enable individual bit setting/clearing`
pour les outputs et des interrupts pour les inputs.


#figure(
	image("media/pio_leds.png"),
	caption : [ Configuration PIO pour les leds ]
)

#figure(
	image("media/pio_switchs.png"),
	caption : [ Configuration PIO pour les switchs ]
)

=== PLL 

Pour la configuration PLL il suffit d'indiquer la fréquence souhaitée. Ici 50Mhz.

#figure(
	image("media/pll.png"),
	caption : [ Configuration PLL ]
)


=== Connexions 

==== Connexions PIO

Une fois défini le nombre de bits comme on va s'interfacer en utilisant le bus AXI lightweight, il faut connecter les signaux `clk`, `reset` et `s1` à cette interface.

Le signal `external_connection` sert à s'interfacer avec les pins physiques du chip.
Pour cela, nous devons l'exporter et la connecter sur le top ultérieurement.

==== Connexions PLL

La PLL fournit les fréquences à chaque bloc.

Comme référence on va la connecter à un oscillateur externe aussi, il faut donc exporter le signal `Clock Input`.

#line(length: 100%)

Voici le résultat, une fois tout mis en place.

#figure(
	image("media/qsys.png")
)


== Modifications du Top

Une fois le `HDL` exporté on découvre que les signaux n'ont pas les noms que nous avons mis ce qui est très triste...

Les modifications du top effectués sont:

- Ajout des nouveaux signaux à la déclaration du composant `qsys_system`.
- Connexion de ces signaux dans l'instanciation de ce même composant.

  - Pour les connexions du clock, leds, switchs et keys il suffit de connecter avec les pins physiques correspondantes.
  - Pour les connexions avec les 7 segments, comme j'ai configuré un PIO. 28 bits pour les 7 segments 0 à 4, je dois "dispatcher" correctement les differents bits. Ceci est fait avec un signal intermédiaire `hex0_4_s`.


```patch
diff --git a/labo1/hps_gpio/hard/src/DE1_SoC_top.vhd b/labo2/hps_gpio/hard/src/DE1_SoC_top.vhd
index 81b0a83..22491e4 100644
--- a/labo1/hps_gpio/hard/src/DE1_SoC_top.vhd
+++ b/labo2/hps_gpio/hard/src/DE1_SoC_top.vhd
@@ -205,9 +205,17 @@ architecture top of DE1_SoC_top is
             ------------------------------------
             -- FPGA Side
             ------------------------------------
+            -- PIO 
+            leds_o_export                    : out   std_logic_vector(9 downto 0);                   
+            switchs_i_export                 : in    std_logic_vector(9 downto 0)  := (others => 'X');
+            hex0_4_o_export                  : out   std_logic_vector(27 downto 0);
+            keys_i_export                    : in    std_logic_vector(3 downto 0)  := (others => 'X');
+
+            -- Clock
+            clk_i_clk                        : in    std_logic                     := 'X';
             -- Global signals
             ------------------------------------
             -- HPS Side
             ------------------------------------
@@ -228,14 +236,14 @@ architecture top of DE1_SoC_top is
             memory_mem_odt                  : out   std_logic;                                        -- mem_odt
             memory_mem_dm                   : out   std_logic_vector(3 downto 0);                     -- mem_dm
             memory_oct_rzqin                : in    std_logic                     := 'X';             -- oct_rzqin
             -- Pushbutton
             hps_io_0_hps_io_gpio_inst_GPIO54  : inout std_logic                     := 'X';             -- hps_io_gpio_inst_GPIO54
             -- LED
             hps_io_0_hps_io_gpio_inst_GPIO53  : inout std_logic                     := 'X'              -- hps_io_gpio_inst_GPIO53
         );
     end component qsys_system;
+    signal hex0_4_s : std_logic_vector(27 downto 0);
 
 begin
 
@@ -248,7 +256,16 @@ begin
         ------------------------------------
         -- FPGA Side
         ------------------------------------
-    
+
+        -- PIO 
+        leds_o_export    => LEDR_o,                   
+        switchs_i_export => SW_i,
+        hex0_4_o_export => hex0_4_s, 
+        keys_i_export =>  KEY_i,
+
+        -- Clock                          
+        clk_i_clk        => CLOCK_50_i,
+        
         -- Global signals
         
         ------------------------------------
@@ -279,4 +296,10 @@ begin
         hps_io_0_hps_io_gpio_inst_GPIO53  => HPS_LED_io
     );
 
+    HEX0_o <= hex0_4_s(HEX0_o'range);
+    HEX1_o <= hex0_4_s(13 downto 7);
+    HEX2_o <= hex0_4_s(20 downto 14);
+    HEX3_o <= hex0_4_s(27 downto 21);
 end top;
```


== Implémentation Software


=== Interface software PIO
Une grande partie du software a pu être prise des laboratoires d'ARE du semestre passé.

Le premier registre PIO (offset `0x00`) sert à lire/écrire selon
si c'est configuré en entrée/sortie.

Voici des examples de configuration en utilisant ce registre:
```c
/* Lecture de l'état des entrées*/
uint32_t pio_switchs_read(void)
{
	return SWITCH_PIO(0);
}

/* Mise à jour de l'état des sorties */
void pio_leds_write(uint32_t value)
{
	LED_PIO(0) = (value & LED_MASK) << LED_SHIFT;
}
```

Le deuxième registre PIO (offset `0x04`) sert à configurer les pins.
Un bit à `0` configure le pin en entrée et un bit `1` en sortie.

Voici des examples de configuration en utilisant ce registre:

```c
/* Configuration en entrée */
void pio_switchs_init(void)
{
	SWITCH_PIO(4) &= ~SWITCH_REGISTER_MASK;
}

/* Configuration en sortie */
void pio_leds_init(void)
{
	LED_PIO(4) |= LED_REGISTER_MASK;
}
```


Les macros `LED_PIO et SWITCH_PIO` évaluent en:


```c
#define AXI_LW_HPS_FPGA_BASE_ADD 0xFF200000
#define LED_PIO(x) *(volatile uint32_t *)(AXI_LW_HPS_FPGA_BASE_ADD + 0x10 + x)
#define SWITCH_PIO(x) *(volatile uint32_t *)(AXI_LW_HPS_FPGA_BASE_ADD + 0x20 + x)
```


=== Application Finale


Avec l'interface PIO, l'application finale devient très simple à écrire
```c
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
```
