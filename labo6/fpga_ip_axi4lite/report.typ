#set align(center)
= SCF 2025 

== Laboratoire 06
== IP AXI4-Lite avec FPGA I/O

=== André Costa

#set align(left)

= Objectifs 

Ce laboratoire a pour but de réaliser une IP avec une interface AXI4-Lite et connectée
sur le bus Lightweight HPS-to-FPGA à partir d’une implémentation VHDL fournie. Cette
IP doit permettre d’accéder à des I/O câblées sur la partie FPGA via des registres.

= Modifications `axi4lite_slave`

Tout d'abord il nous est demandé d'ajouter des fonctionnalités au `axi4lite slave` fournit.

== Edge Capture Register

Ici il nous est demandé de gérer les flancs montants des boutons avec possibilité d'acquittement.

Ceci correspond à:

1. Détecter les changements
2. Mise à jour d'un registre
3. Reset des bits spécifiques registre lors de l'écriture


Pour cela, mon implémentation implique l'ajout de quelques signaux:

```vhdl
    signal prev_input_reg_A_s : std_logic_vector(31 downto 0);
    signal edge_capture_s : std_logic_vector(31 downto 0);
    signal new_edge_capture_s : std_logic_vector(31 downto 0);
    signal wr_edge_capture_s : std_logic;
```

- `prev_input_reg_A_s` sera responsable de stocker l'ancienne valeur du registre
- `edge_capture_s` sera responsable de stocker les flancs montants détéctés et pas encore acquités
- `new_edge_capture_s` et `wr_edge_capture_s` seront responsables pour stocker la valeur écrite sur ce registre pour pouvoir le mettre à jour

Un process supplémentaire a aussi été ajouté pour permettre la gestion de ce registre.

Voici l'idée derrière l'algorithme:

1. Tout d'abord il faut détérminer s'il y a une écriture sur le registre ou non
	- Si oui, nous prennons la nouvelle valeur
	- Sinon, on continue avec la valeur précédente.

2. Finalement, le calcul de la nouvelle valeur du registre est trouvé avec une combinaison de portes logiques qui rend la formule très élégante si j'ose le dire.

- Tout d'abord, pour détécter un flanc, rien de mieux qu'une simple porte `xor` entre l'ancienne et la nouvelle valeur du registre.
- Ensuite, pour filtre sur un flanc montant, nous pouvons faire prendre le résultat et effectuer un `et` logique sur la valeur actuelle (inversée) du registre.
	- L'inversion sert à détérminer une pression du bouton en tenant compte que les boutons sont actifs bas.
- Finalement, on fait rentrer notre état actuelle du registre (ou la nouvelle valeur qui vient d'être écrite) en faisant un `or` sur le résultat précedente.
	- Ceci permettra de garder les `1` actuelles qui représentent les flancs montants non-acquittés


Voici l'algorithme en `vhdl`:

```vhdl
    process (clk_i, reset_s)
        variable current_edge_capture_s: std_logic_vector(edge_capture_s'range);
    begin
        if reset_s = '1' then
            edge_capture_s <= (others => '0');
        elsif rising_edge(clk_i) then

            current_edge_capture_s := edge_capture_s;
            if wr_edge_capture_s = '1' then
                current_edge_capture_s := new_edge_capture_s;
            end if;

            -- 'xor' detects the edge
            -- 'and' with the current value so we only keep the rising edge
            -- 'not' is because the button is active low
            -- 'or' makes sure we keep the previous '1'
            edge_capture_s <= current_edge_capture_s or ((prev_input_reg_A_s xor input_reg_A_s) and not input_reg_A_s);
        end if;
    end process;
``` 

Dans le process qui gére l'écriture du registre, nous pouvons ajouter le case pour le registre correspondant.

Ici nous mettons à jour les valeurs des signaux `new_edge_capture_s` et `wr_edge_capture_s` pour pouvoir, justement les utiliser dans la gestion du
registre. Notons que nous ne pouvons pas modifier `edge_capture_s` directement ici car cela impliquerait avoir deux `process` qui écrivent sur le même signal 
et le synthétiseur n'aime pas trop.

```vhdl
      when 3 => 
      for byte_index in 0 to (AXI_DATA_WIDTH/8-1) loop
	if ( axi_wstrb_i(byte_index) = '1' ) then
		new_edge_capture_s(byte_index * 8 + 7 downto byte_index * 8) <=
			edge_capture_s (byte_index * 8 + 7 downto byte_index * 8) and
			not axi_wdata_i(byte_index * 8 + 7 downto byte_index * 8);
		wr_edge_capture_s <= '1'
	end if;
      end loop;
```

Et finalement la lecture:

```vhdl
            when 3 =>
                axi_rdata_s <= edge_capture_s;
```

== Clear Register et Write Output Register

Les autres deux fonctionnalités à ajouter à ce `slave` sont la gestion d'un registre `clear` et un registre `write`.

```vhdl
when 7 => for byte_index in 0 to (AXI_DATA_WIDTH/8-1) loop
		if ( axi_wstrb_i(byte_index) = '1' ) then
			output_reg_A_s(byte_index * 8 + 7 downto byte_index * 8) <= 
			output_reg_A_s(byte_index * 8 + 7 downto byte_index * 8) and not
			axi_wdata_i(byte_index * 8 + 7 downto byte_index * 8);
		end if;
	end loop;

when 8   => for byte_index in 0 to (AXI_DATA_WIDTH/8-1) loop
		if ( axi_wstrb_i(byte_index) = '1' ) then
			output_reg_B_s(byte_index*8+7 downto byte_index*8) <= axi_wdata_i(byte_index*8+7 downto byte_index*8);
		end if;
	end loop;
```

L'implémentation  des deux est assez simple, pour le `clear`, il faut bien prendre la valeur actuelle et effectuer un `et` avec l'inverse de la nouvelle valeur (case 7 ci-dessus).
Pour le `write`, il suffit de modifier la valeur actuelle du registre.

Tout ça sans oublier la gestion du `byte_enable` (`axi_wstrb_i`) du bux `axi` qui permet d'indiquer quels bytes il faut modifier.


= Génération d'une IP

== Création d'un Component

Ensuite, il était temps de créer une IP avec cet `axi4lite_slave`.

Dans `Platform Designer`, il a fallu créer un nouveau composant.

Voici les différents paramètres configurés:

- Dans l'onglet `Component Type`, modifier le nom du composant.

#image("./media/component_type.png")

- Dans l'onglet `Files`, ajouter le fichier `axi4lite_slave.vhd` et presser sur `Analyze Synthesis Files`. Ceci créera des signaux dans l'interface `Signals & Interface`.

Note: En cas de modification du fichier `axi4lite_slave.vhd`, il faut venir ici et relancer cette analyse.

#image("./media/files.png")

- Dans l'onglet `Parameters`, `Quartus` détecte automatiquement les paramètres génériques de notre
composant. J'utilise les valeurs par défaut, c'est-à-dire, 32 bits de données et 12 bits d'adresse.

#image("./media/parameters.png")

#pagebreak()

- Dans l'onglet `Signals & Interfaces`, les signaux générés automatiquement lors de la pression sur `Analyze Synthesis Files` doivent être glissés sur les bonnes interfaces.

#image("./media/signals.png")

Une fois les signaux correctement mappés, il faut encore indiquer sur `altera_axi4lite_slave`, le clock et reset associés.

#image("./media/signals_ref_clock.png")

Finalement, nous pouvons presser sur `Finish` et designer notre système.

== System Contents

Avec le composant crée, nous pouvons l'ajouter à notre système et le connecter sur l'HPS comme sur l'image suivante:

#image("./media/system_contents.png")

Ne pas oublier d'exporter `external_connections`. Cette interface qui contient les signaux à connecter sur les pins physiques de la `FPGA`.


Notons qu'ici je suis parti du projet avec gestion des IRQs et donc nous voyons des signaux IRQ qui ne sont pas utilisés.

Avec le système finalisé, nous pouvons générer les fichiers nécessaires avec `Generate` -> `Generate HDL`.

Finalement, prendre le template d'instatiation sur `Generate` -> `Show Instatiation Template` qui va nous permettre de déclarer notre composant dans le `DE1_SoC_top`.


== Mappage des Signaux

Composant et systèmes créés, il est temps de modifier le `Top` pour pouvoir les utiliser.

Pour cela, en partant du fichier `DE1_SoC_top` des labos précédents, il faut ajouter les bons signaux dans la déclaration du composant.


```vhdl
    component qsys_system is
        port (
            axi4lite_slave_extern_input_reg_a_i  : in    std_logic_vector(31 downto 0) := (others => 'X'); -- input_reg_a_i
            axi4lite_slave_extern_input_reg_b_i  : in    std_logic_vector(31 downto 0) := (others => 'X'); -- input_reg_b_i
            axi4lite_slave_extern_output_reg_a_o : out   std_logic_vector(31 downto 0);                    -- output_reg_a_o
            axi4lite_slave_extern_output_reg_b_o : out   std_logic_vector(31 downto 0);                    -- output_reg_b_o
            axi4lite_slave_extern_output_reg_c_o : out   std_logic_vector(31 downto 0);                    -- output_reg_c_o

            -- Clock
            clk_i_clk                        : in    std_logic                     := 'X';
```

Et les connecter dans l'instatation:


```vhdl

    signal hex0_3_s : std_logic_vector(31 downto 0);
    signal hex4_5_s : std_logic_vector(31 downto 0);
    signal led_s : std_logic_vector(31 downto 0);

    constant SWITCH_PADDING : std_logic_vector(31 -SW_i'length downto 0) := (others => '0');
    constant KEY_PADDING : std_logic_vector(31 -key_i'length downto 0) := (others => '0');
...

    System : component qsys_system
    port map (

        axi4lite_slave_extern_input_reg_a_i => KEY_PADDING & KEY_i, 
        axi4lite_slave_extern_input_reg_b_i => SWITCH_PADDING & SW_i,
        axi4lite_slave_extern_output_reg_a_o   => led_s,
        axi4lite_slave_extern_output_reg_b_o   => hex0_3_s,
        axi4lite_slave_extern_output_reg_c_o   => hex4_5_s,

        -- Clock                          
        clk_i_clk        => CLOCK_50_i,
...

    HEX0_o <= hex0_3_s(HEX0_o'range);
    HEX1_o <= hex0_3_s(13 downto 7);
    HEX2_o <= hex0_3_s(20 downto 14);
    HEX3_o <= hex0_3_s(27 downto 21);
    HEX4_o <= hex4_5_s(HEX4_o'range);
    HEX5_o <= hex4_5_s(13 downto 7);
    LEDR_o <= led_s(LEDR_o'range);
```

Avec les adaptations nécéssaires pour que les signaux soient connectés correctement.


== Compilation

Pour éviter d'avoir 1915 erreurs lors de la partie de `Fitter (Place & Route)`, il est recommandé d'aller sur `Tools` -> `Tcl Scripts` et lancer le script `DE1_SoC_assign_pins.tcl`. Oui, cela m'a traumatisé :)

Une fois la compilation completé, nous pouvons programmer la carte `DE1` en utilisant les scripts fournis:

```bash
python3 pgm_fpga.py --sof "../labo6/fpga_ip_axi4lite/hard/eda/output_files/fpga_ip_axi4lite.sof"
python3 upld_hps.py
```

= Software

== Driver AXI Slave

Un nouveau driver doit être crée car cette interface n'est plus compatible avec les `PIO` utilisés précedemment.

Voici à quoi se ressemble:

Des `#defines` nous permettent d'accèder au registres et facilement les adapter si l'on change les adresses.

```c
#define AXI_LW_HPS_FPGA_BASE_ADD 0xFF200000

#define AXI_LW_REG(x)		 *(volatile uint32_t *)(AXI_LW_HPS_FPGA_BASE_ADD + x)
#define AXI_LW_CONSTANT_REG	 AXI_LW_REG(0x00)
#define AXI_LW_TEST_REG		 AXI_LW_REG(0x04)
#define AXI_KEY_READ		 AXI_LW_REG(0x08)
#define AXI_KEY_EDGE_CAPTURE 	 AXI_LW_REG(0x0C)
#define AXI_SWITCH_READ	     	 AXI_LW_REG(0x10)
#define AXI_LED_WRITE	     	 AXI_LW_REG(0x14)
#define AXI_LED_SET	     	 AXI_LW_REG(0x18)
#define AXI_LED_CLEAR	     	 AXI_LW_REG(0x1C)
#define AXI_HEX_3_0_WRITE    	 AXI_LW_REG(0x20)
#define AXI_HEX_5_4_WRITE    	 AXI_LW_REG(0x24)
```

Ces defines peuvent alors être utilisés ainsi :

```c
void axi_io_leds_write(uint32_t value)
{
	AXI_LED_WRITE = value;
}

void axi_io_leds_set(uint32_t maskleds)
{
	AXI_LED_SET = maskleds;
}

void axi_io_leds_clear(uint32_t maskleds)
{
	AXI_LED_CLEAR = maskleds;
}
```

Et finalement le driver peut fournir les fonctions suivantes pour utilisation sur l'application finale:

- Pour les constantes et registre de test:

	- `uint32_t axi_lw_read_constant(void)`
	- `void axi_lw_test_reg_write(uint32_t value)` 
	- `uint32_t axi_lw_test_reg_read(void)`

- Pour l'interface IO:

	- `axi_pio_set_leds(uint32_t led_mask)`
	- `axi_pio_clear_leds(uint32_t led_mask)`
	- `axi_io_seg7_write_hex(int seg7_number, uint32_t value)`
	- `bool axi_io_key_rising_edge(int key_number)`
	- `void axi_io_ack_key_rising_edge(int key_number)`


== Aplication Principale


=== Gestion de l'initialisation

Tout d'abord il faut vérifier que nous arrivons à lire la bonne constante et que la lecture et écriture sur le registre de test marchent correctement:


```c

static void halt(void)
{
	printf("Halting\n");

	while (1)
		;
}

int main(void)
{
	const uint32_t axi_id = axi_lw_read_constant();
	if (axi_id != AXI_LW_USER_CONSTANT) {
		printf("Invalid AXI_LW_USER_CONSTANT. Expected %" PRIx32
		       " Got %" PRIx32 "\n.",
		       AXI_LW_USER_CONSTANT, axi_id);
		halt();
	}

	axi_lw_test_reg_write(axi_id);
	const uint32_t read_id = axi_lw_test_reg_read();

	if (axi_id != read_id) {
		printf("Invalid result when writing to test register. Expected %" PRIx32
		       " Got %" PRIx32 "\n.",
		       axi_id, read_id);
		halt();
	}
	...
}
```


Finalement, l'application principale doit seulement attendre qu'un bouton soit pressé lui permettant d'effectuer la bonne tâche.
```c
static void on_key0_press(void)
{
	current_value = axi_io_switchs_read();
	update_hex();
}

static void on_key1_press(void)
{
	if (current_value == 0) {
		set_error();
		return;
	}
	current_value--;
	unset_error();
	update_hex();

}

static void on_key2_press(void)
{
	if(current_value == MAX_HEX_VALUE)
	{
		set_error();
		return;
	}
	current_value++;
	unset_error();
	update_hex();
}

static void on_key3_press(void)
{
	current_value = 0;
	update_hex();
}

typedef void (*on_key_press_fn)(void);

on_key_press_fn on_key_press_fns[] = {
	on_key0_press,
	on_key1_press,
	on_key2_press,
	on_key3_press,
};

int main(void)
{
	...
	while (1) {
		for (size_t i = 0; i < NB_KEYS; ++i) {
			if (axi_io_key_rising_edge(i)) {
				on_key_press_fns[i]();
				axi_io_ack_key_rising_edge(i);
			}
		}
	}
}
```

#pagebreak()

= Conclusion

Ce laboratoire m'a permis de réaliser une IP avec une interface `AXI4-Lite` et la connecter sur le bus `Lightweight HPS-to-FPGA`.

Il m'a aussi permis de me plonger dans un code `vhdl` fourni qui est un exercice qui n'avait pas encore été fait dans le cursus.

Il a fallu comprendre comment marchent les différents logiciels, notamment `Quartus` et aussi mettre en place des techniques de debug apprises précedemment.

Finalement, une fois l'implémentation hardware complète et le système designé, j'ai pu m'amuser dans la création d'une application `C` pour s'interfacer avec la partie `hardware`.

