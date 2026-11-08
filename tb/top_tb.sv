module top_tb;
  parameter int N = 4;
  logic              clk = 0, rst, start;
  logic [N*8-1:0]    a_col, b_row;
  logic              busy, done;
  logic [N*N*32-1:0] acc_flat;

  logic [7:0]  mem_a [0:N*N-1];
  logic [7:0]  mem_b [0:N*N-1];
  logic [31:0] mem_c [0:N*N-1];
  logic [31:0] got;
  reg [8*100:1] a_file, b_file, c_file;
  integer errors = 0;
  integer waited = 0;

  accel_top #(.N(N)) dut (.clk(clk), .rst(rst), .start(start), .a_col(a_col),
                          .b_row(b_row), .busy(busy), .done(done), .acc_flat(acc_flat));

  always #5 clk = ~clk;

  initial begin
    if (!$value$plusargs("A=%s", a_file)) begin $display("need +A=file"); $finish; end
    if (!$value$plusargs("B=%s", b_file)) begin $display("need +B=file"); $finish; end
    if (!$value$plusargs("C=%s", c_file)) begin $display("need +C=file"); $finish; end
    $readmemh(a_file, mem_a);
    $readmemh(b_file, mem_b);
    $readmemh(c_file, mem_c);
    $dumpfile("dump.vcd");
    $dumpvars(0, top_tb);

    rst = 1; start = 0; a_col = '0; b_row = '0;
    repeat (2) @(posedge clk);
    @(negedge clk); rst = 0;

    @(negedge clk); start = 1;       // start is high across the next rising edge
    @(negedge clk); start = 0;       // that edge accepted start, so we are now in cycle 0

    for (int t = 0; t < N; t++) begin   // cycle t: column t of A and row t of B
      for (int i = 0; i < N; i++) begin
        a_col[i*8 +: 8] = mem_a[i*N + t];   // A[i][t]
        b_row[i*8 +: 8] = mem_b[t*N + i];   // B[t][i]
      end
      @(negedge clk);
    end
    a_col = '0; b_row = '0;          // from cycle N on, feed zeros

    while (!done && waited < 100*N) begin
      @(negedge clk);
      waited = waited + 1;
    end
    if (!done) begin
      $display("FAIL: done never rose");
      $finish;
    end

    for (int i = 0; i < N; i++) begin
      for (int j = 0; j < N; j++) begin
        got = acc_flat[(i*N + j)*32 +: 32];
        if (got !== mem_c[i*N + j]) begin
          errors = errors + 1;
          $display("MISMATCH C[%0d][%0d]: got %0d expected %0d",
                   i, j, $signed(got), $signed(mem_c[i*N + j]));
        end
      end
    end

    if (errors == 0) $display("PASS: %0d x %0d result matches NumPy", N, N);
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule
