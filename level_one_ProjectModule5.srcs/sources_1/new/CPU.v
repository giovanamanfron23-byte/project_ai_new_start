`timescale 1ns / 1ps

module CPU(
    input wire clk,
    input wire reset,
    input wire rxd,
    output wire txd
);

    // Program Counter
    reg [31:0] PC;
    wire [31:0] next_pc;
    wire [31:0] instruction;

    // Instruction Fields (matching your encoding)
    wire [3:0] opcode    = instruction[31:28];
    wire [4:0] rs1       = instruction[27:23];
    wire [4:0] rs2       = instruction[22:18];
    wire [4:0] rd        = instruction[17:13];
    wire [12:0] imm      = instruction[12:0];

    // Sign-extend immediate (13-bit → 32-bit)
    wire [31:0] imm_ext  = {{19{imm[12]}}, imm};

    // Control Signals
    wire register_write;
    wire ALUSrc;
    wire [2:0] ALUopcode;
    wire memory_read;
    wire memory_write;
    wire memory_to_register;
    wire branch;

    // Data wires
    wire [31:0] read_data1, read_data2;
    wire [31:0] ALU_result;
    wire [31:0] read_data_memory;
    wire [31:0] write_data;
    wire zero_flag;

    // Instruction Memory
    instruction_memory imem (
        .address(PC),
        .instruction(instruction)
    );

    // Control Unit
    CU control_unit (
        .opcode(opcode),
        .register_write(register_write),
        .ALUSrc(ALUSrc),
        .ALUopcode(ALUopcode),
        .memory_read(memory_read),
        .memory_write(memory_write),
        .memory_to_register(memory_to_register),
        .branch(branch)
    );

    // Register File
    RF regfile (
        .clk(clk),
        .reset(reset),
        .register_write(register_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // ALU input mux
    wire [31:0] ALU_input_B = (ALUSrc) ? imm_ext : read_data2;

    // ALU
    ALU alu (
        .A(read_data1),
        .B(ALU_input_B),
        .ALUopcode(ALUopcode),
        .result(ALU_result),
        .zero(zero_flag)
    );

    // Data Memory
    DM data_memory (
        .clk(clk),
        .memory_write(memory_write),
        .memory_read(memory_read),
        .address(ALU_result),
        .write_data(read_data2),
        .read_data(read_data_memory)
    );
    
    ComU #(
    .FREQ(100_000_000), 
    .BAUD(625_000)
    ) Communication_Unit(
        .clk(clk),
        .rxd(rxd),
        .txd(txd)
    );

    // Write-back MUX
    assign write_data = (memory_to_register) ? read_data_memory : ALU_result;

    // Next PC logic (normal increment or branch)
    wire [31:0] PC_plus4 = PC + 32'd4;
    wire [31:0] branch_target = PC + (imm_ext << 2);
    assign next_pc = (branch && zero_flag) ? branch_target : PC_plus4;

    // Program Counter update
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 0;
        else
            PC <= next_pc;
    end

endmodule

