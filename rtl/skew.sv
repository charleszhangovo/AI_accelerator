module skew #(parameter int N = 4) (
  input  logic           clk,
  input  logic           clear,
  input  logic [N*8-1:0] in_flat,    // lane k enters at in_flat[k*8 +: 8]
  output logic [N*8-1:0] out_flat    // lane k comes out delayed by k cycles
);
  genvar k;
  generate
    for (k = 0; k < N; k++) begin : g_lane
      if (k == 0) begin : g_nodelay
        assign out_flat[k*8 +: 8] = in_flat[k*8 +: 8];
      end 
      else begin : g_delay
        logic [7:0] stage [k];                 // k registers in a chain
        always_ff @(posedge clk) begin
          if (clear) begin
            for (int s = 0; s < k; s++) stage[s] <= '0;
          end 
          else begin
            stage[0] <= in_flat[k*8 +: 8];
            for (int s = 1; s < k; s++) stage[s] <= stage[s-1];
          end
        end
        assign out_flat[k*8 +: 8] = stage[k-1];
      end
    end
  endgenerate
endmodule
