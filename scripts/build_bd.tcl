# Build the PYNQ overlay. Run from the repo folder in the Vivado Tcl Shell:
#   source scripts/build_bd.tcl
set part   xc7z020clg400-1
set proj   build/bd_proj
set outdir build/overlay
file mkdir $outdir

create_project accel_bd $proj -part $part -force

# Use the PYNQ-Z2 board files if they're installed; otherwise use the bare chip.
set have_board [expr {![catch {set_property board_part tul.com.tw:pynq-z2:part0:1.0 [current_project]}]}]
puts "PYNQ-Z2 board files: [expr {$have_board ? {found} : {not found, using bare part}}]"

add_files -norecurse [list rtl/mult8.sv rtl/mac.sv rtl/pe.sv rtl/systolic_array.sv \
  rtl/skew.sv rtl/array_ctrl.sv rtl/accel_top.sv rtl/accel_axi.sv rtl/accel_axi_top.v]
update_compile_order -fileset sources_1

create_bd_design system

# Zynq processor with a 100 MHz clock for your logic and its AXI master port on.
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
  -config [list make_external "FIXED_IO, DDR" apply_board_preset [expr {$have_board ? 1 : 0}] \
           Master Disable Slave Disable] [get_bd_cells ps7]
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} \
                         CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100}] [get_bd_cells ps7]

# Your accelerator, straight from RTL. Vivado recognizes the s_axi_* ports.
create_bd_cell -type module -reference accel_axi_top accel_0

# Connect processor to accelerator; Vivado adds the interconnect and reset logic.
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
  -config {Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/ps7/M_AXI_GP0} \
           Slave {/accel_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}} \
  [get_bd_intf_pins accel_0/s_axi]

assign_bd_address
validate_bd_design
save_bd_design

make_wrapper -files [get_files system.bd] -top -import
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
puts "Implementation WNS: [get_property STATS.WNS [get_runs impl_1]] ns"

# PYNQ needs the .bit and .hwh side by side with the same name.
set bit [glob -nocomplain $proj/accel_bd.runs/impl_1/*.bit]
set hwh [glob -nocomplain $proj/accel_bd.gen/sources_1/bd/system/hw_handoff/*.hwh \
                          $proj/accel_bd.srcs/sources_1/bd/system/hw_handoff/*.hwh]
if {[llength $bit] == 0 || [llength $hwh] == 0} {
  puts "ERROR: could not find the .bit or .hwh file"
} else {
  file copy -force [lindex $bit 0] $outdir/accel.bit
  file copy -force [lindex $hwh 0] $outdir/accel.hwh
  puts "DONE: overlay written to $outdir/accel.bit and accel.hwh"
}
