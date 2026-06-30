//Author : omghodasara
//Module : ma_rw_reg
//Description : The pipeline register between Memory Access (MA) and Register Write (RW). It holds the final data, whether it came from the ALU or was just loaded from the RAM, so we can write it safely back to the register file.

module ma_rw_reg(
    input             clk,
    input             reset,
    
    // Data Inputs (From MA Stage) 
    input      [31:0] pc_in,
    input      [31:0] aluResult_in,     // Math result passed through from EX
    input      [31:0] ldResult_in,      // Data loaded from Data Memory
    input      [31:0] instruction_in,   // Passed down to extract 'rd'
    
    // Control Inputs (From EX/MA Register) 
    input             isWb_in,
    input             isLd_in,
    input             isCall_in,
    
    // Data Outputs (To WB Stage) 
    output reg [31:0] pc_out,
    output reg [31:0] aluResult_out,
    output reg [31:0] ldResult_out,
    output reg [31:0] instruction_out,
    
    // Control Outputs (To WB Stage)
    output reg        isWb_out,
    output reg        isLd_out,
    output reg        isCall_out
);

    always @(posedge clk) begin
        if (reset) begin
            // Clear all data paths to 0
            pc_out          <= 32'b0;
            aluResult_out   <= 32'b0;
            ldResult_out    <= 32'b0;
            
            // Insert a nop instruction on reset
            instruction_out <= 32'b01101_0_0000_0000_0000_00000000000000; 
            
            // Clear all control signals
            isWb_out        <= 1'b0;
            isLd_out        <= 1'b0;
            isCall_out      <= 1'b0;
        end else begin
            // Pass data smoothly down the pipeline
            pc_out          <= pc_in;
            aluResult_out   <= aluResult_in;
            ldResult_out    <= ldResult_in;
            instruction_out <= instruction_in;
            
            // Pass control signals smoothly down the pipeline
            isWb_out        <= isWb_in;
            isLd_out        <= isLd_in;
            isCall_out      <= isCall_in;
        end
    end

endmodule