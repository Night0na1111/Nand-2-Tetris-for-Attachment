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

    //=========================================================
    // Program Counter
    //=========================================================
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

    //=========================================================
    // Registers
    //=========================================================
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

    //=========================================================
    // ALU
    //=========================================================
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

    //=========================================================
    // Datapath Wiring
    //=========================================================

    // ALU 輸出 -> Memory 寫入資料
    assign outM = alu_output;

    // ALU 控制信號：A-instruction 時強制安全值（不影響執行）
    assign {zx_alu, nx_alu, zy_alu, ny_alu, f_alu, no_alu} =
        instruction[15] ? instruction[11:6] : 6'b101010;

    // ALU x: 永遠來自 D register
    assign alu_x = reg_d_value;

    // ALU y: bit12=1 -> inM，bit12=0 -> A register
    assign alu_y = instruction[12] ? inM : reg_a_value;

    // D register 輸入：ALU 輸出
    assign reg_d_in_value = alu_output;

    // A register 輸入：A-instruction 取立即數，C-instruction 取 ALU 輸出
    wire [15:0] instruction_immediate;
    assign instruction_immediate = {1'b0, instruction[14:0]};
    assign reg_a_in_value = instruction[15] ? alu_output : instruction_immediate;

    // ★ 修正：addressM 永遠用 reg_a_value（消除 timing loop）
    // 原本有 instruction[15] ? reg_a_value : reg_a_in_value 的旁路，
    // 造成組合邏輯回路（Vivado timing loop 錯誤）
    assign addressM = reg_a_value[14:0];

    // Register load 控制
    assign reg_a_load = !instruction[15] || (instruction[15] && instruction[5]);
    assign reg_d_load =  instruction[15] && instruction[4];

    // ★ 修正：writeM 加上 cpu_enable 閘控
    // 防止在非 enable 的 cycle 誤寫記憶體（Multiple Driver 錯誤根因之一）
    assign writeM = cpu_enable && instruction[15] && instruction[3];

    // PC 輸入：A register
    assign pc_in = reg_a_value;

    // PC 永遠自動遞增（除非 load 或 reset）
    assign pc_increment = 1'b1;

    // Jump 判斷
    assign pc_load = instruction[15] && (
        (instruction[2:0] == 3'b001 && (!ng_status && !zr_status)) ||  // JGT
        (instruction[2:0] == 3'b010 &&   zr_status               ) ||  // JEQ
        (instruction[2:0] == 3'b011 &&  (zr_status || !ng_status)) ||  // JGE
        (instruction[2:0] == 3'b100 &&   ng_status               ) ||  // JLT
        (instruction[2:0] == 3'b101 &&  !zr_status               ) ||  // JNE
        (instruction[2:0] == 3'b110 &&  (ng_status || zr_status) ) ||  // JLE
        (instruction[2:0] == 3'b111)                                    // JMP
    );

endmodule