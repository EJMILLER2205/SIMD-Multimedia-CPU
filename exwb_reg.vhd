----
--
-- File : exwb_reg.vhd
-- Entity Name : exwb_reg
-- Architecture : behavioral
-- Author : Eric Miller, Adam Roccanova
--
---------------------------------------------------------------------------
----
--
-- Generated : Sat Nov 29 2:24 2025
--
---------------------------------------------------------------------------
----
--
-- Description : entity exwb_reg is the pipeline register between the 
-- Execute stage and the Write Back stage. It has inputs exwb_rd_in, exwb_busD_in,
-- and clk along with outputs exwb_rd_out and exwb_busD_out.
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity exwb_reg is
	port(
	clk : in std_logic;
	exwb_rd_in : in reg_index_t;
	exwb_busD_in : in reg128;
	exwb_rd_out : out reg_index_t;
	exwb_busD_out : out reg128);
end exwb_reg; 

architecture behavioral_exwb of exwb_reg is

	signal exwb_rd_buf : reg_index_t; 
	signal exwb_busD_buf : reg128;

begin
	exwb : process (clk, exwb_rd_in, exwb_busD_in)
	begin
		if rising_edge(clk) then
			exwb_rd_out <= exwb_rd_buf;
			exwb_busD_out <= exwb_busD_buf;
		else
			exwb_rd_buf <= exwb_rd_in;
			exwb_busD_buf <= exwb_busD_in;
		end if;
	end process;
end behavioral_exwb;
