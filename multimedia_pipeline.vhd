library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity multimedia_pipeline is
    port(
        clk          : in std_logic;
        reset        : in std_logic;
        ib_load_en   : in std_logic;
        ib_load_addr : in pc_t;
        ib_load_data : in instr25;
		
		--Debug signals
		rf_write_en_dbg : out std_logic;
		rf_rd_idx_dbg : out reg_index_t;
		rf_busD_dbg : out reg128;
		
		dbg_if_instr     : out instr25;
        dbg_ifid_instr   : out instr25;
        dbg_idex_instr   : out instr25;
        dbg_idex_rs1_val : out reg128;
        dbg_idex_rs2_val : out reg128;
        dbg_idex_rs3_val : out reg128;
        dbg_exwb_rd_idx  : out reg_index_t;
        dbg_exwb_rd_val  : out reg128;
        dbg_exwb_regWrite: out std_logic;
        dbg_ctrl_signal  : out std_logic_vector(1 downto 0)
    );
end multimedia_pipeline;

architecture structural of multimedia_pipeline is

--Helper functions
	--Logic vector to but vector
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
	
	--Bit vector to logic vector
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
    -- IF stage / IF/ID register
    ----------------------------------------------------------------
    signal if_pc      : pc_t; --program counter from instruction buffer
    signal if_instr   : instr25; --Current fetched instruction from instruction buffer
    signal ifid_instr : instr25 := (others => '0'); --Instruction seen by ID stage next cycle

    ----------------------------------------------------------------
    -- ID stage
    ----------------------------------------------------------------
    signal id_rs1_idx, id_rs2_idx, id_rs3_idx, id_rd_idx : reg_index_t := (others => '0'); --Registers
    signal id_regWrite : std_logic := '1'; --Write enable
    signal rf_busS1_bv, rf_busS2_bv, rf_busS3_bv : bit_vector(127 downto 0); --Bit vector data
    signal rf_busD_bv : bit_vector(127 downto 0); --Desitnation data
    signal rf_rdata1, rf_rdata2, rf_rdata3 : reg128 := (others => '0'); --Final data

    ----------------------------------------------------------------
    -- ID/EX register outputs
    ----------------------------------------------------------------
    signal idex_instr   : instr25 := (others => '0'); --ID/EX instruction
    signal idex_rs1_val : reg128  := (others => '0'); --Register values
    signal idex_rs2_val : reg128  := (others => '0');
    signal idex_rs3_val : reg128  := (others => '0');
    signal idex_rs1_idx, idex_rs2_idx, idex_rs3_idx, idex_rd_idx : reg_index_t := (others => '0'); --Index values
    signal idex_regWrite : std_logic := '0'; --Enable reg write

    ----------------------------------------------------------------
    -- EX/WB pipeline register and WB stage signals
    ----------------------------------------------------------------
    signal exwb_rd_idx   : reg_index_t := (others => '0'); --Destination register index
    signal exwb_rd_val   : reg128      := (others => '0'); --Destination register value
    signal exwb_regWrite : std_logic   := '0'; --Register write enable

    signal rf_write_en : std_logic;
    signal rf_rd_idx   : reg_index_t;
    signal rf_busD     : reg128;

begin

    ----------------------------------------------------------------
    -- IF: instruction buffer
    ----------------------------------------------------------------
    ibuf : entity work.instr_buffer
        port map(
            clk       => clk,
            reset     => reset,
            instr_out => if_instr,
            pc_out    => if_pc,
            load_en   => ib_load_en,
            load_addr => ib_load_addr,
            load_data => ib_load_data
        );

    ----------------------------------------------------------------
    -- IF/ID pipeline register
    ----------------------------------------------------------------
    ifid : entity work.ifid_reg
        port map(
            clk            => clk,
            ifid_instr_in  => if_instr,
            ifid_instr_out => ifid_instr
        );

    ----------------------------------------------------------------
    -- Simple ID stage decode (with special case for LI)
    ----------------------------------------------------------------
    decode_proc : process(ifid_instr)
    begin
        -- rd is always bits [4:0]
        id_rd_idx <= ifid_instr(4 downto 0);

        if ifid_instr(24) = '0' then
            ----------------------------------------------------------------
            -- LI format:
            -- bit 24 = 0
            -- [23..21] = load index
            -- [20..5]  = imm16
            -- [4..0]   = rd
            -- ALU uses rs1 as "old rd", so rs1 must point to rd
            ----------------------------------------------------------------
            id_rs1_idx <= ifid_instr(4 downto 0);  -- rs1 = rd (read old value)
            id_rs2_idx <= (others => '0');         -- unused for LI
            id_rs3_idx <= (others => '0');         -- unused for LI

        elsif ifid_instr(24) = '1' and ifid_instr(23) = '0' then
            ----------------------------------------------------------------
            -- R4 format: [22..20] opcode, [19..15] rs3, [14..10] rs2, [9..5] rs1
            ----------------------------------------------------------------
            id_rs1_idx <= ifid_instr(9  downto 5);
            id_rs2_idx <= ifid_instr(14 downto 10);
            id_rs3_idx <= ifid_instr(19 downto 15);

        else
            ----------------------------------------------------------------
            -- R3 format: [22..15] opcode, [14..10] rs2, [9..5] rs1, no rs3
            ----------------------------------------------------------------
            id_rs1_idx <= ifid_instr(9  downto 5);
            id_rs2_idx <= ifid_instr(14 downto 10);
            id_rs3_idx <= (others => '0');
        end if;
    end process;

    ----------------------------------------------------------------
    -- Register file (bit_vector interface)
    ----------------------------------------------------------------
    reg_file : entity work.register_file
        port map(
            write_en => rf_write_en,
            rd       => slv_to_bv(rf_rd_idx),
            rs1      => slv_to_bv(id_rs1_idx),
            rs2      => slv_to_bv(id_rs2_idx),
            rs3      => slv_to_bv(id_rs3_idx),
            busD     => rf_busD_bv,
            busS1    => rf_busS1_bv,
            busS2    => rf_busS2_bv,
            busS3    => rf_busS3_bv
        );

    -- Convert RF outputs back to std_logic_vector form
    rf_rdata1 <= bv_to_slv(rf_busS1_bv);
    rf_rdata2 <= bv_to_slv(rf_busS2_bv);
    rf_rdata3 <= bv_to_slv(rf_busS3_bv);

    -- Connect RF write data from WB stage
    rf_busD_bv <= slv_to_bv(rf_busD);

    ----------------------------------------------------------------
    -- ID/EX register for instruction and source operand values
    ----------------------------------------------------------------
    idex : entity work.idex_reg
        port map(
            clk            => clk,
            idex_instr_in  => ifid_instr,
            idex_busS1_in  => rf_rdata1,
            idex_busS2_in  => rf_rdata2,
            idex_busS3_in  => rf_rdata3,
            idex_instr_out => idex_instr,
            idex_busS1_out => idex_rs1_val,
            idex_busS2_out => idex_rs2_val,
            idex_busS3_out => idex_rs3_val
        );

    ----------------------------------------------------------------
    -- Local ID/EX control pipeline for indices + regWrite
    ----------------------------------------------------------------
    idex_ctrl_reg : process(clk, reset)
    begin
        if reset = '1' then
            idex_rs1_idx  <= (others => '0');
            idex_rs2_idx  <= (others => '0');
            idex_rs3_idx  <= (others => '0');
            idex_rd_idx   <= (others => '0');
            idex_regWrite <= '0';
        elsif rising_edge(clk) then
            idex_rs1_idx  <= id_rs1_idx;
            idex_rs2_idx  <= id_rs2_idx;
            idex_rs3_idx  <= id_rs3_idx;
            idex_rd_idx   <= id_rd_idx;
            idex_regWrite <= id_regWrite;
        end if;
    end process;

    ----------------------------------------------------------------
    -- EX stage (includes forwarding + ALU + EX/WB reg)
    ----------------------------------------------------------------
    ex_stage_inst : entity work.ex_stage
        port map(
            clk              => clk,
            reset            => reset,
            idex_rs1_val     => idex_rs1_val,
            idex_rs2_val     => idex_rs2_val,
            idex_rs3_val     => idex_rs3_val,
            idex_rs1_idx     => idex_rs1_idx,
            idex_rs2_idx     => idex_rs2_idx,
            idex_rs3_idx     => idex_rs3_idx,
            idex_opcode_r3   => idex_instr(22 downto 15),
            idex_opcode_r4   => idex_instr(22 downto 20),
            idex_instr       => idex_instr,
            idex_rd_idx      => idex_rd_idx,
            idex_regWrite    => idex_regWrite,
            prev_exwb_rd_idx => exwb_rd_idx,
            prev_exwb_rd_val => exwb_rd_val,
            exwb_rd_idx      => exwb_rd_idx,
            exwb_rd_val      => exwb_rd_val,
            exwb_regWrite    => exwb_regWrite
        );

    ----------------------------------------------------------------
    -- WB stage: fan EX/WB register out to register file interface
    ----------------------------------------------------------------
    wb_stage_inst : entity work.wb_stage
        port map(
            exwb_rd_idx   => exwb_rd_idx,
            exwb_rd_val   => exwb_rd_val,
            exwb_regWrite => exwb_regWrite,
            rf_write_en   => rf_write_en,
            rf_rd_idx     => rf_rd_idx,
            rf_busD       => rf_busD
        );
		
	--Debug values
	rf_write_en_dbg <= rf_write_en;
	rf_rd_idx_dbg <= rf_rd_idx;
	rf_busD_dbg <= rf_busD;
	dbg_if_instr      <= if_instr;
    dbg_ifid_instr    <= ifid_instr;
    dbg_idex_instr    <= idex_instr;
    dbg_idex_rs1_val  <= idex_rs1_val;
    dbg_idex_rs2_val  <= idex_rs2_val;
    dbg_idex_rs3_val  <= idex_rs3_val;
    dbg_exwb_rd_idx   <= exwb_rd_idx;
    dbg_exwb_rd_val   <= exwb_rd_val;
    dbg_exwb_regWrite <= exwb_regWrite;
    dbg_ctrl_signal   <= idex_instr(24 downto 23);
end architecture structural;
