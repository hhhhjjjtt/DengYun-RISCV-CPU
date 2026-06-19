`include "../defines.v"

// Register map (word-addressed via addr[4:2]):
//   0x00  ENABLE    [`Num_IntSrc-1:0]  RW: bitmask of enabled sources
//   0x04  PENDING   [`Num_IntSrc-1:0]  R:  bitmask of sources waiting to be claimed
//   0x08  CLAIM     [SRC_SEL_WIDTH-1:0] R: ID of highest-priority pending+enabled source;
//                                          reading atomically clears that source from PENDING
//   0x0C  COMPLETE  [SRC_SEL_WIDTH-1:0] W: write source ID when ISR is done (re-arms the source)
//
// Priority: lower source ID = higher priority.
// Pending is set on the rising edge of i_src[n]; cleared by a CLAIM read or COMPLETE write.
// o_external_int_pending = |(r_pending & r_enable), purely combinational.

module PLIC (
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
    input wire[3:0]                     i_axi_wstrb,
    // AXI slave — B channel
    output reg[1:0]                     o_axi_bresp,
    output reg                          o_axi_bvalid,
    input wire                          i_axi_bready,       // unused

    input wire[`Num_IntSrc-1:0]         i_src,

    output wire                         o_external_int_pending
);

    localparam OFFSET_ENABLE   = 3'b000;
    localparam OFFSET_PENDING  = 3'b001;
    localparam OFFSET_CLAIM    = 3'b010;
    localparam OFFSET_COMPLETE = 3'b011;

    // Width needed to hold a source ID (e.g. 2 sources → 1 bit, 4 sources → 2 bits)
    localparam SRC_SEL_WIDTH = (`Num_IntSrc <= 1) ? 1 : $clog2(`Num_IntSrc);

    // ---- Internal state ----
    reg[`Num_IntSrc-1:0]       r_enable;
    reg[`Num_IntSrc-1:0]       r_pending;
    reg[`Num_IntSrc-1:0]       r_src_prev;     // for rising-edge detection on i_src

    wire[`Num_IntSrc-1:0]      src_rise = i_src & ~r_src_prev;
    wire[`Num_IntSrc-1:0]      active   = r_pending & r_enable;

    assign o_external_int_pending = |active;

    // Priority encoder: scan high-to-low so the last write is the lowest (highest-priority) ID
    reg[SRC_SEL_WIDTH-1:0]     claim_id;
    integer                    k;
    always @(*) begin
        claim_id = {SRC_SEL_WIDTH{1'b0}};
        for (k = `Num_IntSrc-1; k >= 0; k = k-1) begin
            if (active[k]) begin 
                claim_id = k[SRC_SEL_WIDTH-1:0];
            end
        end
    end

    // One-cycle strobes from AXI paths into the pending block
    reg                         claim_clear;
    reg[SRC_SEL_WIDTH-1:0]      claim_clear_id;
    reg                         complete_clear;
    reg[SRC_SEL_WIDTH-1:0]      complete_clear_id;

    // ---- Pending register ----
    // Set on rising edge of source; cleared by CLAIM read or COMPLETE write.
    // Both clear strobes arrive from the AXI paths below.
    always @(posedge i_Clk) begin
        if (i_reset) begin
            r_pending  <= {`Num_IntSrc{1'b0}};
            r_src_prev <= {`Num_IntSrc{1'b0}};
        end
        else begin
            r_src_prev <= i_src;
            r_pending  <= r_pending | src_rise;     // set on rising edge

            if (claim_clear) begin
                r_pending[claim_clear_id] <= 1'b0;
            end // cleared by CLAIM read
            if (complete_clear) begin
                r_pending[complete_clear_id] <= 1'b0;
            end // cleared by COMPLETE write
        end
    end

    // ---- AXI write path ----
    reg         aw_pending;
    reg[31:0]   aw_addr_latch;
    reg         w_pending;
    reg[31:0]   w_data_latch;
    reg[3:0]    w_strb_latch;

    always @(posedge i_Clk) begin
        if (i_reset) begin
            o_axi_awready  <= 1'b0;
            o_axi_wready   <= 1'b0;
            o_axi_bvalid   <= 1'b0;
            o_axi_bresp    <= 2'b00;
            aw_pending     <= 1'b0;
            w_pending      <= 1'b0;
            r_enable       <= {`Num_IntSrc{1'b0}};
            complete_clear <= 1'b0;
        end
        else begin
            o_axi_awready  <= 1'b0;
            o_axi_wready   <= 1'b0;
            complete_clear <= 1'b0;

            // Accept AW
            if (i_axi_awvalid && !aw_pending) begin
                o_axi_awready <= 1'b1;
                aw_addr_latch <= i_axi_awaddr;
                aw_pending    <= 1'b1;
            end

            // Accept W
            if (i_axi_wvalid && !w_pending) begin
                o_axi_wready <= 1'b1;
                w_data_latch <= i_axi_wdata;
                w_strb_latch <= i_axi_wstrb;
                w_pending    <= 1'b1;
            end

            // Perform write once both AW and W are latched
            if (aw_pending && w_pending && !o_axi_bvalid) begin
                aw_pending   <= 1'b0;
                w_pending    <= 1'b0;
                o_axi_bvalid <= 1'b1;
                o_axi_bresp  <= 2'b00;
                case (aw_addr_latch[4:2])
                    OFFSET_ENABLE: begin
                        r_enable <= w_data_latch[`Num_IntSrc-1:0];
                    end
                    OFFSET_COMPLETE: begin
                        complete_clear    <= 1'b1;
                        complete_clear_id <= w_data_latch[SRC_SEL_WIDTH-1:0];
                    end
                    default: ;
                endcase
            end

            if (o_axi_bvalid && i_axi_bready) begin
                o_axi_bvalid <= 1'b0;
            end
        end
    end

    // ---- AXI read path ----
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_axi_arready <= 1'b0;
            o_axi_rvalid  <= 1'b0;
            o_axi_rlast   <= 1'b0;
            o_axi_rdata   <= 32'd0;
            claim_clear   <= 1'b0;
        end
        else begin
            o_axi_arready <= 1'b0;
            claim_clear   <= 1'b0;

            if (i_axi_arvalid && !o_axi_rvalid) begin
                o_axi_arready <= 1'b1;
                o_axi_rvalid  <= 1'b1;
                o_axi_rlast   <= 1'b1;
                case (i_axi_araddr[4:2])
                    OFFSET_ENABLE: begin
                        o_axi_rdata <= {{(32-`Num_IntSrc){1'b0}}, r_enable};
                    end
                    OFFSET_PENDING: begin
                        o_axi_rdata <= {{(32-`Num_IntSrc){1'b0}}, r_pending};
                    end
                    OFFSET_CLAIM: begin
                        o_axi_rdata    <= {{(32-SRC_SEL_WIDTH){1'b0}}, claim_id};
                        claim_clear    <= 1'b1;         // atomically clear this source
                        claim_clear_id <= claim_id;
                    end
                    default: o_axi_rdata <= 32'd0;
                endcase
            end

            if (o_axi_rvalid && i_axi_rready) begin
                o_axi_rvalid <= 1'b0;
                o_axi_rlast  <= 1'b0;
            end
        end
    end

endmodule
