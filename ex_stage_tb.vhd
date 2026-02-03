library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity ex_stage_tb is
end entity;

architecture tb of ex_stage_tb is

    -- Clock and reset
    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';

    -- ID/EX inputs
    signal idex_rs1_val   : reg128 := (others => '0');
    signal idex_rs2_val   : reg128 := (others => '0');
    signal idex_rs3_val   : reg128 := (others => '0');
    signal idex_rs1_idx   : reg_index_t := (others => '0');
    signal idex_rs2_idx   : reg_index_t := (others => '0');
    signal idex_rs3_idx   : reg_index_t := (others => '0');
    signal idex_opcode_r3 : opcode_field_r3 := OP_NOP;
    signal idex_opcode_r4 : opcode_field_r4 := OP4_MULADD_LOW;
    signal idex_instr     : instr25 := (others => '0');
    signal idex_rd_idx    : reg_index_t := (others => '0');
    signal idex_regWrite  : std_logic := '0';

    -- Previous EX/WB stage inputs (for forwarding)
    signal prev_exwb_rd_idx : reg_index_t := (others => '0');
    signal prev_exwb_rd_val : reg128 := (others => '0');

    -- EX/WB outputs
    signal exwb_rd_idx    : reg_index_t;
    signal exwb_rd_val    : reg128;
    signal exwb_regWrite  : std_logic;

    -- Helper: convert vector to hex string
    function to_hstring(v: std_logic_vector) return string is
        variable result  : string(1 to (v'length + 3)/4);
        variable nibble  : std_logic_vector(3 downto 0);
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

    ----------------------------------------------------------------
    -- Helper functions to build 25-bit instructions for this TB
    ----------------------------------------------------------------
    function make_instr_r3(op : opcode_field_r3) return instr25 is
        variable i : instr25;
    begin
        i := (others => '0');
        i(24) := '1';             -- not immediate
        i(23) := '1';             -- R3 group
        i(22 downto 15) := op;    -- opcode field
        return i;
    end function;

    function make_instr_r4(op : opcode_field_r4) return instr25 is
        variable i : instr25;
    begin
        i := (others => '0');
        i(24) := '1';             -- not immediate
        i(23) := '0';             -- R4 group
        i(22 downto 20) := op;    -- opcode field
        return i;
    end function;

begin

    ----------------------------------------------------------------
    -- Clock generator: 10 ns period
    ----------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- DUT: ex_stage
    ----------------------------------------------------------------
    dut : entity work.ex_stage
        port map(
            clk              => clk,
            reset            => reset,
            idex_rs1_val     => idex_rs1_val,
            idex_rs2_val     => idex_rs2_val,
            idex_rs3_val     => idex_rs3_val,
            idex_rs1_idx     => idex_rs1_idx,
            idex_rs2_idx     => idex_rs2_idx,
            idex_rs3_idx     => idex_rs3_idx,
            idex_opcode_r3   => idex_opcode_r3,
            idex_opcode_r4   => idex_opcode_r4,
            idex_instr       => idex_instr,
            idex_rd_idx      => idex_rd_idx,
            idex_regWrite    => idex_regWrite,
            prev_exwb_rd_idx => prev_exwb_rd_idx,
            prev_exwb_rd_val => prev_exwb_rd_val,
            exwb_rd_idx      => exwb_rd_idx,
            exwb_rd_val      => exwb_rd_val,
            exwb_regWrite    => exwb_regWrite
        );

    ----------------------------------------------------------------
    -- Stimulus
    ----------------------------------------------------------------
    stim_proc : process
    begin
        -- Global reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        ----------------------------------------------------------------
        -- Test 1: R3 OR via ex_stage (no forwarding)
        ----------------------------------------------------------------
        report "EX_STAGE Test 1: R3 OR (no forwarding)" severity note;
        idex_rs1_val  <= x"0000000000000000000000000000000F";
        idex_rs2_val  <= x"000000000000000000000000000000F0";
        idex_rs3_val  <= (others => '0');
        idex_rs1_idx  <= "00001";
        idex_rs2_idx  <= "00010";
        idex_rs3_idx  <= "00011";
        idex_rd_idx   <= "00100";
        idex_opcode_r3 <= OP_OR;
        idex_instr    <= make_instr_r3(OP_OR);
        idex_regWrite <= '1';

        prev_exwb_rd_idx <= (others => '0');
        prev_exwb_rd_val <= (others => '0');
        wait for 20 ns;  -- 2 cycles

        report "EXWB Result (OR): " & to_hstring(exwb_rd_val);
        assert exwb_rd_val = x"000000000000000000000000000000FF"
            report "EX_STAGE Test 1 FAILED: OR result mismatch" severity failure;

        ----------------------------------------------------------------
        -- Test 2: R3 OR with forwarding on rs1
        ----------------------------------------------------------------
        report "EX_STAGE Test 2: R3 OR with forwarding on rs1" severity note;
        -- Old ID/EX rs1_val will be overridden by forwarding
        idex_rs1_val  <= x"DEADBEEFDEADBEEFDEADBEEFDEADBEEF";
        idex_rs2_val  <= x"0000000000000000000000000000000F";
        idex_rs3_val  <= (others => '0');

        idex_rs1_idx  <= "00110";
        idex_rs2_idx  <= "00010";
        idex_rs3_idx  <= "00011";
        idex_rd_idx   <= "01000";
        idex_opcode_r3 <= OP_OR;
        idex_instr    <= make_instr_r3(OP_OR);
        idex_regWrite <= '1';

        -- Previous EX/WB wrote register 6 with this value
        prev_exwb_rd_idx <= "00110";
        prev_exwb_rd_val <= x"000000000000000000000000000000F0";

        wait for 20 ns;

        report "EXWB Result (OR with forwarding): " & to_hstring(exwb_rd_val);
        assert exwb_rd_val = x"000000000000000000000000000000FF"
            report "EX_STAGE Test 2 FAILED: forwarding on rs1 did not occur" severity failure;

        ----------------------------------------------------------------
        -- Test 3: R4 MULADD_LOW via ex_stage (no forwarding)
        ----------------------------------------------------------------
        report "EX_STAGE Test 3: R4 MULADD_LOW (no forwarding)" severity note;
        idex_rs1_val <= x"00000005000000050000000500000005";  
        idex_rs2_val <= x"00000004000000040000000400000004";  
        idex_rs3_val <= x"00000003000000030000000300000003";  
        idex_rs1_idx <= "00001";
        idex_rs2_idx <= "00010";
        idex_rs3_idx <= "00011";
        idex_rd_idx  <= "00101";
        idex_opcode_r4 <= OP4_MULADD_LOW;
        idex_instr   <= make_instr_r4(OP4_MULADD_LOW);
        idex_regWrite <= '1';

        prev_exwb_rd_idx <= (others => '0');
        prev_exwb_rd_val <= (others => '0');
        wait for 20 ns;

        report "EXWB Result (MULADD_LOW): " & to_hstring(exwb_rd_val);
        assert exwb_rd_val = x"00000011000000110000001100000011"
            report "EX_STAGE Test 3 FAILED: MULADD_LOW mismatch" severity failure;

        ----------------------------------------------------------------
        -- Test 4: R4 MULADD_LOW with forwarding on rs1
        ----------------------------------------------------------------
        report "EX_STAGE Test 4: R4 MULADD_LOW with forwarding on rs1" severity note;

        -- Previous EX/WB wrote register 9 with this value
        prev_exwb_rd_idx <= "01001";  -- 9
        prev_exwb_rd_val <= x"11112222333344445555666677778888";

        -- ID/EX sources: rs1 reads reg 9 (should be forwarded),
        -- rs2 is zero (so product = 0 and result = rs1), rs3 arbitrary
        idex_rs1_idx  <= "01001";  -- same as prev_exwb_rd_idx
        idex_rs2_idx  <= "00010";
        idex_rs3_idx  <= "00011";

        idex_rs1_val  <= (others => '0');  -- will be overridden by forwarding
        idex_rs2_val  <= (others => '0');  -- multiplicand = 0 -> prod = 0
        idex_rs3_val  <= x"00000001000000010000000100000001";

        idex_rd_idx   <= "01100";       
        idex_opcode_r4 <= OP4_MULADD_LOW;
        idex_instr    <= make_instr_r4(OP4_MULADD_LOW);
        idex_regWrite <= '1';

        wait for 20 ns;

        report "EXWB Result (MULADD_LOW with forwarding): " & to_hstring(exwb_rd_val);
        assert exwb_rd_val = x"11112222333344445555666677778888"
            report "EX_STAGE Test 4 FAILED: R4 forwarding on rs1 did not occur" severity failure;

        ----------------------------------------------------------------
        -- Done
        ----------------------------------------------------------------
        report "ALL EX_STAGE TESTS PASSED" severity note;
        wait;
    end process;

end architecture tb;
