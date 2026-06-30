`include "../defines.v"

module program_loader (
    input wire          i_Clk,
    input wire          i_reset,

    // Debug pins
    input wire          i_debug_en_n,
    input wire          i_rx_serial,
    output reg          o_tx_serial,

    // System reset: held high while debug_en is asserted, ORed with pin_reset at soc_top
    output reg          o_sys_reset,

    // AXI master — AR/R channels (write-only master, tied off)
    output reg [31:0]   o_axi_araddr,
    output reg          o_axi_arvalid,
    input  wire         i_axi_arready,
    output reg [7:0]    o_axi_arlen,
    output reg [2:0]    o_axi_arsize,
    output reg [1:0]    o_axi_arburst,
    input  wire [31:0]  i_axi_rdata,
    input  wire         i_axi_rvalid,
    output reg          o_axi_rready,
    input  wire         i_axi_rlast,
    // AXI master — AW channel
    output reg [31:0]   o_axi_awaddr,
    output reg          o_axi_awvalid,
    input  wire         i_axi_awready,
    output reg [7:0]    o_axi_awlen,
    output reg [2:0]    o_axi_awsize,
    output reg [1:0]    o_axi_awburst,
    // AXI master — W channel
    output reg [31:0]   o_axi_wdata,
    output reg          o_axi_wvalid,
    input  wire         i_axi_wready,
    output reg          o_axi_wlast,
    output reg [3:0]    o_axi_wstrb,
    // AXI master — B channel
    input  wire [1:0]   i_axi_bresp,
    input  wire         i_axi_bvalid,
    output reg          o_axi_bready
);

    always @(*) begin
        o_sys_reset = ~i_debug_en_n;
    end

    // Baud rate divisor for 115200 baud at 50 MHz clock
    localparam BAUD_DIV = 16'd434;

    // UART ACK/NAK response bytes
    localparam UART_RESP_ACK = 8'h06;
    localparam UART_RESP_NAK = 8'h15;

    // =========================================================================
    // TX state machine
    // =========================================================================
    localparam ST_TX_IDLE  = 2'b00;
    localparam ST_TX_START = 2'b01;
    localparam ST_TX_DATA  = 2'b10;
    localparam ST_TX_DONE  = 2'b11;

    reg       tx_start;      // one-cycle pulse: begin transmit
    reg[7:0]  tx_data_reg;   // byte to transmit (driven by main FSM only)
    reg[1:0]  tx_state;
    reg[15:0] tx_clk_cnt;
    reg[2:0]  tx_bit_idx;
    reg       tx_pin;
    reg       tx_done;       // one-cycle pulse on stop-bit completion
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset || i_debug_en_n) begin
            tx_state   <= ST_TX_IDLE;
            tx_clk_cnt <= 16'd0;
            tx_bit_idx <= 3'd0;
            tx_pin     <= 1'b1;
            tx_done    <= `Disable;
        end else begin
            tx_done <= `Disable;
            case (tx_state)
                ST_TX_IDLE: begin
                    tx_pin <= 1'b1;
                    if (tx_start) begin
                        tx_pin     <= 1'b0;          // start bit
                        tx_clk_cnt <= BAUD_DIV - 1;
                        tx_state   <= ST_TX_START;
                    end
                end
                ST_TX_START: begin
                    if (tx_clk_cnt == 16'd0) begin
                        tx_pin     <= tx_data_reg[0]; // bit 0
                        tx_bit_idx <= 3'd0;
                        tx_clk_cnt <= BAUD_DIV - 1;
                        tx_state   <= ST_TX_DATA;
                    end else begin
                        tx_clk_cnt <= tx_clk_cnt - 1;
                    end
                end
                ST_TX_DATA: begin
                    if (tx_clk_cnt == 16'd0) begin
                        tx_clk_cnt <= BAUD_DIV - 1;
                        if (tx_bit_idx == 3'd7) begin
                            tx_pin   <= 1'b1;        // stop bit
                            tx_state <= ST_TX_DONE;
                        end else begin
                            tx_bit_idx <= tx_bit_idx + 1;
                            tx_pin     <= tx_data_reg[tx_bit_idx + 1];
                        end
                    end else begin
                        tx_clk_cnt <= tx_clk_cnt - 1;
                    end
                end
                ST_TX_DONE: begin
                    if (tx_clk_cnt == 16'd0) begin
                        tx_done  <= `Enable;
                        tx_state <= ST_TX_IDLE;
                    end else begin
                        tx_clk_cnt <= tx_clk_cnt - 1;
                    end
                end
                default: tx_state <= ST_TX_IDLE;
            endcase
        end
    end
    // drive tx output
    always @(*) begin
        o_tx_serial = tx_pin;
    end

    // =========================================================================
    // RX state machine
    // =========================================================================
    localparam ST_RX_IDLE  = 2'b00;
    localparam ST_RX_START = 2'b01;
    localparam ST_RX_DATA  = 2'b10;
    localparam ST_RX_DONE  = 2'b11;

    reg rx_s0, rx_s1, rx_prev;
    wire rx_fall = rx_prev & ~rx_s1;

    always @(posedge i_Clk) begin
        rx_s0   <= i_rx_serial;
        rx_s1   <= rx_s0;
        rx_prev <= rx_s1;
    end

    reg[1:0]  rx_state;
    reg[15:0] rx_clk_cnt;
    reg[2:0]  rx_bit_idx;
    reg[7:0]  rx_data_reg;
    reg       rx_valid;      // one-cycle pulse when a byte is ready in rx_data_reg
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset || i_debug_en_n) begin
            rx_state    <= ST_RX_IDLE;
            rx_clk_cnt  <= 16'd0;
            rx_bit_idx  <= 3'd0;
            rx_data_reg <= 8'd0;
            rx_valid    <= `Disable;
        end else begin
            case (rx_state)
                ST_RX_IDLE: begin
                    rx_clk_cnt  <= 16'd0;
                    rx_bit_idx  <= 3'd0;
                    rx_data_reg <= 8'd0;
                    rx_valid    <= `Disable;
                    if (rx_fall) begin
                        rx_state   <= ST_RX_START;
                        rx_clk_cnt <= (BAUD_DIV >> 1) - 1; // sample at mid-bit
                    end
                end
                ST_RX_START: begin
                    if (rx_clk_cnt == 16'd0) begin
                        if (~rx_s1) begin             // confirmed start bit
                            rx_clk_cnt <= BAUD_DIV - 1;
                            rx_bit_idx <= 3'd0;
                            rx_state   <= ST_RX_DATA;
                        end else begin
                            rx_state   <= ST_RX_IDLE; // glitch — abort
                        end
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt - 1;
                    end
                end
                ST_RX_DATA: begin
                    if (rx_clk_cnt == 16'd0) begin
                        rx_clk_cnt              <= BAUD_DIV - 1;
                        rx_data_reg[rx_bit_idx] <= rx_s1;
                        if (rx_bit_idx == 3'd7) begin
                            rx_state <= ST_RX_DONE;   // Bug fix #2: was ST_RX_WAIT (undefined)
                        end else begin
                            rx_bit_idx <= rx_bit_idx + 1;
                        end
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt - 1;
                    end
                end
                ST_RX_DONE: begin
                    if (rx_clk_cnt == 16'd0) begin
                        if (rx_s1) begin              // valid stop bit
                            rx_valid <= `Enable;
                        end
                        rx_state <= ST_RX_IDLE;
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt - 1;
                    end
                end
                default: rx_state <= ST_RX_IDLE;
            endcase
        end
    end

    // =========================================================================
    // CRC calculateion
    // =========================================================================
    localparam ST_CRC_IDLE = 2'b00;
    localparam ST_CRC_CALC = 2'b01;
    localparam ST_CRC_DONE = 2'b10;

    reg       crc_start;
    reg[1:0]  crc_state;     // Bug fix #3: was reg (1-bit), can't reach ST_CRC_DONE=2'b10
    reg[15:0] crc_result;
    reg[3:0]  crc_bit_idx;   // 0 = XOR byte; 1-8 = shift iterations; 9 = next byte
    reg[7:0]  crc_byte_idx;
    reg       crc_done;
    reg       crc_valid;
    reg[7:0]  packet_buffer [0:129];
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset || i_debug_en_n) begin
            crc_state    <= ST_CRC_IDLE;
            crc_result   <= 16'hffff;
            crc_bit_idx  <= 4'h0;
            crc_byte_idx <= 8'h0;
            crc_done     <= `Disable;
            crc_valid    <= `Disable;
        end else begin
            case (crc_state)
                ST_CRC_IDLE: begin
                    crc_done  <= `Disable;
                    crc_valid <= `Disable;
                    if (crc_start) begin
                        crc_result   <= 16'hffff;
                        crc_bit_idx  <= 4'h0;
                        crc_byte_idx <= 8'h0;
                        crc_state    <= ST_CRC_CALC;
                    end
                end
                ST_CRC_CALC: begin
                    if (crc_byte_idx > 8'd127 && crc_bit_idx == 4'h0) begin
                        crc_state <= ST_CRC_DONE;
                    end else begin
                        if (crc_bit_idx == 4'h0) begin
                            crc_bit_idx <= crc_bit_idx + 1'b1;
                            crc_result   <= crc_result ^ {8'h0, packet_buffer[crc_byte_idx]};
                            crc_byte_idx <= crc_byte_idx + 1;
                        end else if (crc_bit_idx <= 4'h8) begin
                            crc_bit_idx <= crc_bit_idx + 1'b1;
                            if (crc_result[0]) begin
                                crc_result <= {1'b0, crc_result[15:1]} ^ 16'ha001;
                            end else begin
                                crc_result <= {1'b0, crc_result[15:1]};
                            end
                        end else begin
                            crc_bit_idx <= 4'h0;
                        end
                    end
                end
                ST_CRC_DONE: begin
                    crc_done  <= `Enable;
                    crc_valid <= (crc_result == {packet_buffer[129], packet_buffer[128]});
                    crc_state <= ST_CRC_IDLE;
                end
                default: crc_state <= ST_CRC_IDLE;
            endcase
        end
    end

    // =========================================================================
    // Main FSM
    // =========================================================================
    localparam ST_IDLE        = 3'b000;
    localparam ST_WAIT_PACKET = 3'b001;
    localparam ST_CHECK_CRC   = 3'b010;
    localparam ST_AW          = 3'b011;
    localparam ST_W           = 3'b100;
    localparam ST_B           = 3'b101;
    localparam ST_WAIT_TX     = 3'b110;
    localparam ST_DONE        = 3'b111;

    reg[2:0]  state;
    reg[31:0] write_ptr;         // byte address of next AXI write destination
    reg[7:0]  packet_byte_idx;   // 0-129
    reg[31:0] firmware_size;     // total firmware size in bytes (from metadata packet)
    reg       metadata_done;     // set after metadata packet is processed; Bug fix #12
    reg[4:0]  burst_beat_idx;    // 0-31: current beat within a AXI burst
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset || i_debug_en_n) begin
            state           <= ST_IDLE;
            write_ptr       <= 32'h0;
            packet_byte_idx <= 8'h0;
            firmware_size   <= 32'h0;
            metadata_done   <= 1'b0;
            // tx
            tx_start        <= `Disable;
            tx_data_reg     <= UART_RESP_NAK;
            // crc
            crc_start       <= `Disable;
            // axi write
            burst_beat_idx  <= 5'd0;
            o_axi_awvalid   <= `Disable;
            o_axi_awaddr    <= 32'h0;
            o_axi_awlen     <= 8'd0;
            o_axi_awsize    <= 3'd0;
            o_axi_awburst   <= 2'b00;
            o_axi_wvalid    <= `Disable;
            o_axi_wlast     <= `Disable;
            o_axi_wstrb     <= 4'b1111;
            o_axi_wdata     <= 32'h0;
            o_axi_bready    <= `Disable;
            // axi read
            o_axi_arvalid   <= `Disable;
            o_axi_araddr    <= 32'h0;
            o_axi_arlen     <= 8'h0;
            o_axi_arsize    <= 3'h0;
            o_axi_arburst   <= 2'b00;
            o_axi_rready    <= `Disable;
        end else begin
            // Bug fix #8/#6: default-clear one-cycle pulses each clock
            tx_start  <= `Disable;
            crc_start <= `Disable;

            case (state)
                ST_IDLE: begin
                    write_ptr       <= 32'h0;
                    packet_byte_idx <= 8'd0;
                    firmware_size   <= 32'h0;
                    metadata_done   <= 1'b0;
                    if (!i_debug_en_n) begin
                        state <= ST_WAIT_PACKET;
                    end
                end
                ST_WAIT_PACKET: begin
                    if (rx_valid) begin
                        packet_buffer[packet_byte_idx] <= rx_data_reg;
                        if (packet_byte_idx == 8'd129) begin
                            state           <= ST_CHECK_CRC;
                            packet_byte_idx <= 8'd0;
                            crc_start       <= `Enable; // Bug fix #6: trigger CRC on full packet
                        end else begin
                            packet_byte_idx <= packet_byte_idx + 1'b1;
                        end
                    end
                end
                ST_CHECK_CRC: begin
                    if (crc_done) begin
                        tx_start <= `Enable;
                        if (crc_valid) begin
                            if (!metadata_done) begin   // for first packet (metadata), go strait to ST_WAIT_TX
                                firmware_size <= {packet_buffer[3], packet_buffer[2],
                                                  packet_buffer[1], packet_buffer[0]};
                                metadata_done <= 1'b1;
                                tx_data_reg   <= UART_RESP_ACK;
                                state         <= ST_WAIT_TX;
                            end else begin              // otherwise prepare the AW chennel and go to ST_AW
                                tx_data_reg   <= UART_RESP_ACK;
                                o_axi_awaddr  <= write_ptr;
                                o_axi_awlen   <= 8'd31;   // 32 beats (0-indexed)
                                o_axi_awsize  <= 3'd2;    // 4 bytes per beat
                                o_axi_awburst <= 2'b01;   // INCR
                                o_axi_awvalid <= `Enable;
                                state         <= ST_AW;
                            end
                        end else begin      // crc check fail, send NAK to host, don't write anything to memory
                            tx_data_reg <= UART_RESP_NAK;
                            state       <= ST_WAIT_TX;
                        end
                    end
                end
                ST_AW: begin
                    if (o_axi_awvalid && i_axi_awready) begin
                        o_axi_awvalid  <= `Disable;
                        burst_beat_idx <= 5'd0;
                        // Pre-load beat 0 data and assert wvalid
                        o_axi_wdata    <= {packet_buffer[3], packet_buffer[2],
                                           packet_buffer[1], packet_buffer[0]};
                        o_axi_wstrb    <= 4'b1111;
                        o_axi_wlast    <= 1'b0;
                        o_axi_wvalid   <= `Enable;
                        state          <= ST_W;
                    end
                end
                ST_W: begin
                    if (o_axi_wvalid && i_axi_wready) begin
                        if (burst_beat_idx == 5'd31) begin
                            // Last beat accepted
                            o_axi_wvalid <= `Disable;
                            o_axi_wlast  <= `Disable;
                            o_axi_bready <= `Enable;
                            state        <= ST_B;
                        end else begin
                            burst_beat_idx <= burst_beat_idx + 1'b1;
                            // Assert wlast one beat early so it's valid with the last data beat
                            o_axi_wlast    <= (burst_beat_idx == 5'd30);
                            o_axi_wdata    <= {
                                packet_buffer[((burst_beat_idx + 1) << 2) + 3],
                                packet_buffer[((burst_beat_idx + 1) << 2) + 2],
                                packet_buffer[((burst_beat_idx + 1) << 2) + 1],
                                packet_buffer[((burst_beat_idx + 1) << 2)]
                            };
                        end
                    end
                end
                ST_B: begin
                    if (i_axi_bvalid && o_axi_bready) begin
                        o_axi_bready <= `Disable;
                        write_ptr    <= write_ptr + 32'd128; // Bug fix #14: 32 words * 4 bytes
                        state        <= ST_WAIT_TX;
                    end
                end
                ST_WAIT_TX: begin
                    if (tx_done) begin
                        state <= ST_DONE;
                    end
                end
                ST_DONE: begin
                    if (!metadata_done || write_ptr < firmware_size) begin
                        packet_byte_idx <= 8'd0;
                        state           <= ST_WAIT_PACKET;
                    end
                    // metadata_done && write_ptr >= firmware_size: loading complete
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
