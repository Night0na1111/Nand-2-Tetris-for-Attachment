`timescale 1ns / 1ps

module vga_initials(
    input wire        clk,
    input wire        vidon,
    input wire [9:0]  hc,
    input wire [9:0]  vc,
    input wire [15:0] M,

    input wire        btn_left, 
    input wire        btn_right, 
    input wire        btn_up, 
    input wire        btn_down,

    output reg [12:0] rom_addr,
    output reg [3:0]  red,
    output reg [3:0]  green,
    output reg [3:0]  blue
);
    //N2T is 512 x 256(2:1), but our VGA is 640x480(4:3).
    //So The Responsibile solution is to go look up stretch algorythm and full-screen it. But we simply place a smaller image.

    reg [9:0] HSTART = 10'd64;          //Starting 64 pixel to the right.((512 - 640)/2 = 64)
    reg [9:0] VSTART = 10'd112;         //112 pixel down.((480 - 256) /2 = 112)


    //////////////////////////////////////////////////////////////////////
    //This next part is simply here for compatiblity. So buttons are mapped to adjust where the actual n2t viewport are.
    //Helps when dealing with different monitors, some of them have weird behaviors and don't play nice.

    // Button Debounce (20 bit)
    reg [19:0] debounce_l, debounce_r, debounce_u, debounce_d;
    reg btn_l_clean, btn_r_clean, btn_u_clean, btn_d_clean;
    reg btn_l_prev,  btn_r_prev,  btn_u_prev,  btn_d_prev;

    always @(posedge clk) begin
        debounce_l <= {debounce_l[18:0], btn_left};  //Basically the same shift register as Keyboard.
        debounce_r <= {debounce_r[18:0], btn_right};
        debounce_u <= {debounce_u[18:0], btn_up};
        debounce_d <= {debounce_d[18:0], btn_down};

        btn_l_clean <= (&debounce_l);   //If all are high, only then will data pass through.
        btn_r_clean <= (&debounce_r);
        btn_u_clean <= (&debounce_u);
        btn_d_clean <= (&debounce_d);

        btn_l_prev <= btn_l_clean;
        btn_r_prev <= btn_r_clean;
        btn_u_prev <= btn_u_clean;
        btn_d_prev <= btn_d_clean;
    end

    wire trig_left  = btn_l_clean && !btn_l_prev;   //Trigger only when not pressed to pressed. Makes life easier.
    wire trig_right = btn_r_clean && !btn_r_prev;
    wire trig_up    = btn_u_clean && !btn_u_prev;
    wire trig_down  = btn_d_clean && !btn_d_prev;


    // HSTART / VSTART adjuster.
    always @(posedge clk) begin
        if (trig_left  && HSTART >= 10'd8)           HSTART <= HSTART - 10'd4;  //If in-bound, shift by 4 pixel.
        if (trig_right && HSTART <= 10'd640 - 10'd8) HSTART <= HSTART + 10'd4;
        if (trig_up    && VSTART >= 10'd8)           VSTART <= VSTART - 10'd4;
        if (trig_down  && VSTART <= 10'd480 - 10'd8) VSTART <= VSTART + 10'd4;
    end


    ///////////////////////////////////////////////////////////////////////////
    //Convert VGA coordinate (big one) to N2t coordinate(small one), so that we know which address to fetch data from.

    reg [9:0] x_s0;             //N2T X pos 0 to 511
    reg [8:0] y_s0;             //N2T Y pos 0 to 255
    reg       visible_s0;       //Are we in N2T's viewport now?

    always @(*) begin
        visible_s0 = (hc >= HSTART) && (hc < HSTART + 512) &&
                     (vc >= VSTART) && (vc < VSTART + 256);
        x_s0 = hc - HSTART;
        y_s0 = vc - VSTART;
    end


    ////////////////////////////////////////////////////////////////////
    // Compute which address(word) we want in ram, this is the offset.
    // This is basically the same logic used as Screen.jack in software(Go check that out). Only difference is that we are looking for word, not specific bit.
    // << is shift left, have the effect of multplying 2^bits (binary trick).
    // >> is shift right, have the effect of dividing 2^bits.
    // Timing, Hc and Vc will stick around for 4 cycles, causing x_s0, y_s0 to stick around for 4 cycles. Making memory request stick 4 cycle. Aligning with VGA timing(so that this thing dont run wild).

    always @(*) begin
        rom_addr = (y_s0 << 5) + (x_s0 >> 4);   //(Y * 32) + (x / 16)
    end


    ////////////////////////////////////////////////////////////////////
    // Delay hc/vc/vidon/visible one clock.
    // The data we ask(rom_addr) is for this cycle, but what we get from ram is always what was last cycle(Memory is 100MHZ too), so... we have to delay counters to make sure things align.
    // Timing, the slowdown here is invisible to vga_640x480 (so Hsync and Vsync signal would be fine), because it only operate at 25Mhz, and here is 100Mhz.
    reg [9:0]  hc_d1;
    reg [9:0]  vc_d1;
    reg        vidon_d1;        //VGA space viewable?
    reg        visible_d1;      //N2T space viewable?
    reg [9:0]  x_d1;

    always @(posedge clk) begin
        hc_d1      <= hc;
        vc_d1      <= vc;
        vidon_d1   <= vidon;
        visible_d1 <= visible_s0;
        x_d1       <= x_s0;
    end

    /////////////////////////////////////////////////////////////
    //Bit Extractor.
    //This part determines which bit should we look at from the address we are at.(All address are 16 bit in content) 
    reg [3:0] bit_x;
    reg       pixel;

    always @(*) begin
        bit_x = x_d1[3:0];  //This is actually just the remainder of / 16, tells us which bit to use. clever binary trick.
        pixel = M[bit_x];   //Set pixel value to bit value.
    end

    /////////////////////////////////////////////////////////////
    // RGB coloring
    // And Yes, in offocial N2T spec, 0 = white, 1 = black.
    always @(*) begin
        if (vidon_d1 && visible_d1 && pixel) begin  //If In Vga range + In N2T range + it wants color.
            red   = 4'h0;
            green = 4'h0;       //Black
            blue  = 4'h0;
        end else begin
            red   = 4'hF;
            green = 4'hF;       //White
            blue  = 4'hF;
        end
    end

endmodule     