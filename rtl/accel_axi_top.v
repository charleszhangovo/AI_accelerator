// Plain-Verilog shell so Vivado's block design can reference the accelerator.
module accel_axi_top #(parameter N = 4) (
  input  wire        s_axi_aclk,
  input  wire        s_axi_aresetn,
  input  wire [7:0]  s_axi_awaddr,
  input  wire        s_axi_awvalid,
  output wire        s_axi_awready,
  input  wire [31:0] s_axi_wdata,
  input  wire [3:0]  s_axi_wstrb,
  input  wire        s_axi_wvalid,
  output wire        s_axi_wready,
  output wire [1:0]  s_axi_bresp,
  output wire        s_axi_bvalid,
  input  wire        s_axi_bready,
  input  wire [7:0]  s_axi_araddr,
  input  wire        s_axi_arvalid,
  output wire        s_axi_arready,
  output wire [31:0] s_axi_rdata,
  output wire [1:0]  s_axi_rresp,
  output wire        s_axi_rvalid,
  input  wire        s_axi_rready
);
  accel_axi #(.N(N)) u_accel (
    .s_axi_aclk(s_axi_aclk),       .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr),   .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),     .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),   .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),     .s_axi_bvalid(s_axi_bvalid),   .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),   .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),     .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),   .s_axi_rready(s_axi_rready)
  );
endmodule
