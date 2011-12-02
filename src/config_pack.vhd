USE STD.TEXTIO.ALL;

PACKAGE config_pack IS

  CONSTANT config_clock_period : time :=
    10 ns; -- period of clock
  
  CONSTANT config_file_name : string :=
    "test_commands.txt";  -- name of file of VDP commands run this test
  
  CONSTANT config_post_cycles : integer :=
    100;   -- this makes testbench wait after last command is passed to
           -- VDP before checking final state of RAM. If VDP takes a long
           -- time processing commands it may need to be extended.
  CONSTANT post_command_delay : time :=
    config_clock_period*config_post_cycles;
  
  
  CONSTANT config_window_width : integer :=
    55;    -- this reduces the number of pixels displayed
           -- on the screen at the end of the testbench
           -- set to 64 for full display of RAM memory


           -- RAM timing spec. Note that by default this is all scaled to
           -- clock period so that changing clock frequency doe snot alter
           -- system timing the constants below specify times in number of
           -- clock cycles.
  CONSTANT config_tracc : real := 1.0;
  CONSTANT config_taws  : real := 0.4;
  CONSTANT config_twp   : real := 0.9;
  CONSTANT config_twds  : real := 0.2;
END;
