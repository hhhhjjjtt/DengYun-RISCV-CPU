`include "../defines.v"

// Register map (word-addressed via addr[4:2]):
//   0x00  TX_DATA  [7:0]   write = load & start TX (if idle); read = last byte written
//   0x04  RX_DATA  [7:0]   read = most-recent received byte; clears rx_valid
//   0x08  STATUS   [1:0]   [0] = tx_idle, [1] = rx_valid
//   0x0C  BAUD_DIV [15:0]  clk_freq / baud_rate  (default 10417 = 100 MHz / 9600)
//
// TX: CPU writes TX_DATA when STATUS[0]=1; byte is dropped if TX is busy.
// RX: no FIFO; STATUS[1] is set when a byte arrives, cleared when RX_DATA is read.
//     A second byte arriving before the first is read overwrites rx_data_reg.

module UART (
    input wire          i_Clk,
    input wire          i_reset,

    // AXI slave — AR channel
    input wire[31:0]    i_axi_araddr,
    input wire          i_axi_arvalid,
    output reg          o_axi_arready,
    input wire[7:0]     i_axi_arlen,
    input wire[2:0]     i_axi_arsize,
    input wire[1:0]     i_axi_arburst,
    // AXI slave — R channel
    output reg[31:0]    o_axi_rdata,
    output reg          o_axi_rvalid,
    input wire          i_axi_rready,
    output reg          o_axi_rlast,
    // AXI slave — AW channel
    input wire[31:0]    i_axi_awaddr,
    input wire          i_axi_awvalid,
    output reg          o_axi_awready,
    input wire[7:0]     i_axi_awlen,
    input wire[2:0]     i_axi_awsize,
    input wire[1:0]     i_axi_awburst,
    // AXI slave — W channel
    input wire[31:0]    i_axi_wdata,
    input wire          i_axi_wvalid,
    output reg          o_axi_wready,
    input wire          i_axi_wlast,
    input wire[3:0]     i_axi_wstrb,
    // AXI slave — B channel
    output reg[1:0]     o_axi_bresp,
    output reg          o_axi_bvalid,
    input wire          i_axi_bready,

    // UART tx
    output reg          o_tx_serial,
    output reg          o_tx_done,
    output reg          o_tx_busy,
    // UART rx
    input wire          i_rx_serial,
    output reg          o_rx_valid
);

    localparam OFFSET_TX_DATA  = 3'b000;
    localparam OFFSET_RX_DATA  = 3'b001;
    localparam OFFSET_STATUS   = 3'b010;
    localparam OFFSET_BAUD_DIV = 3'b011;

    // ---- Shared registers ----
    reg [15:0] baud_div;
    reg [7:0]  tx_data_reg;
    reg [7:0]  rx_data_reg;

    // ---- TX state machine ----
    localparam TX_IDLE  = 2'd0;
    localparam TX_START = 2'd1;
    localparam TX_DATA  = 2'd2;
    localparam TX_STOP  = 2'd3;

    reg [1:0]   tx_state;
    reg [15:0]  tx_cnt;
    reg [2:0]   tx_bit;
    reg [7:0]   tx_shift;
    reg         tx_pin;
    reg         tx_idle;
    reg         tx_done_r;   // one-cycle pulse on stop-bit completion
    reg         tx_start;    // one-cycle strobe from AXI write path

    always @(posedge i_Clk) begin
        if (i_reset) begin
            tx_state  <= TX_IDLE;
            tx_cnt    <= 16'd0;
            tx_bit    <= 3'd0;
            tx_shift  <= 8'd0;
            tx_pin    <= 1'b1;
            tx_idle   <= 1'b1;
            tx_done_r <= 1'b0;
        end else begin
            tx_done_r <= 1'b0;
            case (tx_state)
                TX_IDLE: begin
                    tx_pin  <= 1'b1;
                    tx_idle <= 1'b1;
                    if (tx_start) begin
                        tx_shift <= tx_data_reg;
                        tx_pin   <= 1'b0;           // start bit
                        tx_cnt   <= baud_div - 1;
                        tx_idle  <= 1'b0;
                        tx_state <= TX_START;
                    end
                end
                TX_START: begin
                    if (tx_cnt == 16'd0) begin
                        tx_pin   <= tx_shift[0];    // bit 0
                        tx_bit   <= 3'd0;
                        tx_cnt   <= baud_div - 1;
                        tx_state <= TX_DATA;
                    end 
                    else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
                TX_DATA: begin
                    if (tx_cnt == 16'd0) begin
                        tx_cnt <= baud_div - 1;
                        if (tx_bit == 3'd7) begin
                            tx_pin   <= 1'b1;       // stop bit
                            tx_state <= TX_STOP;
                        end else begin
                            tx_bit <= tx_bit + 1;
                            tx_pin <= tx_shift[tx_bit + 1];
                        end
                    end 
                    else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
                TX_STOP: begin
                    if (tx_cnt == 16'd0) begin
                        tx_done_r <= 1'b1;
                        tx_state  <= TX_IDLE;
                        tx_idle   <= 1'b1;
                    end 
                    else begin
                        tx_cnt <= tx_cnt - 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        o_tx_serial     = tx_pin;
        o_tx_busy       = ~tx_idle;
        o_tx_done       = tx_done_r;
    end

    // ---- RX state machine ----
    // 2-FF metastability synchronizer
    reg rx_s0, rx_s1, rx_prev;
    wire rx_fall = rx_prev & ~rx_s1;

    always @(posedge i_Clk) begin
        rx_s0   <= i_rx_serial;
        rx_s1   <= rx_s0;
        rx_prev <= rx_s1;
    end

    localparam RX_IDLE  = 2'd0;
    localparam RX_START = 2'd1;
    localparam RX_DATA  = 2'd2;
    localparam RX_STOP  = 2'd3;

    reg [1:0]  rx_state;
    reg [15:0] rx_cnt;
    reg [2:0]  rx_bit;
    reg [7:0]  rx_shift;
    reg        rx_valid;
    reg        rx_clear;    // one-cycle strobe from AXI read path

    always @(posedge i_Clk) begin
        if (i_reset) begin
            rx_state    <= RX_IDLE;
            rx_cnt      <= 16'd0;
            rx_bit      <= 3'd0;
            rx_shift    <= 8'd0;
            rx_data_reg <= 8'd0;
            rx_valid    <= 1'b0;
        end else begin
            if (rx_clear) begin
                rx_valid <= 1'b0;
            end 

            case (rx_state)
                RX_IDLE: begin
                    if (rx_fall) begin
                        rx_cnt   <= (baud_div >> 1) - 1;
                        rx_state <= RX_START;
                    end
                end
                RX_START: begin
                    if (rx_cnt == 16'd0) begin
                        if (~rx_s1) begin           // confirmed start bit
                            rx_cnt   <= baud_div - 1;
                            rx_bit   <= 3'd0;
                            rx_state <= RX_DATA;
                        end 
                        else begin
                            rx_state <= RX_IDLE;    // glitch — abort
                        end
                    end 
                    else begin
                        rx_cnt <= rx_cnt - 1;
                    end
                end
                RX_DATA: begin
                    if (rx_cnt == 16'd0) begin
                        rx_shift[rx_bit] <= rx_s1;
                        rx_cnt <= baud_div - 1;
                        if (rx_bit == 3'd7) begin
                            rx_state <= RX_STOP;
                        end
                        else begin
                            rx_bit <= rx_bit + 1;
                        end
                    end 
                    else begin
                        rx_cnt <= rx_cnt - 1;
                    end
                end
                RX_STOP: begin
                    if (rx_cnt == 16'd0) begin
                        if (rx_s1) begin
                            rx_data_reg <= rx_shift;
                            rx_valid    <= 1'b1;    // wins over simultaneous rx_clear
                        end
                        rx_state <= RX_IDLE;
                    end 
                    else begin
                        rx_cnt <= rx_cnt - 1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        o_rx_valid = rx_valid;
    end

    // ---- AXI write path ----
    reg         aw_pending;
    reg[31:0]   aw_addr_latch;
    reg         w_pending;
    reg[31:0]   w_data_latch;
    reg[3:0]    w_strb_latch;

    always @(posedge i_Clk) begin
        if (i_reset) begin
            o_axi_awready <= 1'b0;
            o_axi_wready  <= 1'b0;
            o_axi_bvalid  <= 1'b0;
            o_axi_bresp   <= 2'b00;
            aw_pending    <= 1'b0;
            w_pending     <= 1'b0;
            tx_start      <= 1'b0;
            baud_div      <= 16'd10417;
            tx_data_reg   <= 8'd0;
        end 
        else begin
            tx_start      <= 1'b0;
            o_axi_awready <= 1'b0;
            o_axi_wready  <= 1'b0;

            // Accept AW (hold until we consume it)
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
                    OFFSET_TX_DATA: begin
                        if (w_strb_latch[0]) tx_data_reg <= w_data_latch[7:0];
                        if (tx_idle) tx_start <= 1'b1;
                    end
                    OFFSET_BAUD_DIV: begin
                        if (w_strb_latch[0]) baud_div[7:0]  <= w_data_latch[7:0];
                        if (w_strb_latch[1]) baud_div[15:8] <= w_data_latch[15:8];
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
    always @(posedge i_Clk) begin
        if (i_reset) begin
            o_axi_arready <= 1'b0;
            o_axi_rvalid  <= 1'b0;
            o_axi_rlast   <= 1'b0;
            o_axi_rdata   <= 32'd0;
            rx_clear      <= 1'b0;
        end 
        else begin
            o_axi_arready <= 1'b0;
            rx_clear      <= 1'b0;

            if (i_axi_arvalid && !o_axi_rvalid) begin
                o_axi_arready <= 1'b1;
                o_axi_rvalid  <= 1'b1;
                o_axi_rlast   <= 1'b1;
                case (i_axi_araddr[4:2])
                    OFFSET_TX_DATA: begin
                        o_axi_rdata <= {24'd0, tx_data_reg};
                    end
                    OFFSET_RX_DATA: begin
                        o_axi_rdata <= {24'd0, rx_data_reg};
                        rx_clear    <= 1'b1;
                    end
                    OFFSET_STATUS: begin
                        o_axi_rdata <= {30'd0, rx_valid, tx_idle};
                    end 
                    OFFSET_BAUD_DIV: begin
                        o_axi_rdata <= {16'd0, baud_div};
                    end
                    default: begin
                        o_axi_rdata <= 32'd0;
                    end
                endcase
            end

            if (o_axi_rvalid && i_axi_rready) begin
                o_axi_rvalid <= 1'b0;
                o_axi_rlast  <= 1'b0;
            end
        end
    end

endmodule
