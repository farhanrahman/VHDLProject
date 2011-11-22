LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.vram;
USE work.pix_word_cache;
USE work.ram_fsm;


ENTITY rcb IS
	GENERIC(
		w_size 		: INTEGER := 8;
		p_size		: INTEGER := 4
	);
	
	PORT(
		clk, reset	: IN std_logic;
		x,y 		: IN std_logic_vector(5 DOWNTO 0);
		rcbcmd 		: IN std_logic_vector(2 DOWNTO 0);
		startcmd 	: IN std_logic;
		delaycmd 	: OUT std_logic
	);
END ENTITY rcb;


ARCHITECTURE behav OF rcb IS
	SIGNAL pixword 	: std_logic_vector(w_size - 1 DOWNTO 0);
	SIGNAL pixnum 	: std_logic_vector(p_size - 1 DOWNTO 0);
	ALIAS slv IS std_logic_vector;
	ALIAS usg IS unsigned;
	ALIAS sg IS signed;
	
BEGIN

--pcache : ENTITY pix_cache
--	GENERIC MAP(
--		w_size => w_size
--	);
--	PORT MAP(
		
--	);


P1 : PROCESS (x,y,pixword)
	VARIABLE temp_pixword 	: std_logic_vector(w_size - 1 DOWNTO 0);
	VARIABLE temp_pixnum	: std_logic_vector(p_size - 1 DOWNTO 0);
	VARIABLE temp_y		  	: std_logic_vector(w_size - 1 DOWNTO 0);
	VARIABLE temp_y_pix		: std_logic_vector(p_size - 1 DOWNTO 0);
BEGIN
	temp_y := slv(resize(sg(y(5 DOWNTO 2)), w_size) sll 4); --sll 4 needs to change for other bit sizes
	temp_y_pix := slv(resize(sg(y(1 DOWNTO 0)), p_size) sll 2); -- sll 2 needs to change as well
	
	temp_pixword := slv(sg(resize(sg(x(5 DOWNTO 2)), w_size)) + sg(temp_y));
	temp_pixnum := slv(sg(resize(sg(x(1 DOWNTO 0)), p_size)) + sg(temp_y_pix));	
	IF temp_pixword /= pixword THEN
		pixword <= temp_pixword;
		pixnum <= temp_pixnum;
	ELSE --temp_pixword = pixword
			-- flush out the pixel_word_cache
	END IF; -- temp_pixword /= pixword
END PROCESS P1;

C1 : PROCESS
BEGIN

WAIT UNTIL rising_edge(clk);


END PROCESS C1;

END ARCHITECTURE behav;