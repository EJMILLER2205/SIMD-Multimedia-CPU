library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

use work.alu_operations_pkg.all;

entity multimedia_pipeline_tb is
end entity;

architecture tb of multimedia_pipeline_tb is
    ----------------------------------------------------------------
    -- DUT interface signals
    ----------------------------------------------------------------
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal ib_load_en   : std_logic := '0';
    signal ib_load_addr : pc_t      := (others => '0');
    signal ib_load_data : instr25   := (others => '0');

    -- Debug signals from DUT (WB stage)
    signal rf_write_en_dbg : std_logic;
    signal rf_rd_idx_dbg   : reg_index_t;
    signal rf_busD_dbg     : reg128;

    constant period : time := CLK_PERIOD;

    ----------------------------------------------------------------
    -- Shadow register file to mirror RF writes
    ----------------------------------------------------------------
    type regfile_t is array (0 to 31) of reg128;
    signal test_rf : regfile_t := (others => (others => '0'));

    ----------------------------------------------------------------
    -- Pipeline debug signals from DUT
    ----------------------------------------------------------------
    signal dbg_if_instr      : instr25         := (others => '0');
    signal dbg_ifid_instr    : instr25         := (others => '0');
    signal dbg_idex_instr    : instr25         := (others => '0');
    signal dbg_idex_rs1_val  : reg128          := (others => '0');
    signal dbg_idex_rs2_val  : reg128          := (others => '0');
    signal dbg_idex_rs3_val  : reg128          := (others => '0');
    signal dbg_exwb_rd_idx   : reg_index_t     := (others => '0');
    signal dbg_exwb_rd_val   : reg128          := (others => '0');
    signal dbg_exwb_regWrite : std_logic       := '0';
    signal dbg_ctrl_signal   : std_logic_vector(1 downto 0) := (others => '0');

    -- Flag to enable pipeline tracing only during execution
    signal trace_on : std_logic := '0';

    ----------------------------------------------------------------
    -- Helper: convert std_logic_vector (multiple of 4 bits) to hex
    ----------------------------------------------------------------
    function slv_to_hex(v : std_logic_vector) return string is
        constant N : integer := (v'length + 3) / 4;
        variable result : string(1 to N);
        variable nibble : std_logic_vector(3 downto 0);
        variable hexchar : character;
    begin
        for i in 0 to N-1 loop
            nibble := v(v'left - 4*i downto v'left - 4*i - 3);
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
            result(i+1) := hexchar;
        end loop;
        return result;
    end function;

    ----------------------------------------------------------------
    -- Helper: print 25-bit instruction as 8-digit hex (pad to 32 bits)
    ----------------------------------------------------------------
    function instr_to_hex(v : std_logic_vector(24 downto 0)) return string is
        variable tmp : std_logic_vector(31 downto 0);
    begin
        tmp := std_logic_vector(resize(unsigned(v), 32));
        return slv_to_hex(tmp);
    end function;

begin
    ----------------------------------------------------------------
    -- DUT instantiation
    ----------------------------------------------------------------
    dut : entity work.multimedia_pipeline
        port map(
            clk             => clk,
            reset           => reset,
            ib_load_en      => ib_load_en,
            ib_load_addr    => ib_load_addr,
            ib_load_data    => ib_load_data,
            rf_write_en_dbg => rf_write_en_dbg,
            rf_rd_idx_dbg   => rf_rd_idx_dbg,
            rf_busD_dbg     => rf_busD_dbg,
            dbg_if_instr      => dbg_if_instr,
            dbg_ifid_instr    => dbg_ifid_instr,
            dbg_idex_instr    => dbg_idex_instr,
            dbg_idex_rs1_val  => dbg_idex_rs1_val,
            dbg_idex_rs2_val  => dbg_idex_rs2_val,
            dbg_idex_rs3_val  => dbg_idex_rs3_val,
            dbg_exwb_rd_idx   => dbg_exwb_rd_idx,
            dbg_exwb_rd_val   => dbg_exwb_rd_val,
            dbg_exwb_regWrite => dbg_exwb_regWrite,
            dbg_ctrl_signal   => dbg_ctrl_signal
        );

    ----------------------------------------------------------------
    -- Clock generator
    ----------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for period/2;
            clk <= '1';
            wait for period/2;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- Shadow register file update (mirrors RF writes from WB)
    ----------------------------------------------------------------
    shadow_proc : process(clk, reset)
        variable idx : integer;
    begin
        if reset = '1' then
            test_rf <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if rf_write_en_dbg = '1' then
                idx := to_integer(unsigned(rf_rd_idx_dbg));
                if idx >= 0 and idx <= 31 then
                    test_rf(idx) <= rf_busD_dbg;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Results file logger: pipeline status each cycle during execution
    ----------------------------------------------------------------
    results_proc : process
        file results_f : text open write_mode is "pipeline_results.txt";
        variable L     : line;
        variable cycle : integer := 0;
    begin
        -- Wait until the testbench sets trace_on = '1' (start of execution)
        wait until trace_on = '1';
        wait until rising_edge(clk);

        while true loop
            cycle := cycle + 1;

            write(L, string'("Cycle "));
            write(L, cycle);
            write(L, string'(" | IF_instr="));
            write(L, instr_to_hex(dbg_if_instr));

            write(L, string'(" | ID_instr="));
            write(L, instr_to_hex(dbg_ifid_instr));

            write(L, string'(" | EX_instr="));
            write(L, instr_to_hex(dbg_idex_instr));

            write(L, string'(" | EX_rs1="));
            write(L, slv_to_hex(dbg_idex_rs1_val));

            write(L, string'(" | EX_rs2="));
            write(L, slv_to_hex(dbg_idex_rs2_val));

            write(L, string'(" | EX_rs3="));
            write(L, slv_to_hex(dbg_idex_rs3_val));

            write(L, string'(" | WB_rd_idx="));
            write(L, integer'image(to_integer(unsigned(dbg_exwb_rd_idx))));

            write(L, string'(" | WB_rd_val="));
            write(L, slv_to_hex(dbg_exwb_rd_val));

            write(L, string'(" | WB_regWrite="));
            if dbg_exwb_regWrite = '1' then
                write(L, string'("1"));
            else
                write(L, string'("0"));
            end if;

            write(L, string'(" | ctrl_signal="));
            write(L, dbg_ctrl_signal);

            writeline(results_f, L);
            L := null;

            wait until rising_edge(clk);
        end loop;
    end process;

    ----------------------------------------------------------------
    -- Main testbench process: reset, load program, run, compare RF
    ----------------------------------------------------------------
    stim_proc : process
        -- Files
        file prog_file   : text open read_mode is "program.bin";
        file rf_exp_file : text open read_mode is "rf_expected.hex";

        -- Instruction load
        variable L           : line;
        variable instr_bits  : std_logic_vector(24 downto 0);
        variable instr_count : integer := 0;
        variable addr_int    : integer := 0;

        -- Expected RF
        variable rf_line : line;
        variable exp_val : std_logic_vector(127 downto 0);

        variable i : integer;

        -- Helper: wait for n rising edges
        procedure wait_cycles(n : natural) is
        begin
            for k in 1 to n loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        ----------------------------------------------------------------
        -- 1) Global reset BEFORE loading program
        ----------------------------------------------------------------
        report "Resetting" severity note;
        reset      <= '1';
        ib_load_en <= '0';
        wait_cycles(2);
        reset      <= '0';  -- release reset

        ----------------------------------------------------------------
        -- 2) Immediately enable load_en so PC does NOT advance
        ----------------------------------------------------------------
        report "Loading instructions from program.bin into instruction buffer" severity note;
        ib_load_en   <= '1';
        addr_int     := 0;
        instr_count  := 0;

        while not endfile(prog_file) loop
            readline(prog_file, L);
            read(L, instr_bits);

            ib_load_addr <= to_unsigned(addr_int, ib_load_addr'length);
            ib_load_data <= instr_bits;

            wait until rising_edge(clk);

            addr_int    := addr_int + 1;
            instr_count := instr_count + 1;
        end loop;

        ib_load_en <= '0';
        report "Finished loading " & integer'image(instr_count) & " instructions" severity note;

        ----------------------------------------------------------------
        -- 3) Start execution (no further reset; PC stays at 0)
        ----------------------------------------------------------------
        if instr_count = 0 then
            report "No instructions loaded; ending simulation" severity warning;
            wait;
        end if;

        trace_on <= '1';  -- enable tracing for results_proc

        report "Running pipeline for " & integer'image(instr_count * 4 + 4) & " cycles" severity note;
        wait_cycles(instr_count * 4 + 4);

        ----------------------------------------------------------------
        -- 4) Compare shadow RF against expected file
        ----------------------------------------------------------------
        report "Comparing register file against rf_expected.hex" severity note;
        for reg_idx in 0 to 31 loop
            if endfile(rf_exp_file) then
                report "Error: rf_expected.hex has fewer than 32 lines" severity failure;
                wait;
            end if;

            readline(rf_exp_file, rf_line);
            hread(rf_line, exp_val);

            if test_rf(reg_idx) /= exp_val then
                report "Register mismatch: R" & integer'image(reg_idx) &
                       " expected = " & slv_to_hex(exp_val) &
                       " got = "     & slv_to_hex(test_rf(reg_idx))
                       severity error;
            else
                report "Register matches: R" & integer'image(reg_idx) &
                       " = " & slv_to_hex(test_rf(reg_idx))
                       severity note;
            end if;
        end loop;

        if not endfile(rf_exp_file) then
            report "rf_expected.hex has more than 32 lines; extra data ignored" severity warning;
        end if;

        report "Register file comparison complete" severity note;
        report "End of multimedia_pipeline_tb simulation" severity note;
        wait;
    end process;

end architecture tb;
 
