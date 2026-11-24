module pe_tb;
  logic               clk = 0;
  logic               clear, en;
  logic signed [7:0]  a_in, b_in;
  logic signed [7:0]  a_out, b_out;
  logic signed [31:0] acc;
  integer errors = 0;

  pe dut (.clk(clk), .clear(clear), .en(en), .a_in(a_in), .b_in(b_in),
          .a_out(a_out), .b_out(b_out), .acc(acc));

  always #5 clk = ~clk;

  // One cycle: apply inputs, then check acc, a_out, b_out after the edge.
  task automatic step(
    input logic               c,
    input logic               e,
    input logic signed [7:0]  a,
    input logic signed [7:0]  b,
    input logic signed [31:0] exp_acc,
    input logic signed [7:0]  exp_a,
    input logic signed [7:0]  exp_b
  );
    begin
      @(negedge clk);
      clear = c; en = e; a_in = a; b_in = b;
      @(posedge clk);
      #1;
      if (acc !== exp_acc || a_out !== exp_a || b_out !== exp_b) begin
        errors = errors + 1;
        $display("MISMATCH: clear=%b en=%b a=%0d b=%0d | got acc=%0d a_out=%0d b_out=%0d | expected acc=%0d a_out=%0d b_out=%0d",
                 c, e, a, b, acc, a_out, b_out, exp_acc, exp_a, exp_b);
      end
    end
  endtask

  initial begin
    $dumpfile("pe_tb.vcd");
    $dumpvars(0, pe_tb);
    clear = 0; en = 0; a_in = 0; b_in = 0;

    // Warm-up: one unchecked clear cycle. The pipelined MAC applies clear
    // one edge late, so without this the first checked row would see acc = x.
    @(negedge clk);
    clear = 1; en = 0; a_in = 0; b_in = 0;
    @(posedge clk);

    //   clear en   a     b     exp_acc  exp_a  exp_b
    step(1,    0,   0,    0,    0,       0,     0);     // clear lands, acc = 0
    step(0,    1,   1,    5,    0,       1,     5);     // 1 x 5 queued, acc still 0
    step(0,    1,   2,    7,    5,       2,     7);     // 5 lands
    step(0,    1,   0,    0,    19,      0,     0);     // 14 lands: 19
    step(0,    1,   -128, -128, 19,      -128,  -128);  // 0 lands, holds 19
    step(1,    1,   9,    9,    16403,   0,     0);     // 16384 lands; clear queued
    step(0,    0,   3,    4,    0,       3,     4);     // clear lands; en low

    if (errors == 0) $display("PASS");
    else             $display("FAIL: %0d mismatches found.", errors);
    $finish;
  end
endmodule