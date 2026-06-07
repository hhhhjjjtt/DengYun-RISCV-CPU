`include "defines.v"

module soc_top #(
    parameter ROM_FILE = "rom.mem",
    parameter RAM_FILE = "ram.mem"
) (
    input wire                  i_Clk,
    input wire                  i_reset,
    
    input wire                  i_timer_int_pending,
    input wire                  i_external_int_pending
);

    // ---- CPU Outputs ----
    wire                CPU_imem_valid;
    wire[`InstAddrBus]  CPU_imem_rd_addr;

    wire                CPU_dcache_en;
    wire                CPU_mmio_en;
    wire                CPU_dmem_valid;
    wire                CPU_dmem_rd_en;
    wire[`DataAddrBus]  CPU_dmem_rd_addr;
    wire                CPU_dmem_wr_en;
    wire[`StrbBus]      CPU_dmem_wr_strb;
    wire[`DataAddrBus]  CPU_dmem_wr_addr;
    wire[`DataBus]      CPU_dmem_wr_data;

    // ---- I_Cache Outputs ----
    wire                I_Cache_imem_ready;
    wire[`DataBus]      I_Cache_imem_rd_data;

    wire[31:0]          I_Cache_axi_araddr;
    wire                I_Cache_axi_arvalid;
    wire[7:0]           I_Cache_axi_arlen;
    wire[2:0]           I_Cache_axi_arsize;
    wire[1:0]           I_Cache_axi_arburst;

    wire                I_Cache_axi_rready;

    // ---- D_Cache Outputs ----
    wire                D_Cache_dmem_ready;
    wire[`DataBus]      D_Cache_dmem_rd_data;

    wire[31:0]          D_Cache_axi_araddr;
    wire                D_Cache_axi_arvalid;
    wire[7:0]           D_Cache_axi_arlen;
    wire[2:0]           D_Cache_axi_arsize;
    wire[1:0]           D_Cache_axi_arburst;

    wire                D_Cache_axi_rready;

    wire[31:0]          D_Cache_axi_awaddr;
    wire                D_Cache_axi_awvalid;
    wire[7:0]           D_Cache_axi_awlen;
    wire[2:0]           D_Cache_axi_awsize;
    wire[1:0]           D_Cache_axi_awburst;

    wire[31:0]          D_Cache_axi_wdata;
    wire                D_Cache_axi_wvalid;
    wire                D_Cache_axi_wlast;
    wire[3:0]           D_Cache_axi_wstrb;

    wire                D_Cache_axi_bready;

    // ---- MMIO_Port Outputs ----
    wire                MMIO_Port_dmem_ready;
    wire[`DataBus]      MMIO_Port_dmem_rd_data;

    wire[31:0]          MMIO_Port_axi_araddr;
    wire                MMIO_Port_axi_arvalid;
    wire[7:0]           MMIO_Port_axi_arlen;
    wire[2:0]           MMIO_Port_axi_arsize;
    wire[1:0]           MMIO_Port_axi_arburst;

    wire                MMIO_Port_axi_rready;

    wire[31:0]          MMIO_Port_axi_awaddr;
    wire                MMIO_Port_axi_awvalid;
    wire[7:0]           MMIO_Port_axi_awlen;
    wire[2:0]           MMIO_Port_axi_awsize;
    wire[1:0]           MMIO_Port_axi_awburst;

    wire[31:0]          MMIO_Port_axi_wdata;
    wire                MMIO_Port_axi_wvalid;
    wire                MMIO_Port_axi_wlast;
    wire[3:0]           MMIO_Port_axi_wstrb;

    wire                MMIO_Port_axi_bready;

    // ---- AIX4 Outputs ----
    wire                M0_ARREADY;
    wire[31:0]          M0_RDATA;
    wire                M0_RVALID;
    wire                M0_RLAST;

    wire                M1_ARREADY;
    wire[31:0]          M1_RDATA;
    wire                M1_RVALID;
    wire                M1_RLAST;
    wire                M1_AWREADY;
    wire                M1_WREADY;
    wire[1:0]           M1_BRESP;
    wire                M1_BVALID;

    wire                M2_ARREADY;
    wire[31:0]          M2_RDATA;
    wire                M2_RVALID;
    wire                M2_RLAST;
    wire                M2_AWREADY;
    wire                M2_WREADY;
    wire[1:0]           M2_BRESP;
    wire                M2_BVALID;

    wire                M3_ARREADY;
    wire[31:0]          M3_RDATA;
    wire                M3_RVALID;
    wire                M3_RLAST;
    wire                M3_AWREADY;
    wire                M3_WREADY;
    wire[1:0]           M3_BRESP;
    wire                M3_BVALID;

    wire[31:0]          S0_ARADDR;
    wire                S0_ARVALID;
    wire[7:0]           S0_ARLEN;
    wire[2:0]           S0_ARSIZE;
    wire[1:0]           S0_ARBURST;
    wire                S0_RREADY;

    wire[31:0]          S1_ARADDR;
    wire                S1_ARVALID;
    wire[7:0]           S1_ARLEN;
    wire[2:0]           S1_ARSIZE;
    wire[1:0]           S1_ARBURST;
    wire                S1_RREADY;
    wire[31:0]          S1_AWADDR;
    wire                S1_AWVALID;
    wire[7:0]           S1_AWLEN;
    wire[2:0]           S1_AWSIZE;
    wire[1:0]           S1_AWBURST;
    wire[31:0]          S1_WDATA;
    wire                S1_WVALID;
    wire                S1_WLAST;
    wire[3:0]           S1_WSTRB;
    wire                S1_BREADY;

    wire[31:0]          S2_ARADDR;
    wire                S2_ARVALID;
    wire[7:0]           S2_ARLEN;
    wire[2:0]           S2_ARSIZE;
    wire[1:0]           S2_ARBURST;
    wire                S2_RREADY;
    wire[31:0]          S2_AWADDR;
    wire                S2_AWVALID;
    wire[7:0]           S2_AWLEN;
    wire[2:0]           S2_AWSIZE;
    wire[1:0]           S2_AWBURST;
    wire[31:0]          S2_WDATA;
    wire                S2_WVALID;
    wire                S2_WLAST;
    wire[3:0]           S2_WSTRB;
    wire                S2_BREADY;

    // ---- Rom Outputs ----
    wire                Rom_axi_arready;

    wire[31:0]          Rom_axi_rdata;
    wire                Rom_axi_rvalid;
    wire                Rom_axi_rlast;

    // ---- Ram Outputs ----
    wire                Ram_axi_arready;

    wire[31:0]          Ram_axi_rdata;
    wire                Ram_axi_rvalid;
    wire                Ram_axi_rlast;

    wire                Ram_axi_awready;

    wire                Ram_axi_wready;

    wire[1:0]           Ram_axi_bresp;
    wire                Ram_axi_bvalid;

    CPU CPU_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_timer_int_pending    (i_timer_int_pending),
        .i_external_int_pending (i_external_int_pending),

        .o_imem_valid           (CPU_imem_valid),
        .i_imem_ready           (I_Cache_imem_ready),
        .o_imem_rd_addr         (CPU_imem_rd_addr),
        .i_imem_rd_data         (I_Cache_imem_rd_data),

        .o_dcache_en            (CPU_dcache_en),
        .o_mmio_en              (CPU_mmio_en),
        .o_dmem_valid           (CPU_dmem_valid),
        .i_dmem_ready           (D_Cache_dmem_ready | MMIO_Port_dmem_ready),
        .o_dmem_rd_en           (CPU_dmem_rd_en),
        .o_dmem_rd_addr         (CPU_dmem_rd_addr),
        .i_dmem_rd_data         (CPU_dcache_en ? D_Cache_dmem_rd_data : MMIO_Port_dmem_rd_data),
        .o_dmem_wr_en           (CPU_dmem_wr_en),
        .o_dmem_wr_strb         (CPU_dmem_wr_strb),
        .o_dmem_wr_addr         (CPU_dmem_wr_addr),
        .o_dmem_wr_data         (CPU_dmem_wr_data)
    );

    I_Cache I_Cache_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_imem_valid           (CPU_imem_valid),
        .o_imem_ready           (I_Cache_imem_ready),
        .i_imem_rd_addr         (CPU_imem_rd_addr),
        .o_imem_rd_data         (I_Cache_imem_rd_data),

        .o_axi_araddr           (I_Cache_axi_araddr),
        .o_axi_arvalid          (I_Cache_axi_arvalid),
        .i_axi_arready          (M0_ARREADY),
        .o_axi_arlen            (I_Cache_axi_arlen),
        .o_axi_arsize           (I_Cache_axi_arsize),
        .o_axi_arburst          (I_Cache_axi_arburst),

        .i_axi_rdata            (M0_RDATA),
        .i_axi_rvalid           (M0_RVALID),
        .o_axi_rready           (I_Cache_axi_rready),
        .i_axi_rlast            (M0_RLAST)
    );

    D_Cache D_Cache_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_dmem_valid           (CPU_dmem_valid && CPU_dcache_en),
        .o_dmem_ready           (D_Cache_dmem_ready),
        .i_dmem_rd_en           (CPU_dmem_rd_en),
        .i_dmem_rd_addr         (CPU_dmem_rd_addr),
        .o_dmem_rd_data         (D_Cache_dmem_rd_data),
        .i_dmem_wr_en           (CPU_dmem_wr_en),
        .i_dmem_wr_strb         (CPU_dmem_wr_strb),
        .i_dmem_wr_addr         (CPU_dmem_wr_addr),
        .i_dmem_wr_data         (CPU_dmem_wr_data),

        .o_axi_araddr           (D_Cache_axi_araddr),
        .o_axi_arvalid          (D_Cache_axi_arvalid),
        .i_axi_arready          (M1_ARREADY),
        .o_axi_arlen            (D_Cache_axi_arlen),
        .o_axi_arsize           (D_Cache_axi_arsize),
        .o_axi_arburst          (D_Cache_axi_arburst),

        .i_axi_rdata            (M1_RDATA),
        .i_axi_rvalid           (M1_RVALID),
        .o_axi_rready           (D_Cache_axi_rready),
        .i_axi_rlast            (M1_RLAST),

        .o_axi_awaddr           (D_Cache_axi_awaddr),
        .o_axi_awvalid          (D_Cache_axi_awvalid),
        .i_axi_awready          (M1_AWREADY),
        .o_axi_awlen            (D_Cache_axi_awlen),
        .o_axi_awsize           (D_Cache_axi_awsize),
        .o_axi_awburst          (D_Cache_axi_awburst),

        .o_axi_wdata            (D_Cache_axi_wdata),
        .o_axi_wvalid           (D_Cache_axi_wvalid),
        .i_axi_wready           (M1_WREADY),
        .o_axi_wlast            (D_Cache_axi_wlast),
        .o_axi_wstrb            (D_Cache_axi_wstrb),

        .i_axi_bresp            (M1_BRESP),
        .i_axi_bvalid           (M1_BVALID),
        .o_axi_bready           (D_Cache_axi_bready)
    );

    MMIO_Port MMIO_Port_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_dmem_valid           (CPU_dmem_valid && CPU_mmio_en),
        .o_dmem_ready           (MMIO_Port_dmem_ready),
        .i_dmem_rd_en           (CPU_dmem_rd_en),
        .i_dmem_rd_addr         (CPU_dmem_rd_addr),
        .o_dmem_rd_data         (MMIO_Port_dmem_rd_data),
        .i_dmem_wr_en           (CPU_dmem_wr_en),
        .i_dmem_wr_strb         (CPU_dmem_wr_strb),
        .i_dmem_wr_addr         (CPU_dmem_wr_addr),
        .i_dmem_wr_data         (CPU_dmem_wr_data),

        .o_axi_araddr           (MMIO_Port_axi_araddr),
        .o_axi_arvalid          (MMIO_Port_axi_arvalid),
        .i_axi_arready          (M2_ARREADY),
        .o_axi_arlen            (MMIO_Port_axi_arlen),
        .o_axi_arsize           (MMIO_Port_axi_arsize),
        .o_axi_arburst          (MMIO_Port_axi_arburst),

        .i_axi_rdata            (M2_RDATA),
        .i_axi_rvalid           (M2_RVALID),
        .o_axi_rready           (MMIO_Port_axi_rready),
        .i_axi_rlast            (M2_RLAST),

        .o_axi_awaddr           (MMIO_Port_axi_awaddr),
        .o_axi_awvalid          (MMIO_Port_axi_awvalid),
        .i_axi_awready          (M2_AWREADY),
        .o_axi_awlen            (MMIO_Port_axi_awlen),
        .o_axi_awsize           (MMIO_Port_axi_awsize),
        .o_axi_awburst          (MMIO_Port_axi_awburst),

        .o_axi_wdata            (MMIO_Port_axi_wdata),
        .o_axi_wvalid           (MMIO_Port_axi_wvalid),
        .i_axi_wready           (M2_WREADY),
        .o_axi_wlast            (MMIO_Port_axi_wlast),
        .o_axi_wstrb            (MMIO_Port_axi_wstrb),

        .i_axi_bresp            (M2_BRESP),
        .i_axi_bvalid           (M2_BVALID),
        .o_axi_bready           (MMIO_Port_axi_bready)
    );

    AXI4 AXI4_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .M0_ARADDR              (I_Cache_axi_araddr),
        .M0_ARVALID             (I_Cache_axi_arvalid),
        .M0_ARREADY             (M0_ARREADY),
        .M0_ARLEN               (I_Cache_axi_arlen),
        .M0_ARSIZE              (I_Cache_axi_arsize),
        .M0_ARBURST             (I_Cache_axi_arburst),
        .M0_RDATA               (M0_RDATA),
        .M0_RVALID              (M0_RVALID),
        .M0_RREADY              (I_Cache_axi_rready),
        .M0_RLAST               (M0_RLAST),

        .M1_ARADDR              (D_Cache_axi_araddr),
        .M1_ARVALID             (D_Cache_axi_arvalid),
        .M1_ARREADY             (M1_ARREADY),
        .M1_ARLEN               (D_Cache_axi_arlen),
        .M1_ARSIZE              (D_Cache_axi_arsize),
        .M1_ARBURST             (D_Cache_axi_arburst),
        .M1_RDATA               (M1_RDATA),
        .M1_RVALID              (M1_RVALID),
        .M1_RREADY              (D_Cache_axi_rready),
        .M1_RLAST               (M1_RLAST),
        .M1_AWADDR              (D_Cache_axi_awaddr),
        .M1_AWVALID             (D_Cache_axi_awvalid),
        .M1_AWREADY             (M1_AWREADY),
        .M1_AWLEN               (D_Cache_axi_awlen),
        .M1_AWSIZE              (D_Cache_axi_awsize),
        .M1_AWBURST             (D_Cache_axi_awburst),
        .M1_WDATA               (D_Cache_axi_wdata),
        .M1_WVALID              (D_Cache_axi_wvalid),
        .M1_WREADY              (M1_WREADY),
        .M1_WLAST               (D_Cache_axi_wlast),
        .M1_WSTRB               (D_Cache_axi_wstrb),
        .M1_BRESP               (M1_BRESP),
        .M1_BVALID              (M1_BVALID),
        .M1_BREADY              (D_Cache_axi_bready),

        .M2_ARADDR              (MMIO_Port_axi_araddr),
        .M2_ARVALID             (MMIO_Port_axi_arvalid),
        .M2_ARREADY             (M2_ARREADY),
        .M2_ARLEN               (MMIO_Port_axi_arlen),
        .M2_ARSIZE              (MMIO_Port_axi_arsize),
        .M2_ARBURST             (MMIO_Port_axi_arburst),
        .M2_RDATA               (M2_RDATA),
        .M2_RVALID              (M2_RVALID),
        .M2_RREADY              (MMIO_Port_axi_rready),
        .M2_RLAST               (M2_RLAST),
        .M2_AWADDR              (MMIO_Port_axi_awaddr),
        .M2_AWVALID             (MMIO_Port_axi_awvalid),
        .M2_AWREADY             (M2_AWREADY),
        .M2_AWLEN               (MMIO_Port_axi_awlen),
        .M2_AWSIZE              (MMIO_Port_axi_awsize),
        .M2_AWBURST             (MMIO_Port_axi_awburst),
        .M2_WDATA               (MMIO_Port_axi_wdata),
        .M2_WVALID              (MMIO_Port_axi_wvalid),
        .M2_WREADY              (M2_WREADY),
        .M2_WLAST               (MMIO_Port_axi_wlast),
        .M2_WSTRB               (MMIO_Port_axi_wstrb),
        .M2_BRESP               (M2_BRESP),
        .M2_BVALID              (M2_BVALID),
        .M2_BREADY              (MMIO_Port_axi_bready),

        // for future DMA, unused for now
        .M3_ARADDR              (32'b0),
        .M3_ARVALID             (1'b0),
        .M3_ARREADY             (M3_ARREADY),
        .M3_ARLEN               (8'd0),
        .M3_ARSIZE              (3'd2),
        .M3_ARBURST             (2'b01),
        .M3_RDATA               (M3_RDATA),
        .M3_RVALID              (M3_RVALID),
        .M3_RREADY              (1'b0),
        .M3_RLAST               (M3_RLAST),
        .M3_AWADDR              (32'b0),
        .M3_AWVALID             (1'b0),
        .M3_AWREADY             (M3_AWREADY),
        .M3_AWLEN               (8'd0),
        .M3_AWSIZE              (3'd2),
        .M3_AWBURST             (2'b01),
        .M3_WDATA               (32'b0),
        .M3_WVALID              (1'b0),
        .M3_WREADY              (M3_WREADY),
        .M3_WLAST               (1'b0),
        .M3_WSTRB               (4'b0),
        .M3_BRESP               (M3_BRESP),
        .M3_BVALID              (M3_BVALID),
        .M3_BREADY              (1'b0),

        .S0_ARADDR              (S0_ARADDR),
        .S0_ARVALID             (S0_ARVALID),
        .S0_ARREADY             (Rom_axi_arready),
        .S0_ARLEN               (S0_ARLEN),
        .S0_ARSIZE              (S0_ARSIZE),
        .S0_ARBURST             (S0_ARBURST),
        .S0_RDATA               (Rom_axi_rdata),
        .S0_RVALID              (Rom_axi_rvalid),
        .S0_RREADY              (S0_RREADY),
        .S0_RLAST               (Rom_axi_rlast),

        .S1_ARADDR              (S1_ARADDR),
        .S1_ARVALID             (S1_ARVALID),
        .S1_ARREADY             (Ram_axi_arready),
        .S1_ARLEN               (S1_ARLEN),
        .S1_ARSIZE              (S1_ARSIZE),
        .S1_ARBURST             (S1_ARBURST),
        .S1_RDATA               (Ram_axi_rdata),
        .S1_RVALID              (Ram_axi_rvalid),
        .S1_RREADY              (S1_RREADY),
        .S1_RLAST               (Ram_axi_rlast),
        .S1_AWADDR              (S1_AWADDR),
        .S1_AWVALID             (S1_AWVALID),
        .S1_AWREADY             (Ram_axi_awready),
        .S1_AWLEN               (S1_AWLEN),
        .S1_AWSIZE              (S1_AWSIZE),
        .S1_AWBURST             (S1_AWBURST),
        .S1_WDATA               (S1_WDATA),
        .S1_WVALID              (S1_WVALID),
        .S1_WREADY              (Ram_axi_wready),
        .S1_WLAST               (S1_WLAST),
        .S1_WSTRB               (S1_WSTRB),
        .S1_BRESP               (Ram_axi_bresp),
        .S1_BVALID              (Ram_axi_bvalid),
        .S1_BREADY              (S1_BREADY),

        // for future peripherals (UART, SPI, IIC), unused for now
        .S2_ARADDR              (S2_ARADDR),
        .S2_ARVALID             (S2_ARVALID),
        .S2_ARREADY             (1'b0),
        .S2_ARLEN               (S2_ARLEN),
        .S2_ARSIZE              (S2_ARSIZE),
        .S2_ARBURST             (S2_ARBURST),
        .S2_RDATA               (32'b0),
        .S2_RVALID              (1'b0),
        .S2_RREADY              (S2_RREADY),
        .S2_RLAST               (1'b0),
        .S2_AWADDR              (S2_AWADDR),
        .S2_AWVALID             (S2_AWVALID),
        .S2_AWREADY             (1'b0),
        .S2_AWLEN               (S2_AWLEN),
        .S2_AWSIZE              (S2_AWSIZE),
        .S2_AWBURST             (S2_AWBURST),
        .S2_WDATA               (S2_WDATA),
        .S2_WVALID              (S2_WVALID),
        .S2_WREADY              (1'b0),
        .S2_WLAST               (S2_WLAST),
        .S2_WSTRB               (S2_WSTRB),
        .S2_BRESP               (2'b00),
        .S2_BVALID              (1'b0),
        .S2_BREADY              (S2_BREADY)
    );

    Rom #(
        .MEM_FILE(ROM_FILE)
    ) Rom_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_axi_araddr           (S0_ARADDR),
        .i_axi_arvalid          (S0_ARVALID),
        .o_axi_arready          (Rom_axi_arready),
        .i_axi_arlen            (S0_ARLEN),
        .i_axi_arsize           (S0_ARSIZE),
        .i_axi_arburst          (S0_ARBURST),

        .o_axi_rdata            (Rom_axi_rdata),
        .o_axi_rvalid           (Rom_axi_rvalid),
        .i_axi_rready           (S0_RREADY),
        .o_axi_rlast            (Rom_axi_rlast)
    );

    Ram #(
        .MEM_FILE(RAM_FILE)
    ) Ram_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S1_ARADDR),
        .i_axi_arvalid          (S1_ARVALID),
        .o_axi_arready          (Ram_axi_arready),
        .i_axi_arlen            (S1_ARLEN),
        .i_axi_arsize           (S1_ARSIZE),
        .i_axi_arburst          (S1_ARBURST),

        .o_axi_rdata            (Ram_axi_rdata),
        .o_axi_rvalid           (Ram_axi_rvalid),
        .i_axi_rready           (S1_RREADY),
        .o_axi_rlast            (Ram_axi_rlast),

        .i_axi_awaddr           (S1_AWADDR),
        .i_axi_awvalid          (S1_AWVALID),
        .o_axi_awready          (Ram_axi_awready),
        .i_axi_awlen            (S1_AWLEN),
        .i_axi_awsize           (S1_AWSIZE),
        .i_axi_awburst          (S1_AWBURST),

        .i_axi_wdata            (S1_WDATA),
        .i_axi_wvalid           (S1_WVALID),
        .o_axi_wready           (Ram_axi_wready),
        .i_axi_wlast            (S1_WLAST),
        .i_axi_wstrb            (S1_WSTRB),

        .o_axi_bresp            (Ram_axi_bresp),
        .o_axi_bvalid           (Ram_axi_bvalid),
        .i_axi_bready           (S1_BREADY)
    );
    
endmodule
