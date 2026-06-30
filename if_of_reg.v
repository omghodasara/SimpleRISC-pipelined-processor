//Author : omghodasara
//Module : if_of_reg
//Description : The pipeline register between Instruction Fetch (IF) and Operand Fetch (OF). It grabs the PC and instruction on the clock edge. If reset is high, it safely pushes a 'nop' (no operation) into the pipeline so we don't execute garbage data.

module if_of_reg(
    input             clk,
    input             reset,
    input      [31:0] pc_in,        // From Program Counter
    input      [31:0] inst_in,      // From Instruction Memory
    output reg [31:0] pc_out,       // To OF stage
    output reg [31:0] inst_out      // To OF stage (Control Unit and Reg File)
);

    always @(posedge clk) begin
        if (reset) begin
            // Clear the pipeline register on reset (insert a 'nop' effectively)
            pc_out   <= 32'b0;
            inst_out <= 32'b01101_0_0000_0000_0000_00000000000000; 
        end else begin
            // Capture the data at the rising edge and hold it for the OF stage
            pc_out   <= pc_in;
            inst_out <= inst_in;
        end
    end

endmodule