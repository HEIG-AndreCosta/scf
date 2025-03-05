library ieee;
use ieee.std_logic_1164.all;

entity counter is
generic (
    SIZE : integer := 8
);
port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    enable_i    : in  std_logic;
    up_nDown_i  : in  std_logic;
    equal_val_i : in  std_logic_vector(SIZE-1 downto 0);
    equals_o    : out std_logic;
    value_o     : out std_logic_vector(SIZE-1 downto 0);
    nbincr_o    : out std_logic_vector(SIZE-1 downto 0);
    nbdecr_o    : out std_logic_vector(SIZE-1 downto 0)
);
end counter;
