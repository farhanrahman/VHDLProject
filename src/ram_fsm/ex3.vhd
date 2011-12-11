LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.pix_cache_pak.ALL;
USE work.config_pack.ALL;
ENTITY ram_fsm IS
GENERIC(
	a_size 		: INTEGER := 8;
	w_size 		: INTEGER := 16;
	timing_on 	: BOOLEAN := FALSE
);
PORT(
	clk, reset, start	: IN  	std_logic;
	empty_enable		: IN 	std_logic;
	vwrite, delay		: OUT 	std_logic;
	done				: OUT 	std_logic;
	store				: IN 	store_t;
	address				: IN 	std_logic_vector(a_size - 1 DOWNTO 0);	
	vdout				: IN 	std_logic_vector(w_size - 1 DOWNTO 0);
	vdin 				: OUT 	std_logic_vector(w_size - 1 DOWNTO 0);
	vaddr				: OUT 	std_logic_vector(a_size - 1 DOWNTO 0)		
	);
END ram_fsm;
ARCHITECTURE synth OF ram_fsm IS
TYPE   state_t IS (mx, m2, m1, m3);
SIGNAL state, nstate  	: state_t;
SIGNAL delay1         	: std_logic;
SIGNAL vwrite1        	: std_logic;
SIGNAL lock_for_twp 	: BOOLEAN := FALSE;
SIGNAL twp_lock			: BOOLEAN := FALSE;
SIGNAL lock_for_tracc	: BOOLEAN := FALSE;
SIGNAL tracc_lock		: BOOLEAN := FALSE;
SIGNAL store_reg		: store_t;
SIGNAL address_temp 	: std_logic_vector(a_size - 1 DOWNTO 0);
SIGNAL done1			: std_logic;
   CONSTANT twp   : TIME := config_clock_period*config_twp;
   CONSTANT twds  : TIME := twp / 2;
   CONSTANT tracc : TIME := config_clock_period *config_tracc;
   CONSTANT taws  : TIME := tracc / 2;

BEGIN
C: PROCESS(state, reset, start, twp_lock)
BEGIN
delay1 <= '0'; vwrite1 <= '0'; done1 <= '0';
	IF reset = '1' THEN
		nstate <= mx;
	ELSE
	IF NOT twp_lock THEN
		lock_for_twp <= FALSE;
	END IF;
	CASE state IS
		WHEN mx =>
--			IF timing_on THEN
--				IF start = '1' THEN
--					IF NOT twp_lock THEN
--						nstate <= m1;
--					ELSE
--						nstate <= mx;
--						vwrite1 <= '1';
--						delay1 <= start;
--					END IF;
--				ELSE
--					IF twp_lock THEN
--						vwrite1 <= '1';
--						delay1 <= start;
--					END IF;
--					nstate <= mx;
--				END IF;
--			ELSE
				IF start = '1' THEN
					nstate <= m1;
				ELSE 	
					nstate <= mx;
				END IF;		
--			END IF;
		WHEN m1 =>
--			IF timing_on THEN
--				IF start = '1' OR start='0' THEN
--					IF NOT twp_lock THEN
--						nstate <= m2;
--						delay1 <= start;    
--					ELSE
--						nstate <= m1;
--						vwrite1 <= '1';
--						delay1 <= start;
--					END IF;
--				END IF;
--			ELSE
				IF start = '1' OR start='0' THEN
					nstate <= m2;
					delay1 <= start;         
				END IF;			
--			END IF;
		WHEN m2 =>
			IF start='1' OR start='0' THEN
				nstate <= m3;
				delay1 <= start;        
			END IF;          
		WHEN m3 =>
			IF start='1' THEN
				nstate <= m1;
				vwrite1 <= '1';
				lock_for_twp <= TRUE;
				done1 <= '1';
			ELSE
				nstate <= mx;
				vwrite1 <= '1';
				lock_for_twp <= TRUE;
				done1 <= '1';
			END IF;           
	END CASE;
	END IF;
END PROCESS C;
done <= done1;

FSM: PROCESS
BEGIN
  WAIT UNTIL rising_edge(clk);
  state <= nstate;
END PROCESS FSM;


address_delay: PROCESS
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN
    vaddr <= (OTHERS=>'0');
  ELSIF state = m1 THEN--OR state = mx THEN--state = m1 THEN
    vaddr <= address_temp;
	--store_reg <= store;
  END IF;
END PROCESS address_delay;

store_register : PROCESS
BEGIN
WAIT UNTIL rising_edge(empty_enable);
--IF (state = m1 OR state = mx) THEN
	store_reg <= store;
	address_temp <= address;
--END IF;
END PROCESS store_register;

--store_register : PROCESS
--BEGIN
--WAIT UNTIL rising_edge(empty_enable);
--IF start = '1' THEN--AND (state = m1 OR state = mx) THEN
--	store_reg <= store;
--	address_temp <= address;
--END IF;
--END PROCESS store_register;

vdin_compute : PROCESS
  --VARIABLE res  : pixop_t;
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN 
    vdin <= (OTHERS=>'0');
  ELSIF state = m3 THEN
    FOR i IN store_reg'RANGE LOOP
      --res := store(i);
      CASE store_reg(i) IS
        WHEN same   => vdin(i) <= vdout(i);
        WHEN invert => vdin(i) <= NOT vdout(i);
        WHEN black  => vdin(i) <= '1';
        WHEN white  => vdin(i) <= '0';
        WHEN OTHERS => NULL;
      END CASE;
    END LOOP;
  END IF;
END PROCESS vdin_compute;


TWP_COUNT : PROCESS
BEGIN
WAIT UNTIL lock_for_twp;
twp_lock <= TRUE;
WAIT FOR twp;
--WAIT FOR 10 ns;
twp_lock <= FALSE;
END PROCESS TWP_COUNT;

TRACC_COUNT : PROCESS
BEGIN
WAIT UNTIL lock_for_tracc;
tracc_lock <= TRUE;
WAIT FOR tracc;
tracc_lock <= FALSE;
END PROCESS TRACC_COUNT;


delay <= delay1; vwrite <= vwrite1;
END ARCHITECTURE synth;