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
    reg [31:0] memory [0:10000];

    initial 
    begin
        $readmemh("mnist_image.mem", memory);
        $readmemh("best_model_weights.mem", memory, 784);
    end
    // Asynchronous read
//    always @(*) begin
//        if (memory_read)
//            read_data = memory[address[9:2] & 8'd255];  // word-aligned, safe masking
//        else
//            read_data = 32'b0;
//    end

    // Synchronous write
//    always @(posedge clk) begin
//        if (memory_write)
//            memory[address[9:2] & 8'd255] <= write_data;
//    end
    // Synchronous write
    always @(posedge clk) begin
        if (memory_write)
            memory[address[15:2]] <= write_data;
        read_data <= memory[address[15:2]];
    end

endmodule
