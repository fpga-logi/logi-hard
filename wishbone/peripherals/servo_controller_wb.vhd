

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
-- Create Date:    11:27:45 08/19/2013 
-- Design Name: 
-- Module Name:    servo_controller_wb - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity servo_controller_wb is
generic(NB_SERVOS : positive := 2;
			wb_size : natural := 16 ; -- Data port size for wishbone
			pos_width	:	integer := 8 ;
			clock_period             : integer := 10;
			minimum_high_pulse_width : integer := 1000000;
			maximum_high_pulse_width : integer := 2000000
		  );
port(
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
		  
		  servos : out std_logic_vector(NB_SERVOS-1 downto 0)
		  

);

end servo_controller_wb;

architecture Behavioral of servo_controller_wb is

component servo_controller is
  generic(
	 pos_width	:	integer := 8 ;
    clock_period             : integer := 10;
    minimum_high_pulse_width : integer := 1000000;
    maximum_high_pulse_width : integer := 2000000
    );
  port (clk            : in  std_logic;
        rst            : in  std_logic;
        servo_position : in  std_logic_vector (pos_width-1 downto 0);
        servo_out       : out std_logic);
end component;

constant reset_pulse : std_logic_vector(15 downto 0) := X"8080";
type reg16_array is array (0 to (NB_SERVOS-1)) of std_logic_vector(15 downto 0) ;

signal pos_regs : reg16_array := (others => reset_pulse);

signal read_ack : std_logic ;
signal write_ack : std_logic ;

begin


wbs_ack <= read_ack or write_ack;

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
wbs_readdata <= pos_regs(conv_integer(wbs_add)) ;

register_mngmt : process(gls_clk, gls_reset)
begin
    if gls_reset = '1' then
        pos_regs <= (others => reset_pulse) ;
    elsif rising_edge(gls_clk) then
        if ((wbs_strobe and wbs_write and wbs_cycle) = '1' ) then
            pos_regs(conv_integer(wbs_add)) <= wbs_writedata;
        end if ;
    end if;
end process register_mngmt;


gen_servo_ctrl : for i in 0 to (NB_SERVOS-1) generate
	servo_ctrl : servo_controller
	  generic map(
		 pos_width	=> 8,
		 clock_period  => clock_period,
		 minimum_high_pulse_width => minimum_high_pulse_width,
		 maximum_high_pulse_width => maximum_high_pulse_width
		 )
	  port map(clk => gls_clk,
			  rst => gls_reset,
			  servo_position => pos_regs(i)(pos_width-1 downto 0),
			  servo_out      => servos(i)
	  );
end generate ;

end Behavioral;

