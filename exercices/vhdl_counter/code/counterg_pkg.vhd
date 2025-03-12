library ieee;
use ieee.std_logic_1164.all;


package counterg_pkg is
  
  type counter_in_type is record        
    enable    : std_logic;
    up_nDown  : std_logic;
    equal_val : std_logic_vector(7 downto 0);
  end record;
  
  type counter_out_type is record
    equals    : std_logic;
    value     : std_logic_vector(7 downto 0);
    nbincr    : std_logic_vector(7 downto 0);
    nbdecr    : std_logic_vector(7 downto 0);
  end record;

end package;
