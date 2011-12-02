--DRAW BLOCK takes input from Host processor and outputs to rcb, implemented as FSM
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE WORK.ALL;

ENTITY draw_block IS
	GENERIC(
		xsize			: INTEGER := 6;
		ysize			: INTEGER := 6
		);
	PORT(
		-- HOST INTERFACE
		clk,reset,hdb_dav	: IN std_logic;
		hdb					: IN std_logic_vector(3+xsize+ysize DOWNTO 0);	
		hdb_busy			: OUT std_logic;
				
		-- DB/RCB Interface
		delaycmd 		: IN std_logic;
		x				: OUT std_logic_vector(xsize-1 DOWNTO 0);
		y				: OUT std_logic_vector(ysize-1 DOWNTO 0);
		rcbcmd 			: OUT std_logic_vector(2 DOWNTO 0);
		startcmd 		: OUT std_logic
	);
END ENTITY draw_block;

ARCHITECTURE behav OF draw_block IS
-- FSM Signals
TYPE   state_t			IS (draw_run, draw_start, listen);
SIGNAL state, nstate  		: state_t;

-- General Signals
SIGNAL op, pen			: std_logic_vector(1 DOWNTO 0);
SIGNAL xin				: std_logic_vector(xsize-1 DOWNTO 0);
SIGNAL yin				: std_logic_vector(ysize-1 DOWNTO 0); 
SIGNAL penx				: std_logic_vector(xsize-1 DOWNTO 0);
SIGNAL peny				: std_logic_vector(ysize-1 DOWNTO 0); 

-- draw_octant signals
SIGNAL swapxy, negx, negy		: std_logic;
SIGNAL draw_reset, draw_done,	draw, xbias : std_logic;
SIGNAL draw_x					: std_logic_vector(xsize-1 DOWNTO 0);
SIGNAL draw_y					: std_logic_vector(ysize-1 DOWNTO 0);
SIGNAL dxin				   : std_logic_vector(xsize-1 DOWNTO 0);
SIGNAL dyin			   	: std_logic_vector(ysize-1 DOWNTO 0); 

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
	GENERIC MAP(
		vsize => 6
	)
	PORT MAP(
		-- IN
		clk    => clk,
		resetx => draw_reset,
		delay  => delaycmd,
		draw   => draw,
		xbias  => xbias,
		xin    => dxin,
		yin    => dyin,
		swapxy => swapxy,
		negx   => negx,
		negy   => negy,
		-- OUT
		done   => draw_done,
		x      => draw_x,
		y      => draw_y
		);

-- Set useful signals
SIGS: PROCESS(hdb)
BEGIN
	op  <= hdb(3+xsize+ysize DOWNTO 2+xsize+ysize);
	pen <= hdb(1 DOWNTO 0);
	xin <= hdb(1+xsize+ysize DOWNTO 2+ysize);
	yin <= hdb(1+ysize DOWNTO 2);
END PROCESS SIGS;

-- Configure draw octant - Combinational
OCT: PROCESS(xin, yin, penx, peny)
BEGIN
	xbias <= '1';
	
	-- Shall we swap xy? reflects on x=y 
	IF (abs(signed(xin) - signed(penx)) < abs(signed(yin) - signed(peny))) THEN
		swapxy <= '1';
	ELSE	
		swapxy <= '0';
	END IF;
	
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
STATECOMB: PROCESS(state, hdb_dav, xin, yin, penx, peny, pen, draw_x, draw_y, op, draw_done)
BEGIN
	-- defaults
	nstate <= state;
	
	-- First, is the input valid?
	IF (hdb_dav = '1') THEN
  
	CASE state IS
		WHEN listen =>
			hdb_busy <= '0';
			startcmd <= '0';
			
			-- check op and deal with it
			CASE op IS
				WHEN "00" => -- Move pen
					penx <= xin;
					peny <= yin;

				WHEN "01" => -- Draw
					-- Send start postion to draw_octant
					hdb_busy <= '1';
					draw_reset <= '1';
					dxin <= penx;
					dyin <= peny;
					nstate <= draw_start;

				WHEN "10" => -- Clear
					x <= xin;
					y <= yin;
					rcbcmd <= "1" & pen;
					startcmd <= '1';	

				WHEN "11" => -- Flush
					rcbcmd <= "000";
					startcmd <= '1';
					
				WHEN others =>
				  null;

			END CASE;

		WHEN draw_start =>
			-- Send end position to draw_octant
			draw_reset <= '0';
			draw <= '1';
			dxin <= xin;
			dyin <= yin;
			nstate <= draw_run;

		WHEN draw_run =>
			-- Run draw sending result to RCB
			rcbcmd <= "0" & pen;
			x <= draw_x;
			y <= draw_y;			
			startcmd <= '1';

			-- Check if finished
			IF (draw_done = '1') THEN
				nstate <= listen;
			END IF;
						
	END CASE;

	END IF;

END PROCESS STATECOMB;


-- State change clocked
FSM: PROCESS
BEGIN
WAIT UNTIL clk'EVENT AND clk = '1' AND delaycmd ='0';
	state <= nstate;
	IF reset = '1' THEN
		state <= listen; -- sychronous reset
	END IF;
END PROCESS FSM;

END ARCHITECTURE behav;
