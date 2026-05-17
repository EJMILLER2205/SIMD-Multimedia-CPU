# SIMD Multimedia CPU - VHDL, C++

This project implements a custom **4-stage pipelined SIMD multimedia CPU** in VHDL, along with a **C++ assembler** that converts human-readable assembly programs into 25-bit binary machine code. The processor operates on **32 general-purpose 128-bit registers** and supports packed multimedia-style arithmetic, logic, shifting, counting, rotate, multiply, multiply-accumulate, and saturating operations.

The design is organized as a full fetch-to-writeback datapath with instruction buffering, decode logic, register-file access, execution-stage forwarding, writeback control, and self-checking testbenches.

## Key Features

- 4-stage pipeline:
  - **IF** - Instruction Fetch
  - **ID** - Instruction Decode / Register Read
  - **EX** - Execute, ALU, and forwarding resolution
  - **WB** - Write Back
- **32 x 128-bit register file**
- **25-bit custom instruction format**
- Support for:
  - **LI** immediate lane loading
  - **R3** three-register multimedia instructions
  - **R4** four-register multiply-accumulate and multiply-subtract instructions
- Data forwarding logic for resolving back-to-back register dependencies in R3 and R4 instruction sequences
- Modular VHDL components for the instruction buffer, pipeline registers, register file, execution stage, forwarding muxes, ALU, and writeback stage
- Custom C++ assembler that reads `program.asm` and outputs `program.bin`
- Unit-level and full-pipeline verification using self-checking VHDL testbenches

## Architecture Overview

The top-level processor is implemented in `multimedia_pipeline.vhd`.

```text
Instruction Buffer
       |
      IF
       |
   IF/ID Register
       |
      ID  ---> Register File
       |
   ID/EX Register
       |
      EX  ---> Forwarding Muxes ---> Multimedia ALU
       |
   EX/WB Register
       |
      WB
       |
  Register File Writeback
```

### Pipeline Stages

| Stage | Main Responsibilities |
|---|---|
| IF | Fetches a 25-bit instruction from the instruction buffer using the program counter |
| ID | Decodes instruction fields, identifies register operands, and reads source values from the register file |
| EX | Applies forwarding when needed and executes the instruction through the multimedia ALU |
| WB | Writes the final 128-bit result back into the destination register |

## Datapath Components

| File | Purpose |
|---|---|
| `multimedia_pipeline.vhd` | Top-level 4-stage CPU integration |
| `instr_buffer.vhd` | 64-entry instruction memory and program counter |
| `ifid_reg.vhd` | IF/ID pipeline register |
| `idex_reg.vhd` | ID/EX pipeline register |
| `ex_stage.vhd` | Execution-stage integration of forwarding and ALU output capture |
| `exwb_reg.vhd` | EX/WB pipeline register module |
| `wb_stage.vhd` | Writeback fanout into the register file interface |
| `register_file.vhd` | 32-register, 128-bit-wide register file |
| `forwarding_muxs.vhd` | Dependency forwarding for R3 and R4 instruction operands |
| `multimedia_alu.vhd` | SIMD ALU implementing the custom instruction set |
| `alu_operations_pkg.vhd` | Shared datatypes, opcode constants, and processor-wide definitions |

## Instruction Formats

All instructions are encoded as **25-bit words**.

### LI Format

`LI rd, imm16, loadIdx`

| Bits | Field |
|---|---|
| `[24]` | `0` for LI |
| `[23:21]` | 16-bit lane index |
| `[20:5]` | Immediate value |
| `[4:0]` | Destination register |

`LI` writes a 16-bit immediate into one selected lane of a 128-bit destination register.

### R3 Format

`OP rd, rs1, rs2`

| Bits | Field |
|---|---|
| `[24]` | `1` |
| `[23]` | `1` for R3 |
| `[22:15]` | R3 opcode |
| `[14:10]` | `rs2` field or instruction-specific immediate field |
| `[9:5]` | `rs1` |
| `[4:0]` | `rd` |

Special R3 encodings include:
- `SHRHI rd, rs1, shamt`
- `MLHCU rd, rs1, imm5`
- `BCW rd, rs1`
- `NOP`

### R4 Format

`OP rd, rs1, rs2, rs3`

| Bits | Field |
|---|---|
| `[24]` | `1` |
| `[23]` | `0` for R4 |
| `[22:20]` | R4 opcode |
| `[19:15]` | `rs3` |
| `[14:10]` | `rs2` |
| `[9:5]` | `rs1` |
| `[4:0]` | `rd` |

## Supported Instruction Set

### Immediate Instruction

| Mnemonic | Description |
|---|---|
| `LI` | Load a 16-bit immediate into one selected halfword lane of a 128-bit register |

### R3 Instructions

| Mnemonic | Description |
|---|---|
| `NOP` | No operation |
| `SHRHI` | Shift each 16-bit halfword lane right by an immediate shift amount |
| `AU` | Packed unsigned addition across 32-bit lanes |
| `CNT1H` | Count set bits within each 16-bit halfword |
| `AHS` | Packed signed halfword addition with saturation |
| `OR` | Bitwise OR |
| `BCW` | Broadcast the upper 32-bit word of `rs1` into all four 32-bit lanes |
| `MAXWS` | Packed signed maximum across 32-bit lanes |
| `MINWS` | Packed signed minimum across 32-bit lanes |
| `MLHU` | Multiply low unsigned halfwords into 32-bit lane results |
| `MLHCU` | Multiply low unsigned halfwords by a 5-bit constant |
| `AND` | Bitwise AND |
| `CLZW` | Count leading zeros within each 32-bit word |
| `ROTW` | Rotate each 32-bit word using a per-lane shift value |
| `SFWU` | Packed unsigned fullword subtraction |
| `SFHS` | Packed signed halfword subtraction with saturation |

### R4 Instructions

| Mnemonic | Description |
|---|---|
| `MADDL` | Multiply low signed halfwords and add to 32-bit accumulators |
| `MADDH` | Multiply high signed halfwords and add to 32-bit accumulators |
| `MSUBL` | Multiply low signed halfwords and subtract from 32-bit accumulators |
| `MSUBH` | Multiply high signed halfwords and subtract from 32-bit accumulators |
| `MLADDL` | Long multiply-add using low signed 32-bit operands into 64-bit lanes |
| `MLADDH` | Long multiply-add using high signed 32-bit operands into 64-bit lanes |
| `MLSUBL` | Long multiply-subtract using low signed 32-bit operands into 64-bit lanes |
| `MLSUBH` | Long multiply-subtract using high signed 32-bit operands into 64-bit lanes |

## Forwarding Support

The execution stage includes forwarding logic to handle read-after-write hazards between adjacent instructions. The forwarding network compares the destination register from the prior EX/WB result against the current source-register indices and substitutes the newest available 128-bit result when needed.

Forwarding is supported for:
- R3 instructions using `rs1` and `rs2`
- R4 instructions using `rs1`, `rs2`, and `rs3`

Dedicated forwarding test programs are included to validate dependency chains without requiring inserted bubbles or manual register delays.

## C++ Assembler

The assembler is implemented in `assembler.cpp`.

It:
- Reads assembly from `program.asm`
- Outputs one 25-bit binary instruction per line to `program.bin`
- Supports LI, R3, and R4 instruction formats
- Accepts comments beginning with `#` or `//`
- Supports decimal and hexadecimal immediates
- Accepts register names in the form `r0` through `r31`
- Produces line-specific errors for malformed or unknown instructions

### Build the Assembler

```bash
g++ -std=c++17 assembler.cpp -o assembler
```

### Assemble a Program

Rename or copy one of the included `.asm` files to `program.asm`, then run:

```bash
./assembler
```

This generates:

```text
program.bin
```

## Example Assembly

```asm
LI r2, 5, 0
AHS r10, r2, r2
MLHU r16, r2, r2
AND r24, r16, r2
OR r30, r10, r24
SFWU r12, r10, r16
```

This sample creates a short R3 forwarding dependency chain and is representative of the included R3 forwarding regression program.

## Verification and Testbench Coverage

The project includes both module-level and full-system testbenches.

| Testbench | Verification Focus |
|---|---|
| `multimedia_alu_tb.vhd` | LI, R3, R4, saturation behavior, shifts, rotates, counts, max/min, and multiply variants |
| `register_file_tb.vhd` | Register writes and multi-source reads |
| `forwarding_muxs_tb.vhd` | Forwarding behavior across many R3 and R4 source/destination dependency cases |
| `ex_stage_tb.vhd` | EX-stage ALU integration and forwarding behavior |
| `wb_stage_tb.vhd` | Writeback output passthrough and write-enable control |
| `instr_buffer_tb.vhd` | Instruction loading from `program.bin` and fetch sequencing |
| `multimedia_pipeline_tb.vhd` | Full processor execution, register-file result checking, and pipeline debug logging |

## End-to-End Pipeline Regression Flow

The full pipeline testbench uses:
- `program.bin` as the instruction stream
- `rf_expected.hex` as the expected final register-file state

A typical flow is:

1. Choose one of the assembly programs:
   - `R3Program.asm`
   - `R4Program.asm`
   - `R3_Forwarding_Test_Program.asm`
   - `R4ForwardingTestProgram.asm`

2. Copy the selected file to:
   ```text
   program.asm
   ```

3. Assemble it:
   ```bash
   ./assembler
   ```

4. Copy the matching expected register dump to:
   ```text
   rf_expected.hex
   ```

5. Run:
   ```text
   multimedia_pipeline_tb.vhd
   ```

The pipeline testbench mirrors register-file writes, compares the final 32-register state against the expected hex file, and writes cycle-by-cycle debug output to:

```text
pipeline_results.txt
```

## Included Assembly Regression Programs

| File | Purpose |
|---|---|
| `R3Program.asm` | Exercises the complete R3 instruction group |
| `R4Program.asm` | Exercises the complete R4 instruction group |
| `R3_Forwarding_Test_Program.asm` | Tests forwarding through dependent R3 instruction chains |
| `R4ForwardingTestProgram.asm` | Tests forwarding through dependent R4 instruction chains |

Matching expected register dumps are provided in `.hex` files.

## Repository Highlights

This project demonstrates:
- Custom CPU architecture design in VHDL
- SIMD-style packed arithmetic over 128-bit registers
- Pipeline partitioning and interstage register design
- Data hazard handling through forwarding logic
- Custom instruction encoding and assembler development
- Self-checking verification methodology
- End-to-end assembly-to-simulation execution flow
