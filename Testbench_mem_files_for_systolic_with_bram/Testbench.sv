`timescale 1ns/1ps

module tb_top();

    localparam N    = 4;
    localparam AW   = 8;
    localparam ACCW = 16;

    logic clk;
    logic reset;
    logic done;

    logic [ACCW*N*N-1:0] C_flat;

    // DUT
    top_module #(
        .N(N),
        .AW(AW),
        .ACCW(ACCW),
        .ADDRW(9)
    ) dut (
        .clk(clk),
        .reset(reset),
        .done(done),
        .C_flat(C_flat)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    // Reset sequence
    initial begin
        reset = 1;
        repeat(10) @(posedge clk);
        reset = 0;
        repeat(10) @(posedge clk);
        reset = 1;
    end

    // Wait for done and print results
    initial begin
        wait(done);

        $display("\n-------------------------------");
        $display("      SYSTOLIC RESULT C");
        $display("-------------------------------");

        for (int i = 0; i < N; i++) begin
            $write("Row %0d: ", i);
            for (int j = 0; j < N; j++) begin
                int idx = i*N + j;
                $write("%0d ", C_flat[idx*ACCW +: ACCW]);
            end
            $write("\n");
        end

        $display("-------------------------------");

        #20;
        $finish;
    end

endmodule
