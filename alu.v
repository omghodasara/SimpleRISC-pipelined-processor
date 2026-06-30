//Author : omghodasara
//Module : alu
//Description : Arithmetic Logic Unit (ALU). Handles arithmetic, logical, and shift operations based on decoded opcodes. 

module alu(
    input  [31:0] A,           
    input  [31:0] B,           
    input  [4:0]  opcode,      
    output reg [31:0] result,  
    output reg E,              
    output reg GT              
);
    
    // Only set sub_mode to 1 if the instruction is a subtraction (00001)
    wire is_sub = (opcode == 5'b00001);
    wire [31:0] add_sub_result;

    // hardware Adder-Subtractor
    adder_subtractor_32bit ADD_SUB_MOD (
        .A(A),
        .B(B),
        .sub_mode(is_sub),
        .Result(add_sub_result)
    );

    always @(*) begin
        // Flag Logic
        E  = (A == B);
        GT = ($signed(A) > $signed(B)); 

        case(opcode)
            // Arithmetic 
            5'b00000: result = add_sub_result;          // add
            5'b00001: result = add_sub_result;          // sub
            5'b00010: result = A * B;                   // mul
            5'b00011: result = A / B;                   // div 
            5'b00100: result = A % B;                   // mod 
            
            // Logical
            5'b00110: result = A & B;                   // and
            5'b00111: result = A | B;                   // or
            5'b01000: result = ~A;                      // not
            5'b01001: result = B;                       // mov
            
            // Shift
            5'b01010: result = A << B[4:0];             // lsl
            5'b01011: result = A >> B[4:0];             // lsr
            5'b01100: result = $signed(A) >>> B[4:0];   // asr
            
            // Memory Address Calculation (Uses the Adder hardware)
            5'b01110, 5'b01111: result = add_sub_result;         
            
            // Compare / Nop
            5'b00101, 5'b01101: result = 32'b0;         
            
            default:  result = 32'b0;
        endcase
    end
endmodule