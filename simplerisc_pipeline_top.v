//Author : omghodasara
//Module : simplerisc_pipeline_top
//Description : The top-level wrapper that wires the entire 5-stage pipelined processor together. It connects all the individual modules (like the ALU, memory, and control unit) through the pipeline registers. It also contains the routing logic multiplexers to handle branch feedback to the program counter and to decide what final data gets written back to the register file.

`timescale 1ns / 1ps

module simplerisc_pipeline_top(
    input clk,
    input reset
);

    // FORWARD DECLARATIONS (Feedback Signals)
    wire        isBranchTaken_ex;
    wire [31:0] branchPC_ex;
    wire [3:0]  final_rd_rw;
    wire [31:0] final_data_rw;
    wire        isWb_rw;

    // 1. INSTRUCTION FETCH (IF) STAGE
    wire [31:0] pc_if;
    wire [31:0] inst_if;
    
    // MUX: Select between next sequential instruction or the branch target
    wire [31:0] next_pc = isBranchTaken_ex ? branchPC_ex : (pc_if + 4);

    program_counter PC_MOD (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc_if)
    );

    instruction_mem IMEM_MOD (
        .addr(pc_if),
        .inst_out(inst_if)
    );

    // IF/OF PIPELINE REGISTER
    wire [31:0] pc_of;
    wire [31:0] inst_of;

    if_of_reg IF_OF_REG_MOD (
        .clk(clk),
        .reset(reset),
        .pc_in(pc_if),
        .inst_in(inst_if),
        .pc_out(pc_of),
        .inst_out(inst_of)
    );

    // 2. OPERAND FETCH (OF) STAGE
    wire [4:0]  opcode_of = inst_of[31:27];
    wire        i_bit_of  = inst_of[26];
    wire [3:0]  rs1_of    = inst_of[21:18];
    
    // Control Unit Outputs
    wire isSt_of, isLd_of, isBeq_of, isBgt_of, isRet_of;
    wire isImmediate_of, isWb_of, isCall_of, isUBranch_of;
    wire [4:0] aluSignals_of;
    
    // MUX: If it is a Store instruction, the data we want to write to memory  is sitting in the 'rd' field [25:22], not the usual 'rs2' field!
    wire [3:0]  rs2_of    = isSt_of ? inst_of[25:22] : inst_of[17:14];
    
    // Immediate Extension (18-bit to 32-bit)
    wire [17:0] imm_of    = inst_of[17:0];
    wire [31:0] immx_of   = {{14{imm_of[17]}}, imm_of};
    
    // Branch Target Calculation (PC + Offset * 4)
    wire [31:0] branchTarget_of = pc_of + ({{5{inst_of[26]}}, inst_of[26:0]} << 2);

    // Register File Read Outputs
    wire [31:0] op1_of;
    wire [31:0] op2_of;
    
    register_file RF_MOD (
        .clk(clk),
        .reset(reset),
        .rs1_addr(rs1_of),
        .rs2_addr(rs2_of),
        .rd_addr(final_rd_rw),      // Routed back from RW Stage
        .write_data(final_data_rw), // Routed back from RW Stage
        .write_enable(isWb_rw),     // Routed back from RW Stage
        .rs1_data(op1_of),
        .rs2_data(op2_of)
    );

    control_unit CU_MOD (
        .opcode(opcode_of),
        .i_bit(i_bit_of),
        .isSt(isSt_of),
        .isLd(isLd_of),
        .isBeq(isBeq_of),
        .isBgt(isBgt_of),
        .isRet(isRet_of),
        .isImmediate(isImmediate_of),
        .isWb(isWb_of),
        .isCall(isCall_of),
        .isUBranch(isUBranch_of),
        .aluSignals(aluSignals_of)
    );

    // MUX: Select between Register 2 data or Immediate value for ALU Operand B
    wire [31:0] B_of = isImmediate_of ? immx_of : op2_of;

    // OF/EX PIPELINE REGISTER
    wire [31:0] pc_ex;
    wire [31:0] branchTarget_ex;
    wire [31:0] A_ex;
    wire [31:0] B_ex;
    wire [31:0] op2_ex;
    wire [31:0] inst_ex;
    
    wire isSt_ex, isLd_ex, isBeq_ex, isBgt_ex, isRet_ex, isWb_ex, isCall_ex, isUBranch_ex;
    wire [4:0] aluSignals_ex;

    of_ex_reg OF_EX_REG_MOD (
        .clk(clk), 
        .reset(reset),
        // Data in
        .pc_in(pc_of), 
        .branchTarget_in(branchTarget_of), 
        .A_in(op1_of), 
        .B_in(B_of), 
        .op2_in(op2_of), 
        .instruction_in(inst_of),
        // Control in
        .isSt_in(isSt_of), 
        .isLd_in(isLd_of), 
        .isBeq_in(isBeq_of), 
        .isBgt_in(isBgt_of), 
        .isRet_in(isRet_of), 
        .isWb_in(isWb_of), 
        .isCall_in(isCall_of), 
        .isUBranch_in(isUBranch_of), 
        .aluSignals_in(aluSignals_of),
        // Data out
        .pc_out(pc_ex), 
        .branchTarget_out(branchTarget_ex), 
        .A_out(A_ex), 
        .B_out(B_ex), 
        .op2_out(op2_ex), 
        .instruction_out(inst_ex),
        // Control out
        .isSt_out(isSt_ex), 
        .isLd_out(isLd_ex), 
        .isBeq_out(isBeq_ex), 
        .isBgt_out(isBgt_ex), 
        .isRet_out(isRet_ex), 
        .isWb_out(isWb_ex), 
        .isCall_out(isCall_ex), 
        .isUBranch_out(isUBranch_ex), 
        .aluSignals_out(aluSignals_ex)
    );

    // 3. EXECUTE (EX) STAGE
    wire [31:0] aluResult_ex;
    wire E_ex, GT_ex;

    alu ALU_MOD (
        .A(A_ex),
        .B(B_ex),
        .opcode(aluSignals_ex),
        .result(aluResult_ex),
        .E(E_ex),
        .GT(GT_ex)
    );

    branch_unit BU_MOD (
        .E(E_ex),
        .GT(GT_ex),
        .isBeq(isBeq_ex),
        .isBgt(isBgt_ex),
        .isUBranch(isUBranch_ex),
        .isCall(isCall_ex),
        .isRet(isRet_ex),
        .isBranchTaken(isBranchTaken_ex)
    );

    // MUX: Final branch address. 'ret' jumps to the address in ra(A_ex), others use calculated target
    assign branchPC_ex = isRet_ex ? A_ex : branchTarget_ex;

    // EX/MA PIPELINE REGISTER
    wire [31:0] pc_ma;
    wire [31:0] aluResult_ma;
    wire [31:0] op2_ma;
    wire [31:0] inst_ma;
    
    wire isLd_ma, isSt_ma, isWb_ma, isCall_ma;

    ex_ma_reg EX_MA_REG_MOD (
        .clk(clk), 
        .reset(reset),
        // Data in
        .pc_in(pc_ex), 
        .aluResult_in(aluResult_ex), 
        .op2_in(op2_ex), 
        .instruction_in(inst_ex),
        // Control in
        .isLd_in(isLd_ex), 
        .isSt_in(isSt_ex), 
        .isWb_in(isWb_ex), 
        .isCall_in(isCall_ex),
        // Data out
        .pc_out(pc_ma), 
        .aluResult_out(aluResult_ma), 
        .op2_out(op2_ma), 
        .instruction_out(inst_ma),
        // Control out
        .isLd_out(isLd_ma), 
        .isSt_out(isSt_ma), 
        .isWb_out(isWb_ma), 
        .isCall_out(isCall_ma)
    );

    // 4. MEMORY ACCESS (MA) STAGE
    wire [31:0] ldResult_ma;

    memory_unit MEM_MOD (
        .clk(clk),
        .address(aluResult_ma),
        .write_data(op2_ma),
        .isLd(isLd_ma),
        .isSt(isSt_ma),
        .read_data(ldResult_ma)
    );

    // MA/RW PIPELINE REGISTER
    wire [31:0] pc_rw;
    wire [31:0] aluResult_rw;
    wire [31:0] ldResult_rw;
    wire [31:0] inst_rw;
    
    wire isLd_rw, isCall_rw;

    ma_rw_reg MA_RW_REG_MOD (
        .clk(clk), 
        .reset(reset),
        // Data in
        .pc_in(pc_ma), 
        .aluResult_in(aluResult_ma), 
        .ldResult_in(ldResult_ma), 
        .instruction_in(inst_ma),
        // Control in
        .isWb_in(isWb_ma), 
        .isLd_in(isLd_ma), 
        .isCall_in(isCall_ma),
        // Data out
        .pc_out(pc_rw), 
        .aluResult_out(aluResult_rw), 
        .ldResult_out(ldResult_rw), 
        .instruction_out(inst_rw),
        // Control out
        .isWb_out(isWb_rw), 
        .isLd_out(isLd_rw), 
        .isCall_out(isCall_rw)
    );

    // 5. REGISTER WRITE (RW) STAGE
    // MUX: Destination Register Selection. 'call' writes to ra (register 15), else standard 'rd'
    assign final_rd_rw = isCall_rw ? 4'd15 : inst_rw[25:22];

    // MUX: Write Data Selection. Chooses between (PC+4), Memory Data, or ALU Result
    assign final_data_rw = isCall_rw ? (pc_rw + 4) : (isLd_rw  ? ldResult_rw : aluResult_rw);

endmodule