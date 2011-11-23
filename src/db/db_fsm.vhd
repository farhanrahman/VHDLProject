-- Draw Block FSM, decodes commands and sets xy
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
ENTITY db_fsm IS
PORT	(
	-- HOST SIGNALS
	clk, reset, ready	: IN std_logic;
	op, pen			: IN std_logic(1 DOWNTO 0);
	xin, yin		: IN std_logic(5 DOWNTO 0);
	busy			: OUT std_logic;	

	-- DRAWOCTANT SIGNALS
	vwrite, delay		: OUT std_logic;

	-- RCB SIGNALS
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
