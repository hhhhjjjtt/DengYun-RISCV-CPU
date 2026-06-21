# Clock signal 50 MHz
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports i_Clk]
create_clock -period 20.000 -name sys_clk_pin -waveform {0.000 10.000} [get_ports i_Clk]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports i_reset]


