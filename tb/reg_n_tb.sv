module reg_n_tb;
  logic clk = 0, rst, en;
  logic [7:0]  d8,  q8;
  logic [15:0] d16, q16;

  reg_n #(.W(8))  u8  (.clk(clk), .rst(rst), .en(en), .d(d8),  .q(q8));
  reg_n #(.W(64)) u16 (.clk(clk), .rst(rst), .en(en), .d(d16), .q(q16));

  always #5 clk = ~clk;

  initial begin
    rst = 1; en = 0; d8 = 0; d16 = 0;
    @(posedge clk); #1;
    rst = 0; en = 1; d8 = 8'hAB; d16 = 16'hABCD;
    @(posedge clk); #1;
    if (q8 === 8'hAB && q16 === 16'hABCD) $display("PASS");
    else $display("FAIL: q8=%h q16=%h", q8, q16);
    $finish;
  end
endmodule
