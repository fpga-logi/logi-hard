----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:51:59 05/12/2014 
-- Design Name: 
-- Module Name:    encoder_interface - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity encoder_interface is
generic(FREQ_DIV : positive := 100);
port(
	clk, reset : in std_logic ;
	channel_a, channel_b : in std_logic;
	
	period : out std_logic_vector(15 downto 0);
	pv : out std_logic ;
	
	count : out std_logic_vector(15 downto 0);
	reset_count : in std_logic 

);
end encoder_interface;

architecture Behavioral of encoder_interface is
type enc_states is (IDLE, A_H, B_H, A_L, B_L);
signal cur_state, next_state : enc_states ;


signal period_counter, period_latched, pulse_counter : std_logic_vector(15 downto 0);
signal divider_counter : std_logic_vector(15 downto 0);
signal end_div : std_logic ;

signal inc_counter, dec_counter, valid_cw, valid_ccw, latch_period : std_logic ;
begin

process(clk, reset)
begin
	if reset = '1' then
		cur_state <= IDLE ;
	elsif clk'event and clk='1' then
		cur_state <= next_state ;
	end if ;
end process ;

process(cur_state, channel_a, channel_b)
begin
	next_state <= cur_state ;
	case cur_state is
		when IDLE =>
			if channel_a = '1' and channel_b='0' then
				next_state <= A_H ;
			end if ;
			if channel_b = '1' and channel_a='0' then
				next_state <= A_L ;
			end if ;
		when A_H =>
			if channel_a = '1' and channel_b = '1' then
				next_state <= B_H ;
			end if ;
			if channel_a = '0' and channel_b = '0' then
				next_state <= IDLE ;
			end if ;
		when B_H =>
			if channel_a = '0' and channel_b = '1' then
				next_state <= A_L ;
			end if ;
			if channel_b = '0' and channel_a = '1' then
				next_state <= A_H ;
			end if ;
		when A_L =>
			if channel_a = '0' and channel_b = '0' then
				next_state <= IDLE ;
			end if ;
			if channel_a = '1' and channel_b = '1' then
				next_state <= B_H ;
			end if ;
		when others => next_state <= IDLE ;
	end case ;
end process ;


inc_counter <= '1' when cur_state = IDLE and channel_a = '1' else
					'0' ;
					
dec_counter <= '1' when cur_state = A_H and channel_a = '0' else
					'0' ;
					
					
latch_period <= '1' when cur_state = IDLE and channel_a = '1' else
					  '1' when cur_state = IDLE and channel_b = '1' else
					  '0' ;				


process(clk, reset)
begin
	if reset = '1' then
		valid_cw <= '0' ;
		valid_ccw <= '0' ;
	elsif clk'event and clk='1' then
		
		if cur_state = IDLE and channel_a='1' then
			valid_cw <= '1' ;
		elsif cur_state = A_H and channel_a='0' then
			valid_cw <= '0' ;
		elsif cur_state = B_H and channel_b='0' then
			valid_cw <= '0' ;
		elsif cur_state = A_L and channel_a='1' then
			valid_cw <= '0' ;
		elsif cur_state = IDLE and channel_b='1' then
			valid_cw <= '0' ;
		end if ;
		
		if cur_state = IDLE and channel_b='1' then
			valid_ccw <= '1' ;
		elsif cur_state = A_L and channel_b='0' then
			valid_ccw <= '0' ;
		elsif cur_state = B_H and channel_a='0' then
			valid_ccw <= '0' ;
		elsif cur_state = A_H and channel_b='1' then
			valid_ccw <= '0' ;
		elsif cur_state = IDLE and channel_a='1' then
			valid_ccw <= '0' ;
		end if ;
		
	end if ;
end process ;


process(clk, reset)
begin
	if reset = '1' then
		divider_counter <= (others => '0') ;
	elsif clk'event and clk='1' then
		if end_div = '1' then
			divider_counter <= std_logic_vector(to_unsigned(FREQ_DIV-1, 16)) ;
		else
			divider_counter <= divider_counter - 1 ;
		end if ;
	end if ;
end process ;

end_div <= '1' when divider_counter = 0 else
			  '0' ;
			  

process(clk, reset)
begin
	if reset = '1' then
		period_counter <= (others => '0') ;
	elsif clk'event and clk='1' then
		if latch_period = '1' then
			period_counter <= (others => '0') ;
		elsif end_div = '1' then
			period_counter <= period_counter + 1 ;
		end if ;
	end if ;
end process ;			  
			  
process(clk, reset)
begin
	if reset = '1' then
		period_latched <= (others => '0') ;
		pv <= '0' ;
	elsif clk'event and clk='1' then
		if latch_period = '1' and ((valid_ccw = '1' and channel_b='1') or (valid_cw = '1' and channel_a='1') ) then
			if valid_ccw = '0' and valid_cw = '1' then
				period_latched <= period_counter ;
			else
				period_latched <= (NOT period_counter) + 1 ;
			end if;
			pv <= '1' ;
		else
			pv <= '0' ;
		end if ;
	end if ;
end process ;	

process(clk, reset)
begin
	if reset = '1' then
		pulse_counter <= (others => '0') ;
	elsif clk'event and clk='1' then
		if reset_count = '1' then
			pulse_counter <= (others => '0') ;
		elsif inc_counter = '1' then
			pulse_counter <= pulse_counter + 1 ;
		elsif dec_counter = '1' then
			pulse_counter <= pulse_counter - 1 ;
		end if ;
	end if ;
end process ;			  

period <= period_latched ;
count <= pulse_counter ;
end Behavioral;

