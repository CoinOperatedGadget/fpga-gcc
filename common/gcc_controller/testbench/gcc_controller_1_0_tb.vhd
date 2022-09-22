-------------------------------------------------------------------------------
-- Title       : GCC Controller Testbench
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description :
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity GCC_CONTROLLER_1_0_TB is
end entity GCC_CONTROLLER_1_0_TB;

architecture GCC_CONTROLLER_1_0_TB_ARCH of GCC_CONTROLLER_1_0_TB is

   constant C_CONTROLLER_PROBE_COMMAND : std_logic_vector(23 downto 0) := x"00_00_00";

   signal control : std_logic;
   signal clk     : std_logic;
   signal rst     : std_logic;



   procedure send_low_bit (signal c : out std_logic) is
   begin
      -- Low Bit Send
      c <= '0';
      wait for 3 us;
      c <= '1';
      wait for 1 us;
   end procedure;

   procedure send_high_bit (signal c : out std_logic) is
   begin
      -- Low Bit Send
      c <= '0';
      wait for 1 us;
      c <= '1';
      wait for 3 us;
   end procedure;

   procedure send_stop_bit (signal c : out std_logic) is
   begin
      -- Low Bit Send
      c <= '0';
      wait for 1 us;
      c <= '1';
      wait for 2 us;
   end procedure;

begin

   Clk_Stim : process
   begin
      clk <= '0';
      wait for 4 ns;
      clk <= '1';
      wait for 4 ns;
   end process Clk_Stim;

   Rst_Stim : process
   begin
      rst <= '1';
      wait for 10 us;
      rst <= '0';
      wait;
   end process Rst_Stim;

   uut0 : entity work.GCC_CONTROLLER_1_0
      generic map(
         G_CYCLES_PER_US            => 125
      )
      port map(
         I_CLK                      => clk,
         I_RST                      => rst,
         I_START_BUTTON             => '0',
         I_A_BUTTON                 => '0',
         I_B_BUTTON                 => '0',
         I_X_BUTTON                 => '0',
         I_Y_BUTTON                 => '0',
         I_Z_BUTTON                 => '0',
         I_L_BUTTON                 => '0',
         I_R_BUTTON                 => '0',
         I_D_PAD_UP                 => '0',
         I_D_PAD_DOWN               => '0',
         I_D_PAD_LEFT               => '0',
         I_D_PAD_RIGHT              => '0',
         I_RIGHT_STICK_X            => (others => '0'),
         I_RIGHT_STICK_Y            => (others => '0'),
         I_LEFT_STICK_X             => (others => '0'),
         I_LEFT_STICK_Y             => (others => '0'),
         I_L_ANALOGUE               => (others => '0'),
         I_R_ANALOGUE               => (others => '0'),
         O_RUMBLE                   => open,
         I_CONTROL                  => control,
         O_CONTROL                  => open,
         O_VALID                    => open
      );

   Control_Stim : process
   begin
      control <= '1';
      wait until rst = '0';
      wait for 1 us;
      wait until rising_edge(clk);
      -- Send 0x00 command
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_stop_bit(control);
      wait for 200 us;
      -- Send 0x40
      send_low_bit(control);
      send_high_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      -- Send 0x03
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_high_bit(control);
      send_high_bit(control);
      -- Send 0x02
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_low_bit(control);
      send_high_bit(control);
      send_low_bit(control);
      send_stop_bit(control);
      wait for 40 us;
      wait;
   end process Control_Stim;

end architecture GCC_CONTROLLER_1_0_TB_ARCH;
