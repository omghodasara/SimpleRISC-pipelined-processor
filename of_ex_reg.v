//Author : omghodasara
//Module : of_ex_reg
//Description : The pipeline register between Operand Fetch (OF) and Execute (EX). It carries all our decoded control signals, register data (like op1 and op2), and the branch target into the ALU stage.

module of_ex_reg(
    input             clk,
    input             reset,
    
    // Data Inputs (From OF Stage) 
    input      [31:0] pc_in,
    input      [31:0] branchTarget_in,
    input      [31:0] A_in,             // op1
    input      [31:0] B_in,             // Muxed output of op2 or immx
    input      [31:0] op2_in,           // Raw op2 (Needed later for Store)
    input      [31:0] instruction_in,   // Passed down for WB stage rd extraction
    
    // Control Inputs (From Control Unit) 
    input             isSt_in,
    input             isLd_in,
    input             isBeq_in,
    input             isBgt_in,
    input             isRet_in,
    input             isWb_in,
    input             isCall_in,
    input             isUBranch_in,
    input      [4:0]  aluSignals_in,
    
    // Data Outputs (To EX Stage) 
    output reg [31:0] pc_out,
    output reg [31:0] branchTarget_out,
    output reg [31:0] A_out,
    output reg [31:0] B_out,
    output reg [31:0] op2_out,
    output reg [31:0] instruction_out,
    
    // Control Outputs (To EX Stage & Beyond)
    output reg        isSt_out,
    output reg        isLd_out,
    output reg        isBeq_out,
    output reg        isBgt_out,
    output reg        isRet_out,
    output reg        isWb_out,
    output reg        isCall_out,
    output reg        isUBranch_out,
    output reg [4:0]  aluSignals_out
);

    always @(posedge clk) begin
        if (reset) begin
            // Clear all data paths to 0
            pc_out           <= 32'b0;
            branchTarget_out <= 32'b0;
            A_out            <= 32'b0;
            B_out            <= 32'b0;
            op2_out          <= 32'b0;
            
            // Insert a nop instruction on reset
            instruction_out  <= 32'b01101_0_0000_0000_0000_00000000000000; 
            
            // Clear all control signals
            isSt_out         <= 1'b0;
            isLd_out         <= 1'b0;
            isBeq_out        <= 1'b0;
            isBgt_out        <= 1'b0;
            isRet_out        <= 1'b0;
            isWb_out         <= 1'b0;
            isCall_out       <= 1'b0;
            isUBranch_out    <= 1'b0;
            aluSignals_out   <= 5'b01101; // nop opcode
            
        end else begin
            // Pass data smoothly down the pipeline
            pc_out           <= pc_in;
            branchTarget_out <= branchTarget_in;
            A_out            <= A_in;
            B_out            <= B_in;
            op2_out          <= op2_in;
            instruction_out  <= instruction_in;
            
            // Pass control signals smoothly down the pipeline
            isSt_out         <= isSt_in;
            isLd_out         <= isLd_in;
            isBeq_out        <= isBeq_in;
            isBgt_out        <= isBgt_in;
            isRet_out        <= isRet_in;
            isWb_out         <= isWb_in;
            isCall_out       <= isCall_in;
            isUBranch_out    <= isUBranch_in;
            aluSignals_out   <= aluSignals_in;
        end
    end

endmodule