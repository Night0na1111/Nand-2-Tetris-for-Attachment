`timescale 1ns / 1ps

module rom_rect #(
    parameter ROM_MODE = 0   // 0:.mem , 1: test(block)
)(
    input clk,
    input [14:0] nextPC,
    output reg [15:0] instruction
);

    reg [15:0] rom [0:32767];

    generate
        if (ROM_MODE == 0) begin : MODE_MEM_FILE
            initial begin
                $readmemb("C:/Users/jason/Desktop/project_test/N2T-main/N2TPackage/PongHomeMade2.mem", rom);
            end
        end else begin : MODE_TEST_BLOCK
            integer i;
            initial begin
                for (i = 0; i < 32768; i = i + 1) begin
                    rom[i] = 16'b0000000000000000;
                end

                // D = -1 (white)
                rom[0]  = 16'b1110111010010000;

                // row 0
                rom[1]  = 16'b0100000000000000; // @16384
                rom[2]  = 16'b1110001100001000; // M=D

                // row 1
                rom[3]  = 16'b0100000000100000; // @16416
                rom[4]  = 16'b1110001100001000;

                // row 2
                rom[5]  = 16'b0100000001000000; // @16448
                rom[6]  = 16'b1110001100001000;

                // row 3
                rom[7]  = 16'b0100000001100000; // @16480
                rom[8]  = 16'b1110001100001000;

                // row 4
                rom[9]  = 16'b0100000010000000; // @16512
                rom[10] = 16'b1110001100001000;

                // row 5
                rom[11] = 16'b0100000010100000; // @16544
                rom[12] = 16'b1110001100001000;

                // row 6
                rom[13] = 16'b0100000011000000; // @16576
                rom[14] = 16'b1110001100001000;

                // row 7
                rom[15] = 16'b0100000011100000; // @16608
                rom[16] = 16'b1110001100001000;

                // row 8
                rom[17] = 16'b0100000100000000; // @16640
                rom[18] = 16'b1110001100001000;

                // row 9
                rom[19] = 16'b0100000100100000; // @16672
                rom[20] = 16'b1110001100001000;

                // row 10
                rom[21] = 16'b0100000101000000; // @16704
                rom[22] = 16'b1110001100001000;

                // row 11
                rom[23] = 16'b0100000101100000; // @16736
                rom[24] = 16'b1110001100001000;

                // row 12
                rom[25] = 16'b0100000110000000; // @16768
                rom[26] = 16'b1110001100001000;

                // row 13
                rom[27] = 16'b0100000110100000; // @16800
                rom[28] = 16'b1110001100001000;

                // row 14
                rom[29] = 16'b0100000111000000; // @16832
                rom[30] = 16'b1110001100001000;

                // row 15
                rom[31] = 16'b0100000111100000; // @16864
                rom[32] = 16'b1110001100001000;

                // loop
                rom[33] = 16'b0000000000100001; // @33
                rom[34] = 16'b1110101010000111; // 0;JMP
            end
        end
    endgenerate

    always @(posedge clk) begin
        instruction <= rom[nextPC];
    end

endmodule