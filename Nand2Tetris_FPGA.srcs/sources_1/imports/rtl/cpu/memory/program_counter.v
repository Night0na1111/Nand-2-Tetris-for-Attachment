module program_counter(
    input         clk,
    input         cpu_enable, 
    input  [15:0] in_value,
    input  wire   load,
    input  wire   reset,
    input  wire   increment,

    output [15:0] out
);
    reg [15:0] counter;

////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset)
            counter <= 16'b0;
        else if (cpu_enable) begin 

            if (load)
                counter <= in_value;
            else if (increment)
                counter <= counter + 1;

        end
    end
////////////////////////////////////////////////
    assign out = counter;

endmodule