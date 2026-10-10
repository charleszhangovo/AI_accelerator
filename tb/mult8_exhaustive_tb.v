module mult8_exhaustive_tb;
  reg  signed [7:0]  a, b;
  wire signed [15:0] p;
  reg  [15:0] expected [0:65535];
  integer i, errors; // default 32bit integer

  mult8 dut (.a(a), .b(b), .p(p));

  initial begin
    $readmemh("model/products.hex", expected);
    errors = 0;
    for (i = 0; i < 65536; i = i + 1) begin
      a = i[15:8]; // upper byte
      b = i[7:0]; // lower byte
      /*
      let's say i = 2 which is 0000....0010 in binary, then a = 0000 0000 and b = 0000 0010
      */
      
      #1;
      if (p !== expected[i]) begin
        errors = errors + 1;
        if (errors <= 10)
          $display("MISMATCH a=%0d b=%0d got %0d expected %0d", a, b, p, $signed(expected[i]));
      end
    end
    if (errors == 0) $display("PASS: all 65536 cases");
    else             $display("FAIL: %0d mismatches", errors);
    $finish;
  end
endmodule