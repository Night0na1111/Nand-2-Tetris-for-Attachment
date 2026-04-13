`timescale 1ns / 1ps

module vga_initials_top(
    input mclk,
    input clr,
    input [15:0] memory_data,
    
    input  wire        btn_up,     
    input  wire        btn_right, 
    input  wire        btn_down,   
    input  wire        btn_left,  

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

    reg clk25_reg;
    always @(posedge mclk)
        clk25_reg <= div[1];

    wire clk25 = clk25_reg;

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
            .clk(mclk),          
            .vidon(vidon),
            .hc(hc),
            .vc(vc),
            .M(memory_data),
            .btn_up(btn_up),     
            .btn_right(btn_right),
            .btn_down(btn_down),  
            .btn_left(btn_left),  
            .rom_addr(memory_address),
            .red(red),
            .green(green),
            .blue(blue)
        );

endmodule