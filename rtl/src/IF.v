`include "defines.v"

module IF (
    // from PC
    input wire[`InstAddrBus]    i_pc_addr,
    
    // I/O with instruction memory
    output reg                  o_imem_valid,
    input wire                  i_imem_ready,
    // I/O with instruction memory, read
    output reg[`InstAddrBus]    o_imem_rd_addr,
    input wire[`DataBus]        i_imem_rd_data,

    // to Ctrl_Unit
    output reg                  o_if_stall,

    // to IF_ID
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data
);

    always @(*) begin
        o_imem_valid = `Enable;
        o_if_stall   = ~i_imem_ready;
    end

    always @(*) begin
        o_imem_rd_addr      = i_pc_addr;
        
        o_pc_addr           = i_pc_addr;
        o_inst_data         = i_imem_rd_data;
    end

endmodule
