`timescale 1ns / 1ps

module vga_initials(
    input wire        vidon,
    input wire [9:0]  hc,
    input wire [9:0]  vc,
    input wire [15:0] M,

    output reg [12:0] rom_addr,
    output reg [3:0]  red,
    output reg [3:0]  green,
    output reg [3:0]  blue
);


    parameter HSTART = 0;    // 控制畫面左右位置大右小左+-8
    parameter VSTART = 184;   // 控制畫面上下位置大下小上+-8

    reg [9:0] x;
    reg [8:0] y;
    reg       visible;
    reg [3:0] bit_x;
    reg       pixel;

    always @(*) begin
        visible = (hc >= HSTART) && (hc < HSTART + 512) &&
                  (vc >= VSTART) && (vc < VSTART + 256);

        x = hc - HSTART;
        y = vc - VSTART;
    end

    /* address generation */
    always @(*) begin
        rom_addr = (y << 5) + (x >> 4);
    end

    /* pixel extraction */
    always @(*) begin
        bit_x = x[3:0];
        pixel = M[bit_x];
    end

    /* color output */
    always @(*) begin
        if (vidon && visible && pixel) begin
            red   = 4'hF;
            green = 4'hF;
            blue  = 4'hF;
        end
        else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

endmodule
