# 100 MHz system clock
create_clock -name sys_clk -period 10.000 [get_ports clk_board_100M]

# Generated clock: 25 MHz for VGA (100 MHz / 4)
# [修正] 加上反斜線續行符
# [注意] get_pins 路徑取決於合成後的 cell name，
#        合成後請用 report_clocks 確認。如果路徑不對，
#        可以用 get_nets 代替，或讓 Vivado 自動推斷。
create_generated_clock \
    -name clk25 \
    -source [get_ports clk_board_100M] \
    -divide_by 4 \
    [get_pins vga/div_reg[1]/Q]

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