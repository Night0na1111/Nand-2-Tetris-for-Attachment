// 26/3/16 Verfied Logic
module program_counter(
output [15:0] out,

input clk,
input [15:0] in_value,
input wire load,
input wire reset,
input wire increment
);

reg [15:0] counter;

always @(posedge clk) begin

if (reset)
counter <= 16'b0;

else if (load)
counter <= in_value;

else if (increment)
counter <= counter + 1;

end

assign out = counter;

endmodule
