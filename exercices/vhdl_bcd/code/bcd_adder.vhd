-----------------------------------------------------------------------
-- HEIG-VD, Haute Ecole d'Ingenerie et de Gestion du Canton de Vaud
-- Institut REDS
--
-- Composant    : bcd_adder
-- Description  : Additionneur BCD.
--                Un paramètre générique permet de définir le nombre de digits.
-- Auteur       : Yann Thoma
-- Date         : 01.03.2017
-- Version      : 1.0
--
-- Modification : -
--
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use work.bcd_pkg.all;
use work.bcd_configuration_package.all;

entity bcd_adder is
    generic (
        NDIGITS : integer := 4
    );
    port (
        input0_i  : in  bcd_number(NDIGITS - 1 downto 0);
        input1_i  : in  bcd_number(NDIGITS - 1 downto 0);
        result_o  : out bcd_number(NDIGITS downto 0);
        hamming_o : out std_logic_vector(integer(ceil(log2(real(4*NDIGITS)))) downto 0)
    );
end bcd_adder;



architecture struct of bcd_adder is


    component generic_full_adder is
        generic(
            Basis_g         : natural := 10 -- Number Basis_g 2^N_bits_c >= Basis_g
        );
        port(
            Carry_i       : in  std_logic;
            Op_A_i        : in  std_logic_vector(BCX_Bits(Basis_g)-1 downto 0);
            Op_B_i        : in  std_logic_vector(BCX_Bits(Basis_g)-1 downto 0);
            Res_o         : out std_logic_vector(BCX_Bits(Basis_g)-1 downto 0);
            Carry_o       : out std_logic
        );

    end component;
    signal carry_s : std_logic_vector(NDIGITS downto 0);

begin

    carry_s(0) <= '0';

    adders : for i in 0 to NDIGITS - 1 generate 
            gen_add: generic_full_adder port map (
                Op_A_i =>  input0_i(i),
                Op_B_i =>  input1_i(i),
                Carry_i => carry_s(i),
                Carry_o => carry_s(i + 1),
                Res_o => result_o(i)
            );
    end generate adders;


    hamming: process (all)
        variable sum : unsigned(hamming_o'range);
    begin
        sum := (others => '0');
        for i in 0 to NDIGITS - 1 loop
            for j in 0 to 3 loop
                if(input0_i(i)(j) /= input1_i(i)(j)) then
                    sum := sum + 1;
                end if;
            end loop;
        end loop;
        hamming_o <= std_logic_vector(sum);
    end process;

    result_o(NDIGITS) <= (0 => carry_s(NDIGITS -1), others => '0');


end struct;
