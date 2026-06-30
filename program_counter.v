//Author : omghodasara
//Module : program_counter
//Description : Holds the current 32-bit address for the instruction we are executing. It updates to the next address on every clock cycle and resets back to 0 when the reset signal is high.

module program_counter(
    input             clk,
    input             reset,
    input      [31:0] next_pc, // The calculated next address (PC+4 or Branch Target)
    output reg [31:0] pc       // The current address sent to Instruction Memory
);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'b0;       // Start at address 0 on reset
        end else begin
            pc <= next_pc;     // Advance the pipeline every single clock cycle
        end
    end

endmodule