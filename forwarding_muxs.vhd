----
--
-- File : forwarding_muxs.vhd
-- Entity Name : forwarding_muxs
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
-- Description : entity forwarding_muxs has inputs rd, rs1, rs2, busS1_in, 
-- busS2_in, busS3_in, and busD along with outputs busS1_out, busS2_out,
-- and busS3_out. It checks if any of the input rs registers are equal
-- to the rd register and updates those register values to the rd value
-- accordingly
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;

entity forwarding_muxs is
	port (
	ctrl_signal : in std_logic_vector (1 downto 0);--signal to determine instruction type
	rd  : in bit_vector(4 downto 0);			   --the register to be written
	rs1 : in bit_vector(4 downto 0);			   --the register on busS1
	rs2 : in bit_vector(4 downto 0);		   	   --the register on busS2
	rs3 : in bit_vector(4 downto 0); 		 	   --the register on busS3
	busD : in bit_vector(127 downto 0);	     	   --bus with data to be written to rd
	busS1_in : in bit_vector(127 downto 0);	 	   --input bus with data from rs1
	busS2_in : in bit_vector(127 downto 0);        --input bus with data from rs2
	busS3_in : in bit_vector(127 downto 0);  	   --input bus with data from rs3	 
	busS1_out : out bit_vector(127 downto 0);	   --output bus with data from rs1
	busS2_out : out bit_vector(127 downto 0);      --output bus with data from rs2
	busS3_out : out bit_vector(127 downto 0));	   --output bus with data from rs3	
end forwarding_muxs;

architecture behavioral of forwarding_muxs is
begin
	forwarding : process (ctrl_signal, rd, rs1, rs2, rs3, busD, busS1_in, busS2_in, busS3_in)
	begin  
		if ctrl_signal = "10" then 							    --check if r4 instruction
			if rs1 = rs2 and rs2 = rs3 and rs1 = rs3 then 		--check if rs1-rs3 are equal
				if rs1 = rd then								--if rs1-rs3 are all equal and equal to rd, update 
					busS1_out <= busD;							--their bus data with the most current data from busD
					busS2_out <= busD;
					busS3_out <= busD;
				else
					busS1_out <= busS1_in;						--otherwise output their current bus data
					busS2_out <= busS2_in;
					busS3_out <= busS3_in;
					end if;
			elsif rs1 = rs2 then							    --for these next few cases, check if two rs registers are equal
				if rs1 = rd then							    --if they are equal and equal to rd, then update their bus data
					busS1_out <= busD;						    --with the most current data from busD
					busS2_out <= busD;
					busS3_out <= busS3_in;
				elsif rs3 = rd then							    --otherwise if the unequal register is equal to rd, then update
					busS1_out <= busS1_in;					    --its bus data with the most current data from busD
					busS2_out <= busS2_in;
					busS3_out <= busD;
				else										    --otherwise output their current bus data
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
					busS3_out <= busS3_in; 
				end if;
			elsif rs2 = rs3 then
				if rs2 = rd then
					busS1_out <= busS1_in;
					busS2_out <= busD;
					busS3_out <= busD; 
				elsif rs1 = rd then
					busS1_out <= busD;	
					busS2_out <= busS2_in;
					busS3_out <= busS3_in;
				else
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
					busS3_out <= busS3_in;
				end if;
			elsif rs1 = rs3 then
				if rs1 = rd then
					busS1_out <= busD;
					busS2_out <= busS2_in;
					busS3_out <= busD; 
				elsif rs2 = rd then
					busS1_out <= busS1_in;
					busS2_out <= busD;
					busS3_out <= busS3_in;
				else
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
					busS3_out <= busS3_in;
				end if;
			else												--if no other registers are equal to each other
				if rs1 = rd then								--then individually check to see if each register is equal to rd
					busS1_out <= busD;							--if so, then update the bus data with the current data from busD
					busS2_out <= busS2_in;						--otherwise output current bus data
					busS3_out <= busS3_in; 
				elsif rs2 = rd then
					busS1_out <= busS1_in;
					busS2_out <= busD;
					busS3_out <= busS3_in; 
				elsif rs3 = rd then
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
					busS3_out <= busD; 
				else
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
					busS3_out <= busS3_in;
				end if;
			end if;
		elsif ctrl_signal = "11" then						    --check if r3 instruction
			if rs1 = rs2 then 									--check if rs1 and rs2 are equal
				if rs1 = rd then								--if rs1 and rs2 are equal and equal to rd, update 
					busS1_out <= busD;							--their bus data with the most current data from busD
					busS2_out <= busD;
				else
					busS1_out <= busS1_in;						--otherwise output their current bus data
					busS2_out <= busS2_in;
				end if;
			else												--if no other registers are equal to each other
				if rs1 = rd then								--then individually check to see if each register is equal to rd
					busS1_out <= busD;							--if so, then update the bus data with the current data from busD
					busS2_out <= busS2_in;						--otherwise output current bus data 
				elsif rs2 = rd then
					busS1_out <= busS1_in;
					busS2_out <= busD;
				else
					busS1_out <= busS1_in;
					busS2_out <= busS2_in;
				end if;
			end if;
		end if;
	end process;
end behavioral;			
