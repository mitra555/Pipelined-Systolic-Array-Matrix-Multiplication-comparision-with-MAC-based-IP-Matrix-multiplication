`timescale 1ns/1ps
module MATRIX_MUL_TOP #(
    parameter integer N    = 3,
    parameter integer AW   = 8,
    parameter integer ACCW = 48,
    parameter integer ADDRW = 4
)(
    input  wire clk,
    input  wire reset,
    output reg  done,
    output wire [ACCW*N*N-1:0] C_flat
);

    reg ena_A, ena_B;
    reg [ADDRW-1:0] addra_A, addra_B;
    reg [ADDRW-1:0] addra_A_d, addra_B_d;
    wire [AW-1:0] douta_A, douta_B;

    reg [AW*N*N-1:0] A_flat, B_flat;
    reg doneA, doneB;

    // ------------------------------------------------------------
    // BRAM instances
    // ------------------------------------------------------------
    blk_mem_gen_0 BRAM_A (
        .clka(clk),
        .ena(ena_A),
        .wea(1'b0),
        .addra(addra_A),
        .dina(0),
        .douta(douta_A)
    );

    blk_mem_gen_1 BRAM_B (
        .clka(clk),
        .ena(ena_B),
        .wea(1'b0),
        .addra(addra_B),
        .dina(0),
        .douta(douta_B)
    );

    // ------------------------------------------------------------
    // BRAM loader
    // ------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addra_A <= 0; addra_A_d <= 0; ena_A <= 0; A_flat <= 0; doneA <= 0;
            addra_B <= 0; addra_B_d <= 0; ena_B <= 0; B_flat <= 0; doneB <= 0;
            done <= 0;
        end else begin
            addra_A_d <= addra_A;
            addra_B_d <= addra_B;

            if (addra_A_d < N*N) begin
                A_flat[AW*addra_A_d +: AW] <= douta_A;
                if (addra_A_d == N*N-1) doneA <= 1;
            end
            if (addra_B_d < N*N) begin
                B_flat[AW*addra_B_d +: AW] <= douta_B;
                if (addra_B_d == N*N-1) doneB <= 1;
            end

            if (!ena_A && !doneA) ena_A <= 1;
            if (!ena_B && !doneB) ena_B <= 1;

            if (ena_A && addra_A < N*N-1) addra_A <= addra_A + 1;
            if (ena_B && addra_B < N*N-1) addra_B <= addra_B + 1;

            if (doneA) ena_A <= 0;
            if (doneB) ena_B <= 0;

            done <= doneA & doneB;
        end
    end

    // ------------------------------------------------------------
    // Start pulse for MAC
    // ------------------------------------------------------------
    reg done_d;
    always @(posedge clk or posedge reset)
        if (reset) done_d <= 0;
        else done_d <= done;

    wire start_mac = done & ~done_d;   // 1-cycle pulse

    // ------------------------------------------------------------
    // Instantiate sequential MAC
    // ------------------------------------------------------------
    MAC_MATMUL_SEQ_IP #(
        .N(N),
        .AW(AW),
        .ACCW(ACCW)
    ) mac_seq (
        .clk(clk),
        .reset(reset),
        .start(start_mac),    // PULSE!
        .A_flat(A_flat),
        .B_flat(B_flat),
        .C_flat(C_flat),
        .done()
    );

endmodule
`timescale 1ns/1ps
module MAC_MATMUL_SEQ_IP #(
    parameter integer N    = 3,
    parameter integer AW   = 8,
    parameter integer ACCW = 48
)(
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     start,      
    input  wire [AW*N*N-1:0]        A_flat,
    input  wire [AW*N*N-1:0]        B_flat,
    output reg  [ACCW*N*N-1:0]      C_flat,
    output reg                      done
);

    // ---------------------------------------------------------------
    // UNPACK
    // ---------------------------------------------------------------
    wire signed [AW-1:0] A_mat [0:N-1][0:N-1];
    wire signed [AW-1:0] B_mat [0:N-1][0:N-1];

    genvar ii, jj;
    generate
        for(ii = 0; ii < N; ii = ii + 1) begin
            for(jj = 0; jj < N; jj = jj + 1) begin
                assign A_mat[ii][jj] = $signed(A_flat[AW*(ii*N+jj) +: AW]);
                assign B_mat[ii][jj] = $signed(B_flat[AW*(ii*N+jj) +: AW]);
                end
            end
    endgenerate

    // ---------------------------------------------------------------
    // MAC wrapper instance
    // ---------------------------------------------------------------
    reg  signed [AW-1:0]  a_reg, b_reg;
    wire signed [ACCW-1:0] mac_out;

    MAC_XBIP_WRAPPER #(
        .AW(AW),
        .ACCW(ACCW)
    ) mac_inst (
        .a_in(a_reg),
        .b_in(b_reg),
        .psum_in(16'b0),   // multiplier only
        .p_out(mac_out)
    );

    // ---------------------------------------------------------------
    // Internal state
    // ---------------------------------------------------------------
    reg [7:0] i, j, k;
    reg signed [ACCW-1:0] psum;

    // ---------------------------------------------------------------
    // FSM states
    // ---------------------------------------------------------------
    localparam IDLE  = 0,
               LOAD  = 1,
               MACC  = 2,
               STORE = 3,
               NEXT  = 4,
               DONE_ST = 5;

    reg [2:0] state;

    // ---------------------------------------------------------------
    // FSM
    // ---------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            i <= 0; j <= 0; k <= 0;
            psum <= 0;
            C_flat <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case(state)

            IDLE: begin
                done <= 0;
                if (start) begin
                    i <= 0; j <= 0; k <= 0;
                    psum <= 0;
                    state <= LOAD;
                end
            end

            LOAD: begin
                a_reg <= A_mat[i][k];
                b_reg <= B_mat[k][j];
                state <= MACC;
            end

            MACC: begin
                psum <= psum + mac_out;   // identical to MAC chain

                if (k == N-1)
                    state <= STORE;
                else begin
                    k <= k + 1;
                    state <= LOAD;
                end
            end

            STORE: begin
                C_flat[ACCW*(i*N+j) +: ACCW] <= psum;
                psum <= 0;
                state <= NEXT;
            end

            NEXT: begin
                if (j == N-1) begin
                    j <= 0;
                    if (i == N-1)
                        state <= DONE_ST;
                    else begin
                        i <= i + 1;
                        k <= 0;
                        state <= LOAD;
                    end
                end else begin
                    j <= j + 1;
                    k <= 0;
                    state <= LOAD;
                end
            end

            DONE_ST: begin
                done <= 1;
                state <= IDLE;
            end

            endcase
        end
    end

endmodule

`timescale 1ns/1ps
module MAC_XBIP_WRAPPER #(
    parameter AW   = 8,
    parameter ACCW = 48
)(
    input  wire signed [AW-1:0]   a_in,
    input  wire signed [AW-1:0]   b_in,
    input  wire signed [15:0]     psum_in,    // Only 16-bit goes to C port
    output wire signed [ACCW-1:0] p_out
);

    wire [AW-1:0] A = a_in;
    wire [AW-1:0] B = b_in;
    wire [15:0]   C = psum_in;   
    wire SUBTRACT = 1'b0;

    wire [ACCW-1:0] P;
    wire [ACCW-1:0] PCOUT;

    xbip_multadd_0 mac_ip_inst (
        .A(A),
        .B(B),
        .C(C),
        .SUBTRACT(SUBTRACT),
        .P(P),
        .PCOUT(PCOUT)
    );

    assign p_out = P;

endmodule
