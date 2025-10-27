//`timescale 1ns / 1ps

//module instruction_memory(
//    input  [31:0] address,
//    output reg [31:0] instruction
//);
//    reg [31:0] memory [0:255];

///*generate
//    initial begin
//        // addi R1 = R0 + 1
//        memory[0] = {4'b0111, 5'b00000, 5'b00000, 5'b00001, 13'd1};

//        // addi R2 = R0 + 2
//        memory[1] = {4'b0111, 5'b00000, 5'b00000, 5'b00010, 13'd2};

//        // add R3 = R1 + R2
//        memory[2] = {4'b0000, 5'b00001, 5'b00010, 5'b00011, 13'd0};

//        // sub R4 = R2 - R1
//        memory[3] = {4'b0001, 5'b00010, 5'b00001, 5'b00100, 13'd0};

//        // mul R5 = R1 * R2
//        memory[4] = {4'b0010, 5'b00001, 5'b00010, 5'b00101, 13'd0};

//        // addi R6 = R0 + 4
//        memory[5] = {4'b0111, 5'b00000, 5'b00000, 5'b00110, 13'd4};

//        // BEQ: if R1 == R1, branch +4 → jump to memory[10]
//        memory[6] = {4'b1100, 5'b00001, 5'b00001, 5'b00000, 13'd4};

//        // BNE (won't be reached due to branch, but kept for completeness)
//        memory[7] = {4'b1101, 5'b00001, 5'b00010, 5'b00000, 13'd4};

//        // Padding instructions (optional)
//        memory[8] = 32'h00000000;
//        memory[9] = 32'h00000000;

//        // === Branch target starts here (PC = 40) ===

//        // LW R7 = MEM[R2 + 0]
//        memory[10] = {4'b1010, 5'b00010, 5'b00000, 5'b00111, 13'd0};

//        // SW MEM[R2 + 4] = R3
//        memory[11] = {4'b1011, 5'b00010, 5'b00011, 5'b00000, 13'd4};

//        // NOP / HALT (safe stop)
//        memory[12] = 32'h00000000;
//    end
//endgenerate */

//    always @(*) begin
//        instruction = memory[address[9:2]]; // word addressing
//    end
//endmodule


`timescale 1ns / 1ps
module instruction_memory(
    input  [31:0] address,
    output reg [31:0] instruction
);
    reg [31:0] memory [0:30];
    initial begin
//        memory[0] = {4'b1010, 5'd0, 5'd0, 5'd1, 13'd0}; // LW   $r1, 0($zero)
//        memory[1] = {4'b1010, 5'd0, 5'd0, 5'd2, 13'd784}; // LW   $r2, 784($zero)
//        memory[2] = {4'b0111, 5'd0, 5'd0, 5'd3, 13'd784}; // ADDI $r3, $zero, 784
//        memory[3] = {4'b0111, 5'd0, 5'd0, 5'd4, 13'd10}; // ADDI $r4, $zero, 10
//        memory[4] = {4'b0111, 5'd0, 5'd0, 5'd5, 13'd0}; // ADDI $r5, $zero, 0
//        memory[5] = {4'b0111, 5'd0, 5'd0, 5'd6, 13'd8191}; // ADDI $r6, $zero, -1
//        memory[6] = {4'b0111, 5'd0, 5'd0, 5'd7, 13'd0}; // ADDI $r7, $zero, 0
//        memory[7] = {4'b0111, 5'd2, 5'd0, 5'd8, 13'd0}; // ADDI $r8, $r2, 0
//        memory[8] = {4'b0111, 5'd0, 5'd0, 5'd15, 13'd0}; // ADDI $r15, $zero, 0
//        memory[9] = {4'b0111, 5'd0, 5'd0, 5'd9, 13'd0}; // ADDI $r9, $zero, 0
//        memory[10] = {4'b0111, 5'd1, 5'd0, 5'd10, 13'd0}; // ADDI $r10, $r1, 0
//        memory[11] = {4'b0111, 5'd8, 5'd0, 5'd11, 13'd0}; // ADDI $r11, $r8, 0
//        memory[12] = {4'b1010, 5'd10, 5'd0, 5'd12, 13'd0}; // LW  $r12, 0($r10)
//        memory[13] = {4'b1010, 5'd11, 5'd0, 5'd13, 13'd0}; // LW  $r13, 0($r11)
//        memory[14] = {4'b0010, 5'd12, 5'd13, 5'd14, 13'd0}; // MUL  $r14, $r12, $r13
//        memory[15] = {4'b0000, 5'd15, 5'd14, 5'd15, 13'd0}; // ADD  $r15, $r15, $r14
//        memory[16] = {4'b0111, 5'd10, 5'd0, 5'd10, 13'd1}; // ADDI $r10, $r10, 1
//        memory[17] = {4'b0111, 5'd11, 5'd0, 5'd11, 13'd1}; // ADDI $r11, $r11, 1
//        memory[18] = {4'b0111, 5'd9, 5'd0, 5'd9, 13'd1}; // ADDI $r9, $r9, 1
//        memory[19] = {4'b0110, 5'd9, 5'd3, 5'd16, 13'd0}; // SLT  $r16, $r9, $r3
//        memory[20] = {4'b1101, 5'd16, 5'd0, 5'd0, 13'd8183}; // BNE  $r16, $zero, dot_loop
//        memory[21] = {4'b1011, 5'd7, 5'd15, 5'd0, 13'd0}; // SW    $r15, 0($r7)
//        memory[22] = {4'b0110, 5'd5, 5'd15, 5'd16, 13'd0}; // SLT   $r16, $r5, $r15
//        memory[23] = {4'b1100, 5'd16, 5'd0, 5'd0, 13'd2}; // BEQ   $r16, $zero, no_update
//        memory[24] = {4'b0111, 5'd15, 5'd0, 5'd5, 13'd0}; // ADDI  $r5, $r15,0
//        memory[25] = {4'b0111, 5'd7, 5'd0, 5'd6, 13'd0}; // ADDI  $r6, $r7, 0
//        memory[26] = {4'b0111, 5'd7, 5'd0, 5'd7, 13'd1}; // ADDI $r7, $r7, 1
//        memory[27] = {4'b0000, 5'd8, 5'd3, 5'd8, 13'd0}; // ADD  $r8, $r8, $r3
//        memory[28] = {4'b0110, 5'd7, 5'd4, 5'd16, 13'd0}; // SLT  $r16, $r7, $r4
//        memory[29] = {4'b1101, 5'd16, 5'd0, 5'd0, 13'd8170}; // BNE  $r16, $zero, class_loop
//        memory[30] = {4'b1011, 5'd5, 5'd17, 5'd0, 13'd10}; // SW $r17, 10($r5)
        memory[0] = {4'b1010, 5'd0, 5'd0, 5'd1, 13'd0}; // LW   $r1, 0($zero)
        memory[1] = {4'b1010, 5'd0, 5'd0, 5'd2, 13'd784}; // LW   $r2, 784($zero)
        memory[2] = {4'b1011, 5'd0, 5'd1, 5'd0, 13'd784}; // SW   $r1, 784($zero)
        memory[3] = {4'b1011, 5'd0, 5'd2, 5'd0, 13'd0}; // SW   $r2, 0($zero)

    end
    always @(*) begin
        instruction = memory[address[9:2]]; // word addressing
    end
endmodule