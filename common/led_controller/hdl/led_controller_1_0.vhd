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

   signal led_wr_addr   : unsigned(4 downto 0);
   signal led_wr        : std_logic;
   signal led_wr_data   : std_logic_vector(23 downto 0);

   signal led_rd_addr   : unsigned(4 downto 0);
   signal led_rd_addr_reg   : unsigned(4 downto 0);
   signal next_color    : std_logic;

   -- Input Regs for buttons
   signal center_button          : std_logic;
   signal right_thumb_up         : std_logic;
   signal right_thumb_down       : std_logic;
   signal right_thumb_left       : std_logic;
   signal right_thumb_right      : std_logic;
   signal right_thumb_center     : std_logic;
   signal wasd_mod               : std_logic;
   signal wasd_up                : std_logic;
   signal wasd_down              : std_logic;
   signal wasd_left              : std_logic;
   signal wasd_right             : std_logic;
   signal left_thumb_mod_0       : std_logic;
   signal left_thumb_mod_1       : std_logic;
   signal right_cluster          : std_logic_vector(7 downto 0);

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


   -- Update_Counter : process(I_CLK)
   -- begin
      -- if rising_edge(I_CLK) then
         -- update_leds <= '0';
         -- update_count <= update_count+1;
         -- if (update_count = x"ffff") then
            -- update_leds <= '1';
         -- end if;
      -- end if;
   -- end process Update_Counter;

   -- Mem_Array_Wr : process(I_CLK)
   -- begin
      -- if rising_edge(I_CLK) then
         -- led_wr      <= I_CONFIGURE_CONFIRM;
         -- led_wr_addr <= I_CONFIGURE_COLOR_ADDR;
         -- led_wr_data <= I_CONFIGURE_COLOR;
         -- if (led_wr = '1') then
            -- led_array(to_integer(led_wr_addr)) <= led_wr_data;
         -- end if;
      -- end if;
   -- end process Mem_Array_Rd;

   -- Mem_Array_Rd : process(I_CLK)
   -- begin
      -- if rising_edge(I_CLK) then
         -- led_rd_addr_reg <= led_rd_addr;
         -- led_rd_data <= led_array(to_integer(led_rd_addr_reg));
         -- if (update_leds = '1') then
            -- led_rd_addr <= (others => '0');
         -- end if;
         -- if (next_color = '1') then
            -- led_rd_addr <= led_rd_addr + 1;
         -- end if;
      -- end if;
   -- end process Mem_Array_Rd;

   Input_Registers : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         -- Register Stage
         center_button        <= I_CENTER_BUTTON;
         right_thumb_up       <= I_RIGHT_THUMB_UP;
         right_thumb_down     <= I_RIGHT_THUMB_DOWN;
         right_thumb_left     <= I_RIGHT_THUMB_LEFT;
         right_thumb_right    <= I_RIGHT_THUMB_RIGHT;
         right_thumb_center   <= I_RIGHT_THUMB_CENTER;
         wasd_mod             <= I_WASD_MOD;
         wasd_up              <= I_WASD_UP;
         wasd_down            <= I_WASD_DOWN;
         wasd_left            <= I_WASD_LEFT;
         wasd_right           <= I_WASD_RIGHT;
         left_thumb_mod_0     <= I_LEFT_THUMB_MOD_0;
         left_thumb_mod_1     <= I_LEFT_THUMB_MOD_1;
         right_cluster        <= I_RIGHT_CLUSTER;
      end if;
   end process Input_Registers;


   -------------------------------------------------------------------------------
   -- Process     : FSM
   -- Description : Main FSM of emulator.  Waits in Idle until a command is
   --               received, then if its a supported command sends a response 1
   --               byte at a time.
   -------------------------------------------------------------------------------
   FSM : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         O_CONFIGURE_DONE        <= '0';
         blink_mode              <= '0';
         waiting_for_led_sel     <= '0';
         waiting_for_color_sel   <= '0';
         case led_configure_fsm is
            -- Idle, we'll probably spend most of our time here waiting for commands.
            when S_IDLE =>
               if (I_CONFIGURE_MODE = '1') then
                  led_configure_fsm <= S_CHOOSE_BUTTON;
               end if;

            when S_CHOOSE_BUTTON =>
               blink_mode           <= '1';
               waiting_for_led_sel  <= '1';
               if (led_selected_valid = '1') then
                  led_configure_fsm <= S_CHOOSE_COLOR;
               end if;

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

   -- Falling_Edge_Detects : process(I_CLK)
   -- begin
      -- if rising_edge(I_CLK) then
         -- led_button_fe <= (others => '0');
         -- if (I_CENTER_BUTTON      = '0' and center_button      = '1') then
            -- led_button_fe(C_CENTER_BUTTON_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_THUMB_UP     = '0' and right_thumb_up     = '1') then
            -- led_button_fe(C_RIGHT_THUMB_UP_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_THUMB_DOWN   = '0' and right_thumb_down   = '1') then
            -- led_button_fe(C_RIGHT_THUMB_DOWN_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_THUMB_LEFT   = '0' and right_thumb_left   = '1') then
            -- led_button_fe(C_RIGHT_THUMB_LEFT_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_THUMB_RIGHT  = '0' and right_thumb_right  = '1') then
            -- led_button_fe(C_RIGHT_THUMB_RIGHT_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_THUMB_CENTER = '0' and right_thumb_center = '1') then
            -- led_button_fe(C_RIGHT_THUMB_CENTER_LED)   <= '1';
         -- end if;
         -- if (I_WASD_MOD           = '0' and wasd_mod           = '1') then
            -- led_button_fe(C_WASD_MOD_LED)   <= '1';
         -- end if;
         -- if (I_WASD_UP            = '0' and wasd_up            = '1') then
            -- led_button_fe(C_WASD_UP_LED)   <= '1';
         -- end if;
         -- if (I_WASD_DOWN          = '0' and wasd_down          = '1') then
            -- led_button_fe(C_WASD_DOWN_LED)   <= '1';
         -- end if;
         -- if (I_WASD_LEFT          = '0' and wasd_left          = '1') then
            -- led_button_fe(C_WASD_LEFT_LED)   <= '1';
         -- end if;
         -- if (I_WASD_RIGHT         = '0' and wasd_right         = '1') then
            -- led_button_fe(C_WASD_RIGHT_LED)   <= '1';
         -- end if;
         -- if (I_LEFT_THUMB_MOD_0   = '0' and left_thumb_mod_0   = '1') then
            -- led_button_fe(C_LEFT_THUMB_MOD_0_LED)   <= '1';
         -- end if;
         -- if (I_LEFT_THUMB_MOD_1   = '0' and left_thumb_mod_1   = '1') then
            -- led_button_fe(C_LEFT_THUMB_MOD_1_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(0)   = '0' and right_cluster(0)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_0_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(1)   = '0' and right_cluster(1)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_1_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(2)   = '0' and right_cluster(2)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_2_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(3)   = '0' and right_cluster(3)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_3_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(4)   = '0' and right_cluster(4)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_4_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(5)   = '0' and right_cluster(5)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_5_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(6)   = '0' and right_cluster(6)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_6_LED)   <= '1';
         -- end if;
         -- if (I_RIGHT_CLUSTER(7)   = '0' and right_cluster(7)   = '1') then
            -- led_button_fe(C_RIGHT_CLUSTER_7_LED)   <= '1';
         -- end if;
      -- end if;
   -- end process Falling_Edge_Detects;

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
   
   LED_Changer : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         if (waiting_for_color_sel = '0') then
            color_to_change <= led_color_mem(to_integer(unsigned(led_selected)));
         end if;
         if (waiting_for_color_sel = '1') then
            led_color_mem(to_integer(unsigned(led_selected))) <= color_to_change;            
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
