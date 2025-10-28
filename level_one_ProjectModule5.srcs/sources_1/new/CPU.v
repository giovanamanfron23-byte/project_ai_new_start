`timescale 1ns / 1ps

module CPU#(
    parameter FREQ = 100_000_000,
    parameter BAUD = 625_000
)
(
    input  clk,
    input  rst,
    input  rxd,
    output wire txd,
    output wire [15:0]  led,
    output wire [3:0]   D0_AN,
    output wire [7:0]   D0_SEG,
    output wire [3:0]   D1_AN,
    output wire [7:0]   D1_SEG
);

    // Program Counter
    reg [31:0] PC;
    wire [31:0] next_pc;
    wire [31:0] instruction;

    // Instruction Fields (matching your encoding)
    wire [3:0] opcode    = instruction[31:28];
    wire [4:0] rs1       = instruction[27:23];
    wire [4:0] rs2       = instruction[22:18];
    wire [4:0] rd        = instruction[17:13];
    wire [12:0] imm      = instruction[12:0];

    wire [31:0] imm_ext = (opcode == 4'b1010 || opcode == 4'b1011) ? {19'b0, imm} : {{19{imm[12]}}, imm};   

    // Control Signals
    wire register_write;
    wire ALUSrc;
    wire [2:0] ALUopcode;
    wire memory_read;
    wire memory_write;
    wire memory_to_register;
    wire branch;

    // Data wires
    wire [31:0] read_data1, read_data2;
    wire [31:0] ALU_result;
    wire [31:0] read_data_memory;
    wire [23:0] pixel_data_back;
    wire [31:0] write_data;
    wire [31:0] dm_address;
    wire [31:0] dm_data;
//    wire [31:0] dm_data_read;

    wire dm_write;
    wire dm_read;
    wire zero_flag;
    
    reg do_calc = 1'd0;
    reg we_want_to_send = 1'd0;
    reg calc_done = 1'd0;
    wire send_is_done;
    reg the_number;
    
    // Instruction Memory
    instruction_memory imem (
        .address(PC),
        .instruction(instruction)
    );

    // Control Unit
    CU control_unit (
        .opcode(opcode),
        .register_write(register_write),
        .ALUSrc(ALUSrc),
        .ALUopcode(ALUopcode),
        .memory_read(memory_read),
        .memory_write(memory_write),
        .memory_to_register(memory_to_register),
        .branch(branch)
    );

    // Register File
    RF regfile (
        .clk(clk),
        .reset(rst),
        .register_write(register_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // ALU input mux
    wire [31:0] ALU_input_B = (ALUSrc) ? imm_ext : read_data2;

    // ALU
    ALU alu (
        .A(read_data1),
        .B(ALU_input_B),
        .do_calc(do_calc),
        .ALUopcode(ALUopcode),
        .result(ALU_result),
        .zero(zero_flag)
    );

    // Data Memory
    DM data_memory (
        .clk(clk),
        .memory_write(dm_write),
        .memory_read(dm_read),
        .address(dm_address),
        .write_data(dm_data),
        .read_data(read_data_memory)
    );
    wire [23:0] pix_out;
    wire  ready_to_write;
    wire [9:0] pix_addr;
    wire [23:0] pix_info;
    wire [23:0] we_want_pix_back;
    wire data_received;
    reg we_want_to_rec;
    reg result;
    
    RAM pixel_storage(
        .clk_i(clk),
        .addr_i(pix_addr),
        .din_i(pix_info),
        .we_i(ready_to_write),
        .dout_o(pix_out)
    
    );
    
    ComU #(
    .FREQ(FREQ), 
    .BAUD(BAUD)
    ) Communication_Unit(
        .clk(clk),
        .rst(rst),
        .rxd(rxd),
        .we_want_to_rec(we_want_to_rec),
        .we_want_to_send(we_want_to_send),
        .ai_result(read_data_memory[3:0]),
        .the_number(the_number),
        .we_want_pix_back(we_want_pix_back),
        .pixel_data_back(pixel_data_back),
        .txd(txd),
        .ready(ready_to_write),
        .addr(pix_addr),
        .pixel_data(pix_info),
        .rec_done(data_received),
        .send_is_done(send_is_done),
        .led(led),
        .D0_AN(D0_AN),
        .D0_SEG(D0_SEG),
        .D1_AN(D1_AN),
        .D1_SEG(D1_SEG)
    );

    // Write-back MUX
    assign write_data = (memory_to_register) ? read_data_memory : ALU_result;
    
    // Next PC logic (normal increment or branch)
    wire [31:0] PC_plus4 = PC + 32'd4;
    wire [31:0] branch_target = PC + (imm_ext << 2);
    
    wire is_beq = (opcode == 4'b1100);
    wire is_bne = (opcode == 4'b1101);
    wire branch_condition = (is_beq && zero_flag) || (is_bne && !zero_flag);
    assign next_pc = (branch && branch_condition) ? branch_target : PC_plus4;
    
    assign pixel_data_back = read_data_memory[23:0];
    
//    assign dm_data_read =
//        (fsm_state == ST_IDLE)? 32'd0:
//        (fsm_state == ST_RX)? pix_info:
//        (fsm_state == ST_CALC)? read_data_memory:
//        (fsm_state == ST_SEND)? pixel_data_back : 16'd0;
        
        
//    assign dm_data =
//        (fsm_state == ST_IDLE)? 32'd0:
//        (fsm_state == ST_RX)? pix_info:
//        (fsm_state == ST_CALC)? read_data2:
//        (fsm_state == ST_SEND)? 1'd0 : 16'd0;
        

//    assign dm_address = 
//        (fsm_state == ST_IDLE)? 32'd0:
//        (fsm_state == ST_RX)? pix_addr:
//        (fsm_state == ST_CALC)? ALU_result:
//        (fsm_state == ST_SEND)? pix_addr : 32'd0;


//    assign dm_read = 
//        (fsm_state == ST_IDLE)? 1'd0:
//        (fsm_state == ST_RX)? 1'd0:
//        (fsm_state == ST_CALC)? memory_read:
//        (fsm_state == ST_SEND)? 1'd1 : 1'd0;


//    assign dm_write = 
//        (fsm_state == ST_IDLE)? 1'd0:
//        (fsm_state == ST_RX)? ready_to_write:
//        (fsm_state == ST_CALC)? memory_write:
//        (fsm_state == ST_SEND)? 1'd0 : 1'd0;
// DM write data: zero-extend pixel triplet to 32 bits
    assign dm_data =
        (fsm_state == ST_RX)   ? {8'h00, pix_info} :
        (fsm_state == ST_CALC) ? read_data2        :
                                 32'd0;
    
    // DM address selection
    assign dm_address =
        (fsm_state == ST_RX)   ? pix_addr    : // loc+10 from ComU during RX
        (fsm_state == ST_CALC) ? ALU_result  :
        (fsm_state == ST_SEND) ? pix_addr    : // bram_addr+10 from ComU during TX
        (fsm_state == ST_SHOW_RES)? 10:
                                 32'd0;
    
    // DM read enable
    assign dm_read =
        (fsm_state == ST_CALC) ? memory_read :
        (fsm_state == ST_SEND) ? 1'b1        :
        (fsm_state == ST_SHOW_RES) ? 1'b1    :
                                 1'b0;
    
    // DM write enable (make sure ready_to_write is 1 bit!)
    assign dm_write =
        (fsm_state == ST_RX)   ? ready_to_write :
        (fsm_state == ST_CALC) ? memory_write   :
                                 1'b0;

    // Program Counter update
    always @(posedge clk or posedge rst) begin
        if (rst)
            PC <= 0;
        else
            PC <= next_pc;
    end


 localparam ST_IDLE    = 2'd0,
               ST_RX   = 2'd1,
               ST_CALC = 2'd2,
               ST_SEND = 2'd3,
               ST_SHOW_RES   = 3'd4;
               
    
    reg  [2:0]  fsm_state = ST_IDLE;

always @(posedge clk) begin
    if(rst)begin
        we_want_to_send <= 0;
        we_want_to_rec <= 0;
        do_calc <= 0;
        fsm_state <= ST_IDLE;
    end
    else begin
    case (fsm_state)
    
    ST_IDLE:begin
    
    fsm_state <= ST_RX;
    end
    
    ST_RX: begin
        we_want_to_rec <= 1;
        if (data_received) begin
            fsm_state <= ST_CALC;
            we_want_to_rec <= 0;
        end
    end
    
    ST_CALC: begin 
        do_calc <=1;
        if(PC[9:2] > 28)begin
            do_calc <= 0;
//            PC <= 0;
            fsm_state <= ST_SEND;
        end
    end
    
    ST_SEND: begin 
        we_want_to_send <=1;
        the_number <= 0;
        if (send_is_done)begin
            fsm_state <= ST_SHOW_RES;
            we_want_to_send <= 0;
        end
    end
    ST_SHOW_RES: begin
        the_number <= 1;
        fsm_state <= ST_IDLE;
    end

    default: fsm_state <= ST_IDLE;
    endcase
    end
end



endmodule

