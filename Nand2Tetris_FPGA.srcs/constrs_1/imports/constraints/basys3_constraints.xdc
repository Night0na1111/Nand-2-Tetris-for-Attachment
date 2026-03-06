#the input port "clk" to the FPGA input pin "w5" for 100 MHz clock signal.
#set_property PACKAGE_PIN W5 [get_ports clk]
#set_property IOSTANDARD LVCMOS33 [get_ports clk]
## Clock signal
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports clk_board_100M]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk_board_100M]
#create_clock -add -name sys_clk_pin -period 100.00 -waveform {0 50} [get_ports clk]
#create_clock -period 10.000 [get_ports clk_in1]
#
##Reset Buttons ports btnC
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
#
#VGA
set_property -dict {PACKAGE_PIN G19 IOSTANDARD LVCMOS33} [get_ports {Red[0]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports {Red[1]}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {Red[2]}]
set_property -dict {PACKAGE_PIN N19 IOSTANDARD LVCMOS33} [get_ports {Red[3]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {Green[0]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {Green[1]}]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {Green[2]}]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {Green[3]}]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports {Blue[0]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {Blue[1]}]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports {Blue[2]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {Blue[3]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports HSync]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports VSync]

##7 Segment Display
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {led_7seg[0]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {led_7seg[1]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {led_7seg[2]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {led_7seg[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {led_7seg[4]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {led_7seg[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {led_7seg[6]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports {led_7seg[7]}]
## orginal dp
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {led_7seg_sel[0]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {led_7seg_sel[1]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {led_7seg_sel[2]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {led_7seg_sel[3]}]

##USB HID (PS/2)
##USB HID (PS/2)
set_property PACKAGE_PIN C17 [get_ports PS2C]
set_property IOSTANDARD LVCMOS33 [get_ports PS2C]
set_property PULLUP true [get_ports PS2C]
set_property PACKAGE_PIN B17 [get_ports PS2D]
set_property IOSTANDARD LVCMOS33 [get_ports PS2D]
set_property PULLUP true [get_ports PS2D]

