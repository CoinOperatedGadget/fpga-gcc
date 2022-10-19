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
      I_CENTER                   : in  std_logic;
      I_RIGHT_CLUSTER            : in  std_logic_vector(7 downto 0);
      I_RIGHT_THUMB_UP           : in  std_logic;
      I_RIGHT_THUMB_DOWN         : in  std_logic;
      I_RIGHT_THUMB_LEFT         : in  std_logic;
      I_RIGHT_THUMB_RIGHT        : in  std_logic;
      I_RIGHT_THUMB_CENTER       : in  std_logic;
      I_WASD_MOD                 : in  std_logic;
      I_WASD_UP                  : in  std_logic;
      I_WASD_DOWN                : in  std_logic;
      I_WASD_LEFT                : in  std_logic;
      I_WASD_RIGHT               : in  std_logic;
      I_LEFT_THUMB_MOD_0         : in  std_logic;
      I_LEFT_THUMB_MOD_1         : in  std_logic;
      O_LED_CONTROL              : out std_logic;
      O_USB_DP                   : out std_logic;
      O_USB_DM                   : out std_logic;
      O_LED                      : out std_logic
   );
end entity TOP_LEVEL;

architecture TOP_LEVEL_ARCH of TOP_LEVEL is

   constant C_LED_COUNT_INTERVAL    : positive := 12000000;
   signal led_count                 : unsigned(31 downto 0);
   signal clk_12                    : std_logic;
   signal clk_27_bufg               : std_logic;
   signal rst_125_d0                : std_logic;
   signal rst_125_d1                : std_logic;
   signal rst_125                   : std_logic;

   signal gcc_control_in_prereg     : std_logic;
   signal gcc_control_in            : std_logic;
   signal gcc_control_out           : std_logic;
   signal gcc_control_out_en        : std_logic;
   signal gcc_control_out_prereg    : std_logic;
   signal gcc_control_out_en_prereg : std_logic;

   -- Registered raw button presses
   signal center_button             : std_logic;
   signal right_thumb_up            : std_logic;
   signal right_thumb_down          : std_logic;
   signal right_thumb_left          : std_logic;
   signal right_thumb_right         : std_logic;
   signal right_thumb_center        : std_logic;
   signal wasd_mod                  : std_logic;
   signal wasd_up                   : std_logic;
   signal wasd_down                 : std_logic;
   signal wasd_left                 : std_logic;
   signal wasd_right                : std_logic;
   signal left_thumb_mod_0          : std_logic;
   signal left_thumb_mod_1          : std_logic;
   signal right_cluster             : std_logic_vector(7 downto 0);

   -- Muxed buttons
   signal a_button                  : std_logic;
   signal b_button                  : std_logic;
   signal x_button                  : std_logic;
   signal y_button                  : std_logic;
   signal l_button                  : std_logic;
   signal r_button                  : std_logic;
   signal z_button                  : std_logic;
   signal start_button              : std_logic;
   signal left_stick_up             : std_logic;
   signal left_stick_down           : std_logic;
   signal left_stick_left           : std_logic;
   signal left_stick_right          : std_logic;
   signal c_stick_up                : std_logic;
   signal c_stick_down              : std_logic;
   signal c_stick_left              : std_logic;
   signal c_stick_right             : std_logic;
   signal mod_tilt                  : std_logic;
   signal mod_x                     : std_logic;
   signal mod_y                     : std_logic;
   signal mod_trig_0                : std_logic;
   signal mod_trig_1                : std_logic;

   signal left_stick_x              : std_logic_vector(7 downto 0);
   signal left_stick_y              : std_logic_vector(7 downto 0);
   signal c_stick_x                 : std_logic_vector(7 downto 0);
   signal c_stick_y                 : std_logic_vector(7 downto 0);

   signal gcc_control               : std_logic;

   signal led_control               : std_logic;

   signal configure_leds            : std_logic;
   signal configure_leds_done       : std_logic;

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

   Input_Handler : entity work.INPUT_HANDLER_1_0
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,

         I_CENTER_BUTTON            => I_CENTER,

         I_RIGHT_THUMB_UP           => I_RIGHT_THUMB_UP,
         I_RIGHT_THUMB_DOWN         => I_RIGHT_THUMB_DOWN,
         I_RIGHT_THUMB_LEFT         => I_RIGHT_THUMB_LEFT,
         I_RIGHT_THUMB_RIGHT        => I_RIGHT_THUMB_RIGHT,
         I_RIGHT_THUMB_CENTER       => I_RIGHT_THUMB_CENTER,

         I_WASD_MOD                 => I_WASD_MOD,
         I_WASD_UP                  => I_WASD_UP,
         I_WASD_DOWN                => I_WASD_DOWN,
         I_WASD_LEFT                => I_WASD_LEFT,
         I_WASD_RIGHT               => I_WASD_RIGHT,

         I_LEFT_THUMB_MOD_0         => I_LEFT_THUMB_MOD_0,
         I_LEFT_THUMB_MOD_1         => I_LEFT_THUMB_MOD_1,

         I_RIGHT_CLUSTER            => I_RIGHT_CLUSTER,

         O_CENTER_BUTTON            => center_button,

         O_RIGHT_THUMB_UP           => right_thumb_up,
         O_RIGHT_THUMB_DOWN         => right_thumb_down,
         O_RIGHT_THUMB_LEFT         => right_thumb_left,
         O_RIGHT_THUMB_RIGHT        => right_thumb_right,
         O_RIGHT_THUMB_CENTER       => right_thumb_center,

         O_WASD_MOD                 => wasd_mod,
         O_WASD_UP                  => wasd_up,
         O_WASD_DOWN                => wasd_down,
         O_WASD_LEFT                => wasd_left,
         O_WASD_RIGHT               => wasd_right,

         O_LEFT_THUMB_MOD_0         => left_thumb_mod_0,
         O_LEFT_THUMB_MOD_1         => left_thumb_mod_1,

         O_RIGHT_CLUSTER            => right_cluster,

         O_A_BUTTON                 => a_button,
         O_B_BUTTON                 => b_button,
         O_X_BUTTON                 => x_button,
         O_Y_BUTTON                 => y_button,

         O_L_BUTTON                 => l_button,
         O_R_BUTTON                 => r_button,
         O_Z_BUTTON                 => z_button,

         O_START_BUTTON             => start_button,

         O_LEFT_STICK_UP            => left_stick_up,
         O_LEFT_STICK_DOWN          => left_stick_down,
         O_LEFT_STICK_LEFT          => left_stick_left,
         O_LEFT_STICK_RIGHT         => left_stick_right,

         O_C_STICK_UP               => c_stick_up,
         O_C_STICK_DOWN             => c_stick_down,
         O_C_STICK_LEFT             => c_stick_left,
         O_C_STICK_RIGHT            => c_stick_right,

         O_MOD_TILT                 => mod_tilt,
         O_MOD_X                    => mod_x,
         O_MOD_Y                    => mod_y,
         O_MOD_TRIG_0               => mod_trig_0,
         O_MOD_TRIG_1               => mod_trig_1,

         I_CONFIGURE_LEDS_DONE      => configure_leds_done,
         O_CONFIGURE_LEDS           => configure_leds
      );

   Left_Stick_Handler : entity work.STICK_HANDLER_1_0
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,
         I_UP                       => not left_stick_up   ,
         I_DOWN                     => not left_stick_down ,
         I_LEFT                     => not left_stick_left ,
         I_RIGHT                    => not left_stick_right,
         I_TILT_MODIFIER            => not mod_tilt,
         I_X_MODIFIER               => '0',
         I_Y_MODIFIER               => '0',
         I_UP_MOD                   => '0',
         I_DOWN_MOD                 => '0',
         I_LEFT_MOD                 => '0',
         I_RIGHT_MOD                => '0',
         O_STICK_X                  => left_stick_x,
         O_STICK_Y                  => left_stick_y
      );

   C_Stick_Handler : entity work.STICK_HANDLER_1_0
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,
         I_UP                       => not c_stick_up   ,
         I_DOWN                     => not c_stick_down ,
         I_LEFT                     => not c_stick_left ,
         I_RIGHT                    => not c_stick_right,
         I_TILT_MODIFIER            => '0',
         I_X_MODIFIER               => '0',
         I_Y_MODIFIER               => '0',
         I_UP_MOD                   => '0',
         I_DOWN_MOD                 => '0',
         I_LEFT_MOD                 => '0',
         I_RIGHT_MOD                => '0',
         O_STICK_X                  => c_stick_x,
         O_STICK_Y                  => c_stick_y
      );

   Gcc_Controller : entity work.GCC_CONTROLLER_1_0
      generic map(
         G_CYCLES_PER_US            => 12
         -- G_CYCLE_SLOP               : positive        := G_CYCLES_PER_US/4
      )
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,
         I_DISABLE                  => configure_leds,
         I_START_BUTTON             => not start_button,
         I_A_BUTTON                 => not a_button,
         I_B_BUTTON                 => not b_button,
         I_X_BUTTON                 => not x_button,
         I_Y_BUTTON                 => not y_button,
         I_Z_BUTTON                 => not z_button,
         I_L_BUTTON                 => not l_button,
         I_R_BUTTON                 => not r_button,
         I_D_PAD_UP                 => '0',
         I_D_PAD_DOWN               => '0',
         I_D_PAD_LEFT               => '0',
         I_D_PAD_RIGHT              => '0',
         I_RIGHT_STICK_X            => c_stick_x,
         I_RIGHT_STICK_Y            => c_stick_y,
         I_LEFT_STICK_X             => left_stick_x,
         I_LEFT_STICK_Y             => left_stick_y,
         I_L_ANALOGUE               => (others => not l_button),
         I_R_ANALOGUE               => (others => not r_button),
         O_RUMBLE                   => open,
         I_CONTROL                  => gcc_control_in,
         O_CONTROL                  => gcc_control_out_prereg,
         O_VALID                    => gcc_control_out_en_prereg
      );

   -- LED_Controller : entity work.WS2812B_CONTROLLER_1_0
      -- generic map(
         -- G_CYCLES_PER_0_4_US        => 4,
         -- G_NUM_LEDS                 => 21
      -- )
      -- port map(
         -- I_CLK                      => clk_12,
         -- I_RST                      => not I_RST_N,
         -- I_GO                       => not start_button,
         -- O_CONTROL                  => led_control
      -- );

   LED_Controller : entity work.LED_CONTROLLER_1_0
      generic map(
         G_CYCLES_PER_1_S           => 48_000_00,
         G_UPDATE_PERIOD            => 1_2000
      )
      port map(
         I_CLK                      => clk_12,
         I_RST                      => not I_RST_N,

         -- Configuration Ports
         I_CONFIGURE_MODE           => configure_leds,
         I_CENTER_BUTTON            => center_button,
         I_RIGHT_THUMB_UP           => right_thumb_up,
         I_RIGHT_THUMB_DOWN         => right_thumb_down,
         I_RIGHT_THUMB_LEFT         => right_thumb_left,
         I_RIGHT_THUMB_RIGHT        => right_thumb_right, 
         I_RIGHT_THUMB_CENTER       => right_thumb_center,
         I_WASD_MOD                 => wasd_mod,
         I_WASD_UP                  => wasd_up,
         I_WASD_DOWN                => wasd_down,
         I_WASD_LEFT                => wasd_left,
         I_WASD_RIGHT               => wasd_right,
         I_LEFT_THUMB_MOD_0         => left_thumb_mod_0,
         I_LEFT_THUMB_MOD_1         => left_thumb_mod_1,
         I_RIGHT_CLUSTER            => right_cluster,
         O_CONFIGURE_DONE           => configure_leds_done,

         O_CONTROL                  => led_control
      );

   Register_Outputs : process(clk_12)
   begin
      if rising_edge(clk_12) then
         -- Outputs
         gcc_control_in       <= gcc_control_in_prereg;
         gcc_control_out      <= gcc_control_out_prereg;
         gcc_control_out_en   <= gcc_control_out_en_prereg;
         O_LED_CONTROL        <= led_control;
      end if;
   end process Register_Outputs;


end architecture TOP_LEVEL_ARCH;
