`include "defines.v"

module ID (
    // from if_id
    input wire[`InstAddrBus]    i_pc_addr,      // pc address
    input wire[`DataBus]        i_inst_data,    // instruction at pc

    // from regs
    input wire[`DataBus]        i_reg1_rd_data,  // data fetched from reg1
    input wire[`DataBus]        i_reg2_rd_data,  // data fetched from reg2
    
    // to regs
    output reg[`RegsAddrBus]    o_reg1_rd_addr,  // address to fetch from reg1
    output reg[`RegsAddrBus]    o_reg2_rd_addr,  // address to fetch from reg2

    // to id_ex
    output reg[`InstAddrBus]    o_pc_addr,      // pc address
    output reg[`DataBus]        o_inst_data,    // instruction at pc
    output reg[`DataBus]        o_reg1_data,    // data fetched from reg1
    output reg[`RegsAddrBus]    o_reg1_addr,
    output reg[`DataBus]        o_reg2_data,    // data fetched from reg2
    output reg[`RegsAddrBus]    o_reg2_addr,
    output reg[`RegsAddrBus]    o_regd_addr,    // address of rd 
    output reg[`DataBus]        o_imm_data,     // immediate
    output reg[`CtrlBundleBus]  o_ctrl_bundle  // control bundle to tell ex what to do with the data above
);
    
    // instruction segmentation
    wire[6:0] opcode    = i_inst_data[6:0];
    wire[2:0] funct3    = i_inst_data[14:12];
    wire[6:0] funct7    = i_inst_data[31:25];
    wire[4:0] rd        = i_inst_data[11:7];
    wire[4:0] rs1       = i_inst_data[19:15];
    wire[4:0] rs2       = i_inst_data[24:20];

    // control bundles
    reg         cb_Reg_we;          // wheter to write to rd
    reg         cb_ALU_src_A;       // ALU input source A
    reg[1:0]    cb_ALU_src_B;       // ALU input source B
    reg[3:0]    cb_ALU_op;          // ALU operation type
    reg[2:0]    cb_Branch;          // Branch type
    reg         cb_MemtoReg_src;    // source to write to rd
    reg         cb_Mem_we;          // whether to write to data ram
    reg         cb_Mem_re;          // whether to read from data ram
    reg[2:0]    cb_Mem_op;          // memory operation length

    // immediate generator
    wire[`ImmDataBus] immI = {{20{i_inst_data[31]}}, i_inst_data[31:20]};
    wire[`ImmDataBus] immU = {i_inst_data[31:12], 12'b0};
    wire[`ImmDataBus] immS = {{20{i_inst_data[31]}}, i_inst_data[31:25], i_inst_data[11:7]};
    wire[`ImmDataBus] immB = {{20{i_inst_data[31]}}, i_inst_data[7], i_inst_data[30:25], i_inst_data[11:8], 1'b0};
    wire[`ImmDataBus] immJ = {{12{i_inst_data[31]}}, i_inst_data[19:12], i_inst_data[20], i_inst_data[30:21], 1'b0};
    reg[`ImmDataBus] imm;
    always @(*) begin
        case (opcode[6:2])
            5'b11001,5'b00100,5'b00000:     imm = immI;
            5'b01101,5'b00101:              imm = immU;
            5'b01000:                       imm = immS;
            5'b11000:                       imm = immB;
            5'b11011:                       imm = immJ;
            default:                        imm = `ZeroWord;
        endcase
    end

    // output logic
    always @(*) begin
        o_reg1_rd_addr       = rs1;
        o_reg2_rd_addr       = rs2;
        o_inst_data         = i_inst_data;
        o_pc_addr           = i_pc_addr;
        o_reg1_data         = i_reg1_rd_data;
        o_reg1_addr         = rs1;
        o_reg2_data         = i_reg2_rd_data;
        o_reg2_addr         = rs2;
        o_regd_addr         = rd;
        o_imm_data          = imm;

        case (opcode)
            `U_OPCODE_LUI: begin
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;    // don't care
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_ALU_op       = `cb_ALU_op_lui;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
            end
            `U_OPCODE_AUIPC: begin
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_pc;
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
            end
            `I_OPCODE_OP_IMM: begin     // I-type
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
                case (funct3)
                    `funct3_addi: begin
                        cb_ALU_op = `cb_ALU_op_add;
                    end
                    `funct3_slti: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                    end
                    `funct3_sltiu: begin
                        cb_ALU_op = `cb_ALU_op_sltu;
                    end
                    `funct3_xori: begin
                        cb_ALU_op = `cb_ALU_op_xor;
                    end
                    `funct3_ori: begin
                        cb_ALU_op = `cb_ALU_op_or;
                    end
                    `funct3_andi: begin
                        cb_ALU_op = `cb_ALU_op_and;
                    end
                    `funct3_slli: begin
                        cb_ALU_op = `cb_ALU_op_sll;
                    end
                    `funct3_srli_srai: begin
                        cb_ALU_op = (funct7[5] == `funct7_digit6_srli) ? `cb_ALU_op_srl : `cb_ALU_op_sra;
                    end
                    default: begin
                        cb_ALU_op = `cb_ALU_op_add;
                    end
                endcase
            end
            `R_OPCODE: begin            // R-type
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_rs2;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
                case (funct3)
                    `funct3_add_sub: begin
                        cb_ALU_op = (funct7[5] == `funct7_digit6_add) ? `cb_ALU_op_add : `cb_ALU_op_sub;
                    end
                    `funct3_sll: begin
                        cb_ALU_op = `cb_ALU_op_sll;
                    end
                    `funct3_slt: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                    end
                    `funct3_sltu: begin
                        cb_ALU_op = `cb_ALU_op_sltu;
                    end
                    `funct3_xor: begin
                        cb_ALU_op = `cb_ALU_op_xor;
                    end
                    `funct3_srl_sra: begin
                        cb_ALU_op = (funct7[5] == `funct7_digit6_srl) ? `cb_ALU_op_srl : `cb_ALU_op_sra;
                    end
                    `funct3_or: begin
                        cb_ALU_op = `cb_ALU_op_or;
                    end
                    `funct3_and: begin
                        cb_ALU_op = `cb_ALU_op_and;
                    end
                    default: begin
                        cb_ALU_op = `cb_ALU_op_add;
                    end
                endcase
            end
            `J_OPCODE_JAL: begin        // Jump, J-type
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_pc;
                cb_ALU_src_B    = `cb_ALU_src_B_4;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_jump;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
            end
            `J_OPCODE_JALR: begin       // Jump, I-type
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_pc;
                cb_ALU_src_B    = `cb_ALU_src_B_4;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_reg_jump;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
            end
            `B_OPCODE: begin            // B-type
                cb_Reg_we       = `WriteDisable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_rs2;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
                case (funct3)
                    `funct3_beq: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                        cb_Branch = `cb_Branch_jump_eq;
                    end
                    `funct3_bne: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                        cb_Branch = `cb_Branch_jump_ne;
                    end
                    `funct3_blt: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                        cb_Branch = `cb_Branch_jump_l;
                    end
                    `funct3_bge: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                        cb_Branch = `cb_Branch_jump_ge;
                    end
                    `funct3_bltu: begin
                        cb_ALU_op = `cb_ALU_op_sltu;
                        cb_Branch = `cb_Branch_jump_l;
                    end
                    `funct3_bgeu: begin
                        cb_ALU_op = `cb_ALU_op_sltu;
                        cb_Branch = `cb_Branch_jump_ge;
                    end
                    default: begin
                        cb_ALU_op = `cb_ALU_op_slt;
                        cb_Branch = `cb_Branch_jump_eq;
                    end
                endcase
            end
            `I_OPCODE_LOAD: begin       // Load, I-type
                cb_Reg_we       = `WriteEnable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_Mem;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadEnable;
                case (funct3)
                    `funct3_lb: begin
                        cb_Mem_op = `cb_Mem_op_byte;
                    end
                    `funct3_lh: begin
                        cb_Mem_op = `cb_Mem_op_half;
                    end
                    `funct3_lw: begin
                        cb_Mem_op = `cb_Mem_op_word;
                    end
                    `funct3_lbu: begin
                        cb_Mem_op = `cb_Mem_op_ubyte;
                    end
                    `funct3_lhu: begin
                        cb_Mem_op = `cb_Mem_op_uhalf;
                    end
                    default: begin
                        cb_Mem_op = `cb_Mem_op_word;
                    end
                endcase
            end
            `S_OPCODE_STORE: begin      // Store, S-type
                cb_Reg_we       = `WriteDisable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_Mem;
                cb_Mem_we       = `WriteEnable;
                cb_Mem_re       = `ReadDisable;
                case (funct3)
                    `funct3_sb: begin
                        cb_Mem_op = `cb_Mem_op_byte;
                    end
                    `funct3_sh: begin
                        cb_Mem_op = `cb_Mem_op_half;
                    end
                    `funct3_sw: begin
                        cb_Mem_op = `cb_Mem_op_word;
                    end
                    default: begin
                        cb_Mem_op = `cb_Mem_op_byte;
                    end
                endcase
            end
            default: begin
                cb_Reg_we       = `WriteDisable;
                cb_ALU_src_A    = `cb_ALU_src_A_rs1;
                cb_ALU_src_B    = `cb_ALU_src_B_imm;
                cb_ALU_op       = `cb_ALU_op_add;
                cb_Branch       = `cb_Branch_none;
                cb_MemtoReg_src = `cb_MemtoReg_src_ALU;
                cb_Mem_we       = `WriteDisable;
                cb_Mem_re       = `ReadDisable;
                cb_Mem_op       = `cb_Mem_op_word;
            end
        endcase
        
        // sum the control bundle
        o_ctrl_bundle = {cb_Reg_we, cb_ALU_src_A, cb_ALU_src_B, cb_ALU_op, cb_Branch, cb_MemtoReg_src, cb_Mem_we, cb_Mem_re, cb_Mem_op};
    end

endmodule
