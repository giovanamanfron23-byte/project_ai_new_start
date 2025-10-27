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
    output reg branch_ne
);

always @(*) begin 
    // Default values (safe)
    register_write = 0; 
    ALUSrc = 0; 
    ALUopcode = 3'b000; 
    memory_read = 0; 
    memory_write = 0; 
    memory_to_register = 0; 
    branch = 0; 
    branch_ne = 0; 

    case (opcode)

        4'b0000: begin              // ADD (R-type)
            register_write = 1;     
            ALUSrc = 0;             // operand2 = register
            ALUopcode = 3'b000;     // ALU add
        end
        4'b0001: begin              // SUB (R-type)
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b001;     // ALU subtract
        end
        4'b0010: begin              // MUL (R-type)
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b010;     // ALU multiply
        end
        4'b0110: begin              // SLT (R-type)
            register_write = 1;
            ALUSrc = 0;
            ALUopcode = 3'b011;     // ALU set-less-than
        end
        4'b1110: begin              // SLL (R-type)
            register_write = 1;
            ALUopcode = 3'b111;     // ALU shift-left-logical
        end


        4'b0111: begin              // ADDI (I-type)
            register_write = 1;
            ALUSrc = 1;             // operand2 = immediate
            ALUopcode = 3'b000;     // ADD operation
        end
        4'b1010: begin              // LW (I-type)
            register_write = 1;
            ALUSrc = 1;             // address = base + imm
            ALUopcode = 3'b000;     // ADD for address calc
            memory_read = 1; 
            memory_to_register = 1; // load data to register
        end


        4'b1011: begin              // SW (S-type)
            ALUSrc = 1;             // address = base + imm
            ALUopcode = 3'b000;     // ADD for address calc
            memory_write = 1;
        end 


        4'b1100: begin              // BEQ (B-type)
            branch = 1;
            ALUopcode = 3'b001;     // subtract to compare
        end
        4'b1101: begin              // BNE (B-type)
            branch = 1;
            branch_ne = 1;          // branch if not equal
            ALUopcode = 3'b001;     // subtract to compare
        end

        default: begin
            
        end
    endcase
end 

endmodule