Project for the Terasic DE1-Soc board

This project uses the LEDs, switches, buttons and seven segments displays connected to the FPGA. These peripherals are controlled with the HPS.


How to run the project:
    - compile Quartus project (located in hard/eda/DE1_SoC.qpf), do not forget to generate Qsys project before otherwise Quartus will remind you
    - open Altera Monitor Program, open the corresponding project located in soft/proj
    - Load the board with the .sof file (when prompted by Altera Monitor Program), compile the source files and load the processor
    - Run


How the example works:
    - Press KEY0 to turn the LEDs on according to the switches positions. HEX0 and HEX1 display hexadecimal values defined by the LED0 to LED7.
      HEX2 and HEX3 display 1 when LED8 and LED9 are respectively turned on, 0 otherwise.
    - Press KEY1 to turn the LEDs on according to the opposite of switches positions. HEX0 and HEX1 display hexadecimal values defined by the LED0 to LED7.
      HEX2 and HEX3 display 1 when LED8 and LED9 are respectively turned on, 0 otherwise.


folder structure:
    - doc: documentation
    - hard: files related to hardware, ie VHDL source and simulation files, Quartus and Qsys project
    - publi: publications
    - soft: files related to software, ie linux files and project, Altera Monitor Program source and project files
