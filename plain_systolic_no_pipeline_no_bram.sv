module PE #(parameter DATA_WIDTH = 8)(
    input  logic signed [DATA_WIDTH-1:0] a,
    input  logic signed [DATA_WIDTH-1:0] b,
    input  logic clk,
    input  logic rst,    // active-low reset
    input  logic clear,
    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_out,
    output logic signed [2*DATA_WIDTH-1:0] C_out
);
    localparam ACCW = 2*DATA_WIDTH;

    logic signed [2*DATA_WIDTH-1:0] mult;
    logic signed [ACCW-1:0] acc;

    assign mult = a * b;

    // ONLY accumulator is sequential
    always_ff @(posedge clk or negedge rst) begin
        if (!rst)
            acc <= '0;
        else if (clear)
            acc <= '0;
        else
            acc <= acc + mult;
    end

    // *** NON-PIPELINED PROPOGATION ***
    assign a_out = a;   // direct combinational pass (NO register)
    assign b_out = b;   // direct combinational pass (NO register)

    assign C_out = acc;

endmodule
module SystolicArray #(parameter SIZE = 4, parameter DATA_WIDTH = 8)(
    input  logic clk,
    input  logic rst,   
    input  logic clear,
    input  logic signed [DATA_WIDTH-1:0] A_in [SIZE-1:0],
    input  logic signed [DATA_WIDTH-1:0] B_in [SIZE-1:0],
    output logic signed [2*DATA_WIDTH-1:0] C_out [SIZE-1:0][SIZE-1:0],
    output logic done
);

logic signed [DATA_WIDTH-1:0] a_wire [0:SIZE][0:SIZE-1];
logic signed [DATA_WIDTH-1:0] b_wire [0:SIZE-1][0:SIZE];
logic signed [2*DATA_WIDTH-1:0] c_partial [0:SIZE-1][0:SIZE-1];

initial begin
    for (int i = 0; i <= SIZE; i++)
        for (int j = 0; j < SIZE; j++)
            a_wire[i][j] = '0;

    for (int i = 0; i < SIZE; i++)
        for (int j = 0; j <= SIZE; j++)
            b_wire[i][j] = '0;
end

generate
    genvar idx;
    for (idx = 0; idx < SIZE; idx++) begin
        assign a_wire[idx][0] = A_in[idx];
        assign b_wire[0][idx] = B_in[idx];
    end
endgenerate

genvar i, j;
generate
    for (i = 0; i < SIZE; i++)
        for (j = 0; j < SIZE; j++)
        
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
endgenerate

always_comb
    for (int r = 0; r < SIZE; r++)
        for (int c = 0; c < SIZE; c++)
            C_out[r][c] = c_partial[r][c];

logic [15:0] cycle_count;
always_ff @(posedge clk or negedge rst) begin
    if (!rst)
        cycle_count <= 0;
    else if (cycle_count < SIZE*6)
        cycle_count <= cycle_count + 1;
end

assign done = (cycle_count >= 2*SIZE*SIZE);

endmodule
module top_3x3 #(parameter DATA_WIDTH = 8) (
    input  logic clk,
    input  logic rst,
    input  logic clear,

    input  logic signed [DATA_WIDTH-1:0] A_in [2:0],
    input  logic signed [DATA_WIDTH-1:0] B_in [2:0],

    output logic signed [2*DATA_WIDTH-1:0] C_out [2:0][2:0],
    output logic done
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
