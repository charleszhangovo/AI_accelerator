module axi_tb;
  parameter int N = 4;
  logic        clk = 0, aresetn = 0;
  logic [7:0]  awaddr = 0, araddr = 0;
  logic        awvalid = 0, wvalid = 0, arvalid = 0;
  logic        bready = 1, rready = 1;      // the "CPU" always accepts responses
  logic [31:0] wdata = 0;
  logic [3:0]  wstrb = 4'hF;
  logic        awready, wready, bvalid, arready, rvalid;
  logic [1:0]  bresp, rresp;
  logic [31:0] rdata;

  logic [7:0]  mem_a [0:65535];
  logic [7:0]  mem_b [0:65535];
  logic [31:0] mem_c [0:65535];
  reg [8*100:1] a_file, b_file, c_file;
  integer ncases, base, waited, case_err;
  integer errors = 0, bad_cases = 0;
  logic [31:0] word, got, st;

  accel_axi #(.N(N)) dut (
    .s_axi_aclk(clk), .s_axi_aresetn(aresetn),
    .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready)
  );

  always #5 clk = ~clk;

  // One AXI-Lite write, like the CPU storing to a register.
  task automatic axi_write(input logic [7:0] addr, input logic [31:0] data);
    begin
      @(negedge clk);
      awaddr = addr; wdata = data; awvalid = 1; wvalid = 1;
      #1;
      while (!(awready && wready)) begin @(negedge clk); #1; end
      @(posedge clk);                 // handshake happens on this edge
      @(negedge clk);
      awvalid = 0; wvalid = 0;
      if (bvalid !== 1'b1 || bresp !== 2'b00) begin
        errors = errors + 1;
        $display("MISMATCH: bad write response at addr %h", addr);
      end
    end
  endtask

  // One AXI-Lite read, like the CPU loading a register.
  task automatic axi_read(input logic [7:0] addr, output logic [31:0] data);
    begin
      @(negedge clk);
      araddr = addr; arvalid = 1;
      #1;
      while (!arready) begin @(negedge clk); #1; end
      @(posedge clk);                 // handshake; rdata is registered here
      @(negedge clk);
      arvalid = 0;
      if (rvalid !== 1'b1) begin
        errors = errors + 1;
        $display("MISMATCH: rvalid low after read at addr %h", addr);
      end
      data = rdata;
    end
  endtask

  initial begin
    if (!$value$plusargs("A=%s", a_file))     begin $display("need +A=file");      $finish; end
    if (!$value$plusargs("B=%s", b_file))     begin $display("need +B=file");      $finish; end
    if (!$value$plusargs("C=%s", c_file))     begin $display("need +C=file");      $finish; end
    if (!$value$plusargs("CASES=%d", ncases)) begin $display("need +CASES=count"); $finish; end
    $readmemh(a_file, mem_a);
    $readmemh(b_file, mem_b);
    $readmemh(c_file, mem_c);
    if ($test$plusargs("DUMP")) begin
      $dumpfile("dump.vcd");
      $dumpvars(0, axi_tb);
    end

    repeat (3) @(posedge clk);
    @(negedge clk); aresetn = 1;

    // Sanity: a register reads back what was written, and STATUS is 0 after reset.
    axi_read(8'h04, st);
    if (st !== 32'h0) begin
      errors = errors + 1;
      $display("MISMATCH: STATUS after reset is %h, expected 0", st);
    end
    axi_write(8'h10, 32'hA5A5_1234);
    axi_read(8'h10, word);
    if (word !== 32'hA5A5_1234) begin
      errors = errors + 1;
      $display("MISMATCH: A_ROW[0] readback %h", word);
    end

    for (int c = 0; c < ncases; c++) begin
      base = c * N * N;
      case_err = 0;

      // Write A: one row per word, A[i][j] in byte j.
      for (int i = 0; i < N; i++) begin
        word = '0;
        for (int j = 0; j < N; j++) word[j*8 +: 8] = mem_a[base + i*N + j];
        axi_write(8'h10 + 4*i, word);
      end
      // Write B: one row per word, B[k][j] in byte j.
      for (int k = 0; k < N; k++) begin
        word = '0;
        for (int j = 0; j < N; j++) word[j*8 +: 8] = mem_b[base + k*N + j];
        axi_write(8'h20 + 4*k, word);
      end

      axi_write(8'h00, 32'h1);        // start

      // Wait until busy is seen, so a stale done from the last run can't fool us.
      st = '0; waited = 0;
      while (st[0] !== 1'b1 && waited < 20) begin
        axi_read(8'h04, st);
        waited = waited + 1;
      end
      if (st[0] !== 1'b1) begin
        errors = errors + 1;
        $display("MISMATCH: case %0d never showed busy", c);
      end
      // Then poll until done.
      waited = 0;
      while (st[1] !== 1'b1 && waited < 100) begin
        axi_read(8'h04, st);
        waited = waited + 1;
      end
      if (st[1] !== 1'b1) begin
        $display("FAIL: case %0d never reached done", c);
        $finish;
      end

      // Read C and compare with NumPy.
      for (int m = 0; m < N*N; m++) begin
        axi_read(8'h40 + 4*m, got);
        if (got !== mem_c[base + m]) begin
          case_err = case_err + 1;
          errors = errors + 1;
          if (errors <= 10)
            $display("MISMATCH case %0d C[%0d][%0d]: got %0d expected %0d",
                     c, m / N, m % N, $signed(got), $signed(mem_c[base + m]));
        end
      end
      if (case_err != 0) bad_cases = bad_cases + 1;
    end

    if (errors == 0) $display("PASS: N=%0d, %0d cases over AXI-Lite", N, ncases);
    else             $display("FAIL: N=%0d, %0d of %0d cases wrong, %0d errors", N, bad_cases, ncases, errors);
    $finish;
  end
endmodule
