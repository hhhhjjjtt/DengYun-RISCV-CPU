`include "../defines.v"

module PC (
    input wire                  i_Clk,
    input wire                  i_reset,
    
    // from Ctrl_Unit
    input wire[`CtrlTypeBus]    i_pc_ctrl,      // ctrl flag
    input wire                  i_jump_flag,    // jump flag
    input wire[`InstAddrBus]    i_jump_addr,    // jump addr

    // to IF_ID
    output reg[`InstAddrBus]    o_pc_addr       // pc addr 
);

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc_addr <= `ZeroWord; 
        end
        else if (i_pc_ctrl == `ctrl_stall) begin
            o_pc_addr <= o_pc_addr;
        end
        else if (i_jump_flag) begin
            o_pc_addr <= i_jump_addr;
        end
        else begin
            o_pc_addr <= o_pc_addr + 4;
        end
    end

endmodule
