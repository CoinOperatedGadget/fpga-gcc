-------------------------------------------------------------------------------
-- Title       : LED Controller
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description :
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity BUTTON_DEBOUNCER_FALLING_EDGE is
   port(
      I_CLK                      : in  std_logic;
      I_INPUT                    : in  std_logic;
      O_OUTPUT                   : out std_logic
   );
end entity BUTTON_DEBOUNCER_FALLING_EDGE;

architecture BUTTON_DEBOUNCER_FALLING_EDGE_ARCH of BUTTON_DEBOUNCER_FALLING_EDGE is
   -- This is probably way overkill...  Should look into reducing to save resources.
   constant C_STABLE       : natural := 240000;

   signal input_d          : std_logic;
   signal debounce_count   : unsigned(23 downto 0);

begin

   -------------------------------------------------------------------------------
   -- Process     : Debounce
   -- Description : Delay based debouncing process.
   -------------------------------------------------------------------------------
   Debounce : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         O_OUTPUT <= '0';
         input_d  <= I_INPUT;
         if (debounce_count < C_STABLE) then
            debounce_count <= debounce_count+1;
         end if;
         if ((I_INPUT xor input_d) = '1') then
            debounce_count <= (others => '0');
         end if;
         if (debounce_count = C_STABLE-1 and input_d = '0') then
            O_OUTPUT <= '1';
         end if;
      end if;
   end process Debounce;

end architecture BUTTON_DEBOUNCER_FALLING_EDGE_ARCH;
