module pe (
  input  logic               clk,
  input  logic               clear,
  input  logic               en,
  input  logic signed [7:0]  a_in,
  input  logic signed [7:0]  b_in,
  output logic signed [7:0]  a_out,
  output logic signed [7:0]  b_out,
  output logic signed [31:0] acc
);
  mac u_mac (.clk(clk), .clear(clear), .en(en), .a(a_in), .b(b_in), .acc(acc));

  always_ff @(posedge clk) begin
    if (clear) begin
      a_out <= '0;
      b_out <= '0;
    end else begin
      a_out <= a_in;
`ifdef BUG6
      b_out <= '0;                 // BUG6: B pass-through stuck at zero
`else
      b_out <= b_in;
`endif
    end
  end
endmodule
