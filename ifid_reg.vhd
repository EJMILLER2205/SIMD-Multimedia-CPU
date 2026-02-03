----
--
-- File : ifid_reg.vhd
-- Entity Name : ifid_reg
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
-- Description : entity ifid_reg is the pipeline register between the 
-- Instruction Fetch stage and the Instruction Decode stage. It has inputs
-- ifid_instr_in and clk along with output ifid_instr_out.
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all; 


entity ifid_reg is
	port(
	clk : in std_logic;
	ifid_instr_in : in instr25;
	ifid_instr_out : out instr25);
end ifid_reg; 

architecture behavioral_ifid of ifid_reg is

	signal ifid_instr_buffer : instr25; 

begin
	ifid : process (clk, ifid_instr_in)
	begin
		if rising_edge(clk) then
			ifid_instr_out <= ifid_instr_buffer;
		else
			ifid_instr_buffer <= ifid_instr_in;
		end if;
	end process;
end behavioral_ifid;
