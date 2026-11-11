module mac (
  input  logic               clk,
  input  logic               clear,
  input  logic               en,
  input  logic signed [7:0]  a,
  input  logic signed [7:0]  b,
  output logic signed [31:0] acc
);
  logic signed [15:0] product;
  logic signed [31:0] product_ext;

  mult8 u_mult (.a(a), .b(b), .p(product));

`ifdef BUG3
  assign product_ext = {16'b0, product};                 // BUG3: zero-extends
`else
  assign product_ext = {{16{product[15]}}, product};     // sign-extends
`endif

  always_ff @(posedge clk) begin
    if (clear)   acc <= '0;
    else if (en) acc <= acc + product_ext;
  end
endmodule
