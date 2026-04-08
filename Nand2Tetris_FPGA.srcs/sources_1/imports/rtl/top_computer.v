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
    //=========================================================
    reg [2:0] phase_counter;

    always @(posedge clk_board_100M) begin
        if (reset) phase_counter <= 3'd0;
        else       phase_counter <= phase_counter + 1;
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
    wire [15:0] current_key;

    keyboard keyboard(
        .clk25(clk_board_100M),
        .clr(reset),
        .PS2C(PS2C),
        .PS2D(PS2D),
        .current_key(current_key)
    );

    //=========================================================
    // MEMORY
    //=========================================================
    wire [15:0] memory_out;
    wire [15:0] memory_in;
    wire        memory_load;
    wire [14:0] memory_address;

    memory memory_unit(
        .clk(clk_board_100M),
        .address(memory_address),
        .out(memory_out),
        .in_value(memory_in),
        .load(memory_load),
        .kbd_current_key(current_key),

        .second_clk(clk_board_100M),
        .second_address({2'b10, vga_memory_addr}),
        .second_out(vga_memory_in)
    );

    //=========================================================
    // ROM
    //=========================================================
    wire [15:0] nextPC;
    wire [15:0] instruction;

    rom_rect rom_rect_unit(
        .clk(clk_board_100M),
        .instruction(instruction),
        .nextPC(nextPC[14:0])
    );

    //=========================================================
    // CPU
    //=========================================================
    cpu cpu_unit(
        .clk(clk_board_100M),
        .cpu_enable(cpu_enable),
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
        .data_16(current_key),
        .clk(clk_board_100M),
        .RESET(reset),
        .Seven_segment_out(led_7seg),
        .Seven_segment_sel(led_7seg_sel)
    );

endmodule