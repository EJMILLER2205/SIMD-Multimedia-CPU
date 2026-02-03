----
--
-- File : idex_reg.vhd
-- Entity Name : idex_reg
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
-- Description : entity idex_reg is the pipeline register between the 
-- Instruction Decode stage and the Execute stage. It has inputs
-- idex_instr_in, idex_busS1_in, idex_busS2_in, idex_busS3_in, and clk 
-- along with outputs idex_instr_out, idex_busS1_out, idex_busS2_out,
-- and idex_busS3_out.
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;  

entity idex_reg is
	port(
	clk : in std_logic;
	idex_instr_in : in instr25;
	idex_busS1_in : in reg128;
	idex_busS2_in : in reg128;
	idex_busS3_in : in reg128;
	idex_instr_out : out instr25;
	idex_busS1_out : out reg128;
	idex_busS2_out : out reg128;
	idex_busS3_out : out reg128);
end idex_reg;

architecture behavioral_idex of idex_reg is

	signal idex_instr_buffer : instr25; 
	signal idex_rs1_buf, idex_rs2_buf, idex_rs3_buf, idex_rd_buf : reg_index_t;
	signal idex_busS1_buf, idex_busS2_buf, idex_busS3_buf : reg128;

begin
	idex : process (clk, idex_instr_in, idex_busS1_in, idex_busS2_in, idex_busS3_in)
	begin
		if rising_edge(clk) then
			idex_instr_out <= idex_instr_buffer;
			idex_busS1_out <= idex_busS1_buf;
			idex_busS2_out <= idex_busS2_buf;
			idex_busS3_out <= idex_busS3_buf;
		else
			idex_instr_buffer <= idex_instr_in;
			idex_busS1_buf <= idex_busS1_in;
			idex_busS2_buf <= idex_busS2_in;
			idex_busS3_buf <= idex_busS3_in;
		end if;
	end process;
end behavioral_idex;
