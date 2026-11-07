module ctrl_tb;
  parameter int N = 4;
  logic clk = 0, rst, start;
  logic clear, en, busy, done;
  integer errors = 0;
  integer cycles;

  array_ctrl #(.N(N)) dut (.clk(clk), .rst(rst), .start(start),
                           .clear(clear), .en(en), .busy(busy), .done(done));

  always #5 clk = ~clk;

  task automatic expect_state(input string what, input logic e_busy, input logic e_done);
    begin
      if (busy !== e_busy || done !== e_done || en !== e_busy) begin
        errors = errors + 1;
        $display("MISMATCH (%s): busy=%b done=%b en=%b, expected busy=%b done=%b",
                 what, busy, done, en, e_busy, e_done);
      end
    end
  endtask

  // Start one run, measure how many cycles busy stays high.
  // If poke_mid is set, pulse start again during the run: it must be ignored.
  task automatic run_once(input bit poke_mid);
    begin
      @(negedge clk);
      start = 1;
      #1;
      if (clear !== 1'b1) begin
        errors = errors + 1;
        $display("MISMATCH: clear should be high when start is accepted");
      end
      @(posedge clk); #1;            // this edge accepts start
      start = 0;
      expect_state("first run cycle", 1, 0);
      cycles = 0;
      while (busy) begin
        cycles = cycles + 1;
        start = (poke_mid && cycles == 2);   // At cycles = 2, we deliberately send another start = 1 while the FSM is already running.
        #1;
        if (clear !== 1'b0) begin
          errors = errors + 1;
          $display("MISMATCH: clear high during a run");
        end
        @(posedge clk); #1; //allows its updated outputs to settle.
      end
      start = 0;
      if (cycles != 3*N - 2) begin
        errors = errors + 1;
        $display("MISMATCH: run lasted %0d cycles, expected %0d", cycles, 3*N - 2);
      end
      expect_state("done", 0, 1);
      repeat (3) begin
        @(posedge clk); #1;
        expect_state("done holds", 0, 1);
      end
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, ctrl_tb);
    rst = 1; start = 0;
    @(posedge clk);
    #1 rst = 0;
    expect_state("idle after reset", 0, 0);
    repeat (3) @(posedge clk);
    #1;
    expect_state("idle holds", 0, 0);

    run_once(0);   // start from idle
    run_once(1);   // start from done, with a stray start mid-run

    if (errors == 0) $display("PASS: done after %0d cycles", 3*N - 2);
    else             $display("FAIL: %0d errors", errors);
    $finish;
  end
endmodule
