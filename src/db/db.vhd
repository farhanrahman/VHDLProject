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
		hdb			: IN std_logic(3+xsize+ysize DOWNTO 0);	
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

TYPE   state_t IS (drawing, receiving);

SIGNAL state, nstate  	: state_t;

SIGNAL op, pen		: std_logic(1 DOWNTO 0);
SIGNAL xin		: std_logic(xsize-1 DOWNTO 0);
SIGNAL yin		: std_logic(ysize-1 DOWNTO 0); 

SIGNAL penx		: std_logic(xsize-1 DOWNTO 0);
SIGNAL peny		: std_logic(ysize-1 DOWNTO 0); 

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

-- Set useful signals
SIGS: PROCESS()
BEGIN
	op  <= hdb(3+xsize+ysize DOWNTO 2+xsize+ysize);
	pen <= hdb(1 DOWNTO 0);
	xin <= hdb(1+xsize+ysize DOWNTO 2+ysize);
	yin <= hdb(1+ysize DOWNTO 2);
END

-- Configure draw octant - Combinational
OCT: PROCESS(hdb, penx, peny)
BEGIN
	xbias <= '1';
	
	-- Shall we swap xy? reflects on x=y 
	IF (abs(signed(xin - penx)) < abs(signed(yin - peny))) THEN
		swapxy <= '1';
	ELSE	
		swapxy <= '0';
	
	-- Is x negative?
	IF (penx > xin) THEN 
		negx <= '1';
	ELSE
		negx <= '0';
	END IF;


	-- Is y negative?
	IF (peny > yin) THEN 
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
		WHEN receiving =>
			;	
		WHEN drawing => -- completes drawing operation
			;
	END CASE;

END PROCESS STATE;


-- State change clocked
FSM: PROCESS
BEGIN
WAIT UNTIL clk'EVENT AND clk = '1';
	state <= nstate;
	IF reset = '1' THEN
		state <= waits; -- sychronous reset
	END IF;
END PROCESS FSM;

END ARCHITECTURE behav;
