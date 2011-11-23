--DRAW BLOCK takes input from Host processor and outputs to rcb
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY draw_block IS
	PORT(
		-- HOST INTERFACE
		clk,reset,hdb_dav	: IN std_logic;
		hdb			: IN std_logic(15 DOWNTO 0);	
		hdb_busy		: OUT std_logic;
				
		-- DB/RCB Interface
		delaycmd 		: IN std_logic;
		x,y 			: OUT std_logic_vector(5 DOWNTO 0);
		rcbcmd 			: OUT std_logic_vector(2 DOWNTO 0);
		startcmd 		: OUT std_logic
	);
END ENTITY draw_block;


ARCHITECTURE behav OF draw_block IS
	
BEGIN

-- wrapper for draw_any_octant
draw_block_i 	: ENTITY draw_any_octant
	PORT MAP(
		-- IN
		clk    => clk,
		resetx => resetx,
		draw   => draw,
		xbias  => xbias1,
		xin    => xin1,
		yin    => yin1,
		swapxy => ,
		negx   => ,
		negy   => ,
		-- OUT
		done   => done,
		x      => x1,
		y      => y1
		);

-- wrapper for db-fsm
fsm_i		: ENTITY db_fsm
	PORT MAP(
		-- HOST SIGNALS
		clk => clk,
		reset => reset,
		ready => hdb_dav,
		op => hdb(15 DOWNTO 14),
		xin => hdb(13 DOWNTO 8),
		yin => hdb(7 DOWNTO 2),
		pen => hdb(1 DOWNTO 0),
		busy => hdb_busy,

		-- DRAWOCTANT


		-- RCB SIGNALS


		);


-- Combinational Process
C1 : PROCESS
BEGIN

    WAIT UNTIL clk'EVENT and clk='1';


END PROCESS C1;

END ARCHITECTURE behav;
