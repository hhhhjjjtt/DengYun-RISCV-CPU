`include "../defines.v"

module Regs (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from WB
    input wire                  i_wr_en,        // write enable
    input wire[`RegsAddrBus]    i_wr_addr,      // write addr 1
    input wire[`DataBus]        i_wr_data,      // write data

    // from ID
    input wire[`RegsAddrBus]    i_rd_addr1,     // read addr 1
    input wire[`RegsAddrBus]    i_rd_addr2,     // read addr 2

    // to ID
    output reg[`DataBus]        o_rd_data1,     // read data 1
    output reg[`DataBus]        o_rd_data2      // read data 2    
);

    reg[`DataBus] regs[0:`RegsNum - 1];
    
    integer i;
    // write
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            for (i = 0; i < `RegsNum; i = i + 1) begin
                regs[i] <= `ZeroWord;
            end
        end
        else if ((i_wr_en) && (i_wr_addr != `Reg0Addr)) begin
            regs[i_wr_addr] <= i_wr_data;
        end
    end

    // read reg1
    always @(*) begin
        if (i_rd_addr1 == `Reg0Addr) begin
            o_rd_data1 = `ZeroWord;
        end
        else if ((i_wr_en) && (i_rd_addr1 == i_wr_addr)) begin
            o_rd_data1 = i_wr_data;
        end
        else begin
            o_rd_data1 = regs[i_rd_addr1];
        end
    end

    // read reg2
    always @(*) begin
        if (i_rd_addr2 == `Reg0Addr) begin
            o_rd_data2 = `ZeroWord;
        end
        else if ((i_wr_en) && (i_rd_addr2 == i_wr_addr)) begin
            o_rd_data2 = i_wr_data;
        end
        else begin
            o_rd_data2 = regs[i_rd_addr2];
        end
    end

endmodule
