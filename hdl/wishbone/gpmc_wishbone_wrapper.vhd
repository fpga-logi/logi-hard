

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



library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

-- ----------------------------------------------------------------------------
    entity gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------
    generic(sync : boolean := true; burst : boolean := false );
	 port
    (
      -- GPMC SIGNALS
      gpmc_ad : inout   std_logic_vector(15 downto 0);
      gpmc_csn    : in    std_logic;
      gpmc_oen    : in    std_logic;
      gpmc_wen    : in    std_logic;
      gpmc_advn   : in    std_logic;
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
      wbm_ack        : in std_logic;                       -- acknowledge
      wbm_cycle      : out std_logic                       -- bus cycle in progress
    );
    end entity;

-- ----------------------------------------------------------------------------
Architecture RTL of gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------

signal write, writen      : std_logic;
signal read, readn      : std_logic;
signal cs, csn : std_logic ;
signal writedata, iob_writedata, writedata_bridge,iob_readdata, readdata_bridge  : std_logic_vector(15 downto 0);
signal address, address_bridge : std_logic_vector(15 downto 0);
signal burst_counter : std_logic_vector(16 downto 0);
signal wbm_readdata_bridge : std_logic_vector(15 downto 0); 
signal csn_bridge,wen_bridge, oen_bridge : std_logic;
signal gpmc_clk_old, gpmc_clk_re : std_logic;
signal bus_control_logic_side, bus_control_bus_side : std_logic ;
signal is_read, is_write, iob_dq_hiz : std_logic ;
attribute IOB: string;
attribute IOB of csn_bridge: signal is "true";
attribute IOB of wen_bridge: signal is "true";
attribute IOB of oen_bridge    : signal is "true";
attribute IOB of iob_readdata: signal is "true";
attribute IOB of iob_writedata: signal is "true";

--attribute IOB of address_bridge : signal is "true" ;
begin

gen_async : if sync = false generate
	process(gls_clk, gls_reset)
	begin
		if gls_reset = '1' then
			address <= (others => '0');
		elsif gls_clk'event and gls_clk = '1' then
			if gpmc_advn = '0' then
				address <= gpmc_ad;
			end if;
		end if;
	end process;

	process(gls_clk, gls_reset)
	begin
		if(gls_reset='1') then
			write   <= '0';
			cs  <= '0';
			read <= '0';
			writedata <= (others => '0');
		elsif(rising_edge(gls_clk)) then
			cs  <= (not gpmc_csn) and (gpmc_advn) ;--and (gpmc_wen XOR gpmc_oen);
			write   <= (not gpmc_wen);
			read   <= (not gpmc_oen);

			if gpmc_advn = '1' and gpmc_csn ='0' and gpmc_wen='0' then
				writedata <= gpmc_ad;
			end if;
		end if;
	end process;
	
	gpmc_ad <= wbm_readdata when (gpmc_csn = '0' and gpmc_oen = '0') else 
			 (others => 'Z');
			 
	wbm_address    <= address;
	wbm_writedata  <= writedata;
	wbm_strobe     <= cs and (write xor read);
	wbm_write      <= write;
	wbm_cycle      <= cs and (write xor read);
end generate ;

gen_syn : if sync = true generate

	gen_burst : if burst = true generate
		process(gpmc_clk, gls_reset)
		begin
			if(gls_reset='1') then
				address_bridge <= (others => '0');
			elsif(falling_edge(gpmc_clk)) then
				if gpmc_advn = '0' then
					address_bridge <= iob_writedata;
			 	elsif readn = '0' and burst_counter(16) = '0' then
					address_bridge <= address_bridge + 1;
			 	end if;
		  	end if;
		end process;
	end generate;
	
	
		process(gpmc_clk, gls_reset)
		begin
			if(gls_reset='1') then
				burst_counter <= (others => '0');
			elsif(falling_edge(gpmc_clk)) then
				if gpmc_csn = '1' then
					burst_counter <= '0' & X"0001";
			 	elsif readn = '0' and burst_counter(16) = '0' then
					burst_counter <= burst_counter(15 downto 0) & '0'; -- burst access should be a maximum of 16 accesses
			 	end if;
		  	end if;
		end process;
	
	gen_no_burst : if burst = false generate
		process(gpmc_clk, gls_reset)
		begin
			if(gls_reset='1') then
				address_bridge <= (others => '0');
		  	elsif(falling_edge(gpmc_clk)) then
				if gpmc_advn = '0' then
					address_bridge <= iob_writedata;
				end if;
		  	end if;
		end process;
	end generate;

	process(gpmc_clk, gls_reset)
	begin
		if(gls_reset='1') then
			csn_bridge <= '1';
			wen_bridge   <= '1';
			oen_bridge <= '1';
			iob_readdata <= (others => '0');
			writedata_bridge <= (others => '0');
		elsif(falling_edge(gpmc_clk)) then
			csn_bridge  <= gpmc_csn;
			wen_bridge   <= gpmc_wen;
			oen_bridge   <= gpmc_oen;
			iob_readdata <= readdata_bridge;
			writedata_bridge <= iob_writedata;
			iob_dq_hiz <= gpmc_oen;
		end if;
	end process;
	

	process(gls_clk, gls_reset)
	begin
		if(gls_reset='1') then
			csn <= '1';
			writen   <= '1';
			readn <= '1';
			writedata <= (others => '0');
			address <= (others => '0');
			is_read <= '0' ;
			is_write <= '0' ;
		elsif(rising_edge(gls_clk)) then
--			if csn_bridge = '0' and readn = '0' and writen = '1' then
--				is_read <= '1' ;
--			elsif is_read = '1' and readn = '1' and csn_bridge = '1' then
--				is_read <= '0' ;
--			end if ;
--			
--			if csn_bridge = '0' and readn = '1' and writen = '0' then
--				is_write <= '1' ;
--			elsif is_write = '1' and writen = '1' and csn_bridge = '1' then
--				is_write <= '0' ;
--			end if ;
			
			csn  <= csn_bridge;
			writen   <= wen_bridge;
			readn   <= oen_bridge;
			writedata <= writedata_bridge;
			if wbm_ack = '1' then
				readdata_bridge <= wbm_readdata;
			else
				readdata_bridge <= x"0000";
			end if;
			address <= address_bridge;
		end if ;
	end process;

	iob_dq_g: for i in 0 to 15 generate
		begin
		iob_dq_iob: IOBUF
		generic map (DRIVE => 12, IOSTANDARD => "LVTTL", SLEW => "FAST")
		port map ( O  => iob_writedata(i), IO => gpmc_ad(i), I  => iob_readdata(i), T  => oen_bridge);
	end generate;
	
--	gpmc_ad <= --readdata when ((not gpmc_oen) and (not gpmc_csn) and gpmc_advn) = '1' else
--				  readdata when bus_control_logic_side = '1' else
--				(others => 'Z');

	wbm_address <= address;
	wbm_writedata  <= writedata;
	
	wbm_strobe     <= (not csn) and (writen xor readn );
	wbm_write      <= (not writen);
	wbm_cycle      <= (not csn) and (writen xor readn );
--	wbm_strobe <= is_read xor is_write ;
--	wbm_write <= is_write ;
--	wbm_cycle <= is_read xor is_write ;
	
end generate;


end architecture RTL;
