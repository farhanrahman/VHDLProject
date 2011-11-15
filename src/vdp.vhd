-- top-level Vector Display Processor
-- this file is fully synthesisable
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.vdp_pack.ALL;


ENTITY vdp IS
   PORT(
      clk: IN std_logic;
      reset: IN std_logic;
      -- bus from host
      hdb      : IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
      dav      : IN  STD_LOGIC;
      hdb_busy : OUT STD_LOGIC;

      -- bus to VRAM
      vdin   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      vdout  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      vaddr  : OUT STD_LOGIC_VECTOR;
      vwrite : OUT STD_LOGIC
      );
END vdp;


ARCHITECTURE rtl OF vdp IS




BEGIN


END rtl;      


