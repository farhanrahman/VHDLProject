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
 
	-- Draw Block Signals
--	SIGNAL db_delaycmd 							: std_logic;
--	SIGNAL db_x, db_y							: std_logic_vector(vsize-1 DOWNTO 0);
--	SIGNAL db_op, db_pen						: std_logic_vector(1 DOWNTO 0);
--	SIGNAL db_xout, db_yout						: std_logic_vector(vsize-1 DOWNTO 0);
--	SIGNAL db_rcbcmd							: std_logic_vector(2 DOWNTO 0);
--	SIGNAL db_startcmd							: std_logic;
--	SIGNAL db_waitcmd							: std_logic;
--	
	-- Ram Block Signals
--	SIGNAL rb_startcmd							:  std_logic;
--	SIGNAL rb_x, rb_y							:  std_logic_vector(vsize-1 DOWNTO 0);
--	SIGNAL rb_rcbcmd							:  std_logic_vector(2 DOWNTO 0);
--	SIGNAL rb_vdout, rb_vdin					:  std_logic_vector(dsize-1 DOWNTO 0);
--	SIGNAL rb_vaddr								:  std_logic_vector(asize-1 DOWNTO 0);
--	SIGNAL rb_vwrite, rb_delaycmd				:  std_logic;
	
	
	SIGNAL delaycmd,startcmd : std_logic;
	SIGNAL x,y : std_logic_vector(vsize - 1 DOWNTO 0);
	SIGNAL rcbcmd : std_logic_vector(2 DOWNTO 0);
	
BEGIN
	-- DRAW BLOCK
--	d_b: ENTITY draw_block
--	PORT MAP (
--		clk     	=> clk,
--		reset   	=> reset,
--		delaycmd	=> db_delaycmd,
--		x			=> db_x,
--		y			=> db_y,
--		op			=> db_op,
--		pen			=> db_pen,
--		xout		=> db_xout,
--		yout		=> db_yout,
--		rcbcmd		=> db_rcbcmd,
--		startcmd	=> db_startcmd,
--		waitcmd		=> db_waitcmd
--	);
	
	
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
	
	-- RAM BLOCK
--	r_b: ENTITY rcb
--	GENERIC MAP (
--		timing_on => TRUE
--	)
--	PORT MAP (	
--		clk     	=> clk,
--		reset   	=> reset,
--		startcmd	=> rb_startcmd,
--		x			=> rb_x,
--		y			=> rb_y,
--		rcbcmd		=> rb_rcbcmd,
--		vdout		=> vdout,
--		vdin		=> vdin,
--		vaddr		=> vaddr,
--		vwrite		=> vwrite,
--		delaycmd	=> rb_delaycmd
--	);
	
	
--	C1: PROCESS (hdb, rb_delaycmd, db_rcbcmd, db_startcmd, db_yout, db_xout, db_waitcmd,dav)
--	BEGIN
	
	-- inputs to DB
	--hdb_busy <= rb_delaycmd;
	
--	IF (db_waitcmd = '1' OR rb_delaycmd = '1') AND dav = '1' THEN
--		hdb_busy <= '1';
--	ELSE
--		hdb_busy <= '0';
--	END IF;
	

	
	
	
--	db_delaycmd <= rb_delaycmd;
--	db_op <= hdb(15 DOWNTO 14);
--	db_x  <= hdb(13 DOWNTO 8);
--	db_y  <= hdb(7 DOWNTO 2);
--	db_pen<= hdb(1 DOWNTO 0);
	
	-- busses between DB and RB
--	rb_rcbcmd <= db_rcbcmd;
--	rb_startcmd <= db_startcmd;
--	rb_y		<= db_yout;
--	rb_x		<= db_xout;

	-- busses between RB and output
	


	
--	END PROCESS C1;
	
END dave_vdp;      