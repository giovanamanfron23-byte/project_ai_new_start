`timescale 1ns/1ps

module tb_cpu_comu_min;

  // clock/reset
  reg clk = 0;
  reg rst = 1;
  always #5 clk = ~clk; // 100 MHz

  // UART lines
  reg  rxd;
  wire txd;

  // not used, but wired
  wire [15:0] led;
  wire [3:0]  D0_AN, D1_AN;
  wire [7:0]  D0_SEG, D1_SEG;

  // DUT
  CPU uut (
    .clk(clk),
    .rst(rst),
    .rxd(rxd),
    .txd(txd),
    .led(led),
    .D0_AN(D0_AN), .D0_SEG(D0_SEG),
    .D1_AN(D1_AN), .D1_SEG(D1_SEG)
  );

  // UART config (ComU default)
  localparam integer CLK_HZ   = 100_000_000;
  localparam integer BAUD     = 625_000;
  localparam integer BIT_TCKS = CLK_HZ/BAUD; // 160 at 100 MHz

  // ComU framing (header/footer split)
  function [7:0] mk_b0(input [9:0] loc);
    mk_b0 = {3'b101, loc[9:5]};
  endfunction
  function [7:0] mk_b1(input [9:0] loc, input [7:0] data);
    mk_b1 = {loc[4:0], data[7:5]};
  endfunction
  function [7:0] mk_b2(input [7:0] data, input [2:0] foot);
    mk_b2 = {data[4:0], foot};
  endfunction

  // UART driver 8N1
  task uart_tx_byte(input [7:0] b);
    integer i;
    begin
      rxd = 1'b0; repeat (BIT_TCKS) @(posedge clk);      // start
      for (i=0;i<8;i=i+1) begin
        rxd = b[i]; repeat (BIT_TCKS) @(posedge clk);    // data
      end
      rxd = 1'b1; repeat (BIT_TCKS) @(posedge clk);      // stop
      repeat (BIT_TCKS/2) @(posedge clk);                // gap
    end
  endtask

  // one pixel (3 bytes)
  task send_pixel(input [9:0] loc, input [7:0] data);
    reg [7:0] b0,b1,b2;
    begin
      b0 = mk_b0(loc);
      b1 = mk_b1(loc, data);
      b2 = mk_b2(data, 3'b000); // footer ignored (we force accept)
      uart_tx_byte(b0);
      uart_tx_byte(b1);
      uart_tx_byte(b2);
    end
  endtask

  // DM peek (your DM indexes by address directly)
  function [31:0] dm_rd(input [31:0] idx);
    dm_rd = uut.data_memory.memory[idx];
  endfunction

  // expected word written during ST_RX: {00, b0, b1, b2}
  function [31:0] expect_word(input [9:0] loc, input [7:0] data);
    reg [7:0] b0,b1,b2;
    begin
      b0 = mk_b0(loc);
      b1 = mk_b1(loc, data);
      b2 = mk_b2(data, 3'b000);
      expect_word = {8'h00, b0, b1, b2};
    end
  endfunction

  initial begin
    rxd = 1'b1; // idle high

    // reset
    repeat (40) @(posedge clk);
    rst = 0;

    // Force internals for this simple test:
    // 1) ComU.rst is otherwise undriven in your ComU.v - hold it low
    force uut.Communication_Unit.rst = 1'b0;
    // 2) Accept all packets (bypass footer)
    force uut.Communication_Unit.footer_reg = uut.Communication_Unit.footer_calc;
    // (Alternative: force uut.Communication_Unit.packet_ok = 1'b1;)

    // let CPU enter ST_RX
    repeat (2000) @(posedge clk);

    // Stimulus
    send_pixel(10'd0,   8'hAB);
    send_pixel(10'd1,   8'h3C);
    send_pixel(10'd20,  8'hFF);
    send_pixel(10'd123, 8'h55);
    send_pixel(10'd511, 8'h9A);

    // Wait ~2 ms (with `timescale 1ns/1ps`, write as nanoseconds)
    #2_000_000;

    // Checks (DM index = loc + 10)
    if (dm_rd(  0+10) !== expect_word(  0,8'hAB)) $fatal(1, "DM[%0d] got 0x%08h exp 0x%08h",  0+10, dm_rd(0+10),  expect_word(0,8'hAB));
    if (dm_rd(  1+10) !== expect_word(  1,8'h3C)) $fatal(1, "DM[%0d] got 0x%08h exp 0x%08h",  1+10, dm_rd(1+10),  expect_word(1,8'h3C));
    if (dm_rd( 20+10) !== expect_word( 20,8'hFF)) $fatal(1, "DM[%0d] got 0x%08h exp 0x%08h", 20+10, dm_rd(20+10), expect_word(20,8'hFF));
    if (dm_rd(123+10) !== expect_word(123,8'h55)) $fatal(1, "DM[%0d] got 0x%08h exp 0x%08h",123+10, dm_rd(123+10), expect_word(123,8'h55));
    if (dm_rd(511+10) !== expect_word(511,8'h9A)) $fatal(1, "DM[%0d] got 0x%08h exp 0x%08h",511+10, dm_rd(511+10), expect_word(511,8'h9A));

    $display("[%0t] OK: all ComU to CPU to DM writes verified.", $time);

    // release forces (optional)
    release uut.Communication_Unit.footer_reg;
    release uut.Communication_Unit.rst;

    #100_000;
    $stop;
  end

endmodule