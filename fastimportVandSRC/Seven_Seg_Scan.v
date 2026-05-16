`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:11:03 03/07/2008 
// Design Name: 
// Module Name:    Seven_Seg_Scan 
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
module Seven_Seg_Scan(base_scan_clock, RESET, scan_out);
   input base_scan_clock, RESET;
   output [3:0] scan_out;
   reg [3:0] 	scan_out;
   reg [1:0] 	sel;
   

   always@(posedge base_scan_clock )
     begin
	if(RESET)
	  sel<=2'b00;
	else
	  sel<=sel+1'b1;
     end

   always@(sel[1:0])
     case(sel[1:0])
       //Please design your scan logic here within the case block
       2'b00:scan_out = 4'b1110;// Enable U1
       2'b01:scan_out = 4'b1101;// Enable U2 
       2'b10:scan_out = 4'b1011;// Enable U3 
       2'b11:scan_out = 4'b0111;// Enable U4 		 
     endcase

endmodule
