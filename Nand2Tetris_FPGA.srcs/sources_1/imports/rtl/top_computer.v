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
    input wire PS2D,

    input wire btn_up,
    input wire btn_right,
    input wire btn_down,
    input wire btn_left
);


    // Memory reset routine.
    // In memory.v, we only zero out on first flash. This memory wipe run on reset, and before the rest of CPU(thus not creating problems).
    // This is... not according to N2T spec (The og spec relies on software wipe), but put here for the sake of avoiding future confusion. 
    reg        mem_clearing;
    reg [14:0] clr_addr;

    always @(posedge clk_board_100M) begin
        if (reset) begin
            mem_clearing <= 1'b1;
            clr_addr     <= 15'd0;
        end else if (mem_clearing) begin
            if (clr_addr == 15'd24575)
                mem_clearing <= 1'b0;
            else
                clr_addr <= clr_addr + 1;
        end
    end

    /////////////////////////////////////////////////////////////////////////////////
    // CPU enable - stop during clr, slows cpu to 12.5Mhz
    // This thing keeps the internals of CPU (not vga, not memory, not keyboard) stalled long enough to solve timing issues caused by registers.
    // Note: Might be able to push further, you could experiment if 25 or 50MHZ still works for timing.

    reg [2:0] phase_counter;

    always @(posedge clk_board_100M) begin
        if (reset) phase_counter <= 3'd0;
        else       phase_counter <= phase_counter + 1;
    end

    wire cpu_enable = (phase_counter == 3'd7) && !mem_clearing;

    ////////////////////////////////////////////////////////////////////////////////
    // VGA
    wire [15:0] vga_memory_in;
    wire [12:0] vga_memory_addr;

    vga_initials_top vga(
        .mclk(clk_board_100M),
        .clr(reset),
        .memory_data(vga_memory_in),
        .memory_address(vga_memory_addr),
        .btn_up(btn_up),
        .btn_right(btn_right),
        .btn_down(btn_down),
        .btn_left(btn_left),
        .hsync(HSync),
        .vsync(VSync),
        .blue(Blue),
        .red(Red),
        .green(Green)
    );

    ////////////////////////////////////////////////////////////
    // Keyboard
    wire [15:0] current_key;

    keyboard keyboard(
        .clk25(clk_board_100M),
        .clr(reset),
        .PS2C(PS2C),
        .PS2D(PS2D),
        .current_key(current_key)
    );

    ///////////////////////////////////////////////////////////
    // CPU outputted Memory signal lines
    wire [15:0] cpu_outM;
    wire        cpu_writeM;
    wire [14:0] cpu_addressM;


    // Memory clear MUX, this thing is wired to the memory clearing logic up there.
    // And is here to force all inputs  into zero & always load when clearing.
    // Also is here to bridge between CPU and memory.
    wire [14:0] memory_address = mem_clearing ? clr_addr      : cpu_addressM;
    wire [15:0] memory_in      = mem_clearing ? 16'b0         : cpu_outM;
    wire        memory_load    = mem_clearing ? 1'b1          : cpu_writeM;

    //////////////////////////////////////////////////////////
    // MEMORY
    wire [15:0] memory_out;

    memory memory_unit(
        .clk(clk_board_100M),
        .reset(reset),                              
        .address(memory_address),
        .out(memory_out),
        .in_value(memory_in),
        .load(memory_load),
        .kbd_current_key(current_key),

        .second_clk(clk_board_100M),
        .second_address({2'b10, vga_memory_addr}),
        .second_out(vga_memory_in)
    );

    /////////////////////////////////////////////////////////
    // ROM
    wire [15:0] nextPC;
    wire [15:0] instruction;

    rom_rect rom_rect_unit(
        .clk(clk_board_100M),
        .instruction(instruction),
        .nextPC(nextPC[14:0])
    );


    // CPU
    cpu cpu_unit(
        .clk(clk_board_100M),
        .cpu_enable(cpu_enable),
        .inM(memory_out),
        .instruction(instruction),
        .reset(reset),
        .outM(cpu_outM),
        .writeM(cpu_writeM),
        .addressM(cpu_addressM),
        .newPC(nextPC)
    );


    // 7-segment display (for showing current keyboard key)
    top_led7seg_scan led_scan(
        .data_16(current_key),
        .clk(clk_board_100M),
        .RESET(reset),
        .Seven_segment_out(led_7seg),
        .Seven_segment_sel(led_7seg_sel)
    );

endmodule