`timescale 1ns / 1ps

module rom_rect(
    input clk,
    input [14:0] nextPC,
    output reg [15:0] instruction 
);
    
    reg [15:0] rom [0:32767];

    initial begin
        $readmemb("C:/Users/wunai/Desktop/project/N2TPackage/PongHomeMade2.txt", rom); 
    end

    always @(posedge clk) begin
        instruction <= rom[nextPC];
    end

endmodule