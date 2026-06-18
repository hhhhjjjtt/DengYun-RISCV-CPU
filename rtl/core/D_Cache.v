`include "../defines.v"

// ---- d-cache ----
// cache size:      2kB
// Ways:            4
// Sets:            32
// Address:         32-bit  (Tag[31:9] / Index[8:4] / Word[3:2] / Byte[1:0])
// Valid bits:      1 per way per set
// Dirty bits:      1 per way per set
// Replacement:     PLRU, 3 bits per set
// Write Policy:    Write-back, Write-allocate
// ---- AXI ----
// AXI: AR/R/AW/W/B; INCR burst of 4

module D_Cache (
    input wire                  i_Clk,
    input wire                  i_reset,

    // CPU side — MEM (valid gated by cpu_top: dmem_valid && dcache_en)
    input wire                  i_dmem_valid,
    output reg                  o_dmem_ready,
    input wire                  i_dmem_rd_en,
    input wire[`DataAddrBus]    i_dmem_rd_addr,
    output reg[`DataBus]        o_dmem_rd_data,
    input wire                  i_dmem_wr_en,
    input wire[`StrbBus]        i_dmem_wr_strb,
    input wire[`DataAddrBus]    i_dmem_wr_addr,
    input wire[`DataBus]        i_dmem_wr_data,

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
    input wire                  i_axi_rlast,

    // AXI master — AW channel (dirty eviction)
    output reg[31:0]            o_axi_awaddr,
    output reg                  o_axi_awvalid,
    input wire                  i_axi_awready,
    output reg[7:0]             o_axi_awlen,
    output reg[2:0]             o_axi_awsize,
    output reg[1:0]             o_axi_awburst,

    // AXI master — W channel (dirty eviction)
    output reg[31:0]            o_axi_wdata,
    output reg                  o_axi_wvalid,
    input wire                  i_axi_wready,
    output reg                  o_axi_wlast,
    output reg[3:0]             o_axi_wstrb,

    // AXI master — B channel
    input wire[1:0]             i_axi_bresp,
    input wire                  i_axi_bvalid,
    output reg                  o_axi_bready
);

    // ---- cache storage ----
    reg         cache_valid [0:31][0:3];   // [set][way]
    reg         cache_dirty [0:31][0:3];   // [set][way]
    reg [22:0]  cache_tag   [0:31][0:3];   // [set][way]
    reg [127:0] cache_data  [0:31][0:3];   // [set][way]
    reg [2:0]   cache_plru  [0:31];        // [set]
    // plru[0]: 0=evict left (W0/W1),  1=evict right (W2/W3)
    // plru[1]: 0=evict W0, 1=evict W1 (within left)
    // plru[2]: 0=evict W2, 1=evict W3 (within right)

    // ---- address decode ----
    // rd_addr == wr_addr always (both driven from i_mem_addr in MEM.v)
    wire [`DataAddrBus] req_addr = i_dmem_rd_en ? i_dmem_rd_addr : i_dmem_wr_addr;
    wire [22:0] req_tag  = req_addr[31:9];
    wire [4:0]  req_set  = req_addr[8:4];
    wire [1:0]  req_word = req_addr[3:2];

    // ---- hit detection (combinational, all 4 ways in parallel) ----
    wire hit_w0 = cache_valid[req_set][0] && (cache_tag[req_set][0] == req_tag);
    wire hit_w1 = cache_valid[req_set][1] && (cache_tag[req_set][1] == req_tag);
    wire hit_w2 = cache_valid[req_set][2] && (cache_tag[req_set][2] == req_tag);
    wire hit_w3 = cache_valid[req_set][3] && (cache_tag[req_set][3] == req_tag);
    wire        hit = hit_w0 | hit_w1 | hit_w2 | hit_w3;

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

    wire victim_dirty = cache_valid[req_set][victim_way] &&
                        cache_dirty[req_set][victim_way];

    // ---- write merge (combinational) ----
    // merges write strobe+data into the hit line for write-hit updates
    reg [127:0] write_merged;
    always @(*) begin
        write_merged = hit_line;
        case (req_word)
            2'd0: begin
                if (i_dmem_wr_strb[0]) write_merged[7:0]     = i_dmem_wr_data[7:0];
                if (i_dmem_wr_strb[1]) write_merged[15:8]    = i_dmem_wr_data[15:8];
                if (i_dmem_wr_strb[2]) write_merged[23:16]   = i_dmem_wr_data[23:16];
                if (i_dmem_wr_strb[3]) write_merged[31:24]   = i_dmem_wr_data[31:24];
            end
            2'd1: begin
                if (i_dmem_wr_strb[0]) write_merged[39:32]   = i_dmem_wr_data[7:0];
                if (i_dmem_wr_strb[1]) write_merged[47:40]   = i_dmem_wr_data[15:8];
                if (i_dmem_wr_strb[2]) write_merged[55:48]   = i_dmem_wr_data[23:16];
                if (i_dmem_wr_strb[3]) write_merged[63:56]   = i_dmem_wr_data[31:24];
            end
            2'd2: begin
                if (i_dmem_wr_strb[0]) write_merged[71:64]   = i_dmem_wr_data[7:0];
                if (i_dmem_wr_strb[1]) write_merged[79:72]   = i_dmem_wr_data[15:8];
                if (i_dmem_wr_strb[2]) write_merged[87:80]   = i_dmem_wr_data[23:16];
                if (i_dmem_wr_strb[3]) write_merged[95:88]   = i_dmem_wr_data[31:24];
            end
            2'd3: begin
                if (i_dmem_wr_strb[0]) write_merged[103:96]  = i_dmem_wr_data[7:0];
                if (i_dmem_wr_strb[1]) write_merged[111:104] = i_dmem_wr_data[15:8];
                if (i_dmem_wr_strb[2]) write_merged[119:112] = i_dmem_wr_data[23:16];
                if (i_dmem_wr_strb[3]) write_merged[127:120] = i_dmem_wr_data[31:24];
            end
        endcase
    end

    // ---- state machine ----
    localparam S_IDLE      = 3'd0;  // tag compare; serve hit; start miss sequence
    localparam S_WRITEBACK = 3'd1;  // evict dirty victim via AW+W
    localparam S_BWAIT     = 3'd2;  // wait for B response after eviction
    localparam S_FETCH     = 3'd3;  // fetch new line via AR+R
    localparam S_FILL      = 3'd4;  // commit fill_buf to cache, then back to IDLE

    reg [2:0]   state;
    reg [1:0]   fill_cnt;       // R beat counter (0-3)
    reg [127:0] fill_buf;       // accumulates fetched words
    reg [4:0]   fill_set;       // set being filled
    reg [22:0]  fill_tag;       // tag being filled
    reg [1:0]   fill_way;       // way chosen by PLRU for this fill
    reg [1:0]   wb_cnt;         // writeback beat counter (0-3)
    reg [127:0] evict_data;     // dirty line being written back

    integer s, w;

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= S_IDLE;
            o_axi_arvalid <= 1'b0;
            o_axi_rready  <= 1'b0;
            o_axi_awvalid <= 1'b0;
            o_axi_wvalid  <= 1'b0;
            o_axi_wlast   <= 1'b0;
            o_axi_bready  <= 1'b0;
            fill_cnt      <= 2'd0;
            wb_cnt        <= 2'd0;
            for (s = 0; s < 32; s = s + 1) begin
                cache_plru[s] <= 3'd0;
                for (w = 0; w < 4; w = w + 1) begin
                    cache_valid[s][w] <= 1'b0;
                    cache_dirty[s][w] <= 1'b0;
                end
            end
        end
        else begin
            case (state)

                // ---- hit: update data/PLRU; miss: start evict or fetch ----
                S_IDLE: begin
                    if (i_dmem_valid && hit) begin
                        if (i_dmem_wr_en) begin
                            cache_data [req_set][hit_way] <= write_merged;
                            cache_dirty[req_set][hit_way] <= 1'b1;
                        end
                        case (hit_way)
                            2'd0: begin cache_plru[req_set][0]<=1'b1; cache_plru[req_set][1]<=1'b1; end
                            2'd1: begin cache_plru[req_set][0]<=1'b1; cache_plru[req_set][1]<=1'b0; end
                            2'd2: begin cache_plru[req_set][0]<=1'b0; cache_plru[req_set][2]<=1'b1; end
                            2'd3: begin cache_plru[req_set][0]<=1'b0; cache_plru[req_set][2]<=1'b0; end
                        endcase
                    end
                    else if (i_dmem_valid && !hit) begin
                        fill_set <= req_set;
                        fill_tag <= req_tag;
                        fill_way <= victim_way;
                        fill_cnt <= 2'd0;

                        if (victim_dirty) begin
                            // latch evicted line; set up AW+W for first word
                            evict_data    <= cache_data[req_set][victim_way];
                            wb_cnt        <= 2'd0;
                            o_axi_awaddr  <= {cache_tag[req_set][victim_way], req_set, 4'b0};
                            o_axi_awvalid <= 1'b1;
                            o_axi_awlen   <= 8'd3;
                            o_axi_awsize  <= 3'd2;
                            o_axi_awburst <= 2'b01;
                            o_axi_wdata   <= cache_data[req_set][victim_way][31:0];
                            o_axi_wvalid  <= 1'b1;
                            o_axi_wlast   <= 1'b0;
                            o_axi_wstrb   <= 4'b1111;
                            state         <= S_WRITEBACK;
                        end
                        else begin
                            o_axi_araddr  <= {req_addr[31:4], 4'b0};
                            o_axi_arvalid <= 1'b1;
                            o_axi_arlen   <= 8'd3;
                            o_axi_arsize  <= 3'd2;
                            o_axi_arburst <= 2'b01;
                            o_axi_rready  <= 1'b1;
                            state         <= S_FETCH;
                        end
                    end
                end

                // ---- send dirty victim line to memory ----
                S_WRITEBACK: begin
                    if (o_axi_awvalid && i_axi_awready)
                        o_axi_awvalid <= 1'b0;

                    if (o_axi_wvalid && i_axi_wready) begin
                        case (wb_cnt)
                            2'd0: begin o_axi_wdata <= evict_data[63:32];  wb_cnt <= 2'd1; end
                            2'd1: begin o_axi_wdata <= evict_data[95:64];  wb_cnt <= 2'd2; end
                            2'd2: begin o_axi_wdata <= evict_data[127:96]; o_axi_wlast <= 1'b1; wb_cnt <= 2'd3; end
                            2'd3: begin
                                o_axi_wvalid <= 1'b0;
                                o_axi_wlast  <= 1'b0;
                                o_axi_bready <= 1'b1;
                                state        <= S_BWAIT;
                            end
                        endcase
                    end
                end

                // ---- wait for write-back acknowledgement, then fetch ----
                S_BWAIT: begin
                    if (i_axi_bvalid) begin
                        o_axi_bready  <= 1'b0;
                        o_axi_araddr  <= {fill_tag, fill_set, 4'b0};
                        o_axi_arvalid <= 1'b1;
                        o_axi_arlen   <= 8'd3;
                        o_axi_arsize  <= 3'd2;
                        o_axi_arburst <= 2'b01;
                        o_axi_rready  <= 1'b1;
                        state         <= S_FETCH;
                    end
                end

                // ---- collect 4 R beats into fill_buf ----
                S_FETCH: begin
                    if (o_axi_arvalid && i_axi_arready)
                        o_axi_arvalid <= 1'b0;

                    if (i_axi_rvalid) begin
                        fill_buf[fill_cnt * 32 +: 32] <= i_axi_rdata;
                        fill_cnt <= fill_cnt + 1;
                        if (i_axi_rlast) begin
                            o_axi_rready <= 1'b0;
                            state        <= S_FILL;
                        end
                    end
                end

                // ---- commit fill_buf; write-allocate handled by returning to IDLE ----
                // if original was a write miss: next cycle hits as write hit → sets dirty
                // if original was a read miss:  next cycle hits as read hit  → returns data
                S_FILL: begin
                    cache_data [fill_set][fill_way] <= fill_buf;
                    cache_tag  [fill_set][fill_way] <= fill_tag;
                    cache_valid[fill_set][fill_way] <= 1'b1;
                    cache_dirty[fill_set][fill_way] <= 1'b0;
                    case (fill_way)
                        2'd0: begin cache_plru[fill_set][0]<=1'b1; cache_plru[fill_set][1]<=1'b1; end
                        2'd1: begin cache_plru[fill_set][0]<=1'b1; cache_plru[fill_set][1]<=1'b0; end
                        2'd2: begin cache_plru[fill_set][0]<=1'b0; cache_plru[fill_set][2]<=1'b1; end
                        2'd3: begin cache_plru[fill_set][0]<=1'b0; cache_plru[fill_set][2]<=1'b0; end
                    endcase
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ---- combinational output to MEM ----
    // ready goes high in the same cycle the hit is detected — no added latency
    // for write hits, o_dmem_rd_data is irrelevant (MEM won't use it)
    always @(*) begin
        if (state == S_IDLE && i_dmem_valid && hit) begin
            o_dmem_ready   = 1'b1;
            o_dmem_rd_data = hit_word;
        end
        else begin
            o_dmem_ready   = 1'b0;
            o_dmem_rd_data = `ZeroWord;
        end
    end

endmodule
