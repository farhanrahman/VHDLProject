LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY vdp IS

GENERIC(
	vsize: INTEGER := 6;
	asize: INTEGER := 8;
	wsize: INTEGER := 4;
	psize: INTEGER := 2;
	dsize: INTEGER := 16
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
      vaddr  : OUT STD_LOGIC_VECTOR(asize-1 DOWNTO 0);
      vwrite : OUT STD_LOGIC
      );

END ENTITY vdp;

 ARCHITECTURE dave_vdp OF vdp IS
	SIGNAL delaycmd,startcmd 	: std_logic;
	SIGNAL x,y 					: std_logic_vector(vsize - 1 DOWNTO 0);
	SIGNAL rcbcmd 				: std_logic_vector(2 DOWNTO 0);
	
	--Clearscreen OUTPUT--
	SIGNAL delaycmd_cs_out , startcmd_cs_out 	: std_logic;
	SIGNAL x_cs_out, y_cs_out 					: std_logic_vector(vsize - 1 DOWNTO 0);
	SIGNAL rcbcmd_cs_out						: std_logic_vector(2 DOWNTO 0);
	
BEGIN
	
	db: ENTITY draw_block
	PORT MAP(
			clk 		=> clk,
			reset 		=> reset,
			hdb_dav 	=> dav,
			hdb			=> hdb,	
			hdb_busy 	=> hdb_busy,
			delaycmd 	=> delaycmd_cs_out,
			x 			=> x,
			y 			=> y,
			rcbcmd 		=> rcbcmd,
			startcmd 	=> startcmd
	);

	cs : ENTITY clearscreen
	PORT MAP(
		clk 			=> clk, 
		reset 			=> reset,
		x 				=> x,
		y 				=> y,
		rcbcmd 			=> rcbcmd,
		startcmd 		=> startcmd,
		delaycmd_in		=> delaycmd,
		-- OUTPUTS--
		delaycmd 		=> delaycmd_cs_out,
		x_out 			=> x_cs_out, 
		y_out 			=> y_cs_out,
		rcbcmd_out 		=> rcbcmd_cs_out,
		startcmd_out 	=> startcmd_cs_out
	);
	
	rb : ENTITY rcb
	PORT MAP(
			clk 		=> clk, 
			reset 		=> reset,
			x 			=> x_cs_out,
			y 			=> y_cs_out,
			rcbcmd 		=> rcbcmd_cs_out,
			startcmd 	=> startcmd_cs_out,
			delaycmd 	=> delaycmd,
			vaddr 		=> vaddr,
			vdin  		=> vdin,
			vdout  		=> vdout,
			vwrite 		=> vwrite
	);	
	
	
END dave_vdp;      