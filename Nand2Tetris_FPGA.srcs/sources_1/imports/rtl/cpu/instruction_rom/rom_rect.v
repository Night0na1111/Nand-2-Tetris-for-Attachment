module rom_rect(
    input clk,
    output reg [15:0] instruction,
    input wire [15:0] nextPC
);

    reg [15:0] instructions [0:32767];

    always @(posedge clk) 
    begin
        instruction <= instructions[nextPC];
    end

    initial begin
        $readmemb("D:/DeVtool/Vivado_HW/Nand2Tetris_FPGA/PongHomeMade2.hack", instructions);
    end

endmodule