module accel_checker #(parameter int N = 4) (
  input  logic              clk,
  input  logic              rst,
  input  logic              start,
  input  logic              busy,
  input  logic              done,
  input  logic [N*N*32-1:0] acc_flat,
  output logic [31:0]       fails
);
  logic   seen_reset, prev_busy, started_once;
  logic   zero_a, zero_b;     // pipeline for rule 4: check two edges after start
  integer run_len;

  initial begin
    fails = 0; seen_reset = 0; prev_busy = 0;
    started_once = 0; zero_a = 0; zero_b = 0; run_len = 0;
  end

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

    // 4. accumulators are zero two edges after start is accepted
    if (zero_b) begin
      if (acc_flat !== '0) begin
        fails = fails + 1;
        $display("ASSERT FAIL: accumulators not zero after start");
      end
    end
    if (zero_b) started_once = 1;
    zero_b = zero_a;
    zero_a = (start === 1'b1 && busy === 1'b0 && !rst && seen_reset);

    // 5. done arrives after exactly 3N-1 busy cycles
    if (done === 1'b1 && prev_busy) begin
      if (run_len != 3*N - 1) begin
        fails = fails + 1;
        $display("ASSERT FAIL: done after %0d busy cycles, expected %0d", run_len, 3*N - 1);
      end
    end
    if (busy === 1'b1) run_len = prev_busy ? run_len + 1 : 1;
    prev_busy = (busy === 1'b1);

    // set last, so rule 1 only applies after a reset edge has already happened
    if (rst) seen_reset = 1;
  end
endmodule
