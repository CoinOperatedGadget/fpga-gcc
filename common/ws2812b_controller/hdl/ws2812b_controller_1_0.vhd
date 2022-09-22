-------------------------------------------------------------------------------
-- Title       : WS2812b Controller
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description : 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity WS2812B_CONTROLLER_1_0 is
   generic(
      G_CYCLES_PER_0_4_US        : positive  := 5;
      G_NUM_LEDS                 : natural   := 1
   );
   port(
      I_CLK                      : in  std_logic;
      I_RST                      : in  std_logic;
      I_GO                       : in  std_logic;
      O_CONTROL                  : out std_logic
   );
end entity WS2812B_CONTROLLER_1_0;

architecture WS2812B_CONTROLLER_1_0_ARCH of WS2812B_CONTROLLER_1_0 is
   -- Goes "BBRRGG"
   constant C_RGB_VALUE : std_logic_vector(23 downto 0) := x"FF00FF";
   
   signal rgb_counter : unsigned(23 downto 0);
   signal rgb_value   : unsigned(23 downto 0);

   signal go_d : std_logic;
   signal send_in_progress : std_logic;
   signal led_count  : unsigned(7 downto 0);
   signal bit_count  : unsigned(4 downto 0);
   signal signal_count  : unsigned(15 downto 0);
   
   signal last_bit   : std_logic;
   signal last_led   : std_logic;

begin

   Send_Colors : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         rgb_counter <= rgb_counter +1;
         O_CONTROL   <= '0';
         last_bit    <= '0';
         last_led    <= '0';
         go_d        <= I_GO;
         if (I_GO = '1' and go_d = '0') then
            rgb_value <= rgb_counter;
            send_in_progress <= '1';
            led_count <= (others => '0');
            bit_count <= (others => '0');
         end if;
         if (send_in_progress = '1') then
            signal_count <= signal_count + 1;
            if (C_RGB_VALUE(to_integer(bit_count)) = '0') then
            -- if (rgb_value(to_integer(bit_count)) = '0') then
               if (signal_count < G_CYCLES_PER_0_4_US) then
                  O_CONTROL <= '1';
               end if;
            end if;
            if (C_RGB_VALUE(to_integer(bit_count)) = '1') then
            -- if (rgb_value(to_integer(bit_count)) = '1') then
               if (signal_count < G_CYCLES_PER_0_4_US*2) then
                  O_CONTROL <= '1';
               end if;
            end if;
            if (signal_count = G_CYCLES_PER_0_4_US*3) then
               signal_count   <= (others => '0');
               bit_count      <= bit_count + 1;
               if (last_bit = '1') then
                  bit_count <= (others => '0');
                  led_count <= led_count + 1;
                  if (last_led = '1') then
                     send_in_progress <= '0';
                  end if;
               end if;
            end if;
            if (bit_count = 23) then
               last_bit <= '1';
            end if;
            if (led_count = G_NUM_LEDS-1) then
               last_led <= '1';
            end if;
         end if;
      end if;
   end process Send_Colors;

end architecture WS2812B_CONTROLLER_1_0_ARCH;
