----
--
-- File : multimedia_alu_tb.vhd
-- Entity Name : multimedia_alu_tb
-- Architecture : behavioral
-- Author : Eric Miller, Adam Roccanova
--
---------------------------------------------------------------------------
----
--
-- Generated : Sat Oct 25 3:26 2025
--
---------------------------------------------------------------------------
----
--
-- Description : Generates tests for major points of interests for ALU operations
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity multimedia_alu_tb is
end entity;

architecture tb of multimedia_alu_tb is
--Signals
signal rs1, rs2, rs3, rd : reg128 := (others => '0'); 
signal instr : std_logic_vector(24 downto 0) := (others => '0');

--Function to convert vector to hex string
function to_hstring(v: std_logic_vector) return string is
	variable result : string(1 to (v'length + 3)/4);
	variable nibble : std_logic_vector(3 downto 0);
	variable hexchar : character;
	begin
    for i in 0 to (v'length/4 - 1) loop
        nibble := v(v'length-1 - i*4 downto v'length-4 - i*4);
        case nibble is
            when "0000" => hexchar := '0';
            when "0001" => hexchar := '1';
            when "0010" => hexchar := '2';
            when "0011" => hexchar := '3';
            when "0100" => hexchar := '4';
            when "0101" => hexchar := '5';
            when "0110" => hexchar := '6';
            when "0111" => hexchar := '7';
            when "1000" => hexchar := '8';
            when "1001" => hexchar := '9';
            when "1010" => hexchar := 'A';
            when "1011" => hexchar := 'B';
            when "1100" => hexchar := 'C';
            when "1101" => hexchar := 'D';
            when "1110" => hexchar := 'E';
            when "1111" => hexchar := 'F';
            when others => hexchar := 'X';
        end case;
        result(i + 1) := hexchar;
    end loop;
    return result;
end function;

--Helper function to build R3 instruction
function mk_r3(op : opcode_field_r3) return std_logic_vector is
	variable tmp : std_logic_vector(24 downto 0);
	begin
		tmp := (others => '0');
		tmp(24) := '1';
		tmp(23) := '1';
		tmp(22 downto 15) := op;
	return tmp;
end function; 

--Helper function to build R4 instruction
function mk_r4(op : opcode_field_r4) return std_logic_vector is
	variable tmp : std_logic_vector(24 downto 0);
	begin
		tmp := (others => '0');
		tmp(24) := '1';
		tmp(23) := '0';
		tmp(22 downto 20) := op;
	return tmp;
end function; 

--Helper function to build LI instruction
function mk_imm(idx : natural; imm16 : std_logic_vector(15 downto 0)) return std_logic_vector is
	variable tmp : std_logic_vector(24 downto 0);
	begin
		tmp := (others => '0');
		tmp(24) := '0';
		tmp(23 downto 21) := std_logic_vector(to_unsigned(idx, 3));
		tmp(20 downto 5) := imm16;
	return tmp;
end function; 

begin
	--Instantiate ALU
	uut : entity work.multimedia_alu
		port map(rs1 => rs1, rs2 => rs2, rs3 => rs3, instr => instr, rd => rd);
		
	--Test process
	stim : process
	variable iv : std_logic_vector(24 downto 0);
	begin
		--------------------------------
		--LI tests
		--------------------------------
		
		--Write lane 0
		report "IMM test 1: write lane 0" severity note;
		rs1 <= (others => '0');
		iv := mk_imm(0, x"ABCD");
		instr <= iv;
		wait for 10ns;
		report " rd = " & to_hstring(rd);
		assert rd(15 downto 0) = x"ABCD" report "IMM lane 0 failed" severity failure;
		
		--Write lane 5
		report "IMM test 2: write lane 5" severity note;
		rs1 <= x"11112222333344445555666677778888";
		iv := mk_imm(5, x"EFEF");
		instr <= iv;
		wait for 10ns;
		report " rd = " & to_hstring(rd);
		assert rd(95 downto 80) = x"EFEF" report "IMM lane 5 failed" severity failure;
		
		---------------------------------
		--R3 Tests
		---------------------------------
		--NOP
        report "R3 test: NOP" severity note;
        rs1   <= x"1234567890ABCDEF1234567890ABCDEF";
        rs2   <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        instr <= mk_r3(OP_NOP);
        wait for 10 ns;
        assert rd = reg128'(others => '0') report "NOP failed" severity failure;
		
		--Or
        report "R3 test: OR" severity note;
        rs1   <= x"0000000000000000000000000000000F";
        rs2   <= x"000000000000000000000000000000F0";
        instr <= mk_r3(OP_OR);
        wait for 10 ns;
        assert rd = x"000000000000000000000000000000FF" report "OR failed" severity failure;
		
		
		--AND
        report "R3 test: AND" severity note;
        rs1   <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        rs2   <= x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F";
        instr <= mk_r3(OP_AND);
        wait for 10 ns;
        assert rd = x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F" report "AND failed" severity failure;
		
		--AHS
        report "R3 test: AHS (no sat)" severity note;
        rs1   <= x"00010002000300040005000600070008";
        rs2   <= x"00080007000600050004000300020001";
        instr <= mk_r3(OP_AHS);
        wait for 10 ns;
        -- 8 halfwords, each should be 0009
        assert rd = x"00090009000900090009000900090009" report "AHS failed" severity failure;  
		
		--AHS w/sat
        report "R3 test: AHS (with saturation)" severity note;
        rs1   <= x"7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF";
        rs2   <= x"00010001000100010001000100010001";
        instr <= mk_r3(OP_AHS);
        wait for 10 ns;
        -- every lane should saturate to 0x7FFF
        assert rd = x"7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF" report "AHS saturation failed" severity failure; 
		
		--SFHS
        report "R3 test: SFHS" severity note;
        rs1   <= x"00050005000500050005000500050005";
        rs2   <= x"00030003000300030003000300030003";
        instr <= mk_r3(OP_SFHS);
        wait for 10 ns;
        assert rd = x"00020002000200020002000200020002" report "SFHS failed" severity failure;
		
		--SFHS underflow
        report "R3 extra: SFHS negative saturation" severity note;
        rs1   <= x"8AD08AD08AD08AD08AD08AD08AD08AD0";
        rs2   <= x"27102710271027102710271027102710";
        instr <= mk_r3(OP_SFHS);
        wait for 10 ns;
        assert rd = x"80008000800080008000800080008000" report "SFHS negative saturation failed" severity failure;

		
		--AU
		report "R3 test: AU" severity note;
        rs1   <= x"00000001000000010000000100000001";
        rs2   <= x"00000002000000020000000200000002";
        instr <= mk_r3(OP_AU);
        wait for 10 ns;
        assert rd = x"00000003000000030000000300000003" report "AU failed" severity failure; 
		
		--AU wrap
        report "R3 extra: AU wrap" severity note;
        rs1   <= x"FFFFFFFF000000000000000000000000";
        rs2   <= x"00000001000000000000000000000000";
        instr <= mk_r3(OP_AU);
        wait for 10 ns;
        assert rd(31 downto 0) = x"00000000" report "AU wrap failed" severity failure;

		
		--SFWU
        report "R3 test: SFWU" severity note;
        rs1   <= x"00000005000000050000000500000005";
        rs2   <= x"00000003000000030000000300000003";
        instr <= mk_r3(OP_SFWU);
        wait for 10 ns;
        assert rd = x"00000002000000020000000200000002" report "SFWU failed" severity failure;
		
		--CNT1H
        report "R3 test: CNT1H" severity note;
        rs1   <= x"0000FFFF00FF0F0F80007FFF5555AAAA";
        rs2   <= (others => '0');
        instr <= mk_r3(OP_CNT1H);
        wait for 10 ns;
        assert rd = x"00000010000800080001000F00080008" report "CNT1H failed" severity failure;
		
		--CLZW
        report "R3 test: CLZW" severity note;
        rs1   <= x"000000008000000000F0000000000001";
        rs2   <= (others => '0');
        instr <= mk_r3(OP_CLZW);
        wait for 10 ns;
        assert rd = x"0000002000000000000000080000001F" report "CLZW failed" severity failure; 
		
		--ROTW
        report "R3 test: ROTW" severity note;
        rs1   <= x"123456789ABCDEF0F0F0F0F0AAAAAAAA";
        rs2   <= x"00000004000000080000001000000000";
        instr <= mk_r3(OP_ROTW);
        wait for 10 ns;
        assert rd = x"81234567F09ABCDEF0F0F0F0AAAAAAAA" report "ROTW failed" severity failure;
		
		--MLHCU
        report "R3 test: MLHU" severity note;
        rs1   <= x"00000003000000030000000300000003";
        rs2   <= x"00000004000000040000000400000004";
        instr <= mk_r3(OP_MLHU);
        wait for 10 ns;
        assert rd = x"0000000C0000000C0000000C0000000C" report "MLHU failed" severity failure;
		
		--MLHU
        report "R3 test: MLHCU" severity note;
        rs1   <= x"00000003000000030000000300000003";
        rs2   <= x"00000005000000050000000500000005";
        instr <= mk_r3(OP_MLHCU);
        wait for 10 ns;
        assert rd = x"0000000F0000000F0000000F0000000F" report "MLHCU failed" severity failure;	
		
		--SHRHI
        report "R3 test: SHRHI" severity note;
        rs1   <= x"80008000800080008000800080008000";
        iv    := mk_r3(OP_SHRHI);
        iv(13 downto 10) := "0011";
        instr <= iv;
        wait for 10 ns;
        assert rd = x"10001000100010001000100010001000" report "SHRHI failed" severity failure;	
		
		--BCW
        report "R3 test: BCW" severity note;
        rs1   <= x"000000000000000000000000ABCDEF12";
        instr <= mk_r3(OP_BCW);
        wait for 10 ns;
        assert rd = x"ABCDEF12ABCDEF12ABCDEF12ABCDEF12" report "BCW failed" severity failure;
		
		--MAXWS
        report "R3 test: MAXWS" severity note;
        rs1   <= x"00000001000000050000000A0000000F";
        rs2   <= x"00000002000000040000000B0000000E";
        instr <= mk_r3(OP_MAXWS);
        wait for 10 ns;
        assert rd = x"00000002000000050000000B0000000F" report "MAXWS failed" severity failure;	
		
		--MINWS
        report "R3 test: MINWS" severity note;
        rs1   <= x"00000001000000050000000A0000000F";
        rs2   <= x"00000002000000040000000B0000000E";
        instr <= mk_r3(OP_MINWS);
        wait for 10 ns;
        assert rd = x"00000001000000040000000A0000000E" report "MINWS failed" severity failure;	
		
		-------------------------------------
		--R4 Tests
		-------------------------------------
		
		--MULADD_LOW
        report "R4 test: MULADD_LOW" severity note;
        rs1   <= x"00000005000000050000000500000005";
        rs2   <= x"00000004000000040000000400000004";
        rs3   <= x"00000003000000030000000300000003";
        instr <= mk_r4(OP4_MULADD_LOW);
        wait for 10 ns;
        assert rd = x"00000011000000110000001100000011" report "R4 MULADD_LOW failed" severity failure;
		
		--MULADD_LOW w/sat
        report "R4 extra: MULADD_LOW saturation" severity note;
        rs1   <= x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF";
        rs2   <= x"00000000000000000000000000007FFF";
        rs3   <= x"00000000000000000000000000007FFF";
        instr <= mk_r4(OP4_MULADD_LOW);
        wait for 10 ns;
        assert rd = x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF" report "R4 MULADD_LOW saturation failed" severity failure;

		
		--MULADD_HIGH
        report "R4 test: MULADD_HIGH" severity note;
        rs1   <= x"00000005000000050000000500000005";
        rs2   <= x"00040000000400000004000000040000";
        rs3   <= x"00030000000300000003000000030000";
        instr <= mk_r4(OP4_MULADD_HIGH);
        wait for 10 ns;
        assert rd = x"00000011000000110000001100000011" report "R4 MULADD_HIGH failed" severity failure;
		
		--MULADD_HIGH w/sat
        report "R4 extra: MULADD_HIGH saturation" severity note;
        rs1   <= x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF";
        rs2   <= x"7FFF0000000000000000000000000000";
        rs3   <= x"7FFF0000000000000000000000000000";
        instr <= mk_r4(OP4_MULADD_HIGH);
        wait for 10 ns;
        assert rd = x"7FFFFFFF7FFFFFFF7FFFFFFF7FFFFFFF" report "R4 MULADD_HIGH saturation failed" severity failure;
		
		--MULSUB_LOW
		report "R4 test: MULSUB_LOW" severity note;
        rs1   <= x"00000005000000050000000500000005";
        rs2   <= x"00000004000000040000000400000004";
        rs3   <= x"00000003000000030000000300000003";
        instr <= mk_r4(OP4_MULSUB_LOW);
        wait for 10 ns;
        assert rd = x"FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9" report "R4 MULSUB_LOW failed" severity failure;
		
		--MULSUB_LOW underflow
        report "R4 extra: MULSUB_LOW negative saturation" severity note;
        rs1   <= x"80000000800000008000000080000000";
        rs2   <= x"00000000000000000000000000007FFF";
        rs3   <= x"00000000000000000000000000007FFF";
        instr <= mk_r4(OP4_MULSUB_LOW);
        wait for 10 ns;
        assert rd = x"80000000800000008000000080000000" report "R4 MULSUB_LOW negative saturation failed" severity failure;

		
		--MULSUB_HIGH
        report "R4 test: MULSUB_HIGH" severity note;
        rs1   <= x"00000005000000050000000500000005";
        rs2   <= x"00040000000400000004000000040000";
        rs3   <= x"00030000000300000003000000030000";
        instr <= mk_r4(OP4_MULSUB_HIGH);
        wait for 10 ns;
        assert rd = x"FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9" report "R4 MULSUB_HIGH failed" severity failure;
		
		--MULSUB_HIGH underflow
        report "R4 extra: MULSUB_HIGH negative saturation" severity note;
        rs1   <= x"80000000800000008000000080000000";
        rs2   <= x"7FFF0000000000000000000000000000";
        rs3   <= x"7FFF0000000000000000000000000000";
        instr <= mk_r4(OP4_MULSUB_HIGH);
        wait for 10 ns;
        assert rd = x"80000000800000008000000080000000" report "R4 MULSUB_HIGH negative saturation failed" severity failure;
		
		--LONG_MULADD_LOW
        report "R4 test: LONG_MULADD_LOW" severity note;
        rs1   <= (others => '0');
        rs1(63 downto 0)    <= x"0000000000000005";
        rs1(127 downto 64)  <= x"0000000000000005";
        rs2(63 downto 0)    <= x"0000000000000004";
        rs2(127 downto 64)  <= x"0000000000000004";
        rs3(63 downto 0)    <= x"0000000000000003";
        rs3(127 downto 64)  <= x"0000000000000003";
        instr <= mk_r4(OP4_LONG_MULADD_LOW);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"0000000000000011" report "LONG_MULADD_LOW lane0 failed" severity failure;
        assert rd(127 downto 64) = x"0000000000000011" report "LONG_MULADD_LOW lane1 failed" severity failure;
		
		--LONG_MULADD_LOW w/sat
        report "R4 extra: LONG_MULADD_LOW saturation" severity note;
        rs1(63 downto 0)    <= x"7FFFFFFFFFFFFFFF";
        rs1(127 downto 64)  <= x"7FFFFFFFFFFFFFFF";
        rs2(63 downto 0)    <= x"00000000FFFFFFFF";
        rs2(127 downto 64)  <= x"00000000FFFFFFFF";
        rs3(63 downto 0)    <= x"00000000FFFFFFFF";
        rs3(127 downto 64)  <= x"00000000FFFFFFFF";
        instr <= mk_r4(OP4_LONG_MULADD_LOW);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"7FFFFFFFFFFFFFFF" report "LONG_MULADD_LOW saturation lane0 failed" severity failure;
        assert rd(127 downto 64) = x"7FFFFFFFFFFFFFFF" report "LONG_MULADD_LOW saturation lane1 failed" severity failure;

		
		--LONG_MULADD_HIGH
		report "R4 test: LONG_MULADD_HIGH" severity note;
        rs1   <= (others => '0');
        rs1(63 downto 0)    <= x"0000000000000005";
        rs1(127 downto 64)  <= x"0000000000000005";
        rs2(63 downto 0)    <= x"0000000400000000";
        rs2(127 downto 64)  <= x"0000000400000000";
        rs3(63 downto 0)    <= x"0000000300000000";
        rs3(127 downto 64)  <= x"0000000300000000";
        instr <= mk_r4(OP4_LONG_MULADD_HIGH);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"0000000000000011" report "LONG_MULADD_HIGH lane0 failed" severity failure;
        assert rd(127 downto 64) = x"0000000000000011" report "LONG_MULADD_HIGH lane1 failed" severity failure;		 
		
		--LONG_MULADD_HIGH w/sat
        report "R4 extra: LONG_MULADD_HIGH saturation" severity note;
        rs1(63 downto 0)    <= x"7FFFFFFFFFFFFFFF";
        rs1(127 downto 64)  <= x"7FFFFFFFFFFFFFFF";
        rs2(63 downto 0)    <= x"FFFFFFFF00000000";
        rs2(127 downto 64)  <= x"FFFFFFFF00000000";
        rs3(63 downto 0)    <= x"FFFFFFFF00000000";
        rs3(127 downto 64)  <= x"FFFFFFFF00000000";
        instr <= mk_r4(OP4_LONG_MULADD_HIGH);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"7FFFFFFFFFFFFFFF" report "LONG_MULADD_HIGH saturation lane0 failed" severity failure;
        assert rd(127 downto 64) = x"7FFFFFFFFFFFFFFF" report "LONG_MULADD_HIGH saturation lane1 failed" severity failure;
		
		--LONG_MULSUB_LOW
        report "R4 test: LONG_MULSUB_LOW" severity note;
        rs1   <= (others => '0');
        rs1(63 downto 0)    <= x"0000000000000005";
        rs1(127 downto 64)  <= x"0000000000000005";
        rs2(63 downto 0)    <= x"0000000000000004";
        rs2(127 downto 64)  <= x"0000000000000004";
        rs3(63 downto 0)    <= x"0000000000000003";
        rs3(127 downto 64)  <= x"0000000000000003";
        instr <= mk_r4(OP4_LONG_MULSUB_LOW);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"FFFFFFFFFFFFFFF9" report "LONG_MULSUB_LOW lane0 failed" severity failure;
        assert rd(127 downto 64) = x"FFFFFFFFFFFFFFF9" report "LONG_MULSUB_LOW lane1 failed" severity failure;
		
		--LONG_MULSUB_LOW w/sat
        report "R4 extra: LONG_MULSUB_LOW saturation" severity note;
        rs1(63 downto 0)    <= x"8000000000000000";
        rs1(127 downto 64)  <= x"8000000000000000";
        rs2(63 downto 0)    <= x"00000000FFFFFFFF";
        rs2(127 downto 64)  <= x"00000000FFFFFFFF";
        rs3(63 downto 0)    <= x"00000000FFFFFFFF";
        rs3(127 downto 64)  <= x"00000000FFFFFFFF";
        instr <= mk_r4(OP4_LONG_MULSUB_LOW);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"8000000000000000" report "LONG_MULSUB_LOW saturation lane0 failed" severity failure;
        assert rd(127 downto 64) = x"8000000000000000" report "LONG_MULSUB_LOW saturation lane1 failed" severity failure;
		
		--LONG_MULSUB_HIGH
        report "R4 test: LONG_MULSUB_HIGH" severity note;
        rs1   <= (others => '0');
        rs1(63 downto 0)    <= x"0000000000000005";
        rs1(127 downto 64)  <= x"0000000000000005";
        rs2(63 downto 0)    <= x"0000000400000000";
        rs2(127 downto 64)  <= x"0000000400000000";
        rs3(63 downto 0)    <= x"0000000300000000";
        rs3(127 downto 64)  <= x"0000000300000000";
        instr <= mk_r4(OP4_LONG_MULSUB_HIGH);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"FFFFFFFFFFFFFFF9" report "LONG_MULSUB_HIGH lane0 failed" severity failure;
        assert rd(127 downto 64) = x"FFFFFFFFFFFFFFF9" report "LONG_MULSUB_HIGH lane1 failed" severity failure;	
		
		--LONG_MULSUB_HIGH w/sat
        report "R4 extra: LONG_MULSUB_HIGH saturation" severity note;
        rs1(63 downto 0)    <= x"8000000000000000";
        rs1(127 downto 64)  <= x"8000000000000000";
        rs2(63 downto 0)    <= x"FFFFFFFF00000000";
        rs2(127 downto 64)  <= x"FFFFFFFF00000000";
        rs3(63 downto 0)    <= x"FFFFFFFF00000000";
        rs3(127 downto 64)  <= x"FFFFFFFF00000000";
        instr <= mk_r4(OP4_LONG_MULSUB_HIGH);
        wait for 10 ns;
        assert rd(63 downto 0)   = x"8000000000000000" report "LONG_MULSUB_HIGH saturation lane0 failed" severity failure;
        assert rd(127 downto 64) = x"8000000000000000" report "LONG_MULSUB_HIGH saturation lane1 failed" severity failure;
		
		report "ALL THE TESTS PASSED" severity note;

		
		wait;
	end process;
end architecture tb;
