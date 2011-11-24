--DRAW BLOCK takes input from Host processor and outputs to rcb, implemented as FSM
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY draw_block IS
	GENERIC(
		xsize			: INTEGER := 6;
		ysize			: INTEGER := 6;
		);
	PORT(
		-- HOST INTERFACE
		clk,reset,hdb_dav	: IN std_logic;
		hdb			: IN std_logic(15 DOWNTO 0);	
		hdb_busy		: OUT std_logic;
				
		-- DB/RCB Interface
		delaycmd 		: IN std_logic;
		x 			: OUT std_logic_vector(xsize-1 DOWNTO 0);
		y			: OUT std_logic_vector(ysize-1 DOWNTO 0);
		rcbcmd 			: OUT std_logic_vector(2 DOWNTO 0);
		startcmd 		: OUT std_logic
	);
END ENTITY draw_block;

ARCHITECTURE behav OF draw_block IS

TYPE   state_t IS (m3, m2, m1, mx);

SIGNAL state, nstate  	: state_t;
SIGNAL delay1         	: std_logic;

SIGNAL penx, peny	: std_logic_vector(5 DOWNTO 0);
	
BEGIN

-- wrapper for draw_any_octant

-- swapxy negx  negy  octant
--  0      0      0     ENE
--  1      0      0     NNE
--  1      1      0     NNW
--  0      1      0     WNW
--  0      1      1     WSW
--  1      1      1     SSW
--  1      0      1     SSE
--  0      0      1     ESE

draw_block_i 	: ENTITY draw_any_octant
	PORT MAP(
		-- IN
		clk    => clk,
		resetx => oreset,
		draw   => odraw,
		xbias  => oxbias1,
		xin    => oxin,
		yin    => oyin,
		swapxy => oswapxy,
		negx   => onegx,
		negy   => onegy,
		-- OUT
		done   => odone,
		x      => ox1,
		y      => oy1
		);

-- Configure draw octant - Combinational
OCT: PROCESS(hdb, penx, peny)
BEGIN
	xbias <= '1';
	
	-- Shall we swap xy? reflects on x=y 
	IF (abs(signed(hdb(13 DOWNTO 8) - penx)) < abs(signed(hdb(7 DOWNTO 2) - peny))) THEN
		swapxy <= '1';
	ELSE	
		swapxy <= '0';
	
	-- Is x negative?
	IF (penx > hdb(13 DOWNTO 8)) THEN 
		negx <= '1';
	ELSE
		negx <= '0';
	END IF;


	-- Is y negative?
	IF (peny > hdb(7 DOWNTO 2)) THEN 
		negy <= '1';
	ELSE
		negy <= '0';
	END IF;

END PROCESS OCT;

-- State Combinational Logic
STATE: PROCESS()
BEGIN

	--defaults
	nstate <= state;

	CASE state IS
		WHEN reset =>

	END CASE;

END PROCESS STATE;

--Clocked Logic
FSM: PROCESS
BEGIN
  WAIT UNTIL clk'EVENT AND clk = '1';
  state <= nstate;
END PROCESS FSM;

END ARCHITECTURE behav;
