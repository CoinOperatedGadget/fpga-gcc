-------------------------------------------------------------------------------
-- Title         : FPGA GCC Tang Nano 4k Top Level
-- Author        : Gadget
-------------------------------------------------------------------------------
-- Description   : 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity TOP_LEVEL is
   generic(
      G_PLACEHOLDER              : positive                := 32
   );
   port(
      I_CLK_27_MHZ               : in  std_logic;
      I_RST_N                    : in  std_logic;
      IO_CONTROL                 : inout std_logic;
      I_START_BUTTON             : in  std_logic;
      I_A_BUTTON                 : in  std_logic;
      I_B_BUTTON                 : in  std_logic;
      I_X_BUTTON                 : in  std_logic;
      I_Y_BUTTON                 : in  std_logic;
      I_Z_BUTTON                 : in  std_logic;
      I_L_BUTTON                 : in  std_logic;
      I_R_BUTTON                 : in  std_logic;
      I_D_PAD_UP                 : in  std_logic;
      I_D_PAD_DOWN               : in  std_logic;
      I_D_PAD_LEFT               : in  std_logic;
      I_D_PAD_RIGHT              : in  std_logic;
      I_LEFT_STICK_UP            : in  std_logic;
      I_LEFT_STICK_DOWN          : in  std_logic;
      I_LEFT_STICK_LEFT          : in  std_logic;
      I_LEFT_STICK_RIGHT         : in  std_logic;
      I_C_STICK_UP               : in  std_logic;
      I_C_STICK_DOWN             : in  std_logic;
      I_C_STICK_LEFT             : in  std_logic;
      I_C_STICK_RIGHT            : in  std_logic;
      O_LED_CONTROL              : out std_logic;
      O_LED                      : out std_logic
   );
end entity TOP_LEVEL;

architecture TOP_LEVEL_ARCH of TOP_LEVEL is

   constant C_LED_COUNT_INTERVAL : positive := 12000000;
   signal led_count              : unsigned(31 downto 0);
   signal clk_12                 : std_logic;
   signal clk_27_bufg            : std_logic;
   signal rst_125_d0             : std_logic;
   signal rst_125_d1             : std_logic;
   signal rst_125                : std_logic;

   signal gcc_control_in_prereg         : std_logic;
   signal gcc_control_in         : std_logic;
   signal gcc_control_out        : std_logic;
   signal gcc_control_out_en     : std_logic;
   signal gcc_control_out_prereg        : std_logic;
   signal gcc_control_out_en_prereg     : std_logic;

   signal start_button           : std_logic;
   signal a_button               : std_logic;
   signal b_button               : std_logic;
   signal x_button               : std_logic;
   signal y_button               : std_logic;
   signal z_button               : std_logic;
   signal l_button               : std_logic;
   signal r_button               : std_logic;
   signal d_pad_up               : std_logic;
   signal d_pad_down             : std_logic;
   signal d_pad_left             : std_logic;
   signal d_pad_right            : std_logic;
   signal left_stick_up          : std_logic;
   signal left_stick_down        : std_logic;
   signal left_stick_left        : std_logic;
   signal left_stick_right       : std_logic;
   signal c_stick_up             : std_logic;
   signal c_stick_down           : std_logic;
   signal c_stick_left           : std_logic;
   signal c_stick_right          : std_logic;
   
   signal left_stick_x           : std_logic_vector(7 downto 0);
   signal left_stick_y           : std_logic_vector(7 downto 0);

   signal gcc_control            : std_logic;
   
   signal led_control            : std_logic;

   component Gowin_EMPU_Top
      port (
         sys_clk: in std_logic;
         gpio: inout std_logic_vector(15 downto 0);
         reset_n: in std_logic
      );
   end component;

   component Gowin_PLLVR
      port (
         clkout: out std_logic;
         clkin: in std_logic
      );
   end component;

   component IOBUF
      port (
         o:out std_logic;
         io:inout std_logic;
         i:in std_logic;
         oen:in std_logic
      );
   end component;
   component bufg
      port(
         o:out std_logic;
         i:in std_logic
      );
   end component;

begin

   -----------------------------------------------------------------------------
   -- Process:       LED_Counter
   -- Description:
   -----------------------------------------------------------------------------
   Led_Counter : process(clk_12)
   begin
      if rising_edge(clk_12) then
         led_count <= led_count + 1;
         if (led_count = C_LED_COUNT_INTERVAL) then
            O_LED     <= not O_LED;
            led_count <= (others => '0');
         end if;
         if (I_RST_N = '0') then
            led_count <= (others => '0');
            O_LED <= '0';
         end if;
      end if;
   end process Led_Counter;

   -- ARM : Gowin_EMPU_Top
      -- port map (
         -- sys_clk => I_CLK_27_MHZ,
         -- gpio    => open,
         -- reset_n => I_RST_N
      -- );

   Sys_Clk_Pll : Gowin_PLLVR
      port map (
         clkout => clk_12,
         clkin => clk_27_bufg
      );

   Clock_Buff : BUFG
   port map(
      o => clk_27_bufg,
      i => I_CLK_27_MHZ
   );

   Gcc_IOBUF : IOBUF
      port map(
         o     => gcc_control_in_prereg,
         io    => IO_CONTROL,
         i     => gcc_control_out,
         oen   => not gcc_control_out_en
      );

   Register_Inputs : process(clk_12)
   begin
      if rising_edge(clk_12) then
         start_button      <= I_START_BUTTON;
         a_button          <= I_A_BUTTON;
         -- b_button          <= I_B_BUTTON;
         b_button          <= I_LEFT_STICK_RIGHT;
         x_button          <= I_X_BUTTON;
         y_button          <= I_Y_BUTTON;
         z_button          <= I_Z_BUTTON;
         l_button          <= I_L_BUTTON;
         r_button          <= I_R_BUTTON;
         d_pad_up          <= I_D_PAD_UP;
         d_pad_down        <= I_D_PAD_DOWN;
         d_pad_left        <= I_D_PAD_LEFT;
         d_pad_right       <= I_D_PAD_RIGHT;
         left_stick_up     <= I_LEFT_STICK_UP;
         left_stick_down   <= I_LEFT_STICK_DOWN;
         left_stick_left   <= I_LEFT_STICK_LEFT;
         -- left_stick_right  <= I_LEFT_STICK_RIGHT;
         left_stick_right  <= I_B_BUTTON;
         c_stick_up        <= I_C_STICK_UP;
         c_stick_down      <= I_C_STICK_DOWN;
         c_stick_left      <= I_C_STICK_LEFT;
         c_stick_right     <= I_C_STICK_RIGHT;
         gcc_control_in    <= gcc_control_in_prereg;
         gcc_control_out   <= gcc_control_out_prereg;
         gcc_control_out_en   <= gcc_control_out_en_prereg;
         O_LED_CONTROL     <= led_control;
      end if;
   end process Register_Inputs;
   
   Left_Stick_Handler : entity work.STICK_HANDLER_1_0
   port map(
      I_CLK                      => clk_12,
      I_RST                      => not I_RST_N,
      I_UP                       => not left_stick_up   ,
      I_DOWN                     => not left_stick_down ,
      I_LEFT                     => not left_stick_left ,
      I_RIGHT                    => not left_stick_right,
      I_TILT_MODIFIER            => '0',
      I_X_MODIFIER               => '0',
      I_Y_MODIFIER               => '0',
      I_UP_MOD                   => '0',
      I_DOWN_MOD                 => '0',
      I_LEFT_MOD                 => '0',
      I_RIGHT_MOD                => '0',
      O_STICK_X                  => left_stick_x,
      O_STICK_Y                  => left_stick_y
   );

   Gcc_Controller : entity work.GCC_CONTROLLER_1_0
   generic map(
      G_CYCLES_PER_US            => 12
      -- G_CYCLE_SLOP               : positive        := G_CYCLES_PER_US/4
   )
   port map(
      I_CLK                      => clk_12,
      I_RST                      => not I_RST_N,
      I_START_BUTTON             => not start_button,
      I_A_BUTTON                 => not a_button,
      I_B_BUTTON                 => not b_button,
      I_X_BUTTON                 => not x_button,
      I_Y_BUTTON                 => not y_button,
      I_Z_BUTTON                 => not z_button,
      I_L_BUTTON                 => not l_button,
      I_R_BUTTON                 => not r_button,
      I_D_PAD_UP                 => not d_pad_up,
      I_D_PAD_DOWN               => not d_pad_down,
      I_D_PAD_LEFT               => not d_pad_left,
      I_D_PAD_RIGHT              => not d_pad_right,
      I_RIGHT_STICK_X            => x"80",
      I_RIGHT_STICK_Y            => x"80",
      I_LEFT_STICK_X             => left_stick_x,
      I_LEFT_STICK_Y             => left_stick_y,
      I_L_ANALOGUE               => (others => '0'),
      I_R_ANALOGUE               => (others => '0'),
      O_RUMBLE                   => open,
      I_CONTROL                  => gcc_control_in,
      O_CONTROL                  => gcc_control_out_prereg,
      O_VALID                    => gcc_control_out_en_prereg
   );
   
   LED_Controller : entity work.WS2812B_CONTROLLER_1_0
      generic map(
         G_CYCLES_PER_0_4_US        => 5,
         G_NUM_LEDS                 => 2
      )
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,
         I_GO                       => not a_button,
         O_CONTROL                  => led_control
      );

end architecture TOP_LEVEL_ARCH;
