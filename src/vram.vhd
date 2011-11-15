-- Behavioural implementation of VDP Video Ram
-- Provides warning errors of RAM timing parameters
-- are not met
-- Thomas Clarke, 2001
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE work.vdp_pack.ALL;



ENTITY vram IS
   PORT(
      vdin   : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      vdout  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      vaddr  : IN  STD_LOGIC_VECTOR;
      vwrite : IN  STD_LOGIC;
      reset: IN STD_LOGIC
      );
END vram;


ARCHITECTURE behav OF vram IS
  




   SIGNAL ram_write_detect : STD_LOGIC := '0';

   SIGNAL vaddr_delta_1 : STD_LOGIC_VECTOR(vaddr'RANGE);

   SIGNAL vwrite_delta_1: std_logic;

   SIGNAL dout_valid : BOOLEAN;

BEGIN

   vaddr_delta_1 <= vaddr;
   vwrite_delta_1 <= vwrite;

   dout_valid <= vaddr'STABLE(tracc);

   ASSERT vaddr'STABLE(taws) OR (vwrite = '0') REPORT
      "vram address setup error"
      SEVERITY warning;

   p_trwp_check : PROCESS
   BEGIN
      WAIT UNTIL vwrite'EVENT AND vwrite = '0' AND vwrite'LAST_VALUE = '1'
         AND NOT vwrite_delta_1'STABLE(twp);
      REPORT "write pulse < twp" SEVERITY warning;
   END PROCESS p_trwp_check;

   p_write : PROCESS
   BEGIN
      WAIT UNTIL (vwrite'EVENT AND vwrite = '0' AND vwrite'LAST_VALUE = '1'
         AND vwrite_delta_1'STABLE(twp)) OR (reset'EVENT);
      IF reset'EVENT THEN ram_data:=(OTHERS=>(OTHERS=>'0'));
      ELSE
      -- check that data setup time has been met
        IF vdin'STABLE(twds) THEN
         -- write data
          ram_data(conv_integer(UNSIGNED(vaddr_delta_1))) := vdin;
        ELSE
          -- write undefined (setup violation)
          ram_data(conv_integer(UNSIGNED(vaddr_delta_1))) := (OTHERS => 'X');
        END IF;
      END IF;

      ram_write_detect <= NOT ram_write_detect;  -- trigger read process
   END PROCESS p_write;


   p_read : PROCESS(vaddr,dout_valid,ram_write_detect)
   BEGIN
      -- output data may change if either dout_valid, vaddr,
      -- or ram_write_detect changes
      IF dout_valid THEN      --address stable for more than tracc, so data ok
         vdout <= ram_data(conv_integer(UNSIGNED(vaddr)));
      ELSE                    -- address stable for less than tracc, so data undefined
         vdout <= (OTHERS => 'X');
      END IF;
   END PROCESS p_read;

END behav;
