`timescale 1ns / 1ps

module DM(
    input  wire clk,
    input  wire memory_write,
    input  wire memory_read,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    output wire  [31:0] read_data
);
    reg [31:0] data_int;
    // 256 x 32-bit memory
    reg [31:0] memory [0:10000];

    initial 
    begin
        $readmemh("mnist_image.mem", memory,11);
        $readmemh("best_model_weights.mem", memory, 795);
    end
    // Asynchronous read
    always @(*) begin
        if (memory_read)
            data_int = memory[address];  // word-aligned, safe masking
        else
            data_int = 32'b0;
    end

//     Synchronous write
    always @(posedge clk) begin
        if (memory_write)
            memory[address] <= write_data;
    end
    // Synchronous write
//    always @(posedge clk) begin
//        if (memory_write)
//            memory[address[15:2]] <= write_data;
//        data_int <= memory[address[15:2]];
//    end
assign read_data = data_int;
endmodule