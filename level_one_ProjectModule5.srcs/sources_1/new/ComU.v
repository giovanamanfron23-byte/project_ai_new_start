module ComU #(
    parameter FREQ = 100_000_000,
    parameter BAUD = 625_000
)
(
    input  wire         clk,
    input  wire         rxd,
    input  wire         we_want_to_rec,
    input  wire         we_want_to_send,
    input  wire         the_number,
    output wire         txd,
    output wire [3:0]   ready,
    output wire [9:0]   addr,
    output wire [23:0]  pixel_data,
    output wire         rec_done,
    output wire [15:0]  led,
    output wire [3:0]   D0_AN,
    output wire [7:0]   D0_SEG,
    output wire [3:0]   D1_AN,
    output wire [7:0]   D1_SEG
);
    wire [23:0] bram_dout;
    wire tx_ready;
    wire rx_ready;
    wire [7:0] rx_byte;
    wire rst;

    rst_gen #(
        .CC_ACTIVE(20)
    ) rst_gen_inst (
        .clk(clk),
        .rst(rst),
        .rst_n()
    );
    
    uart_receive #(
        .CLK_FREQUENCY_HZ(FREQ),
        .BAUD_RATE       (BAUD)
    ) uart_rx_inst (
        .rst       (rst),
        .clk       (clk),
        .rxd       (rxd),
        .rxd_data  (rx_byte),
        .rxd_ready (rx_ready)
    );
    
    localparam PKT_HEADER   = 3'b101;       
    localparam delay_cnt    = 32'd6400-1;  
    localparam PKT_EXPECTED = 32'd784;

    localparam ST_IDLE    = 2'd0,
               ST_BYTE1   = 2'd1,
               ST_BYTE2   = 2'd2,
               ST_CHECK   = 2'd3,
               ST_DONE    = 3'd4;
               
    
    reg  [2:0]  fsm_state = ST_IDLE;
    reg  [31:0] cnt32b    = 32'd0;
    reg         timeout_flag = 1'b0;
    reg         receive_done = 0;
    
    reg [9:0]  loc_reg   = 10'd0;
    reg [7:0]  data_reg  = 8'd0;
    reg [2:0]  footer_reg= 3'd0;
    reg [23:0] packet_raw;

    reg [31:0] count_packets = 32'd0;
    reg [15:0] led_show      = 16'd0;

    assign led[15:0] = led_show[15:0];


    
    reg send_done = 0;
    wire [2:0] footer_calc;
    assign footer_calc[2] = ^data_reg;                        // f2 = XOR(Data[7:0])
    assign footer_calc[1] = ^loc_reg;                         // f1 = XOR(Loc[9:0])
    assign footer_calc[0] = ^{data_reg[7:4], loc_reg[9:5]};   // f0 = XOR(Data[7:4] + Loc[9:5])

    wire packet_ok = (footer_calc == footer_reg);
    
    //Rx Part
    always @(posedge clk) begin
        if (rst) begin
            receive_done   <= 0;
            fsm_state      <= ST_IDLE;
            cnt32b         <= 32'd0;
            timeout_flag   <= 1'b0;
            count_packets  <= 32'd0;
        end 
        else begin
            (*parallel_case*)
            case (fsm_state)
            
            ST_IDLE: begin
                timeout_flag <= 1'b0;
                cnt32b       <= 32'd0;
                if (rx_ready && (rx_byte[7:5] == PKT_HEADER)) begin
                    packet_raw[23:16] <= rx_byte;
                    loc_reg[9:5] <= rx_byte[4:0];
                    fsm_state    <= ST_BYTE1;
                end
                if (count_packets >= PKT_EXPECTED)begin
                    fsm_state <= ST_DONE;                      
                end
            end
            
            ST_BYTE1: begin
                if (rx_ready) begin
                    packet_raw[15:8] <= rx_byte;
                    loc_reg[4:0]  <= rx_byte[7:3];
                    data_reg[7:5] <= rx_byte[2:0];
                    cnt32b        <= 32'd0;
                    fsm_state     <= ST_BYTE2;
                end 
                else if (cnt32b == delay_cnt) begin
                    timeout_flag <= 1'b1;
                    cnt32b <= 32'd0;
                    fsm_state    <= ST_IDLE;
                end 
                else
                    cnt32b <= cnt32b + 1;
            end
            
            ST_BYTE2: begin
                if (rx_ready) begin
                    packet_raw[7:0] <= rx_byte;
                    data_reg[4:0]  <= rx_byte[7:3];
                    footer_reg     <= rx_byte[2:0];
                    cnt32b         <= 32'd0;  
                    fsm_state <= ST_CHECK;
                end
                else if (cnt32b == delay_cnt) begin
                    timeout_flag <= 1'b1;
                    cnt32b <= 32'd0;
                    fsm_state    <= ST_IDLE;
                end 
                else
                    cnt32b <= cnt32b + 1;
            end
            
            ST_CHECK: begin
                if (packet_ok) begin
                    count_packets <= count_packets + 1;
                    led_show      <= count_packets[15:0] + 1;

                end   
                else begin   
                    timeout_flag <= 1'b1;
                end 
                 fsm_state <= ST_IDLE;
            end
            
            
            ST_DONE: begin
                led_show <= 16'hFFFF;
                receive_done   <= 1;
                if (send_done) begin
                    receive_done  <= 0;              
                    count_packets <= 32'd0;     
                    timeout_flag  <= 1'b0;
                    fsm_state     <= ST_IDLE;   
                end
            end
            
            default: fsm_state <= ST_IDLE;
            endcase
        end
    end
    
    reg [2:0] tx_state;
    reg [1:0] tx_byte_sel = 0;
    reg [9:0] bram_addr = 0;     
    reg [23:0] tx_data = 0;
    reg tx_en = 0;
    reg [7:0] tx_byte = 8'd0;
    
    localparam TX_IDLE = 2'd0,
               TX_WAIT = 2'd1,
               TX_READ = 2'd2,
               TX_LOAD = 2'd3,
               TX_SEND = 3'd4;
               
    
    //Tx Part
    always @(posedge clk) begin
        if (rst) begin
            send_done    <= 0;
            tx_state     <= TX_IDLE;
            tx_byte_sel  <= 0;
            bram_addr    <= 0;
            tx_en        <= 0;
            tx_byte      <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    send_done <= 0;
                    if (receive_done) begin
                        tx_state        <= TX_WAIT;
                        tx_byte_sel     <= 0;
                        bram_addr       <= 0;
                    end
                    tx_en <= 0;
                end
                
                TX_WAIT: begin                        
                    tx_state <= TX_READ;
                end
                
                TX_READ: begin
                    tx_data <= bram_dout;                         
                    tx_state <= TX_LOAD;
                end
                
                TX_LOAD: begin
                    if (tx_ready) begin
                        case (tx_byte_sel)
                           2'd0: tx_byte <= tx_data[23:16];
                           2'd1: tx_byte <= tx_data[15:8];
                           2'd2: tx_byte <= tx_data[7:0];
                        endcase
                        tx_en <= 1;   
                        tx_state <= TX_SEND;
                    end
                end
                
                TX_SEND: begin
                    if (tx_byte_sel == 2'd2) begin
                        tx_byte_sel <= 0;
                        bram_addr <= bram_addr + 1;
                        if (bram_addr == PKT_EXPECTED-1)begin
                            send_done <= 1;
                            tx_state <= TX_IDLE;
                        end
                        else begin
                            tx_state <= TX_WAIT;
                        end
                    end 
                    else begin
                        tx_byte_sel <= tx_byte_sel + 1;
                        tx_state <= TX_LOAD;
                    end 
                    tx_en <= 0;
                end
                default: tx_state <= TX_IDLE;
            endcase
        end
    end
    
    neorv32_sram_blockram #(
        .ADDR_WIDTH(10),
        .INIT_FILE("")
    ) bram_inst (
        .clk_i(clk),
        .addr_i((fsm_state == ST_CHECK && packet_ok) ? loc_reg : bram_addr),
        .din_i(packet_raw),
        .we_i((fsm_state == ST_CHECK && packet_ok)? 4'b1111 : 4'b0000),
        .en_i(1'b1),
        .dout_o(bram_dout)
    );
    
    uart_send #(
        .CLK_FREQUENCY_HZ(FREQ),
        .BAUD_RATE(BAUD)
    ) uart_tx_inst (
        .rst(rst),
        .clk(clk),
        .din(tx_byte),
        .en(tx_en),
        .txd(txd),
        .txd_ready(tx_ready)
    );
    
    
      reg  [3:0] digit_data [7:0];
    parameter REFRESH_PERIOD = 2000;
    
    always @(*) begin
        digit_data[0] = count_packets[19:16];
        digit_data[1] = count_packets[23:20];
        digit_data[2] = count_packets[27:24];
        digit_data[3] = count_packets[31:28];
        
        digit_data[4] = count_packets[3:0];
        digit_data[5] = count_packets[7:4];
        digit_data[6] = count_packets[11:8];
        digit_data[7] = count_packets[15:12];
    end

    reg [2:0] digit_index = 0;
    reg [15:0] refresh_counter = 0;

    always @(posedge clk) begin
        if (refresh_counter >= REFRESH_PERIOD) begin
            refresh_counter <= 0;
            digit_index <= digit_index + 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
        end
    end

    wire [3:0] active_digit = digit_data[digit_index];
    wire [6:0] seg_val;

    seven_segment_decoder_hex decoder (
        .digit(active_digit),
        .seg(seg_val)
    );

    reg [3:0] D0_AN_reg, D1_AN_reg;
    reg [7:0] D0_SEG_reg, D1_SEG_reg;

    always @(*) begin
        D0_AN_reg = 4'b1111;
        D1_AN_reg = 4'b1111;
        D0_SEG_reg = 8'b11111111;
        D1_SEG_reg = 8'b11111111;

        if (digit_index < 4) begin
            D0_AN_reg[digit_index] = 0;
            D0_SEG_reg[6:0] = seg_val;
            D0_SEG_reg[7]   = 1;
        end else begin
            D1_AN_reg[digit_index - 4] = 0;
            D1_SEG_reg[6:0] = seg_val;
            D1_SEG_reg[7]   = 1;
        end
    end
    
    assign D0_AN  = D0_AN_reg;
    assign D0_SEG = D0_SEG_reg;
    assign D1_AN  = D1_AN_reg;
    assign D1_SEG = D1_SEG_reg;
    
assign ready = ((fsm_state == ST_CHECK && packet_ok)? 4'b1111 : 4'b0000);
assign addr = bram_addr;
assign pixel_data = packet_raw;
assign rec_done = receive_done;

endmodule