#!/bin/bash
cd "$(dirname "$0")/.."
python3 model/gen_suite.py > /dev/null
N=4
SRC="rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv tb/accel_checker.sv"

try() {   # $1 = compile flag (may be empty), $2 = label
  local caught=""
  for tb in suite_tb corner_tb; do
    iverilog -g2012 $1 -P$tb.N=$N -o sim_bug.out $SRC tb/$tb.sv 2> /dev/null \
      || { echo "$2: BUILD ERROR"; return; }
    out=$(vvp sim_bug.out +A=model/suite${N}_A.hex +B=model/suite${N}_B.hex \
          +C=model/suite${N}_C.hex +CASES=206 2>&1 || true)
    echo "$out" | grep -q "^PASS" || caught="$caught $tb"
    echo "$out" | grep -q "ASSERT FAIL" && caught="$caught $tb(checker)"
  done
  if [ -z "$caught" ]; then echo "$2: no failure detected"
  else echo "$2: caught by$caught"; fi
}

try ""        "clean design (should show no failure)"
try "-DBUG1"  "BUG1 A skew, lane 1 undelayed"
try "-DBUG2"  "BUG2 B skew, lane 1 undelayed"
try "-DBUG3"  "BUG3 sign extension dropped"
try "-DBUG4"  "BUG4 done one cycle early"
try "-DBUG5"  "BUG5 accumulators never cleared"
try "-DBUG6"  "BUG6 B pass-through stuck at zero"