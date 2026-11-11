#!/bin/bash
set -e
cd "$(dirname "$0")/.."

python3 model/gen_suite.py > /dev/null

N=4
SRC="rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv tb/accel_checker.sv"

rm -rf cov_annotated cov_*.dat coverage.dat

for tb in suite_tb corner_tb; do
  echo "== Building $tb =="
  verilator --binary --coverage-line --timing -Wno-fatal -Wno-lint -Wno-style \
    --top-module $tb -GN=$N --Mdir obj_$tb $SRC tb/$tb.sv \
    > build_$tb.log 2>&1 || { tail -20 build_$tb.log; exit 1; }

  echo "== Running $tb =="
  ./obj_$tb/V$tb +A=model/suite${N}_A.hex +B=model/suite${N}_B.hex \
    +C=model/suite${N}_C.hex +CASES=206 | grep -E "PASS|FAIL|MISMATCH|ASSERT" || true

  mv coverage.dat cov_$tb.dat
done

echo "== Coverage summary =="
verilator_coverage --annotate cov_annotated --annotate-min 1 \
  cov_suite_tb.dat cov_corner_tb.dat

echo "== Lines never reached =="
grep -Hn '^%' cov_annotated/* || true