LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.cl_utility.ALL;
PACKAGE cl_pack IS
	FUNCTION is_in_rect(
		pixnum 		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		oldX		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0)	
	) RETURN BOOLEAN;
	
	FUNCTION is_greaterthan_maxX(
		oldX 		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		pixnum		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0)
	) RETURN BOOLEAN;	
	
	FUNCTION is_outside_max_points(
		pixnum		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		maxX		: std_logic_vector(x_size - 1 DOWNTO 0);
		maxY		: std_logic_vector(x_size - 1 DOWNTO 0)
	) RETURN BOOLEAN;
	
	FUNCTION is_block_in_rect(
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		oldX		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0)			
	) RETURN BOOLEAN;
	
	ALIAS usg IS unsigned;
	ALIAS sg  IS signed;
	ALIAS slv IS std_logic_vector;
	
END PACKAGE cl_pack;

PACKAGE BODY cl_pack IS	
	FUNCTION is_in_rect(
		pixnum 		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		oldX		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0)
	) 
	RETURN BOOLEAN IS
		VARIABLE XTermOld, XTermCurrent : SIGNED(x_size - 1 DOWNTO 0);
		VARIABLE YTermOld, YTermCurrent : SIGNED(x_size - 1 DOWNTO 0);
		VARIABLE diffX, diffY 			: SIGNED(x_size - 1 DOWNTO 0);
	BEGIN
		XTermOld 		:= abs(sg(usg(pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0)) - usg(oldX)));
		XTermCurrent 	:= abs(sg(usg(currentX) - usg(pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0))));
		diffX			:= abs(sg(usg(currentX) - usg(oldX)));
		
		YTermOld 		:= abs(sg(usg(pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2)) - usg(oldY)));
		YTermCurrent	:= abs(sg(usg(currentY) - usg(pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2))));
		diffY			:= abs(sg(usg(currentY) - usg(oldY)));
	IF(((XTermOld + XTermCurrent) = diffX)
				AND ((YTermOld) + YTermCurrent) = diffY) THEN	
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
	END is_in_rect;
	
	FUNCTION is_greaterthan_maxX(
		oldX 		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		pixnum		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0)
	) RETURN BOOLEAN IS
	
	VARIABLE maxX, maxY : std_logic_vector(x_size - 1 DOWNTO 0);
	VARIABLE x, y 		: std_logic_vector(x_size - 1 DOWNTO 0);
	BEGIN
		IF usg(currentX) >  usg(oldX) THEN
			maxX := currentX;
		ELSE
			maxX := oldX;
		END IF;
		
		IF usg(currentY) > usg(oldY) THEN
			maxY := currentY;
		ELSE
			maxY := oldY;
		END IF;
		
	x := pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0);
	y := pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2);
	
	IF x >= maxX THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
		
	END is_greaterthan_maxX;
	
	FUNCTION is_outside_max_points(
		pixnum		: std_logic_vector(p_size - 1 DOWNTO 0);
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		maxX		: std_logic_vector(x_size - 1 DOWNTO 0);
		maxY		: std_logic_vector(x_size - 1 DOWNTO 0)
	) RETURN BOOLEAN IS
	
	BEGIN
		IF (usg(pixword(7 DOWNTO 4) & pixnum(3 DOWNTO 2)) >= usg(maxY)) AND (usg(pixword(3 DOWNTO 0) & pixnum(1 DOWNTO 0)) >= usg(maxX)) THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END is_outside_max_points;
	
	FUNCTION is_block_in_rect(
		pixword 	: std_logic_vector(a_size - 1 DOWNTO 0);
		currentX 	: std_logic_vector(x_size - 1 DOWNTO 0);
		currentY 	: std_logic_vector(x_size - 1 DOWNTO 0);
		oldX		: std_logic_vector(x_size - 1 DOWNTO 0);
		oldY 		: std_logic_vector(x_size - 1 DOWNTO 0)			
	) RETURN BOOLEAN IS
		VARIABLE pixnum 	: std_logic_vector(p_size - 1 DOWNTO 0);
		VARIABLE is_in 		: BOOLEAN := TRUE;
	BEGIN
		pixnum := (OTHERS => '0');
		FOR i IN word_size - 1 DOWNTO 0 LOOP
			IF NOT (is_in_rect(pixnum, pixword, currentX, currentY, oldX, oldY)) THEN
				is_in := FALSE;
			END IF;
			pixnum := slv(usg(pixnum) + 1);
		END LOOP;
		RETURN is_in;
	END is_block_in_rect;
	
END cl_pack;