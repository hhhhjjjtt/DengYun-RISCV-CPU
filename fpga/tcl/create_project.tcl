# fpga/create_project.tcl
# Creates a fresh Vivado project from the repo sources.
# Usage (from Vivado TCL console or batch):
#   vivado -mode batch -source path/to/fpga/create_project.tcl

# ---- User config ----
set repo_dir  [file normalize [file dirname [info script]]/..] 
set proj_dir  $repo_dir/vivado_proj    # change to wherever you want the project
set proj_name "DengYun-1"
set part      "xc7z020clg400-1"       # PYNQ-Z2

# ---- Create project ----
create_project $proj_name $proj_dir -part $part -force

# ---- RTL sources ----
add_files [glob $repo_dir/rtl/core/*.v]
add_files [glob $repo_dir/rtl/bus/*.v]
add_files [glob $repo_dir/rtl/peripherals/*.v]
add_files [glob $repo_dir/rtl/debug/*.v]
add_files $repo_dir/rtl/defines.v
add_files $repo_dir/fpga/pynq_top.v
set_property top pynq_top [current_fileset]

# ---- Constraints ----
add_files -fileset constrs_1 $repo_dir/fpga/constrs/dengyun1.xdc

# ---- Clock wizard IP (125 MHz in → 50 MHz out) ----
create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 \
          -module_name clk_wiz_0
set_property -dict {
    CONFIG.PRIMITIVE          PLL
    CONFIG.PRIM_IN_FREQ       125.000
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ 50.000
    CONFIG.USE_LOCKED         true
    CONFIG.USE_RESET          false
} [get_ips clk_wiz_0]
generate_target all [get_ips clk_wiz_0]

puts "Project created at $proj_dir — open it in Vivado or run build.tcl to compile."
