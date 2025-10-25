`timescale 1ns / 1ps

module instruction_memory(
    input  [31:0] address,
    output reg [31:0] instruction
);
    reg [31:0] memory [0:255];

/*generate
    initial begin
        // addi R1 = R0 + 1
        memory[0] = {4'b0111, 5'b00000, 5'b00000, 5'b00001, 13'd1};

        // addi R2 = R0 + 2
        memory[1] = {4'b0111, 5'b00000, 5'b00000, 5'b00010, 13'd2};

        // add R3 = R1 + R2
        memory[2] = {4'b0000, 5'b00001, 5'b00010, 5'b00011, 13'd0};

        // sub R4 = R2 - R1
        memory[3] = {4'b0001, 5'b00010, 5'b00001, 5'b00100, 13'd0};

        // mul R5 = R1 * R2
        memory[4] = {4'b0010, 5'b00001, 5'b00010, 5'b00101, 13'd0};

        // addi R6 = R0 + 4
        memory[5] = {4'b0111, 5'b00000, 5'b00000, 5'b00110, 13'd4};

        // BEQ: if R1 == R1, branch +4 → jump to memory[10]
        memory[6] = {4'b1100, 5'b00001, 5'b00001, 5'b00000, 13'd4};

        // BNE (won't be reached due to branch, but kept for completeness)
        memory[7] = {4'b1101, 5'b00001, 5'b00010, 5'b00000, 13'd4};

        // Padding instructions (optional)
        memory[8] = 32'h00000000;
        memory[9] = 32'h00000000;

        // === Branch target starts here (PC = 40) ===

        // LW R7 = MEM[R2 + 0]
        memory[10] = {4'b1010, 5'b00010, 5'b00000, 5'b00111, 13'd0};

        // SW MEM[R2 + 4] = R3
        memory[11] = {4'b1011, 5'b00010, 5'b00011, 5'b00000, 13'd4};

        // NOP / HALT (safe stop)
        memory[12] = 32'h00000000;
    end
endgenerate */

    always @(*) begin
        instruction = memory[address[9:2]]; // word addressing
    end
endmodule