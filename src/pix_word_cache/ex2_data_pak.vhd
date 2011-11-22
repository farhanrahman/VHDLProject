
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.pix_cache_pak.ALL;
USE WORK.pix_tb_pak.ALL;

PACKAGE ex2_data_pak IS
    TYPE cyc IS (   reset,  -- reset = '1'
                    start,  -- draw = '1', xin,yin are driven from xin,yin
                    done,   -- done output = 1
                    drawing -- reset,start,done = '0', xin, yin are undefined
                );

    TYPE data_t_rec IS
    RECORD
        rst,empty,pw: INTEGER;
        pixop:  pixop_tb_t;
        pixnum,pixword: INTEGER;
        ready,clean,word: INTEGER;
        store: pixop_tb_vec(0 TO 15);
    END RECORD;

    TYPE data_t IS ARRAY (natural RANGE <>) OF data_t_rec;

    CONSTANT data: data_t :=(
--                 INPUTS                    ||           OUTPUTS
--  rst   empty   pw     pixop pixnum pixword  ready  clean  word    store

		(1,     0,     0,     ':',     0,     0,     0,     1,     0, "::::::::::::::::"),
		(0,     0,     0,     '*',     0,     0,     1,     1,     0, "::::::::::::::::"),
		(0,     0,     1,     'B',     3,     1,     1,     1,     0, "::::::::::::::::"),
		(0,     0,     1,     'W',     4,     1,     1,     0,     1, ":::B::::::::::::"),
		(0,     0,     1,     '*',     5,     1,     1,     0,     1, ":::BW:::::::::::"),
		(0,     0,     0,     '*',     5,     1,     1,     0,     1, ":::BW*::::::::::"),
		(0,     0,     1,     '*',     3,     1,     1,     0,     1, ":::BW*::::::::::"),
		(0,     0,     1,     '*',     4,     1,     1,     0,     1, ":::WW*::::::::::"),
		(0,     0,     1,     '*',     5,     1,     1,     0,     1, ":::WB*::::::::::"),
		(0,     1,     1,     'B',     0,     2,     1,     0,     1, ":::WB:::::::::::"),
		(0,     1,     0,     ':',     0,     2,     1,     0,     2, "B:::::::::::::::"),
		(0,     0,     0,     ':',     0,     2,     1,     1,     2, "::::::::::::::::"),
		(0,     0,     0,     ':',     0,     3,     1,     1,     2, "::::::::::::::::"),
		(0,     1,     0,     '*',     0,     2,     1,     1,     2, "::::::::::::::::")
	);
END PACKAGE ex2_data_pak;
