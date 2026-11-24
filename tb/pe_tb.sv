module pe_tb;
    logic clk = 0;
    logic clear, en;
    logic signed [7:0] a_in, b_in;
    logic signed [7:0] a_out, b_out;
    logic signed [31:0] acc;
    integer errors = 0;

    pe dut (.clk(clk), .clear(clear), .en(en), .a_in(a_in), .b_in(b_in), .a_out(a_out), .b_out(b_out), .acc(acc));

    always #5 clk = ~clk;

    task automatic step(
        input logic clear_in,
        input logic en_in,
        input logic signed [7:0] a_in_val,
        input logic signed [7:0] b_in_val,
        input logic signed [7:0] a_out_exp,
        input logic signed [7:0] b_out_exp,
        input logic signed [31:0] acc_exp
    );
    begin
        @(negedge clk);
        clear = clear_in; en = en_in; a_in = a_in_val; b_in = b_in_val;
        @(posedge clk);
        #1; // let outputs settle after the edge
        if (a_out !== a_out_exp || b_out !== b_out_exp || acc !== acc_exp) begin
            errors = errors + 1;
            $display("MISMATCH: clear=%b en=%b a_in=%0d b_in=%0d | got a_out=%0d b_out=%0d acc=%0d | expected a_out=%0d b_out=%0d acc=%0d",
                     clear, en, a_in, b_in, a_out, b_out, acc, a_out_exp, b_out_exp, acc_exp);
        end
    end
    endtask

    initial begin
        $dumpfile("pe_tb.vcd");
        $dumpvars(0, pe_tb);

        // Test sequence
        //   clear en   a     b     exp_acc  exp_a  exp_b
        step(1,    0,   0,    0,    0,       0,     0);     // clear everything
        step(0,    1,   1,    5,    0,       1,     5);     // 1 x 5 queued, acc still 0
        step(0,    1,   2,    7,    5,       2,     7);     // 5 lands in acc
        step(0,    1,   0,    0,    19,      0,     0);     // 19 lands in acc
        step(0,    1,   -128, -128, 19,      -128,  -128);  // 0 product, acc holds 19
        step(1,    1,   9,    9,    16403,   0,     0);     // -128 x -128 lands; clear next
        step(0,    0,   3,    4,    0,       3,     4);     // cleared, en low

        if (errors == 0) $display("PASS: All tests passed.");
        else             $display("FAIL: %0d mismatches found.", errors);
        $finish;
    end

endmodule
