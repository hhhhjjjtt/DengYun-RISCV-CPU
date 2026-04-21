`include "defines.v"

module rom_comb (
    input wire                  i_Clk,
    input wire                  i_reset,

    // I/O with if, request
    input wire                  i_imem_req_valid,
    output reg                  o_imem_req_ready, 
    // I/O with if, response
    input wire                  i_imem_resp_ready,
    output reg                  o_imem_resp_valid,
    // I/O with if, read
    input wire                  i_imem_req_rd_en,
    input wire[`InstAddrBus]    i_imem_req_rd_addr,
    output reg[`DataBus]        o_imem_resp_rd_data
);

    reg[`DataBus] roms[0:`InstAddrDepth - 1];

    // initialize
    integer i;
    initial begin
        for (i = 0; i < `InstAddrDepth; i = i + 1) begin
            roms[i] = `NOP;
        end
    end

    wire rd_resp_fire = i_imem_resp_ready && o_imem_resp_valid;

    // read
    always @ (*) begin
        if (i_reset) begin
            o_imem_req_ready    = 1'b0;
            o_imem_resp_valid   = 1'b0;
            o_imem_resp_rd_data = `ZeroWord;
        end
        else begin
            o_imem_req_ready    = 1'b1;
            o_imem_resp_valid   = 1'b1;
            o_imem_resp_rd_data = roms[i_imem_req_rd_addr[13:2]]; 
        end
    end    

endmodule
