library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

-- ----------------------------------------------------------------------------
    entity gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------
    port
    (
      -- GPMC SIGNALS
      gpmc_ad : inout   std_logic_vector(15 downto 0);
      gpmc_csn    : in    std_logic;
      gpmc_oen    : in    std_logic;
		gpmc_wen    : in    std_logic;
		gpmc_advn    : in    std_logic;
		
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
    end entity;

-- ----------------------------------------------------------------------------
Architecture RTL of gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------

signal write      : std_logic;
signal read      : std_logic;
signal cs : std_logic ;
signal strobe     : std_logic;
signal writedata  : std_logic_vector(15 downto 0);
signal address    : std_logic_vector(15 downto 0);
signal latch_addr : std_logic ;
begin

latch_addr <= '1' when gpmc_advn = '0' else
				  '0' ;

process(gls_clk, gls_reset)
begin
	if gls_reset = '1' then
		address <= (others => '0');
	elsif gls_clk'event and gls_clk = '1' then
		if latch_addr = '1' then
			address <= gpmc_ad;
		end if ;
	end if ;
end process ;

process(gls_clk, gls_reset)
begin
  if(gls_reset='1') then
    write   <= '0';
    strobe  <= '0';
	 read <= '0' ;
    writedata <= (others => '0');
  elsif(rising_edge(gls_clk)) then
    cs  <= (not gpmc_csn) and (not latch_addr);
    write   <= (not gpmc_csn) and (not gpmc_wen) and (not latch_addr);
	 read   <= (not gpmc_csn) and (not gpmc_oen) and (not latch_addr);
    if latch_addr = '0' and gpmc_csn ='0' and gpmc_wen='0' then
		writedata <= gpmc_ad;
	 end if ;
  end if;
end process;

wbm_address    <= address ; 
wbm_writedata  <= writedata ;
wbm_strobe     <= cs and (write or read);
wbm_write      <= write;
wbm_cycle      <= cs and (write or read);

gpmc_ad <= wbm_readdata when (gpmc_csn = '0' and gpmc_oen = '0') else 
			 (others => 'Z');

end architecture RTL;