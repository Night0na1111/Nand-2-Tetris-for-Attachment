`timescale 1ns/1ps
//26/3/19 Verfied Logic.  Ran 40 line of commands and they all show promising result.
//But timing may be a bit iffy, depending on how other components interact with it.
// `ifdef Xilinx
// `include "../memory/register/register.v"
// `include "../memory/program_counter/program_counter.v"
// `include "../arithmetic/alu/alu.v"
// `else
// original
// `include "../../memory/register/register.v"
// `include "../../memory/program_counter/program_counter.v"
// `include "../../arithmetic/alu/alu.v"
// `endif

module cpu(input clk,
           input[15:0] inM,
           input[15:0] instruction,
           input reset,
           
           output[15:0] outM,
           output writeM,
           output[14:0] addressM,
           output[15:0] newPC);


 /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Program Counter
    wire[15:0] pc_value;
    wire[15:0] pc_in;
    
    wire pc_load;
    wire pc_increment;
    program_counter pc(pc_value, clk, pc_in, pc_load, reset, pc_increment);

    assign newPC = pc_value;
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Registers.
    wire[15:0] reg_a_value;
    wire[15:0] reg_a_in_value;
    wire reg_a_load;
    register register_a(reg_a_value, clk, reg_a_in_value, reg_a_load,reset);

    wire[15:0] reg_d_value;
    wire[15:0] reg_d_in_value;
    wire reg_d_load;
    register register_d(reg_d_value, clk, reg_d_in_value, reg_d_load,reset);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   ALU Lines
    wire[15:0] alu_output;
    wire zr_status, ng_status;
    wire[15:0] alu_x;
    wire[15:0] alu_y;
    wire zx_alu, nx_alu, zy_alu, ny_alu;
    wire f_alu, no_alu;
    alu alu_unit(alu_output, zr_status, ng_status, alu_x, alu_y,
                 zx_alu, nx_alu, zy_alu, ny_alu, f_alu, no_alu);
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // ALU outM  -> Memouy Output
    assign outM = alu_output;

    // Connect C1~C6 to ALU
    assign {zx_alu, nx_alu, zy_alu, ny_alu, f_alu, no_alu} = instruction[11:6];

    // ALU have 2 input, alu_x by design, ALWAYS take input from D.
    assign alu_x = reg_d_value;

    // This d_in_value is a place holder, not all alu_output goes into this register.
    //There is logic down below to decide if d_value <- d_in_value.
    assign reg_d_in_value = alu_output;

    // Memory address is always given by A register value. However, in our case
    // memory loads are 1-cycle delayed. In order to cope with this and still
    // handle dereferencing memory immediately after loading a value into the
    // A-register, we take the incoming value into the register as the address.
    
    //reg A value is immediate from A_register,  if A instruction, use reg_a_in_Value to skip waiting for A register to update.
    assign addressM = instruction[15] ? reg_a_value[14:0] : reg_a_in_value[14:0];
    
    // OUTPUT CONTROL SIGNALS
    assign reg_a_load = !instruction[15] || (instruction[15] && instruction[5]); // reg_a_load is a control signal, 1 or 0. Triggers when is A instruction, or when C instruction calls for it.
    assign reg_d_load = instruction[15] && instruction[4];  //Control signal too, Olny when C instruction calls for it.
    assign writeM = instruction[15] && instruction[3];      //If  C instruction, and it calls for it.

    // A is always wired to PC, just waiting for a load.
    assign pc_in = reg_a_value;

    // Register-A input is either taken as an immediate from the instruction or the output of the ALU.
    wire[15:0] instruction_immediate;
    assign instruction_immediate[15] = 0;
    assign instruction_immediate[14:0] = instruction[14:0];
    assign reg_a_in_value = instruction[15] ? alu_output : instruction_immediate; 
    //This line is basically the next A value, before it goes into the register. If A instruction, take from instruction_immediate.
    
    // This one is the second input for ALU.  Choose between memory value or A-register value depending on bit 12 in the instruction.
    assign alu_y = instruction[12] ? inM : reg_a_value;
    
    /// Every cycle, increment PC, and see if we should jump.
    assign pc_increment = 1'b1;  // Always increment unless jumping

    assign pc_load = !reset && instruction[15] && (
        (instruction[2:0] == 3'b001 && (!ng_status && !zr_status)) ||  // JGT
        (instruction[2:0] == 3'b010 && zr_status) ||                   // JEQ
        (instruction[2:0] == 3'b011 && (zr_status || !ng_status)) ||   // JGE
        (instruction[2:0] == 3'b100 && ng_status) ||                   // JLT
        (instruction[2:0] == 3'b101 && !zr_status) ||                  // JNE
        (instruction[2:0] == 3'b110 && (ng_status || zr_status)) ||    // JLE
        (instruction[2:0] == 3'b111)                                   // JMP (unconditional)
    );
     /******
     always @(*) begin   
       pc_increment = 1'b1;
       
       // JUMP Decoding, bottom 3 bits.
        case (instruction[2:0])
            // No jump.
            3'b000: pc_load <= 0;
            // ALU out > 0
            3'b001: pc_load = (!ng_status && !zr_status) && instruction[15];
            // ALU out = 0
            3'b010: pc_load = (zr_status) && instruction[15];
            // ALU out >= 0
            3'b011: pc_load = (zr_status || !ng_status) && instruction[15];
            // ALU out < 0
            3'b100: pc_load = (ng_status) && instruction[15];
            // ALU out != 0
            3'b101: pc_load = (!zr_status) && instruction[15];
            // ALU out <= 0
            3'b110: pc_load = (ng_status || zr_status) && instruction[15];
            // Unconditional jump.
            3'b111: pc_load = (1) && instruction[15];
        endcase
       end 
    end
    ****/
endmodule