`timescale 1ns/1ps

module memory(
    // Port A: CPU read and write
    input        reset,        
    input [15:0] kbd_current_key,

    input        clk,       
    input [14:0] address,      
    input [15:0] in_value,      
    input        load,         
    output reg [15:0] out,              
    

    // Port B: VGA read
    input        second_clk,
    input [14:0] second_address,
    output reg [15:0] second_out
);

////////////////////////////////////////////////////
//Zeros out all memories on initial boot(Not on reset), just clearing the garbage.
//N2T relies on software memory flushes according to official spec.

    (* ram_style = "block" *)
    reg [15:0] mem [0:24575];   //Declare 16bit, 24576 slot memory.

    integer i;
    initial begin
        for (i = 0; i < 24576; i = i + 1)
            mem[i] = 16'b0;
    end
///////////////////////////////////////////////////

    reg [15:0] bram_out;
    reg [14:0] addr_reg; //Store address, 1 cycle late, match bram delay.

    // Port A: write, Delay: 1 cycle
    always @(posedge clk) begin
        addr_reg <= address;

        if (load && address < 15'd24576) //Write boundary check
            mem[address] <= in_value;

        bram_out <= mem[address];
    end

    // Port A: read mux (Combinational)
    // Remember, RAM is always a cycle late. bram_out gives what was requested last cycle, kbd_current_key must be a cycle late too for consistency's sake.
    // We never wrote keyboard value into ram, just a design choice.
    always @(*) begin
        if (reset)
            out = 16'b0;            // output 0 during clr
        else if (addr_reg == 15'd24576) 
            out = kbd_current_key;
        else
            out = bram_out;
    end



    // Port B: VGA read (Sequential) 100Mhz too.
    always @(posedge second_clk) begin
        second_out <= mem[second_address];
    end

endmodule