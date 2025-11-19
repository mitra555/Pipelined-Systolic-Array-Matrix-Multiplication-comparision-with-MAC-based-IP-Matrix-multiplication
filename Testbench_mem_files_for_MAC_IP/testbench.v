
`timescale 1ns/1ps
module tb_mac_matmul_seq_bram;

    reg clk, reset;
    wire done;
    wire [48*16-1:0] C_flat;

    MATRIX_MUL_TOP dut (
        .clk(clk),
        .reset(reset),
        .done(done),
        .C_flat(C_flat)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        #30 reset = 0;

        // Wait for everything (BRAM load + MAC computation)
        repeat(300) @(posedge clk);

        $display("C_flat = %h", C_flat);

        $finish;
    end

endmodule


