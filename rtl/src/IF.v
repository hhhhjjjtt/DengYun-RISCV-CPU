`include "defines.v"

module IF (
    // from pc
    input wire[`InstAddrBus]    i_pc_addr,
    
    // I/O with inst memory, request
    output reg                  o_imem_req_valid,
    input wire                  i_imem_req_ready,
    // I/O with inst memory, response
    output reg                  o_imem_resp_ready,
    input wire                  i_imem_resp_valid,
    // I/O with inst memory, read
    output reg                  o_imem_req_rd_en,
    output reg[`InstAddrBus]    o_imem_req_rd_addr,
    input wire[`DataBus]        i_imem_resp_rd_data,

    // to ctrl
    output reg                  o_if_stall,

    // to if_id
    output reg[`InstAddrBus]    o_pc_addr,
    output reg[`DataBus]        o_inst_data
);
    
    wire do_dmem_req = 1'b1;

    always @(*) begin
        o_imem_req_valid    = 1'b1;
        o_imem_resp_ready   = 1'b1;
        
        o_imem_req_rd_en    = 1'b1;
        o_imem_req_rd_addr  = i_pc_addr;

        o_if_stall          = !i_imem_req_ready || !i_imem_resp_valid;   
        
        o_pc_addr = i_pc_addr;
        o_inst_data = i_imem_resp_rd_data;
    end

endmodule
