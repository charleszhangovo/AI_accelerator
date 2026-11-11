module stream_tb;
  parameter int N = 4;
  logic              clk = 0, rst;
  logic              a_valid = 0, b_valid = 0, res_ready = 0;
  logic              a_ready, b_ready, res_valid;
  logic [N*8-1:0]    a_data, b_data;
  logic [N*N*32-1:0] acc_flat;

  logic [7:0]  mem_a [0:65535];
  logic [7:0]  mem_b [0:65535];
  logic [31:0] mem_c [0:65535];
  reg [8*100:1] a_file, b_file, c_file;
  integer ncases, stall_pct, cyc;
  integer errors = 0, checked = 0, seed = 7;
  integer a_bp = 0, b_bp = 0;
  integer a_c = 0, a_t = 0, b_c = 0, b_t = 0;
  logic   a_fire = 0, b_fire = 0;

  logic [N*N*32-1:0] held;
  logic              held_ok = 0;
  logic [31:0]       g;

  accel_stream #(.N(N)) dut (
    .clk(clk), .rst(rst),
    .a_valid(a_valid), .a_ready(a_ready), .a_data(a_data),
    .b_valid(b_valid), .b_ready(b_ready), .b_data(b_data),
    .res_valid(res_valid), .res_ready(res_ready), .acc_flat(acc_flat)
  );

  always #5 clk = ~clk;

  // Just before each rising edge: did a transfer happen, and was there backpressure?
  always @(posedge clk) begin
    a_fire = (a_valid === 1'b1) && (a_ready === 1'b1);
    b_fire = (b_valid === 1'b1) && (b_ready === 1'b1);
    if (a_valid === 1'b1 && a_ready === 1'b0) a_bp = a_bp + 1;
    if (b_valid === 1'b1 && b_ready === 1'b0) b_bp = b_bp + 1;
  end

  // Sender for A and B, changing signals only on the falling edge.
  always @(negedge clk) begin
    if (rst === 1'b0) begin
      if (a_fire) begin
        a_valid = 0;
        a_t = a_t + 1;
        if (a_t == N) begin a_t = 0; a_c = a_c + 1; end
      end
      if (!a_valid) begin
        if (a_c < ncases && ({$random(seed)} % 100) >= stall_pct) begin
          a_valid = 1;
          for (int i = 0; i < N; i++) a_data[i*8 +: 8] = mem_a[a_c*N*N + i*N + a_t];  // A[i][t]
        end else begin
          for (int i = 0; i < N; i++) a_data[i*8 +: 8] = $random(seed);               // junk
        end
      end

      if (b_fire) begin
        b_valid = 0;
        b_t = b_t + 1;
        if (b_t == N) begin b_t = 0; b_c = b_c + 1; end
      end
      if (!b_valid) begin
        if (b_c < ncases && ({$random(seed)} % 100) >= stall_pct) begin
          b_valid = 1;
          for (int j = 0; j < N; j++) b_data[j*8 +: 8] = mem_b[b_c*N*N + b_t*N + j];  // B[t][j]
        end else begin
          for (int j = 0; j < N; j++) b_data[j*8 +: 8] = $random(seed);               // junk
        end
      end
    end
    res_ready = ({$random(seed)} % 100) >= stall_pct;
  end

  // Receiver check: compare each result with NumPy when it is taken, and make
  // sure a result never changes while it waits to be taken.
  always @(posedge clk) begin
    if (rst === 1'b0 && res_valid === 1'b1) begin
      if (res_ready === 1'b1) begin
        for (int i = 0; i < N; i++) begin
          for (int j = 0; j < N; j++) begin
            g = acc_flat[(i*N + j)*32 +: 32];
            if (g !== mem_c[checked*N*N + i*N + j]) begin
              errors = errors + 1;
              if (errors <= 10)
                $display("MISMATCH result %0d C[%0d][%0d]: got %0d expected %0d",
                         checked, i, j, $signed(g), $signed(mem_c[checked*N*N + i*N + j]));
            end
          end
        end
        checked = checked + 1;
        held_ok = 0;
      end else begin
        if (held_ok && acc_flat !== held) begin
          errors = errors + 1;
          $display("MISMATCH: result changed while waiting to be taken");
        end
        held = acc_flat;
        held_ok = 1;
      end
    end else begin
      held_ok = 0;
    end
  end

  initial begin
    rst = 1;
    if (!$value$plusargs("A=%s", a_file))        begin $display("need +A=file");      $finish; end
    if (!$value$plusargs("B=%s", b_file))        begin $display("need +B=file");      $finish; end
    if (!$value$plusargs("C=%s", c_file))        begin $display("need +C=file");      $finish; end
    if (!$value$plusargs("CASES=%d", ncases))    begin $display("need +CASES=count"); $finish; end
    if (!$value$plusargs("STALL=%d", stall_pct)) begin $display("need +STALL=percent"); $finish; end
    $readmemh(a_file, mem_a);
    $readmemh(b_file, mem_b);
    $readmemh(c_file, mem_c);
    if ($test$plusargs("DUMP")) begin
      $dumpfile("dump.vcd");
      $dumpvars(0, stream_tb);
    end

    repeat (2) @(posedge clk);
    @(negedge clk); rst = 0;

    cyc = 0;
    while (checked < ncases && cyc < ncases * 200 * N) begin
      @(posedge clk);
      cyc = cyc + 1;
    end
    repeat (30 * N) @(posedge clk);       // leave time for any extra, unexpected result

    if (checked != ncases) begin
      errors = errors + 1;
      $display("MISMATCH: %0d results taken, expected %0d", checked, ncases);
    end
    if (errors == 0)
      $display("PASS: N=%0d, stall=%0d%%, %0d matrices streamed, backpressure cycles A=%0d B=%0d",
               N, stall_pct, ncases, a_bp, b_bp);
    else
      $display("FAIL: N=%0d, stall=%0d%%, %0d errors", N, stall_pct, errors);
    $finish;
  end
endmodule
