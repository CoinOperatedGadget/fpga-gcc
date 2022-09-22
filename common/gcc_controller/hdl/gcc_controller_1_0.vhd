-------------------------------------------------------------------------------
-- Title       : Gamecube Controller Emulator
-- Author      : Gadget
-------------------------------------------------------------------------------
-- Description : Gamecube Controller Emulator
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity GCC_CONTROLLER_1_0 is
   generic(
      G_CYCLES_PER_US            : positive        := 125;
      G_CYCLE_SLOP               : positive        := G_CYCLES_PER_US/4
   );
   port(
      I_CLK                      : in  std_logic;
      I_RST                      : in  std_logic;
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
      I_RIGHT_STICK_X            : in  std_logic_vector(7 downto 0);
      I_RIGHT_STICK_Y            : in  std_logic_vector(7 downto 0);
      I_LEFT_STICK_X             : in  std_logic_vector(7 downto 0);
      I_LEFT_STICK_Y             : in  std_logic_vector(7 downto 0);
      I_L_ANALOGUE               : in  std_logic_vector(7 downto 0);
      I_R_ANALOGUE               : in  std_logic_vector(7 downto 0);
      O_RUMBLE                   : out std_logic;
      I_CONTROL                  : in  std_logic;
      O_CONTROL                  : out std_logic;
      O_VALID                    : out std_logic
   );
end entity GCC_CONTROLLER_1_0;

architecture GCC_CONTROLLER_1_0_ARCH of GCC_CONTROLLER_1_0 is

   -- Constants
   constant C_CONTROLLER_PROBE_COMMAND : std_logic_vector(23 downto 0) := x"00_00_00";
   constant C_CONTROLLER_POLL_COMMAND  : std_logic_vector(7 downto 0)  := x"40";
   constant C_CONTROLLER_0x41_COMMAND  : std_logic_vector(7 downto 0)  := x"41";
   -- This should really be based on the clock speed coming in.
   constant C_CONTROL_COUNTER_LENGTH   : natural := 12;
   constant C_CONTROL_COUNTER_MAX      : integer := (2**(C_CONTROL_COUNTER_LENGTH-1)-1);
   constant C_CONTROL_COUNTER_MIN      : integer := -(2**(C_CONTROL_COUNTER_LENGTH-1));

   type T_GCC_FSM is (
      IDLE,
      RECEIVED_0x00,
      RESPONSE_0x00_0x09,
      RESPONSE_0x00_0x00,
      RESPONSE_0x00_0x03,
      RECEIVED_0x40,
      RESPONSE_0x40_BYTE_0,
      RESPONSE_0x40_BYTE_1,
      RESPONSE_0x40_BYTE_2,
      RESPONSE_0x40_BYTE_3,
      RESPONSE_0x40_BYTE_4,
      RESPONSE_0x40_BYTE_5,
      RESPONSE_0x40_BYTE_6,
      RESPONSE_0x40_BYTE_7,
      RESPONSE_0x40_BYTE_8,
      RESPONSE_0x40_BYTE_9,
      RESPONSE_STOP
      );

   signal gcc_fsm : T_GCC_FSM;

   signal control_in_counter     : signed(C_CONTROL_COUNTER_LENGTH downto 0);
   signal control_out_counter    : unsigned(C_CONTROL_COUNTER_LENGTH downto 0);
   signal in_command             : std_logic_vector(23 downto 0);
   signal in_command_valid       : std_logic;
   signal control_in_d           : std_logic;
   signal command_in_progress    : std_logic;
   signal waiting_for_command    : std_logic;
   signal command_interator      : unsigned(5 downto 0);
   signal command_byte           : std_logic_vector(7 downto 0);

   signal send_byte              : std_logic;
   signal send_done              : std_logic;
   signal send_in_progress       : std_logic;
   signal send_stop              : std_logic;
   signal stop_in_progress       : std_logic;
   signal out_byte               : std_logic_vector(7 downto 0);
   signal byte_count             : unsigned(2 downto 0);

   signal poll_byte_0            : std_logic_vector(7 downto 0);
   signal poll_byte_1            : std_logic_vector(7 downto 0);
   signal poll_byte_2            : std_logic_vector(7 downto 0);
   signal poll_byte_3            : std_logic_vector(7 downto 0);
   signal poll_byte_4            : std_logic_vector(7 downto 0);
   signal poll_byte_5            : std_logic_vector(7 downto 0);
   signal poll_byte_6            : std_logic_vector(7 downto 0);
   signal poll_byte_7            : std_logic_vector(7 downto 0);

   signal debug_iterate          : std_logic;
   signal debug_re               : std_logic;
   signal debug_unspecified_command    : std_logic;

begin

   -- We COULD register these here, but we're going to assume they're registered enough
   -- outside this block.  Keep an eye on this when you build.
   poll_byte_0(0) <= '0';
   poll_byte_0(1) <= '0';
   poll_byte_0(2) <= '0';
   poll_byte_0(3) <= I_START_BUTTON;
   poll_byte_0(4) <= I_Y_BUTTON;
   poll_byte_0(5) <= I_X_BUTTON;
   poll_byte_0(6) <= I_B_BUTTON;
   poll_byte_0(7) <= I_A_BUTTON;
   poll_byte_1(0) <= '1';
   poll_byte_1(1) <= I_L_BUTTON;
   poll_byte_1(2) <= I_R_BUTTON;
   poll_byte_1(3) <= I_Z_BUTTON;
   poll_byte_1(4) <= I_D_PAD_UP;
   poll_byte_1(5) <= I_D_PAD_DOWN;
   poll_byte_1(6) <= I_D_PAD_RIGHT;
   poll_byte_1(7) <= I_D_PAD_LEFT;
   poll_byte_2 <= I_LEFT_STICK_X;
   poll_byte_3 <= I_LEFT_STICK_Y;
   poll_byte_4 <= I_RIGHT_STICK_X;
   poll_byte_5 <= I_RIGHT_STICK_Y;
   poll_byte_6 <= I_L_ANALOGUE;
   poll_byte_7 <= I_R_ANALOGUE;

   -------------------------------------------------------------------------------
   -- Process     : Control_In_Handling_Proc
   -- Description : Controls input serial line filling in a command for the FSM
   --               to work on.  Max length of inputs is 24 bits.  Anything longer
   --               and earlier bits will be lost.  Sends a flag to FSM when a new
   --               command comes in.
   -------------------------------------------------------------------------------
   --todo:  Need to go through here and rework some of this logic, some of the if statements at the end aren't necessary and were
   --       added during integration with hardware.
   Control_In_Handling_Proc : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         debug_iterate <= '0';
         control_in_d <= I_CONTROL;
         -- Count highs
         if (control_in_counter < C_CONTROL_COUNTER_MAX and I_CONTROL = '1') then
            control_in_counter   <= control_in_counter + 1;
         end if;
         -- Count lows
         if (control_in_counter > C_CONTROL_COUNTER_MIN and I_CONTROL = '0') then
            control_in_counter   <= control_in_counter - 1;
         end if;
         -- On Rising edge
         debug_re <= '0';
         if (I_CONTROL = '1' and control_in_d = '0') then
            debug_re <= '1';
         end if;
         -- falling edge of controller
         if (I_CONTROL = '0' and control_in_d = '1') then
            -- flag a command in progress
            command_in_progress  <= '1';
            control_in_counter   <= (others => '0');
            -- if we're already receiving a command
            if (command_in_progress = '1') then
               command_interator    <= command_interator + 1;
               debug_iterate        <= '1';
               in_command(23 downto 1) <= in_command(22 downto 0);
               -- low longer than high means 0 was the last bit
               if (control_in_counter < 0) then
                  in_command(0) <= '0';
               end if;
               -- high longer than low means 1 was the last bit
               if (control_in_counter > 0) then
                  in_command(0) <= '1';
               end if;
            end if;
            -- Clear the command if its the start
            if (command_in_progress = '0') then
               in_command <= (others => '0');
            end if;
         end if;
         if (command_interator = 8) then
            command_byte <= in_command(7 downto 0);
         end if;
         -- GCC bits are 4us long, so if the counter gets to 4us of high over low time that means
         -- the command is done sending and the last bit was a stop bit (all commands end with stop bit).
         in_command_valid <= '0';
         if (control_in_counter = G_CYCLES_PER_US*4 and command_in_progress = '1') then
            command_in_progress <= '0';
            in_command_valid  <= '1';
            command_interator <= (others => '0');
         end if;
         if (in_command_valid = '1') then
            in_command <= (others => '0');
         end if;
         if (waiting_for_command = '0') then
            command_in_progress <= '0';
         end if;
         -- Synchronouse Reset
         if (I_RST = '1') then
            command_in_progress <= '0';
            command_interator    <= (others => '0');
         end if;
      end if;
   end process Control_In_Handling_Proc;

   -------------------------------------------------------------------------------
   -- Process     : FSM
   -- Description : Main FSM of emulator.  Waits in Idle until a command is
   --               received, then if its a supported command sends a response 1
   --               byte at a time.
   -------------------------------------------------------------------------------
   FSM : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         send_byte   <= '0';
         send_stop   <= '0';
         waiting_for_command  <= '0';
         debug_unspecified_command  <= '0';
         case gcc_fsm is
            -- Idle, we'll probably spend most of our time here waiting for commands.
            when IDLE =>
               waiting_for_command  <= '1';
               -- Command came in!
               -- NOTE: Normally I don't like doing these compares in the main FSM body, could move
               -- these compares out to a separate process delayed a cycle and moved into flags.
               if (in_command_valid = '1') then
                  debug_unspecified_command <= '1';
                  -- Probe command -> All zeroes, the host device is seeing if anyone is home
                  -- Will respond with a static 0x09 -> 0x00 -> 0x03.
                  if (command_byte = x"00") then
                     gcc_fsm  <= RECEIVED_0x00;
                     debug_unspecified_command  <= '0';
                  end if;
                  -- Poll command -> It's go time, host device asking for our inputs. 8 byte
                  -- response with all buttons/joystick states.  The command also includes
                  -- what the current state of the rumble motor should be, we handle that outside
                  -- the FSM though.
                  if (command_byte = C_CONTROLLER_POLL_COMMAND) then
                     gcc_fsm  <= RECEIVED_0x40;
                     debug_unspecified_command  <= '0';
                  end if;
                  -- Not sure???
                  if (command_byte = C_CONTROLLER_0x41_COMMAND) then
                     gcc_fsm  <= RECEIVED_0x40;
                     debug_unspecified_command  <= '0';
                  end if;
               end if;
            ----------------------------
            -- PROBE COMMAND HANDLING --
            ----------------------------
            when RECEIVED_0x00 =>
               gcc_fsm     <= RESPONSE_0x00_0x09;
               send_byte   <= '1';
               out_byte    <= x"09";
            when RESPONSE_0x00_0x09 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x00_0x00;
                  send_byte   <= '1';
                  out_byte    <= x"00";
               end if;
            when RESPONSE_0x00_0x00 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x00_0x03;
                  send_byte   <= '1';
                  out_byte    <= x"03";
               end if;
            when RESPONSE_0x00_0x03 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_STOP;
                  send_stop   <= '1';
               end if;
            ---------------------------
            -- POLL COMMAND HANDLING --
            ---------------------------
            when RECEIVED_0x40 =>
               gcc_fsm     <= RESPONSE_0x40_BYTE_0;
               send_byte   <= '1';
               out_byte    <= poll_byte_0;
            when RESPONSE_0x40_BYTE_0 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_1;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_1;
               end if;
            when RESPONSE_0x40_BYTE_1 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_2;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_2;
               end if;
            when RESPONSE_0x40_BYTE_2 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_3;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_3;
               end if;
            when RESPONSE_0x40_BYTE_3 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_4;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_4;
               end if;
            when RESPONSE_0x40_BYTE_4 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_5;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_5;
               end if;
            when RESPONSE_0x40_BYTE_5 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_6;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_6;
               end if;
            when RESPONSE_0x40_BYTE_6 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_7;
                  send_byte   <= '1';
                  out_byte    <= poll_byte_7;
               end if;
            when RESPONSE_0x40_BYTE_7 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_8;
                  send_byte   <= '1';
                  out_byte    <= (others => '0');
               end if;
            when RESPONSE_0x40_BYTE_8 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_0x40_BYTE_9;
                  send_byte   <= '1';
                  out_byte    <= (others => '0');
               end if;
            when RESPONSE_0x40_BYTE_9 =>
               if (send_done = '1') then
                  gcc_fsm     <= RESPONSE_STOP;
                  send_stop   <= '1';
               end if;
            -- Common state for sending out a stop bit after responses.  Returns to idle afterwards.
            when RESPONSE_STOP =>
               if (send_done = '1') then
                  gcc_fsm     <= IDLE;
               end if;
            when others =>
               gcc_fsm <= IDLE;
         end case;
         if (I_RST = '1') then
            gcc_fsm <= IDLE;
         end if;
      end if;
   end process FSM;

   -------------------------------------------------------------------------------
   -- Process     : Rumble_Control
   -- Description : Sets rumble output based on Poll command value.
   -------------------------------------------------------------------------------
   Rumble_Control : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         if (in_command_valid = '1') then
            if (in_command(23 downto 16) = C_CONTROLLER_POLL_COMMAND) then
               O_RUMBLE <= in_command(0);
            end if;
         end if;
      end if;
   end process Rumble_Control;

   -------------------------------------------------------------------------------
   -- Process     : Control_Out_Handling_Proc
   -- Description : Sends out serial bytes based on values from FSM.  Starts a
   --               byte when receiving a send_byte flag, and responds with a
   --               send_done when finished.  Can also receive a send_stop to send
   --               out a single stop bit to tell the host system the response has
   --               completed.  Uses send_done to tell the FSM when this is done
   --               as well.
   -------------------------------------------------------------------------------
   Control_Out_Handling_Proc : process(I_CLK)
   begin
      if rising_edge(I_CLK) then
         send_done   <= '0';
         O_VALID     <= '0';
         O_CONTROL   <= '1';
         -- Logic to send byte of data
         if (send_byte = '1') then
            byte_count <= (others => '0');
            send_in_progress <= '1';
            control_out_counter  <= (others => '0');
         end if;
         if (send_in_progress = '1') then
            control_out_counter <= control_out_counter + 1;
            O_VALID     <= '1';
            -- Low control for 1's
            if (control_out_counter < G_CYCLES_PER_US*1 and out_byte(to_integer(byte_count)) = '1') then
               O_CONTROL   <= '0';
            end if;
            -- Low control for 0's
            if (control_out_counter < G_CYCLES_PER_US*3 and out_byte(to_integer(byte_count)) = '0') then
               O_CONTROL   <= '0';
            end if;
            if (control_out_counter = G_CYCLES_PER_US*4) then
               byte_count <= byte_count + 1;
               control_out_counter  <= (others => '0');
               if (byte_count = 7) then
                  send_in_progress  <= '0';
                  send_done         <= '1';
               end if;
            end if;
         end if;
         -- Stop Bit Control Logic
         if (send_stop = '1') then
            stop_in_progress <= '1';
            control_out_counter  <= (others => '0');
         end if;
         if (stop_in_progress = '1') then
            control_out_counter <= control_out_counter + 1;
            O_VALID     <= '1';
            -- Low control for 1's
            if (control_out_counter < G_CYCLES_PER_US*1) then
               O_CONTROL   <= '0';
            end if;
            if (control_out_counter = G_CYCLES_PER_US*3) then
               stop_in_progress  <= '0';
               send_done         <= '1';
            end if;
         end if;
         if (I_RST = '1') then
            stop_in_progress <= '0';
            send_in_progress <= '0';
         end if;
      end if;
   end process Control_Out_Handling_Proc;

end architecture GCC_CONTROLLER_1_0_ARCH;
