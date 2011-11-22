LIBRARY IEEE;
LIBRARY WORK;
USE ieee.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;               -- add unsigned, signed
USE work.pix_cache_pak.ALL;

ENTITY pix_word_cache IS
  GENERIC(
	w_size : INTEGER := 4
  );
  PORT(
    clk, reset, pw, empty : IN  std_logic;
    pixnum                : IN  std_logic_vector(w_size - 1 DOWNTO 0);
    pixopin               : IN  pixop_t;
    pixword               : IN  std_logic_vector(w_size - 1 DOWNTO 0);
    store                 : OUT store_t;
    word                  : OUT std_logic_vector(w_size - 1 DOWNTO 0);
    clean, ready          : OUT std_logic
    );
END pix_word_cache;

ARCHITECTURE rtl OF pix_word_cache IS

  CONSTANT init_store : store_t := (OTHERS=>same);
  -- you may find these signals useful, feel free to delete them or add others
  SIGNAL store1 : store_t;
  SIGNAL clean1 : std_logic;
  SIGNAL word1  : std_logic_vector(w_size - 1 DOWNTO 0);
  SIGNAL ready1 : std_logic;
BEGIN
COMB : PROCESS (reset, store1, pixword, word1, empty, pw, clean1)
BEGIN  
IF store1 = init_store THEN
  clean1 <= '1';
ELSE -- store1 all element not same
  clean1 <= '0';
END IF; -- if all element of store1 = same
  ready1 <= '1';
IF reset = '1' THEN
  ready1 <= '0';
ELSE -- reset = '0'   

IF empty = '0' AND pw = '0' THEN

IF clean1 = '1' OR pixword = word1 THEN
  ready1 <= '1';
END IF; -- clean1 = '1' OR pixword = word1

END IF; --empty = '0' AND pw = '0'
    
IF empty = '0' AND pw = '1' THEN

IF pixword = word1 THEN
          ready1 <= '1';
ELSE -- pixword != word1
    ready1 <= clean1;
END IF; -- pixword = word1

END IF; -- empty = '0' AND pw = '1'

IF empty = '1' AND pw = '0' THEN
    ready1 <= '1';
END IF; -- empty = '1' AND pw = '0'
  
IF empty = '1' AND pw = '1' THEN
    ready1 <= '1';
END IF; -- empty = '1' AND pw = '1'

END IF; -- reset = '1'
END PROCESS COMB;

REGISTERED : PROCESS  
BEGIN
  WAIT UNTIL clk'EVENT AND clk = '1';
  IF reset = '1' THEN
      store1 <= init_store;
      word1 <= (OTHERS=>'0');
  ELSE -- reset = '1'
  IF (empty = '0' AND pw = '1' AND pixword = word1) OR (empty = '0' AND pw = '1' AND pixword /= word1 AND clean1 = '1') OR (empty = '1' AND pw = '1') THEN
  
  IF empty = '1' AND pw = '1' THEN
        store1 <= (OTHERS=>same);
  END IF; -- empty = '1' AND pw = '1';
    
  CASE pixopin IS
  WHEN invert =>
      CASE store1(to_integer(unsigned(pixnum))) IS
        WHEN black =>
          store1(to_integer(unsigned(pixnum))) <= white;
        WHEN white =>
          store1(to_integer(unsigned(pixnum))) <= black;
        WHEN invert =>
          store1(to_integer(unsigned(pixnum))) <= same;
        WHEN same =>
          store1(to_integer(unsigned(pixnum))) <= invert;
        WHEN OTHERS => NULL;
      END CASE; -- CASE store1(to_integer(unsigned(pixnum))) IS
  WHEN same =>
          store1(to_integer(unsigned(pixnum))) <= store1(to_integer(unsigned(pixnum)));
  WHEN OTHERS =>
          store1(to_integer(unsigned(pixnum))) <= pixopin;
  END CASE; -- CASE pixopin IS            
  END IF; -- pixword = word1 OR (pixword /= word1 AND clean = '1')          
          
IF empty = '0' AND pw = '1' THEN
  IF pixword /= word1 THEN
      IF clean1 = '1' THEN                
        word1 <= pixword;           
      END IF; -- clean1 - '1'
  END IF; --pixword /= word1
END IF; -- empty = '0' AND pw = '1'
        
IF empty = '1' AND pw = '0' THEN 
      store1 <= init_store;
      word1 <= pixword;
END IF; -- empty = '1' AND pw = '0'
    
IF empty = '1' AND pw = '1' THEN               
      word1 <= pixword;   
END IF; -- empty = '1' AND pw = '1'    

END IF; -- reset = '1'
  
END PROCESS REGISTERED;
-- output Assignments
store <= store1;
word <= word1;
clean <= clean1; 
ready <= ready1;
END ARCHITECTURE rtl;