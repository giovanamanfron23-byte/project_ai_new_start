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
        reset = 1;
        #50 reset = 0;
        #200 $stop;
    end
endmodule
