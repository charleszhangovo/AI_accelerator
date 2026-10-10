# signed and unsigned matters
# when write test brench, after @(posedge clk) add #1, since it can't change the value immedaitely
# Python numbers have no fixed width, we need to masking the output
# Use to difference system to test