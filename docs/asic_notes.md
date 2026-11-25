## N = 4 signoff experiments (sky130, 20 ns clock)

| Run | Broad diodes | Other settings | Antenna | Max cap | Max slew |
| --- | --- | --- | --- | --- | --- |
| n4_20ns | on | defaults | pass | 9 corners | 52 |
| n4_20ns_fix | off | antenna iters 10, post-route repair | 7 fail | 6 corners | yes |
| n4_20ns_margin30 | off | + antenna margin 30 | 8 fail | 6 corners | yes |
| n4_20ns_repair | on | + long-wire buffering, repair margins 30% | pass | 0 | 36 |
| n4_20ns_thresh200 | on, threshold 200 | same as repair | 5 fail | 0 | yes |

Final: n4_20ns_repair. Antenna, LVS, DRC, and max cap clean. 36 slew
violations at the slow corners only (worst 1.01 ns vs 0.75 ns limit).

Diagnosis: the remaining violations are pairs of one small gate driving
one flip-flop, with protection diodes on both pins. The diode load slows
the edge, and the drivers weren't upsized. Diodes fix antenna but load
nets; removing them brings antenna violations back. The tool knobs trade
one violation for another.

Next fix (not done): upsize those specific drivers with an ECO, or
reduce how far control and data nets travel in the floorplan.
