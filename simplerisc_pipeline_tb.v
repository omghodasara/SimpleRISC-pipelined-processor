//Author      : omghodasara
//Module      : simplerisc_pipeline_tb
//Description : Self-contained testbench for the 5-stage SimpleRISC processor. It hardcodes a custom assembly program directly into the instruction memory to ensure immediate plug-and-play simulation without external file dependencies. It also features dynamic console monitoring for register write-backs and PC fetching.

`timescale 1ns / 1ps

module simplerisc_pipeline_tb();
    reg clk;
    reg reset;

    simplerisc_pipeline_top uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Signals
        clk = 0;
        reset = 1;

        // --- HARDCODED INSTRUCTION MEMORY ---
        // Loading the custom hex program directly into the IMEM module
        uut.IMEM_MOD.rom[0]  = 32'h4C400014;
        uut.IMEM_MOD.rom[1]  = 32'h4C800003;
        uut.IMEM_MOD.rom[2]  = 32'h4CC00008;
        uut.IMEM_MOD.rom[3]  = 32'h68000000;
        uut.IMEM_MOD.rom[4]  = 32'h68000000;
        uut.IMEM_MOD.rom[5]  = 32'h68000000;
        uut.IMEM_MOD.rom[6]  = 32'h1108C000;
        uut.IMEM_MOD.rom[7]  = 32'h19448000;
        uut.IMEM_MOD.rom[8]  = 32'h21848000;
        uut.IMEM_MOD.rom[9]  = 32'h5DCC0001;
        uut.IMEM_MOD.rom[10] = 32'h68000000;
        uut.IMEM_MOD.rom[11] = 32'h68000000;
        uut.IMEM_MOD.rom[12] = 32'h68000000;
        uut.IMEM_MOD.rom[13] = 32'h68000000;
        uut.IMEM_MOD.rom[14] = 32'h97FFFFFF;

        // Hold reset for a few cycles to clear all pipeline registers
        #20 reset = 0;

        // Run the simulation long enough for the pipeline to fill and execute
        #1000; 

        $display("Simulation complete. Check the wave window for pipeline flow.");
        $finish;
    end

    // --- THE EASY CHECKER ---
    // This will print a message to the console exactly when a register is written to!
    always @(negedge clk) begin
        // If write_enable is high, and we aren't trying to write to Register 0
        if (uut.RF_MOD.write_enable && uut.RF_MOD.rd_addr != 0) begin
            $display("Time=%0t | SUCCESS: Wrote value %0d into Register[%0d]", 
                     $time, uut.RF_MOD.write_data, uut.RF_MOD.rd_addr);
        end
    end

    // Monitor the Program Counter at the very start of the pipeline (IF stage)
    initial begin
        $monitor("Time=%0t | Fetching PC=%h", $time, uut.pc_if);
    end

endmodule