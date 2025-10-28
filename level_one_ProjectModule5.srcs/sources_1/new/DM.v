`timescale 1ns / 1ps

module DM(
    input  wire clk,
    input  wire memory_write,
    input  wire memory_read,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    // 256 x 32-bit memory
    reg [31:0] memory [0:8191];

    // Preload from external memory file (synthesizable for FPGA)
    initial begin
        $readmemb("data_folder/best_model.h5", memory);
    end

    // Asynchronous read
    always @(*) begin
        if (memory_read)
            read_data = memory[address[9:2] & 8'd255];
        else
            read_data = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (memory_write)
            memory[address[9:2] & 8'd255] <= write_data;
    end

endmodule