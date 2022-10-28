-------------------------------------------------------------------------------
-- Title       : Stick Handler
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description : Handles control stick with modifiers
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity STICK_HANDLER_1_0 is
   generic(
      G_STICK_NEUTRAL            : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(128, 8));
      G_MAX_X_VALUE              : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(255, 8));
      G_MAX_Y_VALUE              : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(255, 8));
      G_MIN_X_VALUE              : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(  0, 8));
      G_MIN_Y_VALUE              : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(  0, 8));
      G_TILT_X_VALUE             : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(180, 8));
      G_TILT_Y_VALUE             : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(180, 8));
      G_TILT_X_VALUE_NEG         : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned( 76, 8));
      G_TILT_Y_VALUE_NEG         : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned( 76, 8));
      G_MOD_X_VALUE              : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(128+61, 8));
      G_MOD_X_VALUE_NEG          : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(128-62, 8))
   );
   port(
      I_CLK                      : in  std_logic;
      I_RST                      : in  std_logic;
      I_UP                       : in  std_logic;
      I_DOWN                     : in  std_logic;
      I_LEFT                     : in  std_logic;
      I_RIGHT                    : in  std_logic;
      I_TILT_MODIFIER            : in  std_logic;
      I_X_MODIFIER               : in  std_logic;
      I_Y_MODIFIER               : in  std_logic; -- Todo
      I_UP_MOD                   : in  std_logic; -- Todo
      I_DOWN_MOD                 : in  std_logic; -- Todo
      I_LEFT_MOD                 : in  std_logic; -- Todo
      I_RIGHT_MOD                : in  std_logic; -- Todo
      O_STICK_X                  : out std_logic_vector(7 downto 0);
      O_STICK_Y                  : out std_logic_vector(7 downto 0)
   );
end entity STICK_HANDLER_1_0;

architecture STICK_HANDLER_1_0_ARCH of STICK_HANDLER_1_0 is

   signal stick_x : std_logic_vector(7 downto 0);
   signal stick_y : std_logic_vector(7 downto 0);
   
   signal left_right_priority : std_logic_vector(1 downto 0);
   signal left_button         : std_logic;
   signal right_button        : std_logic;

begin

   -------------------------------------------------------------------------------
   -- Process     : Stick_Mux
   -- Description : Muxes between different 8 bit X/Y output based on directional
   --                and modifier button states.
   -------------------------------------------------------------------------------
   Stick_Mux : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         left_button    <= I_LEFT;
         right_button   <= I_RIGHT;
         if (I_LEFT = '0' or I_RIGHT = '0') then
            left_right_priority <= "00";
         end if;
         if (I_LEFT = '1' and I_RIGHT = '1') then
            if (left_button = '0') then
               left_right_priority <= "10";
            end if;
            if (right_button = '0') then
               left_right_priority <= "01";
            end if;
         end if;
         stick_x   <= G_STICK_NEUTRAL;
         stick_y   <= G_STICK_NEUTRAL;
         if (I_UP = '1') then
            stick_y <= G_MAX_Y_VALUE;
            if (I_TILT_MODIFIER = '1') then
               stick_y <= G_TILT_Y_VALUE;
            end if;
         end if;
         if (I_DOWN = '1') then
            stick_y <= G_MIN_Y_VALUE;
            if (I_TILT_MODIFIER = '1') then
               stick_y <= G_TILT_Y_VALUE_NEG;
            end if;
         end if;
         if (I_LEFT = '1' and left_right_priority /= "01") then
            stick_x <= G_MIN_X_VALUE;
            if (I_TILT_MODIFIER = '1') then
               stick_x <= G_TILT_X_VALUE_NEG;
            end if;
            if (I_X_MODIFIER = '1') then
               stick_x <= G_MOD_X_VALUE_NEG;
            end if;
         end if;
         if (I_RIGHT = '1' and left_right_priority /= "10") then
            stick_x <= G_MAX_X_VALUE;
            if (I_TILT_MODIFIER = '1') then
               stick_x <= G_TILT_X_VALUE;
            end if;
            if (I_X_MODIFIER = '1') then
               stick_x <= G_MOD_X_VALUE;
            end if;
         end if;
      end if;
   end process Stick_Mux;

   -- Gamecube protocol is reverse endianess so we're just swapping it here.
   O_STICK_X(0)  <= stick_x(7);
   O_STICK_X(1)  <= stick_x(6);
   O_STICK_X(2)  <= stick_x(5);
   O_STICK_X(3)  <= stick_x(4);
   O_STICK_X(4)  <= stick_x(3);
   O_STICK_X(5)  <= stick_x(2);
   O_STICK_X(6)  <= stick_x(1);
   O_STICK_X(7)  <= stick_x(0);

   O_STICK_Y(0)  <= stick_y(7);
   O_STICK_Y(1)  <= stick_y(6);
   O_STICK_Y(2)  <= stick_y(5);
   O_STICK_Y(3)  <= stick_y(4);
   O_STICK_Y(4)  <= stick_y(3);
   O_STICK_Y(5)  <= stick_y(2);
   O_STICK_Y(6)  <= stick_y(1);
   O_STICK_Y(7)  <= stick_y(0);

end architecture STICK_HANDLER_1_0_ARCH;
