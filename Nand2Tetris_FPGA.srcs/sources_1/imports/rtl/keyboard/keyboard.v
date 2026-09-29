`timescale 1ns / 1ps

module keyboard(
    input  wire        clk25,   //25MHZ clock
    input  wire        clr,     //Clear/Reset
    input  wire        PS2C,    //PS2 Clock  (10k or 16.7k)
    input  wire        PS2D,    //PS2 Data

    output reg  [15:0] current_key  //ASCII to COMPUTER
);


////////////////////////////////////////////////////////////////
//  PS2 Filter (Debouncing)
//  We can filter PS2C & D because it is at best 16.7kHZ, very slow. Slow enough that we can trow a fast debounce onto it and don't effect timing.
//  PS2Cf and PS2Df are still individual bits (Sequential), just filtered.
reg [7:0] ps2c_filter, ps2d_filter;
reg PS2Cf, PS2Df;

always @(posedge clk25 or posedge clr) begin
    if (clr) begin //Reset
        ps2c_filter <= 8'hFF; //The 8 bit history buffer, fills up after 8 clk25 cycle.
        ps2d_filter <= 8'hFF;
        PS2Cf       <= 1;
        PS2Df       <= 1;

    end else begin

        ps2c_filter <= {ps2c_filter[6:0], PS2C}; //take only bit 0 to 6, and pad on 1 bit. Shifting the entire thing left by one.
        ps2d_filter <= {ps2d_filter[6:0], PS2D}; //Same Shifting.

        if      (ps2c_filter == 8'hFF) PS2Cf <= 1; //Steady 1
        else if (ps2c_filter == 8'h00) PS2Cf <= 0; //Steady 0

        if      (ps2d_filter == 8'hFF) PS2Df <= 1; //Steady 1
        else if (ps2d_filter == 8'h00) PS2Df <= 0; //Steady 0
    end
end



//////////////////////////////////////////////////////////////
// detect PS2Cf fall (Because PS2 operates on Falling edges.) 1 to 0

reg PS2Cf_prev;
always @(posedge clk25 or posedge clr) begin   //constantly refresh prev state.
    if (clr) PS2Cf_prev <= 1;
    else     PS2Cf_prev <= PS2Cf;
end
wire ps2c_fall = (PS2Cf_prev == 1 && PS2Cf == 0);  //If prev is 1 and now is 0, trigger ps2c_fall. Signal only lives for one 25Mhz cycle.



///////////////////////////////////////////////////////////////
// read 11-bit Frame (Frame processing)
// By the way, we actually never use ANY of the built-in error correction bits.
// We only count the frame via clock cycles, not packet integrity. If this thing ever desynced or gets garbeled, we will be off-frame.

reg [3:0]  bit_cnt;   //Counts input
reg [10:0] shift_reg; //The Shift register,11 bit total.
reg        rx_done;   //Signals When the Shift Register is full.

always @(posedge clk25 or posedge clr) begin
    if (clr) begin
        bit_cnt   <= 0; 
        shift_reg <= 0; 
        rx_done   <= 0;

    end else begin

        rx_done <= 0;                               //Resets the Frame complete signal, so that it only lives 1 25MHZ cycle too.
        if (ps2c_fall) begin                        //Operates whenever Negedge(Ps2)
            shift_reg <= {PS2Df, shift_reg[10:1]};  //Replace The leftmost bit with new data, and push all else left.
            if (bit_cnt == 4'd10) begin             //If the frame is done, reset and signal frame complete.
                bit_cnt <= 0;
                rx_done <= 1;
            end else begin

                bit_cnt <= bit_cnt + 1;
            end
        end
    end
end



//////////////////////////////////////////////////////////
//Scan Code → Hack Key Code(ASCII)
//We skipped the entire lower case rendering in software, no way we are ASKING for it here. (Rant)
//Fine, now the memory map of lower case letters are direct duplicates of Captial letters in software.
//This have the side effect of... not requireing shift key or Caps lock!

function [15:0] scancode_to_hack; //Basically a look up table. Gets called, get a value, give an output value. Basically a giant MUX.
    input [7:0] sc;
    begin
        case (sc)
            //alphabet
            8'h1C: scancode_to_hack = 16'd97;  // a
            8'h32: scancode_to_hack = 16'd98;  // b
            8'h21: scancode_to_hack = 16'd99;  // c
            8'h23: scancode_to_hack = 16'd100; // d
            8'h24: scancode_to_hack = 16'd101; // e
            8'h2B: scancode_to_hack = 16'd102; // f
            8'h34: scancode_to_hack = 16'd103; // g
            8'h33: scancode_to_hack = 16'd104; // h
            8'h43: scancode_to_hack = 16'd105; // i
            8'h3B: scancode_to_hack = 16'd106; // j
            8'h42: scancode_to_hack = 16'd107; // k
            8'h4B: scancode_to_hack = 16'd108; // l
            8'h3A: scancode_to_hack = 16'd109; // m
            8'h31: scancode_to_hack = 16'd110; // n
            8'h44: scancode_to_hack = 16'd111; // o
            8'h4D: scancode_to_hack = 16'd112; // p
            8'h15: scancode_to_hack = 16'd113; // q
            8'h2D: scancode_to_hack = 16'd114; // r
            8'h1B: scancode_to_hack = 16'd115; // s
            8'h2C: scancode_to_hack = 16'd116; // t
            8'h3C: scancode_to_hack = 16'd117; // u
            8'h2A: scancode_to_hack = 16'd118; // v
            8'h1D: scancode_to_hack = 16'd119; // w
            8'h22: scancode_to_hack = 16'd120; // x
            8'h35: scancode_to_hack = 16'd121; // y
            8'h1A: scancode_to_hack = 16'd122; // z
            // number
            8'h45: scancode_to_hack = 16'd48;  // 0
            8'h16: scancode_to_hack = 16'd49;  // 1
            8'h1E: scancode_to_hack = 16'd50;  // 2
            8'h26: scancode_to_hack = 16'd51;  // 3
            8'h25: scancode_to_hack = 16'd52;  // 4
            8'h2E: scancode_to_hack = 16'd53;  // 5
            8'h36: scancode_to_hack = 16'd54;  // 6
            8'h3D: scancode_to_hack = 16'd55;  // 7
            8'h3E: scancode_to_hack = 16'd56;  // 8
            8'h46: scancode_to_hack = 16'd57;  // 9
            //others
            8'h5A: scancode_to_hack = 16'd128; // Enter
            8'h76: scancode_to_hack = 16'd140; // Escape
            8'h66: scancode_to_hack = 16'd129; // Backspace
            8'h29: scancode_to_hack = 16'd32;  // Space
            8'h0D: scancode_to_hack = 16'd9;   // Tab
            8'h6C: scancode_to_hack = 16'd134; // Home
            8'h69: scancode_to_hack = 16'd135; // End
            8'h7D: scancode_to_hack = 16'd136; // PgUp
            8'h7A: scancode_to_hack = 16'd137; // PgDn
            // arrow
            8'h75: scancode_to_hack = 16'd131; // Up
            8'h72: scancode_to_hack = 16'd133; // Down
            8'h6B: scancode_to_hack = 16'd130; // Left
            8'h74: scancode_to_hack = 16'd132; // Right

            // F1~F12
            8'h05: scancode_to_hack = 16'd141; // F1
            8'h06: scancode_to_hack = 16'd142; // F2
            8'h04: scancode_to_hack = 16'd143; // F3
            8'h0C: scancode_to_hack = 16'd144; // F4
            8'h03: scancode_to_hack = 16'd145; // F5
            8'h0B: scancode_to_hack = 16'd146; // F6
            8'h83: scancode_to_hack = 16'd147; // F7
            8'h0A: scancode_to_hack = 16'd148; // F8
            8'h01: scancode_to_hack = 16'd149; // F9
            8'h09: scancode_to_hack = 16'd150; // F10
            8'h78: scancode_to_hack = 16'd151; // F11
            8'h07: scancode_to_hack = 16'd152; // F12

            default: scancode_to_hack = 16'd0;
        endcase
    end
endfunction



///////////////////////////////////////////////////////////////////////////
// Make / Break Code FSM.
// So when Ps2 want to send keystrokes, it have 2 parts.
// The makecode is what the PS2 code for that key is, it will repeat as long as the key is held.
// The Break Code is when you let go of the key, it will send out 0xF0, and the PS2 code for the key that was let go of.
// THis module determins what to do with the incoming packets.
reg is_break;

always @(posedge clk25 or posedge clr) begin
    if (clr) begin
        current_key <= 16'd0;
        is_break    <= 1'b0;

    end else if (rx_done) begin              //When Packet is done receiving.

        if (shift_reg[8:1] == 8'hF0) begin   //If the packet is 0xF0, it signals a key release. Next input should be a "release".
            is_break <= 1'b1;        
        end else begin

            if (is_break) begin              //If the last packet is break code, we clear the key buffer and reset the flag this cycle.
                current_key <= 16'd0;   
                is_break    <= 1'b0;         //KEYS ARE EXPECTED TO NOT INPUT WHEN UNPRESSED.
            end else begin

                current_key <= scancode_to_hack(shift_reg[8:1]);   //Finally we get to have a single output. After ALL THAT decoding.
            end
        end
    end
end

endmodule