LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-- This package contains types and constants for use by the pix_word_cache block
-- pix_op_t is an array type used for the block ports, so this package must be
-- used by any architecture instantiated pix_word_cache.

-- Note that although the pixop_t array is similar to std_logic_vector(1 DOWNTO
-- 0) the two cannot be directly assigned. In practice pixop_t will always be
-- used via the constants defined in this package, with CASE statements to
-- detect values or generate values as required.

-- store_t is the array type based on pixop_t that stores pixel operations.
-- Again it is used in  aport of pix_word_cache, so architectures instantiating
-- it will need to use this type.

PACKAGE pix_cache_pak IS
  TYPE pixop_t IS ARRAY (1 DOWNTO 0) OF std_logic;

  CONSTANT same   : pixop_t := "00";
  CONSTANT black  : pixop_t := "10";
  CONSTANT white  : pixop_t := "01";
  CONSTANT invert : pixop_t := "11";

  TYPE store_t IS ARRAY (0 TO 15) OF pixop_t;
END PACKAGE pix_cache_pak;
