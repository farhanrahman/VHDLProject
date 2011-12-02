-- package of procedures to support testing of VDP
-- Thomas Clarke, 2001
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE std.textio.ALL;
USE work.utility_pack.ALL;
USE work.config_pack.ALL;


PACKAGE vdp_pack IS
   --------------------------------------------------------------------------
   ----------------------------- behavioural vram  ----------------------------
   --------------------------------------------------------------------------
   CONSTANT screen_width : INTEGER := 64;  -- dimensions of screen
                                           -- must not be changed

   CONSTANT rsize : INTEGER := (screen_width*screen_width)/16;
   -- number of vram words
   
   
   -- times that characterise vram
   CONSTANT twp   : TIME := config_clock_period*config_twp;
   CONSTANT twds  : TIME := twp / 2;
   CONSTANT tracc : TIME := config_clock_period *config_tracc;
   CONSTANT taws  : TIME := tracc / 2;

   TYPE ram_array IS ARRAY (0 TO rsize-1) OF STD_LOGIC_VECTOR(15 DOWNTO 0);

   SHARED VARIABLE ram_data       : ram_array;  -- state for vram entity ram
   SHARED VARIABLE ram_data_model : ram_array;  -- parallel state for use by testbench


   -- controls do_ram_cycle operation
   TYPE ram_mode_type IS (
      vram,  -- use process ramio in vdp_behav to generate ram I/O signals
      -- these cause ram_data vraiable (in vram) to be read/written
      -- see vram entity
      vram_behav,             -- reads/writes to ram_data directly
      model                   -- reads/writes to ram_data_model directly
      );

   -- I/O for vram, allows procedure that implements ram I/O cycles
   -- and used only two signal parameters (cycle_init and cycle_done)
   SHARED VARIABLE vaddr_v  : INTEGER;
   SHARED VARIABLE vdin_v   : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SHARED VARIABLE vdout_v  : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SHARED VARIABLE vwrite_v : BOOLEAN;

   -- implements a RAM read or write cycle using the above paras
   -- data is written and read via ram_io process
   PROCEDURE do_ram_cycle(
      SIGNAL cycle_init : OUT STD_LOGIC;  -- 0->1 starts cycle
      SIGNAL cycle_done : IN  STD_LOGIC;  -- 0->1 flags end of cycle
      destination       : IN  ram_mode_type
      );


   -- write a single bit at given x,y coordinates to ram
   -- using the hardware ram interface
   PROCEDURE write_ram_bit(
      x                 : IN  INTEGER;
      y                 : IN  INTEGER;
      b                 : IN  STD_LOGIC;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC;
      dest              : IN  ram_mode_type
      );

   -- as above but read a single bit
   PROCEDURE read_ram_bit(
      x                   : IN  INTEGER;
      y                   : IN  INTEGER;
      SIGNAL   cycle_init : OUT STD_LOGIC;
      SIGNAL   cycle_done : IN  STD_LOGIC;
      dest                : IN  ram_mode_type;
      VARIABLE val        : OUT STD_LOGIC
      );

   -- read a ram bit without using hardware interface, accessing
   -- shared variable state directly
   IMPURE FUNCTION read_ram_bit_direct(
      x   : IN INTEGER;
      y   : IN INTEGER;
      ram : IN ram_array)
      RETURN STD_LOGIC;

   -- init ram to all '0' using shared variable state directly
   PROCEDURE clear_ram_direct (VARIABLE ram : OUT ram_array);

   -- print to transcript plot of ram contents, read
   -- from state variables directly (no hardware cycles).
   PROCEDURE display_ram( VARIABLE ram : IN ram_array;
                          window_size  : IN INTEGER
                          );



   ---------------------------------------------------------------------------
   -----------------------------behavioural host  ------------------------------
   ---------------------------------------------------------------------------

   TYPE pen_type IS( black,
                     white,
                     invert
                     );

   TYPE cmd_type IS ( movepen,
                      drawline,
                      clearscreen,
                      flushcache
                      );

   -- convert 16 bit command vector into its constituent fields
   PROCEDURE decode_paras(
      cmdword      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      VARIABLE cmd : OUT cmd_type;
      VARIABLE x   : OUT INTEGER;
      VARIABLE y   : OUT INTEGER;
      VARIABLE pen : OUT pen_type
      );


   -- drive the HDB with a command which has parameters as specified
   -- procedure will return when command has been successfully
   -- output on (hdb, dav, hdb_busy)
   PROCEDURE send_vdp_command(
      -- command parameters
      x               :     INTEGER; y : INTEGER; pen : pen_type; cmd : cmd_type;
      -- host bus I/O signals
      SIGNAL hdb      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      SIGNAL dav      : OUT STD_LOGIC;
      SIGNAL hdb_busy : IN  STD_LOGIC;
      SIGNAL clk: IN STD_LOGIC
      );


   -- drive behavioural simulation of VDP with specified command
   -- output is a sequence of calls to do_ram_cycle that use the
   -- cycle_init/cycle_done interface to trigger vram cycles that
   -- write as specified by the command.
   PROCEDURE do_vdp_command(
      cmd               : IN  cmd_type;
      x                 : IN  INTEGER;
      y                 : IN  INTEGER;
      pen               : IN  pen_type;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC;
      dest              : IN  ram_mode_type
      );

   -- reads file fname and interprets each line as a VDP command.
   -- executes commands using do_vdp_command
   PROCEDURE run_command_file(
      fname             : IN  STRING;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC
      );

   -- writes out sample text file fname that contains
   -- VDP commands in run_command_file format that draw
   -- a star.
   PROCEDURE write_lines(fname : IN STRING);

END PACKAGE vdp_pack;



--------------------------------------------------------------------
--------------------------------------------------------------------
---------------PACKAGE BODY   -----------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------

PACKAGE BODY vdp_pack IS

   -----------------------------------------------------------------
   ------------------------behavioural vram-------------------------
   -----------------------------------------------------------------

   PROCEDURE do_ram_cycle(
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC;
      destination       :     ram_mode_type
      ) IS
   BEGIN
      CASE destination IS

         -- write to model ram state
         -- used to generate behav VRAM state to compare with real thing
         WHEN model =>
            -- don't use vram hardware, use ram_data_model state variable
            IF vwrite_v THEN
               ram_data_model(vaddr_v) := vdin_v;
            ELSE
               vdout_v := ram_data_model(vaddr_v);
            END IF;

            -- write to VRAM directly using shared variable state
         WHEN vram_behav =>
            IF vwrite_v THEN
               ram_data(vaddr_v) := vdin_v;
            ELSE
               vdout_v := ram_data(vaddr_v);
            END IF;

            -- write to hardware VRAM using process ramio in vdp_behav
            -- to do actual I/O
         WHEN vram =>
            cycle_init <= '0';
            WAIT FOR 0 ns;
            cycle_init <= '1';
            WAIT UNTIL cycle_done'EVENT AND cycle_done = '1';
      END CASE;
   END do_ram_cycle;


   PROCEDURE write_ram_bit(
      x                 : IN  INTEGER;
      y                 : IN  INTEGER;
      b                 : IN  STD_LOGIC;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC;
      dest              : IN  ram_mode_type
      ) IS
      -- writes pixel (x,y) 
      VARIABLE bitnum : INTEGER;
      VARIABLE locnum : INTEGER;
   BEGIN
      bitnum         := (x MOD 4) + 4*(y MOD 4);
      vaddr_v        := (x/4)+(y/4)*(screen_width/4);
      vwrite_v       := false;
      do_ram_cycle(cycle_init, cycle_done, dest);
      vdin_v         := vdout_v;
      vdin_v(bitnum) := b;
      vwrite_v       := true;
      do_ram_cycle( cycle_init, cycle_done, dest);
   END write_ram_bit;


   PROCEDURE read_ram_bit(
      x                   : IN  INTEGER;
      y                   : IN  INTEGER;
      SIGNAL   cycle_init : OUT STD_LOGIC;
      SIGNAL   cycle_done : IN  STD_LOGIC;
      dest                : IN  ram_mode_type;
      VARIABLE val        : OUT STD_LOGIC
      ) IS

      -- reads pixel (x,y) from ram
      -- value returned is '0' (white) or '1' (black)

      VARIABLE bitnum : INTEGER;
   BEGIN
      bitnum   := (x MOD 4) + 4*(y MOD 4);
      vaddr_v  := (x/4)+(y/4)*(screen_width/4);
      vwrite_v := false;
      do_ram_cycle( cycle_init, cycle_done, dest);
      val      := vdout_v(bitnum);
   END read_ram_bit;

   PROCEDURE write_ram_bit_direct(
      x            : IN  INTEGER;
      y            : IN  INTEGER;
      b            : IN  STD_LOGIC;
      VARIABLE ram : OUT ram_array) IS
      -- writes pixel (x,y) 
      VARIABLE bitnum : INTEGER;
      VARIABLE locnum : INTEGER;
   BEGIN
      bitnum              := (x MOD 4) + 4*(y MOD 4);
      locnum              := (x/4)+(y/4)*(screen_width/4);
      ram(locnum)(bitnum) := b;
   END write_ram_bit_direct;


   IMPURE FUNCTION read_ram_bit_direct(
      x   : IN INTEGER;
      y   : IN INTEGER;
      ram : IN ram_array)
      RETURN STD_LOGIC IS

      -- reads pixel (x,y) from ram
      -- value returned is '0' (white) or '1' (black)

      VARIABLE bitnum : INTEGER;
      VARIABLE locnum : INTEGER;
   BEGIN
      bitnum := (x MOD 4) + 4*(y MOD 4);
      locnum := (x/4)+(y/4)*(screen_width/4);
      RETURN ram(locnum)(bitnum);
   END read_ram_bit_direct;


   PROCEDURE clear_ram_direct( VARIABLE ram : OUT ram_array) IS
      -- this procedure clears ram to an initial colour of all black
   BEGIN
      FOR i IN ram'RANGE LOOP
         ram(i) := (OTHERS => '0');
      END LOOP;
   END;


   PROCEDURE display_ram( VARIABLE ram : IN ram_array;
                          window_size  : IN INTEGER
                          ) IS
      -- this procedure displays the contents of ram on
      -- the transcript, as a 64*64 block of characters
      -- black is represented by *, white by +
      -- the bottom left hand corner of the block
      -- represents pixel (0,0)

      VARIABLE buff : LINE;
      VARIABLE ch   : CHARACTER;

   BEGIN
      ASSERT window_size <= screen_width REPORT
                            "Window_size must be less than " & i2s(screen_width)
                            SEVERITY error;

      FOR y IN window_size-1 DOWNTO 0 LOOP
         FOR x IN 0 TO window_size-1 LOOP

            CASE read_ram_bit_direct(x, y, ram) IS
               WHEN '0'    => ch := '+';
               WHEN '1'    => ch := '*';
               WHEN 'U'    => ch := 'U';
               WHEN OTHERS => ch := 'X';
            END CASE;

            write( buff, ch);
         END LOOP;
         writeline( output, buff);
      END LOOP;
   END display_ram;




   --------------------------------------------------------------
   ----------------------------behavioural host  ----------------
   --------------------------------------------------------------

   -- code command parameters in 16 bit word and hanshake it onto
   -- the VDP bus (hdb, dav, hdb_busy)
   PROCEDURE send_vdp_command(
      -- command parameters
      x   : INTEGER;
      y   : INTEGER;
      pen : pen_type;
      cmd : cmd_type;

      -- host bus I/O signals
      SIGNAL hdb      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      SIGNAL dav      : OUT STD_LOGIC;
      SIGNAL hdb_busy : IN  STD_LOGIC;
      SIGNAL clk      : IN std_logic
      ) IS

      VARIABLE cmdword : STD_LOGIC_VECTOR(15 DOWNTO 0);
      -- drive host bus with a new command
      -- wait until handshake is complete before returning
   BEGIN

      -- check parameters are legal
      ASSERT x >= 0 AND x < 64 AND y >= 0 AND y < 64 REPORT
         "Invalid parameters for send_vdp_command : x = " & i2s(x) &
         ", y = " & i2s(y)
         SEVERITY error;

      CASE cmd IS
         WHEN movepen     => cmdword(15 DOWNTO 14) := "00";
         WHEN drawline    => cmdword(15 DOWNTO 14) := "01";
         WHEN clearscreen => cmdword(15 DOWNTO 14) := "10";
         WHEN flushcache => cmdword(15 DOWNTO 14) := "11";
      END CASE;

      CASE pen IS
         WHEN black  => cmdword(1 DOWNTO 0) := "10";
         WHEN white  => cmdword(1 DOWNTO 0) := "01";
         WHEN invert => cmdword(1 DOWNTO 0) := "11";
      END CASE;

      cmdword(13 DOWNTO 8) := conv_std_logic_vector( x, 6);
      cmdword( 7 DOWNTO 2) := conv_std_logic_vector( y, 6);

      -- terminate last command if necessary
      ASSERT hdb_busy = '0' OR hdb_busy = '1' REPORT
         "hdb_busy (" & STD_LOGIC'IMAGE(hdb_busy) & " is not a valid value"
      SEVERITY error;

      hdb <= cmdword;         -- put command on host bus
      dav <= '1';
      WAIT UNTIL clk'EVENT and clk='1';
      WHILE hdb_busy = '1' LOOP
        WAIT UNTIL clk'EVENT and clk='1';
      END LOOP;
      dav <= '0';             -- host side of handshake is now complete

   END send_vdp_command;


   ----------------------------------------------------------
   ------------- Software VDP  --------------------------------
   ----------------------------------------------------------


   PROCEDURE decode_paras(
      cmdword      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      VARIABLE cmd : OUT cmd_type;
      VARIABLE x   : OUT INTEGER;
      VARIABLE y   : OUT INTEGER;
      VARIABLE pen : OUT pen_type
      ) IS

   BEGIN
      CASE cmdword(15 DOWNTO 14) IS
         WHEN "00"   => cmd := movepen;
         WHEN "01"   => cmd := drawline;
         WHEN "10"   => cmd := clearscreen;
         WHEN "11"   => cmd := flushcache;
         WHEN OTHERS => REPORT "bad cmd field for do_command : " &
                           v2s(cmdword(15 DOWNTO 14));
      END CASE;


      CASE cmdword(1 DOWNTO 0) IS
         WHEN "10"   => pen := black;
         WHEN "01"   => pen := white;
         WHEN "11"   => pen := invert;
         WHEN OTHERS => REPORT "bad pen field for do_command : " &
                           v2s(cmdword(1 DOWNTO 0));
      END CASE;

      x := conv_integer(UNSIGNED(cmdword(13 DOWNTO 8)));
      y := conv_integer(UNSIGNED(cmdword(7 DOWNTO 2)));

   END PROCEDURE decode_paras;

   -- persistant state for do_command
   SHARED VARIABLE x_old : INTEGER RANGE 0 TO 63 := 0;
   SHARED VARIABLE y_old : INTEGER RANGE 0 TO 63 := 0;

   TYPE image_vector IS RECORD
                           x : INTEGER;
                           y : INTEGER;
                        END RECORD;





   PROCEDURE do_vdp_command(
      cmd               : IN  cmd_type;
      x                 : IN  INTEGER;
      y                 : IN  INTEGER;
      pen               : IN  pen_type;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC;
      dest              : IN  ram_mode_type
      ) IS

      VARIABLE xt, yt : INTEGER;  -- temporary coordinates
      VARIABLE z      : INTEGER;  --temporary current perpendicular offset

      VARIABLE xa, xb, ya, yb, yinc : INTEGER;
      VARIABLE v1, v2, vdir, v      : image_vector;
      VARIABLE oct                  : STD_LOGIC_VECTOR( 0 TO 2);  -- bits determine octant


      PROCEDURE change_ram_bit(
         x                 : IN  INTEGER;
         y                 : IN  INTEGER;
         pen               : IN  pen_type;
         SIGNAL cycle_init : OUT STD_LOGIC;
         SIGNAL cycle_done : IN  STD_LOGIC;
         dest              : IN  ram_mode_type
         ) IS
         -- alters (x,y) pixel in image ram_array as specified by pen
         -- may need to read and write to ram_array (for invert writing)
         VARIABLE val : STD_LOGIC;  -- initial value in ram of bit to be written
      BEGIN
         CASE pen IS
            WHEN black  => write_ram_bit( x, y, '1', cycle_init, cycle_done, dest);
            WHEN white  => write_ram_bit( x, y, '0', cycle_init, cycle_done, dest);
            WHEN invert =>
               read_ram_bit(x, y, cycle_init, cycle_done, dest, val);
               write_ram_bit( x, y, NOT val, cycle_init, cycle_done, dest);
         END CASE;
      END change_ram_bit;

      FUNCTION cross(
         v1 : image_vector;
         v2 : image_vector
         ) RETURN INTEGER IS
         -- magnitude of v1 component in direction perpendicular to v2
      BEGIN
         RETURN v1.x*v2.y-v1.y*v2.x;
      END cross;

      PROCEDURE swap(
         -- sets big, small from a,b swapping if necessary so that big > small
         a              : IN  INTEGER;
         b              : IN  INTEGER;
         VARIABLE big   : OUT INTEGER;
         VARIABLE small : OUT INTEGER
         ) IS
      BEGIN
         big   := maximum(a, b);
         small := minimum(a, b);
      END swap;




   BEGIN
      -- implement the command by writing bits in ram
      CASE cmd IS
         WHEN movepen     => NULL;
         WHEN clearscreen =>
            swap( x, x_old, xb, xa);
            swap( y, y_old, yb, ya);
            --REPORT "clearing screen... xa=" & i2s(xa) &", xb="&i2s(xb)&
            --   ", ya="&i2s(ya)&", yb="&i2s(yb);
            -- xa<xb and ya<yb
            FOR i IN xa TO xb LOOP
               FOR j IN ya TO yb LOOP
                  change_ram_bit( i, j, pen, cycle_init, cycle_done, dest);
               END LOOP;
            END LOOP;
         -- flush cache does nothing in the behavioural VDP
         WHEN flushcache => NULL;
         WHEN drawline =>
            -- print out stuff for debugging 
            -- REPORT integer'image(x_old) & ", " & integer'image(y_old) & "   " &
            --     integer'image(x) & "," & integer'image(y);
            --
            -- swap coordinates so that we are always drawing line in direction
            -- of octant 1 or 2, 7 or 8 (ie x increasing)
            xt   := x_old;
            yt   := y_old;
            z    := 0;
            vdir := (x-x_old, y-y_old);  -- vector to draw
            FOR i IN 0 TO 2 LOOP
               oct(i) := '0';
            END LOOP;

            IF vdir.x > 0 THEN
               oct(0) := '1';
            END IF;

            IF vdir.y > 0 THEN
               oct(1) := '1';
            END IF;


            IF ABS(vdir.x) > ABS(vdir.y) THEN
               oct(2) := '1';
            END IF;
            CASE oct IS
               WHEN "111" => v1 := (1,1); v2 := (1,0);
               WHEN "110" => v1 := (0,1); v2 := (1,1);
               WHEN "010" => v1 := (-1,1); v2 := (0,1);
               WHEN "011" => v1 := (-1,0); v2 := (-1,1);
               WHEN "001" => v1 := (-1,-1); v2 := (-1,0);
               WHEN "000" => v1 := (0,-1); v2 := (-1,-1);
               WHEN "100" => v1 := (1,-1); v2 := (0,-1);
               WHEN "101" => v1 := (1,0); v2 := (1,-1);

               WHEN OTHERS => NULL;
            END CASE;


            -- implement line drawing algorithm

            WHILE NOT((xt = x) AND (yt = y)) LOOP
               -- this check should always pass
               ASSERT (ABS(xt) < 65) AND (ABS(yt) < 65)
                  REPORT "Overflow: xt=" & INTEGER'IMAGE(xt) & ", yt=" & INTEGER'IMAGE(yt) &
                  ", z=" & INTEGER'IMAGE(z) &
                  ", vdir=(" & INTEGER'IMAGE(vdir.x) & "," & INTEGER'IMAGE(vdir.y)& ")"
                  SEVERITY failure;
               
               change_ram_bit( xt, yt, pen, cycle_init, cycle_done, dest);
               IF ABS(z + cross( v1, vdir)) < ABS(z+cross(v2, vdir)) THEN
                  v := v1;
               ELSE
                  v := v2;
               END IF;
               xt := xt+v.x; yt := yt+v.y;
               z  := z + cross( v, vdir);
            END LOOP;
            -- set last pixel
            change_ram_bit( xt, yt, pen, cycle_init, cycle_done, dest);
      END CASE;
      -- tidy up setting old coords to new
      x_old := x;
      y_old := y;
      -- finished!    
   END do_vdp_command;


   PROCEDURE write_lines(fname : IN STRING) IS

      -- writes out a sequence of commands to a file with filename fname
      -- the commands draw a star pattern on the screen, including lines
      -- in every possible octant, and every octant boundary
      -- The file can be read, and run through the behavioural VDP
      -- using vdp_testbench.

      CONSTANT r       : INTEGER := 10;
      CONSTANT xcentre : INTEGER := 32;
      CONSTANT ycentre : INTEGER := 32;

      FILE f : TEXT OPEN write_mode IS fname;

      VARIABLE buf : LINE;

   BEGIN

      FOR i IN -2 TO 2 LOOP
         FOR j IN -2 TO 2 LOOP
            IF ABS(i) = 2 OR ABS(j) = 2 THEN

               write( buf, STRING'("MB "));
               write( buf, xcentre+r*i);
               write( buf, STRING'(" "));
               write( buf, ycentre+r*j);
               writeline(f, buf);

               write( buf, STRING'("DB "));
               write( buf, xcentre);
               write( buf, STRING'(" "));
               write( buf, ycentre);
               writeline(f, buf);
            END IF;
         END LOOP;
      END LOOP;
   END write_lines;





-- this runs a set of commands from file fname through a behavioural
-- VDP which writes to ram using do_ram_cycle, with destination ram_data_model
   PROCEDURE run_command_file(
      fname             : IN  STRING;
      SIGNAL cycle_init : OUT STD_LOGIC;
      SIGNAL cycle_done : IN  STD_LOGIC
      ) IS

      FILE f            : TEXT OPEN read_mode IS fname;
      VARIABLE buf      : LINE;
      VARIABLE ch       : CHARACTER;
      VARIABLE cmd      : cmd_type;
      VARIABLE pen      : pen_type;
      VARIABLE x, y     : INTEGER;
      VARIABLE n        : INTEGER;
      VARIABLE skipline : BOOLEAN;
      
   BEGIN
      n := 1;

      WHILE NOT endfile(f) LOOP
         readline( f, buf);
         skipline := false;
         If buf'LENGTH = 0 THEN
             skipline := true;
             --REPORT "skipping line: " & integer'IMAGE(n) SEVERITY note;
         ELSE
             --REPORT  "Reading command:" & integer'image(n) SEVERITY note;
             read( buf, ch);
         END IF;
         CASE ch IS
            WHEN 'D'    => cmd      := drawline;
            WHEN 'M'    => cmd      := movepen;
            WHEN 'C'    => cmd      := clearscreen;
            WHEN 'F'    => cmd      := flushcache;
            WHEN '-'    => skipline := true;
            WHEN OTHERS =>
               REPORT "Bad character ("& ch &
                  ") should be [DMC] in col 1, line "&i2s(n);
         END CASE;
         IF NOT skipline THEN
            read( buf, ch);
            CASE ch IS
               WHEN 'B'    => pen := black;
               WHEN 'W'    => pen := white;
               WHEN 'I'    => pen := invert;
               WHEN OTHERS =>
                  REPORT "Bad character ("& ch &
                     ") should be [BWI] in col 2, line "&i2s(n);
            END CASE;

            read( buf, x);
            read( buf, y);
            do_vdp_command(cmd, x, y, pen, cycle_init, cycle_done, model);
         END IF;

         n := n+1;
      END LOOP;
      
   END run_command_file;


END vdp_pack;


