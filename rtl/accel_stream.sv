module accel_stream #(parameter int N = 4) (
  input  logic              clk,
  input  logic              rst,
  // A channel: one column of A per beat, N beats per matrix
  input  logic              a_valid,
  output logic              a_ready,
  input  logic [N*8-1:0]    a_data,
  // B channel: one row of B per beat, N beats per matrix
  input  logic              b_valid,
  output logic              b_ready,
  input  logic [N*8-1:0]    b_data,
  // Result: valid until the host takes it
  output logic              res_valid,
  input  logic              res_ready,
  output logic [N*N*32-1:0] acc_flat
);
  logic [N*8-1:0] a_head, b_head, a_col, b_row;
  /* verilator lint_off UNUSEDSIGNAL */
  logic           a_head_valid, b_head_valid;
  /* verilator lint_on UNUSEDSIGNAL */
  logic           busy, done, start, feeding, taken;
  int unsigned    t;                    // which cycle of the run we are in

  fifo #(.W(N*8), .DEPTH(N)) u_fifo_a (
    .clk(clk), .rst(rst),
    .in_valid(a_valid), .in_ready(a_ready), .in_data(a_data),
    .out_valid(a_head_valid), .out_ready(feeding), .out_data(a_head)
  );

  fifo #(.W(N*8), .DEPTH(N)) u_fifo_b (
    .clk(clk), .rst(rst),
    .in_valid(b_valid), .in_ready(b_ready), .in_data(b_data),
    .out_valid(b_head_valid), .out_ready(feeding), .out_data(b_head)
  );

  // Cycles 0 to N-1 of a run take one beat from each FIFO; after that, zeros.
  assign feeding   = busy && (t < N);
  assign a_col     = feeding ? a_head : '0;
  assign b_row     = feeding ? b_head : '0;

  // A finished result waits here until the host takes it.
  assign res_valid = done && !taken;

  // Start a run when both FIFOs are full (not ready), the core is idle,
  // and no finished result is still waiting to be taken.
  assign start     = !rst && !a_ready && !b_ready && !busy && !res_valid;

  accel_top #(.N(N)) u_core (
    .clk(clk), .rst(rst), .start(start),
    .a_col(a_col), .b_row(b_row),
    .busy(busy), .done(done), .acc_flat(acc_flat)
  );

  always_ff @(posedge clk) begin
    if (rst) begin
      t     <= 0;
      taken <= 1'b1;
    end else begin
      t <= busy ? t + 1 : 0;
      if (start)                        taken <= 1'b0;
      else if (res_valid && res_ready)  taken <= 1'b1;
    end
  end
endmodule
