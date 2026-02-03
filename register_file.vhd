----
--
-- File : register_file.vhd
-- Entity Name : register_file
-- Architecture : behavioral
-- Author : Eric Miller, Adam Roccanova
--
---------------------------------------------------------------------------
----
--
-- Generated : Thu Nov 6 11:51 2025
--
---------------------------------------------------------------------------
----
--
-- Description : entity register_file is a register file that holds 32 128-bit
-- registers with inputs write_en rd, rs1, rs2, rs3, and busD along with 
-- outputs busS1, busS2, and busS3
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity register_file is
	port (
	write_en : in std_logic;  		         --write enable signal
	rd  : in bit_vector(4 downto 0);		 --select the register to be written
	rs1 : in bit_vector(4 downto 0);		 --select the register to be put onto busA
	rs2 : in bit_vector(4 downto 0);		 --select the register to be put onto busB
	rs3 : in bit_vector(4 downto 0); 		 --select the register to be put onto busC
	busD : in bit_vector(127 downto 0);	     --bus with data to be written to rd
	busS1 : out bit_vector(127 downto 0);	 --bus with data to be read from rs1
	busS2 : out bit_vector(127 downto 0);    --bus with data to be read from rs2
	busS3 : out bit_vector(127 downto 0));   --bus with data to be read from rs3
end register_file;

architecture behavioral of register_file is		

	function bits_to_natural (bits : in bit_vector) return natural is 
		variable result : natural := 0;		  
	begin
		for i in bits'range loop
			result := result * 2 + bit'pos(bits(i));
		end loop;
		return result;
	end bits_to_natural;

begin
	reg_file : process (write_en, rd, rs1, rs2, rs3, busD)  	
		subtype reg_addr is natural range 0 to 31;					  --5-bit register address
		type reg_arr is array (reg_addr) of bit_vector(127 downto 0); --array holding 32 128-bit registers
		variable reg : reg_arr;										  --selected register within the register array
		
	begin
		if write_en = '1' then					  
			reg(bits_to_natural(rd)) := busD;						  --selected register within the register file receives data from write bus
		end if;														  --on a positive clock edge
		
		busS1 <= reg(bits_to_natural(rs1));							  --read data bus S1 asynchronously receives data from regsiter selected by rs1
		busS2 <= reg(bits_to_natural(rs2));							  --read data bus S2 asynchronously receives data from regsiter selected by rs2
		busS3 <= reg(bits_to_natural(rs3)); 						  --read data bus S3 asynchronously receives data from regsiter selected by rs3
		
	end process reg_file;
end behavioral;
										   
