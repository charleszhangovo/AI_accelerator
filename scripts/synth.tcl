# usage: vivado -mode batch -source scripts/synth.tcl -tclargs <N> <period_ns> <tag>
set N      [lindex $argv 0]
set period [lindex $argv 1]
set tag    [lindex $argv 2]
set part   xc7z020clg400-1
set outdir build/$tag
file mkdir $outdir

read_verilog -sv rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv \
                 rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv

# one clock constraint, written fresh for each run
set f [open $outdir/clk.xdc w]
puts $f "create_clock -period $period -name clk \[get_ports clk\]"
close $f
read_xdc $outdir/clk.xdc

# out_of_context: the design has hundreds of ports, more than the chip has pins
synth_design -top accel_top -part $part -mode out_of_context -generic N=$N
report_utilization -file $outdir/util_synth.rpt

opt_design
place_design
route_design

report_timing_summary -file $outdir/timing_summary.rpt
report_timing -max_paths 3 -file $outdir/timing_paths.rpt
report_utilization -file $outdir/util_impl.rpt
