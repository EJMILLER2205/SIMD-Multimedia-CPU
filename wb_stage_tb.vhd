library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity wb_stage_tb is
end entity;

architecture tb of wb_stage_tb is
    --Signals
    signal exwb_rd_idx : reg_index_t := (others => '0');
    signal exwb_rd_val : reg128      := (others => '0');
    signal exwb_regWrite : std_logic   := '0';
    signal rf_write_en : std_logic;
    signal rf_rd_idx : reg_index_t;
    signal rf_busD : reg128;

    --Helper function to convert vector to hex
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

begin
    --Write back
    uut_wb : entity work.wb_stage
        port map (
            exwb_rd_idx   => exwb_rd_idx,
            exwb_rd_val   => exwb_rd_val,
            exwb_regWrite => exwb_regWrite,
            rf_write_en   => rf_write_en,
            rf_rd_idx     => rf_rd_idx,
            rf_busD       => rf_busD
        );

	--Testbench process
    tb_proc : process
        constant period : time := 10 ns;
    begin
        ----------------------------------------------------------------
        -- Test 1: passthrough with regWrite = 1
        ----------------------------------------------------------------
        report "WB Test 1: simple pass-through with regWrite=1" severity note;
        exwb_rd_idx <= "00110";
        exwb_rd_val <= x"00010002000300040005000600070008";
        exwb_regWrite <= '1';

        wait for period;

        report "WB Test 1: rf_busD = " & to_hstring(rf_busD) severity note;

        assert rf_write_en = '1'
            report "WB Test 1 FAILED: rf_write_en not asserted" severity failure;

        assert rf_rd_idx = "00110"
            report "WB Test 1 FAILED: rf_rd_idx mismatch" severity failure;

        assert rf_busD = x"00010002000300040005000600070008"
            report "WB Test 1 FAILED: rf_busD mismatch" severity failure;

        ----------------------------------------------------------------
        -- Test 2: regWrite = 0 (still passes through, but write_en low)
        ----------------------------------------------------------------
        report "WB Test 2: regWrite=0, write enable low" severity note;
        exwb_rd_idx <= "01011";
        exwb_rd_val <= x"91A516D14EF89171614565224651ADEC";
        exwb_regWrite <= '0';

        wait for period;

        report "WB Test 2: rf_busD = " & to_hstring(rf_busD) severity note;

        assert rf_write_en = '0'
            report "WB Test 2 FAILED: rf_write_en should be 0" severity failure;

        assert rf_rd_idx = "01011"
            report "WB Test 2 FAILED: rf_rd_idx mismatch" severity failure;

        assert rf_busD = x"91A516D14EF89171614565224651ADEC"
            report "WB Test 2 FAILED: rf_busD mismatch" severity failure;

        ----------------------------------------------------------------
        -- Test 3: change both index and data again with regWrite=1
        ----------------------------------------------------------------
        report "WB Test 3: another pass-through check" severity note;
        exwb_rd_idx <= "10101";
        exwb_rd_val <= x"1FAB518BDF565484E40CAF547541EB54";
        exwb_regWrite <= '1';

        wait for period;

        report "WB Test 3: rf_busD = " & to_hstring(rf_busD) severity note;

        assert rf_write_en = '1'
            report "WB Test 3 FAILED: rf_write_en not asserted" severity failure;

        assert rf_rd_idx = "10101"
            report "WB Test 3 FAILED: rf_rd_idx mismatch" severity failure;

        assert rf_busD = x"1FAB518BDF565484E40CAF547541EB54"
            report "WB Test 3 FAILED: rf_busD mismatch" severity failure;

        report "ALL WRITE-BACK STAGE TESTS PASSED" severity note;

        wait;
    end process;

end architecture tb;
