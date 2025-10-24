`timescale 1ns / 1ps

module CU(
    input wire [3:0] opcode, 
    output reg register_write, 
    output reg ALUSrc, 
    output reg [2:0] ALUopcode, 
    output reg memory_read, 
    output reg memory_write, 
    output reg memory_to_register, 
    output reg branch
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
    
    case (opcode)
        4'b0000: begin              // ADD
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b000;     // ALU adds
        end                                 
        4'b0001: begin              // SUB
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b001;     // ALU subtracts
        end
        4'b0010: begin              // MUL
            register_write = 1;     
            ALUSrc = 0;
            ALUopcode = 3'b010;     // ALU multiplies
        end
        4'b0111: begin              // ADDI (immediate add)
            register_write = 1;
            ALUSrc = 1;
            ALUopcode = 3'b000;     // ALU adds
        end
        4'b1010: begin              // LW (load word)
            register_write = 1;
            ALUSrc = 1; 
            ALUopcode = 3'b000;     // address = base + offset
            memory_read = 1; 
            memory_to_register = 1; // load from memory to register
        end 
        4'b1011: begin              // SW (store word)
            ALUSrc = 1; 
            ALUopcode = 3'b000;     // address = base + offset
            memory_write = 1;
        end 
        4'b1100: begin              // BEQ (branch if equal)
            branch = 1;
            ALUopcode = 3'b001;     // use subtraction to compare
        end
        4'b1101: begin              // BNE (branch if not equal)
            branch = 1;
            ALUopcode = 3'b001;     // same compare (check Zero flag outside)
        end
        4'b1110: begin              // SLL (shift left logical)
            register_write = 1;
            ALUopcode = 3'b111;     // shift operation
        end
        default: begin
            // all control signals remain at default (no-op)
        end
    endcase
end 

endmodule
