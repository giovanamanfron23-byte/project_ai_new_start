`timescale 1ns / 1ps

module ALU(
    input wire [31:0] A,
    input wire [31:0] B,
    input wire [2:0] ALUopcode,
    output reg [31:0] result,
    output wire zero
);

always @(*) begin
    case(ALUopcode)
        3'b000: result = A + B;
        3'b001: result = A - B;
        3'b010: result = A * B;
        3'b100: result = A | B;
        3'b101: result = A ^ B;
        3'b110: result = (A < B) ? 32'b1 : 32'b0;
        default: result = 32'b0;
    endcase
end

assign zero = (result == 32'b0);

endmodule