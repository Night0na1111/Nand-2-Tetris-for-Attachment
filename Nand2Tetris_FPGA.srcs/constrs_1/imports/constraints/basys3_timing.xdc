# 100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk_board_100M]


create_generated_clock \
    -name clk25 \
    -source [get_ports clk_board_100M] \
    -divide_by 4 \
    [get_pins vga/clk25_reg_reg/Q]

# Asynchronous inputs - no timing requirement
set_false_path -from [get_ports reset]
set_false_path -from [get_ports PS2C]
set_false_path -from [get_ports PS2D]

# VGA outputs - not timing critical (DAC is purely resistive)
# [修正] Red[] -> Red[*], Green[] -> Green[*]
set_false_path -to [get_ports {Red[*]}]
set_false_path -to [get_ports {Green[*]}]
set_false_path -to [get_ports {Blue[*]}]
set_false_path -to [get_ports HSync]
set_false_path -to [get_ports VSync]

# 7-segment display outputs - slow human-visible refresh, not timing critical
set_false_path -to [get_ports {led_7seg[*]}]
set_false_path -to [get_ports {led_7seg_sel[*]}]