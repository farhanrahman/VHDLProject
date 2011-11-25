LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.vram;
USE work.pix_word_cache;
USE work.ram_fsm;
USE work.pix_cache_pak.ALL;
USE work.pix_write_cache;


ENTITY rcb IS
	GENERIC(
		w_size  : INTEGER := 8;
		p_size	 : INTEGER := 4
	);
	
	PORT(
		clk, reset	 : IN  std_logic;
		x,y 		      : IN  std_logic_vector(5 DOWNTO 0);
		rcbcmd 		   : IN  std_logic_vector(2 DOWNTO 0);
		startcmd 	  : IN  std_logic;
		delaycmd 	  : OUT std_logic;
		vaddr       : OUT std_logic_vector(w_size - 1 DOWNTO 0);
		vdin        : OUT std_logic_vector(w_size - 1 DOWNTO 0);
		vdout       : IN  std_logic_vector(w_size - 1 DOWNTO 0);
		vwrite      : OUT std_logic
	);
END ENTITY rcb;


ARCHITECTURE behav OF rcb IS
  SIGNAL delaycmd1 : std_logic;
  
	SIGNAL pixword 	 : std_logic_vector(w_size - 1 DOWNTO 0);
	SIGNAL pixnum 	  : std_logic_vector(p_size - 1 DOWNTO 0);
	SIGNAL pixopin   : pixop_t;
	SIGNAL clean     : std_logic;
	SIGNAL ready     : std_logic;
	SIGNAL empty     : std_logic;
	SIGNAL store     : store_t;
	SIGNAL word      : std_logic_vector(w_size - 1 DOWNTO 0);
	
	
	SIGNAL start   : std_logic;
	SIGNAL waitx   : std_logic;
	SIGNAL vwrite1 : std_logic;
	
	TYPE states IS (s0,s1,s2,s3);
	SIGNAL state     : states;
	SIGNAL nstate    : states;
	SIGNAL flush_cmd : std_logic;
	
	ALIAS slv  IS std_logic_vector;
	ALIAS usg  IS unsigned;
	ALIAS sg   IS signed;
	
BEGIN

pwordcache : ENTITY pix_word_cache
	GENERIC MAP(
		w_size => w_size,
		p_size => p_size
	)
	PORT MAP(
		clk     => clk,
		reset   => reset, 
		pw      => startcmd,
		empty   => empty,
    pixnum  => pixnum,
    pixopin => pixopin,
    pixword => pixword,
    store   => store,
    word    => word,
    clean   => clean,
    ready   => ready
	);
	

pwritecache : ENTITY pix_write_cache
  PORT MAP(
	 clk     => clk,
	 reset   => reset,
	 start	  => start,
	 store	  => store,
	 address	=> word,
	 waitx	  => waitx,
	 vwrite	 => vwrite1,
	 vdout	  => vdout,
	 vdin    => vdin, 				         
	 vaddr   => vaddr  
  );


P1 : PROCESS (x,y,rcbcmd)
	VARIABLE temp_pixword 	: std_logic_vector(w_size - 1 DOWNTO 0);
	VARIABLE temp_pixnum	  : std_logic_vector(p_size - 1 DOWNTO 0);
	VARIABLE temp_y		  	   : std_logic_vector(w_size - 1 DOWNTO 0);
	VARIABLE temp_y_pix		  : std_logic_vector(p_size - 1 DOWNTO 0);
	VARIABLE pix_cmd       : std_logic_vector(1 DOWNTO 0);
BEGIN
	temp_y       := slv(resize(sg(y(5 DOWNTO 2)), w_size) sll 4);
	temp_y_pix   := slv(resize(sg(y(1 DOWNTO 0)), p_size) sll 2);
	
	temp_pixword := slv(sg(resize(sg(x(5 DOWNTO 2)), w_size)) + sg(temp_y));
	temp_pixnum  := slv(sg(resize(sg(x(1 DOWNTO 0)), p_size)) + sg(temp_y_pix));
	
	pix_cmd := rcbcmd(1) & rcbcmd(0);
	
	CASE pix_cmd IS
	  WHEN "00" => pixopin <= same;
	  WHEN "01" => pixopin <= white;
	  WHEN "10" => pixopin <= black;
	  WHEN "11" => pixopin <= invert;
	  WHEN OTHERS => NULL;   
	 END CASE;
	
	pixword  <= temp_pixword;
	pixnum   <= temp_pixnum;

END PROCESS P1;

FSM : PROCESS (reset, rcbcmd, ready, state, delaycmd1, vwrite1, startcmd, waitx)
  VARIABLE flush : std_logic;
  VARIABLE draw  : std_logic;
  VARIABLE clear : std_logic; 
BEGIN
  flush := NOT rcbcmd(2) AND NOT rcbcmd(1) AND NOT rcbcmd(0);
  clear := rcbcmd(2);
  draw  := (NOT rcbcmd(2) AND NOT flush) OR (rcbcmd(2) AND NOT flush);
  flush_cmd <= '0';
  IF reset = '1' THEN
    nstate <= s0;
  ELSE
    CASE state IS
      WHEN s0 =>
        
        IF startcmd = '1' THEN
          
          IF clear = '1' THEN
            nstate <= s0; --clearscreen not implemented yet
          END IF; -- clear = '1'
          
          IF flush = '1' THEN
            nstate    <= s1;
            flush_cmd <= '1';
          END IF; --flush = '1'
          
          IF draw = '1' THEN
            nstate <= s2;
          END IF; -- draw = '1'
          
        END IF; --startcmd = '1'
      
      WHEN s1 =>
        
        IF waitx = '1' THEN
          nstate <= s1;
          flush_cmd <= '1';
        ELSE -- waitx = '0'
          nstate <= s3;  
        END IF; -- waitx = '1'

      WHEN s3 =>
      
        IF vwrite1 = '1' THEN
          IF startcmd = '0' THEN
            nstate <= s0;
          END IF; --startcmd = '0'   
        ELSE --vwrite1 = '0'
         nstate <= s3;
        END IF; --vwrite1 = '1'
        
        IF startcmd = '1' AND flush = '1' THEN
          nstate    <= s1;
          flush_cmd <= '1';
        END IF; --startcmd = '1' AND flush = '1'
               
      WHEN s2 =>
        
        IF ready = '0' THEN
          nstate <= s1;
          flush_cmd <= '1';
        END IF; --ready = '0'
        
        IF startcmd = '1' THEN
        
          IF delaycmd1 = '0'  AND draw = '1' THEN
            nstate <= s2;
          END IF; --delaycmd = '0'
        
        ELSE --startcmd = '0'
          
          IF delaycmd1 = '0' THEN
            nstate <= s0;
          END IF; --delaycmd = '0'
        
        END IF; --startmcd = '1'
      
      WHEN OTHERS => nstate <= s0;
    END CASE;
  END IF;
END PROCESS FSM;
vwrite    <= vwrite1;
delaycmd  <= delaycmd1;
C1 : PROCESS
BEGIN
WAIT UNTIL rising_edge(clk);
  state <= nstate;
END PROCESS C1;

-----------DATAFLOW STATEMENTS-------
delaycmd <= NOT ready AND waitx;
empty <= NOT ready OR flush_cmd;
start <= NOT ready OR flush_cmd;

END ARCHITECTURE behav;