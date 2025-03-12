library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.counterg_pkg.all;


entity counterg is
generic (
    SIZE : integer := 8
);
port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    counter_i   : in counter_in_type;
    counter_o   : out counter_out_type
);
end counterg;


architecture behave of counterg is

    type counterg_reg_t  is record
        value : unsigned(SIZE-1 downto 0);
        nbincr : unsigned(SIZE-1 downto 0);
        nbdecr : unsigned(SIZE-1 downto 0);
        equal : std_logic;
    end record;
    function init_reg return counterg_reg_t is
            variable reg : counterg_reg_t;
    begin
        reg.value := (others => '0');
        reg.nbincr := (others => '0');
        reg.nbdecr := (others => '0');
        reg.equal := '0';
        return reg;
    end function;

    signal r: counterg_reg_t;
    signal n_r: counterg_reg_t;

begin
    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            r <= init_reg;
        elsif rising_edge(clk_i) then
            r <= n_r;
        end if;
    end process;
    process (all) 
        variable r_v : counterg_reg_t;
    begin
        r_v := r;

        if counter_i.enable = '1' then
            if counter_i.up_nDown = '1' then
                r_v.value := r.value + 1;
                r_v.nbincr := r.nbincr + 1;
            else 
                r_v.value := r.value - 1;
                r_v.nbdecr := r.nbdecr + 1;
            end if;
        end if;

        if r_v.value = unsigned(counter_i.equal_val) then
            r_v.equal := '1';
        else 
            r_v.equal := '0';
        end if;

        n_r <= r_v;
    end process;


    counter_o.equals <= r.equal; 
    counter_o.value <=  std_logic_vector(r.value); 
    counter_o.nbincr <= std_logic_vector(r.nbincr); 
    counter_o.nbdecr <= std_logic_vector(r.nbdecr); 
end architecture;
