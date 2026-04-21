`include "defines.v"

module EX (    
    // from id_ex
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`DataBus]        i_inst_data,
    input wire[`DataBus]        i_reg1_data,
    input wire[`RegsAddrBus]    i_reg1_addr,
    input wire[`DataBus]        i_reg2_data,
    input wire[`RegsAddrBus]    i_reg2_addr,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_imm_data,
    input wire[`CtrlBundleBus]  i_ctrl_bundle,

    // from ex_mem
    input wire                  i_ex_mem_regd_we,
    input wire[`RegsAddrBus]    i_ex_mem_regd_addr,
    input wire[`DataBus]        i_ex_mem_regd_data,
    
    // from mem_wb
    input wire                  i_mem_wb_regd_we,
    input wire[`RegsAddrBus]    i_mem_wb_regd_addr,
    input wire[`DataBus]        i_mem_wb_regd_data,

    // to ex_mem
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data,
    output reg                  o_wb_src,       // which source to write to the destination register, from memory(1) or ALU(0)
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data_alu,
    output reg                  o_mem_we,
    output reg                  o_mem_re,
    output reg[`DataAddrBus]    o_mem_addr,
    output reg[`DataBus]        o_mem_wr_data_raw,
    output reg[`MemOpTypeBus]   o_mem_op_type,

    // to ctrl
    output reg                  o_ex_branch,
    output reg                  o_ex_load_use,
    output reg                  o_jump_flag,
    output reg[`InstAddrBus]    o_jump_addr
);

    // decode ctrl_bundle
    wire        cb_Reg_we = i_ctrl_bundle[16];                                             // wheter to write to rd
    wire        cb_ALU_src_A = i_ctrl_bundle[15];     // ALU input source A
    wire[1:0]   cb_ALU_src_B = i_ctrl_bundle[14:13];  // ALU input source B
    wire[3:0]   cb_ALU_op = i_ctrl_bundle[12:9];                                           // ALU operation type
    wire[2:0]   cb_Branch = i_ctrl_bundle[8:6];                                            // Branch type
    wire        cb_MemtoReg_src = i_ctrl_bundle[5];                                        // source to write to rd, from memory(1) or ALU(0)
    wire        cb_Mem_we = i_ctrl_bundle[4];                                              // whether to write to data ram
    wire        cb_Mem_re = i_ctrl_bundle[3];                                              // whether to read from data ram
    wire[2:0]   cb_Mem_op = i_ctrl_bundle[2:0];                                            // memory operation length

    wire ex_mem_forwardA = i_ex_mem_regd_we && (i_reg1_addr == i_ex_mem_regd_addr) && (i_ex_mem_regd_addr != `Reg0Addr) && (cb_ALU_src_A == `cb_ALU_src_A_rs1);
    wire ex_mem_forwardB = i_ex_mem_regd_we && (i_reg2_addr == i_ex_mem_regd_addr) && (i_ex_mem_regd_addr != `Reg0Addr) && (cb_ALU_src_B == `cb_ALU_src_B_rs2);

    wire mem_wb_forwardA = i_mem_wb_regd_we && (i_reg1_addr == i_mem_wb_regd_addr) && (i_mem_wb_regd_addr != `Reg0Addr) && (cb_ALU_src_A == `cb_ALU_src_A_rs1);
    wire mem_wb_forwardB = i_mem_wb_regd_we && (i_reg2_addr == i_mem_wb_regd_addr) && (i_mem_wb_regd_addr != `Reg0Addr) && (cb_ALU_src_B == `cb_ALU_src_B_rs2);

    wire store_data_forward_ex_mem = cb_Mem_we && i_ex_mem_regd_we && (i_reg2_addr == i_ex_mem_regd_addr) && (i_ex_mem_regd_addr != `Reg0Addr);
    wire store_data_forward_mem_wb = cb_Mem_we && i_mem_wb_regd_we && (i_reg2_addr == i_mem_wb_regd_addr) && (i_mem_wb_regd_addr != `Reg0Addr);

    // ALU input A
    reg[`DataBus] alu_SRC_A;
    always @(*) begin
        if (ex_mem_forwardA) begin
            alu_SRC_A = i_ex_mem_regd_data;
        end
        else if (mem_wb_forwardA) begin
            alu_SRC_A = i_mem_wb_regd_data;
        end
        else begin
            case (cb_ALU_src_A)
                `cb_ALU_src_A_rs1: begin
                    alu_SRC_A = i_reg1_data;
                end
                `cb_ALU_src_A_pc: begin
                    alu_SRC_A = i_pc_addr;
                end
                default: begin
                    alu_SRC_A = i_reg1_data;
                end
            endcase
        end
    end

    // ALU input B
    reg[`DataBus] alu_SRC_B;
    always @(*) begin
        if (ex_mem_forwardB) begin
            alu_SRC_B = i_ex_mem_regd_data;
        end
        else if (mem_wb_forwardB) begin
            alu_SRC_B = i_mem_wb_regd_data;
        end
        else begin
            case (cb_ALU_src_B)
                `cb_ALU_src_B_rs2: begin
                    alu_SRC_B = i_reg2_data;
                end
                `cb_ALU_src_B_imm: begin
                    alu_SRC_B = i_imm_data;
                end
                `cb_ALU_src_B_4: begin
                    alu_SRC_B = 32'd4;
                end
                default: begin
                    alu_SRC_B = i_reg2_data;
                end
            endcase
        end
    end

    // equal flag
    wire equal_flag = (alu_SRC_A == alu_SRC_B);

    // ALU Result
    reg[`DataBus] alu_result;
    always @(*) begin
        case (cb_ALU_op)
            `cb_ALU_op_add: begin
                alu_result = alu_SRC_A + alu_SRC_B;
            end
            `cb_ALU_op_sub: begin
                alu_result = alu_SRC_A - alu_SRC_B;
            end
            `cb_ALU_op_slt: begin
                alu_result = $signed(alu_SRC_A) < $signed(alu_SRC_B) ? 32'd1 : 32'd0;
            end
            `cb_ALU_op_sltu: begin
                alu_result = alu_SRC_A < alu_SRC_B ? 32'd1 : 32'd0;
            end
            `cb_ALU_op_xor: begin
                alu_result = alu_SRC_A ^ alu_SRC_B;
            end
            `cb_ALU_op_or: begin
                alu_result = alu_SRC_A | alu_SRC_B;
            end
            `cb_ALU_op_and: begin
                alu_result = alu_SRC_A & alu_SRC_B;
            end
            `cb_ALU_op_sll: begin
                alu_result = alu_SRC_A << alu_SRC_B[4:0];
            end
            `cb_ALU_op_srl: begin
                alu_result = alu_SRC_A >> alu_SRC_B[4:0];
            end
            `cb_ALU_op_sra: begin
                alu_result = $signed(alu_SRC_A) >>> alu_SRC_B[4:0];
            end
            `cb_ALU_op_lui: begin
                alu_result = alu_SRC_B;
            end
            default: begin
                alu_result = `ZeroWord;
            end
        endcase
    end

    // branch
    always @(*) begin
        case (cb_Branch)
            `cb_Branch_none: begin
                o_ex_branch = 1'b0;
                o_jump_flag = `JumpDisable;
                o_jump_addr = `ZeroAddr;
            end 
            `cb_Branch_jump: begin
                o_ex_branch = 1'b1;
                o_jump_flag = `JumpEnable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `cb_Branch_reg_jump: begin
                o_ex_branch = 1'b1;
                o_jump_flag = `JumpEnable;
                if (ex_mem_forwardA) begin
                    o_jump_addr = (i_ex_mem_regd_data + i_imm_data) & ~32'd1;
                end
                else if (mem_wb_forwardA) begin
                    o_jump_addr = (i_mem_wb_regd_data + i_imm_data) & ~32'd1;
                end
                else begin
                    o_jump_addr = (i_reg1_data + i_imm_data) & ~32'd1;
                end
            end 
            `cb_Branch_jump_eq: begin
                o_ex_branch = equal_flag ? 1'b1 : 1'b0;
                o_jump_flag = equal_flag ? `JumpEnable : `JumpDisable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `cb_Branch_jump_ne: begin
                o_ex_branch = equal_flag ? 1'b0 : 1'b1;
                o_jump_flag = equal_flag ? `JumpDisable : `JumpEnable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `cb_Branch_jump_l: begin
                o_ex_branch = (alu_result == 1) ? 1'b1 : 1'b0;
                o_jump_flag = (alu_result == 1) ? `JumpEnable : `JumpDisable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `cb_Branch_jump_ge: begin
                o_ex_branch = (alu_result == 1) ? 1'b0 : 1'b1;
                o_jump_flag = (alu_result == 1) ? `JumpDisable : `JumpEnable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            default: begin
                o_ex_branch = 1'b0;
                o_jump_flag = `JumpDisable;
                o_jump_addr = `ZeroAddr;
            end 
        endcase
    end

    always @(*) begin
        // load use
        o_ex_load_use = (cb_MemtoReg_src == 1) && cb_Reg_we && (i_regd_addr != `Reg0Addr);

        o_pc_addr = i_pc_addr;
        o_inst_data = i_inst_data;
        
        // register writeback source
        o_wb_src = cb_MemtoReg_src;

        // register write
        o_regd_we = cb_Reg_we;
        o_regd_addr = i_regd_addr;
        o_regd_data_alu = alu_result;
        
        // memory write
        o_mem_we = cb_Mem_we;
        o_mem_re = cb_Mem_re;

        o_mem_op_type = cb_Mem_op;
    end

    always @(*) begin
        if (cb_Mem_we) begin
            o_mem_addr = alu_result;
            if (store_data_forward_ex_mem) begin
                o_mem_wr_data_raw = i_ex_mem_regd_data;
            end
            else if (store_data_forward_mem_wb) begin
                o_mem_wr_data_raw = i_mem_wb_regd_data;
            end
            else begin
                o_mem_wr_data_raw = i_reg2_data;
            end
        end
        else begin
            o_mem_addr = alu_result;
            o_mem_wr_data_raw = `ZeroWord;
        end
    end

endmodule
