//Module for BRAM creation as per requirement (No need to separate into banks) - Write First Mode

module neorv32_sram_blockram #(
  parameter ADDR_WIDTH = 32,        //Pre-compute the address width  
  parameter INIT_FILE = ""          //Specify name/location of RAM initialization file if using one (leave blank if not)
)(
    input clk_i,
    input [ADDR_WIDTH-1:0] addr_i,
    input [23:0] din_i,
    input [3:0] we_i,
    input en_i,
    output [23:0] dout_o
);

reg [23:0] BRAM [2**ADDR_WIDTH-1:0];
reg [23:0] ram_data = {24{1'b0}};

generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, BRAM, 0, 2**ADDR_WIDTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < 2**ADDR_WIDTH; ram_index = ram_index + 1)
          BRAM[ram_index] = {24{1'b0}};
    end
endgenerate

assign dout_o = ram_data; //Write first Mode 

always @(posedge clk_i) 
    if(en_i) begin
      if((&we_i)) begin
        BRAM[addr_i] <= din_i;
        ram_data <= din_i;
      end
      else begin
        ram_data <= BRAM[addr_i];
      end
    end
    

endmodule

