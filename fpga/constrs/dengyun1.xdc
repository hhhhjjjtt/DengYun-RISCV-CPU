# Clock: from Zynq PS7 FCLK_CLK0 (internal PS-PL signal, no board pin).
# Vivado auto-derives this clock from the PS7 IP — no create_clock needed.
# If post-synthesis timing shows unconstrained paths, add:
#   create_clock -period 20.000 -name fclk0 #       [get_pins {ps_wrapper/design_1_i/processing_system7_0/inst/FCLKCLK[0]}]


set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports i_Clk]
create_clock -period 8.000 -name i_Clk [get_ports i_Clk]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports i_reset]

set_property -dict {PACKAGE_PIN W9 IOSTANDARD LVCMOS33} [get_ports i_debug_rx]
set_property -dict {PACKAGE_PIN Y8 IOSTANDARD LVCMOS33} [get_ports o_debug_tx]
# set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS33} [get_ports i_debug_en]
set_property -dict {PACKAGE_PIN W8 IOSTANDARD LVCMOS33 PULLUP true} [get_ports i_debug_en_n]

set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports i_rx_serial]
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports o_tx_serial]

set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[0]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {gpio_pins[1]}]

# set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {test_hi_lo}]
# set_property -dict {PACKAGE_PIN n16 IOSTANDARD LVCMOS33} [get_ports {test_locked}]
