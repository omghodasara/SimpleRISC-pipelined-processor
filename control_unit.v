//Author : omghodasara
//Module : control_unit
//Description : The brain of the processor. It looks at the 5-bit opcode and the immediate bit to figure out what the instruction is. It then turns on the right control signals (like write-back, branch, load, or store) to tell the rest of the pipeline exactly what to do.

module control_unit(
    input  [4:0] opcode,
    input        i_bit,
    output reg   isSt,
    output reg   isLd,
    output reg   isBeq,
    output reg   isBgt,
    output reg   isRet,
    output reg   isImmediate,
    output reg   isWb,
    output reg   isCall,
    output reg   isUBranch,
    output [4:0] aluSignals
);

    // The ALU needs the opcode to know what arithmetic/logic to perform
    assign aluSignals = opcode;

    always @(*) begin
        // Default assignments to prevent latches
        isSt        = 1'b0;
        isLd        = 1'b0;
        isBeq       = 1'b0;
        isBgt       = 1'b0;
        isRet       = 1'b0;
        isImmediate = i_bit; // Directly tied to the instruction's I-bit
        isWb        = 1'b0;
        isCall      = 1'b0;
        isUBranch   = 1'b0;

        case(opcode)
            // ALU operations that write to a register
            5'b00000, 5'b00001, 5'b00010, 5'b00011, 5'b00100, 5'b00110, 5'b00111, 5'b01000, 5'b01001, 5'b01010, 5'b01011, 5'b01100: begin
                isWb = 1'b1;
            end

            // Load Instruction
            5'b01110: begin
                isLd = 1'b1;
                isWb = 1'b1; // Load writes memory data to a register
            end

            // Store Instruction
            5'b01111: begin
                isSt = 1'b1;
            end

            // Branch Instructions
            5'b10000: isBeq     = 1'b1;
            5'b10001: isBgt     = 1'b1;
            5'b10010: isUBranch = 1'b1; // Unconditional branch (b)
            
            // Call and Return
            5'b10011: begin
                isCall = 1'b1;
                isWb   = 1'b1; // Call saves the return address to ra(r15)
            end
            5'b10100: begin
                isRet  = 1'b1;
            end
            
            // cmp (00101) and nop (01101) do not assert any control flags
            default: ; 
        endcase
    end
endmodule