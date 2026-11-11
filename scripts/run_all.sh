#!/bin/bash
cd "$(dirname "$0")/.."   # go to the repo's main folder
fail=0

echo "== Lint =="
if verilator --lint-only -Wall rtl/mult8.sv rtl/mac.sv --top-module mac; then
  echo "lint mac clean"
else
  echo "lint mac FAILED"; fail=1
fi
SRC="rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv"
for N in 2 4 8; do
  if verilator --lint-only -Wall $SRC --top-module accel_top -GN=$N; then
    echo "lint accel_top N=$N clean"
  else
    echo "lint accel_top N=$N FAILED"; fail=1
  fi
done

echo "== Regenerate test data =="
python3 model/gen_products.py
python3 model/gen_mac.py > /dev/null   # hides the Python program's terminal output

echo "== Multiplier, all 65536 cases =="
iverilog -g2012 -o sim.out rtl/mult8.sv tb/mult8_exhaustive_tb.v
out=$(vvp sim.out | grep -E "PASS|FAIL" || true)
echo "$out"
case "$out" in PASS*) ;; *) fail=1 ;; esac

echo "== MAC =="
iverilog -g2012 -o sim.out rtl/mult8.sv rtl/mac.sv tb/mac_tb.sv
run() {
  out=$(vvp sim.out +STIM=model/$1_stim.hex +EXP=model/$1_exp.hex +N=$2 | grep -E "PASS|FAIL" || true)
  echo "$1: $out"
  case "$out" in PASS*) ;; *) fail=1 ;; esac
}
run directed 10
run random1 1001
run random2 1001
run random3 1001

echo "== Full design regression, N = 2, 4, 8 =="
if ./scripts/run_suite.sh > build_suite.log 2>&1; then
  echo "regression passed"
else
  echo "regression FAILED"; tail -20 build_suite.log; fail=1
fi

echo "== Injected bugs =="
./scripts/run_bugs.sh > build_bugs.log 2>&1
cat build_bugs.log
grep -q "clean design.*no failure detected" build_bugs.log || { echo "clean design did not pass cleanly"; fail=1; }
if grep "^BUG" build_bugs.log | grep -v "caught by" | grep -q .; then
  echo "A bug was NOT caught"; fail=1
fi

if [ $fail -eq 0 ]; then echo "ALL CHECKS PASS"; else echo "SOME CHECKS FAILED"; exit 1; fi