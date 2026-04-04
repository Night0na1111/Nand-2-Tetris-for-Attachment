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

    reg [15:0] mem [0:24576];

    integer i;
    initial begin
        for (i = 0; i <= 24576; i = i + 1)
            mem[i] = 16'b0;
    end

    // Port A: CPU 讀寫 (synchronous - BRAM 可推斷)
    always @(posedge clk) begin
        if (load)
            mem[address] <= in_value;
        out <= mem[address];
    end

    // Port B: VGA 讀取 / Keyboard 寫入 (synchronous)
    always @(posedge second_clk) begin
        if (second_load)
            mem[second_address] <= second_in_value;
        second_out <= mem[second_address];
    end

endmodule