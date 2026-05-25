`include "defines.v"

module ID_EX (
    input wire                  i_Clk,
    input wire                  i_reset,

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

    input wire[`TrapCauseBus]   i_trap_cause,

    // from Ctrl_Unit
    input wire[`CtrlTypeBus]    i_ctrl_flag,

    // to EX
    output reg[`InstAddrBus]    o_pc_addr,    
    output reg[`DataBus]        o_inst_data,  
    output reg[`DataBus]        o_reg1_data,  
    output reg[`RegsAddrBus]    o_reg1_addr,
    output reg[`DataBus]        o_reg2_data,  
    output reg[`RegsAddrBus]    o_reg2_addr,
    output reg[`RegsAddrBus]    o_regd_addr,  
    output reg[`DataBus]        o_imm_data,   

    output reg                  o_Reg_we,
    output reg                  o_ALU_src_A,
    output reg[1:0]             o_ALU_src_B,
    output reg[4:0]             o_ALU_op,
    output reg[2:0]             o_Branch,
    output reg                  o_MemtoReg_src,
    output reg                  o_Mem_we,
    output reg                  o_Mem_re,
    output reg[2:0]             o_Mem_op,

    output reg[2:0]             o_csr_op,
    output reg                  o_csr_wr_en,
	output reg[`CSRAddrBus]     o_csr_wr_addr,
    output reg[`DataBus]        o_csr_data,
    output reg[`DataBus]        o_csr_zimm_data,

    output reg[`TrapCauseBus]   o_trap_cause,

    // forward to ID
    output reg                  o_id_ex_Mem_re,
    output reg                  o_id_ex_Reg_we,
    output reg[`RegsAddrBus]    o_id_ex_regd_addr
);
    
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc_addr           <= `ZeroAddr;
            o_inst_data         <= `NOP;
            o_reg1_data         <= `ZeroWord;
            o_reg1_addr         <= `Reg0Addr;
            o_reg2_data         <= `ZeroWord;
            o_reg2_addr         <= `Reg0Addr;
            o_regd_addr         <= `Reg0Addr;
            o_imm_data          <= `ZeroWord;

            o_Reg_we            <= `Disable;
            o_ALU_src_A         <= `ALU_src_A_rs1;
            o_ALU_src_B         <= `ALU_src_B_rs2;
            o_ALU_op            <= `ALU_op_add;
            o_Branch            <= `Branch_none;
            o_MemtoReg_src      <= `MemtoReg_src_ALU;
            o_Mem_we            <= `Disable;
            o_Mem_re            <= `Disable;
            o_Mem_op            <= `Mem_op_word;

            o_csr_op            <= 3'b000;
            o_csr_wr_en         <= `Disable;
            o_csr_wr_addr       <= `Reg0Addr;
            o_csr_data          <= `ZeroWord;
            o_csr_zimm_data     <= `ZeroWord;
            o_trap_cause        <= `trap_none;

            o_id_ex_Mem_re      <= `Disable;
            o_id_ex_Reg_we      <= `Disable;
            o_id_ex_regd_addr   <= `Reg0Addr;
        end
        else begin
            case (i_ctrl_flag)
                `ctrl_none: begin
                    o_pc_addr           <= i_pc_addr;
                    o_inst_data         <= i_inst_data;
                    o_reg1_data         <= i_reg1_data;
                    o_reg1_addr         <= i_reg1_addr;
                    o_reg2_data         <= i_reg2_data;
                    o_reg2_addr         <= i_reg2_addr;
                    o_regd_addr         <= i_regd_addr;
                    o_imm_data          <= i_imm_data;

                    o_Reg_we            <= i_Reg_we;
                    o_ALU_src_A         <= i_ALU_src_A;
                    o_ALU_src_B         <= i_ALU_src_B;
                    o_ALU_op            <= i_ALU_op;
                    o_Branch            <= i_Branch;
                    o_MemtoReg_src      <= i_MemtoReg_src;
                    o_Mem_we            <= i_Mem_we;
                    o_Mem_re            <= i_Mem_re;
                    o_Mem_op            <= i_Mem_op;

                    o_csr_op            <= i_csr_op;
                    o_csr_wr_en         <= i_csr_wr_en;
                    o_csr_wr_addr       <= i_csr_wr_addr;
                    o_csr_data          <= i_csr_data;
                    o_csr_zimm_data     <= i_csr_zimm_data;
                    o_trap_cause        <= i_trap_cause;

                    o_id_ex_Mem_re      <= i_Mem_re;
                    o_id_ex_Reg_we      <= i_Reg_we;
                    o_id_ex_regd_addr   <= i_regd_addr;
                end
                `ctrl_stall: begin
                    o_pc_addr           <= o_pc_addr;
                    o_inst_data         <= o_inst_data;
                    o_reg1_data         <= o_reg1_data;
                    o_reg1_addr         <= o_reg1_addr;
                    o_reg2_data         <= o_reg2_data;
                    o_reg2_addr         <= o_reg2_addr;
                    o_regd_addr         <= o_regd_addr;
                    o_imm_data          <= o_imm_data;

                    o_Reg_we            <= o_Reg_we;
                    o_ALU_src_A         <= o_ALU_src_A;
                    o_ALU_src_B         <= o_ALU_src_B;
                    o_ALU_op            <= o_ALU_op;
                    o_Branch            <= o_Branch;
                    o_MemtoReg_src      <= o_MemtoReg_src;
                    o_Mem_we            <= o_Mem_we;
                    o_Mem_re            <= o_Mem_re;
                    o_Mem_op            <= o_Mem_op;

                    o_csr_op            <= o_csr_op;
                    o_csr_wr_en         <= o_csr_wr_en;
                    o_csr_wr_addr       <= o_csr_wr_addr;
                    o_csr_data          <= o_csr_data;
                    o_csr_zimm_data     <= o_csr_zimm_data;
                    o_trap_cause        <= o_trap_cause;

                    o_id_ex_Mem_re      <= o_id_ex_Mem_re;
                    o_id_ex_Reg_we      <= o_id_ex_Reg_we;
                    o_id_ex_regd_addr   <= o_id_ex_regd_addr;
                end
                `ctrl_flush: begin
                    o_pc_addr           <= `ZeroAddr;
                    o_inst_data         <= `NOP;
                    o_reg1_data         <= `ZeroWord;
                    o_reg1_addr         <= `Reg0Addr;
                    o_reg2_data         <= `ZeroWord;
                    o_reg2_addr         <= `Reg0Addr;
                    o_regd_addr         <= `Reg0Addr;
                    o_imm_data          <= `ZeroWord;

                    o_Reg_we            <= `Disable;
                    o_ALU_src_A         <= `ALU_src_A_rs1;
                    o_ALU_src_B         <= `ALU_src_B_rs2;
                    o_ALU_op            <= `ALU_op_add;
                    o_Branch            <= `Branch_none;
                    o_MemtoReg_src      <= `MemtoReg_src_ALU;
                    o_Mem_we            <= `Disable;
                    o_Mem_re            <= `Disable;
                    o_Mem_op            <= `Mem_op_word;

                    o_csr_op            <= 3'b000;
                    o_csr_wr_en         <= `Disable;
                    o_csr_wr_addr       <= `Reg0Addr;
                    o_csr_data          <= `ZeroWord;
                    o_csr_zimm_data     <= `ZeroWord;
                    o_trap_cause        <= `trap_none;

                    o_id_ex_Mem_re      <= `Disable;
                    o_id_ex_Reg_we      <= `Disable;
                    o_id_ex_regd_addr   <= `Reg0Addr;
                end
                default: begin
                    o_pc_addr           <= i_pc_addr;
                    o_inst_data         <= i_inst_data;
                    o_reg1_data         <= i_reg1_data;
                    o_reg1_addr         <= i_reg1_addr;
                    o_reg2_data         <= i_reg2_data;
                    o_reg2_addr         <= i_reg2_addr;
                    o_regd_addr         <= i_regd_addr;
                    o_imm_data          <= i_imm_data;

                    o_Reg_we            <= i_Reg_we;
                    o_ALU_src_A         <= i_ALU_src_A;
                    o_ALU_src_B         <= i_ALU_src_B;
                    o_ALU_op            <= i_ALU_op;
                    o_Branch            <= i_Branch;
                    o_MemtoReg_src      <= i_MemtoReg_src;
                    o_Mem_we            <= i_Mem_we;
                    o_Mem_re            <= i_Mem_re;
                    o_Mem_op            <= i_Mem_op;

                    o_csr_op            <= i_csr_op;
                    o_csr_wr_en         <= i_csr_wr_en;
                    o_csr_wr_addr       <= i_csr_wr_addr;
                    o_csr_data          <= i_csr_data;
                    o_csr_zimm_data     <= i_csr_zimm_data;
                    o_trap_cause        <= i_trap_cause;

                    o_id_ex_Mem_re      <= i_Mem_re;
                    o_id_ex_Reg_we      <= i_Reg_we;
                    o_id_ex_regd_addr   <= i_regd_addr;
                end
            endcase
        end
    end
endmodule
