`include "defines.v"

module Ram (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from Ctrl_Unit
    input wire                  i_dmem_resp_accept,

    // I/O with MEM
    input wire                  i_dmem_valid,
    output reg                  o_dmem_ready,
    // I/O with MEM, read
    input wire                  i_dmem_rd_en,
    input wire[`DataAddrBus]    i_dmem_rd_addr,
    output reg[`DataBus]        o_dmem_rd_data,
    // I/O with MEM, write
    input wire                  i_dmem_wr_en,       // write enable
    input wire[`StrbBus]        i_dmem_wr_strb,     // write strobe
    input wire[`DataAddrBus]    i_dmem_wr_addr,     // write address
    input wire[`DataBus]        i_dmem_wr_data      // write data
);

    reg[`DataBus] rams[0:`DataAddrDepth - 1];

    // initialize
    integer i;
    initial begin
        for (i = 0; i < `DataAddrDepth; i = i + 1) begin
            rams[i] = `ZeroWord;
        end
    end

    // read / write
    reg resp_valid;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_dmem_rd_data  <= `ZeroWord;
            resp_valid      <= `Disable;
        end
        else begin
            if (resp_valid) begin
                if (i_dmem_resp_accept) begin
                    resp_valid  <= `Disable;
                end
            end
            else if (i_dmem_valid) begin
                if (i_dmem_rd_en) begin
                    o_dmem_rd_data  <= rams[i_dmem_rd_addr[13:2]];
                    resp_valid      <= `Enable;
                end
                else if (i_dmem_wr_en) begin
                    if (i_dmem_wr_strb[0]) begin
                        rams[i_dmem_wr_addr[13:2]][7:0]     <= i_dmem_wr_data[7:0];
                    end
                    if (i_dmem_wr_strb[1]) begin
                        rams[i_dmem_wr_addr[13:2]][15:8]    <= i_dmem_wr_data[15:8];
                    end
                    if (i_dmem_wr_strb[2]) begin
                        rams[i_dmem_wr_addr[13:2]][23:16]   <= i_dmem_wr_data[23:16];
                    end
                    if (i_dmem_wr_strb[3]) begin
                        rams[i_dmem_wr_addr[13:2]][31:24]   <= i_dmem_wr_data[31:24];
                    end
                    resp_valid <= `Enable;
                end
            end
        end
    end

    always @(*) begin
        o_dmem_ready = resp_valid;
    end

endmodule
