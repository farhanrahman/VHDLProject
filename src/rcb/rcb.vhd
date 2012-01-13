LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.pix_word_cache;
USE work.ram_fsm;
USE work.pix_cache_pak.ALL;

ENTITY rcb IS
	GENERIC(
		a_size  	: INTEGER := 8;
		p_size		: INTEGER := 4;
		w_size 		: INTEGER := 16;
		x_size		: INTEGER := 6;
		timing_on 	: BOOLEAN := FALSE
	);
	
	PORT(
		clk, reset	: IN  std_logic;
		x,y 		: IN  std_logic_vector(x_size - 1 DOWNTO 0);
		rcbcmd 		: IN  std_logic_vector(2 DOWNTO 0);
		startcmd 	: IN  std_logic;
		delaycmd 	: OUT std_logic;
		vaddr       : OUT std_logic_vector(a_size - 1 DOWNTO 0);
		vdin        : OUT std_logic_vector(w_size - 1 DOWNTO 0);
		vdout       : IN  std_logic_vector(w_size - 1 DOWNTO 0);
		vwrite      : OUT std_logic
	);
END ENTITY rcb;


ARCHITECTURE behav OF rcb IS
  SIGNAL delaycmd1 : std_logic;
  
	SIGNAL pixword 	 : std_logic_vector(a_size - 1 DOWNTO 0);
	SIGNAL pixnum 	 : std_logic_vector(p_size - 1 DOWNTO 0);
	SIGNAL pixopin   : pixop_t;
	SIGNAL clean     : std_logic;
	SIGNAL readyrcb  : std_logic;
	SIGNAL store     : store_t;
	SIGNAL word      : std_logic_vector(a_size - 1 DOWNTO 0);
	
	
	SIGNAL start   : std_logic;
	SIGNAL waitx   : std_logic;
	SIGNAL vwrite1 : std_logic;
	
	TYPE states IS (idle,f1,f2,f3);
	SIGNAL state     : states;
	SIGNAL nstate    : states;
	
	ALIAS slv  IS std_logic_vector;
	ALIAS usg  IS unsigned;
	ALIAS sg   IS signed;
	
	SIGNAL flush : std_logic;
	SIGNAL draw  : std_logic;
	SIGNAL clear : std_logic;
	
	SIGNAL pixword1 	 	: std_logic_vector(a_size - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL pixnum1 	 		: std_logic_vector(p_size - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL pixopin1   		: pixop_t := same;

	SIGNAL clk_invert		: std_logic;
	
	SIGNAL empty_enable		: std_logic := '0';
	
	SIGNAL done : std_logic;
	
BEGIN

pwordcache : ENTITY pix_word_cache --Pixword cache entity
	GENERIC MAP(
		w_size => a_size,
		p_size => p_size
	)
	PORT MAP(
		clk     => clk,
		reset   => reset, 
		pw      => startcmd,
		empty   => empty_enable,
		pixnum  => pixnum,
		pixopin => pixopin,
		pixword => pixword,
		store   => store,
		word    => word,
		clean   => clean,
		ready   => readyrcb
	);
	
rfsm : ENTITY ram_fsm -- ram_fsm entity
	GENERIC MAP(
		timing_on => timing_on
	)
  PORT MAP(
	 clk     		=> clk_invert,
	 reset   		=> reset,
	 start	  		=> start,
	 empty_enable 	=> empty_enable,
	 store	  		=> store,
	 address		=> word,
	 delay	  		=> waitx,
	 vwrite	 		=> vwrite1,
	 vdout	  		=> vdout,
	 vdin    		=> vdin, 				         
	 vaddr   		=> vaddr,
	 done 			=> done
  );

  clk_invert <= NOT clk;

PARSE_RCBCMD : PROCESS (x,y,rcbcmd) --Combinational process which converts x and y to pixword and pixnum for processing
BEGIN
	pixword1 <= y(5 DOWNTO 2) & x(5 DOWNTO 2);
	pixnum1 <= y(1 DOWNTO 0) & x(1 DOWNTO 0);
	pixopin1 <= rcbcmd(1) & rcbcmd(0);
END PROCESS PARSE_RCBCMD;
-- DATA FLOW--
pixword <= pixword1; pixnum <=pixnum1; pixopin <= pixopin1;

FLUSH_PARSE : PROCESS (rcbcmd) -- Process converts RCB Command for flush
BEGIN
	flush <= NOT (rcbcmd(2) OR rcbcmd(1) OR rcbcmd(0));
END PROCESS FLUSH_PARSE;

PARSE_CMD : PROCESS(rcbcmd, flush) -- Process converts rcbcmd to clear and draw
BEGIN
	clear <= rcbcmd(2);
	draw  <= (rcbcmd(2) AND flush) OR NOT flush;--(NOT rcbcmd(2) AND NOT flush) OR (rcbcmd(2) AND NOT flush);
END PROCESS PARSE_CMD;

ASSIGN_OUT : PROCESS (vwrite1, delaycmd1) --Process assigns vwrite and delaycmd output from dummy variables
BEGIN
	vwrite    <= vwrite1;
	delaycmd  <= delaycmd1;
END PROCESS ASSIGN_OUT;



RCB_FSM : PROCESS(reset, readyrcb, state, waitx, done, startcmd, flush, clean)
-- The combinationl part of the state machine. This state machine takes care of 
-- 1) startcmd 2) empty signal and 3) delaycmd
BEGIN
IF reset = '1' THEN
	nstate <= idle;
ELSE
	nstate <= state;
	CASE state IS
		WHEN idle =>
			IF readyrcb = '0' OR (startcmd = '1' AND flush = '1' AND clean = '0') THEN
				nstate <= f1;
			END IF;
		WHEN f1 =>
			nstate <= f3;
			IF waitx = '1' THEN
				nstate <= f2;
			END IF;
		WHEN f2 =>
			IF waitx = '0' THEN
				nstate <= f3;
			END IF;
		WHEN f3 =>
			IF done = '1' THEN
				nstate <= idle;
			END IF;
	END CASE;
END IF;

END PROCESS RCB_FSM;

ASSIGN_STATE : PROCESS
-- This process assigns the nstate to state (current state). However this process also assigns output
-- on rising_edge of clk (inverted clock, to save cycles) 
BEGIN
WAIT UNTIL rising_edge(clk_invert);
state <= nstate;
IF nstate = idle THEN
	empty_enable <= '0';
	start <= '0';
	delaycmd1 <= '0';
ELSIF nstate = f1 THEN
	empty_enable <= '1';
	start <= '1';
	delaycmd1 <= '1';
ELSIF nstate = f2 THEN
	empty_enable <= '0';
	start <= waitx;
	delaycmd1 <= '1';
ELSIF nstate = f3 THEN
	empty_enable <= '0';
	start <= '0';
	delaycmd1 <= '1';
END IF;
END PROCESS ASSIGN_STATE;

END ARCHITECTURE behav;
