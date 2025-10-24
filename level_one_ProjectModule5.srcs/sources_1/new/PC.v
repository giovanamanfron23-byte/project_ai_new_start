`timescale 1ns / 1ps

module PC(
    input  [31:0] PC,
    input  [31:0] immediate, 
    input  branch, 
    input  branch_ne,       // 1 for BNE, 0 for BEQ
    input  zero_flag,
    output reg  [31:0] next_pc
);

    wire [31:0] PC_plus4 = PC + 32'd4;
    wire [31:0] branch_target = PC + (immediate << 2);

    always @(*) begin
        if (branch && ((zero_flag && !branch_ne) || (!zero_flag && branch_ne)))
            next_pc = branch_target;
        else
            next_pc = PC_plus4;
    end

endmodule
