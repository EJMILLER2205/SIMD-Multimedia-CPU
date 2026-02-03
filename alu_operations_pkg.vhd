library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Package to make project easier to reference
package alu_operations_pkg is
	-----------------------------------------------------------
	--Basic Type Definitions 
	-----------------------------------------------------------
	subtype word32 is std_logic_vector(31 downto 0);
	subtype reg128 is std_logic_vector(127 downto 0); 
	subtype word64 is std_logic_vector(63 downto 0);
	
	
	--Used for opecodes and instruction fields		    
	subtype opcode_field_r3 is std_logic_vector(7 downto 0);
	subtype opcode_field_r4 is std_logic_vector(2 downto 0); 
	
	-----------------------------------------------------------
	--R3 Instruction Opcodes (Bit Positions [22:15])
	-----------------------------------------------------------
	constant OP_NOP   : opcode_field_r3 := "00000000"; --Nop opcode
	constant OP_AHS   : opcode_field_r3 := "00000100"; --Add halfword with saturation opcode
	constant OP_SFHS  : opcode_field_r3 := "00001111"; --Subtract halfword with saturation opcode
	constant OP_AU    : opcode_field_r3 := "00000010"; --Add unsigned opcode	
	constant OP_SFWU  : opcode_field_r3 := "00001110"; --Subtract fullword unsigned opcode 
	constant OP_OR    : opcode_field_r3 := "00000101"; --Or opcode
	constant OP_AND   : opcode_field_r3 := "00001011"; --And opcode
	constant OP_CNT1H : opcode_field_r3 := "00000011"; --Count ones per halfword opcode
	constant OP_CLZW  : opcode_field_r3 := "00001100"; --Count leading zeros per word opcode
	constant OP_ROTW  : opcode_field_r3 := "00001101"; --Rotate word opcode
	constant OP_MLHU  : opcode_field_r3 := "00001001"; --Multiply low halfword unsgined opcode
	constant OP_MLHCU : opcode_field_r3 := "00001010"; --Multiply low halfword constant opcode		 
	constant OP_SHRHI : opcode_field_r3 := "00000001"; --Shift right halfword immediate
	constant OP_BCW	  : opcode_field_r3 := "00000110"; --Broadcast word
	constant OP_MAXWS : opcode_field_r3 := "00000111"; --Max signed word
	constant OP_MINWS : opcode_field_r3 := "00001000"; --Min signed word
	
	----------------------------------------------------------
	--R4 Instruction Opcodes (Bit Positions [22:20])
	----------------------------------------------------------
	constant OP4_MULADD_LOW  : opcode_field_r4 := "000"; --Multiply add low opcode
	constant OP4_MULADD_HIGH : opcode_field_r4 := "001"; --Multiply add high opcode
	constant OP4_MULSUB_LOW  : opcode_field_r4 := "010"; --Multiply sub low opcode
	constant OP4_MULSUB_HIGH : opcode_field_r4 := "011"; --Multiply sub high opcode
	constant OP4_LONG_MULADD_LOW  : opcode_field_r4 := "100"; --Multiply add low opcode
	constant OP4_LONG_MULADD_HIGH : opcode_field_r4 := "101"; --Multiply add high opcode
	constant OP4_LONG_MULSUB_LOW  : opcode_field_r4 := "110"; --Multiply sub low opcode
	constant OP4_LONG_MULSUB_HIGH : opcode_field_r4 := "111"; --Multiply sub high opcode
	
	----------------------------------------------------------
	--ALU Group Enumeration and zero register constant
	----------------------------------------------------------
	type alu_group_t is (R3_GROUP, R4_GROUP, IMM_GROUP);
	constant ZERO_128 : reg128 := (others => '0');
	
	----------------------------------------------------------
	--Instruction Buffer
	----------------------------------------------------------
	subtype instr25 is std_logic_vector(24 downto 0);
	constant IB_DEPTH : natural := 64;
	subtype pc_t is unsigned(5 downto 0);
	constant CLK_PERIOD : time := 10ns;	  
	
	----------------------------------------------------------
	--Pipeline Skeleton
	----------------------------------------------------------
	subtype reg_index_t is std_logic_vector(4 downto 0);

end package alu_operations_pkg;

package body alu_operations_pkg is
end package body alu_operations_pkg;
	
	
	
