LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.pix_cache_pak.ALL;
USE work.config_pack.ALL;
USE IEEE.numeric_std.ALL;
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
SIGNAL store_reg		: store_t;
SIGNAL address_temp 	: std_logic_vector(a_size - 1 DOWNTO 0);
SIGNAL done1			: std_logic;

BEGIN
C: PROCESS(state, reset, start) --state machine combinational process
BEGIN
delay1 <= '0'; vwrite1 <= '0'; done1 <= '0';
	IF reset = '1' THEN
		nstate <= mx;
	ELSE
	CASE state IS
		WHEN mx =>
				IF start = '1' THEN
					nstate <= m1;
				ELSE 	
					nstate <= mx;
				END IF;		
		WHEN m1 =>
				IF start = '1' OR start='0' THEN
					nstate <= m2;
					delay1 <= start;         
				END IF;			
		WHEN m2 =>
			IF start='1' OR start='0' THEN
				nstate <= m3;
				delay1 <= start;        
			END IF;          
		WHEN m3 =>
			IF start='1' THEN
				nstate <= m1;
				vwrite1 <= '1';
				done1 <= '1';
			ELSE
				nstate <= mx;
				vwrite1 <= '1';
				done1 <= '1';
			END IF;           
	END CASE;
	END IF;
END PROCESS C;
done <= done1;

FSM: PROCESS --FSM process assigns next state to current state at rising_edge of clk
BEGIN
  WAIT UNTIL rising_edge(clk);
  state <= nstate;
END PROCESS FSM;


address_delay: PROCESS --This process is a register that stores the incoming address when state is m1
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN
    vaddr <= (OTHERS=>'0');
  ELSIF state = m1 THEN--OR state = mx THEN--state = m1 THEN
    vaddr <= address_temp;
  END IF;
END PROCESS address_delay;

store_register : PROCESS -- This process is a register that stores the values of address and store as soon as empty goes high
BEGIN
WAIT UNTIL rising_edge(empty_enable);
	store_reg <= store;
	address_temp <= address;
END PROCESS store_register;


vdin_compute : PROCESS -- This process in half a cycle after m3 is reached, assigns the output to the VRAM with the values in store.
BEGIN
WAIT UNTIL falling_edge(clk);
  IF reset = '1' THEN 
    vdin <= (OTHERS=>'0');
  ELSIF state = m3 THEN
    FOR i IN store_reg'RANGE LOOP
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


delay <= delay1; vwrite <= vwrite1; --Data flow statements
END ARCHITECTURE synth;


