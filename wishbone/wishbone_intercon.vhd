----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:21:48 12/28/2013 
-- Design Name: 
-- Module Name:    wishbone_intercon - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work ;
use work.logi_wishbone_pack.all ;

entity wishbone_intercon is
generic(memory_map : array_of_addr );
port(
		-- Syscon signals
		gls_reset    : in std_logic ;
		gls_clk      : in std_logic ;
		
		
		-- Wishbone slave signals
		wbs_address       : in std_logic_vector(15 downto 0) ;
		wbs_writedata : in std_logic_vector(15 downto 0);
		wbs_readdata  : out std_logic_vector(15 downto 0);
		wbs_strobe    : in std_logic ;
		wbs_cycle      : in std_logic ;
		wbs_write     : in std_logic ;
		wbs_ack       : out std_logic;
		
		-- Wishbone master signals
		wbm_address       : out array_of_slv16((memory_map'length-1) downto 0) ;
		wbm_writedata : out array_of_slv16((memory_map'length-1) downto 0);
		wbm_readdata  : in array_of_slv16((memory_map'length-1) downto 0);
		wbm_strobe    : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_cycle     : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_write     : out std_logic_vector((memory_map'length-1) downto 0) ;
		wbm_ack       : in std_logic_vector((memory_map'length-1) downto 0)
		
);
end wishbone_intercon;

architecture Behavioral of wishbone_intercon is

signal cs_vector : std_logic_vector(0 to (memory_map'length-1));

begin


gen_cs : for i in 0 to (memory_map'length-1) generate
	
	cs_vector(i) <= '1' when wbs_address(wbs_address'length-1 downto find_X(memory_map(i))) = memory_map(i)(wbs_address'length-1 downto find_X(memory_map(i))) else
					    '0' ;
						 
	wbm_address(i) <= wbs_address ;
	wbm_writedata(i) <= wbs_writedata ;
	wbm_write(i) <= wbs_write and cs_vector(i) ;
	wbm_strobe(i) <= wbs_strobe and cs_vector(i) ;
	wbm_cycle(i) <= wbs_cycle and cs_vector(i) ;
	
	wbs_readdata <= wbm_readdata(i) when cs_vector(i) = '1' else
						(others => 'Z') ;
	
end generate ;

wbs_ack <= '1' when (cs_vector and wbm_ack) /= 0 else
			  '0' ;
wbs_readdata <= (others => '0') when cs_vector = 0 else
					(others => 'Z') ;

end Behavioral;

