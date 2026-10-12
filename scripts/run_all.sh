#!/bin/bash
set -e #tells the operating system to execute this script using the Bash shell
cd "$(dirname "$0")/.." #access to the main folder

echo "== Lint =="
verilator --lint-only -Wall rtl/mult8.sv rtl/mac.sv --top-module mac #mac module uses the mult8 module to perform multiplication.
echo "lint clean"

echo "== Regenerate test data =="
python3 model/gen_products.py
python3 model/gen_mac.py > /dev/null #hides the Python program's standard terminal output

fail=0

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

if [ $fail -eq 0 ]; then echo "ALL PASS"; else echo "SOME TESTS FAILED"; exit 1; fi
