module PE #(parameter DATA_WIDTH = 8)(
    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] a,
    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] b,
    (* dont_touch = "true", keep = "true" *) input  logic clk,
    (* dont_touch = "true", keep = "true" *) input  logic rst,    
    (* dont_touch = "true", keep = "true" *) input  logic clear,

    (* dont_touch = "true", keep = "true" *) output logic signed [DATA_WIDTH-1:0] a_out,
    (* dont_touch = "true", keep = "true" *) output logic signed [DATA_WIDTH-1:0] b_out,
    (* dont_touch = "true", keep = "true" *) output logic signed [2*DATA_WIDTH-1:0] C_out
);

    localparam ACCW = 2*DATA_WIDTH;

    (* dont_touch = "true", keep = "true" *) logic signed [2*DATA_WIDTH-1:0] mult;
    (* dont_touch = "true", keep = "true" *) logic signed [ACCW-1:0] acc;

    assign mult = a * b;

    // sequential accumulator
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            acc <= 0;
        else if (clear)
            acc <= 0;
        else
            acc <= acc + mult;
    end

    // NON-PIPELINED datapath
    assign a_out = a;
    assign b_out = b;

    assign C_out = acc;

endmodule
module SystolicArray #(parameter SIZE = 3, parameter DATA_WIDTH = 8)(
    (* dont_touch = "true", keep = "true" *) input  logic clk,
    (* dont_touch = "true", keep = "true" *) input  logic rst,
    (* dont_touch = "true", keep = "true" *) input  logic clear,

    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] A_in [SIZE-1:0],
    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] B_in [SIZE-1:0],

    (* dont_touch = "true", keep = "true" *) output logic signed [2*DATA_WIDTH-1:0] C_out [SIZE-1:0][SIZE-1:0],
    (* dont_touch = "true", keep = "true" *) output logic done
);

    // Internal propagation wires
    logic signed [DATA_WIDTH-1:0] a_wire [0:SIZE][0:SIZE-1];
    logic signed [DATA_WIDTH-1:0] b_wire [0:SIZE-1][0:SIZE];
    logic signed [2*DATA_WIDTH-1:0] c_partial [SIZE-1:0][SIZE-1:0];

    // Clear initial wires
    initial begin
        for (int i = 0; i <= SIZE; i++)
            for (int j = 0; j < SIZE; j++)
                a_wire[i][j] = 0;

        for (int i = 0; i < SIZE; i++)
            for (int j = 0; j <= SIZE; j++)
                b_wire[i][j] = 0;
    end

    // feed edges
    generate
        genvar idx;
        for (idx = 0; idx < SIZE; idx++) begin
            assign a_wire[idx][0] = A_in[idx];
            assign b_wire[0][idx] = B_in[idx];
        end
    endgenerate

    // Instantiate SIZE×SIZE PEs
    generate
        genvar i, j;
        for (i = 0; i < SIZE; i++) begin : row
            for (j = 0; j < SIZE; j++) begin : col
              (* dont_touch = "true", keep = "true" *)
                PE #(.DATA_WIDTH(DATA_WIDTH)) pe_inst (
                    .a      (a_wire[i][j]),
                    .b      (b_wire[i][j]),
                    .clk    (clk),
                    .rst    (rst),
                    .clear  (clear),
                    .a_out  (a_wire[i][j+1]),
                    .b_out  (b_wire[i+1][j]),
                    .C_out  (c_partial[i][j])
                );
            end
        end
    endgenerate

    // final output assignment
    always_comb begin
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++)
                C_out[r][c] = c_partial[r][c];
    end

    // done signal
    logic [15:0] cycle_count;
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            cycle_count <= 0;
        else if (cycle_count < SIZE * 6)
            cycle_count <= cycle_count + 1;
    end

    assign done = (cycle_count >= 2 * SIZE * SIZE);

endmodule
module top_3x3 #(parameter DATA_WIDTH = 8)(
    (* dont_touch = "true", keep = "true" *) input  logic clk,
    (* dont_touch = "true", keep = "true" *) input  logic rst,
    (* dont_touch = "true", keep = "true" *) input  logic clear,

    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] A_in [2:0],
    (* dont_touch = "true", keep = "true" *) input  logic signed [DATA_WIDTH-1:0] B_in [2:0],

    (* dont_touch = "true", keep = "true" *) output logic signed [2*DATA_WIDTH-1:0] C_out [2:0][2:0],
    (* dont_touch = "true", keep = "true" *) output logic done
);
    (* dont_touch = "true", keep = "true" *)
    SystolicArray #(
        .SIZE(3),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .A_in(A_in),
        .B_in(B_in),
        .C_out(C_out),
        .done(done)
    );

endmodule

