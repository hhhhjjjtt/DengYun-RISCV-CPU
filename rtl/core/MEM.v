`include "../defines.v"

module MEM (
    // from EX_MEM
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`DataBus]        i_inst_data,
    input wire                  i_wb_src,
    input wire                  i_regd_we,
    input wire[`RegsAddrBus]    i_regd_addr,
    input wire[`DataBus]        i_regd_data,
    input wire                  i_mem_we,
    input wire                  i_mem_re,
    input wire[`DataAddrBus]    i_mem_addr,
    input wire[`DataBus]        i_mem_wr_data_raw,
    input wire[`MemOpTypeBus]   i_mem_op_type,

    // I/O with data memory
    output reg                  o_dcache_en,    // to d_cache
    output reg                  o_mmio_en,      // to mmio_port
    output reg                  o_dmem_valid,
    input wire                  i_dmem_ready,
    // I/O with data memory, read
    output reg                  o_dmem_rd_en,
    output reg[`DataAddrBus]    o_dmem_rd_addr,
    input wire[`DataBus]        i_dmem_rd_data,
    // I/O with data memory, write
    output reg                  o_dmem_wr_en,           // write enable
    output reg[`StrbBus]        o_dmem_wr_strb,         // write strobe
    output reg[`DataAddrBus]    o_dmem_wr_addr,     // write address
    output reg[`DataBus]        o_dmem_wr_data,         // write data

    // to Ctrl_Unit 
    output reg                  o_mem_stall,
    
    // to MEM_WB
    output reg                  o_regd_we,
    output reg[`RegsAddrBus]    o_regd_addr,
    output reg[`DataBus]        o_regd_data
);

    wire[31:0] rd_shift_b = i_dmem_rd_data >> ({i_mem_addr[1:0], 3'b000});
    wire[31:0] rd_shift_h = i_dmem_rd_data >> ({i_mem_addr[1],   4'b0000});

    // I/O with data memory
    wire do_dmem_req = i_mem_re || i_mem_we;
    always @(*) begin
        o_dmem_valid = do_dmem_req;
        o_mem_stall  = do_dmem_req & ~i_dmem_ready;
    end

    always @(*) begin
        o_dmem_rd_addr      = i_mem_addr;
        o_dmem_rd_en        = i_mem_re;
        
        o_dmem_wr_en        = i_mem_we;
        o_dmem_wr_strb      = 4'b0000;
        o_dmem_wr_addr      = i_mem_addr;
        o_dmem_wr_data      = i_mem_wr_data_raw;

        o_regd_we           = i_regd_we;
        o_regd_addr         = i_regd_addr;
        o_regd_data         = i_regd_data;

        if (i_mem_we) begin
            case (i_mem_op_type)
                `Mem_op_byte: begin
                    o_dmem_wr_strb = 4'b0001 << i_mem_addr[1:0];
                    o_dmem_wr_data = i_mem_wr_data_raw << ({i_mem_addr[1:0], 3'b000});
                end
                `Mem_op_half: begin
                    o_dmem_wr_strb = 4'b0011 << {i_mem_addr[1], 1'b0};
                    o_dmem_wr_data = i_mem_wr_data_raw << ({i_mem_addr[1], 4'b0000});
                end
                `Mem_op_word: begin
                    o_dmem_wr_strb = 4'b1111;
                    o_dmem_wr_data = i_mem_wr_data_raw;
                end
                default: begin
                    o_dmem_wr_strb = 4'b0000;
                    o_dmem_wr_data = i_mem_wr_data_raw;
                end
            endcase        
        end

        if (i_wb_src == `WB_src_MEM) begin
            case (i_mem_op_type)
                `Mem_op_byte: begin
                    o_regd_data = {{24{rd_shift_b[7]}}, rd_shift_b[7:0]};
                end
                `Mem_op_half: begin
                    o_regd_data = {{16{rd_shift_h[15]}}, rd_shift_h[15:0]};
                end
                `Mem_op_word: begin
                    o_regd_data = i_dmem_rd_data;
                end
                `Mem_op_ubyte: begin
                    o_regd_data = {24'b0, rd_shift_b[7:0]};
                end
                `Mem_op_uhalf: begin
                    o_regd_data = {16'b0, rd_shift_h[15:0]};
                end
                default: begin
                    o_regd_data = i_dmem_rd_data;
                end
            endcase
        end

        o_dcache_en = `Disable;
        o_mmio_en   = `Disable;
        if (o_dmem_rd_en) begin
            if (i_mem_addr >= `RAM_BASE && i_mem_addr < `RAM_BASE + `RAM_SIZE) begin
                o_dcache_en = `Enable;
            end
            else if (i_mem_addr >= `RAM_BASE + `RAM_SIZE) begin
                o_mmio_en   = `Enable;
            end
        end
        else if (o_dmem_wr_en) begin
            if (i_mem_addr >= `RAM_BASE && i_mem_addr < `RAM_BASE + `RAM_SIZE) begin
                o_dcache_en = `Enable;
            end
            else if (i_mem_addr >= `RAM_BASE + `RAM_SIZE) begin
                o_mmio_en   = `Enable;
            end
        end
    end

endmodule
