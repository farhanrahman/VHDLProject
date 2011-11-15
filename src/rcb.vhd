LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY rcb IS
	PORT(
		clk			: IN std_logic;
		x,y 		: IN std_logic_vector(5 DOWNTO 0);
		rcbcmd 		: IN std_logic_vector(2 DOWNTO 0);
		startcmd 	: IN std_logic;
		delaycmd 	: OUT std_logic
	);
END ENTITY rcb;


ARCHITECTURE behav OF rcb IS

BEGIN

C1 : PROCESS
BEGIN

WAIT UNTIL rising_edge(clk);


END PROCESS C1;

END ARCHITECTURE behav;