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
    reg [31:0] memory [0:16383];

/*generate 
    // Optional: manually preload a few words (for LW testing)
    initial begin
        memory[0] = 32'd10;
        memory[1] = 32'd20;
        memory[2] = 32'd30;
        // Others left uninitialized (default X or 0)
    end
endgenerate */
    // Asynchronous read
    always @(*) begin
        if (memory_read)
            read_data = memory[address[9:2] & 15'd16383];  // word-aligned, safe masking
        else
            read_data = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (memory_write)
            memory[address[9:2] & 15'd16383] <= write_data;
    end

endmodule
