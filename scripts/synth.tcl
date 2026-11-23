# usage: vivado -mode batch -source scripts/synth.tcl -tclargs <N> <period_ns> <tag> [quick|full]
set N      [lindex $argv 0]
set period [lindex $argv 1]
set tag    [lindex $argv 2]
set mode   [expr {[llength $argv] > 3 ? [lindex $argv 3] : "full"}]
set part   xc7z020clg400-1
set outdir build/$tag
file mkdir $outdir
file mkdir reports

set_param general.maxThreads 4

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

if {$mode eq "full"} {
    opt_design
    place_design
    route_design
    report_timing_summary -file $outdir/timing_summary.rpt
    report_timing -max_paths 3 -file $outdir/timing_paths.rpt
    report_utilization -file $outdir/util_impl.rpt
}

# summary row for reports/summary.csv
# WNS: quick mode gives only an estimate, since there is no placement yet.
set wns "?"
catch {set wns [format %.3f [get_property SLACK [lindex [get_timing_paths -max_paths 1 -setup] 0]]]}

set rpt [expr {$mode eq "full" ? "$outdir/util_impl.rpt" : "$outdir/util_synth.rpt"}]
set h [open $rpt r]; set txt [read $h]; close $h
set luts "?"; set ffs "?"; set dsps "?"
if {[regexp {Slice LUTs[^|]*\|\s*(\d+)} $txt -> v]} { set luts $v }
if {[regexp {Slice Registers\s*\|\s*(\d+)} $txt -> v]} { set ffs $v }
if {[regexp {DSPs\s*\|\s*(\d+)} $txt -> v]} { set dsps $v }

set csv reports/summary.csv
if {![file exists $csv]} {
    set h [open $csv w]; puts $h "tag,N,period_ns,mode,wns_ns,luts,ffs,dsps"; close $h
}
set h [open $csv a]
puts $h "$tag,$N,$period,$mode,$wns,$luts,$ffs,$dsps"
close $h
puts "DONE $tag ($mode): WNS=$wns LUTs=$luts FFs=$ffs DSPs=$dsps"
