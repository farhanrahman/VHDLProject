--DRAW BLOCK takes input from Host processor and outputs to rcb, implemented as FSM
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE WORK.ALL;

ENTITY draw_block IS
	GENERIC(
		vsize			: INTEGER := 6
		);
	PORT(
		-- HOST INTERFACE
		clk,reset,hdb_dav	: IN std_logic;
		hdb					: IN std_logic_vector(3+(2*vsize) DOWNTO 0);	
		hdb_busy			: OUT std_logic;
				
		-- DB/RCB Interface
		delaycmd 		: IN std_logic;
		x				: OUT std_logic_vector(vsize-1 DOWNTO 0);
		y				: OUT std_logic_vector(vsize-1 DOWNTO 0);
		rcbcmd 			: OUT std_logic_vector(2 DOWNTO 0);
		startcmd 		: OUT std_logic
	);
END ENTITY draw_block;

ARCHITECTURE behav OF draw_block IS
-- FSM Signals
TYPE   state_t				IS (draw_run, draw_start, listen);
SIGNAL state, nstate  		: state_t;

-- General Signals
SIGNAL op, pen								: std_logic_vector(1 DOWNTO 0);
SIGNAL xin									: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL yin									: std_logic_vector(vsize-1 DOWNTO 0); 
SIGNAL penx, penx1							: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL peny, peny1							: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL startcmd1, startcmdreg				: std_logic;
SIGNAL rcbcmd1, rcbcmdreg					: std_logic_vector(2 DOWNTO 0);
SIGNAL xreg, x1, yreg, y1					: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL hdb_busy1, hdb_busyreg				: std_logic;

-- draw_octant signals
SIGNAL swapxy, negx, negy, xbias			: std_logic;
SIGNAL draw_reset, draw_reset1				: std_logic;
SIGNAL draw_done, draw_done1, draw, draw1 	: std_logic;
SIGNAL draw_x								: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL draw_y								: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL dxin, dxin1				   			: std_logic_vector(vsize-1 DOWNTO 0);
SIGNAL dyin, dyin1   						: std_logic_vector(vsize-1 DOWNTO 0); 

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
		resetg => reset,
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
	op  <= hdb(3+(2*vsize) DOWNTO 2+(2*vsize));
	pen <= hdb(1 DOWNTO 0);
	xin <= hdb(1+(2*vsize) DOWNTO 2+vsize);
	yin <= hdb(1+vsize DOWNTO 2);
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
STATECOMB: PROCESS(state, xreg, yreg, dyin, dxin, draw_done, draw_reset, rcbcmdreg, 
						startcmdreg, peny, penx, hdb_busyreg, hdb_dav, xin, yin, pen,
						op, draw_x, draw_y)
BEGIN
	-- defaults
	nstate <= state;
	x1 <= xreg;
	y1 <= yreg;
	dyin1 <= dyin;
	dxin1 <= dxin;
	draw1 <= '0';
	draw_done1 <= draw_done;
	draw_reset1 <= draw_reset;
	rcbcmd1 <= rcbcmdreg;
	startcmd1 <= startcmdreg;
	peny1 <= peny;
	penx1 <= penx;
	hdb_busy1 <= hdb_busyreg;
	
	-- NEED TO WORK OUT BEST WAY TO DO THIS
	-- First, is the input valid?
	IF (hdb_dav = '1') THEN
  
	CASE state IS
		WHEN listen =>
			hdb_busy1 <= '0';
			startcmd1 <= '0';
			
			-- check op and deal with it
			CASE op IS
				WHEN "00" => -- Move pen
					penx1 <= xin;
					peny1 <= yin;

				WHEN "01" => -- Draw
					-- Send start postion to draw_octant
					hdb_busy1 <= '1';
					draw_reset1 <= '1';
					dxin1 <= penx;
					dyin1 <= peny;
					nstate <= draw_start;

				WHEN "10" => -- Clear
					x1 <= xin;
					y1 <= yin;
					rcbcmd1 <= "1" & pen;
					startcmd1 <= '1';	

				WHEN "11" => -- Flush
					rcbcmd1 <= "000";
					startcmd1 <= '1';
					
				WHEN others =>
				  null;

			END CASE;

		WHEN draw_start =>
			-- Send end position to draw_octant
			draw_reset1 <= '0';
			draw1 <= '1';
			dxin1 <= xin;
			dyin1 <= yin;
			nstate <= draw_run;

		WHEN draw_run =>
			-- Run draw sending result to RCB
			draw1 <= '0';
			rcbcmd1 <= "0" & pen;
			x1 <= draw_x;
			y1 <= draw_y;			
			startcmd1 <= '1';

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
WAIT UNTIL clk'EVENT AND clk = '1';
	-- Sychronous Reset
	IF reset = '1' THEN
		state <= listen;
	END IF; 

	-- Update registers
	state <= nstate;
	penx <= penx1;
	peny <= peny1;
	startcmd <= startcmd1;
	startcmdreg <= startcmd1;
	rcbcmd <= rcbcmd1;
	rcbcmdreg <= rcbcmd1;
	dxin <= dxin1;
	dyin <= dyin1;
	draw <= draw1;
	draw_reset <= draw_reset1;
	xreg <= x1;
	yreg <= y1;
	x <= x1;
	y <= y1;
	hdb_busy <= hdb_busy1;
	hdb_busyreg <= hdb_busy1;
	
END PROCESS FSM;

END ARCHITECTURE behav;

