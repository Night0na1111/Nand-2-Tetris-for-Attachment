`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:46:46 04/02/2012 
// Design Name: 
// Module Name:    vga_initials 
// Project Name: 
// Target Devices: Xilinx Basys3
// Tool versions: 
// Description: Codes are modified based on "Digital Design-Using Digilent FPGA Boards"
//              Verilog/Active-HDL Edition
//              by Richard E. Haskell & Darrin M. Hanna
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_initials(
    input wire vidon,
    input wire [9:0] hc,
    input wire [9:0] vc,
    input wire [15:0] M,
    input wire [7:0] sw,
    output wire [12:0] rom_addr,
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue
    );
	
	 parameter hbp = 10'b0010010000;
			//Horizontal back porch = 144 (128+16)
	 parameter vbp = 10'b0000011111;
			//Vertical back porch = 31 (2+29)
	 parameter W = 512;
	 parameter H = 256;
	 wire [12:0] C1, R1;
	 wire [15:0] rom_pix;
	 wire [12:0] vc_adjust, hc_adjust;//
	 reg spriteon, R, G, B;
	 
	 assign C1 = {4'b0000, sw[3:0], 5'b00001};
	 assign R1 = {4'b0000, sw[7:4], 5'b00001};

	 //do not read the memory outside the sprite region
	 //leave a break for keyboard to write the memory
	 assign  vc_adjust= spriteon?(vc - vbp - R1):13'b0;
	 assign  hc_adjust= spriteon?(hc - hbp - C1):13'b0;
	 assign rom_addr = (vc_adjust<<5)+(hc_adjust>>5);
	 assign rom_pix = hc_adjust[3:0];
	 
	 /*
	 assign rom_addr = vc - vbp - R1;
	 assign rom_pix = hc - hbp - C1;
	 assign rom_addr4 = rom_addr[12:0];
	 */
	 //Enable sprite video out when within the sprite region
	 
	 always @(*)
		begin 
			if ((hc >= C1 + hbp )&&(hc < C1 + hbp + W)&&(vc >= R1 + vbp)&&(vc < R1 + vbp + H))
				spriteon = 1 ;
			else
				spriteon = 0 ;
		end
		
	//Output video color signals
	
	always @(*)
		begin 
			red = 0;
			green = 0;
			blue = 0;
			R = M[rom_pix];
			G = M[rom_pix];
			B = M[rom_pix];
			if((spriteon == 1'b1)&&(vidon == 1'b1))
				begin
					red = {R,R,R,R};
					//green = {G,G,G};
					//blue = {B,B,B};
					green ={1'b0,1'b0,1'b0,1'b0};
					blue = {1'b0,1'b0,1'b0,1'b0};
				end
			else
			     begin
			        red = {1'b0,1'b0,1'b0,1'b0};
				    green ={1'b0,1'b0,1'b0,1'b0};
					blue = {1'b0,1'b0,1'b0,1'b0};
			     end
		end
	 
endmodule
