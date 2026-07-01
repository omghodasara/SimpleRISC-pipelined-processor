# Custom SimpleRISC 32-bit 5-Stage Pipelined Processor

## Project Overview & Acknowledgements
This repository contains the complete Register Transfer Level (RTL) Verilog implementation and simulation environment for a custom 32-bit, 5-stage pipelined central processing unit. This processor was developed as a comprehensive course project for **Computer Organisation and Architecture**.

The microarchitecture, datapath design, and custom Instruction Set Architecture (ISA) are heavily inspired by and built upon the foundational concepts presented in **Dr. Smruti R. Sarangi’s textbook, *Basic Computer Architecture***. 

##  Design Philosophy: The Car Assembly Analogy
To understand the transition from a standard single-cycle processor to this pipelined architecture, the design mimics a car manufacturing assembly line. Building a processor's datapath follows a similar staged approach:
1. **Build the Chassis:** Casting the raw frame (Instruction Fetch & Decode).
2. **Build the Engine:** Doing the heavy mechanical lifting (Execution/ALU).
3. **Assemble Engine and Chassis:** Bringing the core components together (Memory Access).
4. **Dashboard and Furnishing:** Finalizing the product and writing it down (Register Write-back).

##  Performance & Throughput Analysis
The core objective of pipelining this SimpleRISC processor is to drastically increase instruction execution throughput. 
* **The Single-Cycle Bottleneck:** In a standard single-cycle processor, the total execution time per instruction (Latency) is 5 clock cycles ($5T$). If the clock period $T = 10ns$, the throughput is strictly $1/5T$, yielding only $20$ MIPS (Million Instructions Per Second).

* **The Pipelined Advantage:** By introducing isolating pipeline registers between the 5 independent stages (IF, OF, EX, MA, RW), a new instruction finishes every single clock cycle once the pipeline is full. The throughput becomes $1/T$. At $T = 10ns$, the throughput skyrockets to $100$ MIPS—a 5x theoretical performance gain.

##  The 5-Stage Microarchitecture Deep Dive

### 1. Instruction Fetch Unit (IF)
* **Program Counter (PC):** Holds the current 32-bit execution address. A hardware multiplexer decides whether the next PC is strictly `PC + 4` (normal sequential flow) or the `branchPC` (if a jump/branch is taken).
* **Instruction Memory:** A dedicated ROM block triggered by the clock edge that outputs the 32-bit instruction fetched at the current PC address.

### 2. Operand Fetch & Decode Unit (OF/ID)
* **Register File:** Contains 16 general-purpose registers (`r0`-`r15`). It features two asynchronous read ports to fetch operands simultaneously (`op1` and `op2`). Register `r15` is hardwired as the Return Address (`ra`) register, and `r14` serves as the Stack Pointer (`sp`).
* **Immediate Calculator:** Extracts the 18-bit immediate from the instruction (`inst[1:18]`) and calculates the 32-bit sign-extended immediate (`immx`).
* **Branch Target Logic:** Computes the branch target regardless of the instruction format. It takes the 27-bit offset (`inst[1:27]`), shifts it left by 2 bits (multiplying by 4 for word alignment), and adds it to the current PC.
* **Control Unit:** The central sequencer that reads the 6-bit opcode and Immediate flag (`inst[27:32]`) to generate binary control variables (signals) that orchestrate the multiplexers and ALU in later stages.

### 3. Execution Unit (EX)
The Execution stage is the computational heart of the pipeline, resolving all arithmetic, logical, and control flow decisions.
* **Arithmetic Logic Unit (ALU):** A highly modular block containing dedicated hardware for addition/subtraction, multiplication, and division. It also contains a Shift Unit for logical and arithmetic shifts (`lsl`, `lsr`, `asr`) and a Logical Unit for bitwise operations (`and`, `or`, `not`).
* **Operand B Multiplexer:** Depending on the `isImmediate` control signal (the `I` bit), the ALU's second input seamlessly switches between the second register operand (`op2`) and the 32-bit sign-extended immediate (`immx`).
* **Flags Register & Branch Unit:** The `cmp` instruction updates the `flags` register, specifically setting `flags.E` (Equality) and `flags.GT` (Greater Than). The Branch Unit evaluates these flags alongside control signals (`isBeq`, `isBgt`, `isUBranch`) to generate the definitive `isBranchTaken` signal, which is fed back to the IF stage multiplexer.

### 4. Memory Access Unit (MA)
This stage bridges the processor with the data memory (RAM), handling direct memory reads and writes.
* **Memory Interface:** It uses the calculated `aluResult` as the Memory Address Register (MAR).
* **Load/Store Execution:** For a store (`st`), the raw data from `op2` is fed into the Memory Data Register (MDR) and written to RAM if the `isSt` control signal is high. For a load (`ld`), data is fetched into `ldResult` if `isLd` is high.

### 5. Register Write Unit (RW / WB)
The final pipeline stage routes calculated or fetched data back into the register file to complete the instruction lifecycle.
* **Data Routing Multiplexer:** A 3-to-1 multiplexer selects the final write data (`result`). It chooses between the memory output (`ldResult`), the math output (`aluResult`), or `PC + 4`.
* **Destination Address Selection:** Under normal operation, the destination register (`rd`) is extracted from `inst[23:26]`. However, if the `isCall` signal is high, the destination address is forcefully overridden to `15` (`ra`), safely storing the `PC + 4` return address.

---

## Custom Instruction Set Architecture & Encoding

The SimpleRISC ISA operates on a strict 32-bit encoded format to drastically simplify the hardware decoding logic in the OF stage. It supports 21 core instructions across data movement, arithmetic, bitwise logic, and control flow.

### Instruction Formats
The instruction decoder extracts operational data based on the position of specific bit fields:

| Format Type | Opcode (Bits 27-31) | I-Bit (26) | Destination `rd` (22-25) | Source `rs1` (18-21) | Source `rs2` (14-17) | Immediate `imm` (0-17) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **R-Type (Register)** | 5 bits | `0` | 4 bits | 4 bits | 4 bits | N/A |
| **I-Type (Immediate)**| 5 bits | `1` | 4 bits | 4 bits | N/A | 18 bits |

*Note: For 2-Address instructions (like `cmp` or `not`), unused register fields are simply ignored by the datapath.*

### Branch Format Encoding
Control flow instructions (`b`, `call`, `beq`, `bgt`) ignore standard register fields to maximize the jump range. 
* **Encoding:** `Opcode (Bits 27-31)` | `Offset (Bits 0-26)`.
* **Address Calculation:** Because the 27-bit offset points to a 4-byte word boundary, the hardware computes the final physical target address using the formula: $PC + offset \times 4$.

### Immediate Modifiers
To increase the flexibility of the 18-bit immediate field, the ISA supports 2 modifier bits embedded within the instruction:
* **Default (`00`):** Automatic sign extension (treats the immediate as a signed number).
* **Unsigned (`01` / `u`):** Zero-extends the immediate, treating it as an unsigned number.
* **High (`10` / `h`):** Shifts the immediate left by 16 positions (e.g., `movh`), which is critical for loading full 32-bit addresses or constants into a register across two instructions.

---

## Pipeline Hazards & Software Resolution (NOPs)

A pipeline hazard represents the possibility of erroneous execution because an instruction requires a resource, data, or address that is not yet ready.

### Identified Pipeline Hazards
1. **Data Hazards (RAW):** Read After Write dependencies occur when an instruction (e.g., `add r1, r2, r3`) attempts to write to a register (`r1`), but the immediately following instruction (`sub r4, r1, r5`) tries to read that exact register before the Write-Back stage has completed.
2. **Control Hazards:** When a branch instruction (e.g., `beq`) is fetched, the pipeline continues fetching sequential instructions blindly. If the branch is evaluated as "taken" in the EX stage, the sequential instructions already loaded into the IF and OF stages are erroneous and must be discarded.
3. **Structural Hazards:** Occurs when two instructions conflict over the same physical hardware in the same cycle (e.g., simultaneous memory reads/writes).

### The Software-Level Fix: NOP Insertion
Instead of complicating the RTL with heavy operand forwarding (data bypassing) logic or hardware flush mechanisms, this CPU resolves all hazards at the software/compiler level. 

By deliberately inserting `nop` (No Operation) instructions (Opcode: `01101`) into the assembly code, dependent instructions are physically pushed back in the execution timeline. 
* For **Data Hazards**, inserting up to 3 `nop` instructions ensures the first instruction finishes the RW stage before the dependent instruction enters the OF stage.
* For **Control Hazards**, inserting 2 `nop` instructions immediately after a branch ensures the pipeline has time to calculate the `branchTarget` and update the PC without executing incorrect code.

## Simulation & Verification Environment

Unlike many academic processor projects that rely on complex external dependencies or fragile absolute file paths for memory initialization, this project is designed for **100% plug-and-play simulation**. 

### The Self-Contained Testbench
The top-level testbench (`simplerisc_pipeline_tb.v`) bypasses the standard `$readmemh` Verilog system task. Instead, the custom hexadecimal machine code is injected directly into the Instruction Memory's ROM array during the `initial` block. 

* **Why this matters:** Anyone cloning this repository can compile and run the simulation immediately on any operating system or IDE (like Xilinx Vivado, ModelSim, or Icarus Verilog) without ever encountering "file not found" errors.

### The "Easy Checker" Output
To make verification effortless, the testbench includes an automated console logger. Rather than forcing the user to decipher a chaotic waveform of 32-bit hex values across 5 pipeline stages, the testbench dynamically monitors the Register Write (RW) stage. 

Every time a valid instruction successfully writes data back to the register file (excluding the hardwired `r0`), it prints a clean success message directly to the console:
```text
Time=150 | SUCCESS: Wrote value 20 into Register[3]
Time=190 | SUCCESS: Wrote value 10 into Register[2]
```

## Repository Structure

All project source files are located in the main directory for easy accessibility:

* **RTL Design Files**: 
  * `full_adder.v`, `adder_subtractor_32bit.v`, `alu.v`, `branch_unit.v`
  * `program_counter.v`, `register_file.v`, `instruction_mem.v`, `memory_unit.v`
  * `if_of_reg.v`, `of_ex_reg.v`, `ex_ma_reg.v`, `ma_rw_reg.v`
  * `control_unit.v`
  * `simplerisc_pipeline_top.v`
* **Simulation Files**: 
  * `simplerisc_pipeline_tb.v` (Testbench with hardcoded execution sequence)

---

##  How to Run the Simulation

Follow these steps to verify the processor performance using your preferred Verilog simulator (e.g., Vivado, ModelSim, or Icarus Verilog):

1. **Clone the Repository**: Download all files from this directory to your local machine.
2. **Setup Project**: Open your simulation tool and create a new project.
3. **Import Files**: Add all `.v` files from the main project folder to your project sources. 
4. **Compile & Run**: Initiate the simulation process. Set the simulation duration to at least `1000ns` to provide enough time for the pipeline to fill, execute the hardcoded program, and flush.
5. **Verify Results**: Check the simulator console/log output. You will see real-time updates for every register write operation performed by the CPU, providing an immediate confirmation of successful program execution.
