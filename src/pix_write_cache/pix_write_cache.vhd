LIBRARY IEEE;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_1164.ALL;
USE work.pix_cache_pak.ALL;
USE work.ram_fsm;

ENTITY pix_write_cache IS
GENERIC(
	a_size : INTEGER := 8;
	w_size : INTEGER := 16
);
PORT(
	clk, reset, start	 		: IN 	std_logic;
	store				        : IN 	store_t;
	address				        : IN 	std_logic_vector(a_size - 1 DOWNTO 0);
	waitx				        : OUT 	std_logic;
	vwrite				        : OUT 	std_logic;
	vdout				        : IN 	std_logic_vector(w_size - 1 DOWNTO 0);
	vdin 				        : OUT 	std_logic_vector(w_size - 1 DOWNTO 0);
	vaddr				        : OUT 	std_logic_vector(a_size - 1 DOWNTO 0)
);

END pix_write_cache;

ARCHITECTURE rtl OF pix_write_cache IS
BEGIN

ramfsm : ENTITY work.ram_fsm
  PORT MAP(
    clk     => clk,
    reset   => reset,
    start   => start,
    vwrite  => vwrite,
    delay   => waitx
  );

address_delay: PROCESS
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN
    vaddr <= (OTHERS=>'0');
  ELSE
    vaddr <= address;
  END IF;
END PROCESS address_delay;

vdin_compute : PROCESS
  --VARIABLE res  : pixop_t;
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN 
    vdin <= (OTHERS=>'0');
  ELSE
    FOR i IN store'RANGE LOOP
      --res := store(i);
      CASE store(i) IS
        WHEN same   => vdin(i) <= vdout(i);
        WHEN invert => vdin(i) <= NOT vdout(i);
        WHEN black  => vdin(i) <= '1';
        WHEN white  => vdin(i) <= '0';
        WHEN OTHERS => NULL;
      END CASE;
    END LOOP;
  END IF;
END PROCESS vdin_compute;

END ARCHITECTURE rtl;