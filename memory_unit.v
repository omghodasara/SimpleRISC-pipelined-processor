//Author : omghodasara
//Module : memory_unit
//Description : The main data RAM for load and store instructions. It saves data on the clock edge when we store, and reads data out immediately when we need to load it.

module memory_unit(
    input             clk,
    input      [31:0] address,    // From EX-MA Register (aluResult)
    input      [31:0] write_data, // From EX-MA Register (op2 for Store)
    input             isLd,       // Control signal from EX-MA Register
    input             isSt,       // Control signal from EX-MA Register
    output reg [31:0] read_data   // Sent to MA-RW Register (ldResult)
);

    // 256-word data memory (1024 bytes)
    reg [31:0] ram [255:0];

    // Initialize memory to zero to avoid undefined 'x' states 
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            ram[i] = 32'b0;
        end
    end

    // Sequential Write: Store instruction executes on the clock edge
    always @(posedge clk) begin
        if (isSt) begin
            // Word-aligned access using address[9:2]
            ram[address[9:2]] <= write_data;
        end
    end

    // Combinational Read: Load instruction fetches data immediately so it is ready for the MA-RW pipeline register at the next clock edge
    always @(*) begin
        if (isLd) begin
            read_data = ram[address[9:2]];
        end else begin
            read_data = 32'b0;
        end
    end

endmodule