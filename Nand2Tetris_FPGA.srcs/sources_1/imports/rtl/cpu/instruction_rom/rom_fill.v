//instruction ROM
//fill
module rom_fill(
    input clk,
    output [15:0] instruction,
    input wire[15:0] nextPC
    );
    
    reg [15:0] instructions [0:35];
    reg [15:0] instruction;
 

    //load the Rect instructions for quick debug
    always @(posedge clk) 
    begin
       instruction <= instructions[nextPC];
    end

    initial begin

instructions[0]=16'b0100000000000000;
instructions[1]=16'b1110110000010000;
instructions[2]=16'b0000000000000000;
instructions[3]=16'b1110001100001000;
instructions[4]=16'b0110000000000000;
instructions[5]=16'b1111110000010000;
instructions[6]=16'b0000000000001100;
instructions[7]=16'b1110001100000001;
instructions[8]=16'b0000000000010000;
instructions[9]=16'b1110001100000010;
instructions[10]=16'b0000000000000100;
instructions[11]=16'b1110101010000111;
instructions[12]=16'b0000000000000001;
instructions[13]=16'b1110111010001000;
instructions[14]=16'b0000000000010100;
instructions[15]=16'b1110101010000111;
instructions[16]=16'b0000000000000001;
instructions[17]=16'b1110101010001000;
instructions[18]=16'b0000000000010100;
instructions[19]=16'b1110101010000111;
instructions[20]=16'b0000000000000001;
instructions[21]=16'b1111110000010000;
instructions[22]=16'b0000000000000000;
instructions[23]=16'b1111110000100000;
instructions[24]=16'b1110001100001000;
instructions[25]=16'b0000000000000000;
instructions[26]=16'b1111110111010000;
instructions[27]=16'b0110000000000000;
instructions[28]=16'b1110000111010000;
instructions[29]=16'b0000000000000000;
instructions[30]=16'b1111110111001000;
instructions[31]=16'b1111110000100000;
instructions[32]=16'b0000000000010100;
instructions[33]=16'b1110001100000001;
instructions[34]=16'b0000000000000000;
instructions[35]=16'b1110101010000111;
    end

endmodule