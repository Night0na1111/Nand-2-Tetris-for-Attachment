`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: CYCU
// Engineer: 
// 
// Create Date:    11:10:18 03/07/2008 
// Design Name: 
// Module Name:    Dip_SW_input 
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
module mux4_1(data_16,sel,hex_out );
  
   input [3:0] sel;
   input [15:0] data_16;
   output [3:0] hex_out;
   reg [3:0] 	hex_out;
   
   always@(data_16 or sel)
     case(sel)
		4'b1110:hex_out = data_16[3:0];
		4'b1101:hex_out = data_16[7:4];
		4'b1011:hex_out = data_16[11:8];
		4'b0111:hex_out = data_16[15:12];			
       //multiplex the input signals (hex_1, hex_2 or counter) to the output, "hex_out"
       //  
     endcase
endmodule
