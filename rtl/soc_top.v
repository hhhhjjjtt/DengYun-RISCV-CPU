`include "defines.v"

module soc_top #(
    parameter ROM_FILE = "rom.mem",
    parameter RAM_FILE = "ram.mem",
    parameter GPIO_N   = 2
) (
    input wire                  i_Clk,
    input wire                  i_reset,

    // Peripheral: UART
    output wire                 o_tx_serial,
    input wire                  i_rx_serial,

    // Peripheral: GPIO
    inout wire[GPIO_N-1:0]      gpio_pins
);

    // ---- cpu_core Outputs ----
    wire                cpu_core_imem_valid;
    wire[`InstAddrBus]  cpu_core_imem_rd_addr;

    wire                cpu_core_dcache_en;
    wire                cpu_core_mmio_en;
    wire                cpu_core_dmem_valid;
    wire                cpu_core_dmem_rd_en;
    wire[`DataAddrBus]  cpu_core_dmem_rd_addr;
    wire                cpu_core_dmem_wr_en;
    wire[`StrbBus]      cpu_core_dmem_wr_strb;
    wire[`DataAddrBus]  cpu_core_dmem_wr_addr;
    wire[`DataBus]      cpu_core_dmem_wr_data;

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

    wire[31:0]          S3_ARADDR;
    wire                S3_ARVALID;
    wire[7:0]           S3_ARLEN;
    wire[2:0]           S3_ARSIZE;
    wire[1:0]           S3_ARBURST;
    wire                S3_RREADY;
    wire[31:0]          S3_AWADDR;
    wire                S3_AWVALID;
    wire[7:0]           S3_AWLEN;
    wire[2:0]           S3_AWSIZE;
    wire[1:0]           S3_AWBURST;
    wire[31:0]          S3_WDATA;
    wire                S3_WVALID;
    wire                S3_WLAST;
    wire[3:0]           S3_WSTRB;
    wire                S3_BREADY;

    wire[31:0]          S4_ARADDR;
    wire                S4_ARVALID;
    wire[7:0]           S4_ARLEN;
    wire[2:0]           S4_ARSIZE;
    wire[1:0]           S4_ARBURST;
    wire                S4_RREADY;
    wire[31:0]          S4_AWADDR;
    wire                S4_AWVALID;
    wire[7:0]           S4_AWLEN;
    wire[2:0]           S4_AWSIZE;
    wire[1:0]           S4_AWBURST;
    wire[31:0]          S4_WDATA;
    wire                S4_WVALID;
    wire                S4_WLAST;
    wire[3:0]           S4_WSTRB;
    wire                S4_BREADY;

    wire[31:0]          S6_ARADDR;
    wire                S6_ARVALID;
    wire[7:0]           S6_ARLEN;
    wire[2:0]           S6_ARSIZE;
    wire[1:0]           S6_ARBURST;
    wire                S6_RREADY;
    wire[31:0]          S6_AWADDR;
    wire                S6_AWVALID;
    wire[7:0]           S6_AWLEN;
    wire[2:0]           S6_AWSIZE;
    wire[1:0]           S6_AWBURST;
    wire[31:0]          S6_WDATA;
    wire                S6_WVALID;
    wire                S6_WLAST;
    wire[3:0]           S6_WSTRB;
    wire                S6_BREADY;

    // ---- ROM Outputs ----
    wire                ROM_axi_arready;

    wire[31:0]          ROM_axi_rdata;
    wire                ROM_axi_rvalid;
    wire                ROM_axi_rlast;

    // ---- RAM Outputs ----
    wire                RAM_axi_arready;

    wire[31:0]          RAM_axi_rdata;
    wire                RAM_axi_rvalid;
    wire                RAM_axi_rlast;

    wire                RAM_axi_awready;

    wire                RAM_axi_wready;

    wire[1:0]           RAM_axi_bresp;
    wire                RAM_axi_bvalid;

    // ---- PLIC Outputs ----
    wire                PLIC_axi_arready;

    wire[31:0]          PLIC_axi_rdata;
    wire                PLIC_axi_rvalid;
    wire                PLIC_axi_rlast;

    wire                PLIC_axi_awready;

    wire                PLIC_axi_wready;

    wire[1:0]           PLIC_axi_bresp;
    wire                PLIC_axi_bvalid;

    wire                PLIC_external_int_pending;

    // ---- UART Outputs ----
    wire                UART_axi_arready;

    wire[31:0]          UART_axi_rdata;
    wire                UART_axi_rvalid;
    wire                UART_axi_rlast;

    wire                UART_axi_awready;

    wire                UART_axi_wready;

    wire[1:0]           UART_axi_bresp;
    wire                UART_axi_bvalid;

    wire                UART_tx_done;
    wire                UART_tx_busy;

    wire                UART_rx_valid;

    // ---- GPIO Outputs ----
    wire                GPIO_axi_arready;

    wire[31:0]          GPIO_axi_rdata;
    wire                GPIO_axi_rvalid;
    wire                GPIO_axi_rlast;

    wire                GPIO_axi_awready;

    wire                GPIO_axi_wready;

    wire[1:0]           GPIO_axi_bresp;
    wire                GPIO_axi_bvalid;

    wire                GPIO_interrupt;

    wire[GPIO_N-1:0]    GPIO_out;
    wire[GPIO_N-1:0]    GPIO_out_en;
    wire[GPIO_N-1:0]    GPIO_in;

    genvar gi;
    generate
        for (gi = 0; gi < GPIO_N; gi = gi + 1) begin : gpio_iobuf
            IOBUF iobuf (
                .IO (gpio_pins[gi]),
                .I  (GPIO_out[gi]),
                .T  (~GPIO_out_en[gi]),  // T=1 = hi-Z, high=input, low=output
                .O  (GPIO_in[gi])
            );
        end
    endgenerate

    // ---- CLINT Outputs ----
    wire                CLINT_axi_arready;

    wire[31:0]          CLINT_axi_rdata;
    wire                CLINT_axi_rvalid;
    wire                CLINT_axi_rlast;

    wire                CLINT_axi_awready;

    wire                CLINT_axi_wready;

    wire[1:0]           CLINT_axi_bresp;
    wire                CLINT_axi_bvalid;

    wire                CLINT_timer_int_pending;    

    cpu_core cpu_core_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_timer_int_pending    (CLINT_timer_int_pending),
        .i_external_int_pending (PLIC_external_int_pending),

        .o_imem_valid           (cpu_core_imem_valid),
        .i_imem_ready           (I_Cache_imem_ready),
        .o_imem_rd_addr         (cpu_core_imem_rd_addr),
        .i_imem_rd_data         (I_Cache_imem_rd_data),

        .o_dcache_en            (cpu_core_dcache_en),
        .o_mmio_en              (cpu_core_mmio_en),
        .o_dmem_valid           (cpu_core_dmem_valid),
        .i_dmem_ready           (D_Cache_dmem_ready | MMIO_Port_dmem_ready),
        .o_dmem_rd_en           (cpu_core_dmem_rd_en),
        .o_dmem_rd_addr         (cpu_core_dmem_rd_addr),
        .i_dmem_rd_data         (cpu_core_dcache_en ? D_Cache_dmem_rd_data : MMIO_Port_dmem_rd_data),
        .o_dmem_wr_en           (cpu_core_dmem_wr_en),
        .o_dmem_wr_strb         (cpu_core_dmem_wr_strb),
        .o_dmem_wr_addr         (cpu_core_dmem_wr_addr),
        .o_dmem_wr_data         (cpu_core_dmem_wr_data)
    );

    I_Cache I_Cache_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_imem_valid           (cpu_core_imem_valid),
        .o_imem_ready           (I_Cache_imem_ready),
        .i_imem_rd_addr         (cpu_core_imem_rd_addr),
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

        .i_dmem_valid           (cpu_core_dmem_valid && cpu_core_dcache_en),
        .o_dmem_ready           (D_Cache_dmem_ready),
        .i_dmem_rd_en           (cpu_core_dmem_rd_en),
        .i_dmem_rd_addr         (cpu_core_dmem_rd_addr),
        .o_dmem_rd_data         (D_Cache_dmem_rd_data),
        .i_dmem_wr_en           (cpu_core_dmem_wr_en),
        .i_dmem_wr_strb         (cpu_core_dmem_wr_strb),
        .i_dmem_wr_addr         (cpu_core_dmem_wr_addr),
        .i_dmem_wr_data         (cpu_core_dmem_wr_data),

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

        .i_dmem_valid           (cpu_core_dmem_valid && cpu_core_mmio_en),
        .o_dmem_ready           (MMIO_Port_dmem_ready),
        .i_dmem_rd_en           (cpu_core_dmem_rd_en),
        .i_dmem_rd_addr         (cpu_core_dmem_rd_addr),
        .o_dmem_rd_data         (MMIO_Port_dmem_rd_data),
        .i_dmem_wr_en           (cpu_core_dmem_wr_en),
        .i_dmem_wr_strb         (cpu_core_dmem_wr_strb),
        .i_dmem_wr_addr         (cpu_core_dmem_wr_addr),
        .i_dmem_wr_data         (cpu_core_dmem_wr_data),

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

        // ROM
        .S0_ARADDR              (S0_ARADDR),
        .S0_ARVALID             (S0_ARVALID),
        .S0_ARREADY             (ROM_axi_arready),
        .S0_ARLEN               (S0_ARLEN),
        .S0_ARSIZE              (S0_ARSIZE),
        .S0_ARBURST             (S0_ARBURST),
        .S0_RDATA               (ROM_axi_rdata),
        .S0_RVALID              (ROM_axi_rvalid),
        .S0_RREADY              (S0_RREADY),
        .S0_RLAST               (ROM_axi_rlast),

        // RAM
        .S1_ARADDR              (S1_ARADDR),
        .S1_ARVALID             (S1_ARVALID),
        .S1_ARREADY             (RAM_axi_arready),
        .S1_ARLEN               (S1_ARLEN),
        .S1_ARSIZE              (S1_ARSIZE),
        .S1_ARBURST             (S1_ARBURST),
        .S1_RDATA               (RAM_axi_rdata),
        .S1_RVALID              (RAM_axi_rvalid),
        .S1_RREADY              (S1_RREADY),
        .S1_RLAST               (RAM_axi_rlast),
        .S1_AWADDR              (S1_AWADDR),
        .S1_AWVALID             (S1_AWVALID),
        .S1_AWREADY             (RAM_axi_awready),
        .S1_AWLEN               (S1_AWLEN),
        .S1_AWSIZE              (S1_AWSIZE),
        .S1_AWBURST             (S1_AWBURST),
        .S1_WDATA               (S1_WDATA),
        .S1_WVALID              (S1_WVALID),
        .S1_WREADY              (RAM_axi_wready),
        .S1_WLAST               (S1_WLAST),
        .S1_WSTRB               (S1_WSTRB),
        .S1_BRESP               (RAM_axi_bresp),
        .S1_BVALID              (RAM_axi_bvalid),
        .S1_BREADY              (S1_BREADY),

        // PLIC
        .S2_ARADDR              (S2_ARADDR),
        .S2_ARVALID             (S2_ARVALID),
        .S2_ARREADY             (PLIC_axi_arready),
        .S2_ARLEN               (S2_ARLEN),
        .S2_ARSIZE              (S2_ARSIZE),
        .S2_ARBURST             (S2_ARBURST),
        .S2_RDATA               (PLIC_axi_rdata),
        .S2_RVALID              (PLIC_axi_rvalid),
        .S2_RREADY              (S2_RREADY),
        .S2_RLAST               (PLIC_axi_rlast),
        .S2_AWADDR              (S2_AWADDR),
        .S2_AWVALID             (S2_AWVALID),
        .S2_AWREADY             (PLIC_axi_awready),
        .S2_AWLEN               (S2_AWLEN),
        .S2_AWSIZE              (S2_AWSIZE),
        .S2_AWBURST             (S2_AWBURST),
        .S2_WDATA               (S2_WDATA),
        .S2_WVALID              (S2_WVALID),
        .S2_WREADY              (PLIC_axi_wready),
        .S2_WLAST               (S2_WLAST),
        .S2_WSTRB               (S2_WSTRB),
        .S2_BRESP               (PLIC_axi_bresp),
        .S2_BVALID              (PLIC_axi_bvalid),
        .S2_BREADY              (S2_BREADY),

        // UART
        .S3_ARADDR              (S3_ARADDR),
        .S3_ARVALID             (S3_ARVALID),
        .S3_ARREADY             (UART_axi_arready),
        .S3_ARLEN               (S3_ARLEN),
        .S3_ARSIZE              (S3_ARSIZE),
        .S3_ARBURST             (S3_ARBURST),
        .S3_RDATA               (UART_axi_rdata),
        .S3_RVALID              (UART_axi_rvalid),
        .S3_RREADY              (S3_RREADY),
        .S3_RLAST               (UART_axi_rlast),
        .S3_AWADDR              (S3_AWADDR),
        .S3_AWVALID             (S3_AWVALID),
        .S3_AWREADY             (UART_axi_awready),
        .S3_AWLEN               (S3_AWLEN),
        .S3_AWSIZE              (S3_AWSIZE),
        .S3_AWBURST             (S3_AWBURST),
        .S3_WDATA               (S3_WDATA),
        .S3_WVALID              (S3_WVALID),
        .S3_WREADY              (UART_axi_wready),
        .S3_WLAST               (S3_WLAST),
        .S3_WSTRB               (S3_WSTRB),
        .S3_BRESP               (UART_axi_bresp),
        .S3_BVALID              (UART_axi_bvalid),
        .S3_BREADY              (S3_BREADY),

        // GPIO
        .S4_ARADDR              (S4_ARADDR),
        .S4_ARVALID             (S4_ARVALID),
        .S4_ARREADY             (GPIO_axi_arready),
        .S4_ARLEN               (S4_ARLEN),
        .S4_ARSIZE              (S4_ARSIZE),
        .S4_ARBURST             (S4_ARBURST),
        .S4_RDATA               (GPIO_axi_rdata),
        .S4_RVALID              (GPIO_axi_rvalid),
        .S4_RREADY              (S4_RREADY),
        .S4_RLAST               (GPIO_axi_rlast),
        .S4_AWADDR              (S4_AWADDR),
        .S4_AWVALID             (S4_AWVALID),
        .S4_AWREADY             (GPIO_axi_awready),
        .S4_AWLEN               (S4_AWLEN),
        .S4_AWSIZE              (S4_AWSIZE),
        .S4_AWBURST             (S4_AWBURST),
        .S4_WDATA               (S4_WDATA),
        .S4_WVALID              (S4_WVALID),
        .S4_WREADY              (GPIO_axi_wready),
        .S4_WLAST               (S4_WLAST),
        .S4_WSTRB               (S4_WSTRB),
        .S4_BRESP               (GPIO_axi_bresp),
        .S4_BVALID              (GPIO_axi_bvalid),
        .S4_BREADY              (S4_BREADY),

        // CLINT
        .S6_ARADDR              (S6_ARADDR),
        .S6_ARVALID             (S6_ARVALID),
        .S6_ARREADY             (CLINT_axi_arready),
        .S6_ARLEN               (S6_ARLEN),
        .S6_ARSIZE              (S6_ARSIZE),
        .S6_ARBURST             (S6_ARBURST),
        .S6_RDATA               (CLINT_axi_rdata),
        .S6_RVALID              (CLINT_axi_rvalid),
        .S6_RREADY              (S6_RREADY),
        .S6_RLAST               (CLINT_axi_rlast),
        .S6_AWADDR              (S6_AWADDR),
        .S6_AWVALID             (S6_AWVALID),
        .S6_AWREADY             (CLINT_axi_awready),
        .S6_AWLEN               (S6_AWLEN),
        .S6_AWSIZE              (S6_AWSIZE),
        .S6_AWBURST             (S6_AWBURST),
        .S6_WDATA               (S6_WDATA),
        .S6_WVALID              (S6_WVALID),
        .S6_WREADY              (CLINT_axi_wready),
        .S6_WLAST               (S6_WLAST),
        .S6_WSTRB               (S6_WSTRB),
        .S6_BRESP               (CLINT_axi_bresp),
        .S6_BVALID              (CLINT_axi_bvalid),
        .S6_BREADY              (S6_BREADY)
    );

    ROM #(
        .MEM_FILE(ROM_FILE)
    ) ROM_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_axi_araddr           (S0_ARADDR),
        .i_axi_arvalid          (S0_ARVALID),
        .o_axi_arready          (ROM_axi_arready),
        .i_axi_arlen            (S0_ARLEN),
        .i_axi_arsize           (S0_ARSIZE),
        .i_axi_arburst          (S0_ARBURST),

        .o_axi_rdata            (ROM_axi_rdata),
        .o_axi_rvalid           (ROM_axi_rvalid),
        .i_axi_rready           (S0_RREADY),
        .o_axi_rlast            (ROM_axi_rlast)
    );

    RAM #(
        .MEM_FILE(RAM_FILE)
    ) RAM_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S1_ARADDR),
        .i_axi_arvalid          (S1_ARVALID),
        .o_axi_arready          (RAM_axi_arready),
        .i_axi_arlen            (S1_ARLEN),
        .i_axi_arsize           (S1_ARSIZE),
        .i_axi_arburst          (S1_ARBURST),

        .o_axi_rdata            (RAM_axi_rdata),
        .o_axi_rvalid           (RAM_axi_rvalid),
        .i_axi_rready           (S1_RREADY),
        .o_axi_rlast            (RAM_axi_rlast),

        .i_axi_awaddr           (S1_AWADDR),
        .i_axi_awvalid          (S1_AWVALID),
        .o_axi_awready          (RAM_axi_awready),
        .i_axi_awlen            (S1_AWLEN),
        .i_axi_awsize           (S1_AWSIZE),
        .i_axi_awburst          (S1_AWBURST),

        .i_axi_wdata            (S1_WDATA),
        .i_axi_wvalid           (S1_WVALID),
        .o_axi_wready           (RAM_axi_wready),
        .i_axi_wlast            (S1_WLAST),
        .i_axi_wstrb            (S1_WSTRB),

        .o_axi_bresp            (RAM_axi_bresp),
        .o_axi_bvalid           (RAM_axi_bvalid),
        .i_axi_bready           (S1_BREADY)
    );

    wire[`Num_IntSrc-1:0]       PLIC_int_src = {UART_tx_done, UART_rx_valid, GPIO_interrupt};
    PLIC PLIC_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S2_ARADDR),
        .i_axi_arvalid          (S2_ARVALID),
        .o_axi_arready          (PLIC_axi_arready),
        .i_axi_arlen            (S2_ARLEN),
        .i_axi_arsize           (S2_ARSIZE),
        .i_axi_arburst          (S2_ARBURST),
        .o_axi_rdata            (PLIC_axi_rdata),
        .o_axi_rvalid           (PLIC_axi_rvalid),
        .i_axi_rready           (S2_RREADY),
        .o_axi_rlast            (PLIC_axi_rlast),
        .i_axi_awaddr           (S2_AWADDR),
        .i_axi_awvalid          (S2_AWVALID),
        .o_axi_awready          (PLIC_axi_awready),
        .i_axi_awlen            (S2_AWLEN),
        .i_axi_awsize           (S2_AWSIZE),
        .i_axi_awburst          (S2_AWBURST),
        .i_axi_wdata            (S2_WDATA),
        .i_axi_wvalid           (S2_WVALID),
        .o_axi_wready           (PLIC_axi_wready),
        .i_axi_wlast            (S2_WLAST),
        .i_axi_wstrb            (S2_WSTRB),
        .o_axi_bresp            (PLIC_axi_bresp),
        .o_axi_bvalid           (PLIC_axi_bvalid),
        .i_axi_bready           (S2_BREADY),

        .i_src                  (PLIC_int_src),

        .o_external_int_pending (PLIC_external_int_pending)
    );

    UART UART_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S3_ARADDR),
        .i_axi_arvalid          (S3_ARVALID),
        .o_axi_arready          (UART_axi_arready),
        .i_axi_arlen            (S3_ARLEN),
        .i_axi_arsize           (S3_ARSIZE),
        .i_axi_arburst          (S3_ARBURST),
        .o_axi_rdata            (UART_axi_rdata),
        .o_axi_rvalid           (UART_axi_rvalid),
        .i_axi_rready           (S3_RREADY),
        .o_axi_rlast            (UART_axi_rlast),
        .i_axi_awaddr           (S3_AWADDR),
        .i_axi_awvalid          (S3_AWVALID),
        .o_axi_awready          (UART_axi_awready),
        .i_axi_awlen            (S3_AWLEN),
        .i_axi_awsize           (S3_AWSIZE),
        .i_axi_awburst          (S3_AWBURST),
        .i_axi_wdata            (S3_WDATA),
        .i_axi_wvalid           (S3_WVALID),
        .o_axi_wready           (UART_axi_wready),
        .i_axi_wlast            (S3_WLAST),
        .i_axi_wstrb            (S3_WSTRB),
        .o_axi_bresp            (UART_axi_bresp),
        .o_axi_bvalid           (UART_axi_bvalid),
        .i_axi_bready           (S3_BREADY),

        .o_tx_serial            (o_tx_serial),
        .o_tx_done              (UART_tx_done),
        .o_tx_busy              (UART_tx_busy),

        .i_rx_serial            (i_rx_serial),
        .o_rx_valid             (UART_rx_valid)
    );

    GPIO #(.N(GPIO_N)) GPIO_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S4_ARADDR),
        .i_axi_arvalid          (S4_ARVALID),
        .o_axi_arready          (GPIO_axi_arready),
        .i_axi_arlen            (S4_ARLEN),
        .i_axi_arsize           (S4_ARSIZE),
        .i_axi_arburst          (S4_ARBURST),
        .o_axi_rdata            (GPIO_axi_rdata),
        .o_axi_rvalid           (GPIO_axi_rvalid),
        .i_axi_rready           (S4_RREADY),
        .o_axi_rlast            (GPIO_axi_rlast),
        .i_axi_awaddr           (S4_AWADDR),
        .i_axi_awvalid          (S4_AWVALID),
        .o_axi_awready          (GPIO_axi_awready),
        .i_axi_awlen            (S4_AWLEN),
        .i_axi_awsize           (S4_AWSIZE),
        .i_axi_awburst          (S4_AWBURST),
        .i_axi_wdata            (S4_WDATA),
        .i_axi_wvalid           (S4_WVALID),
        .o_axi_wready           (GPIO_axi_wready),
        .i_axi_wlast            (S4_WLAST),
        .i_axi_wstrb            (S4_WSTRB),
        .o_axi_bresp            (GPIO_axi_bresp),
        .o_axi_bvalid           (GPIO_axi_bvalid),
        .i_axi_bready           (S4_BREADY),

        .o_gpio_out             (GPIO_out),
        .o_gpio_out_en          (GPIO_out_en),
        .i_gpio_in              (GPIO_in),

        .o_gpio_interrupt       (GPIO_interrupt)
    );

    CLINT CLINT_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_axi_araddr           (S6_ARADDR),
        .i_axi_arvalid          (S6_ARVALID),
        .o_axi_arready          (CLINT_axi_arready),
        .i_axi_arlen            (S6_ARLEN),
        .i_axi_arsize           (S6_ARSIZE),
        .i_axi_arburst          (S6_ARBURST),
        .o_axi_rdata            (CLINT_axi_rdata),
        .o_axi_rvalid           (CLINT_axi_rvalid),
        .i_axi_rready           (S6_RREADY),
        .o_axi_rlast            (CLINT_axi_rlast),
        .i_axi_awaddr           (S6_AWADDR),
        .i_axi_awvalid          (S6_AWVALID),
        .o_axi_awready          (CLINT_axi_awready),
        .i_axi_awlen            (S6_AWLEN),
        .i_axi_awsize           (S6_AWSIZE),
        .i_axi_awburst          (S6_AWBURST),
        .i_axi_wdata            (S6_WDATA),
        .i_axi_wvalid           (S6_WVALID),
        .o_axi_wready           (CLINT_axi_wready),
        .i_axi_wlast            (S6_WLAST),
        .i_axi_wstrb            (S6_WSTRB),
        .o_axi_bresp            (CLINT_axi_bresp),
        .o_axi_bvalid           (CLINT_axi_bvalid),
        .i_axi_bready           (S6_BREADY),

        .o_timer_int_pending    (CLINT_timer_int_pending)
    );

endmodule
