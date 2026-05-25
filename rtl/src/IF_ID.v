`include "defines.v"

module IF_ID (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from IF
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`DataBus]        i_inst_data,

    // from Ctrl_Unit
    input wire[`CtrlTypeBus]    i_ctrl_flag,

    // to ID
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data
);

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc_addr <= `ZeroAddr;
            o_inst_data <= `NOP;
        end
        else begin
            case (i_ctrl_flag)
                `ctrl_none: begin
                    o_pc_addr <= i_pc_addr;
                    o_inst_data <= i_inst_data;
                end
                `ctrl_stall: begin
                    o_pc_addr <= o_pc_addr;
                    o_inst_data <= o_inst_data;
                end
                `ctrl_flush: begin
                    o_pc_addr <= `ZeroAddr;
                    o_inst_data <= `NOP;
                end
                default: begin
                    o_pc_addr <= i_pc_addr;
                    o_inst_data <= i_inst_data;
                end
            endcase
        end
    end
    
endmodule
