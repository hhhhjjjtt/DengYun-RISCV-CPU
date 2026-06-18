`include "../defines.v"

// ---- mmio_port ----
// Uncached AXI master for peripheral (MMIO) accesses.
// Always single-beat: ARLEN=0, AWLEN=0, WLAST=1.

module MMIO_Port (
    input wire                  i_Clk,
    input wire                  i_reset,

    // CPU side — MEM (valid gated by cpu_top: dmem_valid && mmio_en)
    input wire                  i_dmem_valid,
    output reg                  o_dmem_ready,
    input wire                  i_dmem_rd_en,
    input wire[`DataAddrBus]    i_dmem_rd_addr,
    output reg[`DataBus]        o_dmem_rd_data,
    input wire                  i_dmem_wr_en,
    input wire[`StrbBus]        i_dmem_wr_strb,
    input wire[`DataAddrBus]    i_dmem_wr_addr,
    input wire[`DataBus]        i_dmem_wr_data,

    // AXI master — AR channel (single beat)
    output reg[31:0]            o_axi_araddr,
    output reg                  o_axi_arvalid,
    input wire                  i_axi_arready,
    output reg[7:0]             o_axi_arlen,    // hardwired 0
    output reg[2:0]             o_axi_arsize,   // hardwired 2 (4 bytes)
    output reg[1:0]             o_axi_arburst,  // hardwired 01 (INCR)

    // AXI master — R channel
    input wire[31:0]            i_axi_rdata,
    input wire                  i_axi_rvalid,
    output reg                  o_axi_rready,
    input wire                  i_axi_rlast,

    // AXI master — AW channel (single beat)
    output reg[31:0]            o_axi_awaddr,
    output reg                  o_axi_awvalid,
    input wire                  i_axi_awready,
    output reg[7:0]             o_axi_awlen,    // hardwired 0
    output reg[2:0]             o_axi_awsize,   // hardwired 2 (4 bytes)
    output reg[1:0]             o_axi_awburst,  // hardwired 01 (INCR)

    // AXI master — W channel (single beat, WLAST always 1)
    output reg[31:0]            o_axi_wdata,
    output reg                  o_axi_wvalid,
    input wire                  i_axi_wready,
    output reg                  o_axi_wlast,    // hardwired 1
    output reg[3:0]             o_axi_wstrb,

    // AXI master — B channel
    input wire[1:0]             i_axi_bresp,
    input wire                  i_axi_bvalid,
    output reg                  o_axi_bready
);

    // single-beat constants
    always @(*) begin
        o_axi_arlen   = 8'd0;
        o_axi_arsize  = 3'd2;
        o_axi_arburst = 2'b01;
        o_axi_awlen   = 8'd0;
        o_axi_awsize  = 3'd2;
        o_axi_awburst = 2'b01;
        o_axi_wlast   = 1'b1;
    end
    

    // ---- state machine ----
    localparam S_IDLE  = 2'd0;
    localparam S_READ  = 2'd1;
    localparam S_WRITE = 2'd2;
    localparam S_BWAIT = 2'd3;

    reg [1:0] state;

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= S_IDLE;
            o_axi_arvalid <= 1'b0;
            o_axi_rready  <= 1'b0;
            o_axi_awvalid <= 1'b0;
            o_axi_wvalid  <= 1'b0;
            o_axi_bready  <= 1'b0;
        end
        else begin
            case (state)

                S_IDLE: begin
                    if (i_dmem_valid && i_dmem_rd_en) begin
                        o_axi_araddr  <= i_dmem_rd_addr;
                        o_axi_arvalid <= 1'b1;
                        o_axi_rready  <= 1'b1;
                        state         <= S_READ;
                    end
                    else if (i_dmem_valid && i_dmem_wr_en) begin
                        o_axi_awaddr  <= i_dmem_wr_addr;
                        o_axi_awvalid <= 1'b1;
                        o_axi_wdata   <= i_dmem_wr_data;
                        o_axi_wstrb   <= i_dmem_wr_strb;
                        o_axi_wvalid  <= 1'b1;
                        state         <= S_WRITE;
                    end
                end

                // hold ARVALID until accepted; assert ready when data arrives
                S_READ: begin
                    if (o_axi_arvalid && i_axi_arready)
                        o_axi_arvalid <= 1'b0;
                    if (i_axi_rvalid) begin
                        o_axi_rready <= 1'b0;
                        state        <= S_IDLE;
                    end
                end

                // hold AWVALID/WVALID until accepted; then wait for B
                S_WRITE: begin
                    if (o_axi_awvalid && i_axi_awready)
                        o_axi_awvalid <= 1'b0;
                    if (o_axi_wvalid && i_axi_wready) begin
                        o_axi_wvalid <= 1'b0;
                        o_axi_bready <= 1'b1;
                        state        <= S_BWAIT;
                    end
                end

                S_BWAIT: begin
                    if (i_axi_bvalid) begin
                        o_axi_bready <= 1'b0;
                        state        <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ---- combinational output to MEM ----
    always @(*) begin
        o_dmem_ready   = 1'b0;
        o_dmem_rd_data = `ZeroWord;
        if (state == S_READ && i_axi_rvalid) begin
            o_dmem_ready   = 1'b1;
            o_dmem_rd_data = i_axi_rdata;
        end
        else if (state == S_BWAIT && i_axi_bvalid) begin
            o_dmem_ready   = 1'b1;
        end
    end

endmodule
