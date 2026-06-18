`include "../defines.v"

module EX (    
    // from ID_EX
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`DataBus]        i_inst_data,
    input wire[`DataBus]        i_reg1_data,
    input wire[`RegsAddrBus]    i_reg1_addr,
    input wire[`DataBus]        i_reg2_data,
    input wire[`RegsAddrBus]    i_reg2_addr,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_imm_data,

    input wire                  i_Reg_we,
    input wire                  i_ALU_src_A,
    input wire[1:0]             i_ALU_src_B,
    input wire[4:0]             i_ALU_op,
    input wire[2:0]             i_Branch,
    input wire                  i_MemtoReg_src,
    input wire                  i_Mem_we,
    input wire                  i_Mem_re,
    input wire[2:0]             i_Mem_op,

    input wire[2:0]             i_csr_op,
    input wire                  i_csr_wr_en,
	input wire[`CSRAddrBus]     i_csr_wr_addr,
    input wire[`DataBus]        i_csr_data,
    input wire[`DataBus]        i_csr_zimm_data,

    // forward from EX_MEM
    input wire                  i_ex_mem_regd_we,
    input wire[`RegsAddrBus]    i_ex_mem_regd_addr,
    input wire[`DataBus]        i_ex_mem_regd_data,
    
    // forward from MEM_WB
    input wire                  i_mem_wb_regd_we,
    input wire[`RegsAddrBus]    i_mem_wb_regd_addr,
    input wire[`DataBus]        i_mem_wb_regd_data,

    // I/O with Divider
    input wire[`DataBus]        i_quotient_data,
    input wire[`DataBus]        i_remainder_data,
    input wire                  i_div_ready,        // result ready
    output reg[`DataBus]        o_dividend_data,
    output reg[`DataBus]        o_divisor_data,
    output reg                  o_div_valid,        // division instruction vallid
    output reg                  o_div_signed,

    // to Regs_CSR
    output reg                  o_csr_wr_en,
	output reg[`CSRAddrBus]     o_csr_wr_addr,
	output reg[`DataBus]        o_csr_wr_data,

    // to EX_MEM
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data,
    output reg                  o_wb_src,       // which source to write to the destination register, from memory(1) or ALU(0)
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data,
    output reg                  o_mem_we,
    output reg                  o_mem_re,
    output reg[`DataAddrBus]    o_mem_addr,
    output reg[`DataBus]        o_mem_wr_data_raw,
    output reg[`MemOpTypeBus]   o_mem_op_type,

    // to Ctrl_unit
    output reg                  o_ex_branch,
    output reg                  o_ex_division_busy,
    output reg                  o_jump_flag,
    output reg[`InstAddrBus]    o_jump_addr
);

    wire ex_mem_writeReg1 = i_ex_mem_regd_we && 
                        (i_reg1_addr == i_ex_mem_regd_addr) && 
                        (i_ex_mem_regd_addr != `Reg0Addr);
    wire ex_mem_writeReg2 = i_ex_mem_regd_we && 
                        (i_reg2_addr == i_ex_mem_regd_addr) && 
                        (i_ex_mem_regd_addr != `Reg0Addr);
    
    wire mem_wb_writeReg1 = i_mem_wb_regd_we && 
                        (i_reg1_addr == i_mem_wb_regd_addr) && 
                        (i_mem_wb_regd_addr != `Reg0Addr);
    wire mem_wb_writeReg2 = i_mem_wb_regd_we && 
                        (i_reg2_addr == i_mem_wb_regd_addr) && 
                        (i_mem_wb_regd_addr != `Reg0Addr);

    wire ex_mem_forwardA = ex_mem_writeReg1 && (i_ALU_src_A == `ALU_src_A_rs1);
    wire ex_mem_forwardB = ex_mem_writeReg2 && (i_ALU_src_B == `ALU_src_B_rs2);

    wire mem_wb_forwardA = mem_wb_writeReg1 && (i_ALU_src_A == `ALU_src_A_rs1);
    wire mem_wb_forwardB = mem_wb_writeReg2 && (i_ALU_src_B == `ALU_src_B_rs2);

    wire store_data_forward_ex_mem = ex_mem_writeReg2 && i_Mem_we;
    wire store_data_forward_mem_wb = mem_wb_writeReg2 && i_Mem_we;

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
            case (i_ALU_src_A)
                `ALU_src_A_rs1: begin
                    alu_SRC_A = i_reg1_data;
                end
                `ALU_src_A_pc: begin
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
            case (i_ALU_src_B)
                `ALU_src_B_rs2: begin
                    alu_SRC_B = i_reg2_data;
                end
                `ALU_src_B_imm: begin
                    alu_SRC_B = i_imm_data;
                end
                `ALU_src_B_4: begin
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

    // multiply result
    wire signed[63:0]   mul_ss = $signed({{32{alu_SRC_A[31]}}, alu_SRC_A}) * $signed({{32{alu_SRC_B[31]}}, alu_SRC_B});
    wire signed[63:0]   mul_su = $signed({{32{alu_SRC_A[31]}}, alu_SRC_A}) * $signed({32'b0, alu_SRC_B});
    wire[63:0]          mul_uu = {32'b0, alu_SRC_A} * {32'b0, alu_SRC_B};

    // ALU Result
    reg[`DataBus] alu_result;
    always @(*) begin
        o_dividend_data     = `ZeroWord;
        o_divisor_data      = `ZeroWord;
        o_div_valid         = 1'b0;
        o_div_signed        = 1'b0;
        o_ex_division_busy  = 1'b0;
        case (i_ALU_op)
            `ALU_op_add: begin
                alu_result = alu_SRC_A + alu_SRC_B;
            end
            `ALU_op_sub: begin
                alu_result = alu_SRC_A - alu_SRC_B;
            end
            `ALU_op_slt: begin
                alu_result = $signed(alu_SRC_A) < $signed(alu_SRC_B) ? 32'd1 : 32'd0;
            end
            `ALU_op_sltu: begin
                alu_result = alu_SRC_A < alu_SRC_B ? 32'd1 : 32'd0;
            end
            `ALU_op_xor: begin
                alu_result = alu_SRC_A ^ alu_SRC_B;
            end
            `ALU_op_or: begin
                alu_result = alu_SRC_A | alu_SRC_B;
            end
            `ALU_op_and: begin
                alu_result = alu_SRC_A & alu_SRC_B;
            end
            `ALU_op_sll: begin
                alu_result = alu_SRC_A << alu_SRC_B[4:0];
            end
            `ALU_op_srl: begin
                alu_result = alu_SRC_A >> alu_SRC_B[4:0];
            end
            `ALU_op_sra: begin
                alu_result = $signed(alu_SRC_A) >>> alu_SRC_B[4:0];
            end
            `ALU_op_lui: begin
                alu_result = alu_SRC_B;
            end
            `ALU_op_mul: begin
                alu_result = mul_ss[31:0];
            end
            `ALU_op_mulh: begin
                alu_result = mul_ss[63:32];
            end
            `ALU_op_mulhsu: begin
                alu_result = mul_su[63:32];
            end
            `ALU_op_mulhu: begin
                alu_result = mul_uu[63:32];
            end
            `ALU_op_div: begin
                if (i_div_ready) begin
                    o_div_valid         = 1'b0;
                    alu_result          = i_quotient_data;
                    o_ex_division_busy  = 1'b0;
                end
                else begin
                    o_dividend_data     = alu_SRC_A;
                    o_divisor_data      = alu_SRC_B;
                    o_div_valid         = 1'b1;
                    o_div_signed        = 1'b1;
                    alu_result          = `ZeroWord;
                    o_ex_division_busy  = 1'b1;         // pipeline stall upon division
                end
            end
            `ALU_op_divu: begin
                if (i_div_ready) begin
                    o_div_valid         = 1'b0;
                    alu_result          = i_quotient_data;
                    o_ex_division_busy  = 1'b0;
                end
                else begin
                    o_dividend_data     = alu_SRC_A;
                    o_divisor_data      = alu_SRC_B;
                    o_div_valid         = 1'b1;
                    o_div_signed        = 1'b0;
                    alu_result          = `ZeroWord;
                    o_ex_division_busy  = 1'b1;
                end
            end
            `ALU_op_rem: begin
                if (i_div_ready) begin
                    o_div_valid         = 1'b0;
                    alu_result          = i_remainder_data;
                    o_ex_division_busy  = 1'b0;
                end
                else begin
                    o_dividend_data     = alu_SRC_A;
                    o_divisor_data      = alu_SRC_B;
                    o_div_valid         = 1'b1;
                    o_div_signed        = 1'b1;
                    alu_result          = `ZeroWord;
                    o_ex_division_busy  = 1'b1;
                end
            end
            `ALU_op_remu: begin
                if (i_div_ready) begin
                    o_div_valid         = 1'b0;
                    alu_result          = i_remainder_data;
                    o_ex_division_busy  = 1'b0;
                end
                else begin
                    o_dividend_data     = alu_SRC_A;
                    o_divisor_data      = alu_SRC_B;
                    o_div_valid         = 1'b1;
                    o_div_signed        = 1'b0;
                    alu_result          = `ZeroWord;
                    o_ex_division_busy  = 1'b1;
                end
            end
            default: begin
                alu_result = `ZeroWord;
            end
        endcase
    end

    // branch
    always @(*) begin
        case (i_Branch)
            `Branch_none: begin
                o_ex_branch = 1'b0;
                o_jump_flag = `JumpDisable;
                o_jump_addr = `ZeroAddr;
            end 
            `Branch_jump: begin
                o_ex_branch = 1'b1;
                o_jump_flag = `JumpEnable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `Branch_reg_jump: begin
                o_ex_branch = 1'b1;
                o_jump_flag = `JumpEnable;
                if (ex_mem_writeReg1) begin
                    o_jump_addr = (i_ex_mem_regd_data + i_imm_data) & ~32'd1;
                end
                else if (mem_wb_writeReg1) begin
                    o_jump_addr = (i_mem_wb_regd_data + i_imm_data) & ~32'd1;
                end
                else begin
                    o_jump_addr = (i_reg1_data + i_imm_data) & ~32'd1;
                end
            end 
            `Branch_jump_eq: begin
                o_ex_branch = equal_flag ? 1'b1 : 1'b0;
                o_jump_flag = equal_flag ? `JumpEnable : `JumpDisable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `Branch_jump_ne: begin
                o_ex_branch = equal_flag ? 1'b0 : 1'b1;
                o_jump_flag = equal_flag ? `JumpDisable : `JumpEnable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `Branch_jump_l: begin
                o_ex_branch = (alu_result == 1) ? 1'b1 : 1'b0;
                o_jump_flag = (alu_result == 1) ? `JumpEnable : `JumpDisable;
                o_jump_addr = i_pc_addr + i_imm_data;
            end 
            `Branch_jump_ge: begin
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
        o_pc_addr = i_pc_addr;
        o_inst_data = i_inst_data;
        
        // register writeback source
        o_wb_src = i_MemtoReg_src;

        // register write
        o_regd_we = i_Reg_we;
        o_regd_addr = i_regd_addr;
        if (i_csr_wr_en) begin
            o_regd_data = i_csr_data;
        end
        else begin
            o_regd_data = alu_result;
        end
        
        // memory write
        o_mem_we = i_Mem_we;
        o_mem_re = i_Mem_re;

        o_mem_op_type = i_Mem_op;
    end

    always @(*) begin
        if (i_Mem_we) begin
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

    // CSRRS/CSRRC must not write when rs1=x0; CSRRSI/CSRRCI must not write when zimm=0
    wire csr_wr_suppress =
        ((i_csr_op == `funct3_csrrs  || i_csr_op == `funct3_csrrc)  && (i_reg1_addr == 5'b0)) ||
        ((i_csr_op == `funct3_csrrsi || i_csr_op == `funct3_csrrci) && (i_csr_zimm_data == `ZeroWord));

    // Forward register rs1 for CSR write data (same hazard as ALU but separate mux)
    wire [`DataBus] fwd_reg1_data =
        ex_mem_writeReg1 ? i_ex_mem_regd_data :
        mem_wb_writeReg1 ? i_mem_wb_regd_data :
        i_reg1_data;

    // csr regs
    always @(*) begin
        o_csr_wr_en   = i_csr_wr_en && !csr_wr_suppress;
        o_csr_wr_addr = i_csr_wr_addr;
        case (i_csr_op)
            `funct3_csrrw: begin
                o_csr_wr_data = fwd_reg1_data;
            end
            `funct3_csrrs: begin
                o_csr_wr_data = i_csr_data | fwd_reg1_data;
            end
            `funct3_csrrc: begin
                o_csr_wr_data = i_csr_data & ~fwd_reg1_data;
            end
            `funct3_csrrwi: begin
                o_csr_wr_data = i_csr_zimm_data;
            end
            `funct3_csrrsi: begin
                o_csr_wr_data = i_csr_data | i_csr_zimm_data;
            end
            `funct3_csrrci: begin
                o_csr_wr_data = i_csr_data & ~i_csr_zimm_data;
            end
            default: begin
                o_csr_wr_data = `ZeroWord;
            end
        endcase
    end

endmodule
