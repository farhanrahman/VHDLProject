LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.rcb;
USE work.pix_cache_pak.ALL;

ENTITY clearscreen IS
GENERIC(
	x_size : INTEGER := 6;
	p_size : INTEGER := 4;
	a_size : INTEGER := 8
);
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

--FLUSH, CLEAR AND DRAW--
SIGNAL flush, clear, draw 		: std_logic;


--ALIAS--
	ALIAS slv  IS std_logic_vector;
	ALIAS usg  IS unsigned;
	ALIAS sg   IS signed;

BEGIN

delaycmd <= delaycmd1; startcmd_out <= startcmd_out1;
x_out <= x_out1; y_out <= y_out1;
rcbcmd_out <= rcbcmd_out1;

FLUSH_PARSE : PROCESS (rcbcmd, startcmd)
BEGIN
	IF startcmd = '1' THEN
		flush <= NOT rcbcmd(2) AND NOT rcbcmd(1) AND NOT rcbcmd(0);
	ELSE 
		flush <= '0';
	END IF;
END PROCESS FLUSH_PARSE;

PARSE_CMD : PROCESS(rcbcmd, flush, startcmd)
BEGIN
	IF startcmd = '1' THEN
		IF rcbcmd(2) = '1' AND rcbcmd(1) /= '0' AND rcbcmd(0) /= '0' THEN--rcbcmd(2);
			clear <= '1';
		ELSE 
			clear <= '0';
		END IF;
		draw  <= (NOT rcbcmd(2) AND NOT flush) OR (rcbcmd(2) AND NOT flush);
	ELSE
		clear <= '0';
		draw <= '0';
	END IF;
END PROCESS PARSE_CMD;


FSM_COMB : PROCESS (state, reset, delaycmd_in, startcmd, rcbcmd, x, y, currentX, currentY, oldX, oldY)
	VARIABLE x1,x2 			: std_logic_vector(x_size - 1 DOWNTO 0);
	VARIABLE y1,y2 			: std_logic_vector(x_size - 1 DOWNTO 0);
	VARIABLE thisX, thisY 	: std_logic_vector(x_size - 1 DOWNTO 0);
	VARIABLE pixnum			: std_logic_vector(p_size - 1 DOWNTO 0);
	VARIABLE pixword		: std_logic_vector(a_size - 1 DOWNTO 0);
	VARIABLE rcbcmd_var		: std_logic_vector(2 DOWNTO 0);
	CONSTANT pixnum_end		: std_logic_vector(p_size - 1 DOWNTO 0) := (OTHERS => '1');
	CONSTANT pixword_end	: std_logic_vector(a_size - 1 DOWNTO 0) := (OTHERS => '1');
BEGIN
IF reset = '1' THEN 
	nstate <= idle;
ELSE 
	nstate <= state;
	delaycmd1 		<= delaycmd_in;
	startcmd_out1 	<= startcmd;
	rcbcmd_out1 	<= rcbcmd;
	y_out1 			<= y;
	x_out1 			<= x;
	--PASS THROUGH END--
	--ASSIGNING VARIABLES--
	x1 := oldX;
	y1 := oldY;
	x2 := currentX;
	y2 := currentY;
	thisX := (OTHERS => '0');
	thisY := (OTHERS => '0');
	pixnum := (OTHERS => '0');
	pixword := (OTHERS => '0');	
	CASE state IS
		WHEN idle =>
			--PASS THROUGH BEGIN--

			rcbcmd_var := rcbcmd;
			 IF (rcbcmd(2) = '1') THEN -- AND rcbcmd(1) /= '0' AND rcbcmd(0) /= '0') THEN
				nstate <= check;
			 END IF;
		WHEN check =>
			delaycmd1 <= '1';
			startcmd_out1 <= '0';
			thisX := pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0);
			thisY := pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2);
			IF ((abs(sg(usg(thisX) - usg(x1))) + abs(sg(usg(x2) - usg(thisX)))) = abs(sg(usg(x2) - usg(x1))))
				AND ((abs(sg(usg(thisY) - usg(y1))) + abs(sg(usg(y2) - usg(thisY)))) = abs(sg(usg(y2) - usg(y1)))) THEN
				-- draw(thisX,thisY)
				nstate <= draw_state;
			ELSE
				IF (pixnum = pixnum_end) AND (pixword = pixword_end) THEN
					nstate <= idle;
				ELSE
					IF pixnum = pixnum_end THEN
						pixnum 	:= (OTHERS => '0');
						pixword := slv(usg(pixword) + 1);
					ELSE
						pixnum := slv(usg(pixnum) + 1);
					END IF;
				END IF;
			END IF;
		WHEN draw_state =>
			delaycmd1 <= '1';
			startcmd_out1 <= '1';
			rcbcmd_out1 <= rcbcmd_var;
			x_out1 <= thisX;
			y_out1 <= thisY;
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
IF nstate = idle THEN
	currentX 	<= x;
	currentY 	<= y;
	oldX 		<= currentX;
	oldY 		<= currentY;
END IF;
END PROCESS ASSIGN_STATE;

END ARCHITECTURE rtl;