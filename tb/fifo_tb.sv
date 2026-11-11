module fifo_tb;
  localparam int W     = 8;
  localparam int DEPTH = 4;
  logic         clk = 0, rst;
  logic         in_valid, in_ready, out_valid, out_ready;
  logic [W-1:0] in_data, out_data;
  integer errors = 0, pushes = 0, pops = 0, occ, seed = 1;
  bit saw_full = 0, saw_empty = 0;

  fifo #(.W(W), .DEPTH(DEPTH)) dut (.clk(clk), .rst(rst),
    .in_valid(in_valid), .in_ready(in_ready), .in_data(in_data),
    .out_valid(out_valid), .out_ready(out_ready), .out_data(out_data));

  always #5 clk = ~clk;

  // Scoreboard: samples just before every rising edge. Item n carries data n mod 256,
  // so the item at the head of the FIFO must always equal the number of pops so far.
  always @(posedge clk) begin
    if (!rst) begin
      occ = pushes - pops;
      if (in_ready !== (occ < DEPTH)) begin
        errors = errors + 1;
        $display("MISMATCH: in_ready=%b with %0d items stored", in_ready, occ);
      end
      if (out_valid !== (occ > 0)) begin
        errors = errors + 1;
        $display("MISMATCH: out_valid=%b with %0d items stored", out_valid, occ);
      end
      if (out_valid === 1'b1 && out_data !== pops[7:0]) begin
        errors = errors + 1;
        $display("MISMATCH: head is %0d, expected %0d", out_data, pops[7:0]);
      end
      if (occ == DEPTH) saw_full = 1;
      if (occ == 0 && pops > 0) saw_empty = 1;
      if (in_valid && in_ready)   pushes = pushes + 1;
      if (out_valid && out_ready) pops   = pops + 1;
    end
  end

  task automatic drive(input logic v, input logic r);
    begin
      @(negedge clk);
      in_valid  = v;
      out_ready = r;
      in_data   = pushes[7:0];
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, fifo_tb);
    rst = 1; in_valid = 0; out_ready = 0; in_data = 0;
    repeat (2) @(posedge clk);
    @(negedge clk); rst = 0;

    // 1. fill with no consumer: only DEPTH items may get in
    repeat (DEPTH + 3) drive(1, 0);
    drive(0, 0);
    if (pushes != DEPTH) begin
      errors = errors + 1;
      $display("MISMATCH: %0d items accepted, expected %0d", pushes, DEPTH);
    end

    // 2. drain everything
    repeat (DEPTH + 2) drive(0, 1);
    drive(0, 0);
    if (pops != DEPTH) begin
      errors = errors + 1;
      $display("MISMATCH: %0d items drained, expected %0d", pops, DEPTH);
    end

    // 3. random traffic: mostly pushing, mostly popping, and balanced
    for (int c = 0; c < 2000; c++)
      drive(({$random(seed)} % 4) != 0, ({$random(seed)} % 4) == 0);
    for (int c = 0; c < 2000; c++)
      drive(({$random(seed)} % 4) == 0, ({$random(seed)} % 4) != 0);
    for (int c = 0; c < 2000; c++)
      drive(({$random(seed)} % 2) == 0, ({$random(seed)} % 2) == 0);

    // 4. drain and compare totals
    repeat (DEPTH + 2) drive(0, 1);
    drive(0, 0);
    if (pushes != pops) begin
      errors = errors + 1;
      $display("MISMATCH: %0d pushed but %0d popped", pushes, pops);
    end
    if (!saw_full || !saw_empty) begin
      errors = errors + 1;
      $display("MISMATCH: test never reached full (%b) or empty (%b)", saw_full, saw_empty);
    end

    if (errors == 0) $display("PASS: %0d items through the FIFO, full and empty both reached", pushes);
    else             $display("FAIL: %0d errors", errors);
    $finish;
  end
endmodule
