`timescale 1ns/1ps

module tb_CPU;
  reg  clk = 0;
  reg  rst = 1;

  // tie UART RX idle high; we don't drive UART in this TB
  wire rxd = 1'b1;

  // unused outs
  wire txd;
  wire [15:0] led;
  wire [3:0] D0_AN;
  wire [7:0] D0_SEG;
  wire [3:0] D1_AN;
  wire [7:0] D1_SEG;

  // DUT
  CPU uut (
    .clk(clk),
    .rst(rst),
    .rxd(rxd),
    .txd(txd),
    .led(led),
    .D0_AN(D0_AN),
    .D0_SEG(D0_SEG),
    .D1_AN(D1_AN),
    .D1_SEG(D1_SEG)
  );

  // 100 MHz
  always #5 clk = ~clk;

  // match your program's RESULT_ADDR
  localparam RESULT_ADDR = 32'd8624;

  initial begin
    // reset
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Wait until the program stores the prediction to RESULT_ADDR
    // (hierarchical refs to CPU internals)
    wait (uut.memory_write && uut.ALU_result == RESULT_ADDR);
    $display("[%0t] Predicted class (low nibble) = %0d  full word = 0x%08h",
             $time, uut.write_data[3:0], uut.write_data);

    // Optionally confirm by peeking DM
    #1;
    $display("DM[11] = 0x%08h",
             uut.data_memory.memory[RESULT_ADDR>>2]);

    // done
    repeat (50) @(posedge clk);
    $stop;
  end
endmodule