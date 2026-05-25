`include "defines.v"

module EX_MEM (
    input wire                  i_Clk,
    input wire                  i_reset,
    
    // from EX
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`DataBus]        i_inst_data,
    input wire                  i_wb_src,
    input wire                  i_regd_we,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_regd_data,
    input wire                  i_mem_we,
    input wire                  i_mem_re,
    input wire[`DataAddrBus]    i_mem_addr,
    input wire[`DataBus]        i_mem_wr_data_raw,
    input wire[`MemOpTypeBus]   i_mem_op_type,

    // from Ctrl_Unit
    input wire[`CtrlTypeBus]    i_ctrl_flag,

    // to MEM
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data,
    output reg                  o_wb_src,
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data,
    output reg                  o_mem_we,
    output reg                  o_mem_re,
    output reg[`DataAddrBus]    o_mem_addr,
    output reg[`DataBus]        o_mem_wr_data_raw,
    output reg[`MemOpTypeBus]   o_mem_op_type,

    // forward to EX
    output reg                  o_ex_mem_regd_we,
    output reg[`RegsAddrBus]    o_ex_mem_regd_addr,
    output reg[`DataBus]        o_ex_mem_regd_data
);
    
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc_addr           <= `ZeroAddr;
            o_inst_data         <= `NOP;
            o_wb_src            <= `WB_src_ALU;
            o_regd_we           <= `WriteDisable;
            o_regd_addr         <= `Reg0Addr;
            o_regd_data         <= `ZeroWord;
            o_mem_we            <= `WriteDisable;
            o_mem_re            <= `ReadDisable;
            o_mem_addr          <= `ZeroAddr;
            o_mem_wr_data_raw   <= `ZeroWord;
            o_mem_op_type       <= `Mem_op_word;
            o_ex_mem_regd_we    <= `WriteDisable;
            o_ex_mem_regd_addr  <= `Reg0Addr;
            o_ex_mem_regd_data  <= `ZeroWord;
        end
        else begin
            case (i_ctrl_flag)
                `ctrl_none: begin
                    o_pc_addr           <= i_pc_addr;
                    o_inst_data         <= i_inst_data;
                    o_wb_src            <= i_wb_src;
                    o_regd_we           <= i_regd_we;
                    o_regd_addr         <= i_regd_addr;
                    o_regd_data         <= i_regd_data;
                    o_mem_we            <= i_mem_we;
                    o_mem_re            <= i_mem_re;
                    o_mem_addr          <= i_mem_addr;
                    o_mem_wr_data_raw   <= i_mem_wr_data_raw;
                    o_mem_op_type       <= i_mem_op_type;
                    o_ex_mem_regd_we    <= i_regd_we && (i_wb_src == `WB_src_ALU);
                    o_ex_mem_regd_addr  <= i_regd_addr;
                    o_ex_mem_regd_data  <= i_regd_data;
                end
                `ctrl_stall: begin
                    o_pc_addr           <= o_pc_addr;
                    o_inst_data         <= o_inst_data;
                    o_wb_src            <= o_wb_src;
                    o_regd_we           <= o_regd_we;
                    o_regd_addr         <= o_regd_addr;
                    o_regd_data         <= o_regd_data;
                    o_mem_we            <= o_mem_we;
                    o_mem_re            <= o_mem_re;
                    o_mem_addr          <= o_mem_addr;
                    o_mem_wr_data_raw   <= o_mem_wr_data_raw;
                    o_mem_op_type       <= o_mem_op_type;
                    o_ex_mem_regd_we    <= o_ex_mem_regd_we;
                    o_ex_mem_regd_addr  <= o_ex_mem_regd_addr;
                    o_ex_mem_regd_data  <= o_ex_mem_regd_data;
                end
                `ctrl_flush: begin
                    o_pc_addr           <= `ZeroAddr;
                    o_inst_data         <= `NOP;
                    o_wb_src            <= `WB_src_ALU;
                    o_regd_we           <= `WriteDisable;
                    o_regd_addr         <= `Reg0Addr;
                    o_regd_data         <= `ZeroWord;
                    o_mem_we            <= `WriteDisable;
                    o_mem_re            <= `ReadDisable;
                    o_mem_addr          <= `ZeroAddr;
                    o_mem_wr_data_raw   <= `ZeroWord;
                    o_mem_op_type       <= `Mem_op_word;
                    o_ex_mem_regd_we    <= `WriteDisable;
                    o_ex_mem_regd_addr  <= `Reg0Addr;
                    o_ex_mem_regd_data  <= `ZeroWord;
                end
                default: begin
                    o_pc_addr           <= i_pc_addr;
                    o_inst_data         <= i_inst_data;
                    o_wb_src            <= i_wb_src;
                    o_regd_we           <= i_regd_we;
                    o_regd_addr         <= i_regd_addr;
                    o_regd_data         <= i_regd_data;
                    o_mem_we            <= i_mem_we;
                    o_mem_re            <= i_mem_re;
                    o_mem_addr          <= i_mem_addr;
                    o_mem_wr_data_raw   <= i_mem_wr_data_raw;
                    o_mem_op_type       <= i_mem_op_type;
                    o_ex_mem_regd_we    <= i_regd_we && (i_wb_src == `WB_src_ALU);
                    o_ex_mem_regd_addr  <= i_regd_addr;
                    o_ex_mem_regd_data  <= i_regd_data;
                end
            endcase
        end
    end
    
endmodule
