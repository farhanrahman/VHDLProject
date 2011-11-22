-------------------------------------------------------------------------------
-- Title      : Testbench for design "pix_word_cache"
-- Project    : 
-------------------------------------------------------------------------------
-- File       : pix_word_cache_tb.vhd
-- Author     : TJWC
-- Company    : 
-- Created    : 2011-08-26
-- Platform   : 
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2011 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2011-08-26  1.0      tomcl   Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pix_cache_pak.ALL;
USE work.pix_tb_pak.ALL;
USE work.ex2_data_pak.ALL;

-------------------------------------------------------------------------------

ENTITY pix_word_cache_tb IS

END pix_word_cache_tb;

-------------------------------------------------------------------------------

ARCHITECTURE behav OF pix_word_cache_tb IS

  ALIAS slv IS std_logic_vector;        -- for convenience
  ALIAS sl IS std_logic;                -- for convenience

  -- entity ports
  SIGNAL reset, pw, empty : std_logic;
  SIGNAL pixnum           : slv(3 DOWNTO 0);
  SIGNAL pixopin          : pixop_t;
  SIGNAL pixword          : slv(3 DOWNTO 0);
  SIGNAL store            : store_t;
  SIGNAL word             : slv(3 DOWNTO 0);
  SIGNAL clean, ready     : std_logic;

  -- clock
  SIGNAL Clk : std_logic := '1';
  
procedure check_output ( 
     out_name: STRING; 
     out_val: std_logic;
     correct_val: std_logic ) is
 BEGIN
 assert correct_val = out_val
 report "Output " & out_name & " is " & std_logic'image(out_val) & " should be:" & std_logic'IMAGE(correct_val)
 severity error;
 end;

function pixop_image(po: pixop_t) return STRING is
begin
  case po is
    when same => return "same  " ;
    when invert => return "invert";
    when black => return "black ";
    when white => return "white ";
    when others => return "undef ";
  end case;
end;

function sig_image(name: string; x: std_logic) return STRING is
begin
   return name & " = " & std_logic'IMAGE(x) & "  ";
end;

function sig_image(name: string; x: INTEGER) return STRING is
begin
   return name & " = " & INTEGER'IMAGE(x) & "  ";
end;

BEGIN  -- behav

  -- entity instantiation
  DUT : ENTITY WORK.pix_word_cache
    PORT MAP (
      clk     => clk,
      reset   => reset,
      pw      => pw,
      empty   => empty,
      pixnum  => pixnum,
      pixopin => pixopin,
      pixword => pixword,
      store   => store,
      word    => word,
      clean   => clean,
      ready   => ready);

  -- clock generation
  Clk <= NOT Clk AFTER 10 ns;

  -- waveform generation
  p3_test : PROCESS
    VARIABLE xx, yy, dd, ddver : integer;
    VARIABLE rep               : string(1 TO 4);
    VARIABLE x                 : pixop_tb_t;
    VARIABLE dat               : data_t_rec;
    
  BEGIN
    WAIT UNTIL clk'event AND clk = '1';
    FOR n IN data'range LOOP
      
      dat     := data(n);  -- get record of this cycle stimulus & monitor data
      reset   <= to_sl(dat.rst);
      empty   <= to_sl(dat.empty);
      pw      <= to_sl(dat.pw);
      pixopin <= ctb2p(dat.pixop);
      pixnum  <= slv(to_unsigned(dat.pixnum, 4));
      pixword <= slv(to_unsigned(dat.pixword, 4));
      WAIT UNTIL clk'event AND clk = '1';
      REPORT "CYCLE " & integer'image(n) & ": " &  sig_image("reset",reset) &
           sig_image("empty",empty) & sig_image("pw",pw) &
           sig_image("pixnum",dat.pixnum) & sig_image("pixword",dat.pixword) &
           "pixopin=" & pixop_image( pixopin);
      IF reset = '0' THEN
        check_output("clean", clean, to_sl(data(n).clean));
        check_output("ready", ready, to_sl(data(n).ready));
        FOR i IN store'range LOOP
            ASSERT cp2tb(store(i)) = dat.store(i)
            REPORT "store("& integer'image(i) &") is "& pixop_image(store(i)) & " should be " &
              pixop_image(ctb2p(dat.store(i)))  SEVERITY failure;
        END LOOP;  -- i
      END IF;  --reset = '0'
      
    END LOOP;  -- n

    -- only way to stop Modelsim at end is using a failure assert
    -- this leads to a 'failure' message when everything is OK.
    --
    REPORT "All tests finished OK, terminating with failure ASSERT."
      SEVERITY failure;
    
  END PROCESS p3_test;

  

END behav;

