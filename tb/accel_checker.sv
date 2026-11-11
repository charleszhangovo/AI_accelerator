module accel_checker #(parameter int N = 4) (
  input  logic              clk,
  input  logic              rst,
  input  logic              start,
  input  logic              busy,
  input  logic              done,
  input  logic [N*N*32-1:0] acc_flat,
  output logic [31:0]       fails
);
  logic   seen_reset, prev_busy, check_zero, started_once;
  integer run_len;

  initial begin
    fails = 0; seen_reset = 0; prev_busy = 0;
    check_zero = 0; started_once = 0; run_len = 0;
  end

  // Every check samples the signals just before a rising edge.
  always @(posedge clk) begin
    // 1. busy and done are never unknown once reset has happened
    if (seen_reset && ((^{busy, done}) === 1'bx)) begin
      fails = fails + 1;
      $display("ASSERT FAIL: busy or done is unknown after reset");
    end

    // 2. busy and done are never high together
    if (busy === 1'b1 && done === 1'b1) begin
      fails = fails + 1;
      $display("ASSERT FAIL: busy and done high together");
    end

    // 3. results contain no unknown bits once a run has started
    if (started_once && ((^acc_flat) === 1'bx)) begin
      fails = fails + 1;
      $display("ASSERT FAIL: unknown bits in the accumulators");
    end

    // 4. accumulators are all zero in the first cycle after start is accepted
    if (check_zero) begin
      if (acc_flat !== '0) begin
        fails = fails + 1;
        $display("ASSERT FAIL: accumulators not zero after start");
      end
      check_zero = 0;
    end
    if (start === 1'b1 && busy === 1'b0 && !rst && seen_reset) begin
      check_zero   = 1;
      started_once = 1;
    end

    // 5. done arrives after exactly 3N-2 busy cycles
    if (done === 1'b1 && prev_busy) begin
      if (run_len != 3*N - 2) begin
        fails = fails + 1;
        $display("ASSERT FAIL: done after %0d busy cycles, expected %0d", run_len, 3*N - 2);
      end
    end
    if (busy === 1'b1) run_len = prev_busy ? run_len + 1 : 1;
    prev_busy = (busy === 1'b1);
     if (rst) seen_reset = 1;
  end
endmodule