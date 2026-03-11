#CLOCK
set_property PACKAGE_PIN W5 [get_ports clk_board_100M]
set_property IOSTANDARD LVCMOS33 [get_ports clk_board_100M]

#RESET BUTTON
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

#VGA RED
set_property PACKAGE_PIN G19 [get_ports {Red[0]}]
set_property PACKAGE_PIN H19 [get_ports {Red[1]}]
set_property PACKAGE_PIN J19 [get_ports {Red[2]}]
set_property PACKAGE_PIN N19 [get_ports {Red[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Red[*]}]

#VGA GREEN
set_property PACKAGE_PIN J17 [get_ports {Green[0]}]
set_property PACKAGE_PIN H17 [get_ports {Green[1]}]
set_property PACKAGE_PIN G17 [get_ports {Green[2]}]
set_property PACKAGE_PIN D17 [get_ports {Green[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Green[*]}]

#VGA BLUE
set_property PACKAGE_PIN N18 [get_ports {Blue[0]}]
set_property PACKAGE_PIN L18 [get_ports {Blue[1]}]
set_property PACKAGE_PIN K18 [get_ports {Blue[2]}]
set_property PACKAGE_PIN J18 [get_ports {Blue[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Blue[*]}]

#VGA SYNC
set_property PACKAGE_PIN P19 [get_ports HSync]
set_property PACKAGE_PIN R19 [get_ports VSync]
set_property IOSTANDARD LVCMOS33 [get_ports HSync]
set_property IOSTANDARD LVCMOS33 [get_ports VSync]

#7 SEGMENT
set_property PACKAGE_PIN W7 [get_ports {led_7seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {led_7seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {led_7seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {led_7seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {led_7seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {led_7seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {led_7seg[6]}]
set_property PACKAGE_PIN V7 [get_ports {led_7seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_7seg[*]}]

set_property PACKAGE_PIN U2 [get_ports {led_7seg_sel[0]}]
set_property PACKAGE_PIN U4 [get_ports {led_7seg_sel[1]}]
set_property PACKAGE_PIN V4 [get_ports {led_7seg_sel[2]}]
set_property PACKAGE_PIN W4 [get_ports {led_7seg_sel[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_7seg_sel[*]}]

#PS2 KEYBOARD
set_property PACKAGE_PIN C17 [get_ports PS2C]
set_property PACKAGE_PIN B17 [get_ports PS2D]

set_property IOSTANDARD LVCMOS33 [get_ports PS2C]
set_property IOSTANDARD LVCMOS33 [get_ports PS2D]

set_property PULLUP true [get_ports PS2C]
set_property PULLUP true [get_ports PS2D]