module mult8 (
  input  logic signed [7:0]  a,
  input  logic signed [7:0]  b,
  output logic signed [15:0] p
);
  always_comb p = a * b;
endmodule
