`timescale 1ns/1ps

module cpu(
    input clk,
    input cpu_enable,          
    input [15:0] inM,
    input [15:0] instruction,
    input reset,

    output [15:0] outM,
    output writeM,
    output [14:0] addressM,
    output [15:0] newPC
);
    //////////////////////////////////////////////////////////
    // Program Counter
    wire [15:0] pc_value;
    wire [15:0] pc_in;
    wire pc_load;
    wire pc_increment;

    program_counter pc(
        .out(pc_value),
        .clk(clk),
        .cpu_enable(cpu_enable),   
        .in_value(pc_in),
        .load(pc_load),
        .reset(reset),
        .increment(pc_increment)
    );

    assign newPC = pc_value;

    ///////////////////////////////////////////////////////
    // Registers
    wire [15:0] reg_a_value;
    wire [15:0] reg_a_in_value;
    wire        reg_a_load;

    register register_a(
        .out(reg_a_value),
        .clk(clk),
        .cpu_enable(cpu_enable),  
        .in_value(reg_a_in_value),
        .load(reg_a_load),
        .reset(reset)
    );


    wire [15:0] reg_d_value;
    wire [15:0] reg_d_in_value;
    wire        reg_d_load;

    register register_d(
        .out(reg_d_value),
        .clk(clk),
        .cpu_enable(cpu_enable),  
        .in_value(reg_d_in_value),
        .load(reg_d_load),
        .reset(reset)
    );
    ////////////////////////////////////////////////////////////
    // ALU
    wire [15:0] alu_output;
    wire        zr_status, ng_status;
    wire [15:0] alu_x, alu_y;
    wire        zx_alu, nx_alu, zy_alu, ny_alu, f_alu, no_alu;

    alu alu_unit(
        .out(alu_output),
        .zr(zr_status),
        .ng(ng_status),
        .x(alu_x),
        .y(alu_y),
        .zx(zx_alu),
        .nx(nx_alu),
        .zy(zy_alu),
        .ny(ny_alu),
        .f(f_alu),
        .no(no_alu)
    );

    /////////////////////////////////////////////////////////////////////////
    // Datapath Wiring

    // ALU output to outM (CPU Output)
    assign outM = alu_output;

    // ALU control signal. (i xx a cccccc ddd jjj)
    // If C-instructions, use [11 to 6] for control signal. If A-instruction, use dummy.
    assign {zx_alu, nx_alu, zy_alu, ny_alu, f_alu, no_alu} =
        instruction[15] ? instruction[11:6] : 6'b101010;

    // ALU X input. this input is wired to D register
    assign alu_x = reg_d_value;

    // ALU Y input. This one have 2 possibility. From in inM or A register. Depends on what "a(bit 12)" is .
    assign alu_y = instruction[12] ? inM : reg_a_value;



    // D register input is ALU output
    assign reg_d_in_value = alu_output;

    // A register input MUX , 2 possibility too. From ALU or A-instruction.
    wire [15:0] instruction_immediate;
    assign instruction_immediate = {1'b0, instruction[14:0]}; //if the instruction is A-instruction, this would be it's input. (By the way this is proboably redundant.)
    assign reg_a_in_value = instruction[15] ? alu_output : instruction_immediate; //if it is C-instruction, Load from Alu-output.

    // addressM is always reg_a_value.
    assign addressM = reg_a_value[14:0];

    // Register load control (1bit signal). Bit  543 is load ADM.
    assign reg_a_load = !instruction[15] || (instruction[15] && instruction[5]); //If A-instruction,load it, no question asked. If C-instruction, load only if bit 5 demands it.
    assign reg_d_load =  instruction[15] && instruction[4]; //A-instruction by concept never touches this register. So only if C-inst, and bit 4 demands it.

    // writeM , Same as above, write when C-inst, bit 3 demands. This time Cpu enable to wait for timing.
    assign writeM = cpu_enable && instruction[15] && instruction[3]; 



    // PC input is tied to a register output.
    assign pc_in = reg_a_value;

    // PC plus 1 signal. In PCs code this is judged last, so fine to force high as this is the default behavior if no other signal shows up.
    assign pc_increment = 1'b1;



    // Jump instruction [2,1,0][<,==,>]
    // I can still recall the whole reason things were wrote this way was to try fit 1 cycle timeframe.
    // So basically, this tells if PC should "load" or jump. We compare all possible combinations of jumping and flag a Yes if one matched.
    assign pc_load = instruction[15] && (
        (instruction[2:0] == 3'b001 && (!ng_status && !zr_status)) ||  // JGT (ALU out >  0)
        (instruction[2:0] == 3'b010 &&   zr_status               ) ||  // JEQ (ALU out =  0)
        (instruction[2:0] == 3'b011 &&  (zr_status || !ng_status)) ||  // JGE (ALU out >= 0)
        (instruction[2:0] == 3'b100 &&   ng_status               ) ||  // JLT (ALU out <  0)
        (instruction[2:0] == 3'b101 &&  !zr_status               ) ||  // JNE (ALU out != 0)
        (instruction[2:0] == 3'b110 &&  (ng_status || zr_status) ) ||  // JLE (ALU out <= 0)
        (instruction[2:0] == 3'b111)                                   // JMP (ALU out >=< 0)
    );

endmodule