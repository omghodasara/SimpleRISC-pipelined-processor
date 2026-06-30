//Author : omghodasara
//Module : branch_unit
//Description : Evaluates branch conditions. Uses ALU flags and Control Unit signals to determine if the Program Counter should jump to a new address.

module branch_unit(
    input  E,              // Equality flag from ALU
    input  GT,             // Greater Than flag from ALU
    input  isBeq,          // Branch if Equal control signal
    input  isBgt,          // Branch if Greater Than control signal
    input  isUBranch,      // Unconditional Branch (b) control signal
    input  isCall,         // Call control signal
    input  isRet,          // Return control signal
    output isBranchTaken   // Final decision sent to the PC multiplexer
);

    // The branch is taken if it's an unconditional branch (b, call, ret), OR if it's a conditional branch (beq, bgt) and the ALU flag matches.
    assign isBranchTaken = isUBranch | isCall | isRet | (isBeq & E) | (isBgt & GT);

endmodule