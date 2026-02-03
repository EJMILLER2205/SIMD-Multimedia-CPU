library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.alu_operations_pkg.all;

entity instr_buffer_tb is
end entity;

architecture tb of instr_buffer_tb is 
--Signals
signal clk : std_logic := '0';
signal reset : std_logic := '1';
signal instr_out : instr25;	 
signal pc_out : pc_t;
signal load_en : std_logic := '0';
signal load_addr : pc_t := (others => '0');
signal load_data : instr25 := (others => '0');

--Allows for input file to be read
file prog_file : text open read_mode is "program.bin";

--Helper funcion that converts vector to string
function func_to_string(v : std_logic_vector) return string is
variable s : string(1 to v'length);
begin
    for i in v'range loop
        s(v'length - i) := std_logic'image(v(i))(2);
    end loop;
    return s; 
end function;

begin
	--Creates free running clock process
	clk_process : process
	begin
		while true loop
			clk <= '0';
			wait for CLK_PERIOD / 2;
			clk <= '1';
			wait for CLK_PERIOD / 2;
		end loop;
	end process;
	
	--Port map
	uut : entity work.instr_buffer
		port map(
		clk => clk,
		reset => reset,
		instr_out => instr_out,
		pc_out => pc_out,
		load_en => load_en,
		load_addr => load_addr,
		load_data => load_data);
	
	--Creates testing Process
	stim_proc : process
	variable L : line;
	variable tmpv : std_logic_vector(24 downto 0);
	variable addr_i : integer := 0;
	begin
		--Reset
		reset <= '1';
		load_en <= '0';
		wait for 3*CLK_PERIOD;
		reset <= '0';
		
		--Load instructions from file
		report "Starting instruction load from file" severity note;
		load_en <= '1';
		addr_i := 0;
		
		while not endfile(prog_file) loop
			readLine(prog_file, L);
			--Reads 25 bit line and puts it into tmpv
			read(L, tmpv);
			--Checks for overflow
			if addr_i < IB_DEPTH then
				--Converts
				load_addr <= to_unsigned(addr_i, load_addr'length);
				--Drive the istruction to be written
				load_data <= tmpv;
				wait for CLK_PERIOD;
				report "Loaded instr[" & integer'image(addr_i) & "] = " & func_to_string(tmpv) severity note;
				--Move to the next line in memory
				addr_i := addr_i + 1;
			--If overflow is detected
			else
				report "Warning: program.bin has more than 64 lines, extra lines will be ignored" severity warning;
				exit;
			end if;
		end loop;
		
		--Turns off load enable
		load_en <= '0';								   
		report "Finished loading " & integer'image(addr_i) & " instructions from file" severity note;
		
		--Run the instructions
		report "Beginning fetch phase" severity note;
		for i in 0 to 10 loop
			wait until rising_edge(clk);
			wait for 1ns;
			report "Cycle " & integer'image(i) & ": PC =" & integer'image(to_integer(pc_out)) & " instr_out=" & func_to_string(instr_out) severity note;
		end loop;
		report "Instruction buffer file-based test completed" severity note;
		wait;
	end process;
end architecture tb;
			
