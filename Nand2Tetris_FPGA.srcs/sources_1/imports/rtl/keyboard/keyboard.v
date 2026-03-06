`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:44:07 05/02/2012 
// Design Name: 
// Module Name:    keyboard 
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
module keyboard(
input wire clk25 ,
input wire clr ,
input wire PS2C ,
input wire PS2D ,
output wire [15:0] xkey
    );
reg PS2Cf, PS2Df;
reg [7:0] ps2c_filter,ps2d_filter;
reg [10:0] shift1, shift2;
assign xkey = {shift2[8:1], shift1[8:1]};

//filter for PS2 clock and data
always @(posedge clk25 or posedge clr)
  begin
    if(clr == 1)
      begin
           ps2c_filter <= 0;
           ps2d_filter <= 0;
           PS2Cf <= 1;
           PS2Df <= 1;
      end
    else
      begin
           ps2c_filter[7] <= PS2C;
           ps2c_filter[6:0] <= ps2c_filter[7:1];
           ps2d_filter[7] <= PS2D;
           ps2d_filter[6:0] <= ps2d_filter[7:1];
           if(ps2c_filter == 8'b11111111)
              PS2Cf <= 1;
           else
               if(ps2c_filter == 8'b00000000)
                     PS2Cf <= 0;
           if(ps2d_filter == 8'b11111111)
                     PS2Df <= 1;
           else
               if(ps2d_filter == 8'b00000000)
                     PS2Df <= 0;
      end
  end

//Shift register used to clock in scan codes from PS2
always @(negedge PS2Cf or posedge clr)
  begin
    if(clr == 1)
      begin
           shift1 <= 0;
           shift2 <= 0;
      end
    else
      begin
           shift1 <= {PS2Df,shift1[10:1]};
           shift2 <= {shift1[0],shift2[10:1]};
      end
  end

endmodule
