-- Package of utility functions for VHDL
-- Thomas Clarke 2001
--
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_arith.ALL;



PACKAGE utility_pack IS


   TYPE string_type IS ACCESS STRING;  -- variable length strings

   FUNCTION maximum( a : INTEGER; b : INTEGER) RETURN INTEGER;
   FUNCTION minimum( a : INTEGER; b : INTEGER) RETURN INTEGER;

   IMPURE FUNCTION random (l : IN INTEGER;
                           h : IN INTEGER) RETURN INTEGER;

   -- makes a 32 bit vector with bits from n down to m set to '1'
   FUNCTION ones_mask( n : INTEGER; m : INTEGER) RETURN STD_LOGIC_VECTOR;

   -- makes a 32 bit vector with bit n set to '1'
   FUNCTION ones_mask( n : INTEGER) RETURN STD_LOGIC_VECTOR;

   -- std_logic_vector to unsigned interger
   FUNCTION v2i( x : STD_LOGIC_VECTOR) RETURN INTEGER;

   -- integer to string: used to add debug printout to ASSERT messages
   -- if width is present, print in a fixed-width field
   FUNCTION i2s( val : INTEGER) RETURN STRING;
   FUNCTION i2s(val  : INTEGER; width : INTEGER) RETURN STRING;

   -- std_logic vector to string representing unsigned integer value
   FUNCTION v2s( x : STD_LOGIC_VECTOR) RETURN STRING;

   -- std_logic_vector to string representing its hex value
   FUNCTION v2sh( x : STD_LOGIC_VECTOR) RETURN STRING;

   -- boolean to std_logic
   FUNCTION b2s( b : BOOLEAN) RETURN STD_LOGIC;

   -- std_logic_vector to string representing binary value
   -- VHDL93 only
   FUNCTION v2sb( x : STD_LOGIC_VECTOR) RETURN STRING;

   -- return vector of n zeros
   FUNCTION zeros( n : NATURAL) RETURN STD_LOGIC_VECTOR;
   -- return vector of n '1's


   FUNCTION ones( n : NATURAL) RETURN STD_LOGIC_VECTOR;

   -- round x up to nearest integer divisible by m. (preserve 0).
   FUNCTION round_up( x : INTEGER; m : INTEGER) RETURN INTEGER;

   -- wait until nth clock 0->1 transition
   PROCEDURE delay( SIGNAL clk : IN STD_LOGIC; n : INTEGER);

   -- drive signal drive with waveform (new bit every 0->1 transition of clk)
   PROCEDURE gen_waveform(
      SIGNAL clk   : IN  STD_LOGIC;
      SIGNAL drive : OUT STD_LOGIC;
      waveform     :     STD_LOGIC_VECTOR
      );


END;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
---------------------- PACKAGE BODY
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

PACKAGE BODY utility_pack IS

   CONSTANT MAX_DIGITS : INTEGER := 20;

   SUBTYPE int_string_buf IS STRING(1 TO MAX_DIGITS);


-------------------------------------------------------------------------------
-- GENERAL CONVENIENCE FUNCTIONS
-------------------------------------------------------------------------------

   FUNCTION maximum( a : INTEGER; b : INTEGER) RETURN INTEGER IS
   BEGIN
      IF a > b THEN
         RETURN a;
      ELSE
         RETURN b;
      END IF;
   END maximum;

   FUNCTION minimum( a : INTEGER; b : INTEGER) RETURN INTEGER IS
   BEGIN
      IF a < b THEN
         RETURN a;
      ELSE
         RETURN b;
      END IF;
   END minimum;


-- makes a 32 bit vector with bits from n down to m set to '1'
   FUNCTION ones_mask( n : INTEGER; m : INTEGER) RETURN STD_LOGIC_VECTOR IS

      VARIABLE x : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

   BEGIN
      ASSERT m >= 0 AND m < 32 REPORT
         "lower bound for make_ones_mask is not in range 0..31"
         SEVERITY failure;
      ASSERT n >= 0 AND n < 32 REPORT
         "upper bound for make_ones_mask is not in range 0..31"
         SEVERITY failure;
      ASSERT m <= n REPORT
                  "Range for mask has upper bound less than lower bound"
                  SEVERITY failure;
      FOR i IN n DOWNTO m LOOP
         x(i) := '1';
      END LOOP;
      RETURN x;
   END;

   -- makes a 32 bit vector with bit n set to '1'
   FUNCTION ones_mask( n : INTEGER) RETURN STD_LOGIC_VECTOR IS
      VARIABLE x         : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
   BEGIN
      ASSERT n >= 0 AND n < 32 REPORT
         "bound for make_ones_mask is not in range 0..31"
         SEVERITY failure;
      x(n)                                               := '1';
      RETURN x;
   END;


   -- round x up to nearest number divisible by m.
   FUNCTION round_up( x : INTEGER; m : INTEGER) RETURN INTEGER IS
   BEGIN
      ASSERT x >= 0 REPORT
         "Can't round up a negative INTEGER"
         SEVERITY failure;
      IF x = 0 THEN RETURN 0; END IF;
      RETURN ((x-1)/m + 1)*m;
   END;

   -- return vector of n zeros
   FUNCTION zeros( n : NATURAL) RETURN STD_LOGIC_VECTOR IS
      VARIABLE x     : STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (OTHERS => '0');
   BEGIN
      RETURN X;
   END;

   -- return vector of n '1's
   FUNCTION ones( n : NATURAL) RETURN STD_LOGIC_VECTOR IS
      VARIABLE x    : STD_LOGIC_VECTOR(n-1 DOWNTO 0) := (OTHERS => '1');
   BEGIN
      RETURN X;
   END;


   -- std_logic_vector to unsigned integer
   FUNCTION v2i( x : STD_LOGIC_VECTOR) RETURN INTEGER IS
   BEGIN
      RETURN conv_integer(UNSIGNED(x));
   END;

   -- stolen from TEXTIO! Converts integer val to string result,
   -- last is set to
   -- length of output string
   PROCEDURE Int_to_string(
      CONSTANT val    : IN  INTEGER;
      VARIABLE result : OUT int_string_buf;
      VARIABLE last   : OUT INTEGER)
   IS

      VARIABLE buf   : STRING(20 DOWNTO 1);
      VARIABLE pos   : INTEGER := 1;
      VARIABLE tmp   : INTEGER := ABS(val);
      VARIABLE digit : INTEGER;

   BEGIN
      LOOP
         digit    := ABS(tmp MOD 10);  -- MOD of integer'left
                                       -- returns neg number!
         tmp      := tmp / 10;
         buf(pos) := CHARACTER'VAL(CHARACTER'POS('0') + digit);
         pos      := pos + 1;
         EXIT WHEN tmp = 0;
      END LOOP;

      IF val < 0 THEN
         buf(pos) := '-';
         pos      := pos + 1;
      END IF;

      pos              := pos - 1;
      result(1 TO pos) := buf(pos DOWNTO 1);
      last             := pos;

   END Int_to_string;  -- procedure



   -- integer to string: used to add debug printout to ASSERT messages
   FUNCTION i2s(val : INTEGER)
      RETURN STRING
   IS
      VARIABLE buf  : int_string_buf;
      VARIABLE last : INTEGER;
   BEGIN
      Int_to_string(val, buf, last);
      RETURN buf(1 TO last);
   END i2s;  -- function

   -- integer to string: used to add debug printout to ASSERT messages
   FUNCTION i2s(val : INTEGER; width : INTEGER)
      RETURN STRING
   IS

      VARIABLE buf  : int_string_buf;
      VARIABLE last : INTEGER;
      VARIABLE res  : STRING(1 TO width) := (OTHERS => ' ');

   BEGIN
      Int_to_string(val, buf, last);
      IF width > last THEN
         res(1 TO last) := buf(1 TO last);
         RETURN res( 1 TO width);
      ELSE
         RETURN buf(1 TO last);
      END IF;
   END i2s;  -- function



   -- std_logic vector to string representing integer value
   FUNCTION v2s( x : STD_LOGIC_VECTOR) RETURN STRING IS
   BEGIN
      RETURN i2s( v2i( x));
   END;

   -- std_logic_vector to string with HEX value
   FUNCTION v2sh( x : STD_LOGIC_VECTOR) RETURN STRING IS

      VARIABLE n, h, digits : INTEGER;
      VARIABLE ch           : CHARACTER;

      VARIABLE xx : STD_LOGIC_VECTOR( round_up( x'LENGTH, 4) DOWNTO 1);

      VARIABLE str : STRING(xx'LENGTH/4 DOWNTO 1);

   BEGIN

      digits := round_up( x'LENGTH, 4)/4;
      xx     := zeros(4*digits - x'LENGTH) & x;
      -- put input into vector with standardised range

      FOR i IN str'RANGE LOOP

         h := v2i(xx(4*i DOWNTO 4*i-3));

         IF h < 10 THEN
            ch := CHARACTER'VAL(CHARACTER'POS('0')+h);
         ELSE
            ch := CHARACTER'VAL(CHARACTER'POS('A')+h-10);
         END IF;

         str(i) := ch;

      END LOOP;
      RETURN str;
   END;




   -- std_logic_vector to string representing binary value
   FUNCTION v2sb( x : STD_LOGIC_VECTOR) RETURN STRING IS

      VARIABLE s : STRING(x'LENGTH+2 DOWNTO 1) := (OTHERS => '"');

      VARIABLE xx : STD_LOGIC_VECTOR( x'LENGTH DOWNTO 1);

      FUNCTION s2ch( s : STD_LOGIC) RETURN CHARACTER IS
      BEGIN
         CASE s IS
            WHEN 'U' => RETURN 'U';  -- Uninitialized
            WHEN 'X' => RETURN 'X';  -- Forcing  Unknown
            WHEN '0' => RETURN '0';  -- Forcing  0
            WHEN '1' => RETURN '1';  -- Forcing  1
            WHEN 'Z' => RETURN 'Z';  -- High Impedance   
            WHEN 'W' => RETURN 'W';  -- Weak     Unknown
            WHEN 'L' => RETURN 'L';  -- Weak     0       
            WHEN 'H' => RETURN 'H';  -- Weak     1       
            WHEN '-' => RETURN '-';  -- Don't care
         END CASE;
      END;

   BEGIN
      xx      := x;
      FOR i IN x'LENGTH+1 DOWNTO 2 LOOP
         s(i) := s2ch(xx(i-1));
      END LOOP;
      RETURN s;
   END;

   -- boolean to std_logic
   FUNCTION b2s( b : BOOLEAN) RETURN STD_LOGIC IS
   BEGIN
      CASE b IS
         WHEN true  => RETURN '1';
         WHEN false => RETURN '0';
      END CASE;
   END b2s;




-------------------------------------------------------------------------------
-- SIGNAL GENERATION FUNCTIONS
-------------------------------------------------------------------------------


   -- wait N cycles.
   PROCEDURE delay( SIGNAL clk : IN STD_LOGIC; n : IN INTEGER) IS
   BEGIN
      FOR i IN 1 TO n LOOP
         WAIT UNTIL clk'EVENT AND clk = '1';
      END LOOP;
   END;

   -- never used this yet - it shows what can be done!
   PROCEDURE gen_waveform(
      SIGNAL clk   : IN  STD_LOGIC;
      SIGNAL drive : OUT STD_LOGIC;
      waveform     :     STD_LOGIC_VECTOR
      ) IS
   BEGIN
      FOR i IN waveform'left TO waveform'right LOOP
         drive <= waveform(i);
         WAIT UNTIL clk'EVENT AND clk = '1';
      END LOOP;
   END;

-------------------------------------------------------------------------------
-- RANDOM NUMBER GENERATOR
-------------------------------------------------------------------------------

   -- seed for random number generator
   SHARED VARIABLE randx : INTEGER;

   IMPURE FUNCTION random (l : IN INTEGER;
                           h : IN INTEGER) RETURN INTEGER IS

      VARIABLE max_int2         : INTEGER := 1073741823;            -- 30 bits
      VARIABLE randx_mult       : INTEGER := 551757623;
      VARIABLE Als              : INTEGER := randx_mult MOD 32768;  -- 15 LSBs
      VARIABLE Ams              : INTEGER := randx_mult / 32768;    -- 15 MSBs
      VARIABLE randx_var        : INTEGER;
      VARIABLE chunk            : INTEGER;
      VARIABLE A0B0, A1B0, A0B1 : INTEGER;
      VARIABLE i, j             : INTEGER;
   BEGIN

      A0B0 := (Als * (randx MOD 32768));                        -- Als * Bls
      A1B0 := (((Ams * (randx MOD 32768)) MOD 32768) * 32768);  -- Ams * Bls
      A0B1 := (((Als * (randx / 32768)) MOD 32768) * 32768);    -- Als * Bms

      randx_var := A0B0 + A1B0;

      IF (randx_var > max_int2) THEN
         randx_var := randx_var MOD max_int2;  -- Strip off 30 LSBs
      END IF;
      randx_var    := randx_var + A0B1 + 12345;
      IF (randx_var > max_int2) THEN
         randx_var := randx_var MOD max_int2;  -- Strip off 30 LSBs
      END IF;

      i     := (randx_var/2) * 2;   -- drop LSB
      chunk := max_int2 / (h+1-l);  -- break integer range into equal pieces
      randx := randx_var;
      RETURN (i / chunk) + l;
   END random;


END utility_pack;






