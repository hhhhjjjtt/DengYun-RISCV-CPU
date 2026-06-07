`include "defines.v"

// ---- i-cache ----
// cache size:      2kB
// Ways:            4
// Sets:            32
// Address:         32-bit  (Tag[31:9] / Index[8:4] / Word[3:2] / Byte[1:0])
// Valid bits:      1 per way per set (no dirty bit)
// Replacement:     PLRU, 3 bits per set
// Write Policy:    N/A (read-only)
// ---- AXI ----
// AXI: AR+R only, INCR burst of 4

module I_Cache (
    input wire                  i_Clk,
    input wire                  i_reset,

    // I/O with IF
    input wire                  i_imem_valid,
    output reg                  o_imem_ready,
    input wire[`InstAddrBus]    i_imem_rd_addr,
    output reg[`DataBus]        o_imem_rd_data,

    // AXI master — AR channel
    output reg[31:0]            o_axi_araddr,
    output reg                  o_axi_arvalid,
    input wire                  i_axi_arready,
    output reg[7:0]             o_axi_arlen,
    output reg[2:0]             o_axi_arsize,
    output reg[1:0]             o_axi_arburst,

    // AXI master — R channel
    input wire[31:0]            i_axi_rdata,
    input wire                  i_axi_rvalid,
    output reg                  o_axi_rready,
    input wire                  i_axi_rlast
);

    // ---- cache storage ----
    reg         cache_valid [0:31][0:3];   // [set][way]
    reg [22:0]  cache_tag   [0:31][0:3];   // [set][way]
    reg [127:0] cache_data  [0:31][0:3];   // [set][way]
    reg [2:0]   cache_plru  [0:31];        // [set]
    // plru[0]: 0=evict left (W0/W1),  1=evict right (W2/W3)
    // plru[1]: 0=evict W0, 1=evict W1 (within left)
    // plru[2]: 0=evict W2, 1=evict W3 (within right)

    // ---- address decode ----
    wire [22:0] req_tag  = i_imem_rd_addr[31:9];
    wire [4:0]  req_set  = i_imem_rd_addr[8:4];
    wire [1:0]  req_word = i_imem_rd_addr[3:2];

    // ---- hit detection (combinational, all 4 ways in parallel) ----
    wire hit_w0 = cache_valid[req_set][0] && (cache_tag[req_set][0] == req_tag);
    wire hit_w1 = cache_valid[req_set][1] && (cache_tag[req_set][1] == req_tag);
    wire hit_w2 = cache_valid[req_set][2] && (cache_tag[req_set][2] == req_tag);
    wire hit_w3 = cache_valid[req_set][3] && (cache_tag[req_set][3] == req_tag);
    wire hit = hit_w0 | hit_w1 | hit_w2 | hit_w3;

    wire [1:0] hit_way = hit_w0 ? 2'd0 :
                         hit_w1 ? 2'd1 :
                         hit_w2 ? 2'd2 : 2'd3;

    // ---- hit data mux ----
    wire [127:0] hit_line = hit_w0 ? cache_data[req_set][0] :
                            hit_w1 ? cache_data[req_set][1] :
                            hit_w2 ? cache_data[req_set][2] :
                                     cache_data[req_set][3];

    wire [31:0] hit_word = hit_line[req_word * 32 +: 32];

    // ---- PLRU victim selection (combinational) ----
    wire [2:0] plru_bits  = cache_plru[req_set];
    wire [1:0] victim_way = (plru_bits[0] == 1'b0) ? (plru_bits[1] == 1'b0 ? 2'd0 : 2'd1)
                                                    : (plru_bits[2] == 1'b0 ? 2'd2 : 2'd3);

    // ---- state machine ----
    localparam S_IDLE  = 2'd0;  // tag compare; hit → serve; miss → start fetch
    localparam S_FETCH = 2'd1;  // AXI AR + R: collect 4 beats into fill_buf
    localparam S_WRITE = 2'd2;  // commit completed fill_buf into cache array

    reg [1:0]   state;
    reg [1:0]   fill_cnt;       // R beat counter (0-3)
    reg [127:0] fill_buf;       // accumulates fetched words
    reg [4:0]   fill_set;       // set of the line being filled
    reg [22:0]  fill_tag;       // tag  of the line being filled
    reg [1:0]   fill_way;       // way  chosen by PLRU for this fill

    integer s, w;

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= S_IDLE;
            o_axi_arvalid <= 1'b0;
            o_axi_rready  <= 1'b0;
            fill_cnt      <= 2'd0;
            for (s = 0; s < 32; s = s + 1) begin
                cache_plru[s] <= 3'd0;
                for (w = 0; w < 4; w = w + 1)
                    cache_valid[s][w] <= 1'b0;
            end
        end
        else begin
            case (state)

                // ---- hit: update PLRU; miss: launch AXI fetch ----
                S_IDLE: begin
                    if (i_imem_valid && hit) begin
                        case (hit_way)
                            2'd0: begin cache_plru[req_set][0] <= 1'b1; cache_plru[req_set][1] <= 1'b1; end
                            2'd1: begin cache_plru[req_set][0] <= 1'b1; cache_plru[req_set][1] <= 1'b0; end
                            2'd2: begin cache_plru[req_set][0] <= 1'b0; cache_plru[req_set][2] <= 1'b1; end
                            2'd3: begin cache_plru[req_set][0] <= 1'b0; cache_plru[req_set][2] <= 1'b0; end
                        endcase
                    end
                    else if (i_imem_valid && !hit) begin
                        fill_set      <= req_set;
                        fill_tag      <= req_tag;
                        fill_way      <= victim_way;
                        fill_cnt      <= 2'd0;

                        o_axi_araddr  <= {i_imem_rd_addr[31:4], 4'b0}; // line-aligned
                        o_axi_arvalid <= 1'b1;
                        o_axi_arlen   <= 8'd3;   // 4 beats
                        o_axi_arsize  <= 3'd2;   // 4 bytes / beat
                        o_axi_arburst <= 2'b01;  // INCR
                        o_axi_rready  <= 1'b1;

                        state <= S_FETCH;
                    end
                end

                // ---- hold ARVALID until accepted; collect R beats ----
                S_FETCH: begin
                    if (o_axi_arvalid && i_axi_arready) begin
                        o_axi_arvalid <= 1'b0;
                    end

                    if (i_axi_rvalid) begin
                        fill_buf[fill_cnt * 32 +: 32] <= i_axi_rdata;
                        fill_cnt <= fill_cnt + 1;

                        if (i_axi_rlast) begin
                            o_axi_rready <= 1'b0;
                            state        <= S_WRITE;
                        end
                    end
                end

                // ---- write completed line into cache, update PLRU ----
                // fill_buf is fully written by NBAs from S_FETCH, safe to commit here
                S_WRITE: begin
                    cache_data [fill_set][fill_way] <= fill_buf;
                    cache_tag  [fill_set][fill_way] <= fill_tag;
                    cache_valid[fill_set][fill_way] <= 1'b1;
                    case (fill_way)
                        2'd0: begin cache_plru[fill_set][0] <= 1'b1; cache_plru[fill_set][1] <= 1'b1; end
                        2'd1: begin cache_plru[fill_set][0] <= 1'b1; cache_plru[fill_set][1] <= 1'b0; end
                        2'd2: begin cache_plru[fill_set][0] <= 1'b0; cache_plru[fill_set][2] <= 1'b1; end
                        2'd3: begin cache_plru[fill_set][0] <= 1'b0; cache_plru[fill_set][2] <= 1'b0; end
                    endcase
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ---- combinational output to IF ----
    // o_imem_ready goes high in the same cycle the hit is detected — no added latency
    always @(*) begin
        if (state == S_IDLE && i_imem_valid && hit) begin
            o_imem_ready   = 1'b1;
            o_imem_rd_data = hit_word;
        end
        else begin
            o_imem_ready   = 1'b0;
            o_imem_rd_data = `ZeroWord;
        end
    end

endmodule
