`timescale 1ns/1ps

module memory(
    // Port A: CPU 讀寫
    input             clk,
    input             reset,          // ← 新增
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
    reg [15:0] mem [0:24575];

    integer i;
    initial begin
        for (i = 0; i < 24576; i = i + 1)
            mem[i] = 16'b0;
    end

    reg [15:0] bram_out;
    reg [14:0] addr_reg;//對齊bram延遲

    // Port A - 寫入路徑的 address/in_value/load 完全由外部控制
    // reset 期間由 top 層的 FSM 送入清零地址與資料
    always @(posedge clk) begin
        addr_reg <= address;
        if (load && address < 15'd24576)
            mem[address] <= in_value;
        bram_out <= mem[address];
    end

    // 讀取多工
    always @(*) begin
        if (reset)
            out = 16'b0;            // 清零期間強制輸出 0，避免 CPU 讀到垃圾
        else if (addr_reg == 15'd24576)
            out = kbd_current_key;
        else
            out = bram_out;
    end

    // Port B: VGA 純讀
    always @(posedge second_clk) begin
        second_out <= mem[second_address];
    end

endmodule