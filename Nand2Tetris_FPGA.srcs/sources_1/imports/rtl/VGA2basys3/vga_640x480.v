`timescale 1ns / 1ps
//So Basically, the perpouse of this ENTIRE module, is to get the signal timig right. If timing is needed, consult the document I wrote.
//(If the document somehow never gets finished, seek microvga.com)
module vga_640x480(
    input wire clk,
    input wire clr,

    output reg hsync,       //These two signals are active high usually, and only low when it's their time to shine.
    output reg vsync,
    output wire vidon,      //Are we in viewable space right now?

    output reg [9:0] hc,    //Horizontal Counter
    output reg [9:0] vc     //Veritcal Counter
);

    // horizontal timing(Pixels)
    parameter HD = 640;     //Visable Area
    parameter HF = 16;      //Front Porch
    parameter HS = 96;      //Sync Pulse
    parameter HB = 48;      //Back Porch
    parameter HT = 800;     //Whole Line width.

    // vertical timing (Pixels too)
    parameter VD = 480;     //Visable Area
    parameter VF = 10;      //Front porch
    parameter VS = 2;       //Sync Pulse
    parameter VB = 33;      //Back Porch
    parameter VT = 525;     //Whole Frame Width.

    ///////////////////////////////////////////////////////////////////
    //Horizontal Counter ---
    always @(posedge clk or posedge clr)
    begin
        if (clr)
            hc <= 0;
        else if (hc == HT - 1)          //If reach 800th(-1 because the counter starts from 1) pixel, reset counter.
            hc <= 0;
        else
            hc <= hc + 1;               //Else counter goes up.
    end

    //Vertical Counter |||
    always @(posedge clk or posedge clr)
    begin
        if (clr)
            vc <= 0;
        else if (hc == HT - 1)          //If Horizontal pixel reaches it's end, it means time for the next line.
        begin
            if (vc == VT - 1)           //Checks if end of Vertical line, if not Vertical counter goes up.
                vc <= 0;
            else
                vc <= vc + 1;
        end
    end

    /////////////////////////////////////////////////////////////////////
    // Sync Signals
    always @(*)
    begin
        hsync = ~((hc >= HD + HF) && (hc < HD + HF + HS)); //Simple math, just getting the range of hsync. 
        vsync = ~((vc >= VD + VF) && (vc < VD + VF + VS));
    end

    // Video Enable(visiable area)
    assign vidon = (hc < HD) && (vc < VD);

endmodule