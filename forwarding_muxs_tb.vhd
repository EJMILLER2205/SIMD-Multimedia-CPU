----
--
-- File : forwarding_muxs_tb.vhd
-- Entity Name : forwarding_muxs_tb
-- Architecture : behavioral
-- Author : Eric Miller, Adam Roccanova
--
---------------------------------------------------------------------------
----
--
-- Generated : Thu Nov 27 12:03 2025
--
---------------------------------------------------------------------------
----
--
-- Description : entity forwarding_muxs_tb verfies the functionality of
-- the entity forwarding_muxs using 12 self-checking test cases that test
-- every type of input combination of rs1, rs2, rs3, and rd
--																							   
---------------------------------------------------------------------------	  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all; 

entity forwarding_muxs_tb is
end entity;

architecture tb of forwarding_muxs_tb is   
	--input signals
	signal ctrl_signal : std_logic_vector(1 downto 0);--control signal
	signal rd  : bit_vector(4 downto 0);			 --the register to be written
	signal rs1 : bit_vector(4 downto 0);			 --the register on busS1
	signal rs2 : bit_vector(4 downto 0);			 --the register on busS2
	signal rs3 : bit_vector(4 downto 0); 			 --the register on busS3
	signal busD : bit_vector(127 downto 0);	     	 --bus with data to be written to rd
	signal busS1_in : bit_vector(127 downto 0);	 	 --input bus with data from rs1
	signal busS2_in : bit_vector(127 downto 0);      --input bus with data from rs2
	signal busS3_in : bit_vector(127 downto 0);  	 --input bus with data from rs3	 
	--output signals
	signal busS1_out : bit_vector(127 downto 0);	 --output bus with data from rs1
	signal busS2_out : bit_vector(127 downto 0);     --output bus with data from rs2
	signal busS3_out : bit_vector(127 downto 0);	 --output bus with data from rs3   
	
	begin
		uut: entity forwarding_muxs port map(
			ctrl_signal => ctrl_signal,
			rd => rd,
			rs1 => rs1,
			rs2 => rs2,
			rs3 => rs3,	
			busD => busD,
			busS1_in => busS1_in,
			busS2_in => busS2_in,
			busS3_in => busS3_in,
			busS1_out => busS1_out,
			busS2_out => busS2_out,
			busS3_out => busS3_out);
		tb: process
		constant period: time := 10 ns;
		
		begin
			ctrl_signal <= "10";
			--Case: rs1, rs2, and rs3 are equal and equal to rd	
			report "Test 1: rs1, rs2, and rs3 are equal and equal to rd" severity note;
			rd <= "00110";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00110";
			rs3 <= "00110";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"91A516D14EF89171614565224651ADEC";
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 1 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 1 failed for busS2" severity failure;
			assert busS3_out = x"00010002000300040005000600070008" report "Test 1 failed for busS3" severity failure; 
				
			--Case: rs1, rs2, and rs3 are equal but not equal to rd
			report "Test 2: rs1, rs2, and rs3 are equal but not equal to rd" severity note;
			rd <= "00111";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00110";
			rs3 <= "00110";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"91A516D14EF89171614565224651ADEC" report "Test 2 failed for busS1" severity failure;
			assert busS2_out = x"91A516D14EF89171614565224651ADEC" report "Test 2 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 2 failed for busS3" severity failure;
				
			--Case: rs1 = rs2 and equal to rd 
			report "Test 3: rs1 = rs2 and equal to rd" severity note;
			rd <= "00110";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00110";
			rs3 <= "00101";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA"; 
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 3 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 3 failed for busS2" severity failure;
			assert busS3_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 3 failed for busS3" severity failure;
				
			--Case: rs1 = rs2 but not equal to rd
			report "Test 4: rs1 = rs2 but not equal to rd" severity note;
			rd <= "00111";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00110";
			rs3 <= "00101";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA"; 
			wait for period;
			assert busS1_out = x"91A516D14EF89171614565224651ADEC" report "Test 4 failed for busS1" severity failure;
			assert busS2_out = x"91A516D14EF89171614565224651ADEC" report "Test 4 failed for busS2" severity failure;
			assert busS3_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 4 failed for busS3" severity failure; 
				
			--Case: rs2 = rs3 and equal to rd  
			report "Test 5: rs2 = rs3 and equal to rd" severity note;
			rd <= "00101";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00101";
			rs3 <= "00101";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 5 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 5 failed for busS2" severity failure;
			assert busS3_out = x"00010002000300040005000600070008" report "Test 5 failed for busS3" severity failure;   
				
			--Case: rs2 = rs3 but not equal to rd
			report "Test 5: rs2 = rs3 and equal to rd" severity note;
			rd <= "00111";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00110";
			rs2 <= "00101";
			rs3 <= "00101";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 6 failed for busS1" severity failure;
			assert busS2_out = x"91A516D14EF89171614565224651ADEC" report "Test 6 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 6 failed for busS3" severity failure;
				
			--Case: rs1 = rs3 and equal to rd	
			report "Test 7: rs1 = rs3 and equal to rd" severity note;
			rd <= "00101";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00101";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 7 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 7 failed for busS2" severity failure;
			assert busS3_out = x"00010002000300040005000600070008" report "Test 7 failed for busS3" severity failure;
				
			--Case: rs1 = rs3 but not equal to rd
			report "Test 8: rs1 = rs3 but not equal to rd" severity note;
			rd <= "00111";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00101";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"91A516D14EF89171614565224651ADEC";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"91A516D14EF89171614565224651ADEC" report "Test 8 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 8 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 8 failed for busS3" severity failure;	 
				
			--Case: only rs1 = rd	
			report "Test 9: only rs1 = rd" severity note;
			rd <= "00111";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 9 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 9 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 9 failed for busS3" severity failure;  
				
			--Case: only rs2 = rd 
			report "Test 10: only rs2 = rd" severity note;
			rd <= "11101";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"6516516519844594A54B874871CFED47" report "Test 10 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 10 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 10 failed for busS3" severity failure;
				
			--Case: only rs3 = rd
			report "Test 11: only rs3 = rd" severity note;
			rd <= "00101";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"6516516519844594A54B874871CFED47" report "Test 11 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 11 failed for busS2" severity failure;
			assert busS3_out = x"00010002000300040005000600070008" report "Test 11 failed for busS3" severity failure;	  
				
			--Case: none are equal to rd	   
			report "Test 12: none are equal to rd" severity note;
			rd <= "10001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "11101";
			rs3 <= "00101";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"91A516D14EF89171614565224651ADEC"; 
			wait for period;
			assert busS1_out = x"6516516519844594A54B874871CFED47" report "Test 12 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 12 failed for busS2" severity failure;
			assert busS3_out = x"91A516D14EF89171614565224651ADEC" report "Test 12 failed for busS3" severity failure;
				
			--Case: rs1 = rs3, but rs2 = rd	   
			report "Test 13: rs1 = rs3, but rs2 = rd" severity note;
			rd <= "10001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "10001";
			rs3 <= "00111";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS3_in <= x"6516516519844594A54B874871CFED47"; 
			wait for period;
			assert busS1_out = x"6516516519844594A54B874871CFED47" report "Test 13 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 13 failed for busS2" severity failure;
			assert busS3_out = x"6516516519844594A54B874871CFED47" report "Test 13 failed for busS3" severity failure;
				
			--Case: rs1 = rs2, but rs3 = rd	   
			report "Test 14: rs1 = rs2, but rs3 = rd" severity note;
			rd <= "10001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "00111";
			rs2 <= "00111";
			rs3 <= "10001";
			busS1_in <= x"6516516519844594A54B874871CFED47";
			busS2_in <= x"6516516519844594A54B874871CFED47";
			busS3_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA"; 
			wait for period;
			assert busS1_out = x"6516516519844594A54B874871CFED47" report "Test 14 failed for busS1" severity failure;
			assert busS2_out = x"6516516519844594A54B874871CFED47" report "Test 14 failed for busS2" severity failure;
			assert busS3_out = x"00010002000300040005000600070008" report "Test 14 failed for busS3" severity failure;
				
			--Case: rs2 = rs3, but rs1 = rd	   
			report "Test 15: rs2 = rs3, but rs1 = rd" severity note;
			rd <= "10001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "10001";
			rs2 <= "00111";
			rs3 <= "00111";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"6516516519844594A54B874871CFED47";
			busS3_in <= x"6516516519844594A54B874871CFED47"; 
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 15 failed for busS1" severity failure;
			assert busS2_out = x"6516516519844594A54B874871CFED47" report "Test 15 failed for busS2" severity failure;
			assert busS3_out = x"6516516519844594A54B874871CFED47" report "Test 15 failed for busS3" severity failure;
			
			ctrl_signal <= "11";
			--Case: rs1 = rs2, and are equal to rd	   
			report "Test 16: rs1 = rs2, and are equal to rd" severity note;
			rd <= "10001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "10001";
			rs2 <= "10001";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 16 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 16 failed for busS2" severity failure; 
				
			--Case: rs1 = rs2, but are not equal to rd	   
			report "Test 17: rs1 = rs2, but are not equal to rd" severity note;
			rd <= "11001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "10001";
			rs2 <= "10001";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			wait for period;
			assert busS1_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 17 failed for busS1" severity failure;
			assert busS2_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 17 failed for busS2" severity failure; 
				
			--Case: only rs1 = rd	   
			report "Test 18: only rs1 = rd" severity note;
			rd <= "11001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "11001";
			rs2 <= "10001";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			wait for period;
			assert busS1_out = x"00010002000300040005000600070008" report "Test 18 failed for busS1" severity failure;
			assert busS2_out = x"91A516D14EF89171614565224651ADEC" report "Test 18 failed for busS2" severity failure;
				
			--Case: only rs2 = rd	   
			report "Test 19: only rs2 = rd" severity note;
			rd <= "11001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "10001";
			rs2 <= "11001";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			wait for period;
			assert busS1_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 19 failed for busS1" severity failure;
			assert busS2_out = x"00010002000300040005000600070008" report "Test 19 failed for busS2" severity failure;
			
			--Case: neither are equal   
			report "Test 20: none are equal" severity note;
			rd <= "11001";
			busD <= x"00010002000300040005000600070008";
			rs1 <= "11101";
			rs2 <= "10011";
			busS1_in <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
			busS2_in <= x"91A516D14EF89171614565224651ADEC";
			wait for period;
			assert busS1_out = x"123456789ABCDEF0F0F0F0F0AAAAAAAA" report "Test 20 failed for busS1" severity failure;
			assert busS2_out = x"91A516D14EF89171614565224651ADEC" report "Test 20 failed for busS2" severity failure;
				
			report "ALL THE TESTS PASSED" severity note;

		wait;
	end process;
end architecture tb;
