#100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk_board_100M]

#generated clock (25 MHz)
create_clock -name sys_clk -period 10.000 [get_ports clk_board_100M]

#asynchronous inputs
set_false_path -from [get_ports reset]
set_false_path -from [get_ports PS2C]
set_false_path -from [get_ports PS2D]

#VGA output not timing critical
set_false_path -to [get_ports {Red[0]}]
set_false_path -to [get_ports {Green[0]}]
set_false_path -to [get_ports {Blue[0]}]
set_false_path -to [get_ports HSync]
set_false_path -to [get_ports VSync]