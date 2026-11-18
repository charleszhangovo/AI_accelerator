module fifo #(
  parameter int W     = 8,
  parameter int DEPTH = 4            // power of 2, at least 2
) (
  input  logic         clk,
  input  logic         rst,          // synchronous, active high
  input  logic         in_valid,     // have date
  output logic         in_ready,     // have space
  input  logic [W-1:0] in_data,
  output logic         out_valid,
  input  logic         out_ready,
  output logic [W-1:0] out_data
);
  localparam int AW = $clog2(DEPTH); // How many bits do we need to address all the FIFO slots?

  logic [W-1:0] mem [DEPTH];
  logic [AW:0]  wr_ptr, rd_ptr;      // one extra bit separates full from empty 
                                     // 000, 001, 010, 011, 100(we can know it's full)

  wire empty = (wr_ptr == rd_ptr);
  wire full  = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]); // the hightest bits are differnt && read = write

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
