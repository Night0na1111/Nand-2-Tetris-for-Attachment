`timescale 1ns/1ps

module memory(
input clk,
input [14:0] address,
output reg [15:0] out,
input [15:0] in_value,
input load,

input second_clk,
input [14:0] second_address,
output reg [15:0] second_out,
input [15:0] second_in_value,
input second_load
);

reg [15:0] mem [0:24575];

always @(posedge clk) begin
    out <= mem[address];
    if(load)
        mem[address] <= in_value;
end

always @(posedge second_clk) begin
    second_out <= mem[second_address];
    if(second_load)
        mem[second_address] <= second_in_value;
end

endmodule