LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.pix_cache_pak.ALL;

PACKAGE pix_tb_pak IS
  TYPE pixop_tb_t IS (':', 'W', 'B', '*', 'X');  -- easy to read pixop type for testbenches
  TYPE pixop_tb_vec IS ARRAY (integer RANGE <>) OF pixop_tb_t;  -- vectors of above
  TYPE pixop_vec IS ARRAY (integer RANGE <>) OF pixop_t;  -- vectors of pixop_t

  FUNCTION to_sl (i : integer RANGE 0 TO 1) RETURN std_logic;

  FUNCTION to_pixop_tb_vec (p : pixop_vec) RETURN pixop_tb_vec;
  FUNCTION to_pixop_vec (p    : pixop_tb_vec) RETURN pixop_vec;

  FUNCTION cp2tb (p : pixop_t) RETURN pixop_tb_t;
  FUNCTION ctb2p (p : pixop_tb_t) RETURN pixop_t;

END PACKAGE pix_tb_pak;

PACKAGE BODY pix_tb_pak IS

  FUNCTION to_sl (i : integer RANGE 0 TO 1) RETURN std_logic IS
    VARIABLE r : std_logic;
  BEGIN
    CASE i IS
      WHEN 0 => r := '0';
      WHEN 1 => r := '1';
    END CASE;
    RETURN r;
  END FUNCTION to_sl;

  FUNCTION cp2tb (p : pixop_t) RETURN pixop_tb_t IS
    VARIABLE result : pixop_tb_t;
  BEGIN
    CASE p IS
      WHEN same   => result := ':';
      WHEN white  => result := 'W';
      WHEN black  => result := 'B';
      WHEN invert => result := '*';
      WHEN OTHERS => result := 'X';
    END CASE;
    RETURN result;
  END FUNCTION cp2tb;

  FUNCTION ctb2p (p : pixop_tb_t) RETURN pixop_t IS
    VARIABLE result : pixop_t;
  BEGIN
    CASE p IS
      WHEN ':' => result := same;
      WHEN 'W'  => result := white;
      WHEN 'B'  => result := black;
      WHEN '*'  => result := invert;
      WHEN 'X'  => result := pixop_t'("XX");
    END CASE;
    RETURN result;
  END FUNCTION ctb2p;

  FUNCTION to_pixop_tb_vec (p : pixop_vec) RETURN pixop_tb_vec IS
    VARIABLE result : pixop_tb_vec (p'range);
  BEGIN
    FOR i IN result'range LOOP
      result(i) := cp2tb(p(i));
    END LOOP;
    RETURN result;
  END FUNCTION to_pixop_tb_vec;

  FUNCTION to_pixop_vec (p : pixop_tb_vec) RETURN pixop_vec IS
    VARIABLE result : pixop_vec (p'range);
  BEGIN
    FOR i IN result'range LOOP
      result(i) := ctb2p(p(i));
    END LOOP;
    RETURN result;
  END FUNCTION to_pixop_vec;
END PACKAGE BODY pix_tb_pak;

