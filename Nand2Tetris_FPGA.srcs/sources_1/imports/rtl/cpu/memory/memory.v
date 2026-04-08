`timescale 1ns/1ps

module memory(
    // Port A: CPU 讀寫
    input             clk,
    input      [14:0] address,
    output reg [15:0] out,
    input      [15:0] in_value,
    input             load,
    input      [15:0] kbd_current_key,

    // Port B: VGA 純讀
    input             second_clk,
    input      [14:0] second_address,
    output reg [15:0] second_out
);

    (* ram_style = "block" *)
    reg [15:0] mem [0:24575]; // Screen 結束在 24575，24576 是鍵盤暫存器

    integer i;
    initial begin
        for (i = 0; i < 24576; i = i + 1)
            mem[i] = 16'b0;
    end

    reg [15:0] bram_out;
    reg [14:0] addr_reg; // 對齊 BRAM 1-clock 延遲

    // Port A
    always @(posedge clk) begin
        addr_reg <= address;
        if (load && address < 15'd24576)
            mem[address] <= in_value;
        bram_out <= mem[address];
    end

    // 讀取多工：addr_reg 對齊 bram_out 的時間
    always @(*) begin
        if (addr_reg == 15'd24576)
            out = kbd_current_key;
        else
            out = bram_out;
    end

    // Port B: VGA 純讀
    always @(posedge second_clk) begin
        second_out <= mem[second_address];
    end

endmodule