LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.pix_cache_pak.ALL;

ENTITY fifo_store IS
GENERIC (
	q_size 	: INTEGER := 4;
	p_size	: INTEGER := 4
);
PORT (
	clk, reset, push, pop 	: IN std_logic;
	store					: IN store_t;
	store_out				: OUT store_t;
	full, empty				: OUT std_logic
);
END ENTITY fifo_store;

ARCHITECTURE rtl OF fifo_store IS
		ALIAS slv IS std_logic_vector ;
		ALIAS usg IS unsigned;
		CONSTANT endPnt 	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '1');
		CONSTANT startPnt	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		
		TYPE queue_type IS ARRAY (to_integer(usg(endPnt)) DOWNTO 0) OF store_t;
		SIGNAL queue : queue_type;
		SIGNAL readPtr, writePtr : std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		
		SIGNAL full1,empty1  	: std_logic;
		
		SIGNAL	store_out1						: store_t;

		SIGNAL lastop : std_logic;
		SIGNAL add 	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		SIGNAL we	: std_logic;
	
BEGIN

full <= full1; empty <= empty1;
store_out <= store_out1; 

sync: PROCESS
BEGIN
 WAIT UNTIL rising_edge(clk);
  IF (reset = '1') THEN
	writePtr 	<= startPnt; 
	readPtr 	<= startPnt;
    lastop 		<= '0'; 
  ELSIF (pop = '1' and empty1 = '0') THEN
	IF readPtr = endPnt THEN
		readPtr <= startPnt;
	ELSE
		readPtr <= slv(usg(readPtr) + 1);
	END IF;
    lastop <= '0'; 
  ELSIF (push = '1' and full1 = '0') THEN

		IF writePtr /= endPnt THEN
			writePtr <= slv(usg(writePtr) + 1);
		ELSE
			writePtr <= startPnt;
		END IF;
      lastop <= '1'; 
  END IF;  -- otherwise all Fs hold their value -- 

END PROCESS sync; 



comb: PROCESS (push,pop,writePtr,readPtr,lastop,full1,empty1)
BEGIN
-- full and empty flags -- 
	 IF (readPtr = writePtr) THEN 
		  IF (lastop = '1') THEN
				full1 <= '1'; 
				empty1 <= '0'; 
			ELSE 
				full1 <= '0';
				empty1 <= '1'; 
		  END IF; 
	 ELSE
		full1 <= '0'; 
		empty1 <= '0'; 
	 END IF; 
	 
-- address, write enable logic -- 
IF (pop = '0' and push = '0') THEN -- no operation -- 
		add <= readPtr; 
		we <= '0'; 
	ELSIF (pop = '0' and push = '1') THEN -- push only -- 
		  add <= writePtr; 
		  IF (full1 = '0') THEN -- valid write condition -- 
			we <= '1'; 
		  ELSE     -- no write condition -- 
		   we <= '0'; 
		  END IF; 
	ELSIF (pop = '1' and push = '0') THEN -- pop only -- 
		  add <= readPtr;  
		  we <= '0'; 
ELSE   -- push and pop at same time – 
	  IF (empty1 = '0') THEN -- valid pop -- 
			add <= readPtr; 
			we <= '0'; 
	  ELSE 
			add <= writePtr; 
			we <= '1';  
	  END IF; 
 END IF; 
END PROCESS comb; 

RAM : PROCESS (we, readPtr, writePtr, store, queue)
	VARIABLE dat1 	: store_t;
	VARIABLE dat2	: store_t; 
BEGIN
	IF we = '1' THEN
		dat1 	:= store;
		queue(to_integer(usg(writePtr))) <= dat1;	
			
	END IF;
		dat2 := queue(to_integer(usg(readPtr)));
		store_out1 	<= dat2;
END PROCESS RAM;


END ARCHITECTURE rtl;