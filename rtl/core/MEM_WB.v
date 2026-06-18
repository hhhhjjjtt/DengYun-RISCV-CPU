`include "../defines.v"

module MEM_WB (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from MEM
    input wire                  i_regd_we,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_regd_data,

    // from Ctrl_Unit
    input wire[`CtrlTypeBus]    i_mem_wb_ctrl,

    // to WB
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data,

    // forward to EX
    output reg                  o_mem_wb_regd_we,
    output reg[`RegsAddrBus]    o_mem_wb_regd_addr,
    output reg[`DataBus]        o_mem_wb_regd_data
);

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_regd_we           <= `Disable;
            o_regd_addr         <= `Reg0Addr;
            o_regd_data         <= `ZeroWord;
            o_mem_wb_regd_we    <= `Disable;
            o_mem_wb_regd_addr  <= `Reg0Addr;
            o_mem_wb_regd_data  <= `ZeroWord;
        end
        else begin
            if (i_mem_wb_ctrl == `ctrl_stall) begin
                o_regd_we           <= o_regd_we;
                o_regd_addr         <= o_regd_addr;
                o_regd_data         <= o_regd_data;
                o_mem_wb_regd_we    <= o_mem_wb_regd_we;
                o_mem_wb_regd_addr  <= o_mem_wb_regd_addr;
                o_mem_wb_regd_data  <= o_mem_wb_regd_data;
            end
            else begin
                o_regd_we           <= i_regd_we;
                o_regd_addr         <= i_regd_addr;
                o_regd_data         <= i_regd_data;
                o_mem_wb_regd_we    <= i_regd_we;
                o_mem_wb_regd_addr  <= i_regd_addr;
                o_mem_wb_regd_data  <= i_regd_data;
            end
        end
    end
    
endmodule
