`timescale 1ns / 1ps

`define Rect 1

module top_computer(

input clk_board_100M,
input reset,

output [7:0] led_7seg,
output [3:0] led_7seg_sel,

output HSync,
output VSync,
output [3:0] Blue,
output [3:0] Red,
output [3:0] Green,

input wire PS2C,
input wire PS2D
);

wire cpu_clk;

/* VGA */

wire [15:0] vga_memory_in;
wire [12:0] vga_memory_addr;

vga_initials_top vga(
.mclk(clk_board_100M),
.clr(reset),
.memory_data(vga_memory_in),
.memory_address(vga_memory_addr),
.hsync(HSync),
.vsync(VSync),
.blue(Blue),
.red(Red),
.green(Green)
);

/* MEMORY */

wire [15:0] memory_out;
wire [15:0] memory_in;
wire memory_load;
wire [14:0] memory_address;

reg [14:0] second_mem_address;
reg key_pressed;
reg keyboard_write;

wire [15:0] xkey;

memory memory_unit(

.clk(cpu_clk),
.address(memory_address),
.out(memory_out),
.in_value(memory_in),
.load(memory_load),

.second_clk(clk_board_100M),
.second_address(second_mem_address),
.second_out(vga_memory_in),
.second_in_value(xkey),
.second_load(keyboard_write)

);

/* VGA + Keyboard */

always @(*) begin
if (key_pressed && (vga_memory_addr == 13'b0))
keyboard_write = 1'b1;
else
keyboard_write = 1'b0;
end

always @(*) begin
if (keyboard_write)
second_mem_address = 15'h6000;
else
second_mem_address = {2'b10, vga_memory_addr};
end

always @(posedge cpu_clk) begin
if (reset)
key_pressed <= 0;
else if (xkey[15:8] == xkey[7:0])
key_pressed <= 1;
else
key_pressed <= 0;
end

/* ROM */

wire [15:0] nextPC;
wire [15:0] instruction;

rom_rect rom_rect_unit(
.clk(cpu_clk),
.instruction(instruction),
.nextPC(nextPC)
);

/* CPU */

cpu cpu_unit(
.clk(cpu_clk),
.inM(memory_out),
.instruction(instruction),
.reset(reset),
.outM(memory_in),
.writeM(memory_load),
.addressM(memory_address),
.newPC(nextPC)
);

/* CLOCK DIVIDER */

reg [26:0] div;

always @(posedge clk_board_100M)
div <= div + 1;

assign cpu_clk = div[10];

/* 7SEG */

top_led7seg_scan led_scan(
.data_16(xkey),
.clk(clk_board_100M),
.RESET(reset),
.Seven_segment_out(led_7seg),
.Seven_segment_sel(led_7seg_sel)
);

/* KEYBOARD */

keyboard keyboard(
.clk25(clk_board_100M),
.clr(reset),
.PS2C(PS2C),
.PS2D(PS2D),
.xkey(xkey)
);

endmodule