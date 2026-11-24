module accel_axi #(
  parameter int N = 4          // 2 to 4: one row of 8-bit values fits in a 32-bit word
) (
  input  logic        s_axi_aclk,
  input  logic        s_axi_aresetn,
  // write address
  input  logic [7:0]  s_axi_awaddr,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  // write data
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  // write response
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  // read address
  input  logic [7:0]  s_axi_araddr,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  // read data
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready
);
  localparam int TW = $clog2(N);

  logic clk, rst;
  assign clk = s_axi_aclk;
  assign rst = !s_axi_aresetn;

  logic [31:0]       a_reg [N];   // a_reg[i] = row i of A
  logic [31:0]       b_reg [N];   // b_reg[k] = row k of B
  logic              start_pulse, busy, done, feeding;
  logic [N*8-1:0]    a_col, b_row;
  logic [N*N*32-1:0] acc_flat;
  int unsigned       t;
  logic [TW-1:0]     ti;
  
  // Lint skips signals whose name contains "unused", so this one is silent.
  logic unused_ok;
  assign unused_ok = &{1'b0, s_axi_wstrb, s_axi_awaddr[1:0], s_axi_araddr[1:0]};

  // ---------------- write channel ----------------
  logic        wr_hs;
  logic [31:0] wr_word;
  assign wr_hs         = s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;
  assign s_axi_awready = wr_hs;
  assign s_axi_wready  = wr_hs;
  assign s_axi_bresp   = 2'b00;
  assign wr_word       = {26'd0, s_axi_awaddr[7:2]};

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axi_bvalid <= 1'b0;
      start_pulse  <= 1'b0;
      for (int i = 0; i < N; i++) begin
        a_reg[i] <= '0;
        b_reg[i] <= '0;
      end
    end else begin
      start_pulse <= 1'b0;
      if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
      if (wr_hs) begin
        s_axi_bvalid <= 1'b1;
        if (wr_word == 0 && s_axi_wdata[0]) start_pulse <= 1'b1;
        for (int i = 0; i < N; i++) begin
          if (wr_word == 4 + i) a_reg[i] <= s_axi_wdata;
          if (wr_word == 8 + i) b_reg[i] <= s_axi_wdata;
        end
      end
    end
  end

  // ---------------- read channel ----------------
  logic [31:0] rd_word, rd_data;
  assign rd_word       = {26'd0, s_axi_araddr[7:2]};
  assign s_axi_arready = s_axi_arvalid && !s_axi_rvalid;
  assign s_axi_rresp   = 2'b00;

  always_comb begin
    rd_data = '0;
    if (rd_word == 1) rd_data = {30'd0, done, busy};
    for (int i = 0; i < N; i++) begin
      if (rd_word == 4 + i) rd_data = a_reg[i];
      if (rd_word == 8 + i) rd_data = b_reg[i];
    end
    for (int m = 0; m < N*N; m++) begin
      if (rd_word == 16 + m) rd_data = acc_flat[m*32 +: 32];
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      s_axi_rvalid <= 1'b0;
      s_axi_rdata  <= '0;
    end else begin
      if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 1'b0;
      if (s_axi_arready) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rdata  <= rd_data;
      end
    end
  end

  // ---------------- feed the core ----------------
  // Same timing as accel_stream: cycle t of a run presents column t of A
  // and row t of B; after N cycles, zeros.
  always_ff @(posedge clk) begin
    if (rst) t <= 0;
    else     t <= busy ? t + 1 : 0;
  end

  assign feeding = busy && (t < N);
  assign ti      = t[TW-1:0];

  always_comb begin
    for (int i = 0; i < N; i++)
      a_col[i*8 +: 8] = feeding ? a_reg[i][ti*8 +: 8] : 8'd0;   // A[i][t]
    b_row = feeding ? b_reg[ti][N*8-1:0] : '0;                   // row t of B
  end

  accel_top #(.N(N)) u_core (
    .clk(clk), .rst(rst), .start(start_pulse),
    .a_col(a_col), .b_row(b_row),
    .busy(busy), .done(done), .acc_flat(acc_flat)
  );
endmodule
