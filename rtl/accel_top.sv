module accel_top #(parameter int N = 4) (
  input  logic              clk,
  input  logic              rst,
  input  logic              start,
  input  logic [N*8-1:0]    a_col,     // column k of A: a_col[i*8 +: 8] = A[i][k]
  input  logic [N*8-1:0]    b_row,     // row k of B:    b_row[j*8 +: 8] = B[k][j]
  output logic              busy,
  output logic              done,
  output logic [N*N*32-1:0] acc_flat
);
  logic           clear, en;
  logic [N*8-1:0] a_skewed, b_skewed;
  logic [N*8-1:0] a_to_array, b_to_array;

  array_ctrl #(.N(N)) u_ctrl (
    .clk(clk), .rst(rst), .start(start),
    .clear(clear), .en(en), .busy(busy), .done(done)
  );

  skew #(.N(N)) u_skew_a (.clk(clk), .clear(clear), .in_flat(a_col), .out_flat(a_skewed));
  skew #(.N(N)) u_skew_b (.clk(clk), .clear(clear), .in_flat(b_row), .out_flat(b_skewed));

  // Normally the skewed values go straight to the array.
  // The BUG switches break one connection for the bug-injection tests.
  always_comb begin
    a_to_array = a_skewed;
    b_to_array = b_skewed;
`ifdef BUG1
    a_to_array[15:8] = a_col[15:8];   // BUG1: lane 1 of A loses its delay
`endif
`ifdef BUG2
    b_to_array[15:8] = b_row[15:8];   // BUG2: lane 1 of B loses its delay
`endif
  end

  systolic_array #(.N(N)) u_array (
    .clk(clk), .clear(clear), .en(en),
    .a_left(a_to_array), .b_top(b_to_array), .acc_flat(acc_flat)
  );
endmodule
