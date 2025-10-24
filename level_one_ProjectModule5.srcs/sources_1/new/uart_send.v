//UART Send (TX) 
//Developer: Sameed Sohail
//BaudCount = [Clock_Frequency / Baud_Rate]-1  (Ideally clock frequency should be multiple of baurd_rate to avoid clock related glitches)

module uart_send #(
    parameter CLK_FREQUENCY_HZ = 100_000_000,
    parameter BAUD_RATE = 1_562_500
)
(
    input rst,
    input clk,
    input [7:0] din,
    input en,                       //1cc
    output reg txd = 1'b1,
    output reg txd_ready = 1'b1
);

localparam  SM_IDLE = 2'd0,
            SM_WAIT = 2'd1,
            SM_TX = 2'd2,
            SM_TX_1 = 2'd3;

reg [31:0] baud_count = (CLK_FREQUENCY_HZ/BAUD_RATE)-1; // clock divider value

reg [31:0] counter_baud = {32{1'b0}};
reg [1:0] fsm_tx = SM_IDLE;
reg [7:0] din_temp = 8'd0;
reg [3:0] cnt_4b = 4'd0;

always@(posedge clk) begin

    if(rst) begin
        fsm_tx <= SM_IDLE;
        txd <= 1'b1;
        txd_ready <= 1'b1;
        din_temp <= 8'd0;
        counter_baud <= {32{1'b0}};
        cnt_4b <= 4'd0;
    end
    else begin
        
        (*parallel_case*)
        case(fsm_tx)

            SM_IDLE: begin
                fsm_tx <= SM_WAIT;
                txd_ready <= 1'b1;
                txd <= 1'b1;
            end

            SM_WAIT: begin
                if(txd_ready & en) begin
                    fsm_tx <= SM_TX;
                    din_temp <= din;
                    txd <= 1'b0;
                    txd_ready <= 1'b0;
                end
            end
            
            SM_TX: begin
                if(counter_baud >= baud_count-1) begin
                    fsm_tx <= SM_TX_1;
                    counter_baud <= {32{1'b0}};
                end
                else begin
                    counter_baud <= counter_baud + {{32-1{1'b0}},1'b1};
                end
            end

            SM_TX_1: begin
                if( cnt_4b > 4'd8 ) begin
                    fsm_tx <= SM_WAIT;
                    cnt_4b <= 4'd0;
                    txd_ready <= 1'b1;  //Transmit complete
                end
                else if( cnt_4b == 4'd8 ) begin
                    fsm_tx <= SM_TX;
                    txd <= 1'b1;    //Stop bit
                    cnt_4b <= cnt_4b + 4'd1;    
                end
                else begin
                    fsm_tx <= SM_TX;
                    txd <= din_temp[cnt_4b]; //Data
                    cnt_4b <= cnt_4b + 4'd1;
                end
            end
        
        endcase    
    end    

end

endmodule
