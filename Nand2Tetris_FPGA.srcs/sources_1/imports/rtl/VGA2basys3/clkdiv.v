module clkdiv(
input wire mclk,
input wire clr,

output wire clk25
);

reg [1:0] q;  //1 Extra register is divide by 2, so 2 Register is divide by 4.
////////////////////////////////////// A simple Clock divider. Makes 100Mhz to 25Mhz.
always @(posedge mclk or posedge clr)
begin
    if(clr)
        q <= 0;
    else
        q <= q + 1;
end

assign clk25 = q[1];

endmodule