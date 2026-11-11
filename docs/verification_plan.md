## Coverage
Line coverage from run_cov.sh at N = 4, suite_tb and corner_tb combined.
One RTL line is unreached:
- array_ctrl.sv:36, the default branch of the state machine. Unreachable:
  the state register has an unused fourth encoding. Kept as a safety net.

Unreached lines in the testbenches and checker are failure-reporting paths
(MISMATCH and ASSERT FAIL printouts), which run only when a check fails, plus
waveform dumping, which runs only with +DUMP. The injected-bug table in
week 5 exercises the checker paths.

## Known gaps
- Overflow of the 32-bit accumulator is not tested.
- Coverage was measured at N = 4 only.
- Branch coverage is about 71%; the missing branches are the failure-reporting
  paths above.
- Toggle and FSM coverage were not enabled.

## Injected bugs
Each bug is switched on by a compile flag (run_bugs.sh). The clean design shows no failure.

| Bug | What it breaks | Caught by |
| --- | --- | --- |
| BUG1 | Lane 1 of A loses its skew delay, so row 1 starts a cycle early | suite_tb, corner_tb (wrong results) |
| BUG2 | Lane 1 of B loses its skew delay, so column 1 starts a cycle early | suite_tb, corner_tb (wrong results) |
| BUG3 | Product is zero-extended, so negative products become large positive numbers | suite_tb, corner_tb (wrong results) |
| BUG4 | done rises one cycle early | suite_tb, corner_tb, and the checker (done-timing rule) |
| BUG5 | Accumulators never clear on start, so runs carry over | suite_tb, corner_tb, and the checker (accumulators-zero rule) |
| BUG6 | B pass-through stuck at zero, so rows below the first get no B data | suite_tb, corner_tb (wrong results) |

Data-path bugs (1, 2, 3, 6) are caught by comparing results with NumPy.
Control bugs (4, 5) are also caught by the checker.