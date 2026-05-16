`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CYCU
// Engineer: 
// 
// Create Date:    09:56:37 03/07/2008 
// Design Name: 
// Module Name:    Clk_Div 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Clk_Div(clk, RESET, clk_div_out);
   input clk;
   input  RESET;
   output [15:0] clk_div_out;
   reg [63:0] 	 count;
   wire [15:0] 	 clk_div_out;
     
   assign clk_div_out=count[30:15];
   //There are 16bits for the clk_div_out,
   //it will be easier for the designer to try out different clocks
   
   //The input clock is a 50Mhz signal (from Nexys2 clocks)
   //Therefore, 
   // count[0] represents a 25Mhz clk
   // count[1]: 12.5MHz
   // count[2]: 6.25MHz
   // count[3]: 3.125MHz
   // ...
   //count[16]:381.47Hz
   //count[17]:190.73Hz
   // count[18]:95.37Hz
   // count[19]:47.68Hz
   // count[20]:23.84Hz

   
   //This is a 64-bit counter 
   always@(posedge clk)
     begin
	if(RESET)
	  count<=64'b0;
	else
	  count<=count+1;
	
     end 
endmodule 