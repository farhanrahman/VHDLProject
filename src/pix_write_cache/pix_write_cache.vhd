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
	clk, reset, start	 : IN 	std_logic;
	store				          : IN 	store_t;
	address				        : IN 	std_logic_vector(a_size - 1 DOWNTO 0);
	waitx				          : OUT std_logic;
	vwrite				         : OUT std_logic;
	vdout				          : IN 	std_logic_vector(w_size - 1 DOWNTO 0);
	vdin 				          : OUT std_logic_vector(w_size - 1 DOWNTO 0);
	vaddr				          : OUT std_logic_vector(a_size - 1 DOWNTO 0)
);

END pix_write_cache;

ARCHITECTURE rtl OF pix_write_cache IS
	SIGNAL add_temp		    : std_logic_vector(a_size - 1 DOWNTO 0);
	SIGNAL store_del	    : std_logic_vector(w_size - 1 DOWNTO 0);
	SIGNAL din           : std_logic_vector(w_size - 1 DOWNTO 0);
BEGIN

ram_fsm : ENTITY ram_fsm
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

din_compute : PROCESS
  VARIABLE res  : pixop_t;
BEGIN
  WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN 
    din <= (OTHERS=>'0');
  ELSE
    FOR i IN store'RANGE LOOP
      res := store(i);
      CASE res IS
        WHEN same   => din(i) <= dout(i);
        WHEN invert => din(i) <= NOT dout(i);
        WHEN black  => din(i) <= 1;
        WHEN white  => din(i) <= 0;
        WHEN OTHERS => NULL;
      END CASE res;
    END LOOP;
  END IF;
END PROCESS din_compute;
vdin <= din;
END ARCHITECTURE rtl;