module fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 4            // power of 2, at least 2
) (
  input  logic         clk,
  input  logic         rst,          // synchronous, active high
  input  logic         in_valid,
  output logic         in_ready,
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
  localparam int AW = $clog2(DEPTH);

  logic [W-1:0] mem [DEPTH];
  logic [AW:0]  wr_ptr, rd_ptr;      // one extra bit separates full from empty

  wire empty = (wr_ptr == rd_ptr);
  wire full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);

  assign in_ready  = !full;
  assign out_valid = !empty;
  assign out_data  = mem[rd_ptr[AW-1:0]];

  wire push = in_valid && in_ready;  // a transfer happens when valid and ready are both high
  wire pop  = out_valid && out_ready;

  always_ff @(posedge clk) begin
    if (rst) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      if (push) begin
        mem[wr_ptr[AW-1:0]] <= in_data;
        wr_ptr <= wr_ptr + 1;
      end
      if (pop) rd_ptr <= rd_ptr + 1;
    end
  end
endmodule
