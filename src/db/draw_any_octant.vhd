LIBRARY IEEE;

USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.ALL;

ENTITY draw_any_octant IS

  -- swapxy negx  negy  octant
  --  0      0      0     ENE
  --  1      0      0     NNE
  --  1      1      0     NNW
  --  0      1      0     WNW
  --  0      1      1     WSW
  --  1      1      1     SSW
  --  1      0      1     SSE
  --  0      0      1     ESE

  -- swapxy: x & y swap round on inputs & outputs
  -- negx:   invert bits of x on inputs & outputs
  -- negy:   invert bits of y on inputs & outputs

  -- xbias always give nias in x axis direction, so swapxy must invert xbias
  GENERIC(
    vsize: INTEGER := 6
  );
  
  PORT(
    clk, resetg, resetx, delay, draw, xbias : IN  std_logic;
    xin, yin                 : IN  std_logic_vector(vsize-1 DOWNTO 0);
    done                     : OUT std_logic;
    x, y                     : OUT std_logic_vector(vsize-1 DOWNTO 0);
    swapxy, negx, negy       : IN  std_logic
    );
END ENTITY draw_any_octant;

ARCHITECTURE comb OF draw_any_octant IS
  -- you may find the following signals useful, if not delete them
  SIGNAL xin1, yin1, xin1temp, yin1temp, x1, y1, xtemp, ytemp		: std_logic_vector(xin'range);
  SIGNAL xbias1, negx1, negy1, swapxy1								: std_logic;

BEGIN

	-- wrapper draw_octant
	wrapper : ENTITY draw_octant
	GENERIC MAP(
		vsize 	=> vsize
	)
    PORT MAP (
      clk    => clk,
      resetx => resetx,
      delay  => delay,
	  draw   => draw,
      done   => done,
      x      => x1,
      y      => y1,
      xin    => xin1,
      yin    => yin1,
      xbias  => xbias1);

	C1 : PROCESS(xin, yin, yin1temp, xin1temp, xbias, negx, negy, swapxy) -- combinational process for cycle x
	
	BEGIN	
		
		-- defaults
		xin1temp <= xin;
		yin1temp <= yin;
		
		-- negx
		IF (negx = '1') THEN
			xin1temp <= NOT xin;
		END IF;
		
		-- negy
		IF (negy = '1') THEN
			yin1temp <= NOT yin;
		END IF;
		
		-- swapxy & final xyin
		IF (swapxy = '1') THEN
			xin1 <= yin1temp;
			yin1 <= xin1temp;
		ELSE
			xin1 <= xin1temp;
			yin1 <= yin1temp;
		END IF;	
		
		-- xbias
		IF (swapxy = '1') THEN
			xbias1 <= NOT xbias;
		ELSE
			xbias1 <= xbias;
		END IF;
		
	END PROCESS C1;
	
	
	C2 : PROCESS(x1, y1, negx1, negy1, swapxy1, xtemp, ytemp) -- combinational process for cycle x+1
	
	BEGIN	
		
		-- defaults
		xtemp <= x1;
		ytemp <= y1;
		
		-- negx
		IF (negx1 = '1') THEN
			xtemp <= NOT x1;
		END IF;
		
		-- negy
		IF (negy1 = '1') THEN
			ytemp <= NOT y1;
		END IF;
		
		-- swapxy & final xyin
		IF (swapxy1 = '1') THEN
			x <= ytemp;
			y <= xtemp;
		ELSE
			x <= xtemp;
			y <= ytemp;
		END IF;	
			
	
	END PROCESS C2;
	
	
	R1 : PROCESS -- registered process

	BEGIN
		WAIT UNTIL clk'EVENT AND clk = '1';
			-- n+1 cycle signals
			negx1 <= negx;
			negy1 <= negy;
			swapxy1 <= swapxy;
		
	END PROCESS R1;
  
END ARCHITECTURE comb;

