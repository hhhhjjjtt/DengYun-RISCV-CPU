`include "defines.v"

module ram_comb (
    input wire                  i_Clk,
    input wire                  i_reset,

    // I/O with mem, request
    input wire                  i_dmem_req_valid,
    output reg                  o_dmem_req_ready, 
    // I/O with mem, response
    input wire                  i_dmem_resp_ready,
    output reg                  o_dmem_resp_valid,
    // I/O with mem, read
    input wire                  i_dmem_rd_en,
    input wire[`DataAddrBus]    i_dmem_rd_addr,
    output reg[`DataBus]        o_dmem_rd_data,
    // I/O with mem, write
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

    wire req_fire = i_dmem_req_valid && o_dmem_req_ready;

    // write 
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            
        end
        else begin
            if (req_fire && i_dmem_wr_en) begin
                if (i_dmem_wr_strb[0]) begin
                    rams[i_dmem_wr_addr[13:2]][7:0] <= i_dmem_wr_data[7:0];
                end
                if (i_dmem_wr_strb[1]) begin
                    rams[i_dmem_wr_addr[13:2]][15:8] <= i_dmem_wr_data[15:8];
                end
                if (i_dmem_wr_strb[2]) begin
                    rams[i_dmem_wr_addr[13:2]][23:16] <= i_dmem_wr_data[23:16];
                end
                if (i_dmem_wr_strb[3]) begin
                    rams[i_dmem_wr_addr[13:2]][31:24] <= i_dmem_wr_data[31:24];
                end
            end
        end
    end

    // read
    always @ (*) begin
        if (i_reset) begin
            o_dmem_req_ready = 1'b0;
            o_dmem_resp_valid = 1'b0;
            o_dmem_rd_data = `ZeroWord;
        end
        else begin
            o_dmem_req_ready = 1'b1;
            o_dmem_resp_valid = i_dmem_req_valid && i_dmem_rd_en;
            o_dmem_rd_data = rams[i_dmem_rd_addr[13:2]]; 
        end
    end    

endmodule
