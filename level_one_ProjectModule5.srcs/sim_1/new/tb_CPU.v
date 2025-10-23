`timescale 1ns / 1ps
module tb_CPU;
    reg clk = 0;
    reg reset = 1;

    CPU uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        #20 reset = 0;
        #100 $stop;
    end
endmodule
