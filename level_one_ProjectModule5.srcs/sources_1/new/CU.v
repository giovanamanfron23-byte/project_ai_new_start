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
    register_write = 0; 
    ALUSrc = 0; 
    ALUopcode = 3'b000; 
    memory_read = 0; 
    memory_write =0; 
    memory_to_register = 0; 
    branch =0; 
    
case(opcode)
    4'b0000: begin                  //adding 
        register_write = 1;     
        ALUSrc = 0;
        ALUopcode = 3'b000;
    end                                 
     4'b0001: begin                 //subtracting 
        register_write = 1;     
        ALUSrc = 0;
        ALUopcode = 3'b001;
    end
     4'b0010: begin                 //multiplying 
        register_write = 1;     
        ALUSrc = 0;
        ALUopcode = 3'b010;
    end
    4'b0111: begin                     //addi 
        register_write = 1;
        ALUSrc = 1;
        ALUopcode = 3'b000;
    end
    4'b1010: begin 
        register_write = 1;                    //load word LW 
        ALUSrc = 1; 
        ALUopcode = 3'b000; 
        memory_read = 1; 
        memory_to_register = 1; 
    end 
    4'b1011: begin                              //store word SW 
        ALUSrc = 1; 
        ALUopcode = 3'b000;
        memory_write = 1;
    end 
    4'b1101: begin                          //branch 
        ALUSrc = 0; 
        ALUopcode = 3'b001; 
        branch = 1; 
    end 
endcase 

end 
endmodule