module skew_tb;
  localparam int N = 4;
  logic           clk = 0, clear;
  logic [N*8-1:0] in_flat, out_flat;
  logic [7:0]     exp_v;
  integer         errors = 0;

  skew #(.N(N)) dut (.clk(clk), .clear(clear), .in_flat(in_flat), .out_flat(out_flat));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, skew_tb);
    clear = 1; in_flat = '0;
    @(negedge clk);          
    clear = 0;

    for (int t = 0; t < 10; t++) begin
      @(negedge clk);
      for (int k = 0; k < N; k++) in_flat[k*8 +: 8] = t + 1;   // same value on every lane
      #1;
      for (int k = 0; k < N; k++) begin
        exp_v = (t >= k) ? (t - k + 1) : 8'd0;
        if (out_flat[k*8 +: 8] !== exp_v) begin
          errors = errors + 1;
          $display("MISMATCH t=%0d lane=%0d got %0d expected %0d", t, k, out_flat[k*8 +: 8], exp_v);
        end
      end
    end

    if (errors == 0) $display("PASS");
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule