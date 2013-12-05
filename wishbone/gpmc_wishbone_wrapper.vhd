library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

-- ----------------------------------------------------------------------------
    entity gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------
    generic(sync : boolean := false; burst : boolean := false );
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
signal writedata, writedata_bridge,readdata, readdata_bridge  : std_logic_vector(15 downto 0);
signal address, address_bridge : std_logic_vector(15 downto 0);
signal wbm_readdata_bridge : std_logic_vector(15 downto 0); 
signal csn_bridge,wen_bridge, oen_bridge, advn_bridge : std_logic;
signal gpmc_clk_old, gpmc_clk_re : std_logic;
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
					address_bridge <= gpmc_ad;
			 	elsif readn = '0' then
					address_bridge <= address_bridge + 1;
			 	end if;
		  	end if;
		end process;
	end generate;
	
	gen_no_burst : if burst = false generate
		process(gpmc_clk, gls_reset)
		begin
			if(gls_reset='1') then
				address_bridge <= (others => '0');
		  	elsif(falling_edge(gpmc_clk)) then
				if gpmc_advn = '0' then
					address_bridge <= gpmc_ad;
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
			readdata <= (others => '0');
			writedata_bridge <= (others => '0');
			advn_bridge <= '1';
		elsif(falling_edge(gpmc_clk)) then
			csn_bridge  <= gpmc_csn;
			wen_bridge   <= gpmc_wen;
			oen_bridge   <= gpmc_oen;
			advn_bridge <= gpmc_advn;
			readdata <= readdata_bridge;
			writedata_bridge <= gpmc_ad;
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
		elsif(rising_edge(gls_clk)) then
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
		end if;
	end process;

	gpmc_ad <= readdata when (gpmc_csn = '0' and gpmc_oen = '0') else
		(others => 'Z');

	wbm_address <= address;
	wbm_writedata  <= writedata;
	wbm_strobe     <= (not csn) and (writen xor readn );
	wbm_write      <= (not writen);
	wbm_cycle      <= (not csn) and (writen xor readn );
end generate;


end architecture RTL;
