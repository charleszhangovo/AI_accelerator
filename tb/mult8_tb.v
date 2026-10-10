module mult8_tb;
  reg  signed [7:0]  a, b;
  wire signed [15:0] p;

  mult8 dut (.a(a), .b(b), .p(p));

  initial begin
    a = -128; b = -128; #10; $display("%0d x %0d = %0d (expect 16384)", a, b, p);
    a = -128; b = 127;  #10; $display("%0d x %0d = %0d (expect -16256)", a, b, p);
    a = 127;  b = 127;  #10; $display("%0d x %0d = %0d (expect 16129)", a, b, p);
    a = 5;    b = -3;   #10; $display("%0d x %0d = %0d (expect -15)", a, b, p);
    a = 77;   b = 0;    #10; $display("%0d x %0d = %0d (expect 0)", a, b, p);
    $finish;
  end
endmodule
