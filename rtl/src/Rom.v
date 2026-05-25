`include "defines.v"

module Rom (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from Ctrl_Unit
    input wire                  i_imem_resp_accept,

    // I/O with IF
    input wire                  i_imem_valid,
    output reg                  o_imem_ready,
    // I/O with IF, read
    input wire                  i_imem_rd_en,
    input wire[`InstAddrBus]    i_imem_rd_addr,
    output reg[`DataBus]        o_imem_rd_data
);

    reg[`DataBus] roms[0:`InstAddrDepth - 1];

    // initialize
    integer i;
    initial begin
        for (i = 0; i < `InstAddrDepth; i = i + 1) begin
            roms[i] = `NOP;
        end
    end

    // read
    reg resp_valid;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_imem_rd_data <= `ZeroWord;
            resp_valid     <= `Disable;
        end
        else begin
            if (resp_valid) begin
                if (i_imem_resp_accept) begin
                    resp_valid <= `Disable;
                end
            end
            else if (i_imem_valid && i_imem_rd_en) begin
                o_imem_rd_data <= roms[i_imem_rd_addr[13:2]];
                resp_valid     <= `Enable;
            end
        end
    end

    always @(*) begin
        o_imem_ready = resp_valid;
    end

endmodule
