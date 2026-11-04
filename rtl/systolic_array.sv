module systolic_array #(parameter int N = 4) (
  input  logic              clk,
  input  logic              clear,
  input  logic              en,
  input  logic [N*8-1:0]    a_left,    // row i enters at a_left[i*8 +: 8]
  input  logic [N*8-1:0]    b_top,     // column j enters at b_top[j*8 +: 8]
  output logic [N*N*32-1:0] acc_flat   // PE(i,j) result is acc_flat[(i*N+j)*32 +: 32]
);
  // a_w: A values moving right. Row i has N+1 slots: slot 0 is the left edge,
  // slot j+1 is PE(i,j)'s a_out.
  /* verilator lint_off UNUSEDSIGNAL */
  logic [N*(N+1)*8-1:0] a_w;
  // b_w: B values moving down. Column j has N+1 slots: slot 0 is the top edge,
  // slot i+1 is PE(i,j)'s b_out.
  logic [(N+1)*N*8-1:0] b_w;
  /* verilator lint_on UNUSEDSIGNAL */

  genvar i, j;
  generate
    for (i = 0; i < N; i++) begin : g_edge_a
      assign a_w[(i*(N+1))*8 +: 8] = a_left[i*8 +: 8];
    end
    for (j = 0; j < N; j++) begin : g_edge_b
      assign b_w[j*8 +: 8] = b_top[j*8 +: 8];
    end
    for (i = 0; i < N; i++) begin : g_row
      for (j = 0; j < N; j++) begin : g_col
        pe u_pe (
          .clk  (clk),
          .clear(clear),
          .en   (en),
          .a_in (a_w[(i*(N+1)+j)*8 +: 8]),
          .b_in (b_w[(i*N+j)*8 +: 8]),
          .a_out(a_w[(i*(N+1)+j+1)*8 +: 8]),
          .b_out(b_w[((i+1)*N+j)*8 +: 8]),
          .acc  (acc_flat[(i*N+j)*32 +: 32])
        );
      end
    end
  endgenerate
endmodule      

