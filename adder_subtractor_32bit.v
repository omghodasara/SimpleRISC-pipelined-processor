//Author : omghodasara
//Module : adder_subtractor_32bit
//Description : 32-bit Ripple Carry Adder/Subtractor built using a structural generate loop. Uses 2's complement logic for subtraction.

module adder_subtractor_32bit(
    input  [31:0] A,
    input  [31:0] B,
    input         sub_mode, // 0 for Add, 1 for Sub
    output [31:0] Result
);

    wire [31:0] b_xor;
    wire [32:0] carry;

    // The first carry-in is tied directly to the sub_mode flag
    assign carry[0] = sub_mode;

    // generate block to instantiate 32 full adders
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : add_sub_loop
            // XOR B with sub_mode for 2's complement inversion
            assign b_xor[i] = B[i] ^ sub_mode;
            
            full_adder FA (
                .a(A[i]),
                .b(b_xor[i]),
                .cin(carry[i]),
                .sum(Result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

endmodule