`timescale 1ns / 1ps

module vga_640x480(
    input wire clk,
    input wire clr,

    output reg hsync,
    output reg vsync,
    output wire vidon,

    output reg [9:0] hc,
    output reg [9:0] vc
);

    // horizontal timing
    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800;

    // vertical timing 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;

    //horizontal counter
    always @(posedge clk or posedge clr)
    begin
        if (clr)
            hc <= 0;
        else if (hc == HT - 1)
            hc <= 0;
        else
            hc <= hc + 1;
    end

    //vertical counter
    always @(posedge clk or posedge clr)
    begin
        if (clr)
            vc <= 0;
        else if (hc == HT - 1)
        begin
            if (vc == VT - 1)
                vc <= 0;
            else
                vc <= vc + 1;
        end
    end

    // sync signals
    always @(*)
    begin
        hsync = ~((hc >= HD + HF) && (hc < HD + HF + HS));
        vsync = ~((vc >= VD + VF) && (vc < VD + VF + VS));
    end

    // video enable(visiable area)
    assign vidon = (hc < HD) && (vc < VD);

endmodule