module register(output [15:0] out,
                input clk,
                input [15:0] in_value,
                input wire load,
                input wire reset);
    reg [15:0] data;

    always @(posedge(clk)) begin
        if (reset)
            data<=#1 16'h0000;
        else if (load) begin
            data <= #1 in_value;
        end
    end

    assign out = data;
endmodule