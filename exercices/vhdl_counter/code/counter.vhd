library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

architecture behave of counter is
    signal value_s : unsigned(SIZE-1 downto 0);
    signal nbincr_s : unsigned(SIZE-1 downto 0);
    signal nbdecr_s : unsigned(SIZE-1 downto 0);
    signal equal_s : std_logic;

begin
    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            value_s <= to_unsigned(0, SIZE);
            nbincr_s <= to_unsigned(0, SIZE);
            nbdecr_s <= to_unsigned(0, SIZE);
        elsif rising_edge(clk_i) then
            equals_o <= equal_s;
            if enable_i = '1' then
                if up_nDown_i = '1' then
                    value_s <= value_s + 1;
                    nbincr_s <= nbincr_s + 1;
                else 
                    value_s <= value_s - 1;
                    nbdecr_s <= nbdecr_s + 1;
                end if;
            end if;
        end if;
    end process;
    --process (all) 
    process (equal_val_i, value_s, nbincr_s, nbdecr_s, value_s) 
        variable target_value_v : unsigned(SIZE-1 downto 0);
    begin
        target_value_v := unsigned(equal_val_i);
        
        if value_s = target_value_v then
            equal_s <= '1';
        else
            equal_s <= '0';
        end if;
        nbincr_o <= std_logic_vector(nbincr_s);
        nbdecr_o <= std_logic_vector(nbdecr_s);
        value_o <= std_logic_vector(value_s);
    end process;
end architecture;
