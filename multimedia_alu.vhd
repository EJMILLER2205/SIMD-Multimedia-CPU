----
--
-- File : multimedia_alu.vhd
-- Entity Name : multimedia_alu
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
-- Description : Creates the ALU for Part 1 of the project. multimedia_alu
-- has inputs rs1, rs2, and rs3 (three 128-bit input registers), instr (25-bit
-- instruction), and output 128-bit output register rd. There are three categories
-- of instruction formats, load immediate, R4, and R3.
--																							   
---------------------------------------------------------------------------	
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity multimedia_alu is
	port(
	rs1 : in reg128; --Source register 1
	rs2 : in reg128; --Source register 2
	rs3 : in reg128; --Source register 3   
	instr : in std_logic_vector (24 downto 0); --instruction
	rd : out reg128 --Destination register
	);
end entity multimedia_alu;

architecture behavioral of multimedia_alu is	  
	--Lane slicing helpers
	function get32(v: reg128; i: natural) return word32 is
	begin return v(i*32+31 downto i*32); 
	end;
	
	function put32(v: reg128; i: natural; w: word32) return reg128 is
	  variable t: reg128 := v;
	begin t(i*32+31 downto i*32) := w; return t; 
	end;  
	
	function get64(v: reg128; i: natural) return word64 is
	begin return v(i*64+63 downto i*64); 
	end;
	
	function put64(v: reg128; i: natural; w: word64) return reg128 is
	  variable t: reg128 := v;
	begin t(i*64+63 downto i*64) := w; return t; 
	end;
	
	--Signed 16-bit saturation
	function sat16(x: signed(16 downto 0)) return signed is
	begin
	  if x >  to_signed( 32767,17) then return to_signed( 32767,16);
	  elsif x < to_signed(-32768,17) then return to_signed(-32768,16);
	  else return x(15 downto 0);
	  end if;
	end;
	
	--Count leading zeros for one 32bit word
	function clz32(x: std_logic_vector(31 downto 0)) return std_logic_vector is
	  variable n: integer := 0;
	begin
	  for b in 31 downto 0 loop
	    if x(b)='0' then n := n + 1; else exit; end if;
	  end loop;
	  return std_logic_vector(to_unsigned(n,32));
	end;  
	
	--32 bit saturation
	function sat32(x : signed(32 downto 0)) return signed is
		constant MAX32 : signed(31 downto 0) := to_signed(2147483647, 32);
		constant MIN32 : signed(31 downto 0) := to_signed(-2147483648, 32);
	begin
		if x > resize(MAX32, 33) then
			return MAX32;
		elsif x < resize(MIN32, 33) then
			return MIN32;
		else 
			return x(31 downto 0);
		end if;
	end function; 
	
	--64 bit saturation
    function sat64(x : signed(64 downto 0)) return signed is
        constant MAX64 : signed(63 downto 0) := (63 => '0', others => '1');
        constant MIN64 : signed(63 downto 0) := (63 => '1', others => '0');
    begin
        if x(64) /= x(63) then
            if x(64) = '0' then
                return MAX64;
            else
                return MIN64;
            end if;
        else
            return x(63 downto 0);
        end if;
    end function;	
	
begin 
	process(rs1, rs2, rs3, instr)
	--Declare variables that will be used 
	
	--temps
	variable tmp : reg128 := (others => '0');
	variable temp128 : reg128 := (others => '0'); 
	--halfword operations
	variable a, b : signed(15 downto 0);
	variable s17 : signed(16 downto 0);
	variable sat : signed(15 downto 0);
	--word operations
	variable w, r : std_logic_vector(31 downto 0);  
	variable sh : natural range 0 to 31; 
	--unsigned lanes
	variable a16, b16 : unsigned(15 downto 0); 
	--signed lanes
	variable a16s, b16s : signed(15 downto 0);
	variable prod32s : signed(31 downto 0);
	variable rs1_32s : signed(31 downto 0);
	variable acc32 : signed(32 downto 0);  
	--long signed lanes
    variable a32s, b32s : signed(31 downto 0);
    variable prod64s : signed(63 downto 0);
    variable rs1_64s : signed(63 downto 0);
    variable acc64 : signed(64 downto 0); 
	--misc
	variable k5 : unsigned(4 downto 0);  
	variable p32 : unsigned(31 downto 0);
	variable hw : std_logic_vector(15 downto 0); 
	variable c : integer;
	--decoded fields
	variable opcode_r3 : opcode_field_r3;
	variable opcode_r4 : opcode_field_r4;
	--Load intermediate variables
	variable old_rd : reg128;
	variable imm16 : std_logic_vector(15 downto 0);
	variable idx : integer;	 
	--SHRI immediate
	variable shamt4 : unsigned(3 downto 0);
	
	--Start process
	begin
		--Default result
		tmp := (others => '0');
		
		if instr(24) = '0' then	
			old_rd := rs1;
			imm16 := instr(20 downto 5);
			idx := to_integer(unsigned(instr(23 downto 21)));
			
			temp128 := old_rd;
			case idx is
				when 0 => temp128(15 downto 0) := imm16; 
				when 1 => temp128(31 downto 16) := imm16;
				when 2 => temp128(47 downto 32) := imm16;
				when 3 => temp128(63 downto 48) := imm16;
				when 4 => temp128(79 downto 64) := imm16;
				when 5 => temp128(95 downto 80) := imm16;
				when 6 => temp128(111 downto 96) := imm16;
				when 7 => temp128(127 downto 112) := imm16;
				when others => null;
			end case;
			tmp := temp128;
				
			
		elsif instr (24) = '1' and instr(23) = '0' then
		-----------------------------------------------
		--Decode and execute operations for R4
		-----------------------------------------------
		opcode_r4 := instr(22 downto 20);
		case opcode_r4 is					 
			
			--Signed Integer Multiply
			
			when OP4_MULADD_LOW =>
				temp128 := (others => '0');
				for i in 0 to 3 loop 
					--Get low 16 bits
					a16s := signed(get32(rs3, i)(15 downto 0));
					b16s := signed(get32(rs2, i)(15 downto 0));
					prod32s := a16s * b16s;
					rs1_32s := signed(get32(rs1, i));
					acc32 := resize(rs1_32s, 33) + resize(prod32s, 33);
					temp128 := put32(temp128, i, std_logic_vector(sat32(acc32)));
				end loop;
			tmp := temp128;

			when OP4_MULADD_HIGH =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
					a16s := signed(get32(rs3, i)(31 downto 16));
					b16s := signed(get32(rs2, i)(31 downto 16));
					prod32s := a16s * b16s;
					rs1_32s := signed(get32(rs1, i));
                    acc32   := resize(rs1_32s, 33) + resize(prod32s, 33);
                    temp128 := put32(temp128, i, std_logic_vector(sat32(acc32)));
				end loop;
			tmp := temp128;
			
			when OP4_MULSUB_LOW =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
                    a16s := signed(get32(rs3, i)(15 downto 0));
                    b16s := signed(get32(rs2, i)(15 downto 0));
                    prod32s := a16s * b16s;
                    rs1_32s := signed(get32(rs1, i));
                    acc32   := resize(rs1_32s, 33) - resize(prod32s, 33);
                    temp128 := put32(temp128, i, std_logic_vector(sat32(acc32)));
				end loop;
			tmp := temp128;
			
			when OP4_MULSUB_HIGH =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
                    a16s := signed(get32(rs3, i)(31 downto 16));
                    b16s := signed(get32(rs2, i)(31 downto 16));
                    prod32s := a16s * b16s;
                    rs1_32s := signed(get32(rs1, i));
                    acc32   := resize(rs1_32s, 33) - resize(prod32s, 33);
                    temp128 := put32(temp128, i, std_logic_vector(sat32(acc32)));
				end loop;
			tmp := temp128;	 
			
			--Signed Long Integer Multiply	
			
			when OP4_LONG_MULADD_LOW =>
				temp128 := (others => '0');
				for i in 0 to 1 loop
                    a32s    := signed(get64(rs3, i)(31 downto 0));
                    b32s    := signed(get64(rs2, i)(31 downto 0));
                    prod64s := a32s * b32s;
                    rs1_64s := signed(get64(rs1, i));
                    acc64   := resize(rs1_64s, 65) + resize(prod64s, 65);
                    temp128 := put64(temp128, i, std_logic_vector(sat64(acc64)));
				end loop;
			tmp := temp128;

			when OP4_LONG_MULADD_HIGH =>
				temp128 := (others => '0');
				for i in 0 to 1 loop
                    a32s    := signed(get64(rs3, i)(63 downto 32));
                    b32s    := signed(get64(rs2, i)(63 downto 32));
                    prod64s := a32s * b32s;
                    rs1_64s := signed(get64(rs1, i));
                    acc64   := resize(rs1_64s, 65) + resize(prod64s, 65);
                    temp128 := put64(temp128, i, std_logic_vector(sat64(acc64)));
				end loop;
			tmp := temp128;
			
			when OP4_LONG_MULSUB_LOW =>
				temp128 := (others => '0');
				for i in 0 to 1 loop
                    a32s    := signed(get64(rs3, i)(31 downto 0));
                    b32s    := signed(get64(rs2, i)(31 downto 0));
                    prod64s := a32s * b32s;
                    rs1_64s := signed(get64(rs1, i));
                    acc64   := resize(rs1_64s, 65) - resize(prod64s, 65);
                    temp128 := put64(temp128, i, std_logic_vector(sat64(acc64)));
				end loop;
			tmp := temp128;
			
			when OP4_LONG_MULSUB_HIGH =>
				temp128 := (others => '0');
				for i in 0 to 1 loop
                    a32s    := signed(get64(rs3, i)(63 downto 32));
                    b32s    := signed(get64(rs2, i)(63 downto 32));
                    prod64s := a32s * b32s;
                    rs1_64s := signed(get64(rs1, i));
                    acc64   := resize(rs1_64s, 65) - resize(prod64s, 65);
                    temp128 := put64(temp128, i, std_logic_vector(sat64(acc64)));
				end loop;
			tmp := temp128;
			when others =>
			null;
		end case;
		
		else
		-------------------------------------------------
		--Decode and execute opreations for R3
		-------------------------------------------------  
		opcode_r3 := instr(22 downto 15);
		case opcode_r3 is
			--BASE OPERATIONS
			when OP_NOP =>
				tmp := (others => '0'); --No operation (output = 0)
			
			when OP_OR =>
				tmp := rs1 or rs2; --Or operation
			
			when OP_AND =>
				tmp := rs1 and rs2; --And operation
			
			--AHS OPERATION
      		when OP_AHS =>
				--Reset temp
				temp128 := (others => '0');
				--Iterates through halfwords
				for i in 0 to 7 loop
					--Gets registers
		          	a := signed(rs1(i*16+15 downto i*16));
		          	b := signed(rs2(i*16+15 downto i*16));
		          	s17 := resize(a,17) + resize(b,17);
					
					--Prevents overflow with saturation
		          	if s17 > to_signed( 32767,17) then
		            		sat := to_signed( 32767,16);
		          	elsif s17 < to_signed(-32768,17) then
		            		sat := to_signed(-32768,16);
		          	else
		            		sat := s17(15 downto 0);
		          	end if;
		          	temp128(i*16+15 downto i*16) := std_logic_vector(sat);
		        	end loop;
			--Sets temp register
		     tmp := temp128;
			
			--SFHS OPERATION
			when OP_SFHS =>
				--Reset temp
				temp128 := (others => '0');
				--Iterates through halfwords
				for i in 0 to 7 loop
					--Gets registers
					a := signed(rs1(i*16+15 downto i*16));
					b := signed(rs2(i*16+15 downto i*16));
					s17 := resize(b, 17) - resize(a, 17);
					sat := sat16(s17);
					temp128(i*16+15 downto i*16) := std_logic_vector(sat);
				end loop;
			tmp := temp128;
			
			--AU OPERATION
			when OP_AU =>
				--Resets temp
				temp128 := (others => '0');
				--Iterates through all 4x32 bits
				for i in 0 to 3 loop
					--Adds
					temp128 := put32(temp128, i, std_logic_vector(unsigned(get32(rs1,i)) + unsigned(get32(rs2,i))));
				end loop;
			tmp := temp128;
			
			--SFWU OPERATION
			when OP_SFWU =>
				--Resets temp
				temp128 := (others => '0');
				--Iterates through 4x32 bits
				for i in 0 to 3 loop
					--Subtracts
					temp128 := put32(temp128, i, std_logic_vector(unsigned(get32(rs2, i)) - unsigned(get32(rs1, i))));
				end loop;
			tmp := temp128;
			
			--CNT1H OPERATION
			when OP_CNT1H =>
				--Resets temp
				temp128 := (others => '0');
				--Iterates through all words
				for i in 0 to 7 loop
					--Creates usable variables
					c := 0;
					--Counts 1s and increases c if detected
					hw := rs1(i*16 + 15 downto i*16);
					for m in 0 to 15 loop
						if hw(m) = '1' 
							then c := c + 1;
						end if;
					end loop;
					--Puts count into high
					temp128(i*16 + 15 downto i*16) := std_logic_vector(to_unsigned(c, 16));
				end loop;
			tmp := temp128;
			
			
			--CLZW OPERATOR
			when OP_CLZW =>
			temp128 := (others => '0');
			--Iterates Through
			for i in 0 to 3 loop
					--Counts Leading 0s
					temp128 := put32(temp128, i, clz32(get32(rs1,i)));
				end loop;
			tmp := temp128;	
			
			--ROTW OPERATOR
			when OP_ROTW =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
			    		w  := get32(rs1, i);
			    		sh := to_integer(unsigned(get32(rs2, i)(4 downto 0)));
			    		if sh = 0 then
			      		r := w;
			   		else
			      		r := std_logic_vector((unsigned(w) srl sh) or (unsigned(w) sll (32 - sh)));
			    		end if;
			    		temp128 := put32(temp128, i, r);
			  	end loop;
			tmp := temp128;
			
			--MLHU OPERATOR
			when OP_MLHU =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
					a16 := unsigned(get32(rs1, i)(15 downto 0));
					b16 := unsigned(get32(rs2, i)(15 downto 0));
					p32 := a16*b16;
					temp128 := put32(temp128, i, std_logic_vector(p32));
				end loop;
			tmp := temp128;
			
			--MLHCU OPERATOR
			when OP_MLHCU =>
			    temp128 := (others => '0');
			    k5 := unsigned(instr(14 downto 10));
			    for i in 0 to 3 loop
			        a16 := unsigned(get32(rs1, i)(15 downto 0));
			        p32 := resize(a16 * k5, 32);
			        temp128 := put32(temp128, i, std_logic_vector(p32));
			    end loop;
			    tmp := temp128;	 
			
			--SHRHI OPERATOR
			when OP_SHRHI =>
			temp128 := (others => '0');
			shamt4 := unsigned(instr(13 downto 10));
				for i in 0 to 7 loop 
					temp128(i*16+15 downto i*16) := std_logic_vector(unsigned(rs1(i*16+15 downto i*16)) srl to_integer(shamt4));
				end loop;
			tmp := temp128;
			
			--BCW OPERATOR
			when OP_BCW =>
		    temp128 := (others => '0');
		    for i in 0 to 3 loop
		        temp128 := put32(temp128, i, get32(rs1, 3));
		    end loop;
		    tmp := temp128;
			
			--MAXWS OPERATOR
			when OP_MAXWS =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
					if signed(get32(rs1, i)) > signed(get32(rs2, i)) then
						temp128 := put32(temp128, i, get32(rs1, i)); 
					else
						temp128 := put32(temp128, i, get32(rs2, i));
					end if;
				end loop;
			tmp := temp128;
			
			--MINWS OPERATOR
			when OP_MINWS =>
				temp128 := (others => '0');
				for i in 0 to 3 loop
					if signed(get32(rs1, i)) < signed(get32(rs2, i)) then
						temp128 := put32(temp128, i, get32(rs1, i)); 
					else
						temp128 := put32(temp128, i, get32(rs2, i));
					end if;
				end loop;
			tmp := temp128; 
		
			when others =>
			tmp := (others => '0');
		end case;
		end if;
		
		---------------------------------------------
		--Output Results
		---------------------------------------------
		rd <= tmp;
	end process;
end architecture behavioral;
		
			
