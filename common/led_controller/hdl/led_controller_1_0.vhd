-------------------------------------------------------------------------------
-- Title       : LED Controller
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description :
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity LED_CONTROLLER_1_0 is
   generic(
      G_CYCLES_PER_1_S           : natural   := 12_000_000;
      G_UPDATE_PERIOD            : natural   := 12_000
   );
   port(
      I_CLK                      : in  std_logic;
      I_RST                      : in  std_logic;

      -- Configuration Ports
      I_CONFIGURE_MODE           : in  std_logic;
      I_CENTER_BUTTON            : in  std_logic;
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
      I_RIGHT_CLUSTER            : in  std_logic_vector(7 downto 0);
      O_CONFIGURE_DONE           : out std_logic;

      O_CONTROL                  : out std_logic
   );
end entity LED_CONTROLLER_1_0;

architecture LED_CONTROLLER_1_0_ARCH of LED_CONTROLLER_1_0 is

   -- LED Map
   constant C_NUM_LEDS                 : natural := 21;
   constant C_CENTER_BUTTON_LED        : natural := 7;
   constant C_RIGHT_THUMB_UP_LED       : natural := 12;
   constant C_RIGHT_THUMB_DOWN_LED     : natural := 8;
   constant C_RIGHT_THUMB_LEFT_LED     : natural := 11;
   constant C_RIGHT_THUMB_RIGHT_LED    : natural := 10;
   constant C_RIGHT_THUMB_CENTER_LED   : natural := 9;
   constant C_WASD_MOD_LED             : natural := 1;
   constant C_WASD_UP_LED              : natural := 0;
   constant C_WASD_DOWN_LED            : natural := 3;
   constant C_WASD_LEFT_LED            : natural := 2;
   constant C_WASD_RIGHT_LED           : natural := 4;
   constant C_LEFT_THUMB_MOD_0_LED     : natural := 5;
   constant C_LEFT_THUMB_MOD_1_LED     : natural := 6;
   constant C_RIGHT_CLUSTER_0_LED      : natural := 13;
   constant C_RIGHT_CLUSTER_1_LED      : natural := 14;
   constant C_RIGHT_CLUSTER_2_LED      : natural := 15;
   constant C_RIGHT_CLUSTER_3_LED      : natural := 16;
   constant C_RIGHT_CLUSTER_4_LED      : natural := 17;
   constant C_RIGHT_CLUSTER_5_LED      : natural := 18;
   constant C_RIGHT_CLUSTER_6_LED      : natural := 19;
   constant C_RIGHT_CLUSTER_7_LED      : natural := 20;
   
   constant C_R_SEL                    : std_logic_vector(1 downto 0) := "01";
   constant C_G_SEL                    : std_logic_vector(1 downto 0) := "10";
   constant C_B_SEL                    : std_logic_vector(1 downto 0) := "11";

   type T_LED_CONFIGURE_FSM is (
      S_IDLE,
      S_CHOOSE_BUTTON,
      S_CHOOSE_COLOR,
      S_END_CONFIGURE
   );

   signal led_configure_fsm : T_LED_CONFIGURE_FSM;

   type led_array is array (C_NUM_LEDS-1 downto 0) of std_logic_vector(23 downto 0);
   signal led_color_mem : led_array  := (
      C_CENTER_BUTTON_LED        => x"FFFFFF",
      C_RIGHT_THUMB_UP_LED       => x"00FFFF",
      C_RIGHT_THUMB_DOWN_LED     => x"00FFFF",
      C_RIGHT_THUMB_LEFT_LED     => x"00FFFF",
      C_RIGHT_THUMB_RIGHT_LED    => x"00FFFF",
      C_RIGHT_THUMB_CENTER_LED   => x"0000FF",
      C_WASD_MOD_LED             => x"FFFF00",
      C_WASD_UP_LED              => x"FFFFFF",
      C_WASD_DOWN_LED            => x"FFFFFF",
      C_WASD_LEFT_LED            => x"FFFFFF",
      C_WASD_RIGHT_LED           => x"FFFFFF",
      C_LEFT_THUMB_MOD_0_LED     => x"FFFF00",
      C_LEFT_THUMB_MOD_1_LED     => x"FFFF00",
      C_RIGHT_CLUSTER_0_LED      => x"FF0000",
      C_RIGHT_CLUSTER_1_LED      => x"FF00FF",
      C_RIGHT_CLUSTER_2_LED      => x"00FF00",
      C_RIGHT_CLUSTER_3_LED      => x"FFFF00",
      C_RIGHT_CLUSTER_4_LED      => x"FFFFFF",
      C_RIGHT_CLUSTER_5_LED      => x"FF00FF",
      C_RIGHT_CLUSTER_6_LED      => x"FFFFFF",
      C_RIGHT_CLUSTER_7_LED      => x"FFFF00"
      );
      
   signal led_color_sel_rom : led_array  := (
      C_CENTER_BUTTON_LED        => x"FFFFFF",
      C_RIGHT_THUMB_UP_LED       => x"000000",
      C_RIGHT_THUMB_DOWN_LED     => x"000000",
      C_RIGHT_THUMB_LEFT_LED     => x"000000",
      C_RIGHT_THUMB_RIGHT_LED    => x"000000",
      C_RIGHT_THUMB_CENTER_LED   => x"000000",
      C_WASD_MOD_LED             => x"000000",
      C_WASD_UP_LED              => x"000000",
      C_WASD_DOWN_LED            => x"0000FF",
      C_WASD_LEFT_LED            => x"00FF00",
      C_WASD_RIGHT_LED           => x"FF0000",
      C_LEFT_THUMB_MOD_0_LED     => x"000000",
      C_LEFT_THUMB_MOD_1_LED     => x"000000",
      C_RIGHT_CLUSTER_0_LED      => x"000000",
      C_RIGHT_CLUSTER_1_LED      => x"000000",
      C_RIGHT_CLUSTER_2_LED      => x"000000",
      C_RIGHT_CLUSTER_3_LED      => x"000000",
      C_RIGHT_CLUSTER_4_LED      => x"000000",
      C_RIGHT_CLUSTER_5_LED      => x"000000",
      C_RIGHT_CLUSTER_6_LED      => x"000000",
      C_RIGHT_CLUSTER_7_LED      => x"000000"
      );

   signal led_button_fe          : std_logic_vector(20 downto 0);

   signal blink_mode             : std_logic;
   signal waiting_for_led_sel    : std_logic;
   signal led_selected_valid     : std_logic;
   signal led_selected           : std_logic_vector(4 downto 0);
   signal waiting_for_color_sel  : std_logic;

   signal color_out              : std_logic_vector(23 downto 0);
   signal current_led            : unsigned(7 downto 0);
   
   signal blink_count            : unsigned(31 downto 0);
   signal blink                  : std_logic;
   
   signal update_count           : unsigned(31 downto 0);
   signal update_leds            : std_logic;
   
   signal color_to_change        : std_logic_vector(23 downto 0);
   alias color_to_change_r       : std_logic_vector(7 downto 0) is color_to_change(15 downto 8);
   alias color_to_change_g       : std_logic_vector(7 downto 0) is color_to_change(7 downto 0);
   alias color_to_change_b       : std_logic_vector(7 downto 0) is color_to_change(23 downto 16);
   
   signal rgb_sel                : std_logic_vector(1 downto 0);

begin

   -------------------------------------------------------------------------------
   -- Process     : FSM
   -- Description : Main FSM of emulator.  Waits in Idle until configure mode
   --                is entered.
   -------------------------------------------------------------------------------
   FSM : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         O_CONFIGURE_DONE        <= '0';
         blink_mode              <= '0';
         waiting_for_led_sel     <= '0';
         waiting_for_color_sel   <= '0';
         case led_configure_fsm is
            -- Idle, we'll probably spend most of our time here waiting for configure mode.
            when S_IDLE =>
               if (I_CONFIGURE_MODE = '1') then
                  led_configure_fsm <= S_CHOOSE_BUTTON;
               end if;
            -- Here we choose a button to edit
            when S_CHOOSE_BUTTON =>
               blink_mode           <= '1';
               waiting_for_led_sel  <= '1';
               if (led_selected_valid = '1') then
                  led_configure_fsm <= S_CHOOSE_COLOR;
               end if;
            -- Configure color for the button
            when S_CHOOSE_COLOR =>
               waiting_for_color_sel   <= '1';
               if (led_button_fe(C_CENTER_BUTTON_LED) = '1') then
                  led_configure_fsm <= S_END_CONFIGURE;
               end if;
            -- State to wait for configure mode to be disabled in input handler.
            when S_END_CONFIGURE =>
               -- Activate handshake signal
               O_CONFIGURE_DONE <= '1';
               -- Go back to idle when we're out of configuration mode.
               if (I_CONFIGURE_MODE = '0') then
                  led_configure_fsm <= S_IDLE;
               end if;
            when others =>
               led_configure_fsm <= S_IDLE;
         end case;
         if (I_RST = '1') then
            led_configure_fsm <= S_IDLE;
         end if;
      end if;
   end process FSM;

   -------------------------------------------------------------------------------
   -- Process     : Led_Sel_Proc
   -- Description : When the FSM needs to select an LED, we just wait for the
   --                first one to be hit and return a flag back that its selected.
   -------------------------------------------------------------------------------
   Led_Sel_Proc : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         led_selected_valid <= '0';
         if (waiting_for_led_sel = '1') then
            for i in C_NUM_LEDS-1 downto 0 loop
               if (led_button_fe(i) = '1') then
                  led_selected_valid   <= '1';
                  led_selected         <= std_logic_vector(to_unsigned(i,5));
               end if;
            end loop;
         end if;
      end if;
   end process Led_Sel_Proc;
   
   Debouncer_0 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_CENTER_BUTTON,
         O_OUTPUT    => led_button_fe(C_CENTER_BUTTON_LED)
      );
   
   Debouncer_1 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_THUMB_UP,
         O_OUTPUT    => led_button_fe(C_RIGHT_THUMB_UP_LED)
      );
   
   Debouncer_2 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_THUMB_DOWN,
         O_OUTPUT    => led_button_fe(C_RIGHT_THUMB_DOWN_LED)
      );
   
   Debouncer_3 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_THUMB_LEFT,
         O_OUTPUT    => led_button_fe(C_RIGHT_THUMB_LEFT_LED)
      );
   
   Debouncer_4 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_THUMB_RIGHT,
         O_OUTPUT    => led_button_fe(C_RIGHT_THUMB_RIGHT_LED)
      );
   
   Debouncer_5 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_THUMB_CENTER,
         O_OUTPUT    => led_button_fe(C_RIGHT_THUMB_CENTER_LED)
      );
   
   Debouncer_6 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_WASD_MOD,
         O_OUTPUT    => led_button_fe(C_WASD_MOD_LED)
      );
   
   Debouncer_7 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_WASD_UP,
         O_OUTPUT    => led_button_fe(C_WASD_UP_LED)
      );
   
   Debouncer_8 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_WASD_DOWN,
         O_OUTPUT    => led_button_fe(C_WASD_DOWN_LED)
      );
   
   Debouncer_9 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_WASD_LEFT,
         O_OUTPUT    => led_button_fe(C_WASD_LEFT_LED)
      );
   
   Debouncer_10 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_WASD_RIGHT,
         O_OUTPUT    => led_button_fe(C_WASD_RIGHT_LED)
      );
   
   Debouncer_11 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_LEFT_THUMB_MOD_0,
         O_OUTPUT    => led_button_fe(C_LEFT_THUMB_MOD_0_LED)
      );
   
   Debouncer_12 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_LEFT_THUMB_MOD_1,
         O_OUTPUT    => led_button_fe(C_LEFT_THUMB_MOD_1_LED)
      );
   
   Debouncer_13 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(0),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_0_LED)
      );
   
   Debouncer_14 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(1),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_1_LED)
      );
   
   Debouncer_15 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(2),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_2_LED)
      );
   
   Debouncer_16 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(3),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_3_LED)
      );
   
   Debouncer_17 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(4),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_4_LED)
      );
   
   Debouncer_18 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(5),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_5_LED)
      );
   
   Debouncer_19 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(6),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_6_LED)
      );
   
   Debouncer_20 : entity work.BUTTON_DEBOUNCER_FALLING_EDGE 
      port map(
         I_CLK       => I_CLK,
         I_INPUT     => I_RIGHT_CLUSTER(7),
         O_OUTPUT    => led_button_fe(C_RIGHT_CLUSTER_7_LED)
      );

   -------------------------------------------------------------------------------
   -- Process     : Blinker
   -- Description : Counter for controlling blink speeds for when we want to blink
   --                the LEDs.
   -------------------------------------------------------------------------------
   Blinker : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         blink_count <= blink_count + 1;
         if (blink_count = G_CYCLES_PER_1_S-1) then
            blink_count <= (others => '0');
            blink       <= not blink;
         end if;
      end if;
   end process Blinker;

   -------------------------------------------------------------------------------
   -- Process     : Updater
   -- Description : Counter for how often we want to update the LED colors.
   --                Only really necessary if we are changing colors.
   -------------------------------------------------------------------------------
   Updater : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         update_count   <= update_count + 1;
         update_leds    <= '0';
         if (update_count = G_CYCLES_PER_1_S-1) then
            update_count   <= (others => '0');
            update_leds    <= '1';
         end if;
      end if;
   end process Updater;
   
   -------------------------------------------------------------------------------
   -- Process     : LED_Changer
   -- Description : When configuring colors this is the logic that controls the
   --                color change.
   -------------------------------------------------------------------------------
   LED_Changer : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         -- Latch in the original color when we're not in color change state.
         if (waiting_for_color_sel = '0') then
            color_to_change <= led_color_mem(to_integer(unsigned(led_selected)));
         end if;
         -- This means we're actively changing the color.
         if (waiting_for_color_sel = '1') then
            led_color_mem(to_integer(unsigned(led_selected))) <= color_to_change;
            -- Each button on the right cluster will be a single bit of the current active color we're editing (RGB)
            for i in 7 downto 0 loop
               if (led_button_fe(i+C_RIGHT_CLUSTER_0_LED) = '1') then
                  if (rgb_sel = C_R_SEL) then
                     color_to_change_r(i) <= not color_to_change_r(i);
                  end if;
                  if (rgb_sel = C_G_SEL) then
                     color_to_change_g(i) <= not color_to_change_g(i);
                  end if;
                  if (rgb_sel = C_B_SEL) then
                     color_to_change_b(i) <= not color_to_change_b(i);
                  end if;
               end if;
            end loop;
            -- WASD controls whether we're editing R, G or B
            if (led_button_fe(C_WASD_LEFT_LED) = '1') then
               rgb_sel <= C_R_SEL;
            end if;
            if (led_button_fe(C_WASD_DOWN_LED) = '1') then
               rgb_sel <= C_G_SEL;
            end if;
            if (led_button_fe(C_WASD_RIGHT_LED) = '1') then
               rgb_sel <= C_B_SEL;
            end if;
         end if;
      end if;
   end process LED_Changer;
   
   -------------------------------------------------------------------------------
   -- Process     : LED_Mux
   -- Description : Muxes output so we're outputting the correct color for each
   --                LED.  Let's us do per key RGB.
   -------------------------------------------------------------------------------
   LED_Mux : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         color_out <= led_color_mem(to_integer(current_led));
         if (waiting_for_color_sel = '1') then
            color_out <= led_color_sel_rom(to_integer(current_led));
            if (current_led = C_CENTER_BUTTON_LED) then
               color_out <= color_to_change;
            end if;
            for i in 7 downto 0 loop
               if (current_led = i+13) then
                  if (rgb_sel = C_R_SEL) then
                     if (color_to_change_r(i) = '1') then
                        color_out <= x"00FF00";
                     end if;
                  end if;
                  if (rgb_sel = C_G_SEL) then
                     if (color_to_change_g(i) = '1') then
                        color_out <= x"0000FF";
                     end if;
                  end if;
                  if (rgb_sel = C_B_SEL) then
                     if (color_to_change_b(i) = '1') then
                        color_out <= x"FF0000";
                     end if;
                  end if;
               end if;
            end loop;
         end if;
         if (blink = '1' and blink_mode = '1') then
            color_out <= (others => '0');
         end if;
      end if;
   end process LED_Mux;

   -------------------------------------------------------------------------------
   -- Entity      : SK6812_Controller
   -- Description : We can use the WS2812B_CONTROLLER_1_0 as a SK6812 Controller
   --               by modifying the G_CYCLES_PER_0_4_US value...
   -------------------------------------------------------------------------------
   SK6812_Controller : entity work.WS2812B_CONTROLLER_1_0
      generic map(
         G_CYCLES_PER_0_4_US        => 4,
         G_NUM_LEDS                 => C_NUM_LEDS
      )
      port map(
         I_CLK                      => I_CLK,
         I_RST                      => I_RST,
         I_GO                       => update_leds,
         I_COLOR                    => color_out,
         O_LED_NUMBER               => current_led,
         O_CONTROL                  => O_CONTROL
      );

end architecture LED_CONTROLLER_1_0_ARCH;
