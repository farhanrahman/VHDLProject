LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.rcb;
USE work.pix_cache_pak.ALL;
USE work.cl_utility.ALL;
USE work.cl_pack.ALL;
ENTITY clearscreen IS
PORT(
	clk, reset		: IN  std_logic;
	x,y 			: IN  std_logic_vector(x_size - 1 DOWNTO 0);
	rcbcmd 			: IN  std_logic_vector(2 DOWNTO 0);
	startcmd 		: IN  std_logic;
	delaycmd_in		: IN  std_logic;
	-- OUTPUTS--
	delaycmd 		: OUT std_logic;
	x_out, y_out	: OUT std_logic_vector(x_size - 1 DOWNTO 0);
	rcbcmd_out		: OUT std_logic_vector(2 DOWNTO 0);
	startcmd_out 	: OUT std_logic
);

END ENTITY clearscreen;

ARCHITECTURE rtl OF clearscreen IS

TYPE states IS (idle, check, draw_state);
SIGNAL state 				: states;
SIGNAL nstate 				: states;
SIGNAL currentX, currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
SIGNAL oldX, oldY			: std_logic_vector(x_size - 1 DOWNTO 0);


-- DUMMY OUTPUTS--
SIGNAL delaycmd1, startcmd_out1 : std_logic;
SIGNAL x_out1, y_out1 			: std_logic_vector(x_size - 1 DOWNTO 0);
SIGNAL rcbcmd_out1				: std_logic_vector(2 DOWNTO 0);


--ALIAS--
	ALIAS slv  IS std_logic_vector;
	ALIAS usg  IS unsigned;
	ALIAS sg   IS signed;
	CONSTANT pixnum_end		: std_logic_vector(p_size - 1 DOWNTO 0) := (OTHERS => '1');
	CONSTANT pixword_end	: std_logic_vector(a_size - 1 DOWNTO 0) := (OTHERS => '1');
	
	SIGNAL pixnum			: std_logic_vector(p_size - 1 DOWNTO 0);
	SIGNAL pixword			: std_logic_vector(a_size - 1 DOWNTO 0);	
BEGIN

delaycmd <= delaycmd1; startcmd_out <= startcmd_out1;
x_out <= x_out1; y_out <= y_out1;
rcbcmd_out <= rcbcmd_out1;



FSM_COMB : PROCESS (state, reset, delaycmd_in, startcmd, rcbcmd, x, y, currentX, currentY, oldX, oldY, pixword, pixnum)--, pixnum_reg, pixword_reg)

VARIABLE maxX : std_logic_vector(x_size - 1 DOWNTO 0);
VARIABLE maxY : std_logic_vector(x_size - 1 DOWNTO 0);

BEGIN

IF usg(currentX) >  usg(oldX) THEN
	maxX := currentX;
ELSE
	maxX := oldX;
END IF;

IF usg(currentY) > usg(oldY) THEN
	maxY := currentY;
ELSE
	maxY := oldY;
END IF;

IF reset = '1' THEN 
	nstate 			<= idle;
	delaycmd1 		<= delaycmd_in;
	startcmd_out1 	<= startcmd;
	rcbcmd_out1 	<= rcbcmd;
	y_out1 			<= y;
	x_out1 			<= x;
ELSE 
	nstate 			<= state;
	delaycmd1 		<= delaycmd_in;
	startcmd_out1 	<= startcmd;
	rcbcmd_out1 	<= rcbcmd;
	x_out1 			<= x;
	y_out1 			<= y;

	CASE state IS
		WHEN idle =>
			 IF rcbcmd(2) = '1' THEN
				x_out1 <= (OTHERS => '0');
				y_out1 <= (OTHERS => '0');
				nstate <= check;
			 END IF;
		WHEN check =>
			delaycmd1 <= '1';
			startcmd_out1 <= '0';
			x_out1 	<= pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0);
			y_out1 	<= pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2);			
			IF oldX = currentX AND oldY = currentY THEN
				nstate <= idle; --need to fix this..have to clear single pixel.
			END IF;
			
			IF is_in_rect(pixnum, pixword, currentX, currentY, oldX, oldY) THEN
			
				-- check if pixel is within given rectangle
				nstate <= draw_state;
			ELSE
				IF (pixnum = pixnum_end) AND (pixword = pixword_end) THEN
					nstate <= idle;
				END IF;
				
				IF is_outside_max_points(pixnum, pixword, maxX, maxY) THEN
					nstate <= idle;
				END IF;
				
			END IF;
		WHEN draw_state =>	
			delaycmd1 <= '1';
			startcmd_out1 <= '1';
			rcbcmd_out1 <= rcbcmd;
			x_out1 	<= pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0);
			y_out1 	<= pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2);
			IF delaycmd_in = '0' THEN
				nstate <= check;
			END IF;
	END CASE;
END IF;

END PROCESS FSM_COMB;

ASSIGN_STATE : PROCESS
BEGIN
WAIT UNTIL rising_edge(clk);
	state <= nstate;
	currentX 	<= x;
	currentY 	<= y;

IF nstate = idle THEN
	pixnum 			<= (OTHERS => '0');
	pixword			<= (OTHERS => '0');
END IF;	
IF state = idle AND nstate = check THEN
	oldX 		<= currentX;
	oldY 		<= currentY;
END IF;
IF state = draw_state AND nstate = check AND delaycmd_in = '0' THEN
	IF pixnum = pixnum_end THEN
		pixnum 	<= (OTHERS => '0');
		pixword <= slv(usg(pixword) + 1);
	ELSE
		pixnum <= slv(usg(pixnum) + 1);
	END IF;
END IF;
IF state = check THEN
	IF NOT is_in_rect(pixnum, pixword, currentX, currentY, oldX, oldY) THEN
		IF pixnum = pixnum_end THEN
			pixnum 	<= (OTHERS => '0');
			pixword <= slv(usg(pixword) + 1);
		ELSE
			pixnum <= slv(usg(pixnum) + 1);
		END IF;
		
		IF is_greaterthan_maxX(oldX, oldY, currentX, currentY, pixnum, pixword) AND pixnum = pixnum_end THEN
			IF pixword /= pixword_end THEN
				pixnum <= (OTHERS => '0');
				pixword <= slv(usg(pixword) + 16 - usg(pixword(3 DOWNTO 0)));
			END IF;
		END IF;				
	END IF;
END IF;
END PROCESS ASSIGN_STATE;

END ARCHITECTURE rtl;