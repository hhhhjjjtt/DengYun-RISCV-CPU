`include "defines.v"

module dmem_decoder (
    input wire[`DataAddrBus]    i_dmem_rd_addr_raw,
    output wire[`DataAddrBus]   o_dmem_rd_addr,

    input wire[`DataAddrBus]    i_dmem_wr_addr_raw,
    output wire[`DataAddrBus]   o_dmem_wr_addr
);
    
    assign o_dmem_rd_addr = i_dmem_rd_addr_raw - `RAM_base;
    assign o_dmem_wr_addr = i_dmem_wr_addr_raw - `RAM_base;

endmodule
