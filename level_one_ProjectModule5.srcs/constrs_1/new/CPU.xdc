set_property PACKAGE_PIN F14 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name clk [get_ports clk]

set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports rxd]
set_property PULLUP true [get_ports rxd]

set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports txd]
set_property SLEW FAST [get_ports txd]