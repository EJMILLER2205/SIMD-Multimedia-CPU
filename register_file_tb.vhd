----
--
-- File : register_file_tb.vhd
-- Entity Name : register_file_tb
-- Architecture : behavioral
-- Author : Eric Miller, Adam Roccanova
--
---------------------------------------------------------------------------
----
--
-- Generated : Wed Nov 26 5:18 2025
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
use work.all;

entity register_file_tb is
end entity;

architecture tb of register_file_tb is

signal write_en : std_logic;
signal rd, rs1, rs2, rs3 : bit_vector(4 downto 0);
signal busD, busS1, busS2, busS3 : bit_vector (127 downto 0);

begin
	uut: entity register_file port map (
		write_en => write_en,
		rd => rd,
		rs1 => rs1,
		rs2 => rs2,
		rs3 => rs3,
		busD => busD,
		busS1 => busS1,
		busS2 => busS2,
		busS3 => busS3);
	tb : process		
	constant period: time := 10 ns;
	
	begin
		
		--write to register 6
		report "Test to write to register 6" severity note;
		write_en <= '1';
		rd <= "00110";
		busD <= x"00010002000300040005000600070008";
		wait for period;
		--write to register 11 
		report "Test to write to register 11" severity note;
		write_en <= '1';
		rd <= "01011";
		busD <= x"91A516D14EF89171614565224651ADEC";  
		wait for period;
		--write to register 23		
		report "Test to write to register 23" severity note;
		write_en <= '1';
		rd <= "10111";
		busD <= x"1FAB518BDF565484E40CAF547541EB54";
		wait for period;
		--read from registers 6, 11, and 23 and write to register 15
		report "Test to write to read 6, 11, and 23 and write to 15" severity note;
		write_en <= '1';
		rd <= "01111";		   
		rs1 <= "00110";
		rs2 <= "01011";
		rs3 <= "10111";
		busD <= x"6516516519844594A54B874871CFED47";
		wait for period;
		assert busS1 = x"00010002000300040005000600070008" report "Read from 6 failed" severity failure;
		assert busS2 = x"91A516D14EF89171614565224651ADEC" report "Read from 11 failed" severity failure; 
		assert busS3 = x"1FAB518BDF565484E40CAF547541EB54" report "Read from 23 failed" severity failure;
		--read from registers 6 and 15 with write disabled	  
		report "Test to write to read 6, 11, and 23 and write to 15" severity note;
		write_en <= '0';
		rd <= "00110";		   
		rs1 <= "00110";
		rs2 <= "01111";	
		rs3 <= "10111";
		busD <= x"6516516519844594A54B874871CFED47";
		wait for period;				 
		assert busS1 = x"00010002000300040005000600070008" report "Read from 6 failed" severity failure;
		assert busS2 = x"6516516519844594A54B874871CFED47" report "Read from 15 failed" severity failure; 
		assert busS3 = x"1FAB518BDF565484E40CAF547541EB54" report "Read from 23 failed" severity failure;
		
		report "ALL THE TESTS PASSED" severity note;

		wait;
	end process;
end architecture tb;
