`timescale 1ns / 1ps

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

    //=========================================================
    // CPU CLOCK ENABLE
    // 用 3-bit counter 產生 cpu_enable 脈衝
    // 每 8 個 100MHz cycle enable 一次（等效 12.5MHz）
    //
    // 時序說明：
    //   Phase 0: cpu_enable 觸發，CPU 更新 PC/reg_a（posedge）
    //   Phase 1: ROM/Memory 鎖存新地址（posedge 100MHz）
    //   Phase 2: ROM/Memory 輸出新資料（sync read 延遲 1 cycle）
    //   Phase 3~6: 資料穩定
    //   Phase 7: 下一次 cpu_enable，CPU 讀到正確的 instruction/inM
    //=========================================================
    reg [2:0] phase_counter;

    always @(posedge clk_board_100M) begin
        if (reset)
            phase_counter <= 3'd0;
        else
            phase_counter <= phase_counter + 1;
    end

    wire cpu_enable = (phase_counter == 3'd7);

    //=========================================================
    // VGA
    //=========================================================
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

    //=========================================================
    // KEYBOARD
    //=========================================================
    wire [15:0] xkey;
    reg key_pressed;

    keyboard keyboard(
        .clk25(clk_board_100M),
        .clr(reset),
        .PS2C(PS2C),
        .PS2D(PS2D),
        .xkey(xkey)
    );

    always @(posedge clk_board_100M) begin
        if (reset)
            key_pressed <= 0;
        else if (xkey != 16'h0000 && xkey != 16'h00F0)
            key_pressed <= 1;
        else
            key_pressed <= 0;
    end

    //=========================================================
    // MEMORY + VGA/KEYBOARD MUX
    //=========================================================
    wire [15:0] memory_out;
    wire [15:0] memory_in;
    wire        memory_load;
    wire [14:0] memory_address;

    reg [14:0] second_mem_address;
    reg        keyboard_write;

    always @(*) begin
        if (key_pressed && vga_memory_addr == 13'b1111111111111)
            keyboard_write = 1'b1;
        else
            keyboard_write = 1'b0;

        if (keyboard_write)
            second_mem_address = 15'd24576;
        else
            second_mem_address = {2'b10, vga_memory_addr};
    end

    memory memory_unit(
        .clk(clk_board_100M),
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

    //=========================================================
    // ROM
    //=========================================================
    wire [15:0] nextPC;
    wire [15:0] instruction;

    rom_rect rom_rect_unit(
        .clk(clk_board_100M),
        .instruction(instruction),
        .nextPC(nextPC[14:0])       // 明確截斷為 15-bit
    );

    //=========================================================
    // CPU - 改接 100MHz，用 cpu_enable 控制執行頻率
    //=========================================================
    cpu cpu_unit(
        .clk(clk_board_100M),      // ★ 改：原本是 cpu_clk（慢時脈），現在統一用 100MHz
        .cpu_enable(cpu_enable),   // ★ 新增
        .inM(memory_out),
        .instruction(instruction),
        .reset(reset),
        .outM(memory_in),
        .writeM(memory_load),
        .addressM(memory_address),
        .newPC(nextPC)
    );

    //=========================================================
    // 7-SEGMENT DISPLAY
    //=========================================================
    top_led7seg_scan led_scan(
        .data_16(xkey),
        .clk(clk_board_100M),
        .RESET(reset),
        .Seven_segment_out(led_7seg),
        .Seven_segment_sel(led_7seg_sel)
    );

endmodule