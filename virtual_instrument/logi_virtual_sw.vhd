----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:15:04 12/17/2013 
-- Design Name: 
-- Module Name:    logi_virtual_sw - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity logi_virtual_sw is
	generic(
		  wb_size : natural := 16  -- Data port size for wishbone
	 );
	 port 
	 (
		  -- Syscon signals
		  gls_reset    : in std_logic ;
		  gls_clk      : in std_logic ;
		  -- Wishbone signals
		  wbs_add       : in std_logic_vector(15 downto 0) ;
		  wbs_writedata : in std_logic_vector( wb_size-1 downto 0);
		  wbs_readdata  : out std_logic_vector( wb_size-1 downto 0);
		  wbs_strobe    : in std_logic ;
		  wbs_cycle      : in std_logic ;
		  wbs_write     : in std_logic ;
		  wbs_ack       : out std_logic;
		  -- out signals
		  sw : out std_logic_vector(15 downto 0)
	 );

end logi_virtual_sw;

architecture Behavioral of logi_virtual_sw is
	signal reg_out_d : std_logic_vector(15 downto 0) ;
	signal read_ack : std_logic ;
	signal write_ack : std_logic ;
begin
	wbs_ack <= read_ack or write_ack;

	write_bloc : process(gls_clk,gls_reset)
	begin
		 if gls_reset = '1' then 
			  reg_out_d <= (others => '0');
			  write_ack <= '0';
		 elsif rising_edge(gls_clk) then
			  if ((wbs_strobe and wbs_write and wbs_cycle) = '1' ) then
					reg_out_d  <= wbs_writedata;
					write_ack <= '1';
			  else
					write_ack <= '0';
			  end if;
		 end if;
	end process write_bloc;
	sw <= reg_out_d ;


	read_bloc : process(gls_clk, gls_reset)
	begin
		 if gls_reset = '1' then
			  
		 elsif rising_edge(gls_clk) then
			  if (wbs_strobe = '1' and wbs_write = '0'  and wbs_cycle = '1' ) then
					read_ack <= '1';
			  else
					read_ack <= '0';
			  end if;
			  
		 end if;
	end process read_bloc;


end Behavioral;

