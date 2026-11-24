module mac (
  input  logic               clk,
  input  logic               clear,
  input  logic               en,
  input  logic signed [7:0]  a,
  input  logic signed [7:0]  b,
  output logic signed [31:0] acc
);
  logic signed [15:0] product, prod_r;
  logic signed [31:0] product_ext;
  logic               en_d, clear_d;

  mult8 u_mult (.a(a), .b(b), .p(product));

`ifdef BUG3
  assign product_ext = {16'b0, prod_r};                  // BUG3: zero-extends
`else
  assign product_ext = {{16{prod_r[15]}}, prod_r};       // sign-extends
`endif

  // Stage 1: multiply and register. A cycle with clear or en low adds nothing.
  always_ff @(posedge clk) begin
    prod_r  <= product;
    en_d    <= en && !clear;
    clear_d <= clear;
  end

  // Stage 2: accumulate. clear wins over en, as before.
  always_ff @(posedge clk) begin
    if (clear_d)   acc <= '0;
    else if (en_d) acc <= acc + product_ext;
  end
endmodule
