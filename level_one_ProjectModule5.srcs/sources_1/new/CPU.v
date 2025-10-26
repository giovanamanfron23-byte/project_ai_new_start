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
    wire [31:0] write_data;
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
        .memory_write(memory_write),
        .memory_read(memory_read),
        .address(ALU_result),
        .write_data(read_data2),
        .read_data(read_data_memory)
    );
    wire [23:0] pix_out;
    wire [3:0] ready_to_write;
    wire [9:0] pix_addr;
    wire [23:0] pix_info;
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
        .rxd(rxd),
        .we_want_to_rec(we_want_to_rec),
        .we_want_to_send(we_want_to_send),
        .the_number(the_number),
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
    wire [31:0] PC_plus4 = PC + 32'd4*do_calc;
    wire [31:0] branch_target = PC + (imm_ext << 2);
    
    wire is_beq = (opcode == 4'b1100);
    wire is_bne = (opcode == 4'b1101);
    wire branch_condition = (is_beq && zero_flag) || (is_bne && !zero_flag);
    assign next_pc = (branch && branch_condition) ? branch_target : PC_plus4;

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
               ST_GO   = 3'd4;
               
    
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
        if (data_received)begin
            fsm_state <= ST_CALC;
            we_want_to_rec <= 0;
        end
    end
    
    ST_CALC: begin 
        do_calc <=1;
        if(calc_done)begin
            do_calc <= 0;
            the_number <= result;
            fsm_state <= ST_SEND;
        end
    end
    
    ST_SEND: begin 
        we_want_to_send <=1;
        if (send_is_done)begin
            fsm_state <= ST_IDLE;
            we_want_to_send <= 0;
        end
    
    end
    default: fsm_state <= ST_IDLE;
    endcase
    end
end



endmodule

