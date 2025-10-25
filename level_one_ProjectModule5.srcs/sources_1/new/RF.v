`timescale 1ns / 1ps

module RF(
    input wire clk, 
    input wire reset,
    input wire register_write, 
    input wire [4:0] rs1, 
    input wire [4:0] rs2, 
    input wire [4:0] rd, 
    input wire [31:0] write_data, 
    output wire [31:0] read_data1,
    output wire [31:0] read_data2 
);

    reg [31:0] registers [0:31]; 
    integer i; 
/* generate 

    // ✅ Initialize all registers to 0 for simulation stability
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'd0;
        
        // Optional: preload a few registers with known values for debugging
        registers[1] = 32'd5;
        registers[2] = 32'd10;
        registers[3] = 32'd15;
    end
endgenerate */
    // ✅ Reset and write logic
    always @(posedge clk or posedge reset) begin  
        if (reset) begin 
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;    
        end 
        else if (register_write && rd != 0)
            registers[rd] <= write_data; 
    end 

    // ✅ Combinational reads
    assign read_data1 = registers[rs1];
    assign read_data2 = registers[rs2];        

endmodule