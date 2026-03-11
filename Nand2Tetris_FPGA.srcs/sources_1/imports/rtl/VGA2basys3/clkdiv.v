module clkdiv(
input wire mclk,
input wire clr,
output wire clk25
);

reg [1:0] q;

always @(posedge mclk or posedge clr)
begin
if(clr)
q <= 0;
else
q <= q + 1;
end

assign clk25 = q[1];

endmodule