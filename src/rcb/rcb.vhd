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
		w_size 		: INTEGER := 8;
		p_size		: INTEGER := 4
	);
	
	PORT(
		clk, reset	: IN std_logic;
		x,y 		: IN std_logic_vector(5 DOWNTO 0);
		rcbcmd 		: IN std_logic_vector(2 DOWNTO 0);
		startcmd 	: IN std_logic;
		delaycmd 	: OUT std_logic;
		vaddr     : OUT std_logic_vector(w_size - 1 DOWNTO 0);
		vdin      : OUT std_logic_vector(w_size - 1 DOWNTO 0);
		vdout     : IN std_logic_vector(w_size - 1 DOWNTO 0);
		vwrite    : OUT std_logic
	);
END ENTITY rcb;


ARCHITECTURE behav OF rcb IS
	SIGNAL pixword 	: std_logic_vector(w_size - 1 DOWNTO 0);
	SIGNAL pixnum 	: std_logic_vector(p_size - 1 DOWNTO 0);
	SIGNAL pixopin  : pixop_t;
	SIGNAL clean   : std_logic;
	SIGNAL ready   : std_logic;
	SIGNAL empty   : std_logic;
	SIGNAL store   : store_t;
	SIGNAL word    : std_logic_vector(w_size - 1 DOWNTO 0);
	
	
	SIGNAL start   : std_logic;
	SIGNAL waitx   : std_logic;
	
	ALIAS slv IS std_logic_vector;
	ALIAS usg IS unsigned;
	ALIAS sg IS signed;
	
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
	 vwrite	 => vwrite,
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
	temp_y       := slv(resize(sg(y(5 DOWNTO 2)), w_size) sll 4); --sll 4 needs to change for other bit sizes
	temp_y_pix   := slv(resize(sg(y(1 DOWNTO 0)), p_size) sll 2); -- sll 2 needs to change as well
	
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

C1 : PROCESS
BEGIN

WAIT UNTIL rising_edge(clk);


END PROCESS C1;

-----------DATAFLOW STATEMENTS-------
delaycmd <= NOT ready AND waitx;
empty <= ready;
start <= ready;

END ARCHITECTURE behav;