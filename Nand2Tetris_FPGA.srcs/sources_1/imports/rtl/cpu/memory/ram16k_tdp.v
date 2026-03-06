module ram16k_tdp(
              //--port 1--
              input clk,
              input [14:0] address,
              output wire [15:0] out,
              input [15:0] in_value,
              input wire load,
              //--port 2--
              input second_clk,
              input [14:0] second_address,
              output wire [15:0] second_out,
              input [15:0] second_in_value,
              input wire second_load        
              
              );

    parameter n = 15;
    reg [15:0] reg_array [(2**n)-1:0];

    reg[15:0] data;
    reg[15:0] second_data;

    assign out          = data;
    assign second_out   = second_data;

    always @(posedge(clk)) begin
        data <= reg_array[address];
        if (load) begin
            reg_array[address] <= in_value;
        end
    end

   
    always @(posedge(second_clk)) begin
        second_data <= reg_array[second_address];
        if (second_load) begin
            reg_array[second_address] <= second_in_value;
        end
    end


endmodule
