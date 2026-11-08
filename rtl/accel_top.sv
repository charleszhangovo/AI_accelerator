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

  array_ctrl #(.N(N)) u_ctrl (
    .clk(clk), .rst(rst), .start(start),
    .clear(clear), .en(en), .busy(busy), .done(done)
  );

  skew #(.N(N)) u_skew_a (.clk(clk), .clear(clear), .in_flat(a_col), .out_flat(a_skewed));
  skew #(.N(N)) u_skew_b (.clk(clk), .clear(clear), .in_flat(b_row), .out_flat(b_skewed));

  systolic_array #(.N(N)) u_array (
    .clk(clk), .clear(clear), .en(en),
    .a_left(a_skewed), .b_top(b_skewed), .acc_flat(acc_flat)
  );
endmodule
