#!/bin/bash
set -e
cd "$(dirname "$0")/.."
python3 model/gen_suite.py
SRC="rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv tb/accel_checker.sv"
fail=0
for N in 2 4 8; do
  for tb in suite_tb corner_tb; do
    iverilog -g2012 -P$tb.N=$N -o sim_$N.out $SRC tb/$tb.sv
    out=$(vvp sim_$N.out +A=model/suite${N}_A.hex +B=model/suite${N}_B.hex \
          +C=model/suite${N}_C.hex +CASES=206 | grep -E "PASS|FAIL|MISMATCH|ASSERT" || true)
    echo "$tb N=$N:"
    echo "$out"
    echo "$out" | grep -q "^PASS" || fail=1
  done
done
if [ $fail -eq 0 ]; then echo "ALL PASS"; else echo "SOME TESTS FAILED"; exit 1; fi
