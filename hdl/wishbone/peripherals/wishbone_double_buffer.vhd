

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



----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:24:19 11/08/2013 
-- Design Name: 
-- Module Name:    double_buffer - Behavioral 
-- Project Name: 
-- Target Devices: Spartan 6 
-- Tool versions: ISE 14.1 
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

entity wishbone_double_buffer is
generic( wb_add_width: positive := 16; --! width of the address bus
			wb_data_width	: positive := 16; --! width of the data bus
			buffer_size	: positive	:= 4096 --! buffer size
			); 
port(
	-- Syscon signals
	gls_reset    : in std_logic ;
	gls_clk      : in std_logic ;
	-- Wishbone signals
	wbs_address       : in std_logic_vector(wb_add_width-1 downto 0) ;
	wbs_writedata : in std_logic_vector( wb_add_width-1 downto 0);
	wbs_readdata  : out std_logic_vector( wb_add_width-1 downto 0);
	wbs_strobe    : in std_logic ;
	wbs_cycle      : in std_logic ;
	wbs_write     : in std_logic ;
	wbs_ack       : out std_logic;
		  
	-- logic signals  
	write_buffer : in std_logic ;
	buffer_index : out std_logic ;
	buffer_full : out std_logic ;
	
	buffer_input : in std_logic_vector(15 downto 0)
	
);
end wishbone_double_buffer;

architecture Behavioral of wishbone_double_buffer is
component dpram_NxN is
	generic(SIZE : natural := 64 ; NBIT : natural := 8; ADDR_WIDTH : natural := 6);
	port(
 		clk : in std_logic; 
 		we : in std_logic; 
 		
 		di : in std_logic_vector(NBIT-1 downto 0 ); 
		a	:	in std_logic_vector((ADDR_WIDTH - 1) downto 0 );
 		dpra : in std_logic_vector((ADDR_WIDTH - 1) downto 0 );
		spo : out std_logic_vector(NBIT-1 downto 0 );
		dpo : out std_logic_vector(NBIT-1 downto 0 ) 		
	); 
end component;


signal buffer_write_index, buffer_read_index : std_logic ;
signal buffer_free_flag, buffer_overwrite_flag : std_logic;
signal read_register, write_register : std_logic_vector(15 downto 0);
signal buffer_read_data : std_logic_vector(15 downto 0);
signal read_address, write_address : std_logic_vector(12 downto 0);
signal reset_free_flag, reset_overwrite_flag, reset_buffer :std_logic ;

signal read_ack : std_logic ;
signal write_ack : std_logic ;

begin

wbs_ack <= read_ack or write_ack;

-- need to implement write to the status register somewhere
write_bloc : process(gls_clk,gls_reset)
begin
    if gls_reset = '1' then 
        write_ack <= '0';
    elsif rising_edge(gls_clk) then
        if ((wbs_strobe and wbs_write and wbs_cycle) = '1' ) then
            write_ack <= '1';
        else
            write_ack <= '0';
        end if;
    end if;
end process write_bloc;

-- need to implement read of the status register somewhere
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

					
buffer_read_index <= not buffer_write_index ;

wbs_readdata <= read_register when wbs_address(read_address'high) = '1' else
					 buffer_read_data ;

read_register(0) <= NOT buffer_free_flag ;
read_register(1) <= buffer_overwrite_flag ;
read_register(15 downto 2) <= (others => '0') ;

reset_free_flag <= write_register(0);
reset_overwrite_flag <= write_register(1);
reset_buffer <= write_register(2);

write_register <= wbs_writedata when (wbs_strobe and wbs_write and wbs_cycle) = '1' and wbs_address(read_address'high) = '1' else
						(others => '0');


ram0 : dpram_NxN 
	generic map(SIZE => (buffer_size*2),  NBIT => wb_data_width, ADDR_WIDTH=> 13) -- need to be computed
	port map(
 		clk => gls_clk,
 		we => write_buffer ,
 		di => buffer_input, 
		a	=> write_address ,
 		dpra => read_address,
		spo => open,
		dpo => buffer_read_data 		
	); 



-- highest bit select buffer to write to 
write_address(write_address'high) <= buffer_write_index ;
read_address(read_address'high) <=buffer_read_index ;
read_address(read_address'high-1 downto 0) <= wbs_address(read_address'high-1 downto 0);											 

process(gls_clk, gls_reset)
begin
	if gls_reset = '1' then	
		buffer_free_flag <= '1' ;
		buffer_overwrite_flag <= '0' ;
		write_address(write_address'high - 1 downto 0) <= (others => '0');
		buffer_write_index <= '0' ;
		buffer_full <= '0' ;
	elsif gls_clk'event and gls_clk = '1' then
		if reset_buffer = '1' then
			buffer_free_flag <= '1' ;
			buffer_overwrite_flag <= '0' ;
			write_address(write_address'high - 1 downto 0) <= (others => '0');
			buffer_write_index <= '0' ;
			buffer_full <= '0' ;
		elsif write_buffer = '1' then -- if write and one buffer at least is available
			write_address(write_address'high - 1 downto 0) <= write_address(write_address'high - 1 downto 0) + 1 ;
			if write_address(write_address'high - 1 downto 0) = (buffer_size-1) and buffer_free_flag = '1' then -- last address is just being written
				-- switching buffer
				buffer_write_index <= not buffer_write_index ;
				buffer_free_flag <= '0' ;
				buffer_full <= not buffer_free_flag ; -- if buffer is not free, buffer is full
			elsif write_address(write_address'high - 1 downto 0) = (buffer_size-1) and buffer_free_flag = '1' then
				buffer_overwrite_flag <= '1' ;
			end if ;
		end if ;
		
		if reset_free_flag = '1' then -- command from wishbone bus
				buffer_free_flag <= '1' ;
		end if ;
		
		if reset_overwrite_flag = '1' then -- command from wishbone bus
				buffer_overwrite_flag <= '0' ;
		end if ;
		
	end if ;
end process ;
	

end Behavioral;

