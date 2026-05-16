`timescale 1ns/1ps

module memory(
    // Port A: CPU read and write
    input             clk,
    input             reset,         
    input      [14:0] address,
    output reg [15:0] out,
    input      [15:0] in_value,
    input             load,
    input      [15:0] kbd_current_key,

    // Port B: VGA read
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
    reg [14:0] addr_reg;//match bram delay

    // Port A
    always @(posedge clk) begin
        addr_reg <= address;
        if (load && address < 15'd24576)
            mem[address] <= in_value;
        bram_out <= mem[address];
    end

    // read mux
    always @(*) begin
        if (reset)
            out = 16'b0;            // output 0 during clr
        else if (addr_reg == 15'd24576)
            out = kbd_current_key;
        else
            out = bram_out;
    end

    // Port B: VGA read
    always @(posedge second_clk) begin
        second_out <= mem[second_address];
    end

endmodule