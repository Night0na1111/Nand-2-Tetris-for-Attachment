module alu(
    output [15:0] out,
    output wire   zr,  //Output if zero.
    output wire   ng,  //Output if negative.

    input [15:0] x,
    input [15:0] y,
    input wire   zx, nx, zy, ny, f, no
);
////////////////////////////////////////////////
    reg signed [15:0] result;
    reg zero_flag;
    reg negative_flag;

    reg [15:0]        x_actual;
    reg [15:0]        y_actual;
    reg [15:0]        and_result;
    reg signed [15:0] sum_result;

//Despite using reg, this ALU is entirely combinational.
//Reg will only be non-blocking when you use it in a clocked situation.
//But in below, we use it in always@(*), this is a combinational case.

////////////////////////////////////////////////
//There is specific order to zx, nx, zy, ny. Consult the book.
//
    always @(*) begin
        x_actual = zx ? 16'd0 : x;                   //If zx is true, use the left one, else the right one.
        x_actual = nx ? ~x_actual : x_actual;

        y_actual = zy ? 16'd0 : y;
        y_actual = ny ? ~y_actual : y_actual;

        and_result = x_actual & y_actual;
        sum_result = x_actual + y_actual;

        result = f ? sum_result : and_result;
        result = no ? ~result : result;

        zero_flag     = (result == 16'd0);          //Compare result to zero, return 1 if passed.

        // All our data operate on two's complement, that is the first bit is always signed.
        negative_flag = result[15];
    end

    assign out = result;
    assign zr  = zero_flag;
    assign ng  = negative_flag;

endmodule