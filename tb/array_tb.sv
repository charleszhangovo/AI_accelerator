module array_tb;
  localparam int N = 2;
  logic clk = 0, clear, en;
  logic [N*8-1:0]    a_left, b_top;
  logic [N*N*32-1:0] acc_flat;
  integer errors = 0;

  systolic_array #(.N(N)) dut (.clk(clk), .clear(clear), .en(en),
                               .a_left(a_left), .b_top(b_top), .acc_flat(acc_flat));

  always #5 clk = ~clk;

  // One clock cycle. a0,a1 feed rows 0 and 1 from the left.
  // b0,b1 feed columns 0 and 1 from the top.
  task automatic cycle(input logic c, input logic [7:0] a0, a1, b0, b1);
    begin
      @(negedge clk);
      clear = c; en = 1;
      a_left = {a1, a0};
      b_top  = {b1, b0};
      @(posedge clk);
      #1;
    end
  endtask

  task automatic check(input int i, input int j, input int expected);
    logic signed [31:0] got;
    begin
      got = acc_flat[(i*N+j)*32 +: 32];
      if (got !== expected) begin
        errors = errors + 1;
        $display("MISMATCH PE(%0d,%0d): got %0d expected %0d", i, j, got, expected);
      end
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, array_tb);
    clear = 0; en = 0; a_left = 0; b_top = 0;

    cycle(1, 0, 0, 0, 0);   // clear
    cycle(0, 3, 0, 4, 0);   // PE(0,0) sees 3 x 4
    cycle(0, 0, 6, 0, 5);   // PE(0,1) sees 3 x 5, PE(1,0) sees 6 x 4
    cycle(0, 0, 0, 0, 0);   // PE(1,1) sees 6 x 5

    check(0, 0, 12);
    check(0, 1, 15);
    check(1, 0, 24);
    check(1, 1, 30);

    if (errors == 0) $display("PASS");
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule
