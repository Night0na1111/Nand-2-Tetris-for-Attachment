module rom_rect(
    input clk,
    output reg [15:0] instruction,
    input [15:0] nextPC
);

(* rom_style = "block" *)
reg [15:0] rom [0:32767];

initial $readmemb("PongHomeMade2.mem", rom);  // simulation 用

// 改用 COE 初始化需要透過 Vivado IP，見下方說明

always @(posedge clk)
    instruction <= rom[nextPC];

endmodule