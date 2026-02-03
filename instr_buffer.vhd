library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity instr_buffer is
	port(
	clk : in std_logic;
	reset : in std_logic;
	-- Instruction at current PC
	instr_out : out instr25;
	-- Current PC
	pc_out : out pc_t;
	-- Load enable for buffer
	load_en : in std_logic;
	--Determines what word to use, and stores instructions
	load_addr : in pc_t;  
	-- What instruction to store in load_addr
	load_data : in instr25);
end entity;	

architecture behavioral of instr_buffer is
--Signals
type mem_t is array (0 to IB_DEPTH-1) of instr25; --Instruction memory array
signal mem : mem_t := (others => (others => '0')); --Instruction memory
signal pc : pc_t := (others => '0'); --Internal Program counter
signal pc_fetch: pc_t := (others => '0'); --Copy of PC for pc_out (creates stable output that matches instr_out)

begin
	process(clk, reset)
	begin 
		--Resets PC and Instr_out
		if reset = '1' then
			pc <= (others => '0');
			pc_fetch <= (others => '0');
			instr_out <= (others => '0');
		--If rising edge and load is enabled then write load_data to memory
		elsif rising_edge(clk) then
			if load_en = '1' then
				mem(to_integer(load_addr)) <= load_data;
			else  
				--If load is not enabled then get instruction from memory and output it
				pc_fetch <= pc;
				instr_out <= mem(to_integer(pc));
				pc <= pc + 1;
			end if;
		end if;
	end process;
	--Makes it easier to check PC for debugging
	pc_out <= pc_fetch;
end architecture behavioral;
