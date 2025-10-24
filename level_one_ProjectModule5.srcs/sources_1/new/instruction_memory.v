`timescale 1ns / 1ps

module instruction_memory(
    input  wire [31:0] address,
    output reg  [31:0] instruction
);

    reg [31:0] memory [0:255];

    initial begin
        // addi R1 = R0 + 1
        memory[0] = {4'b0111, 5'b00000, 5'b00000, 5'b00001, 13'd1};

        // addi R2 = R0 + 2
        memory[1] = {4'b0111, 5'b00000, 5'b00000, 5'b00010, 13'd2};

        // add R3 = R1 + R2
        memory[2] = {4'b0000, 5'b00001, 5'b00010, 5'b00011, 13'd0};

        // sub R4 = R3 - R1
        memory[3] = {4'b0001, 5'b00011, 5'b00001, 5'b00100, 13'd0};

        // mul R5 = R2 * R4
        memory[4] = {4'b0010, 5'b00010, 5'b00100, 5'b00101, 13'd0};

        // sll R6 = R1 << 2
        memory[5] = {4'b1110, 5'b00001, 5'b00000, 5'b00110, 13'd2};

        // beq if R1 == R1, branch by +4
        memory[6] = {4'b1100, 5'b00001, 5'b00001, 5'b00000, 13'd4};

        // bne if R1 != R2, branch by +4
        memory[7] = {4'b1101, 5'b00001, 5'b00010, 5'b00000, 13'd4};

        // lw R7 = MEM[R2 + 0]
        memory[8] = {4'b1010, 5'b00010, 5'b00000, 5'b00111, 13'd0};

        // sw MEM[R2 + 4] = R3
        memory[9] = {4'b1011, 5'b00010, 5'b00011, 5'b00000, 13'd4};
    end

    always @(*) begin
        instruction = memory[address[9:2]];  // word addressing
    end

endmodule
