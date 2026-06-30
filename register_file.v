//Author : omghodasara
//Module : register_file
//Description : Holds our 16 general-purpose 32-bit registers. It lets us read two registers at the same time continuously, and writes new data to a register exactly on the clock edge.

module register_file(
    input             clk,
    input             reset,
    input      [3:0]  rs1_addr,      // Read Address 1 (From IF/OF register)
    input      [3:0]  rs2_addr,      // Read Address 2 (From IF/OF register)
    input      [3:0]  rd_addr,       // Write Address (From MA/RW register)
    input      [31:0] write_data,    // Data to write (From MA/RW register)
    input             write_enable,  // isWb control signal (From MA/RW register)
    output [31:0] rs1_data,          // Data sent to OF/EX register
    output [31:0] rs2_data           // Data sent to OF/EX register
);

    // 16 registers, each 32 bits wide
    reg [31:0] registers [15:0];

    // Combinational Read: Operands are fetched continuously based on the address
    assign rs1_data = registers[rs1_addr];
    assign rs2_data = registers[rs2_addr];

    // Sequential Write: Occurs on the clock edge during the Write Back stage
    integer i;
    always @(posedge clk) begin
        if (reset) begin
            // Clear all registers to 0 on reset
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (write_enable) begin
            // Write data to the destination register
            registers[rd_addr] <= write_data;
        end
    end

endmodule