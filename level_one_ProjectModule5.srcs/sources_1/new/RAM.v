
module RAM(
    input clk_i,
    input [9:0] addr_i,
    input [23:0] din_i,
    input [3:0] we_i,
    output [23:0] dout_o
    );
    
reg [23:0] BRAM [2**9:0];
reg [23:0] ram_data = {24{1'b0}};

assign dout_o = ram_data; //Write first Mode 

always @(posedge clk_i) 
    begin
      if((&we_i)) begin
        BRAM[addr_i] <= din_i;
        ram_data <= din_i;
      end
      else begin
        ram_data <= BRAM[addr_i];
      end
    end
    
endmodule
