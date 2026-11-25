module asic_top4 (
  input  logic         clk,
  input  logic         rst,
  input  logic         start,
  input  logic [31:0]  a_col,
  input  logic [31:0]  b_row,
  output logic         busy,
  output logic         done,
  output logic [511:0] acc_flat
);
  accel_top #(.N(4)) u_core (
    .clk(clk), .rst(rst), .start(start),
    .a_col(a_col), .b_row(b_row),
    .busy(busy), .done(done), .acc_flat(acc_flat)
  );
endmodule
