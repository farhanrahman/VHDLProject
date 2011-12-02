-- top-level Vector Display Processor
-- this file is fully synthesisable
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.vdp_pack.ALL;
USE work.rcb;
USE work.draw_block;

ENTITY vdp IS
	GENERIC (
		size : INTEGER := 6	
	);
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

	SIGNAL delaycmd,startcmd : std_logic;
	SIGNAL x,y : std_logic_vector(size - 1 DOWNTO 0);
	SIGNAL rcbcmd : std_logic_vector(2 DOWNTO 0);
	
BEGIN
db: ENTITY draw_block
PORT MAP(
		clk => clk,
		reset => reset,
		hdb_dav => dav,
		hdb	=> hdb,	
		hdb_busy => hdb_busy,
		delaycmd => delaycmd,
		x => x,
		y => y,
		rcbcmd 	=> rcbcmd,
		startcmd => startcmd
);

rb : ENTITY rcb
PORT MAP(
		clk => clk, 
		reset => reset,
		x => x,
		y => y,
		rcbcmd => rcbcmd,
		startcmd => startcmd,
		delaycmd => delaycmd,
		vaddr => vaddr,
		vdin  => vdin,
		vdout  => vdout,
		vwrite => vwrite
);

END rtl;      


