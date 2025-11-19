//`timescale 1ns/1ps

//module tb_mac_matmul_ip_flat;

//    // ------------------------------------------------------------------------
//    // Parameters
//    // ------------------------------------------------------------------------
//    localparam N    = 3;
//    localparam AW   = 32;
//    localparam ACCW = 48;

//    // ------------------------------------------------------------------------
//    // DUT I/O
//    // ------------------------------------------------------------------------
//    reg  [AW*N*N-1:0]   A_flat;
//    reg  [AW*N*N-1:0]   B_flat;
//    wire [ACCW*N*N-1:0] C_flat;
//    wire                done;

//    // ------------------------------------------------------------------------
//    // DUT Instance (combinational)
//    // ------------------------------------------------------------------------
//    MAC_MATMUL_IP #(
//        .N(N),
//        .AW(AW),
//        .ACCW(ACCW)
//    ) dut (
//        .A_flat(A_flat),
//        .B_flat(B_flat),
//        .C_flat(C_flat),
//        .done(done)
//    );

//    // ------------------------------------------------------------------------
//    // Task: Display flattened output as 2D matrix
//    // ------------------------------------------------------------------------
//    task display_C;
//        input [ACCW*N*N-1:0] flat;
//        integer i, j;
//        reg signed [ACCW-1:0] elem;
//        begin
//            $display("\n=== MAC IP-Based Matrix Multiply Result ===");
//            for (i = 0; i < N; i = i + 1) begin
//                for (j = 0; j < N; j = j + 1) begin
//                    elem = flat[ACCW*(i*N + j) +: ACCW];
//                    $write("%0d\t", elem);
//                end
//                $write("\n");
//            end
//            $display("===========================================\n");
//        end
//    endtask

//    // ------------------------------------------------------------------------
//    // Stimulus
//    // ------------------------------------------------------------------------
//    integer i, j;
//    reg signed [AW-1:0] A_mat [0:N-1][0:N-1];
//    reg signed [AW-1:0] B_mat [0:N-1][0:N-1];

//    initial begin
//        // Initialize input matrices
//        A_mat[0][0]=1; A_mat[0][1]=2; A_mat[0][2]=3;
//        A_mat[1][0]=4; A_mat[1][1]=5; A_mat[1][2]=6;
//        A_mat[2][0]=7; A_mat[2][1]=8; A_mat[2][2]=9;

//        B_mat[0][0]=1; B_mat[0][1]=0; B_mat[0][2]=0;
//        B_mat[1][0]=0; B_mat[1][1]=1; B_mat[1][2]=0;
//        B_mat[2][0]=0; B_mat[2][1]=0; B_mat[2][2]=1;

//        // Flatten A and B into buses
//        for (i = 0; i < N; i = i + 1)
//            for (j = 0; j < N; j = j + 1) begin
//                A_flat[AW*(i*N + j) +: AW] = A_mat[i][j];
//                B_flat[AW*(i*N + j) +: AW] = B_mat[i][j];
//            end

//        // Wait for combinational settle
//        #1;

//        // Display result
//        display_C(C_flat);

//        // Expected
//        $display("Expected Result:\n1 2 3\n4 5 6\n7 8 9\n");

//        #5;
//        $display("Simulation completed.");
//        $finish;
//    end

//endmodule
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


