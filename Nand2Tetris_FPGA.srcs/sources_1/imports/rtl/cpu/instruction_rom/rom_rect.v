//instruction ROM
//fill
module rom_rect(
    input clk,
    output reg [15:0] instruction,
    input wire[15:0] nextPC
    );
    
    reg [15:0] instructions [0:20];
 

    //load the Rect instructions for quick debug
    always @(posedge clk) 
    begin
       instruction <= instructions[nextPC];
    end

    initial begin

/*
       //demo code for Add 2+3=5
       instructions[0]=16'b0000000000000010;
       instructions[1]=16'b1110110000010000;
       instructions[2]=16'b0000000000000011;
       instructions[3]=16'b1110000010010000;
       instructions[4]=16'b0000000000000000;
       instructions[5]=16'b1110001100001000;
       */
//demo code for rect.hack
instructions[0]=16'b0000000000000000;
instructions[1]=16'b1111110000010000;
instructions[2]=16'b0000000000010000;
instructions[3]=16'b1110001100001000;
instructions[4]=16'b0100000000000000;
instructions[5]=16'b1110110000010000;
instructions[6]=16'b0000000000010001;
instructions[7]=16'b1110001100001000;
instructions[8]=16'b0000000000010001;
instructions[9]=16'b1111110000100000;
instructions[10]=16'b1110111010001000;
instructions[11]=16'b0000000000010001;
instructions[12]=16'b1111110000010000;
//instructions[13]=16'b0000000000100000;//solid
instructions[13]=16'b0000000001000000;//every other raw
instructions[14]=16'b1110000010010000;
instructions[15]=16'b0000000000010001;
instructions[16]=16'b1110001100001000;
instructions[17]=16'b0000000000010000;
instructions[18]=16'b1111110010011000;
instructions[19]=16'b0000000000001000;
instructions[20]=16'b1110001100000111;
end

endmodule