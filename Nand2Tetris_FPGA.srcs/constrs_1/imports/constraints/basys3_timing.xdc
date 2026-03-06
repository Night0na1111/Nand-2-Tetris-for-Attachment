## timing constraint ##
create_generated_clock -name clk -source [get_ports clk_board_100M] -divide_by 4 [get_pins {clock_divider_reg[1]/Q}]
create_generated_clock -name keyboard/PS2Cf -source [get_pins {clock_divider_reg[1]/Q}] -divide_by 1 [get_pins keyboard/PS2Cf_reg/Q]
create_generated_clock -name {led_scan/U1/S[0]} -source [get_pins {clock_divider_reg[1]/Q}] -divide_by 65536 [get_pins {led_scan/U1/count_reg[15]/Q}]
create_generated_clock -name vga/U1/CLK -source [get_ports clk_board_100M] -divide_by 4 [get_pins {vga/U1/q_reg[1]/Q}]


set_false_path -from [get_ports PS2C]
set_false_path -from [get_ports PS2D]
set_false_path -from [get_ports reset]


set_false_path -from [get_clocks vga/U1/CLK] -to [get_ports {Red[*]}]
set_false_path -from [get_clocks vga/U1/CLK] -to [get_ports {led_7seg[*]}]
set_false_path -from [get_clocks vga/U1/CLK] -to [get_ports {led_7seg_sel[*]}]

set_clock_groups -asynchronous -group [get_clocks {led_scan/U1/S[0]}] -group [get_clocks clk]

