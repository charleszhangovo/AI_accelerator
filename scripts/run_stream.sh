#!/bin/bash
cd "$(dirname "$0")/.."
python3 model/gen_suite.py > /dev/null
SRC="rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv rtl/fifo.sv rtl/accel_stream.sv"
fail=0
for N in 2 4 8; do
  iverilog -g2012 -Pstream_tb.N=$N -o sim_stream.out $SRC tb/stream_tb.sv \
    || { echo "N=$N BUILD ERROR"; fail=1; continue; }
  for stall in 0 30 70; do
    out=$(vvp sim_stream.out +A=model/suite${N}_A.hex +B=model/suite${N}_B.hex \
          +C=model/suite${N}_C.hex +CASES=206 +STALL=$stall | grep -E "PASS|FAIL|MISMATCH" || true)
    echo "N=$N stall=$stall%: $out"
    echo "$out" | grep -q "^PASS" || fail=1
  done
done
if [ $fail -eq 0 ]; then echo "STREAM PASS"; else echo "STREAM FAILED"; exit 1; fi
