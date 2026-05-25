`include "defines.v"

module ID (
    // from IF_ID
    input wire[`InstAddrBus]    i_pc_addr,          // pc address
    input wire[`DataBus]        i_inst_data,        // instruction at pc

    // I/O with Regs
    input wire[`DataBus]        i_reg1_rd_data,     // data fetched from reg1
    input wire[`DataBus]        i_reg2_rd_data,     // data fetched from reg2
    output reg[`RegsAddrBus]    o_reg1_rd_addr,     // address to fetch from reg1
    output reg[`RegsAddrBus]    o_reg2_rd_addr,     // address to fetch from reg2

    // I/O with Regs_CSR
	input wire[`DataBus]        i_csr_rd_data,
    output reg[`CSRAddrBus]     o_csr_rd_addr,

    // forward from ID_EX
    input wire                  i_id_ex_Mem_re,
    input wire                  i_id_ex_Reg_we,
    input wire[`RegsAddrBus]    i_id_ex_regd_addr,

    // to ID_EX
    output reg[`InstAddrBus]    o_pc_addr,          // pc address
    output reg[`DataBus]        o_inst_data,        // instruction at pc
    output reg[`DataBus]        o_reg1_data,        // data fetched from reg1
    output reg[`RegsAddrBus]    o_reg1_addr,    
    output reg[`DataBus]        o_reg2_data,        // data fetched from reg2
    output reg[`RegsAddrBus]    o_reg2_addr,    
    output reg[`RegsAddrBus]    o_regd_addr,        // address of rd 
    output reg[`DataBus]        o_imm_data,         // immediate
    
    output reg                  o_Reg_we,           // wheter to write to rd
    output reg                  o_ALU_src_A,        // ALU input source A
    output reg[1:0]             o_ALU_src_B,        // ALU input source B
    output reg[4:0]             o_ALU_op,           // ALU operation type
    output reg[2:0]             o_Branch,           // Branch type
    output reg                  o_MemtoReg_src,     // source to write to rd
    output reg                  o_Mem_we,           // whether to write to data ram
    output reg                  o_Mem_re,           // whether to read from data ram
    output reg[2:0]             o_Mem_op,           // memory operation length & type

    output reg[2:0]             o_csr_op,
    output reg                  o_csr_wr_en,
	output reg[`CSRAddrBus]     o_csr_wr_addr,
    output reg[`DataBus]        o_csr_data,
    output reg[`DataBus]        o_csr_zimm_data,

    output reg[`TrapCauseBus]   o_trap_cause,

    // to Ctrl_Unit
    output reg                  o_id_load_use
);
    
    // instruction segmentation
    wire[6:0] opcode    = i_inst_data[6:0];
    wire[2:0] funct3    = i_inst_data[14:12];
    wire[6:0] funct7    = i_inst_data[31:25];
    wire[4:0] rd        = i_inst_data[11:7];
    wire[4:0] rs1       = i_inst_data[19:15];
    wire[4:0] rs2       = i_inst_data[24:20];

    // csr instruction segmentation
    wire is_system = (opcode == `OPCODE_SYSTEM);
    wire is_csr_inst      = is_system && (funct3 != 3'b000);
    wire is_csr_reg_inst  = is_csr_inst && (funct3[2] == 1'b0);
    wire[11:0] csr_addr = i_inst_data[31:20];
    wire[4:0]  csr_zimm = i_inst_data[19:15];
    wire[`DataBus] csr_zimm_data    = {27'b0, csr_zimm};

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

    always @(*) begin
        o_reg1_rd_addr      = rs1;
        o_reg2_rd_addr      = rs2;
        
        o_csr_rd_addr       = csr_addr;
        o_inst_data         = i_inst_data;
        o_pc_addr           = i_pc_addr;
        o_reg1_data         = i_reg1_rd_data;
        o_reg1_addr         = rs1;
        o_reg2_data         = i_reg2_rd_data;
        o_reg2_addr         = rs2;
        o_regd_addr         = rd;
        o_imm_data          = imm;

        o_csr_wr_addr       = csr_addr;
        o_csr_data          = i_csr_rd_data;
        o_csr_zimm_data     = csr_zimm_data;
        o_csr_op            = funct3;
    end

    // output logic
    always @(*) begin
        o_Reg_we        = `Disable;
        o_ALU_src_A     = `ALU_src_A_rs1;
        o_ALU_src_B     = `ALU_src_B_imm;
        o_ALU_op        = `ALU_op_add;
        o_Branch        = `Branch_none;
        o_MemtoReg_src  = `MemtoReg_src_ALU;
        o_Mem_we        = `Disable;
        o_Mem_re        = `Disable;
        o_Mem_op        = `Mem_op_word;
        o_csr_wr_en     = `Disable;
        o_trap_cause    = `trap_none;
        case (opcode)
            `OPCODE_SYSTEM: begin
                o_ALU_src_A     = `ALU_src_A_rs1;   // don't care
                o_ALU_src_B     = `ALU_src_B_imm;   // don't care
                o_ALU_op        = `ALU_op_add;      // don't care
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
                if (funct3 != 3'b000) begin
                    o_Reg_we    = `Enable;
                    o_csr_wr_en = `Enable;
                end else begin
                    case (i_inst_data[31:20])
                        `funct12_ecall:  o_trap_cause = `trap_ecall;
                        `funct12_ebreak: o_trap_cause = `trap_ebreak;
                        `funct12_mret:   o_trap_cause = `trap_mret;
                        default:         o_trap_cause = `trap_none;
                    endcase
                end
            end
            `U_OPCODE_LUI: begin        // LUI, U-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_rs1;    // don't care
                o_ALU_src_B     = `ALU_src_B_imm;
                o_ALU_op        = `ALU_op_lui;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
            end
            `U_OPCODE_AUIPC: begin      // AUIPC, U-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_pc;
                o_ALU_src_B     = `ALU_src_B_imm;
                o_ALU_op        = `ALU_op_add;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
            end
            `I_OPCODE_OP_IMM: begin     // I-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_rs1;
                o_ALU_src_B     = `ALU_src_B_imm;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
                case (funct3)
                    `funct3_addi: begin
                        o_ALU_op = `ALU_op_add;
                    end
                    `funct3_slti: begin
                        o_ALU_op = `ALU_op_slt;
                    end
                    `funct3_sltiu: begin
                        o_ALU_op = `ALU_op_sltu;
                    end
                    `funct3_xori: begin
                        o_ALU_op = `ALU_op_xor;
                    end
                    `funct3_ori: begin
                        o_ALU_op = `ALU_op_or;
                    end
                    `funct3_andi: begin
                        o_ALU_op = `ALU_op_and;
                    end
                    `funct3_slli: begin
                        o_ALU_op = `ALU_op_sll;
                    end
                    `funct3_srli_srai: begin
                        o_ALU_op = (funct7[5] == 1'b0) ? `ALU_op_srl : `ALU_op_sra;
                    end
                    default: begin
                        o_ALU_op = `ALU_op_add;
                    end
                endcase
            end
            `R_OPCODE: begin            // R-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_rs1;
                o_ALU_src_B     = `ALU_src_B_rs2;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
                if (funct7 == `funct7_mul_div) begin        // rv32IM instructions
                    case (funct3)
                        `funct3_mul: begin
                            o_ALU_op = `ALU_op_mul;
                        end 
                        `funct3_mulh: begin
                            o_ALU_op = `ALU_op_mulh;
                        end
                        `funct3_mulhsu: begin
                            o_ALU_op = `ALU_op_mulhsu;
                        end
                        `funct3_mulhu: begin
                            o_ALU_op = `ALU_op_mulhu;
                        end
                        `funct3_div: begin
                            o_ALU_op = `ALU_op_div;
                        end
                        `funct3_divu: begin
                            o_ALU_op = `ALU_op_divu;
                        end
                        `funct3_rem: begin
                            o_ALU_op = `ALU_op_rem;
                        end
                        `funct3_remu: begin
                            o_ALU_op = `ALU_op_remu;
                        end
                        default: begin
                            o_ALU_op = `ALU_op_mul;
                        end
                    endcase
                end
                else begin                  // rv32I instructions
                    case (funct3)
                        `funct3_add_sub: begin
                            o_ALU_op = (funct7[5] == 1'b0) ? `ALU_op_add : `ALU_op_sub;
                        end
                        `funct3_sll: begin
                            o_ALU_op = `ALU_op_sll;
                        end
                        `funct3_slt: begin
                            o_ALU_op = `ALU_op_slt;
                        end
                        `funct3_sltu: begin
                            o_ALU_op = `ALU_op_sltu;
                        end
                        `funct3_xor: begin
                            o_ALU_op = `ALU_op_xor;
                        end
                        `funct3_srl_sra: begin
                            o_ALU_op = (funct7[5] == 1'b0) ? `ALU_op_srl : `ALU_op_sra;
                        end
                        `funct3_or: begin
                            o_ALU_op = `ALU_op_or;
                        end
                        `funct3_and: begin
                            o_ALU_op = `ALU_op_and;
                        end
                        default: begin
                            o_ALU_op = `ALU_op_add;
                        end
                    endcase
                end
            end
            `J_OPCODE_JAL: begin        // Jump, J-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_pc;
                o_ALU_src_B     = `ALU_src_B_4;
                o_ALU_op        = `ALU_op_add;
                o_Branch        = `Branch_jump;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
            end
            `J_OPCODE_JALR: begin       // Jump, I-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_pc;
                o_ALU_src_B     = `ALU_src_B_4;
                o_ALU_op        = `ALU_op_add;
                o_Branch        = `Branch_reg_jump;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
            end
            `B_OPCODE: begin            // B-type
                o_Reg_we        = `Disable;
                o_ALU_src_A     = `ALU_src_A_rs1;
                o_ALU_src_B     = `ALU_src_B_rs2;
                o_MemtoReg_src  = `MemtoReg_src_ALU;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Disable;
                o_Mem_op        = `Mem_op_word;
                case (funct3)
                    `funct3_beq: begin
                        o_ALU_op = `ALU_op_slt;
                        o_Branch = `Branch_jump_eq;
                    end
                    `funct3_bne: begin
                        o_ALU_op = `ALU_op_slt;
                        o_Branch = `Branch_jump_ne;
                    end
                    `funct3_blt: begin
                        o_ALU_op = `ALU_op_slt;
                        o_Branch = `Branch_jump_l;
                    end
                    `funct3_bge: begin
                        o_ALU_op = `ALU_op_slt;
                        o_Branch = `Branch_jump_ge;
                    end
                    `funct3_bltu: begin
                        o_ALU_op = `ALU_op_sltu;
                        o_Branch = `Branch_jump_l;
                    end
                    `funct3_bgeu: begin
                        o_ALU_op = `ALU_op_sltu;
                        o_Branch = `Branch_jump_ge;
                    end
                    default: begin
                        o_ALU_op = `ALU_op_slt;
                        o_Branch = `Branch_jump_eq;
                    end
                endcase
            end
            `I_OPCODE_LOAD: begin       // Load, I-type
                o_Reg_we        = `Enable;
                o_ALU_src_A     = `ALU_src_A_rs1;
                o_ALU_src_B     = `ALU_src_B_imm;
                o_ALU_op        = `ALU_op_add;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_Mem;
                o_Mem_we        = `Disable;
                o_Mem_re        = `Enable;
                case (funct3)
                    `funct3_lb: begin
                        o_Mem_op = `Mem_op_byte;
                    end
                    `funct3_lh: begin
                        o_Mem_op = `Mem_op_half;
                    end
                    `funct3_lw: begin
                        o_Mem_op = `Mem_op_word;
                    end
                    `funct3_lbu: begin
                        o_Mem_op = `Mem_op_ubyte;
                    end
                    `funct3_lhu: begin
                        o_Mem_op = `Mem_op_uhalf;
                    end
                    default: begin
                        o_Mem_op = `Mem_op_word;
                    end
                endcase
            end
            `S_OPCODE_STORE: begin      // Store, S-type
                o_Reg_we        = `Disable;
                o_ALU_src_A     = `ALU_src_A_rs1;
                o_ALU_src_B     = `ALU_src_B_imm;
                o_ALU_op        = `ALU_op_add;
                o_Branch        = `Branch_none;
                o_MemtoReg_src  = `MemtoReg_src_Mem;
                o_Mem_we        = `Enable;
                o_Mem_re        = `Disable;
                case (funct3)
                    `funct3_sb: begin
                        o_Mem_op = `Mem_op_byte;
                    end
                    `funct3_sh: begin
                        o_Mem_op = `Mem_op_half;
                    end
                    `funct3_sw: begin
                        o_Mem_op = `Mem_op_word;
                    end
                    default: begin
                        o_Mem_op = `Mem_op_byte;
                    end
                endcase
            end
            default: begin
                o_Reg_we       = `Disable;
                o_ALU_src_A    = `ALU_src_A_rs1;
                o_ALU_src_B    = `ALU_src_B_imm;
                o_ALU_op       = `ALU_op_add;
                o_Branch       = `Branch_none;
                o_MemtoReg_src = `MemtoReg_src_ALU;
                o_Mem_we       = `Disable;
                o_Mem_re       = `Disable;
                o_Mem_op       = `Mem_op_word;
            end
        endcase
    end

    // load use detection
    wire uses_rs1 = (opcode == `R_OPCODE) ||
                (opcode == `I_OPCODE_OP_IMM) ||
                (opcode == `I_OPCODE_LOAD) ||
                (opcode == `S_OPCODE_STORE) ||
                (opcode == `B_OPCODE) ||
                (opcode == `J_OPCODE_JALR) ||
                is_csr_reg_inst;
    wire uses_rs2 = (opcode == `R_OPCODE) ||
                (opcode == `S_OPCODE_STORE) ||
                (opcode == `B_OPCODE);
    wire ex_is_load = i_id_ex_Mem_re && i_id_ex_Reg_we && (i_id_ex_regd_addr != `Reg0Addr);
    always @(*) begin
        o_id_load_use = ex_is_load &&
                        ((uses_rs1 && (i_id_ex_regd_addr == rs1)) ||
                        (uses_rs2 && (i_id_ex_regd_addr == rs2)));
    end

endmodule
