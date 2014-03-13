--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.log2;
use IEEE.MATH_REAL.ceil;

package logi_utils_pack is

function nbit(max : integer) return integer;
function count_ones(slv : std_logic_vector) return natural;
function max(LEFT : integer ; RIGHT: integer) return integer ;

type slv8_array is array (natural range <>) of std_logic_vector(7 downto 0);
type slv16_array is array (natural range <>) of std_logic_vector(15 downto 0);
type slv32_array is array (natural range <>) of std_logic_vector(31 downto 0);

end logi_utils_pack;

package body logi_utils_pack is

	function nbit (max : integer) return integer is
		begin
		return (integer(ceil(log2(real(max)))));
	end nbit;
 
	function count_ones(slv : std_logic_vector) return natural is
	  variable n_ones : natural := 0;
		begin
		  for i in slv'range loop
			 if slv(i) ='1' then
				n_ones := n_ones + 1;
			 end if;
		  end loop;
	  return n_ones;
	end function count_ones;

	function max(LEFT : integer; RIGHT: INTEGER) return INTEGER is
		begin
			 if LEFT > RIGHT then return LEFT;
			 else return RIGHT;
		end if;
	end max;
 
end logi_utils_pack;
