`timescale 1ns / 1ps

module DM(
    input  wire clk,
    input  wire memory_write,
    input  wire memory_read,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] memory [0:255];

    assign read_data = (memory_read) ? memory[address[9:2]] : 32'b0;

    always @(posedge clk) begin
        if (memory_write)
            memory[address[9:2]] <= write_data;
    end

endmodule