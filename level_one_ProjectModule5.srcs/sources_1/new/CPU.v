`timescale 1ns / 1ps

module CPU(
    input clk,
    input reset
);

    // Program counter register
    reg [31:0] PC;

    // Wires
    wire [31:0] next_pc;
    wire [31:0] instruction;

    // Fetch instruction
    instruction_memory imem(
        .address(PC),
        .instruction(instruction)
    );

    // Instruction fields (adjust indices to match your encoding if needed)
    wire [3:0] opcode    = instruction[31:28];
    wire [4:0] rs1       = instruction[27:23];
    wire [4:0] rs2       = instruction[22:18];
    wire [4:0] rd        = instruction[17:13];
    wire [12:0] immediate= instruction[12:0];

    // Register file
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_data;
    wire register_write;

    RF register_file (
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

    // Control signals
    wire memory_read, memory_write, branch, ALUSrc, memory_to_register;
    wire [2:0] ALUopcode;

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

    // Immediate sign-extend (13 -> 32)
    wire [31:0] imm_ext = {{19{immediate[12]}}, immediate};

    // ALU input mux
    wire [31:0] ALU_in2 = (ALUSrc) ? imm_ext : read_data2;

    // ALU
    wire [31:0] ALU_result;
    wire zero_flag;

    ALU alu (
        .A(read_data1),
        .B(ALU_in2),
        .ALUopcode(ALUopcode),
        .result(ALU_result),
        .zero(zero_flag)
    );
    
    // Data memory
    wire [31:0] memory_read_data;

    DM data_mem (
        .clk(clk),
        .memory_write(memory_write),
        .memory_read(memory_read),
        .address(ALU_result),
        .write_data(read_data2),
        .read_data(memory_read_data)
    );

    // Writeback mux
    assign write_data = (memory_to_register) ? memory_read_data : ALU_result;

    // PC combinational next (use PC module to compute next_pc)
    PC program_control (
        .PC(PC),
        .immediate(imm_ext[12:0] /* caution: PC module expects 13-bit? */),
        .branch(branch),
        .zero_flag(zero_flag),
        .next_pc(next_pc)
    );

    // Register PC
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else
            PC <= next_pc;
    end

endmodule