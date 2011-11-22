LIBRARY IEEE;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_1164.ALL;
USE work.pix_cache_pak.ALL;

ENTITY pix_write_cache IS
GENERIC(
	a_size : INTEGER := 8;
	w_size : INTEGER := 16
);
PORT(
	clk, reset, start	: IN 	std_logic;
	store				: IN 	store_t;
	address				: IN 	std_logic_vector(a_size - 1 DOWNTO 0);
	waitx				: OUT 	std_logic;
	vwrite				: OUT 	std_logic;
	vdout				: IN 	std_logic_vector(w_size - 1 DOWNTO 0);
	vdin 				: OUT 	std_logic_vector(w_size - 1 DOWNTO 0);
	vaddr				: OUT 	std_logic_vector(w_size - 1 DOWNTO 0)
);

END pix_write_cache;

ARCHITECTURE rtl OF pix_write_cache IS
	SIGNAL address_del 	: std_logic_vector(a_size - 1 DOWNTO 0);
	SIGNAL add_temp		: std_logic_vector(a_size - 1 DOWNTO 0);
	SIGNAL store_del	: std_logic_vector(w_size - 1 DOWNTO 0);
	SIGNAL store_temp	: std_logic_vector(w_size - 1 DOWNTO 0);
BEGIN

address_delay: PROCESS
BEGIN
WAIT UNTIL falling_edge(clk);
	address_del <= address;
END PROCESS address_delay;

store_delay : PROCESS
BEGIN
WAIT UNTIL falling_edge(clk);
	FOR i IN store'RANGE LOOP
		--CASE store IS
		--	WHEN invert =>  
		--	WHEN black  =>
		--	WHEN white  =>
		--	WHEN OTHERS => NULL;
		--END CASE;
	END LOOP;
END PROCESS store_delay;

address_register : PROCESS
BEGIN
	add_temp <= address;
END PROCESS address_register;

store_register : PROCESS
BEGIN
	store_temp <= store;
END PROCESS store_register;

END ARCHITECTURE rtl;