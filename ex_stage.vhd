library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity ex_stage is
    port(
        clk : in std_logic;
        reset : in std_logic;
        
        --Inputs from pipeline register
        idex_rs1_val : in reg128;
        idex_rs2_val : in reg128;
        idex_rs3_val : in reg128;
        idex_rs1_idx : in reg_index_t;
        idex_rs2_idx : in reg_index_t;
        idex_rs3_idx : in reg_index_t;
        idex_opcode_r3 : in opcode_field_r3;
        idex_opcode_r4 : in opcode_field_r4;
        -- full 25-bit instruction from ID/EX
        idex_instr : in instr25;
        idex_rd_idx : in reg_index_t;
        idex_regWrite : in std_logic; 
        
        --From previous EX/WB stage
        prev_exwb_rd_idx : in reg_index_t;
        prev_exwb_rd_val : in reg128;
        
        --Outputs to EX/WB pipeline register
        exwb_rd_idx : out reg_index_t;
        exwb_rd_val : out reg128;
        exwb_regWrite : out std_logic
    );
end entity;

architecture rtl of ex_stage is    

    ----------------------------------------------------------------
    -- Helper conversion functions (unchanged)
    ----------------------------------------------------------------
    function slv_to_bv(s : std_logic_vector) return bit_vector is
        variable r : bit_vector(s'range);
    begin
        for i in s'range loop
            if s(i) = '1' then
                r(i) := '1';
            else
                r(i) := '0';
            end if;
        end loop;
        return r;
    end function;

    function bv_to_slv(b : bit_vector) return std_logic_vector is
        variable r : std_logic_vector(b'range);
    begin
        for i in b'range loop
            if b(i) = '1' then
                r(i) := '1';
            else
                r(i) := '0';
            end if;
        end loop;
        return r;
    end function;
    
    ----------------------------------------------------------------
    -- Signals
    ----------------------------------------------------------------
    signal fwd_ctrl_signal : std_logic_vector(1 downto 0);
    signal fwd_rd_bv       : bit_vector(4 downto 0);
    signal fwd_rs1_bv      : bit_vector(4 downto 0);
    signal fwd_rs2_bv      : bit_vector(4 downto 0);
    signal fwd_rs3_bv      : bit_vector(4 downto 0);
    signal fwd_busD_bv     : bit_vector(127 downto 0);
    signal fwd_S1_in_bv    : bit_vector(127 downto 0);
    signal fwd_S2_in_bv    : bit_vector(127 downto 0);
    signal fwd_S3_in_bv    : bit_vector(127 downto 0);
    signal fwd_S1_out_bv   : bit_vector(127 downto 0);
    signal fwd_S2_out_bv   : bit_vector(127 downto 0);
    signal fwd_S3_out_bv   : bit_vector(127 downto 0);

    signal alu_rs1 : reg128 := (others => '0');
    signal alu_rs2 : reg128 := (others => '0');
    signal alu_rs3 : reg128 := (others => '0');
    signal alu_rd  : reg128 := (others => '0'); 

begin
    ----------------------------------------------------------------
    -- Forwarding Control
    ----------------------------------------------------------------
    fwd_ctrl_signal <= 
        "10" when (idex_instr(24) = '1' and idex_instr(23) = '0') else
        "11" when (idex_instr(24) = '1' and idex_instr(23) = '1') else
        "11";

    ----------------------------------------------------------------
    -- Drive vector signals
    ----------------------------------------------------------------
    fwd_rd_bv    <= slv_to_bv(prev_exwb_rd_idx);
    fwd_rs1_bv   <= slv_to_bv(idex_rs1_idx);
    fwd_rs2_bv   <= slv_to_bv(idex_rs2_idx);
    fwd_rs3_bv   <= slv_to_bv(idex_rs3_idx);
    fwd_busD_bv  <= slv_to_bv(prev_exwb_rd_val);
    fwd_S1_in_bv <= slv_to_bv(idex_rs1_val);
    fwd_S2_in_bv <= slv_to_bv(idex_rs2_val);
    fwd_S3_in_bv <= slv_to_bv(idex_rs3_val);
    
    ----------------------------------------------------------------
    -- Forwarding mux instance
    ----------------------------------------------------------------
    fwd_inst : entity work.forwarding_muxs
        port map (
            ctrl_signal => fwd_ctrl_signal,
            rd          => fwd_rd_bv,
            rs1         => fwd_rs1_bv,
            rs2         => fwd_rs2_bv,
            rs3         => fwd_rs3_bv,
            busD        => fwd_busD_bv,
            busS1_in    => fwd_S1_in_bv,
            busS2_in    => fwd_S2_in_bv,
            busS3_in    => fwd_S3_in_bv,
            busS1_out   => fwd_S1_out_bv,
            busS2_out   => fwd_S2_out_bv,
            busS3_out   => fwd_S3_out_bv
        ); 
    
    ----------------------------------------------------------------
    -- Convert forwarded outputs back to std_logic_vector for the ALU
    ----------------------------------------------------------------
    alu_rs1 <= bv_to_slv(fwd_S1_out_bv);
    alu_rs2 <= bv_to_slv(fwd_S2_out_bv);
    alu_rs3 <= bv_to_slv(fwd_S3_out_bv);

    ----------------------------------------------------------------
    -- ALU instance
    ----------------------------------------------------------------
    alu_map : entity work.multimedia_alu
        port map( 
            rs1   => alu_rs1,
            rs2   => alu_rs2,
            rs3   => alu_rs3,
            instr => idex_instr,
            rd    => alu_rd
        );
        
    ----------------------------------------------------------------
    -- EX/WB register results
    ----------------------------------------------------------------
    exwb_reg_proc : process(clk, reset)
    begin
        if reset = '1' then
            exwb_rd_idx   <= (others => '0');
            exwb_rd_val   <= (others => '0');
            exwb_regWrite <= '0';
        elsif rising_edge(clk) then
            exwb_rd_idx   <= idex_rd_idx;
            exwb_rd_val   <= alu_rd;
            exwb_regWrite <= idex_regWrite;
        end if;
    end process;

end architecture rtl;
