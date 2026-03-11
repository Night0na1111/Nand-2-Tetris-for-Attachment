module rom_rect(
input clk,
output reg [15:0] instruction,
input wire [15:0] nextPC
);

reg [15:0] instructions [0:63];

always @(posedge clk)
begin
instruction <= instructions[nextPC[5:0]];
end

initial begin

// i = 0
instructions[0] = 16'b0000000000000000;
instructions[1] = 16'b1110110000010000;
instructions[2] = 16'b0000000000010000;
instructions[3] = 16'b1110001100001000;

// addr = SCREEN
instructions[4] = 16'b0100000000000000;
instructions[5] = 16'b1110110000010000;
instructions[6] = 16'b0000000000010001;
instructions[7] = 16'b1110001100001000;

// LOOP
instructions[8] = 16'b0000000000010000;
instructions[9] = 16'b1111110000010000;

instructions[10] = 16'b0000000000101000;
instructions[11] = 16'b1110001100000010;

// pattern select
instructions[12] = 16'b0000000000010000;
instructions[13] = 16'b1111110000010000;
instructions[14] = 16'b0000000000000001;
instructions[15] = 16'b1110000000010000;

instructions[16] = 16'b0000000000011010;
instructions[17] = 16'b1110001100000101;

// black row
instructions[18] = 16'b0000000000010001;
instructions[19] = 16'b1111110000100000;
instructions[20] = 16'b1110101010001000;
instructions[21] = 16'b0000000000011110;
instructions[22] = 16'b1110101010000111;

// white row
instructions[26] = 16'b0000000000010001;
instructions[27] = 16'b1111110000100000;
instructions[28] = 16'b1110111111001000;

// addr++
instructions[30] = 16'b0000000000010001;
instructions[31] = 16'b1111110111001000;

// counter++
instructions[32] = 16'b0000000000010000;
instructions[33] = 16'b1111110111001000;

instructions[34] = 16'b0000000000001000;
instructions[35] = 16'b1110101010000111;

// END
instructions[40] = 16'b0000000000101000;
instructions[41] = 16'b1110101010000111;

end

endmodule