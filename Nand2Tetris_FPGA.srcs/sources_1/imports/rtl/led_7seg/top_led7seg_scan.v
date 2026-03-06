//////////////////////////////////////////////////////////////////////////////////
// Company: CYCU
// Engineer: 
// 
// Create Date:    11:30:44 03/07/2008 
// Design Name: 
// Module Name:   scan_7segment
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
// `include "../led_7seg/Clk_Div.v"
// `include "../led_7seg/mux4_1.v"
// `include "../led_7seg/Seven_Seg_Scan.v"
// `include "../led_7seg/Seven_segment_decoder.v"
module top_led7seg_scan(data_16,
    clk,  RESET, 	Seven_segment_out, Seven_segment_sel);
   
   input       clk;
   input       RESET;
   input [15:0] data_16;
   output [7:0] Seven_segment_out;//to segment a,b,...,g
   output [3:0] Seven_segment_sel;//to AN[3:0]


   wire [15:0] 	clk_div;
   wire [3:0] 	hex_value;
  
 	

   Clk_Div U1(.clk(clk), //A 50MHz clock
	      .RESET(RESET), 
	      .clk_div_out(clk_div)
         // A 16-bit wire, 
         //clk_div[0]: 381.47Hz Hz
          //clk_div[3]: 47.68Hz Hz
	      );
   
   
   mux4_1 U2(
  
	.hex_out(hex_value),
	.sel(Seven_segment_sel), 
	.data_16(data_16));
   
   //Turn on the 7-Led digit sequentially
   Seven_Seg_Scan U3(.base_scan_clock(clk_div[0]), 
		     .RESET(RESET),
		     .scan_out(Seven_segment_sel));

   //A 7 segment led decoder
   Seven_segment_decoder U4(.hex_in(hex_value), 
			    .segment_led_out(Seven_segment_out));

endmodule
