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

package logi_wishbone_peripherals_pack is

component wishbone_register is
	generic(
		  wb_size : natural := 16 -- Data port size for wishbone
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
		  reg_out : out std_logic_vector(wb_size-1 downto 0);
		  reg_in : in std_logic_vector(wb_size-1 downto 0)
	 );
end component;

component wishbone_fifo is
generic( ADDR_WIDTH: positive := 16; --! width of the address bus
			WIDTH	: positive := 16; --! width of the data bus
			SIZE	: positive	:= 128; --! fifo depth
			BURST_SIZE : positive := 4;
			SYNC_LOGIC_INTERFACE : boolean := false 
			); 
port(
	-- Syscon signals
	gls_reset    : in std_logic ;
	gls_clk      : in std_logic ;
	-- Wishbone signals
	wbs_add       : in std_logic_vector(ADDR_WIDTH-1 downto 0) ;
	wbs_writedata : in std_logic_vector( WIDTH-1 downto 0);
	wbs_readdata  : out std_logic_vector( WIDTH-1 downto 0);
	wbs_strobe    : in std_logic ;
	wbs_cycle      : in std_logic ;
	wbs_write     : in std_logic ;
	wbs_ack       : out std_logic;
		  
	-- logic signals  
	wrB, rdA : in std_logic ; --! logic side fifo control signal
	inputB: in std_logic_vector((WIDTH - 1) downto 0); --! data input of fifo B
	outputA	: out std_logic_vector((WIDTH - 1) downto 0); --! data output of fifo A
	emptyA, fullA, emptyB, fullB, burst_available_B	:	out std_logic --! fifo state signals
);
end component;

end logi_wishbone_peripherals_pack;

package body logi_wishbone_peripherals_pack is

 
end logi_wishbone_peripherals_pack;
