`timescale 1ns / 1ps

module CU(
    input wire [3:0] opcode, 
    output reg register_write, 
    output reg ALUSrc, 
    output reg [2:0] ALUopcode, 
    output reg memory_read, 
    output reg memory_write, 
    output reg memory_to_register, 
    output reg branch,
    output reg branch_ne  // NEW SIGNAL for BNE
);

always @(*) begin 
    // Default values
    register_write = 0; 
    ALUSrc = 0; 
    ALUopcode = 3'b000; 
    memory_read = 0; 
    memory_write = 0; 
    memory_to_register = 0; 
    branch = 0; 
    branch_ne = 0; // default

    case (opcode)
        4'b0000: begin              // ADD
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b000;
        end
        4'b0001: begin              // SUB
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b001;
        end
        4'b0010: begin              // MUL
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b010;
        end
        4'b0111: begin              // ADDI
            register_write = 1;
            ALUSrc = 1;
            ALUopcode = 3'b000;
        end
        4'b1010: begin              // LW
            register_write = 1;
            ALUSrc = 1; 
            ALUopcode = 3'b000;
            memory_read = 1; 
            memory_to_register = 1;
        end 
        4'b1011: begin              // SW
            ALUSrc = 1; 
            ALUopcode = 3'b000;
            memory_write = 1;
        end 
        4'b1100: begin              // BEQ
            branch = 1;
            ALUopcode = 3'b001; // compare (A - B)
        end
        4'b1101: begin              // BNE
            branch = 1;
            branch_ne = 1;          // NEW
            ALUopcode = 3'b001;
        end
        4'b1110: begin              // SLL
            register_write = 1;
            ALUopcode = 3'b111;
        end
        default: begin
            // no-op
        end
    endcase
end 

endmodule
