`include "../defines.v"

// ---- AXI4 Interconnect ----
// M0→S0 direct, M2→S2,S3 based on address, M1+M3→S1 arbitrated
// Masters: M0=i_cache(AXI4;AR+R), M1=d_cache(AXI4), M2=mmio_port(AXI4-Lite), M3=DMA stub(AXI4)
// Slaves:  S0=ROM(AXI4;AR+R), S1=RAM(AXI4), S2=PLIC(AXI4-Lite), S3=UART(AXI4-Lite), S6=CLINT(AXI4-Lite)

module AXI4 (
    input wire          i_Clk,
    input wire          i_reset,

    // ---- Master 0: i_cache (AXI4; AR + R only) ----
    input wire[31:0]    M0_ARADDR,
    input wire          M0_ARVALID,
    output reg          M0_ARREADY,
    input wire[7:0]     M0_ARLEN,
    input wire[2:0]     M0_ARSIZE,
    input wire[1:0]     M0_ARBURST,
    output reg[31:0]    M0_RDATA,
    output reg          M0_RVALID,
    input wire          M0_RREADY,
    output reg          M0_RLAST,

    // ---- Master 1: d_cache (AXI4) ----
    input wire[31:0]    M1_ARADDR,
    input wire          M1_ARVALID,
    output reg          M1_ARREADY,
    input wire[7:0]     M1_ARLEN,
    input wire[2:0]     M1_ARSIZE,
    input wire[1:0]     M1_ARBURST,
    output reg[31:0]    M1_RDATA,
    output reg          M1_RVALID,
    input wire          M1_RREADY,
    output reg          M1_RLAST,
    input wire[31:0]    M1_AWADDR,
    input wire          M1_AWVALID,
    output reg          M1_AWREADY,
    input wire[7:0]     M1_AWLEN,
    input wire[2:0]     M1_AWSIZE,
    input wire[1:0]     M1_AWBURST,
    input wire[31:0]    M1_WDATA,
    input wire          M1_WVALID,
    output reg          M1_WREADY,
    input wire          M1_WLAST,
    input wire[3:0]     M1_WSTRB,
    output reg[1:0]     M1_BRESP,
    output reg          M1_BVALID,
    input wire          M1_BREADY,

    // ---- Master 2: mmio_port (AXI4-Lite) ----
    input wire[31:0]    M2_ARADDR,
    input wire          M2_ARVALID,
    output reg          M2_ARREADY,
    input wire[7:0]     M2_ARLEN,
    input wire[2:0]     M2_ARSIZE,
    input wire[1:0]     M2_ARBURST,
    output reg[31:0]    M2_RDATA,
    output reg          M2_RVALID,
    input wire          M2_RREADY,
    output reg          M2_RLAST,
    input wire[31:0]    M2_AWADDR,
    input wire          M2_AWVALID,
    output reg          M2_AWREADY,
    input wire[7:0]     M2_AWLEN,
    input wire[2:0]     M2_AWSIZE,
    input wire[1:0]     M2_AWBURST,
    input wire[31:0]    M2_WDATA,
    input wire          M2_WVALID,
    output reg          M2_WREADY,
    input wire          M2_WLAST,
    input wire[3:0]     M2_WSTRB,
    output reg[1:0]     M2_BRESP,
    output reg          M2_BVALID,
    input wire          M2_BREADY,

    // ---- Master 3: DMA stub (AXI4, tie all inputs to 0 in cpu_top) ----
    input wire[31:0]    M3_ARADDR,
    input wire          M3_ARVALID,
    output reg          M3_ARREADY,
    input wire[7:0]     M3_ARLEN,
    input wire[2:0]     M3_ARSIZE,
    input wire[1:0]     M3_ARBURST,
    output reg[31:0]    M3_RDATA,
    output reg          M3_RVALID,
    input wire          M3_RREADY,
    output reg          M3_RLAST,
    input wire[31:0]    M3_AWADDR,
    input wire          M3_AWVALID,
    output reg          M3_AWREADY,
    input wire[7:0]     M3_AWLEN,
    input wire[2:0]     M3_AWSIZE,
    input wire[1:0]     M3_AWBURST,
    input wire[31:0]    M3_WDATA,
    input wire          M3_WVALID,
    output reg          M3_WREADY,
    input wire          M3_WLAST,
    input wire[3:0]     M3_WSTRB,
    output reg[1:0]     M3_BRESP,
    output reg          M3_BVALID,
    input wire          M3_BREADY,

    // ---- Slave 0: ROM (AXI4; AR + R only) ----
    output reg[31:0]    S0_ARADDR,
    output reg          S0_ARVALID,
    input wire          S0_ARREADY,
    output reg[7:0]     S0_ARLEN,
    output reg[2:0]     S0_ARSIZE,
    output reg[1:0]     S0_ARBURST,
    input wire[31:0]    S0_RDATA,
    input wire          S0_RVALID,
    output reg          S0_RREADY,
    input wire          S0_RLAST,

    // ---- Slave 1: RAM (AXI4) ----
    output reg[31:0]    S1_ARADDR,
    output reg          S1_ARVALID,
    input wire          S1_ARREADY,
    output reg[7:0]     S1_ARLEN,
    output reg[2:0]     S1_ARSIZE,
    output reg[1:0]     S1_ARBURST,
    input wire[31:0]    S1_RDATA,
    input wire          S1_RVALID,
    output reg          S1_RREADY,
    input wire          S1_RLAST,
    output reg[31:0]    S1_AWADDR,
    output reg          S1_AWVALID,
    input wire          S1_AWREADY,
    output reg[7:0]     S1_AWLEN,
    output reg[2:0]     S1_AWSIZE,
    output reg[1:0]     S1_AWBURST,
    output reg[31:0]    S1_WDATA,
    output reg          S1_WVALID,
    input wire          S1_WREADY,
    output reg          S1_WLAST,
    output reg[3:0]     S1_WSTRB,
    input wire[1:0]     S1_BRESP,
    input wire          S1_BVALID,
    output reg          S1_BREADY,

    // ---- Slave 2: PLIC (AXI4-Lite) ----
    output reg[31:0]    S2_ARADDR,
    output reg          S2_ARVALID,
    input wire          S2_ARREADY,
    output reg[7:0]     S2_ARLEN,
    output reg[2:0]     S2_ARSIZE,
    output reg[1:0]     S2_ARBURST,
    input wire[31:0]    S2_RDATA,
    input wire          S2_RVALID,
    output reg          S2_RREADY,
    input wire          S2_RLAST,
    output reg[31:0]    S2_AWADDR,
    output reg          S2_AWVALID,
    input wire          S2_AWREADY,
    output reg[7:0]     S2_AWLEN,
    output reg[2:0]     S2_AWSIZE,
    output reg[1:0]     S2_AWBURST,
    output reg[31:0]    S2_WDATA,
    output reg          S2_WVALID,
    input wire          S2_WREADY,
    output reg          S2_WLAST,
    output reg[3:0]     S2_WSTRB,
    input wire[1:0]     S2_BRESP,
    input wire          S2_BVALID,
    output reg          S2_BREADY,

    // ---- Slave 3: UART (AXI4-Lite) ----
    output reg[31:0]    S3_ARADDR,
    output reg          S3_ARVALID,
    input wire          S3_ARREADY,
    output reg[7:0]     S3_ARLEN,
    output reg[2:0]     S3_ARSIZE,
    output reg[1:0]     S3_ARBURST,
    input wire[31:0]    S3_RDATA,
    input wire          S3_RVALID,
    output reg          S3_RREADY,
    input wire          S3_RLAST,
    output reg[31:0]    S3_AWADDR,
    output reg          S3_AWVALID,
    input wire          S3_AWREADY,
    output reg[7:0]     S3_AWLEN,
    output reg[2:0]     S3_AWSIZE,
    output reg[1:0]     S3_AWBURST,
    output reg[31:0]    S3_WDATA,
    output reg          S3_WVALID,
    input wire          S3_WREADY,
    output reg          S3_WLAST,
    output reg[3:0]     S3_WSTRB,
    input wire[1:0]     S3_BRESP,
    input wire          S3_BVALID,
    output reg          S3_BREADY,

    // ---- Slave 4: GPIO (AXI4-Lite) ----
    output reg[31:0]    S4_ARADDR,
    output reg          S4_ARVALID,
    input wire          S4_ARREADY,
    output reg[7:0]     S4_ARLEN,
    output reg[2:0]     S4_ARSIZE,
    output reg[1:0]     S4_ARBURST,
    input wire[31:0]    S4_RDATA,
    input wire          S4_RVALID,
    output reg          S4_RREADY,
    input wire          S4_RLAST,
    output reg[31:0]    S4_AWADDR,
    output reg          S4_AWVALID,
    input wire          S4_AWREADY,
    output reg[7:0]     S4_AWLEN,
    output reg[2:0]     S4_AWSIZE,
    output reg[1:0]     S4_AWBURST,
    output reg[31:0]    S4_WDATA,
    output reg          S4_WVALID,
    input wire          S4_WREADY,
    output reg          S4_WLAST,
    output reg[3:0]     S4_WSTRB,
    input wire[1:0]     S4_BRESP,
    input wire          S4_BVALID,
    output reg          S4_BREADY,

    // ---- Slave 6: CLINT (AXI4-Lite) ----
    output reg[31:0]    S6_ARADDR,
    output reg          S6_ARVALID,
    input wire          S6_ARREADY,
    output reg[7:0]     S6_ARLEN,
    output reg[2:0]     S6_ARSIZE,
    output reg[1:0]     S6_ARBURST,
    input wire[31:0]    S6_RDATA,
    input wire          S6_RVALID,
    output reg          S6_RREADY,
    input wire          S6_RLAST,
    output reg[31:0]    S6_AWADDR,
    output reg          S6_AWVALID,
    input wire          S6_AWREADY,
    output reg[7:0]     S6_AWLEN,
    output reg[2:0]     S6_AWSIZE,
    output reg[1:0]     S6_AWBURST,
    output reg[31:0]    S6_WDATA,
    output reg          S6_WVALID,
    input wire          S6_WREADY,
    output reg          S6_WLAST,
    output reg[3:0]     S6_WSTRB,
    input wire[1:0]     S6_BRESP,
    input wire          S6_BVALID,
    output reg          S6_BREADY
);

    // M0 <--> S0 (i_cache <--> ROM)
    always @(*) begin
        S0_ARADDR  = M0_ARADDR;
        S0_ARVALID = M0_ARVALID;
        M0_ARREADY = S0_ARREADY;
        S0_ARLEN   = M0_ARLEN;
        S0_ARSIZE  = M0_ARSIZE;
        S0_ARBURST = M0_ARBURST;
        M0_RDATA   = S0_RDATA;
        M0_RVALID  = S0_RVALID;
        S0_RREADY  = M0_RREADY;
        M0_RLAST   = S0_RLAST;
    end

    // M2 <--> S2/S3/S4/S6 (mmio <--> PLIC/UART/GPIO/CLINT)
    always @(*) begin
        // AR
        M2_ARREADY = 1'b0;
        S2_ARADDR  = M2_ARADDR;
        S2_ARVALID = 1'b0;
        S2_ARLEN   = M2_ARLEN;
        S2_ARSIZE  = M2_ARSIZE;
        S2_ARBURST = M2_ARBURST;
        S3_ARADDR  = M2_ARADDR;
        S3_ARVALID = 1'b0;
        S3_ARLEN   = M2_ARLEN;
        S3_ARSIZE  = M2_ARSIZE;
        S3_ARBURST = M2_ARBURST;
        S4_ARADDR  = M2_ARADDR;
        S4_ARVALID = 1'b0;
        S4_ARLEN   = M2_ARLEN;
        S4_ARSIZE  = M2_ARSIZE;
        S4_ARBURST = M2_ARBURST;
        S6_ARADDR  = M2_ARADDR;
        S6_ARVALID = 1'b0;
        S6_ARLEN   = M2_ARLEN;
        S6_ARSIZE  = M2_ARSIZE;
        S6_ARBURST = M2_ARBURST;
        // R
        M2_RDATA   = S2_RDATA;
        M2_RVALID  = 1'b0;
        M2_RLAST   = S2_RLAST;
        S2_RREADY  = 1'b0;
        S3_RREADY  = 1'b0;
        S4_RREADY  = 1'b0;
        S6_RREADY  = 1'b0;
        // AW
        M2_AWREADY = 1'b0;
        S2_AWADDR  = M2_AWADDR;
        S2_AWVALID = 1'b0;
        S2_AWLEN   = M2_AWLEN;
        S2_AWSIZE  = M2_AWSIZE;
        S2_AWBURST = M2_AWBURST;
        S3_AWADDR  = M2_AWADDR;
        S3_AWVALID = 1'b0;
        S3_AWLEN   = M2_AWLEN;
        S3_AWSIZE  = M2_AWSIZE;
        S3_AWBURST = M2_AWBURST;
        S4_AWADDR  = M2_AWADDR;
        S4_AWVALID = 1'b0;
        S4_AWLEN   = M2_AWLEN;
        S4_AWSIZE  = M2_AWSIZE;
        S4_AWBURST = M2_AWBURST;
        S6_AWADDR  = M2_AWADDR;
        S6_AWVALID = 1'b0;
        S6_AWLEN   = M2_AWLEN;
        S6_AWSIZE  = M2_AWSIZE;
        S6_AWBURST = M2_AWBURST;
        // W
        M2_WREADY  = 1'b0;
        S2_WDATA   = M2_WDATA;
        S2_WVALID  = 1'b0;
        S2_WLAST   = M2_WLAST;
        S2_WSTRB   = M2_WSTRB;
        S3_WDATA   = M2_WDATA;
        S3_WVALID  = 1'b0;
        S3_WLAST   = M2_WLAST;
        S3_WSTRB   = M2_WSTRB;
        S4_WDATA   = M2_WDATA;
        S4_WVALID  = 1'b0;
        S4_WLAST   = M2_WLAST;
        S4_WSTRB   = M2_WSTRB;
        S6_WDATA   = M2_WDATA;
        S6_WVALID  = 1'b0;
        S6_WLAST   = M2_WLAST;
        S6_WSTRB   = M2_WSTRB;
        // B
        M2_BRESP   = S2_BRESP;
        M2_BVALID  = 1'b0;
        S2_BREADY  = 1'b0;
        S3_BREADY  = 1'b0;
        S4_BREADY  = 1'b0;
        S6_BREADY  = 1'b0;

        // Read routing 
        if (M2_ARADDR >= `PLIC_BASE && M2_ARADDR < `PLIC_BASE + `REGION_SIZE) begin
            M2_RDATA   = S2_RDATA;
            S2_ARVALID = M2_ARVALID;
            M2_ARREADY = S2_ARREADY;
            M2_RVALID  = S2_RVALID;
            S2_RREADY  = M2_RREADY;
        end
        else if (M2_ARADDR >= `UART_BASE && M2_ARADDR < `UART_BASE + `REGION_SIZE) begin
            M2_RDATA   = S3_RDATA;
            M2_RLAST   = S3_RLAST;
            S3_ARVALID = M2_ARVALID;
            M2_ARREADY = S3_ARREADY;
            M2_RVALID  = S3_RVALID;
            S3_RREADY  = M2_RREADY;
        end
        else if (M2_ARADDR >= `GPIO_BASE && M2_ARADDR < `GPIO_BASE + `REGION_SIZE) begin
            M2_RDATA   = S4_RDATA;
            M2_RLAST   = S4_RLAST;
            S4_ARVALID = M2_ARVALID;
            M2_ARREADY = S4_ARREADY;
            M2_RVALID  = S4_RVALID;
            S4_RREADY  = M2_RREADY;
        end
        else if (M2_ARADDR >= `CLINT_BASE && M2_ARADDR < `CLINT_BASE + `REGION_SIZE) begin
            M2_RDATA   = S6_RDATA;
            M2_RLAST   = S6_RLAST;
            S6_ARVALID = M2_ARVALID;
            M2_ARREADY = S6_ARREADY;
            M2_RVALID  = S6_RVALID;
            S6_RREADY  = M2_RREADY;
        end
        
        // Write routing 
        if (M2_AWADDR >= `PLIC_BASE && M2_AWADDR < `PLIC_BASE + `REGION_SIZE) begin
            S2_AWVALID = M2_AWVALID;
            M2_AWREADY = S2_AWREADY;
            S2_WVALID  = M2_WVALID;
            M2_WREADY  = S2_WREADY;
            M2_BVALID  = S2_BVALID;
            S2_BREADY  = M2_BREADY;
        end
        else if (M2_AWADDR >= `UART_BASE && M2_AWADDR < `UART_BASE + `REGION_SIZE) begin
            S3_AWVALID = M2_AWVALID;
            M2_AWREADY = S3_AWREADY;
            S3_WVALID  = M2_WVALID;
            M2_WREADY  = S3_WREADY;
            M2_BRESP   = S3_BRESP;
            M2_BVALID  = S3_BVALID;
            S3_BREADY  = M2_BREADY;
        end
        else if (M2_AWADDR >= `GPIO_BASE && M2_AWADDR < `GPIO_BASE + `REGION_SIZE) begin
            S4_AWVALID = M2_AWVALID;
            M2_AWREADY = S4_AWREADY;
            S4_WVALID  = M2_WVALID;
            M2_WREADY  = S4_WREADY;
            M2_BRESP   = S4_BRESP;
            M2_BVALID  = S4_BVALID;
            S4_BREADY  = M2_BREADY;
        end
        else if (M2_AWADDR >= `CLINT_BASE && M2_AWADDR < `CLINT_BASE + `REGION_SIZE) begin
            S6_AWVALID = M2_AWVALID;
            M2_AWREADY = S6_AWREADY;
            S6_WVALID  = M2_WVALID;
            M2_WREADY  = S6_WREADY;
            M2_BRESP   = S6_BRESP;
            M2_BVALID  = S6_BVALID;
            S6_BREADY  = M2_BREADY;
        end
    end

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
                    if (M1_ARVALID && S1_ARREADY) begin
                        ram_rd_state <= RD_SERVE_M1;
                    end 
                    else if (M3_ARVALID && S1_ARREADY && !M1_ARVALID) begin
                        ram_rd_state <= RD_SERVE_M3;
                    end
                end
                RD_SERVE_M1: begin
                    if (S1_RVALID && S1_RLAST && M1_RREADY) begin
                        ram_rd_state <= RD_IDLE;
                    end
                end
                RD_SERVE_M3:  begin
                    if (S1_RVALID && S1_RLAST && M3_RREADY) begin
                        ram_rd_state <= RD_IDLE;
                    end 
                end 
                default: ram_rd_state <= RD_IDLE;
            endcase
        end
    end

    wire m1_ar_wins = (ram_rd_state == RD_IDLE) &&  M1_ARVALID;
    wire m3_ar_wins = (ram_rd_state == RD_IDLE) && !M1_ARVALID && M3_ARVALID;

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
                    if (M1_AWVALID && S1_AWREADY) begin
                        ram_wr_state <= WR_SERVE_M1;
                    end 
                    else if (M3_AWVALID && S1_AWREADY && !M1_AWVALID) begin
                        ram_wr_state <= WR_SERVE_M3;
                    end
                end
                WR_SERVE_M1: begin
                    if (M1_WVALID && S1_WREADY && M1_WLAST) begin
                        ram_wr_state <= WR_SERVE_M1_B;
                    end
                end
                WR_SERVE_M1_B: begin
                    if (S1_BVALID && M1_BREADY) begin
                        ram_wr_state <= WR_IDLE;
                    end
                end
                WR_SERVE_M3: begin
                    if (M3_WVALID && S1_WREADY && M3_WLAST) begin
                        ram_wr_state <= WR_SERVE_M3_B;
                    end 
                end
                WR_SERVE_M3_B: begin
                    if (S1_BVALID && M3_BREADY) begin
                        ram_wr_state <= WR_IDLE;
                    end
                end
                default: ram_wr_state <= WR_IDLE;
            endcase
        end
    end

    wire m1_aw_active = (ram_wr_state == WR_IDLE && M1_AWVALID) ||
                            (ram_wr_state == WR_SERVE_M1) ||
                            (ram_wr_state == WR_SERVE_M1_B);
    wire m3_aw_active = (ram_wr_state == WR_IDLE && !M1_AWVALID && M3_AWVALID) ||
                        (ram_wr_state == WR_SERVE_M3) ||
                        (ram_wr_state == WR_SERVE_M3_B);

    // M1/M3 <--> S1 (d_cache <--> RAM)
    always @(*) begin
        // AR
        S1_ARVALID  = m1_ar_wins || m3_ar_wins;
        S1_ARADDR   = m1_ar_wins ? M1_ARADDR  : M3_ARADDR;
        S1_ARLEN    = m1_ar_wins ? M1_ARLEN   : M3_ARLEN;
        S1_ARSIZE   = m1_ar_wins ? M1_ARSIZE  : M3_ARSIZE;
        S1_ARBURST  = m1_ar_wins ? M1_ARBURST : M3_ARBURST;
        M1_ARREADY  = m1_ar_wins && S1_ARREADY;
        M3_ARREADY  = m3_ar_wins && S1_ARREADY;
        // R
        M1_RDATA    = (ram_rd_state == RD_SERVE_M1) ? S1_RDATA  : 32'b0;
        M1_RVALID   = (ram_rd_state == RD_SERVE_M1) ? S1_RVALID : 1'b0;
        M1_RLAST    = (ram_rd_state == RD_SERVE_M1) ? S1_RLAST  : 1'b0;
        M3_RDATA    = (ram_rd_state == RD_SERVE_M3) ? S1_RDATA  : 32'b0;
        M3_RVALID   = (ram_rd_state == RD_SERVE_M3) ? S1_RVALID : 1'b0;
        M3_RLAST    = (ram_rd_state == RD_SERVE_M3) ? S1_RLAST  : 1'b0;
        S1_RREADY   = (ram_rd_state == RD_SERVE_M1) ? M1_RREADY :
                        (ram_rd_state == RD_SERVE_M3) ? M3_RREADY : 1'b0;
        // AW
        S1_AWVALID  = m1_aw_active ? M1_AWVALID : (m3_aw_active ? M3_AWVALID : 1'b0);
        S1_AWADDR   = m1_aw_active ? M1_AWADDR  : M3_AWADDR;
        S1_AWLEN    = m1_aw_active ? M1_AWLEN   : M3_AWLEN;
        S1_AWSIZE   = m1_aw_active ? M1_AWSIZE  : M3_AWSIZE;
        S1_AWBURST  = m1_aw_active ? M1_AWBURST : M3_AWBURST;
        M1_AWREADY  = m1_aw_active ? S1_AWREADY : 1'b0;
        M3_AWREADY  = m3_aw_active ? S1_AWREADY : 1'b0;
        // W
        S1_WVALID = (ram_wr_state == WR_SERVE_M1) ? M1_WVALID :
                    (ram_wr_state == WR_SERVE_M3) ? M3_WVALID : 1'b0;
        S1_WDATA  = (ram_wr_state == WR_SERVE_M1) ? M1_WDATA  : M3_WDATA;
        S1_WLAST  = (ram_wr_state == WR_SERVE_M1) ? M1_WLAST  : M3_WLAST;
        S1_WSTRB  = (ram_wr_state == WR_SERVE_M1) ? M1_WSTRB  : M3_WSTRB;
        M1_WREADY = (ram_wr_state == WR_SERVE_M1) ? S1_WREADY : 1'b0;
        M3_WREADY = (ram_wr_state == WR_SERVE_M3) ? S1_WREADY : 1'b0;
        // B
        M1_BVALID = (ram_wr_state == WR_SERVE_M1_B) ? S1_BVALID : 1'b0;
        M1_BRESP  = (ram_wr_state == WR_SERVE_M1_B) ? S1_BRESP  : 2'b0;
        M3_BVALID = (ram_wr_state == WR_SERVE_M3_B) ? S1_BVALID : 1'b0;
        M3_BRESP  = (ram_wr_state == WR_SERVE_M3_B) ? S1_BRESP  : 2'b0;
        S1_BREADY = (ram_wr_state == WR_SERVE_M1_B) ? M1_BREADY :
                       (ram_wr_state == WR_SERVE_M3_B) ? M3_BREADY : 1'b0;
    end

endmodule
