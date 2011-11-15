LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;  -- add unsigned, signed
USE work.ALL;


ENTITY ram_fsm_tb is
  PORT(z: OUT INTEGER);--included so that estate will be in wave & dataflow
END ram_fsm_tb;



ARCHITECTURE testbench OF ram_fsm_tb is

   
   SIGNAL clk, reset_hard, reset, reset_i, start_i, delay_i, vwrite_i: STD_LOGIC;
   
   TYPE xstate_t IS (mx,m1,m2,m3);
   
   SIGNAL estate: xstate_t;
   
   ALIAS slv IS std_logic_vector;
   
begin

reset_i <= reset_hard or reset;

   dut: ENTITY ram_fsm
      PORT MAP (
         clk => clk,
         reset=>reset_i,
         start => start_i,
         delay => delay_i,
         vwrite => vwrite_i);

p1_clkgen: process
       begin
          clk <= '0';
          WAIT for 50 ns;
          clk <= '1';
          WAIT for 50 ns;
       END process p1_clkgen;


p2_rstgen: process
   begin
      reset_hard <= '1';
      WAIT UNTIL clk'event AND clk='1';
      reset_hard <= '0';
      WAIT; -- wait forever (don't want to loop!)
   END process p2_rstgen;



   p3_main: process
      -- test f3_alu;

      TYPE test_rec_type IS
         RECORD
            reset, start: std_logic;
			      outputs: std_logic_vector(1 DOWNTO 0); --(delay, vwrite)
            state_expected: xstate_t;
         END record;
                           
      TYPE test_table_type IS ARRAY (natural RANGE <>) OF test_rec_type;

      CONSTANT test_table: test_table_type := (
      -- 
      -- reset, start, (delay,vwrite),expected state
	    --
         ('0','0',"00",mx),
         ('0','1',"00",mx),
		 ('0','0',"00",m1),
		 ('0','0',"00",m2),
		 ('0','1',"01",m3),
		 ('0','1',"10",m1),
		 ('0','1',"10",m2),
		 ('0','0',"01",m3),
		 ('0','0',"00",mx),
		 ('0','0',"00",mx)
         );
   BEGIN

      WAIT UNTIL reset_hard'event AND reset_hard='0';
      WAIT FOR 0 ns;
      -- after reset
      FOR n IN test_table'RANGE loop
      start_i <= test_table(n).start;
      reset <= test_table(n).reset;
      estate <= test_table(n).state_expected;
      REPORT "Starting Test " & integer'image(n);
         
      WAIT UNTIL clk'EVENT and clk = '1';
      -- process the result
      IF  test_table(n).outputs = (delay_i,vwrite_i) THEN
         REPORT "test " & integer'image(n) & " PASSED.";
      ELSE
         REPORT "test " & integer'image(n) & " FAILED." &
         " outputs are " & std_logic'image(delay_i) & 
		      std_logic'image(vwrite_i) &
            ", should be " & std_logic'image(test_table(n).outputs(1)) & 
		      std_logic'image(test_table(n).outputs(0))
      SEVERITY failure;
      END IF;

      END loop; -- n

      
      -- only way to stop Modelsim at end is using a failure assert
      -- this leads to a 'failure' message when everything is OK. ;)
      --
      REPORT "All tests finished OK, terminating with failure ASSERT."
      SEVERITY failure;
      
   END process p3_main;
   
   
   p4: PROCESS(estate)
   -- estate cannot directly be OUT port, so it drives z which is
   -- OUT port means estate will be visible in simulation
   -- otherwise it drives nothing and will be ignored
   BEGIN
     CASE estate IS
     WHEN mx => z <= 0;
     WHEN m1 => z <= 1;
     WHEN m2 => z <= 2;
     WHEN m3 => z <= 3;
   END CASE;
 END PROCESS p4;

   
END testbench;


