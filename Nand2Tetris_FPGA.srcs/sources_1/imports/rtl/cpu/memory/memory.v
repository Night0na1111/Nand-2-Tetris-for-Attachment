`timescale 1ns/1ps

module memory(
              input clk,
              input [14:0] address,
              output [15:0] out,
              input [15:0] in_value,
              input wire load,
              
              input second_clk,
              input [14:0] second_address,
              output [15:0] second_out,
              input [15:0] second_in_value,
              input wire second_load
              );
   
    //ram16k ram(out, clk, in_value, load, address, 
    //            second_clk, second_address, second_out);
    ram16k_tdp ram(
            .clk(clk),
            .address(address), //address from CPU
            .out(out),        //data out to CPU
            .in_value(in_value), //data in from CPU
            .load(load), // cpu write

            .second_clk(second_clk),
            .second_address(second_address), //from Keyboard
            .second_out(second_out),
            .second_in_value(second_in_value),//KB data
            .second_load(second_load)//Keyboard write
            );

endmodule
