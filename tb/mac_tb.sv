module mac_tb;
  logic               clk = 0;
  logic               clear, en;
  logic signed [7:0]  a, b;
  logic signed [31:0] acc;

  logic [17:0] stim [0:4095]; //enough big power for future tests
  logic [31:0] expv [0:4095];
  reg [8*100:1] stim_file, exp_file; // choose 800 cause simply large enough for FILE NAME, 100 chars
  integer n, i, errors;

  mac dut (.clk(clk), .clear(clear), .en(en), .a(a), .b(b), .acc(acc));

  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("STIM=%s", stim_file)) begin $display("need +STIM=file"); $finish; end
    if (!$value$plusargs("EXP=%s", exp_file))   begin $display("need +EXP=file");  $finish; end
    if (!$value$plusargs("N=%d", n))            begin $display("need +N=count");   $finish; end
    $dumpfile("dump.vcd");
    $dumpvars(0, mac_tb);
    $readmemh(stim_file, stim);
    $readmemh(exp_file, expv);
    errors = 0;
    clear = 0; en = 0; a = 0; b = 0;

    for (i = 0; i < n; i = i + 1) begin
      @(negedge clk);
      {clear, en, a, b} = stim[i];   // conebine and assign the value
      @(posedge clk);
      #1;                            // let acc settle after the edge
      if (acc !== expv[i]) begin
        errors = errors + 1;
        if (errors <= 5)
          $display("MISMATCH cycle %0d: clear=%b en=%b a=%0d b=%0d got %0d expected %0d",
                   i, clear, en, a, b, acc, $signed(expv[i]));
      end
    end

    if (errors == 0) $display("PASS: %0d cycles", n);
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule
