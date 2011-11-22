--DRAW BLOCK takes input from Host processor and outputs to rcb
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY draw_block IS
	PORT(
		-- HOST INTERFACE
		clk,hdb_dav	: IN std_logic;
		hdb		: IN std_logic(15 DOWNTO 0);	
		hdb_busy	: OUT std_logic;
				
		-- DB/RCB Interface
		delaycmd 	: IN std_logic;
		x,y 		: OUT std_logic_vector(5 DOWNTO 0);
		rcbcmd 		: OUT std_logic_vector(2 DOWNTO 0);
		startcmd 	: OUT std_logic
	);
END ENTITY draw_block;


ARCHITECTURE behav OF draw_block IS
	
BEGIN

C1 : PROCESS
BEGIN

    WAIT UNTIL clk'EVENT and clk='1';


END PROCESS C1;

END ARCHITECTURE behav;
