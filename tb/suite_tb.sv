module suite_tb;
  parameter int N = 4;
  logic              clk = 0, rst, start;
  logic [N*8-1:0]    a_col, b_row;
  logic              busy, done;
  logic [N*N*32-1:0] acc_flat;

  logic [7:0]  mem_a [0:65535];
  logic [7:0]  mem_b [0:65535];
  logic [31:0] mem_c [0:65535];
  logic [31:0] got;
  reg [8*100:1] a_file, b_file, c_file;
  wire [31:0] chk_fails; 
  integer ncases, base, waited;
  integer errors = 0;
  integer bad_cases = 0;
  integer case_errors;

  accel_top #(.N(N)) dut (.clk(clk), .rst(rst), .start(start), .a_col(a_col),
                          .b_row(b_row), .busy(busy), .done(done), .acc_flat(acc_flat));
  accel_checker #(.N(N)) u_chk (.clk(clk), .rst(rst), .start(start), .busy(busy),
                                .done(done), .acc_flat(acc_flat), .fails(chk_fails));

  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("A=%s", a_file))      begin $display("need +A=file");     $finish; end
    if (!$value$plusargs("B=%s", b_file))      begin $display("need +B=file");     $finish; end
    if (!$value$plusargs("C=%s", c_file))      begin $display("need +C=file");     $finish; end
    if (!$value$plusargs("CASES=%d", ncases))  begin $display("need +CASES=count"); $finish; end
    $readmemh(a_file, mem_a);
    $readmemh(b_file, mem_b);
    $readmemh(c_file, mem_c);
    if ($test$plusargs("DUMP")) begin       // waveforms only when you ask: they get big
      $dumpfile("dump.vcd");
      $dumpvars(0, suite_tb);
    end

    rst = 1; start = 0; a_col = '0; b_row = '0;
    repeat (2) @(posedge clk);
    @(negedge clk); rst = 0;

    for (int c = 0; c < ncases; c++) begin
      base = c * N * N;
      case_errors = 0;

      @(negedge clk); start = 1;       // no reset between cases: back-to-back runs
      @(negedge clk); start = 0;

      for (int t = 0; t < N; t++) begin
        for (int i = 0; i < N; i++) begin
          a_col[i*8 +: 8] = mem_a[base + i*N + t];   // A[i][t]
          b_row[i*8 +: 8] = mem_b[base + t*N + i];   // B[t][i]
        end
        @(negedge clk);
      end
      a_col = '0; b_row = '0;

      waited = 0;
      while (!done && waited < 100*N) begin
        @(negedge clk);
        waited = waited + 1;
      end
      if (!done) begin
        $display("FAIL: done never rose in case %0d", c);
        $finish;
      end

      for (int i = 0; i < N; i++) begin
        for (int j = 0; j < N; j++) begin
          got = acc_flat[(i*N + j)*32 +: 32];
          if (got !== mem_c[base + i*N + j]) begin
            case_errors = case_errors + 1;
            errors = errors + 1;
            if (errors <= 10)
              $display("MISMATCH case %0d C[%0d][%0d]: got %0d expected %0d",
                       c, i, j, $signed(got), $signed(mem_c[base + i*N + j]));
          end
        end
      end
      if (case_errors != 0) bad_cases = bad_cases + 1;
    end

    if (errors == 0 && chk_fails == 0)
      $display("PASS: N=%0d, %0d cases, no assertion failures", N, ncases);
    else
      $display("FAIL: N=%0d, %0d of %0d cases wrong (%0d wrong outputs), %0d assertion failures",
               N, bad_cases, ncases, errors, chk_fails);
    $finish;
  end
endmodule