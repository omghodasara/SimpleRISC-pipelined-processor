//Author : omghodasara
//Module : ex_ma_reg
//Description : The pipeline register between Execute (EX) and Memory Access (MA). It holds the math result from the ALU, the data we might want to store, and the control signals needed to use the RAM.

module ex_ma_reg(
    input             clk,
    input             reset,
    
    // Data Inputs (From EX Stage) 
    input      [31:0] pc_in,
    input      [31:0] aluResult_in,     // Calculated memory address or math result
    input      [31:0] op2_in,           // Data to store in memory
    input      [31:0] instruction_in,   // Passed down for WB stage rd extraction
    
    // Control Inputs (From OF/EX Register)
    input             isLd_in,
    input             isSt_in,
    input             isWb_in,
    input             isCall_in,
    
    // Data Outputs (To MA Stage) 
    output reg [31:0] pc_out,
    output reg [31:0] aluResult_out,
    output reg [31:0] op2_out,
    output reg [31:0] instruction_out,
    
    // Control Outputs (To MA Stage & Beyond)
    output reg        isLd_out,
    output reg        isSt_out,
    output reg        isWb_out,
    output reg        isCall_out
);

    always @(posedge clk) begin
        if (reset) begin
            // Clear all data paths to 0
            pc_out          <= 32'b0;
            aluResult_out   <= 32'b0;
            op2_out         <= 32'b0;
            
            // Insert a nop instruction on reset
            instruction_out <= 32'b01101_0_0000_0000_0000_00000000000000; 
            
            // Clear all control signals
            isLd_out        <= 1'b0;
            isSt_out        <= 1'b0;
            isWb_out        <= 1'b0;
            isCall_out      <= 1'b0;
        end else begin
            // Pass data smoothly down the pipeline
            pc_out          <= pc_in;
            aluResult_out   <= aluResult_in;
            op2_out         <= op2_in;
            instruction_out <= instruction_in;
            
            // Pass control signals smoothly down the pipeline
            isLd_out        <= isLd_in;
            isSt_out        <= isSt_in;
            isWb_out        <= isWb_in;
            isCall_out      <= isCall_in;
        end
    end

endmodule