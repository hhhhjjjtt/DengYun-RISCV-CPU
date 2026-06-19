`include "../defines.v"

module CLINT (
    input wire                          i_Clk,
    input wire                          i_reset,

    // AXI slave — AR channel
    input wire[31:0]                    i_axi_araddr,
    input wire                          i_axi_arvalid,
    output reg                          o_axi_arready,
    input wire[7:0]                     i_axi_arlen,        // unused
    input wire[2:0]                     i_axi_arsize,       // unused
    input wire[1:0]                     i_axi_arburst,      // unused
    // AXI slave — R channel
    output reg[31:0]                    o_axi_rdata,
    output reg                          o_axi_rvalid,
    input wire                          i_axi_rready,
    output reg                          o_axi_rlast,
    // AXI slave — AW channel
    input wire[31:0]                    i_axi_awaddr,
    input wire                          i_axi_awvalid,
    output reg                          o_axi_awready,
    input wire[7:0]                     i_axi_awlen,        // unused
    input wire[2:0]                     i_axi_awsize,       // unused
    input wire[1:0]                     i_axi_awburst,      // unused
    // AXI slave — W channel
    input wire[31:0]                    i_axi_wdata,
    input wire                          i_axi_wvalid,
    output reg                          o_axi_wready,
    input wire                          i_axi_wlast,        // unused
    input wire[3:0]                     i_axi_wstrb,        // unused
    // AXI slave — B channel
    output reg[1:0]                     o_axi_bresp,
    output reg                          o_axi_bvalid,
    input wire                          i_axi_bready,

    output wire                         o_timer_int_pending
);

    localparam OFFSET_MTIME     = 4'h0;
    localparam OFFSET_MTIMECMP  = 4'h4;

    reg[`DataBus]   reg_mtime;
    reg[`DataBus]   reg_mtimecmp;

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            reg_mtime           <= `ZeroWord;
        end
        else begin
            reg_mtime           <= reg_mtime + 1'b1;
        end
    end
    assign o_timer_int_pending = (reg_mtime >= reg_mtimecmp);

    // ---- AXI write path ----
    reg             aw_pending;
    reg[31:0]       aw_addr_latch;
    reg             w_pending;
    reg[`DataBus]   w_data_latch;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_axi_awready   <= `Disable;
            o_axi_wready    <= `Disable;
            o_axi_bresp     <= 2'b00;
            o_axi_bvalid    <= `Disable;
            reg_mtimecmp    <= 32'hFFFF_FFFF;
            aw_pending      <= `Disable;
            w_pending       <= `Disable;
        end
        else begin
            o_axi_awready   <= `Disable;
            o_axi_wready    <= `Disable;
            // Accept AW
            if (i_axi_awvalid && !aw_pending) begin
                o_axi_awready   <= `Enable;
                aw_pending      <= `Enable;
                aw_addr_latch   <= i_axi_awaddr;
            end
            // Accept W
            if (i_axi_wvalid && !w_pending) begin
                o_axi_wready    <= `Enable;
                w_pending       <= `Enable;
                w_data_latch    <= i_axi_wdata;
            end
            // Perform write once both AW and W are latched
            if (aw_pending && w_pending && !o_axi_bvalid) begin
                aw_pending      <= `Disable;
                w_pending       <= `Disable;
                o_axi_bvalid    <= `Enable;
                o_axi_bresp     <= 2'b00;
                if (aw_addr_latch[3:0] == OFFSET_MTIMECMP) begin
                    reg_mtimecmp    <= w_data_latch;
                end
            end
            if (o_axi_bvalid && i_axi_bready) begin
                o_axi_bvalid <= `Disable;
            end
        end
    end

    // ---- AXI read path ----
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_axi_arready   <= `Disable;
            o_axi_rdata     <= `ZeroWord;
            o_axi_rvalid    <= `Disable;
            o_axi_rlast     <= `Disable;
        end
        else begin
            o_axi_arready   <= `Disable;

            if (i_axi_arvalid && !o_axi_rvalid) begin
                o_axi_arready   <= `Enable;
                o_axi_rvalid    <= `Enable;
                o_axi_rlast     <= `Enable;

                case (i_axi_araddr[3:0])
                    OFFSET_MTIME: begin
                        o_axi_rdata <= reg_mtime;
                    end
                    OFFSET_MTIMECMP: begin
                        o_axi_rdata <= reg_mtimecmp;
                    end
                    default: begin
                        o_axi_rdata <= `ZeroWord;
                    end
                endcase
            end

            if (o_axi_rvalid && i_axi_rready) begin
                o_axi_rvalid <= `Disable;
                o_axi_rlast  <= `Disable;
            end
        end
    end
endmodule
