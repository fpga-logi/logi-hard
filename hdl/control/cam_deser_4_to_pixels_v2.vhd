----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:09:09 12/17/2014 
-- Design Name: 
-- Module Name:    cam_deser_4_to_pixels - Behavioral 
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

entity cam_deser_4_to_pixels_v2 is
generic(INVERT_DATA : boolean := true);
port(
	deser_clk, sys_clk : in std_logic ;
	sys_reset : in std_logic ;
	data_in_deser : in std_logic_vector(3 downto 0);
	
	
	raw_deser : out std_logic_vector(9 downto 0);
	
	pixel_out_clk, pixel_out_hsync, pixel_out_vsync : out std_logic ;
	pixel_out_data : out std_logic_vector(7 downto 0);
	synced_out : out std_logic 
);
end cam_deser_4_to_pixels_v2;

architecture Behavioral of cam_deser_4_to_pixels_v2 is
type synced_states is (WAIT_SYNC, ACC) ;
type array_3 is array(0 to 2) of std_logic_vector(9 downto 0);

signal current_state, next_state : synced_states ;
signal data_acc : array_3 ;

signal data_shift_register : std_logic_vector(15 downto 0);
signal sync_phase, sync_mask, old_phase : std_logic_vector(3 downto 0);
signal shift_counter : std_logic_vector(2 downto 0);
signal en_shift, reset_shift : std_logic ;

signal pixel_valid, pixel_valid_long, frame_valid, line_valid : std_logic ;
signal pixel_data : std_logic_vector(7 downto 0);

signal pixel_out_clk_deser_clk, pixel_out_hsync_deser_clk, pixel_out_vsync_deser_clk : std_logic ;
signal pixel_out_data_deser_clk : std_logic_vector(7 downto 0);

signal pixel_out_clk_sync1, pixel_out_hsync_sync1, pixel_out_vsync_sync1 : std_logic ;
signal pixel_out_data_sync1 : std_logic_vector(7 downto 0);

signal raw_deser_data, raw_deser_deser_clk, raw_deser_sync1 : std_logic_vector(9 downto 0) ;
signal sync_pattern : std_logic ;

signal in_sync_0, in_sync_1 : std_logic ;
begin


with_invert : if INVERT_DATA generate
process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		data_shift_register <= (others => '0') ;
	elsif deser_clk'event and deser_clk = '1' then
		data_shift_register(data_shift_register'high-4 downto 0) <=  data_shift_register(15 downto 4) ;
		data_shift_register(data_shift_register'high downto data_shift_register'high-3) <= not data_in_deser ;
	end if ;
end process ;
end generate ;

without_invert : if not INVERT_DATA generate
process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		data_shift_register <= (others => '0') ;
	elsif deser_clk'event and deser_clk = '1' then
		data_shift_register(data_shift_register'high-4 downto 0) <=  data_shift_register(15 downto 4) ;
		data_shift_register(data_shift_register'high downto data_shift_register'high-3) <= data_in_deser ;
	end if ;
end process ;
end generate ;


gen_detect_start_stop : for i in 0 to 3 generate
	sync_phase(i) <= '1' when data_shift_register(i) = '1' and data_shift_register(i+11) = '0' else
						  '0' ;
end generate ;	

process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		shift_counter(0) <= '1' ;
		shift_counter(shift_counter'high downto 1) <= (others => '0') ;
	elsif deser_clk'event and deser_clk = '1' then
		if reset_shift = '1' then
			shift_counter(0) <= '1' ;
			shift_counter(shift_counter'high downto 1) <= (others => '0') ;
		elsif en_shift = '1' then
			shift_counter(0) <= shift_counter(shift_counter'high) ;
			shift_counter(shift_counter'high downto 1) <= shift_counter(shift_counter'high-1 downto 0) ;
		end if ;
	end if ;
end process ;
		
sync_mask <= old_phase when (sync_phase and old_phase) /= 0 else
				 "0001" when sync_phase(0) = '1' else
				 "0010" when sync_phase(1) = '1' else
				 "0100" when sync_phase(2) = '1' else
				 "1000" when sync_phase(3) = '1' else
				 "0000" ;
		
process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		old_phase <= (others => '0') ;
	elsif deser_clk'event and deser_clk = '1' then
		if current_state = WAIT_SYNC and next_state = ACC then
			old_phase <= sync_mask ;
		end if ;
	end if ;
end process ;		
		
en_shift <= '1' when current_state = WAIT_SYNC and sync_phase /=0 else
				'1' when current_state = ACC else
				'0' ;
reset_shift <= '1' when current_state = WAIT_SYNC and sync_phase = 0 else
					'0' ;

process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		current_state <= WAIT_SYNC ;
	elsif deser_clk'event and deser_clk = '1' then
		current_state <= next_state ;
	end if ;
end process ;			

process(current_state, shift_counter, sync_phase)
begin
	next_state <= current_state ;
	case  current_state is
		when WAIT_SYNC =>
			if sync_phase /= 0 then
				next_state <= ACC ;
			end if ;
		when ACC =>
			if shift_counter(2) = '1' then
				next_state <= WAIT_SYNC ;
			end if ;
		when others => 
			next_state <= WAIT_SYNC ;
	end case ;
end process ;		

pixel_valid <= '1' when current_state = WAIT_SYNC and  sync_phase /= 0 else
					'0' ;
					
pixel_valid_long <= '1' when current_state = WAIT_SYNC and  sync_phase /= 0 else
						  '1' when current_state = ACC and  shift_counter(1)='1' else
						  '0' ;					
					


with sync_mask select
	line_valid <= data_shift_register(9) when "0001",
					  data_shift_register(10) when "0010",
					  data_shift_register(11) when "0100",
					  data_shift_register(12) when "1000",
					  '0' when others ;
with sync_mask select
	frame_valid <= data_shift_register(10) when "0001",
						data_shift_register(11) when "0010",
						data_shift_register(12) when "0100",
						data_shift_register(13) when "1000",
						'0' when others ;	

with sync_mask select
	pixel_data <= data_shift_register(8 downto 1) when "0001",
					  data_shift_register(9 downto 2) when "0010",
					  data_shift_register(10 downto 3) when "0100",
					  data_shift_register(11 downto 4) when "1000",
					  (others => '0') when others ;					  
					  
with sync_mask select
	raw_deser_data <= data_shift_register(10 downto 1) when "0001",
					  data_shift_register(11 downto 2) when "0010",
					  data_shift_register(12 downto 3) when "0100",
					  data_shift_register(13 downto 4) when "1000",
					  (others => '0') when others ;	

process(deser_clk, sys_reset)
begin
	if sys_reset = '1' then
		pixel_out_hsync_deser_clk <= '1' ;
		pixel_out_vsync_deser_clk <= '1' ;
		pixel_out_clk_deser_clk <= '0' ;
		pixel_out_data_deser_clk <= (others => '0');
		raw_deser_deser_clk <= (others => '0');
		data_acc <= (others => (others => '0'));
	elsif deser_clk'event and deser_clk = '1' then
		pixel_out_clk_deser_clk <= pixel_valid_long ;
		if pixel_valid = '1' then
			data_acc(0) <= raw_deser_data ;
			data_acc(1 to 2) <= data_acc(0 to 1); 
			raw_deser_deser_clk <= raw_deser_data ;
			pixel_out_hsync_deser_clk <= not line_valid ;
			pixel_out_vsync_deser_clk <= not frame_valid ;
			pixel_out_data_deser_clk <= pixel_data ;
		end if ;
	end if ;
end process ;	



process(sys_clk, sys_reset)
begin
	if sys_reset = '1' then
		pixel_out_hsync <= '1' ;
		pixel_out_vsync <= '1' ;
		pixel_out_clk <= '0' ;
		pixel_out_data <= (others => '0');
		pixel_out_hsync_sync1 <= '1' ;
		pixel_out_vsync_sync1 <= '1' ;
		pixel_out_clk_sync1 <= '0' ;
		pixel_out_data_sync1 <= (others => '0');
		raw_deser_sync1 <= (others => '0');
		raw_deser <= (others => '0');
		in_sync_1 <= '0';
		synced_out <= '0' ;
	elsif sys_clk'event and sys_clk = '1' then
		--synced_out <= sync_pattern ;
		in_sync_1 <= in_sync_0 ;
		synced_out <= in_sync_1 ;
		raw_deser_sync1 <= raw_deser_deser_clk ;
		raw_deser <= raw_deser_sync1 ;
		pixel_out_clk_sync1 <= pixel_out_clk_deser_clk ;
		pixel_out_hsync_sync1 <= pixel_out_hsync_deser_clk ;
		pixel_out_vsync_sync1 <= pixel_out_vsync_deser_clk;
		pixel_out_data_sync1 <= pixel_out_data_deser_clk ;
		pixel_out_clk <= pixel_out_clk_sync1 ;
		pixel_out_hsync <= pixel_out_hsync_sync1 ;
		pixel_out_vsync <= pixel_out_vsync_sync1 ;
		pixel_out_data <= pixel_out_data_sync1 ;		
	end if ;
end process ;	
in_sync_0 <= '1' when current_state = ACC else
				  '1' when current_state = WAIT_SYNC and (sync_phase and old_phase) /= 0 else
				  '0' ;
sync_pattern <= '1' when data_acc(0) = "1111111111" and data_acc(1) = "0000000000" and data_acc(2) = "1111111111" else
				  '0' ;

end Behavioral;

