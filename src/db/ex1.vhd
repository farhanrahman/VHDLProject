LIBRARY IEEE;

USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY draw_octant IS
  GENERIC(
		vsize : INTEGER := 6
  );
  PORT(
    clk, resetx, resetg, delay, draw, xbias		: IN  std_logic;
    xin, yin                 					: IN  std_logic_vector(vsize - 1 DOWNTO 0);
    done                     					: OUT std_logic;
    x, y                     					: OUT std_logic_vector(vsize - 1 DOWNTO 0)
    );
END ENTITY draw_octant;

ARCHITECTURE comb OF draw_octant IS

  SIGNAL done1                    : std_logic;
  SIGNAL x1, y1                   : std_logic_vector(vsize - 1 DOWNTO 0);
  SIGNAL xincr, yincr, xnew, ynew : std_logic_vector(vsize - 1 DOWNTO 0);
  SIGNAL error                    : std_logic_vector(vsize - 1 DOWNTO 0);
  SIGNAL err1, err2               : std_logic_vector(vsize DOWNTO 0);

  ALIAS slv IS std_logic_vector;
  ALIAS sg	IS signed;

BEGIN



  C1 : PROCESS(error, xincr, yincr, x1, y1, xnew, ynew, resetx, draw)


    
  BEGIN
		-- err1 = | error + yincr |
		err1 <= slv(resize(abs(sg(error) + sg(yincr)), (vsize+1)));
		
		-- err2 = | error + yincr - xincr |
		err2 <= slv(resize(abs(sg(error) + sg(yincr) - sg(xincr)), (vsize+1)));
		
		-- done =  x = xnew and y = ynew
		IF ((x1 = xnew) and (y1 = ynew) and (resetx = '0') and (draw = '0')) THEN
		  done1 <= '1';
		ELSE
		  done1 <= '0';
		END IF;
		

		
  END PROCESS C1;

  R1 : PROCESS
  
  BEGIN
		WAIT UNTIL clk'EVENT AND clk = '1';
		IF ((resetx = '1') and (delay = '0')) THEN -- RESET
			error <= (OTHERS => '0'); 
			x1 <= xin;
			y1 <= yin;
			xincr <= (OTHERS => '0');
			yincr <= (OTHERS => '0');
			xnew <= xin;
			ynew <= yin;
		
		ELSIF ((resetx = '0') and (draw = '1') and (delay = '0')) THEN -- DRAW
			xincr <= slv(sg(xin) - sg(x1));
			yincr <= slv(sg(yin) - sg(y1));
			xnew <= xin;
			ynew <= yin;
			
		ELSIF ((resetx = '0') and (draw = '0') and (done1 = '0') and (delay = '0')) THEN 
			x1 <= slv(sg(x1) + 1);
			
			IF ((sg(err1) > sg(err2)) or ((err1 = err2) and (xbias = '0'))) THEN
				y1 <= slv(sg(y1) + 1);
				error <= slv(sg(error) + sg(yincr) - sg(xincr));
			ELSIF ((sg(err1) < sg(err2)) or ((err1 = err2) and (xbias = '1'))) THEN
				error <= slv(sg(error) + sg(yincr));
			END IF;
		
		ELSIF ((resetx = '0') and (draw = '0') and (done1 = '1')) THEN
			NULL; -- do nothing		
		END IF;
		
		IF resetg = '1' THEN
			error <= (OTHERS => '0'); 
			x1 <= (OTHERS => '0');
			y1 <= (OTHERS => '0');
			xincr <= (OTHERS => '0');
			yincr <= (OTHERS => '0');
			xnew <= (OTHERS => '0');
			ynew <= (OTHERS => '0');
		END IF;
		
  END PROCESS R1;
	
	done <= done1;

		-- drive x and y from x1 and y1 (otherwise we cannot read output)
	x <= x1;
	y <= y1;
END ARCHITECTURE comb;

