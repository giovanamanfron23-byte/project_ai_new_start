`timescale 1ns / 1ps

module instruction_memory(
    input  wire [31:0] address,
    output reg  [31:0] instruction
);

    reg [31:0] memory [0:255];

    initial begin
        // addi R1 = R0 + 1  → opcode=0111, rs1=00000, rs2=x, rd=00001, imm=0000000000001
        memory[0] = {4'b0111, 5'b00000, 5'b00000, 5'b00001, 13'b0000000000001};

        // addi R2 = R0 + 2
        memory[1] = {4'b0111, 5'b00000, 5'b00000, 5'b00010, 13'b0000000000010};

        // addi R3 = R0 + 3
        memory[2] = {4'b0111, 5'b00000, 5'b00000, 5'b00011, 13'b0000000000011};

        // addi W1 = R0 + 4 → let's use R4
        memory[3] = {4'b0111, 5'b00000, 5'b00000, 5'b00100, 13'b0000000000100};

        // addi W2 = R0 + 5 → R5
        memory[4] = {4'b0111, 5'b00000, 5'b00000, 5'b00101, 13'b0000000000101};

        // addi W3 = R0 + 6 → R6
        memory[5] = {4'b0111, 5'b00000, 5'b00000, 5'b00110, 13'b0000000000110};

        // R7 = R1 * W1
        memory[6] = {4'b0010, 5'b00001, 5'b00100, 5'b00111, 13'b0000000000000};

        // R8 = R2 * W2
        memory[7] = {4'b0010, 5'b00010, 5'b00101, 5'b01000, 13'b0000000000000};

        // R9 = R3 * W3
        memory[8] = {4'b0010, 5'b00011, 5'b00110, 5'b01001, 13'b0000000000000};

        // R10 = R7 + R8
        memory[9]  = {4'b0000, 5'b00111, 5'b01000, 5'b01010, 13'b0000000000000};

        // R11 = R10 + R9
        memory[10] = {4'b0000, 5'b01010, 5'b01001, 5'b01011, 13'b0000000000000};
    end

    always @(*) begin
        instruction = memory[address[9:2]]; // word addressing (address / 4)
    end

endmodule
