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
		startcmd 	: IN  std_logic; -- need to connect this to fifo
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
--	SIGNAL empty     : std_logic;
	SIGNAL store     : store_t;
	SIGNAL word      : std_logic_vector(a_size - 1 DOWNTO 0);
	
	
	SIGNAL start   : std_logic;
	SIGNAL waitx   : std_logic;
	SIGNAL vwrite1 : std_logic;
	
	TYPE states IS (s1,s2,s0);
	SIGNAL state     : states;
	SIGNAL nstate    : states;
	SIGNAL flush_cmd : std_logic;
	
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
	
BEGIN

pwordcache : ENTITY pix_word_cache
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
	
rfsm : ENTITY ram_fsm
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
	 vaddr   		=> vaddr  
  );

  clk_invert <= NOT clk;

PARSE_RCBCMD : PROCESS (x,y,rcbcmd)
	VARIABLE pix_cmd       		: std_logic_vector(1 DOWNTO 0);
BEGIN
	pixword1(7 DOWNTO 4) <= y(5 DOWNTO 2);
	pixword1(3 DOWNTO 0) <= x(5 DOWNTO 2);
	
	pixnum1(3 DOWNTO 2) <= y(1 DOWNTO 0);
	pixnum1(1 DOWNTO 0) <= x(1 DOWNTO 0);
	
	pix_cmd := rcbcmd(1) & rcbcmd(0);
	
	CASE pix_cmd IS
	  WHEN "00" => pixopin1 <= same;
	  WHEN "01" => pixopin1 <= white;
	  WHEN "10" => pixopin1 <= black;
	  WHEN "11" => pixopin1 <= invert;
	  WHEN OTHERS => NULL;   
	 END CASE;
END PROCESS PARSE_RCBCMD;
pixword <= pixword1; pixnum <=pixnum1; pixopin <= pixopin1;

FLUSH_PARSE : PROCESS (rcbcmd, startcmd)
BEGIN
	IF startcmd = '1' THEN
		flush <= NOT rcbcmd(2) AND NOT rcbcmd(1) AND NOT rcbcmd(0);
	ELSE 
		flush <= '0';
	END IF;
END PROCESS FLUSH_PARSE;

PARSE_CMD : PROCESS(rcbcmd, flush, startcmd)
BEGIN
	IF startcmd = '1' THEN
		clear <= rcbcmd(2);
		draw  <= (NOT rcbcmd(2) AND NOT flush) OR (rcbcmd(2) AND NOT flush);
	ELSE
		clear <= '0';
		draw <= '0';
	END IF;
END PROCESS PARSE_CMD;

ASSIGN_OUT : PROCESS (vwrite1, delaycmd1)
BEGIN
	vwrite    <= vwrite1;
	delaycmd  <= delaycmd1;
END PROCESS ASSIGN_OUT;


ASSIGN_DELAYCMD : PROCESS (readyrcb, waitx)
BEGIN
	delaycmd1 <= (NOT readyrcb AND waitx);
END PROCESS ASSIGN_DELAYCMD;

--PIXWORD_FLUSH : PROCESS
--BEGIN
--WAIT UNTIL rising_edge(clk);
--	empty <= start;--(NOT readyrcb OR waitx) OR (flush OR waitx);--(NOT readyrcb AND NOT waitx) OR (flush AND NOT waitx);
--END PROCESS PIXWORD_FLUSH;

EMP_ENABLE : PROCESS
BEGIN
	WAIT UNTIL rising_edge(start);
		empty_enable <= '1';
	WAIT UNTIL falling_edge(clk);
		empty_enable <= '0';
END PROCESS EMP_ENABLE;

RAM_FSM_START : PROCESS
BEGIN
WAIT UNTIL rising_edge(clk_invert);
	start <= (NOT readyrcb OR waitx) OR (flush OR waitx);--empty;--(NOT readyrcb OR waitx) OR (flush OR waitx);--NOT readyrcb OR waitx OR flush;
END PROCESS RAM_FSM_START;


END ARCHITECTURE behav;