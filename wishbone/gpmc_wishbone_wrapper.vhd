library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

-- ----------------------------------------------------------------------------
    entity gpmc_wishbone_wrapper is
-- ----------------------------------------------------------------------------
    port
    (
      -- GPMC SIGNALS
      gpmc_ad : in    std_logic_vector(11 downto 0); -- LSB not used 
      gpmc_csn    : in    std_logic;
      gpmc_oen    : in    std_logic;
		gpmc_wrn    : in    std_logic;
		gpmc_advn    : in    std_logic;
      imx_eb3_n   : in    std_logic;
		
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
signal read       : std_logic;
signal strobe     : std_logic;
signal writedata  : std_logic_vector(15 downto 0);
signal address    : std_logic_vector(15 downto 0);

begin

process(gls_clk, gls_reset)
begin
	if gls_reset = '1' then
		address <= (others => '0');
	elsif gls_clk'event and gls_clk = '1' then
		if gpmc_advn = '0' then
			address <= gpmc_ad;
		end if ;
	end if ;
end process ;

process(gls_clk, gls_reset)
begin
  if(gls_reset='1') then
    write   <= '0';
    read    <= '0';
    strobe  <= '0';
    writedata <= (others => '0');
  elsif(rising_edge(gls_clk)) then
    strobe  <= not (gpmc_csn) and not(gpmc_oen and gpmc_wrn);
    write   <= not (gpmc_csn or imx_wrn or latch_addr);
    read    <= not (gpmc_csn or gpmc_oen or latch_addr);
    if gpmc_advn = '1' then
		writedata <= gpmc_ad;
	 end if ;
  end if;
end process;

wbm_address    <= address when (strobe = '1') else (others => '0');
wbm_writedata  <= writedata when (write = '1') else (others => '0');
wbm_strobe     <= strobe;
wbm_write      <= write;
wbm_cycle      <= strobe;

gpmc_ad <= wbm_readdata when(read = '1' ) else 
			 (others => 'Z');

end architecture RTL;