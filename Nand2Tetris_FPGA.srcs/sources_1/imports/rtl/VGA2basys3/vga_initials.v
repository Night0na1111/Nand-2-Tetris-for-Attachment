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

    reg [9:0] HSTART = 10'd64;
    reg [9:0] VSTART = 10'd112;

    // ============================================
    // 按鈕防彈跳 + one-shot（不變）
    // ============================================
    reg [19:0] debounce_l, debounce_r, debounce_u, debounce_d;
    reg btn_l_clean, btn_r_clean, btn_u_clean, btn_d_clean;
    reg btn_l_prev,  btn_r_prev,  btn_u_prev,  btn_d_prev;

    always @(posedge clk) begin
        debounce_l <= {debounce_l[18:0], btn_left};
        debounce_r <= {debounce_r[18:0], btn_right};
        debounce_u <= {debounce_u[18:0], btn_up};
        debounce_d <= {debounce_d[18:0], btn_down};

        btn_l_clean <= (&debounce_l);
        btn_r_clean <= (&debounce_r);
        btn_u_clean <= (&debounce_u);
        btn_d_clean <= (&debounce_d);

        btn_l_prev <= btn_l_clean;
        btn_r_prev <= btn_r_clean;
        btn_u_prev <= btn_u_clean;
        btn_d_prev <= btn_d_clean;
    end

    wire trig_left  = btn_l_clean && !btn_l_prev;
    wire trig_right = btn_r_clean && !btn_r_prev;
    wire trig_up    = btn_u_clean && !btn_u_prev;
    wire trig_down  = btn_d_clean && !btn_d_prev;

    // ============================================
    // HSTART / VSTART 更新（不變）
    // ============================================
    always @(posedge clk) begin
        if (trig_left  && HSTART >= 10'd8)           HSTART <= HSTART - 10'd4;
        if (trig_right && HSTART <= 10'd640 - 10'd8) HSTART <= HSTART + 10'd4;
        if (trig_up    && VSTART >= 10'd8)           VSTART <= VSTART - 10'd4;
        if (trig_down  && VSTART <= 10'd480 - 10'd8) VSTART <= VSTART + 10'd4;
    end

    // ============================================
    // ★ 修正：Pipeline 對齊 BRAM 延遲
    // ============================================
    // Stage 0 (combinational): 計算地址，送給 memory
    reg [9:0] x_s0;
    reg [8:0] y_s0;
    reg       visible_s0;

    always @(*) begin
        visible_s0 = (hc >= HSTART) && (hc < HSTART + 512) &&
                     (vc >= VSTART) && (vc < VSTART + 256);
        x_s0 = hc - HSTART;
        y_s0 = vc - VSTART;
    end

    // rom_addr 立即輸出 → memory 在下一個 clk edge 讀出 M
    always @(*) begin
        rom_addr = (y_s0 << 5) + (x_s0 >> 4);
    end

    // Stage 1: 延遲 hc/vc/vidon/visible 一個 clock，與 M 對齊
    reg [9:0]  hc_d1;
    reg [9:0]  vc_d1;
    reg        vidon_d1;
    reg        visible_d1;
    reg [9:0]  x_d1;

    always @(posedge clk) begin
        hc_d1      <= hc;
        vc_d1      <= vc;
        vidon_d1   <= vidon;
        visible_d1 <= visible_s0;
        x_d1       <= x_s0;
    end

    //用延遲後的 x 去索引 M
    reg [3:0] bit_x;
    reg       pixel;

    always @(*) begin
        bit_x = x_d1[3:0];
        pixel = M[bit_x];
    end

    // 輸出 RGB
    always @(*) begin
        if (vidon_d1 && visible_d1 && pixel) begin
            red   = 4'hF;
            green = 4'hF;
            blue  = 4'hF;
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end

endmodule