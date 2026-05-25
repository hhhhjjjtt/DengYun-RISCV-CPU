`include "defines.v"

module WB (
    // from MEM_WB
    input wire                  i_regd_we,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_regd_data,

    // to Regs
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data
);

    always @(*) begin
        o_regd_we    = i_regd_we;
        o_regd_addr  = i_regd_addr;
        o_regd_data  = i_regd_data;
    end

endmodule
