

-- ----------------------------------------------------------------------
--LOGI-hard
--Copyright (c) 2013, Jonathan Piat, Michael Jones, All rights reserved.
--
--This library is free software; you can redistribute it and/or
--modify it under the terms of the GNU Lesser General Public
--License as published by the Free Software Foundation; either
--version 3.0 of the License, or (at your option) any later version.
--
--This library is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public
--License along with this library.
-- ----------------------------------------------------------------------



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

package logi_wishbone_pack is

 component gpmc_wishbone_wrapper is
    generic(sync : boolean := false ; burst : boolean := false );
	 port
    (
      -- GPMC SIGNALS
      gpmc_ad : inout   std_logic_vector(15 downto 0);
      gpmc_csn    : in    std_logic;
      gpmc_oen    : in    std_logic;
		gpmc_wen    : in    std_logic;
		gpmc_advn    : in    std_logic;
		gpmc_clk    : in    std_logic;
		
      -- Global Signals
      gls_reset : in std_logic;
      gls_clk   : in std_logic;
      -- Wishbone interface signals
      wbm_address    : out std_logic_vector(15 downto 0);  -- Address bus
      wbm_readdata   : in  std_logic_vector(15 downto 0);  -- Data bus for read access
      wbm_writedata  : out std_logic_vector(15 downto 0);  -- Data bus for write access
      wbm_strobe     : out std_logic;                      -- Data Strobe
      wbm_write      : out std_logic;                      -- Write access
      wbm_ack        : in std_logic ;                      -- acknowledge
      wbm_cycle      : out std_logic                       -- bus cycle in progress
    );
end component;

 
component spi_wishbone_wrapper is
generic(BIG_ENDIAN : boolean := true);
	port
	(
	-- SPI SIGNALS
	mosi, ss, sck : in std_logic;
	miso : out std_logic;

	-- Global Signals
	gls_reset : in std_logic;
	gls_clk   : in std_logic;
	-- Wishbone interface signals
	wbm_address    : out std_logic_vector(15 downto 0);  -- Address bus
	wbm_readdata   : in  std_logic_vector(15 downto 0);  -- Data bus for read access
	wbm_writedata  : out std_logic_vector(15 downto 0);  -- Data bus for write access
	wbm_strobe     : out std_logic;                      -- Data Strobe
	wbm_write      : out std_logic;                      -- Write access
	wbm_ack        : in std_logic ;                      -- acknowledge
	wbm_cycle      : out std_logic                       -- bus cycle in progress
	);
end component;

end logi_wishbone_pack;

package body logi_wishbone_pack is

end logi_wishbone_pack;
