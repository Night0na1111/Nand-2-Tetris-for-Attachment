`timescale 1ns / 1ps

module keyboard(
    input  wire        clk25,
    input  wire        clr,
    input  wire        PS2C,
    input  wire        PS2D,
    output reg  [15:0] current_key
);

// ============================================
// 1. PS2 濾波器
// ============================================
reg [7:0] ps2c_filter, ps2d_filter;
reg PS2Cf, PS2Df;

always @(posedge clk25 or posedge clr) begin
    if (clr) begin
        ps2c_filter <= 8'hFF;
        ps2d_filter <= 8'hFF;
        PS2Cf       <= 1;
        PS2Df       <= 1;
    end else begin
        ps2c_filter <= {ps2c_filter[6:0], PS2C};
        ps2d_filter <= {ps2d_filter[6:0], PS2D};

        if      (ps2c_filter == 8'hFF) PS2Cf <= 1;
        else if (ps2c_filter == 8'h00) PS2Cf <= 0;

        if      (ps2d_filter == 8'hFF) PS2Df <= 1;
        else if (ps2d_filter == 8'h00) PS2Df <= 0;
    end
end

// ============================================
// 2. 偵測 PS2Cf 下降沿（全部留在 clk25 domain）
// ============================================
reg PS2Cf_prev;
always @(posedge clk25 or posedge clr) begin
    if (clr) PS2Cf_prev <= 1;
    else     PS2Cf_prev <= PS2Cf;
end
wire ps2c_fall = (PS2Cf_prev == 1 && PS2Cf == 0);

// ============================================
// 3. 接收完整 11-bit Frame
// ============================================
reg [3:0]  bit_cnt;
reg [10:0] shift_reg;
reg        rx_done;

always @(posedge clk25 or posedge clr) begin
    if (clr) begin
        bit_cnt   <= 0;
        shift_reg <= 0;
        rx_done   <= 0;
    end else begin
        rx_done <= 0;
        if (ps2c_fall) begin
            shift_reg <= {PS2Df, shift_reg[10:1]};
            if (bit_cnt == 4'd10) begin
                bit_cnt <= 0;
                rx_done <= 1;
            end else begin
                bit_cnt <= bit_cnt + 1;
            end
        end
    end
end

// ============================================
// 4. Scan Code → Hack Key Code 對照表
// ============================================
function [15:0] scancode_to_hack;
    input [7:0] sc;
    begin
        case (sc)
            // 字母
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
            // 數字
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
            // 特殊鍵
            8'h5A: scancode_to_hack = 16'd128; // Enter
            8'h76: scancode_to_hack = 16'd140; // Escape
            8'h66: scancode_to_hack = 16'd129; // Backspace
            8'h29: scancode_to_hack = 16'd32;  // Space
            8'h0D: scancode_to_hack = 16'd9;   // Tab
            // 方向鍵
            8'h75: scancode_to_hack = 16'd131; // Up
            8'h72: scancode_to_hack = 16'd133; // Down
            8'h6B: scancode_to_hack = 16'd130; // Left
            8'h74: scancode_to_hack = 16'd132; // Right
            // Home / End / PgUp / PgDn
            8'h6C: scancode_to_hack = 16'd134; // Home
            8'h69: scancode_to_hack = 16'd135; // End
            8'h7D: scancode_to_hack = 16'd136; // PgUp
            8'h7A: scancode_to_hack = 16'd137; // PgDn
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

// ============================================
// 5. Make / Break 狀態機
// ============================================
reg is_break;

always @(posedge clk25 or posedge clr) begin
    if (clr) begin
        current_key <= 16'd0;
        is_break    <= 1'b0;
    end else if (rx_done) begin
        if (shift_reg[8:1] == 8'hF0) begin
            is_break <= 1'b1;           // 收到 Break prefix
        end else begin
            if (is_break) begin
                current_key <= 16'd0;   // 按鍵放開，清零
                is_break    <= 1'b0;
            end else begin
                current_key <= scancode_to_hack(shift_reg[8:1]); // 按下，轉換
            end
        end
    end
end

endmodule