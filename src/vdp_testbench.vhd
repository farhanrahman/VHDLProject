LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.vdp_pack.ALL;
USE std.textio.ALL;
USE work.utility_pack.ALL;
USE work.config_pack.ALL;

ENTITY vdp_testbench IS
END vdp_testbench;





ARCHITECTURE behav OF vdp_testbench IS
   
   -- file name of command file to be read
   

   -- Host Bus
   SIGNAL hdb_i      : STD_LOGIC_VECTOR( 15 DOWNTO 0);
   SIGNAL dav_i      : STD_LOGIC;
   SIGNAL hdb_busy_i : STD_LOGIC;

   -- VRAM bus
   SIGNAL vdin_i   : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL vdout_i  : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL vaddr_i  : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL vwrite_i : STD_LOGIC;
   
   -- needed as parameters for run_command_file but not
   -- used since it is called with ram_mode_v=model
   SIGNAL cycle_init, cycle_done : STD_LOGIC;  -- dummy signals

   SIGNAL trace_commands: boolean := false;
 
   SIGNAL clk_i, reset_i: std_logic;
 
BEGIN


   P_RST_CLK: PROCESS
      -- generate reset_i & clk_i
      BEGIN
        -- first one cycle with reset '1'
        reset_i <= '1';
        clk_i <= '0';
        WAIT FOR config_clock_period / 2;
        clk_i <= '1';
        WAIT FOR config_clock_period / 2;
        reset_i <= '0';
        -- now generate continuous clock with reset '0'
        WHILE TRUE LOOP
           clk_i <= '0';
           WAIT FOR config_clock_period / 2;
           clk_i <= '1';
           WAIT FOR config_clock_period / 2;
        END LOOP;
      END PROCESS P_RST_CLK;


   
   RAM1 : ENTITY work.vram
      PORT MAP (
         vdin   => vdin_i,
         vdout  => vdout_i,
         vaddr  => vaddr_i,
         vwrite => vwrite_i,
         reset=>reset_i
         );

   DUT : ENTITY work.vdp
      PORT MAP (
         clk => clk_i,
         reset=>reset_i,
         hdb      => hdb_i,
         dav      => dav_i,
         hdb_busy => hdb_busy_i,
         vdin     => vdin_i,
         vdout    => vdout_i,
         vaddr    => vaddr_i,
         vwrite   => vwrite_i
         );


   -- main process, tests VDP
   --
   MAIN : PROCESS

      FILE f                 : TEXT OPEN read_mode IS config_file_name;
      VARIABLE buf           : LINE;
      VARIABLE ch            : CHARACTER;
      VARIABLE cmd           : cmd_type;
      VARIABLE pen           : pen_type;
      VARIABLE x, y          : INTEGER;
      VARIABLE n             : INTEGER;
      VARIABLE skipline      : BOOLEAN;
      VARIABLE bad_pix_count : INTEGER;
   BEGIN
      -- wait until after initial reset pulse
      WAIT UNTIL reset_i = '1';
      WAIT UNTIL reset_i = '0';
      --
      clear_ram_direct(ram_data);  -- write directly to ram state variables to
                                   -- init vram
      -- could do this using clearscreen but would use much
      -- more simulation time
      -- and require correct implementation of clearscreen part of VDP

      n := 1;

      -- read file of commands, handshaking each command onto VDP host bus.
      -- VDP will modify pixels in vram by driving vram bus signals
      -- monitor vram state variables to check correct operation.

      WHILE NOT endfile(f) LOOP
         readline( f, buf);
         skipline := false;
         If buf'LENGTH = 0 THEN
            skipline := true;
            REPORT "skipping line: " & integer'IMAGE(n) SEVERITY note;
         ELSE
            REPORT "Reading command:" & integer'image(n) SEVERITY note;
            read( buf, ch);
            skipline := false;
         END IF;
         CASE ch IS
            WHEN 'D'       => cmd      := drawline;
            WHEN 'M'       => cmd      := movepen;
            WHEN 'C'       => cmd      := clearscreen;
            WHEN 'F'       => cmd      := flushcache;
            WHEN '-'       => skipline := true;  -- comment line
            WHEN OTHERS    =>
               REPORT "Bad character ("& ch &
                  ") should be [DMC] in col 1, line "&i2s(n);
         END CASE;
         IF NOT skipline THEN
            read( buf, ch);
            CASE ch IS
               WHEN 'B'    => pen      := black;
               WHEN 'W'    => pen      := white;
               WHEN 'I'    => pen      := invert;
               WHEN OTHERS =>
                  REPORT "Bad character ("& ch &
                     ") should be [BWI] in col 2, line "&i2s(n);
            END CASE;

            read( buf, x);
            read( buf, y);
            IF trace_commands THEN
               REPORT "sending ("& cmd_type'IMAGE(cmd) & ", " &
                  pen_type'IMAGE(pen) &", (" & i2s(x)&", " & i2s(y) &
                  ") line = "& i2s(n);
            END IF;
            send_vdp_command(x, y, pen, cmd, hdb_i, dav_i, hdb_busy_i, clk_i);
         END IF;
         n := n+1;
      END LOOP;

      -- wait until last command has been fully processed
      -- needed because send_vdp_command returns after command has been
      -- sent but before VDP stops being busy - normally this is checked
      -- at the start of the next send_vdp_command
      IF hdb_busy_i /= '0' THEN
         WAIT UNTIL hdb_busy_i = '0';
      END IF;

      -- extra delay (see config_pak)

      WAIT for post_command_delay;
      WAIT UNTIL clk_i'EVENT and clk_i='1'; -- synchronise with clock

      -- this is good for debugging a design
      -- it displays the final VRAM contents on the screen
      -- NB for regression testing we need to compare VRAM results
      -- with correct results from a behavioural simulation.
      ASSERT config_window_width >= screen_width REPORT
        "Displaying VRAM data with width of " &
        INTEGER'IMAGE(config_window_width) &
        " some pixels will not be displayed" SEVERITY note;
      display_ram(ram_data, config_window_width);  -- 2nd parameter limits
                                                   -- displayed window size


      --now generate a comparison screen image from
      --the same set of commands run through a software simulation of
      --the VDP
      clear_ram_direct( ram_data_model);
      run_command_file( config_file_name, cycle_init, cycle_done);
      
      IF ram_data = ram_data_model THEN
         REPORT "Commands from: " & config_file_name & ", VDP PASSED.";
      ELSE
         REPORT "Commands from: " & config_file_name & ", VDP FAILED";
         
         bad_pix_count          := 0;
         
         FOR i IN 0 TO screen_width-1 LOOP
            FOR j IN 0 TO screen_width-1 LOOP
               IF read_ram_bit_direct(i, j, ram_data) /=
                  read_ram_bit_direct( i, j, ram_data_model) THEN
                  bad_pix_count := bad_pix_count+1;
               END IF;
            END LOOP;
         END LOOP;
         
         REPORT "Number of unequal pixels: " & i2s(bad_pix_count);
      END IF;

      REPORT "Test finished normally." SEVERITY failure;
   END PROCESS MAIN;




END behav;










