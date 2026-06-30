//Author : omghodasara
//Module : instruction_mem
//Description : A 1024-byte ROM that holds our program code. It uses word-aligned addressing (dropping the last two bits) to fetch the 32-bit instruction.

module instruction_mem(
    input  [31:0] addr,      // Address from the Program Counter (PC)
    output [31:0] inst_out   // 32-bit instruction sent to IF/OF Register
);

    // Memory size of 256 words (1024 bytes)
    reg [31:0] rom [255:0];

    // Initialize memory to zero to prevent 'X' states during simulation startup
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 32'b0;
        end
    end

    // Combinational read: Address is divided by 4 (byte to word addressing) using addr[9:2] because the PC increments by 4
    assign inst_out = rom[addr[9:2]];

endmodule