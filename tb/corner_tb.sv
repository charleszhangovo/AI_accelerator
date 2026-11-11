module corner_tb;
  parameter int N = 4;
  logic              clk = 0, rst, start;
  logic [N*8-1:0]    a_col, b_row;
  logic              busy, done;
  logic [N*N*32-1:0] acc_flat;
  wire  [31:0]       chk_fails;

  logic [7:0]  mem_a [0:65535];
  logic [7:0]  mem_b [0:65535];
  logic [31:0] mem_c [0:65535];
  reg [8*100:1] a_file, b_file, c_file;
  integer errors = 0;

  accel_top #(.N(N)) dut (.clk(clk), .rst(rst), .start(start), .a_col(a_col),
                          .b_row(b_row), .busy(busy), .done(done), .acc_flat(acc_flat));

  accel_checker #(.N(N)) u_chk (.clk(clk), .rst(rst), .start(start), .busy(busy),
                                .done(done), .acc_flat(acc_flat), .fails(chk_fails));

  always #5 clk = ~clk;

  task automatic check_case(input int c, input string tag);
    integer base;
    logic [31:0] g;
    begin
      base = c * N * N;
      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          g = acc_flat[(i*N + j)*32 +: 32];
          if (g !== mem_c[base + i*N + j]) begin
            errors = errors + 1;
            if (errors <= 10)
              $display("MISMATCH (%s) case %0d C[%0d][%0d]: got %0d expected %0d",
                       tag, c, i, j, $signed(g), $signed(mem_c[base + i*N + j]));
          end
        end
      end
    end
  endtask

  // Runs one matrix pair for the full 3N-2 cycles. Optionally pulses start
  // at cycle poke_cycle, or pulses rst at cycle rst_cycle (-1 means never).
  task automatic run_case(input int c, input int poke_cycle, input int rst_cycle);
    integer base;
    begin
      base = c * N * N;
      @(negedge clk); start = 1;
      @(negedge clk); start = 0;
      for (int cyc = 0; cyc < 3*N - 2; cyc++) begin
        for (int i = 0; i < N; i++) begin
          if (cyc < N) begin
            a_col[i*8 +: 8] = mem_a[base + i*N + cyc];
            b_row[i*8 +: 8] = mem_b[base + cyc*N + i];
          end else begin
            a_col[i*8 +: 8] = 8'd0;
            b_row[i*8 +: 8] = 8'd0;
          end
        end
        start = (cyc == poke_cycle);
        rst   = (cyc == rst_cycle);
        @(negedge clk);
      end
      start = 0; rst = 0;
    end
  endtask

  initial begin
    if (!$value$plusargs("A=%s", a_file)) begin $display("need +A=file"); $finish; end
    if (!$value$plusargs("B=%s", b_file)) begin $display("need +B=file"); $finish; end
    if (!$value$plusargs("C=%s", c_file)) begin $display("need +C=file"); $finish; end
    $readmemh(a_file, mem_a);
    $readmemh(b_file, mem_b);
    $readmemh(c_file, mem_c);
    if ($test$plusargs("DUMP")) begin
      $dumpfile("dump.vcd");
      $dumpvars(0, corner_tb);
    end

    rst = 1; start = 0; a_col = '0; b_row = '0;
    repeat (2) @(posedge clk);
    @(negedge clk); rst = 0;

    // 1. normal run from idle
    run_case(6, -1, -1);
    check_case(6, "normal run");

    // 2. a stray start in the middle of a run must be ignored
    run_case(7, N-1, -1);
    check_case(7, "stray start");
    if (done !== 1'b1) begin
      errors = errors + 1;
      $display("MISMATCH: done not high after the stray-start run");
    end

    // 3. reset in the middle of a run drops the FSM back to idle
    run_case(8, -1, N);
    if (busy !== 1'b0 || done !== 1'b0) begin
      errors = errors + 1;
      $display("MISMATCH: after mid-run reset busy=%b done=%b, expected 0 0", busy, done);
    end
    repeat (5) @(negedge clk);
    if (busy !== 1'b0 || done !== 1'b0) begin
      errors = errors + 1;
      $display("MISMATCH: FSM left idle by itself after reset");
    end

    // 4. a full run after the reset must still be correct
    run_case(9, -1, -1);
    check_case(9, "after reset");

    if (errors == 0 && chk_fails == 0) $display("PASS: N=%0d corner tests, no assertion failures", N);
    else $display("FAIL: N=%0d, %0d output errors, %0d assertion failures", N, errors, chk_fails);
    $finish;
  end
endmodule
