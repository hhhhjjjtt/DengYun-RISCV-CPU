`include "defines.v"

// ---- AXI4 Interconnect ----
// M0→S0 direct, M2→S2 direct, M1+M3→S1 arbitrated
// Masters: M0=i_cache(AR+R), M1=d_cache(full), M2=mmio_port(full), M3=DMA stub(full)
// Slaves:  S0=ROM(AR+R),     S1=RAM(full),     S2=Peripheral(full)

module AXI4 (
    input wire          i_Clk,
    input wire          i_reset,

    // ---- Master 0: i_cache (AR + R only) ----
    input wire[31:0]    M0_ARADDR,
    input wire          M0_ARVALID,
    output wire         M0_ARREADY,
    input wire[7:0]     M0_ARLEN,
    input wire[2:0]     M0_ARSIZE,
    input wire[1:0]     M0_ARBURST,
    output wire[31:0]   M0_RDATA,
    output wire         M0_RVALID,
    input wire          M0_RREADY,
    output wire         M0_RLAST,

    // ---- Master 1: d_cache (full AXI) ----
    input wire[31:0]    M1_ARADDR,
    input wire          M1_ARVALID,
    output wire         M1_ARREADY,
    input wire[7:0]     M1_ARLEN,
    input wire[2:0]     M1_ARSIZE,
    input wire[1:0]     M1_ARBURST,
    output wire[31:0]   M1_RDATA,
    output wire         M1_RVALID,
    input wire          M1_RREADY,
    output wire         M1_RLAST,
    input wire[31:0]    M1_AWADDR,
    input wire          M1_AWVALID,
    output wire         M1_AWREADY,
    input wire[7:0]     M1_AWLEN,
    input wire[2:0]     M1_AWSIZE,
    input wire[1:0]     M1_AWBURST,
    input wire[31:0]    M1_WDATA,
    input wire          M1_WVALID,
    output wire         M1_WREADY,
    input wire          M1_WLAST,
    input wire[3:0]     M1_WSTRB,
    output wire[1:0]    M1_BRESP,
    output wire         M1_BVALID,
    input wire          M1_BREADY,

    // ---- Master 2: mmio_port (full AXI) ----
    input wire[31:0]    M2_ARADDR,
    input wire          M2_ARVALID,
    output wire         M2_ARREADY,
    input wire[7:0]     M2_ARLEN,
    input wire[2:0]     M2_ARSIZE,
    input wire[1:0]     M2_ARBURST,
    output wire[31:0]   M2_RDATA,
    output wire         M2_RVALID,
    input wire          M2_RREADY,
    output wire         M2_RLAST,
    input wire[31:0]    M2_AWADDR,
    input wire          M2_AWVALID,
    output wire         M2_AWREADY,
    input wire[7:0]     M2_AWLEN,
    input wire[2:0]     M2_AWSIZE,
    input wire[1:0]     M2_AWBURST,
    input wire[31:0]    M2_WDATA,
    input wire          M2_WVALID,
    output wire         M2_WREADY,
    input wire          M2_WLAST,
    input wire[3:0]     M2_WSTRB,
    output wire[1:0]    M2_BRESP,
    output wire         M2_BVALID,
    input wire          M2_BREADY,

    // ---- Master 3: DMA stub (full AXI, tie all inputs to 0 in cpu_top) ----
    input wire[31:0]    M3_ARADDR,
    input wire          M3_ARVALID,
    output wire         M3_ARREADY,
    input wire[7:0]     M3_ARLEN,
    input wire[2:0]     M3_ARSIZE,
    input wire[1:0]     M3_ARBURST,
    output wire[31:0] M3_RDATA,
    output wire         M3_RVALID,
    input wire          M3_RREADY,
    output wire         M3_RLAST,
    input wire[31:0]    M3_AWADDR,
    input wire          M3_AWVALID,
    output wire         M3_AWREADY,
    input wire[7:0]     M3_AWLEN,
    input wire[2:0]     M3_AWSIZE,
    input wire[1:0]     M3_AWBURST,
    input wire[31:0]    M3_WDATA,
    input wire          M3_WVALID,
    output wire         M3_WREADY,
    input wire          M3_WLAST,
    input wire[3:0]     M3_WSTRB,
    output wire[1:0]    M3_BRESP,
    output wire         M3_BVALID,
    input wire          M3_BREADY,

    // ---- Slave 0: ROM (AR + R only) ----
    output wire[31:0]   S0_ARADDR,
    output wire         S0_ARVALID,
    input wire          S0_ARREADY,
    output wire[7:0]    S0_ARLEN,
    output wire[2:0]    S0_ARSIZE,
    output wire[1:0]    S0_ARBURST,
    input wire[31:0]    S0_RDATA,
    input wire          S0_RVALID,
    output wire         S0_RREADY,
    input wire          S0_RLAST,

    // ---- Slave 1: RAM (full AXI) ----
    output wire[31:0]   S1_ARADDR,
    output wire         S1_ARVALID,
    input wire          S1_ARREADY,
    output wire[7:0]    S1_ARLEN,
    output wire[2:0]    S1_ARSIZE,
    output wire[1:0]    S1_ARBURST,
    input wire[31:0]    S1_RDATA,
    input wire          S1_RVALID,
    output wire         S1_RREADY,
    input wire          S1_RLAST,
    output wire[31:0]   S1_AWADDR,
    output wire         S1_AWVALID,
    input wire          S1_AWREADY,
    output wire[7:0]    S1_AWLEN,
    output wire[2:0]    S1_AWSIZE,
    output wire[1:0]    S1_AWBURST,
    output wire[31:0]   S1_WDATA,
    output wire         S1_WVALID,
    input wire          S1_WREADY,
    output wire         S1_WLAST,
    output wire[3:0]    S1_WSTRB,
    input wire[1:0]     S1_BRESP,
    input wire          S1_BVALID,
    output wire         S1_BREADY,

    // ---- Slave 2: Peripheral (full AXI) ----
    output wire[31:0]   S2_ARADDR,
    output wire         S2_ARVALID,
    input wire          S2_ARREADY,
    output wire[7:0]    S2_ARLEN,
    output wire[2:0]    S2_ARSIZE,
    output wire[1:0]    S2_ARBURST,
    input wire[31:0]    S2_RDATA,
    input wire          S2_RVALID,
    output wire         S2_RREADY,
    input wire          S2_RLAST,
    output wire[31:0]   S2_AWADDR,
    output wire         S2_AWVALID,
    input wire          S2_AWREADY,
    output wire[7:0]    S2_AWLEN,
    output wire[2:0]    S2_AWSIZE,
    output wire[1:0]    S2_AWBURST,
    output wire[31:0]   S2_WDATA,
    output wire         S2_WVALID,
    input wire          S2_WREADY,
    output wire         S2_WLAST,
    output wire[3:0]    S2_WSTRB,
    input wire[1:0]     S2_BRESP,
    input wire          S2_BVALID,
    output wire         S2_BREADY
);

    // S0 (ROM)
    assign S0_ARADDR  = M0_ARADDR;
    assign S0_ARVALID = M0_ARVALID;
    assign M0_ARREADY = S0_ARREADY;
    assign S0_ARLEN   = M0_ARLEN;
    assign S0_ARSIZE  = M0_ARSIZE;
    assign S0_ARBURST = M0_ARBURST;
    assign M0_RDATA   = S0_RDATA;
    assign M0_RVALID  = S0_RVALID;
    assign S0_RREADY  = M0_RREADY;
    assign M0_RLAST   = S0_RLAST;

    // S2 (Peripheral)
    assign S2_ARADDR  = M2_ARADDR;
    assign S2_ARVALID = M2_ARVALID;
    assign M2_ARREADY = S2_ARREADY;
    assign S2_ARLEN   = M2_ARLEN;
    assign S2_ARSIZE  = M2_ARSIZE;
    assign S2_ARBURST = M2_ARBURST;
    assign M2_RDATA   = S2_RDATA;
    assign M2_RVALID  = S2_RVALID;
    assign S2_RREADY  = M2_RREADY;
    assign M2_RLAST   = S2_RLAST;

    assign S2_AWADDR  = M2_AWADDR;
    assign S2_AWVALID = M2_AWVALID;
    assign M2_AWREADY = S2_AWREADY;
    assign S2_AWLEN   = M2_AWLEN;
    assign S2_AWSIZE  = M2_AWSIZE;
    assign S2_AWBURST = M2_AWBURST;
    assign S2_WDATA   = M2_WDATA;
    assign S2_WVALID  = M2_WVALID;
    assign M2_WREADY  = S2_WREADY;
    assign S2_WLAST   = M2_WLAST;
    assign S2_WSTRB   = M2_WSTRB;
    assign M2_BRESP   = S2_BRESP;
    assign M2_BVALID  = S2_BVALID;
    assign S2_BREADY  = M2_BREADY;

    // S1 (RAM): arbiter between M1 (d_cache) and M3 (DMA)
    // Priority: M1 > M3 on both read and write channels

    // Read arbiter: AR + R
    localparam RD_IDLE     = 2'd0;
    localparam RD_SERVE_M1 = 2'd1;
    localparam RD_SERVE_M3 = 2'd2;

    reg [1:0] ram_rd_state;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            ram_rd_state <= RD_IDLE;
        end
        else begin
            case (ram_rd_state)
                RD_IDLE: begin
                    if      (M1_ARVALID && S1_ARREADY)                ram_rd_state <= RD_SERVE_M1;
                    else if (M3_ARVALID && S1_ARREADY && !M1_ARVALID) ram_rd_state <= RD_SERVE_M3;
                end
                RD_SERVE_M1:
                    if (S1_RVALID && S1_RLAST && M1_RREADY) ram_rd_state <= RD_IDLE;
                RD_SERVE_M3:
                    if (S1_RVALID && S1_RLAST && M3_RREADY) ram_rd_state <= RD_IDLE;
                default: ram_rd_state <= RD_IDLE;
            endcase
        end
    end

    wire m1_ar_wins = (ram_rd_state == RD_IDLE) &&  M1_ARVALID;
    wire m3_ar_wins = (ram_rd_state == RD_IDLE) && !M1_ARVALID && M3_ARVALID;

    assign S1_ARVALID = m1_ar_wins || m3_ar_wins;
    assign S1_ARADDR  = m1_ar_wins ? M1_ARADDR  : M3_ARADDR;
    assign S1_ARLEN   = m1_ar_wins ? M1_ARLEN   : M3_ARLEN;
    assign S1_ARSIZE  = m1_ar_wins ? M1_ARSIZE  : M3_ARSIZE;
    assign S1_ARBURST = m1_ar_wins ? M1_ARBURST : M3_ARBURST;

    assign M1_ARREADY = m1_ar_wins && S1_ARREADY;
    assign M3_ARREADY = m3_ar_wins && S1_ARREADY;

    assign M1_RDATA  = (ram_rd_state == RD_SERVE_M1) ? S1_RDATA  : 32'b0;
    assign M1_RVALID = (ram_rd_state == RD_SERVE_M1) ? S1_RVALID : 1'b0;
    assign M1_RLAST  = (ram_rd_state == RD_SERVE_M1) ? S1_RLAST  : 1'b0;
    assign M3_RDATA  = (ram_rd_state == RD_SERVE_M3) ? S1_RDATA  : 32'b0;
    assign M3_RVALID = (ram_rd_state == RD_SERVE_M3) ? S1_RVALID : 1'b0;
    assign M3_RLAST  = (ram_rd_state == RD_SERVE_M3) ? S1_RLAST  : 1'b0;

    assign S1_RREADY = (ram_rd_state == RD_SERVE_M1) ? M1_RREADY :
                       (ram_rd_state == RD_SERVE_M3) ? M3_RREADY : 1'b0;

    // Write arbiter: AW + W + B
    localparam WR_IDLE       = 3'd0;
    localparam WR_SERVE_M1   = 3'd1; // M1 granted, AW+W in progress
    localparam WR_SERVE_M1_B = 3'd2; // M1 W done, waiting for B
    localparam WR_SERVE_M3   = 3'd3; // M3 granted, AW+W in progress
    localparam WR_SERVE_M3_B = 3'd4; // M3 W done, waiting for B

    reg [2:0] ram_wr_state;

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            ram_wr_state <= WR_IDLE;
        end
        else begin
            case (ram_wr_state)
                WR_IDLE: begin
                    if      (M1_AWVALID && S1_AWREADY)                ram_wr_state <= WR_SERVE_M1;
                    else if (M3_AWVALID && S1_AWREADY && !M1_AWVALID) ram_wr_state <= WR_SERVE_M3;
                end
                WR_SERVE_M1:
                    if (M1_WVALID && S1_WREADY && M1_WLAST) ram_wr_state <= WR_SERVE_M1_B;
                WR_SERVE_M1_B:
                    if (S1_BVALID && M1_BREADY) ram_wr_state <= WR_IDLE;
                WR_SERVE_M3:
                    if (M3_WVALID && S1_WREADY && M3_WLAST) ram_wr_state <= WR_SERVE_M3_B;
                WR_SERVE_M3_B:
                    if (S1_BVALID && M3_BREADY) ram_wr_state <= WR_IDLE;
                default: ram_wr_state <= WR_IDLE;
            endcase
        end
    end

    // AW
    wire m1_aw_active = (ram_wr_state == WR_IDLE     &&  M1_AWVALID) ||
                        (ram_wr_state == WR_SERVE_M1)                 ||
                        (ram_wr_state == WR_SERVE_M1_B);
    wire m3_aw_active = (ram_wr_state == WR_IDLE     && !M1_AWVALID && M3_AWVALID) ||
                        (ram_wr_state == WR_SERVE_M3)                               ||
                        (ram_wr_state == WR_SERVE_M3_B);

    assign S1_AWVALID = m1_aw_active ? M1_AWVALID : (m3_aw_active ? M3_AWVALID : 1'b0);
    assign S1_AWADDR  = m1_aw_active ? M1_AWADDR  : M3_AWADDR;
    assign S1_AWLEN   = m1_aw_active ? M1_AWLEN   : M3_AWLEN;
    assign S1_AWSIZE  = m1_aw_active ? M1_AWSIZE  : M3_AWSIZE;
    assign S1_AWBURST = m1_aw_active ? M1_AWBURST : M3_AWBURST;

    assign M1_AWREADY = m1_aw_active ? S1_AWREADY : 1'b0;
    assign M3_AWREADY = m3_aw_active ? S1_AWREADY : 1'b0;

    // W
    assign S1_WVALID = (ram_wr_state == WR_SERVE_M1) ? M1_WVALID :
                       (ram_wr_state == WR_SERVE_M3) ? M3_WVALID : 1'b0;
    assign S1_WDATA  = (ram_wr_state == WR_SERVE_M1) ? M1_WDATA  : M3_WDATA;
    assign S1_WLAST  = (ram_wr_state == WR_SERVE_M1) ? M1_WLAST  : M3_WLAST;
    assign S1_WSTRB  = (ram_wr_state == WR_SERVE_M1) ? M1_WSTRB  : M3_WSTRB;

    assign M1_WREADY = (ram_wr_state == WR_SERVE_M1) ? S1_WREADY : 1'b0;
    assign M3_WREADY = (ram_wr_state == WR_SERVE_M3) ? S1_WREADY : 1'b0;

    // B
    assign M1_BVALID = (ram_wr_state == WR_SERVE_M1_B) ? S1_BVALID : 1'b0;
    assign M1_BRESP  = (ram_wr_state == WR_SERVE_M1_B) ? S1_BRESP  : 2'b0;
    assign M3_BVALID = (ram_wr_state == WR_SERVE_M3_B) ? S1_BVALID : 1'b0;
    assign M3_BRESP  = (ram_wr_state == WR_SERVE_M3_B) ? S1_BRESP  : 2'b0;

    assign S1_BREADY = (ram_wr_state == WR_SERVE_M1_B) ? M1_BREADY :
                       (ram_wr_state == WR_SERVE_M3_B) ? M3_BREADY : 1'b0;

endmodule
