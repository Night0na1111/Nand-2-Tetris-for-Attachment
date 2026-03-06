`timescale 1ns / 1ps
//
//https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Dual-Port-Block-RAM-with-Two-Write-Ports-in-Read-First-Mode-Example-Verilog
//
`define Xilinx 1
`define Rect 1
// `timescale 1ns/1ps
// `include "../architecture/memory/memory.v"
// `include "../architecture/cpu/cpu.v"
// `include "../led_7seg/top_led7seg_scan.v"
// `include "../VGA2_basys3/vga_initials_top.v"
// `include "../keyboard/keyboard.v"
// `include "../instruction_rom/rom_rect.v"
// `include "../instruction_rom/rom_fill.v"
module top_computer(input clk_board_100M,
                input reset,
				//output[15:0] reg_d,
				output [7:0] led_7seg, //board 7seg led
				output [3:0] led_7seg_sel, //board AN[3:0]
	            output HSync, 
	            output VSync,
	            output[3:0] Blue, 
                output[3:0] Red, 
                output[3:0] Green,
                input wire PS2C,//interface keyboard
                input wire PS2D
                );
    
	 
	 // Value retrieved from memory and fed to VGA module.
	 wire[15:0] vga_memory_in;
	 // Address to read memory for VGA module from.
	 wire[12:0] vga_memory_addr;
	 vga_initials_top vga(.mclk(clk_board_100M), 
	                       .clr(reset),
	                       .memory_data(vga_memory_in), 
	                       .memory_address(vga_memory_addr),//vga 
                           .hsync(HSync),
                           .vsync(VSync), 
                           .blue(Blue), 
                           .red(Red), 
                           .green(Green));					 

    // Value retrieved from memory and fed to the CPU.
    wire[15:0] memory_out;
    // Value computed by the CPU and to be written into memory.
    wire[15:0] memory_in;
    // Whether to write `memory_in` to memory or not.
    wire memory_load;
    // The address to write `memory_in` to if `memory_load` is true.
    wire[14:0] memory_address;
    wire clk;      
    memory memory_unit(
        .clk(clk), 
        .address(memory_address),
        .out(memory_out), 
        .in_value(memory_in), 
        .load(memory_load), 
        //=====================//
        .second_clk(clk), 
        //.second_address({2'b10,vga_memory_addr}),
        .second_address(second_mem_address ),//integrate with KB
        //address index from screen memory (Read Only)
        //address index from keyboard (Write Only) 15'h6000
        .second_out(vga_memory_in), //data read out to the VGA
		.second_in_value(xkey),//from KB
        .second_load(keyboard_write)//from KB
    );
//============================
//keyboard and VGA arbitration
//============================
    reg [14:0] second_mem_address;
    reg [15:0] key_hold;
    reg key_pressed, key_released;
    reg keyboard_write;
    wire [15:0] xkey;
    always@(*)
        begin
            //if((key_pressed||key_released)&& (|vga_memory_addr==1'b0))
            if((key_pressed)&& (|vga_memory_addr==1'b0))
                keyboard_write=1'b1;
                //keyboard can only write to memory
                //when VGA is idle (not reading)
            else
                keyboard_write=1'b0;
        end

    //Second Address MUX
    //VGA and keyboard are sharing the same address bus
    //VGA read has the priority
    always@(*)
        begin
            if (keyboard_write)
                second_mem_address=15'h6000;
            else 
                second_mem_address={2'b10,vga_memory_addr};
        end
    
    //detect key press
    //write mem address 15'h6000 with xkey[7:0]
    
    always@(posedge clk)
        begin
            if(reset)
                key_pressed<=1'b0;
            else if(xkey[15:8]==xkey[7:0])
                key_pressed<=1'b1;
            //xkey is hold whenever a key is pressed
            else 
                key_pressed<=1'b0;
        end
    //detect key release
    //write mem address 15'h6000 with 16'h0
    always@(posedge clk)
        begin
            if(reset)
                key_released<=1'b0;
            else if(xkey[15:8]==8'hF0)
                key_released<=1'b1;
            //a key is released
            else 
                key_released<=1'b0;
        end

//============================
//instruction ROM
//============================
    wire[15:0] nextPC;
    wire [15:0] instruction;
    
 
`ifdef Rect

    rom_rect(
        .clk(clk),
        .instruction(instruction),
        .nextPC(nextPC)
    );
    

`else
   
 rom_fill(
        .clk(clk),
        .instruction(instruction),
        .nextPC(nextPC)
    );
`endif
///////////////////////////////////////////////////    

   
    cpu cpu_unit(.clk(clk), 
                .inM(memory_out), 
                .instruction(instruction), 
                .reset(reset), 
                .outM(memory_in), 
                .writeM(memory_load), 
                .addressM(memory_address), 
                .newPC(nextPC)
                ); 
                //reg_d);
                ///
          
    reg [1:0] clock_divider;
    always@(posedge clk_board_100M)
        if(reset)
            clock_divider<=1'b0;
        else
            clock_divider<=clock_divider+1'b1;
    assign clk=clock_divider[1];//25Mhz clock
/*
    clk_wiz_0 clk_wiz_0(clk, //10Mhz clock
                          reset, 
                          locked, 
                          clk_board_100M //100Mhz Board clock
                          );
*/

    top_led7seg_scan led_scan(
        .data_16(xkey),  
        .clk(clk),  
        .RESET(reset),
        .Seven_segment_out(led_7seg),
        .Seven_segment_sel(led_7seg_sel)
        );
    keyboard keyboard(
        .clk25(clk),
        .clr(reset),
        .PS2C(PS2C),
        .PS2D(PS2D),
        .xkey(xkey)
    );
endmodule
