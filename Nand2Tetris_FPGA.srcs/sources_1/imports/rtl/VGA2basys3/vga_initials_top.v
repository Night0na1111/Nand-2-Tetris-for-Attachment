`timescale 1ns / 1ps

module vga_initials_top(

input mclk,
input clr,
input [15:0] memory_data,

output hsync,
output vsync,
output [3:0] blue,
output [3:0] red,
output [3:0] green,

output [12:0] memory_address
);

reg [1:0] div;
always @(posedge mclk)
div <= div + 1;

wire clk25 = div[1];

wire [9:0] hc;
wire [9:0] vc;
wire vidon;

vga_640x480 sync(
.clk(clk25),
.clr(clr),
.hsync(hsync),
.vsync(vsync),
.hc(hc),
.vc(vc),
.vidon(vidon)
);

vga_initials renderer(
.vidon(vidon),
.hc(hc),
.vc(vc),
.M(memory_data),
.rom_addr(memory_address),
.red(red),
.green(green),
.blue(blue)
);

endmodule