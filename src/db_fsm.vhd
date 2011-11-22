LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
ENTITY db_fsm IS
PORT	(
	clk, reset, start	: IN  std_logic;
	vwrite, delay		: OUT std_logic 
	);
END db_fsm;

ARCHITECTURE synth OF db_fsm IS

TYPE   state_t IS (m3, m2, m1, mx);

SIGNAL state, nstate  : state_t;
SIGNAL delay1         : std_logic;
SIGNAL vwrite1        : std_logic;

BEGIN

--Combinational Logic
C: PROCESS()
BEGIN

END PROCESS C;

--Clocked Logic
FSM: PROCESS
BEGIN
  WAIT UNTIL clk'EVENT AND clk = '1';
  state <= nstate;
END PROCESS FSM;

END ARCHITECTURE synth;
