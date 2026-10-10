module reg8_tb;
  reg clk = 0;
  reg rst, en;
  reg [7:0] d;
  wire [7:0] q;
  integer errors = 0;

  reg8 dut (.clk(clk), .rst(rst), .en(en), .d(d), .q(q));

  always #5 clk = ~clk; // 100 MHz clock

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, reg8_tb);

    // example check: reset clears the register
    rst = 1; en = 0; d = 8'hBB;
    @(posedge clk); #1;
    if (q !== 8'h00) begin 
        $display("FAIL: reset"); 
        errors = errors + 1; 
    end
    
    rst = 0; en = 1;
    @(posedge clk); #1;
    if (q !== 8'hBB) begin 
        $display("FAIL: enable"); 
        errors = errors + 1; 
    end
    
    rst = 1; en = 1;
    @(posedge clk); #1;
    if (q !== 8'h00) begin 
        $display("FAIL: reset and enable"); 
        errors = errors + 1; 
    end

    if (errors == 0) $display("PASS");
    else $display("FAIL: %0d errors", errors);
    $finish;
  end
endmodule