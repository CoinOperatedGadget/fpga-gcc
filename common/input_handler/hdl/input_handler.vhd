-------------------------------------------------------------------------------
-- Title       : Input Handler
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description : Muxes inputs
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.MATH_REAL.all;

entity INPUT_HANDLER_1_0 is
   generic(
      G_CLK_CYCLES_1_SECOND      : natural := 12_000_000 -- Default for 12 MHz
   );
   port(
      -- CLock/Reset
      I_CLK                      : in  std_logic;
      I_RST                      : in  std_logic;

      -- Unregistered Inputs
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

      -- Registered Outputs
      O_CENTER_BUTTON            : out std_logic;
      O_RIGHT_THUMB_UP           : out std_logic;
      O_RIGHT_THUMB_DOWN         : out std_logic;
      O_RIGHT_THUMB_LEFT         : out std_logic;
      O_RIGHT_THUMB_RIGHT        : out std_logic;
      O_RIGHT_THUMB_CENTER       : out std_logic;
      O_WASD_MOD                 : out std_logic;
      O_WASD_UP                  : out std_logic;
      O_WASD_DOWN                : out std_logic;
      O_WASD_LEFT                : out std_logic;
      O_WASD_RIGHT               : out std_logic;
      O_LEFT_THUMB_MOD_0         : out std_logic;
      O_LEFT_THUMB_MOD_1         : out std_logic;
      O_RIGHT_CLUSTER            : out std_logic_vector(7 downto 0);

      -- Muxed GCC Outputs
      -- Face Buttons
      O_A_BUTTON                 : out std_logic;
      O_B_BUTTON                 : out std_logic;
      O_X_BUTTON                 : out std_logic;
      O_Y_BUTTON                 : out std_logic;

      -- Shoulder buttons
      O_L_BUTTON                 : out std_logic;
      O_R_BUTTON                 : out std_logic;
      O_Z_BUTTON                 : out std_logic;

      -- Start
      O_START_BUTTON             : out std_logic;

      -- Left Stick
      O_LEFT_STICK_UP            : out std_logic;
      O_LEFT_STICK_DOWN          : out std_logic;
      O_LEFT_STICK_LEFT          : out std_logic;
      O_LEFT_STICK_RIGHT         : out std_logic;

      -- Right Stick
      O_C_STICK_UP               : out std_logic;
      O_C_STICK_DOWN             : out std_logic;
      O_C_STICK_LEFT             : out std_logic;
      O_C_STICK_RIGHT            : out std_logic;

      -- Modifiers
      O_MOD_TILT                 : out std_logic;
      O_MOD_X                    : out std_logic;
      O_MOD_Y                    : out std_logic;
      O_MOD_TRIG_0               : out std_logic;
      O_MOD_TRIG_1               : out std_logic;

      -- Configure Mode Signals
      I_CONFIGURE_LEDS_DONE      : in  std_logic;
      O_CONFIGURE_LEDS           : out std_logic
   );
end entity INPUT_HANDLER_1_0;

architecture INPUT_HANDLER_1_0_ARCH of INPUT_HANDLER_1_0 is

   constant C_NUM_INPUTS         : natural := 21;
   constant C_INPUT_ARRAY_SIZE   : natural := natural(ceil(log2(real(C_NUM_INPUTS))));
   constant C_CENTER_BUTTON      : natural := 0;
   constant C_RIGHT_THUMB_UP     : natural := 1;
   constant C_RIGHT_THUMB_DOWN   : natural := 2;
   constant C_RIGHT_THUMB_LEFT   : natural := 3;
   constant C_RIGHT_THUMB_RIGHT  : natural := 4;
   constant C_RIGHT_THUMB_CENTER : natural := 5;
   constant C_WASD_MOD           : natural := 6;
   constant C_WASD_UP            : natural := 7;
   constant C_WASD_DOWN          : natural := 8;
   constant C_WASD_LEFT          : natural := 9;
   constant C_WASD_RIGHT         : natural := 10;
   constant C_LEFT_THUMB_MOD_0   : natural := 11;
   constant C_LEFT_THUMB_MOD_1   : natural := 12;
   constant C_RIGHT_CLUSTER_0    : natural := 13;
   constant C_RIGHT_CLUSTER_1    : natural := 14;
   constant C_RIGHT_CLUSTER_2    : natural := 15;
   constant C_RIGHT_CLUSTER_3    : natural := 16;
   constant C_RIGHT_CLUSTER_4    : natural := 17;
   constant C_RIGHT_CLUSTER_5    : natural := 18;
   constant C_RIGHT_CLUSTER_6    : natural := 19;
   constant C_RIGHT_CLUSTER_7    : natural := 20;

   constant C_NUM_OUTPUTS        : natural := 21;
   constant C_A_BUTTON           : natural := 0;
   constant C_B_BUTTON           : natural := 1;
   constant C_X_BUTTON           : natural := 2;
   constant C_Y_BUTTON           : natural := 3;
   constant C_L_BUTTON           : natural := 4;
   constant C_R_BUTTON           : natural := 5;
   constant C_Z_BUTTON           : natural := 6;
   constant C_START_BUTTON       : natural := 7;
   constant C_LEFT_STICK_UP      : natural := 8;
   constant C_LEFT_STICK_DOWN    : natural := 9;
   constant C_LEFT_STICK_LEFT    : natural := 10;
   constant C_LEFT_STICK_RIGHT   : natural := 11;
   constant C_C_STICK_UP         : natural := 12;
   constant C_C_STICK_DOWN       : natural := 13;
   constant C_C_STICK_LEFT       : natural := 14;
   constant C_C_STICK_RIGHT      : natural := 15;
   constant C_MOD_TILT           : natural := 16;
   constant C_MOD_X              : natural := 17;
   constant C_MOD_Y              : natural := 18;
   constant C_MOD_TRIG_0         : natural := 19;
   constant C_MOD_TRIG_1         : natural := 20;

   type T_OUTPUT_MUX_ARRAY is array (C_NUM_OUTPUTS-1 downto 0) of std_logic_vector(C_INPUT_ARRAY_SIZE-1 downto 0);
   constant C_DEFAULT_OUTPUT_MUX_CONTROL  : T_OUTPUT_MUX_ARRAY := (
      C_A_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_THUMB_CENTER, C_INPUT_ARRAY_SIZE)),
      C_B_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_2   , C_INPUT_ARRAY_SIZE)),
      C_X_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_1   , C_INPUT_ARRAY_SIZE)),
      C_Y_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_5   , C_INPUT_ARRAY_SIZE)),
      C_L_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_6   , C_INPUT_ARRAY_SIZE)),
      C_R_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_4   , C_INPUT_ARRAY_SIZE)),
      C_Z_BUTTON           => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_7   , C_INPUT_ARRAY_SIZE)),
      C_START_BUTTON       => std_logic_vector(to_unsigned(C_CENTER_BUTTON     , C_INPUT_ARRAY_SIZE)),
      C_LEFT_STICK_UP      => std_logic_vector(to_unsigned(C_WASD_UP           , C_INPUT_ARRAY_SIZE)),
      C_LEFT_STICK_DOWN    => std_logic_vector(to_unsigned(C_WASD_DOWN         , C_INPUT_ARRAY_SIZE)),
      C_LEFT_STICK_LEFT    => std_logic_vector(to_unsigned(C_WASD_LEFT         , C_INPUT_ARRAY_SIZE)),
      C_LEFT_STICK_RIGHT   => std_logic_vector(to_unsigned(C_WASD_RIGHT        , C_INPUT_ARRAY_SIZE)),
      C_C_STICK_UP         => std_logic_vector(to_unsigned(C_RIGHT_THUMB_UP    , C_INPUT_ARRAY_SIZE)),
      C_C_STICK_DOWN       => std_logic_vector(to_unsigned(C_RIGHT_THUMB_DOWN  , C_INPUT_ARRAY_SIZE)),
      C_C_STICK_LEFT       => std_logic_vector(to_unsigned(C_RIGHT_THUMB_LEFT  , C_INPUT_ARRAY_SIZE)),
      C_C_STICK_RIGHT      => std_logic_vector(to_unsigned(C_RIGHT_THUMB_RIGHT , C_INPUT_ARRAY_SIZE)),
      C_MOD_TILT           => std_logic_vector(to_unsigned(C_WASD_MOD          , C_INPUT_ARRAY_SIZE)),
      C_MOD_X              => std_logic_vector(to_unsigned(C_LEFT_THUMB_MOD_0  , C_INPUT_ARRAY_SIZE)),
      C_MOD_Y              => std_logic_vector(to_unsigned(C_LEFT_THUMB_MOD_1  , C_INPUT_ARRAY_SIZE)),
      C_MOD_TRIG_0         => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_3   , C_INPUT_ARRAY_SIZE)),
      C_MOD_TRIG_1         => std_logic_vector(to_unsigned(C_RIGHT_CLUSTER_0   , C_INPUT_ARRAY_SIZE))
      );

   signal output_mux_input       : std_logic_vector(C_NUM_INPUTS-1 downto 0);
   signal output_mux_control     : T_OUTPUT_MUX_ARRAY;
   signal output_mux_output      : std_logic_vector(C_NUM_OUTPUTS-1 downto 0);

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

   signal config_count           : unsigned(31 downto 0);
   signal led_config             : std_logic;
   signal control_config         : std_logic;

begin

   O_CENTER_BUTTON      <= center_button;
   O_RIGHT_THUMB_UP     <= right_thumb_up;
   O_RIGHT_THUMB_DOWN   <= right_thumb_down;
   O_RIGHT_THUMB_LEFT   <= right_thumb_left;
   O_RIGHT_THUMB_RIGHT  <= right_thumb_right;
   O_RIGHT_THUMB_CENTER <= right_thumb_center;
   O_WASD_MOD           <= wasd_mod;
   O_WASD_UP            <= wasd_up;
   O_WASD_DOWN          <= wasd_down;
   O_WASD_LEFT          <= wasd_left;
   O_WASD_RIGHT         <= wasd_right;
   O_LEFT_THUMB_MOD_0   <= left_thumb_mod_0;
   O_LEFT_THUMB_MOD_1   <= left_thumb_mod_1;
   O_RIGHT_CLUSTER      <= right_cluster;

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
         -- Register intput mux input (extra stage for timing)
         output_mux_input(C_CENTER_BUTTON     ) <= center_button     ;
         output_mux_input(C_RIGHT_THUMB_UP    ) <= right_thumb_up    ;
         output_mux_input(C_RIGHT_THUMB_DOWN  ) <= right_thumb_down  ;
         output_mux_input(C_RIGHT_THUMB_LEFT  ) <= right_thumb_left  ;
         output_mux_input(C_RIGHT_THUMB_RIGHT ) <= right_thumb_right ;
         output_mux_input(C_RIGHT_THUMB_CENTER) <= right_thumb_center;
         output_mux_input(C_WASD_MOD          ) <= wasd_mod          ;
         output_mux_input(C_WASD_UP           ) <= wasd_up           ;
         output_mux_input(C_WASD_DOWN         ) <= wasd_down         ;
         output_mux_input(C_WASD_LEFT         ) <= wasd_left         ;
         output_mux_input(C_WASD_RIGHT        ) <= wasd_right        ;
         output_mux_input(C_LEFT_THUMB_MOD_0  ) <= left_thumb_mod_0  ;
         output_mux_input(C_LEFT_THUMB_MOD_1  ) <= left_thumb_mod_1  ;
         output_mux_input(C_RIGHT_CLUSTER_0   ) <= right_cluster(0)  ;
         output_mux_input(C_RIGHT_CLUSTER_1   ) <= right_cluster(1)  ;
         output_mux_input(C_RIGHT_CLUSTER_2   ) <= right_cluster(2)  ;
         output_mux_input(C_RIGHT_CLUSTER_3   ) <= right_cluster(3)  ;
         output_mux_input(C_RIGHT_CLUSTER_4   ) <= right_cluster(4)  ;
         output_mux_input(C_RIGHT_CLUSTER_5   ) <= right_cluster(5)  ;
         output_mux_input(C_RIGHT_CLUSTER_6   ) <= right_cluster(6)  ;
         output_mux_input(C_RIGHT_CLUSTER_7   ) <= right_cluster(7)  ;
      end if;
   end process Input_Registers;

   Output_Mux : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         for i in C_NUM_OUTPUTS-1 downto 0 loop
            output_mux_output(i) <= output_mux_input(to_integer(unsigned(C_DEFAULT_OUTPUT_MUX_CONTROL(i))));
         end loop;
      end if;
   end process Output_Mux;

   Output_Registers : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         O_A_BUTTON           <= output_mux_output(C_A_BUTTON        );
         O_B_BUTTON           <= output_mux_output(C_B_BUTTON        );
         O_X_BUTTON           <= output_mux_output(C_X_BUTTON        );
         O_Y_BUTTON           <= output_mux_output(C_Y_BUTTON        );
         O_L_BUTTON           <= output_mux_output(C_L_BUTTON        );
         O_R_BUTTON           <= output_mux_output(C_R_BUTTON        );
         O_Z_BUTTON           <= output_mux_output(C_Z_BUTTON        );
         O_START_BUTTON       <= output_mux_output(C_START_BUTTON    );
         O_LEFT_STICK_UP      <= output_mux_output(C_LEFT_STICK_UP   );
         O_LEFT_STICK_DOWN    <= output_mux_output(C_LEFT_STICK_DOWN );
         O_LEFT_STICK_LEFT    <= output_mux_output(C_LEFT_STICK_LEFT );
         O_LEFT_STICK_RIGHT   <= output_mux_output(C_LEFT_STICK_RIGHT);
         O_C_STICK_UP         <= output_mux_output(C_C_STICK_UP      );
         O_C_STICK_DOWN       <= output_mux_output(C_C_STICK_DOWN    );
         O_C_STICK_LEFT       <= output_mux_output(C_C_STICK_LEFT    );
         O_C_STICK_RIGHT      <= output_mux_output(C_C_STICK_RIGHT   );
         O_MOD_TILT           <= output_mux_output(C_MOD_TILT        );
         O_MOD_X              <= output_mux_output(C_MOD_X           );
         O_MOD_Y              <= output_mux_output(C_MOD_Y           );
         O_MOD_TRIG_0         <= output_mux_output(C_MOD_TRIG_0      );
         O_MOD_TRIG_1         <= output_mux_output(C_MOD_TRIG_1      );
         -- -- Pass all '1's when
         -- if (led_config = '1' or control_config = '1') then
            -- O_A_BUTTON           <= output_mux_output(C_A_BUTTON        );
            -- O_B_BUTTON           <= output_mux_output(C_B_BUTTON        );
            -- O_X_BUTTON           <= output_mux_output(C_X_BUTTON        );
            -- O_Y_BUTTON           <= output_mux_output(C_Y_BUTTON        );
            -- O_L_BUTTON           <= output_mux_output(C_L_BUTTON        );
            -- O_R_BUTTON           <= output_mux_output(C_R_BUTTON        );
            -- O_Z_BUTTON           <= output_mux_output(C_Z_BUTTON        );
            -- O_START_BUTTON       <= output_mux_output(C_START_BUTTON    );
            -- O_LEFT_STICK_UP      <= output_mux_output(C_LEFT_STICK_UP   );
            -- O_LEFT_STICK_DOWN    <= output_mux_output(C_LEFT_STICK_DOWN );
            -- O_LEFT_STICK_LEFT    <= output_mux_output(C_LEFT_STICK_LEFT );
            -- O_LEFT_STICK_RIGHT   <= output_mux_output(C_LEFT_STICK_RIGHT);
            -- O_C_STICK_UP         <= output_mux_output(C_C_STICK_UP      );
            -- O_C_STICK_DOWN       <= output_mux_output(C_C_STICK_DOWN    );
            -- O_C_STICK_LEFT       <= output_mux_output(C_C_STICK_LEFT    );
            -- O_C_STICK_RIGHT      <= output_mux_output(C_C_STICK_RIGHT   );
            -- O_MOD_TILT           <= output_mux_output(C_MOD_TILT        );
            -- O_MOD_X              <= output_mux_output(C_MOD_X           );
            -- O_MOD_Y              <= output_mux_output(C_MOD_Y           );
            -- O_MOD_TRIG_0         <= output_mux_output(C_MOD_TRIG_0      );
            -- O_MOD_TRIG_1         <= output_mux_output(C_MOD_TRIG_1      );
         -- end if;
      end if;
   end process Output_Registers;

   Config_Mode_Watchdog : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         O_CONFIGURE_LEDS  <= led_config;
         -- Sharing a count for each to save resources, this means you could do
         -- weird things to activate them but not a huge deal as long as we make
         -- it so you can't activate both at the same time...
         config_count      <= (others => '0');
         if (center_button = '0' and right_cluster(3) = '0' and led_config = '0' and control_config = '0') then
            config_count <= config_count + 1;
            if (config_count = G_CLK_CYCLES_1_SECOND * 3) then
               led_config  <= '1';
            end if;
         end if;
         if (center_button = '0' and right_cluster(7) = '0' and right_cluster(3) = '1' and led_config = '0' and control_config = '0') then
            config_count <= config_count + 1;
            if (config_count = G_CLK_CYCLES_1_SECOND * 3) then
               control_config <= '1';
            end if;
         end if;
         if (I_CONFIGURE_LEDS_DONE = '1') then
            led_config <= '0';
         end if;
         if (I_RST = '1') then
            led_config        <= '0';
            control_config    <= '0';
         end if;
      end if;
   end process Config_Mode_Watchdog;

end architecture INPUT_HANDLER_1_0_ARCH;
