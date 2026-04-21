`include "defines.v"

module ID_EX (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from id
    input wire[`InstAddrBus]    i_pc_addr,    
    input wire[`DataBus]        i_inst_data,  
    input wire[`DataBus]        i_reg1_data,  
    input wire[`RegsAddrBus]    i_reg1_addr,
    input wire[`DataBus]        i_reg2_data, 
    input wire[`RegsAddrBus]    i_reg2_addr, 
    input wire[`RegsAddrBus]    i_regd_addr,  
    input wire[`DataBus]        i_imm_data,   
    input wire[`CtrlBundleBus]  i_ctrl_bundle,

    // from ctrl
    input wire[`CtrlTypeBus]    i_ctrl_flag,

    // to ex
    output reg[`InstAddrBus]    o_pc_addr,    
    output reg[`DataBus]        o_inst_data,  
    output reg[`DataBus]        o_reg1_data,  
    output reg[`RegsAddrBus]    o_reg1_addr,
    output reg[`DataBus]        o_reg2_data,  
    output reg[`RegsAddrBus]    o_reg2_addr,
    output reg[`RegsAddrBus]    o_regd_addr,  
    output reg[`DataBus]        o_imm_data,   
    output reg[`CtrlBundleBus]  o_ctrl_bundle
);
    
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc_addr       <= `ZeroAddr;
            o_inst_data     <= `NOP;
            o_reg1_data     <= `ZeroWord;
            o_reg1_addr     <= `Reg0Addr;
            o_reg2_data     <= `ZeroWord;
            o_reg2_addr     <= `Reg0Addr;
            o_regd_addr     <= `Reg0Addr;
            o_imm_data      <= `ZeroWord;
            o_ctrl_bundle   <= `ZeroCtrlBundle;
        end
        else begin
            case (i_ctrl_flag)
                `ctrl_none: begin
                    o_pc_addr       <= i_pc_addr;
                    o_inst_data     <= i_inst_data;
                    o_reg1_data     <= i_reg1_data;
                    o_reg1_addr     <= i_reg1_addr;
                    o_reg2_data     <= i_reg2_data;
                    o_reg2_addr     <= i_reg2_addr;
                    o_regd_addr     <= i_regd_addr;
                    o_imm_data      <= i_imm_data;
                    o_ctrl_bundle   <= i_ctrl_bundle;
                end
                `ctrl_stall: begin
                    o_pc_addr       <= o_pc_addr;
                    o_inst_data     <= o_inst_data;
                    o_reg1_data     <= o_reg1_data;
                    o_reg1_addr     <= o_reg1_addr;
                    o_reg2_data     <= o_reg2_data;
                    o_reg2_addr     <= o_reg2_addr;
                    o_regd_addr     <= o_regd_addr;
                    o_imm_data      <= o_imm_data;
                    o_ctrl_bundle   <= o_ctrl_bundle;
                end
                `ctrl_flush: begin
                    o_pc_addr       <= `ZeroAddr;
                    o_inst_data     <= `NOP;
                    o_reg1_data     <= `ZeroWord;
                    o_reg1_addr     <= `Reg0Addr;
                    o_reg2_data     <= `ZeroWord;
                    o_reg2_addr     <= `Reg0Addr;
                    o_regd_addr     <= `Reg0Addr;
                    o_imm_data      <= `ZeroWord;
                    o_ctrl_bundle   <= `ZeroCtrlBundle;
                end
                default: begin
                    o_pc_addr       <= i_pc_addr;
                    o_inst_data     <= i_inst_data;
                    o_reg1_data     <= i_reg1_data;
                    o_reg1_addr     <= i_reg1_addr;
                    o_reg2_data     <= i_reg2_data;
                    o_reg2_addr     <= i_reg2_addr;
                    o_regd_addr     <= i_regd_addr;
                    o_imm_data      <= i_imm_data;
                    o_ctrl_bundle   <= i_ctrl_bundle;
                end
            endcase
        end
    end
endmodule
