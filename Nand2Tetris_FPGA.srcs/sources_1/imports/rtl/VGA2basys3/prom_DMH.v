`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:28:30 04/02/2012 
// Design Name: 
// Module Name:    prom_DMH 
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
module prom_DMH(
    input wire [12:0] addr,
    output wire [0:15] M
    );
	
   reg [0:15] rom [0:8191];
   	 
	 integer i;
	 
	 initial
		begin
			for(i=0; i<8191; i=i+1)
				rom[i] = 16'h3333;
		end
		
	assign M = rom[addr];

endmodule
