module array_ctrl #(parameter int N = 4) (
  input  logic clk,
  input  logic rst,     // synchronous reset, active high
  input  logic start,
  output logic clear,   // clears accumulators and skew registers
  output logic en,      // lets the array accumulate
  output logic busy,
  output logic done
);
  typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
  state_t state;

`ifdef BUG4
  localparam int unsigned LAST = 3*N - 4;   // BUG4: done one cycle early
`else
  localparam int unsigned LAST = 3*N - 3;   // last RUN cycle number
`endif
  int unsigned cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      cnt   <= 0;
    end else begin
      case (state)
        IDLE, DONE: begin
          if (start) begin
            state <= RUN;
            cnt   <= 0;
          end
        end
        RUN: begin
          if (cnt == LAST) state <= DONE;
          else             cnt   <= cnt + 1;
        end
        default: state <= IDLE;
      endcase
    end
  end

`ifdef BUG5
  assign clear = 1'b0;                      // BUG5: never clears on start
`else
  assign clear = start && (state != RUN);
`endif
  assign en    = (state == RUN);
  assign busy  = (state == RUN);
  assign done  = (state == DONE);
endmodule
