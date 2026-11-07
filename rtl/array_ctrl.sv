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

  localparam int unsigned LAST = 3*N - 3;   // last RUN cycle number
  int unsigned cnt;

  always_ff @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      cnt   <= 0;
    end 
    else begin
      case (state)
        IDLE, DONE: begin
          if (start) begin
            state <= RUN;
            cnt   <= 0;
          end
        end
        RUN: begin
          if (cnt == LAST) 
          state <= DONE;
          else             
          cnt   <= cnt + 1;
        end
        default: state <= IDLE;
      endcase
    end
  end

  assign clear = start && (state != RUN);
  assign en    = (state == RUN);
  assign busy  = (state == RUN);
  assign done  = (state == DONE);
endmodule

