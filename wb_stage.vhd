library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.alu_operations_pkg.all;

entity wb_stage is
	port(
	--Inputs from EX/WB pipeline register
	exwb_rd_idx : in reg_index_t;
	exwb_rd_val : in reg128;
	exwb_regWrite : in std_logic;
	--Outputs to register file
	rf_write_en : out std_logic;
	rf_rd_idx : out reg_index_t;
	rf_busD : out reg128);
end entity;

architecture behavioral of wb_stage is
begin
	--Write back information transfer
	rf_write_en <= exwb_regWrite;
    rf_rd_idx <= exwb_rd_idx;
    rf_busD <= exwb_rd_val;
end behavioral;
