module reg8 (
  input            clk,
  input            rst,   // synchronous, active high
  input            en,
  input      [7:0] d,
  output reg [7:0] q
);
    always @(posedge clk) begin
        if (rst) 
        q <= 8'h00;
        else if (en)
        q <= d;  
    end
endmodule