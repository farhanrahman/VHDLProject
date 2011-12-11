LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.pix_cache_pak.ALL;

ENTITY FIFO IS
GENERIC (
	q_size 	: INTEGER := 4;
	a_size 	: INTEGER := 8;
	p_size	: INTEGER := 4
);
PORT (
	clk, reset, push, pop 	: IN std_logic;
	pixword					: IN std_logic_vector(a_size - 1 DOWNTO 0);
	pixnum					: IN std_logic_vector(p_size - 1 DOWNTO 0);
	pixop					: IN pixop_t;
	flush,draw,clear		: IN std_logic;
	pixword_out				: OUT std_logic_vector(a_size - 1 DOWNTO 0);
	pixnum_out				: OUT std_logic_vector(p_size - 1 DOWNTO 0);
	pixop_out				: OUT pixop_t;
	full, empty				: OUT std_logic;
	flush_out				: OUT std_logic;
	clear_out				: OUT std_logic;
	draw_out				: OUT std_logic
);
END ENTITY FIFO;

ARCHITECTURE rtl OF FIFO IS
		ALIAS slv IS std_logic_vector ;
		ALIAS usg IS unsigned;
		CONSTANT endPnt 	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '1');
		CONSTANT startPnt	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		TYPE data_type IS
		RECORD
			pword 	: std_logic_vector(a_size - 1 DOWNTO 0);
			pnum	: std_logic_vector(p_size - 1 DOWNTO 0);
			pix_op	: pixop_t;
			fl		: std_logic;
			clr		: std_logic;
			dr		: std_logic;
		END RECORD;
		TYPE queue_type IS ARRAY (to_integer(usg(endPnt)) DOWNTO 0) OF data_type;
		SIGNAL queue : queue_type;
		SIGNAL readPtr, writePtr : std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		
		SIGNAL full1,empty1  	: std_logic;
		
		SIGNAL	pixword_out1						: std_logic_vector(a_size - 1 DOWNTO 0);
		SIGNAL	pixnum_out1							: std_logic_vector(p_size - 1 DOWNTO 0);
		SIGNAL	pixop_out1							: pixop_t;
		SIGNAL 	flush_out1, clear_out1, draw_out1	: std_logic;

		SIGNAL lastop : std_logic;
		SIGNAL add 	: std_logic_vector(q_size - 1 DOWNTO 0) := (OTHERS => '0');
		SIGNAL we	: std_logic;
	
BEGIN

full <= full1; empty <= empty1;
pixword_out <= pixword_out1; 
pixnum_out <= pixnum_out1; 
pixop_out <= pixop_out1; flush_out <= flush_out1; 
clear_out <= clear_out1; draw_out <= draw_out1;

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

RAM : PROCESS (we, readPtr, writePtr, pixword, pixnum, pixop, flush, clear, draw, queue)
	VARIABLE dat 	: data_type;
	VARIABLE dat2	: data_type; 
BEGIN
	IF we = '1' THEN
		dat.pword 	:= pixword;
		dat.pnum	:= pixnum;
		dat.pix_op	:= pixop;
		dat.fl 		:= flush;
		dat.clr		:= clear;
		dat.dr		:= draw;
		queue(to_integer(usg(writePtr))) <= dat;	
			
	END IF;

		dat2 := queue(to_integer(usg(readPtr)));
		pixword_out1 	<= dat2.pword;
		pixnum_out1		<= dat2.pnum;
		pixop_out1		<= dat2.pix_op;
		flush_out1		<= dat2.fl;
		clear_out1		<= dat2.clr;
		draw_out1		<= dat2.dr;

END PROCESS RAM;


END ARCHITECTURE rtl;