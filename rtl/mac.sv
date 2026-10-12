module mac (
  input  logic               clk,
  input  logic               clear,
  input  logic               en,
  input  logic signed [7:0]  a,
  input  logic signed [7:0]  b,
  output logic signed [31:0] acc
);
  logic signed [15:0] product;
  logic signed [31:0] product_acc;

  mult8 u_mult (.a(a), .b(b), .p(product));
  assign
    product_acc = {{16{product[15]}},product}; // sign-extend to 32 bits, since the product is 16bits

  always_ff @(posedge clk) begin
    if (clear)     acc <= 32'b0;
    else if (en)   acc <= acc + product_acc;
  end
endmodule
