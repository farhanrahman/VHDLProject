LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
ENTITY ram_fsm IS
PORT(clk, reset, start: IN  std_logic; vwrite, delay: OUT std_logic );
END ram_fsm;
ARCHITECTURE synth OF ram_fsm IS
TYPE   state_t IS (m3, m2, m1, mx);
SIGNAL state, nstate  : state_t;
SIGNAL delay1         : std_logic;
SIGNAL vwrite1        : std_logic;
BEGIN
C: PROCESS(state, reset, start)
BEGIN
delay1 <= '0'; vwrite1 <= '0';
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
			ELSE
				nstate <= mx;
				vwrite1 <= '1';           
			END IF;           
	END CASE;
	END IF;
END PROCESS C;

FSM: PROCESS
BEGIN
  WAIT UNTIL clk'EVENT AND clk = '1';
  state <= nstate;
END PROCESS FSM;
delay <= delay1; vwrite <= vwrite1;
END ARCHITECTURE synth;