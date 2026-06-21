`include "../defines.v"

// ---- RAM AXI Slave ----
// Full AXI (AR+R+AW+W+B). Serialized: one read or write at a time.
// Burst support: ARLEN+1 read beats, AWLEN+1 write beats.
// Byte-enable writes via WSTRB. Address offset: word = (addr - RAM_BASE) >> 2.

module RAM #(
    parameter MEM_FILE = "ram.mem"
) (
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
    input wire          i_axi_bready
);

    (* ram_style = "block" *) reg [`DataBus] rams [0:`DataAddrDepth-1];

    integer i;
    initial begin
        for (i = 0; i < `DataAddrDepth; i = i + 1) begin
            rams[i] = `ZeroWord;
        end
        $readmemh(MEM_FILE, rams);
    end

    localparam S_IDLE  = 2'd0;
    localparam S_READ  = 2'd1;
    localparam S_WRITE = 2'd2;
    localparam S_BWAIT = 2'd3;

    reg [1:0]  state;
    reg [11:0] word_idx;    // current beat's word index into rams[]
    reg [7:0]  beats_left;  // beats remaining after current (read path only)

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= S_IDLE;
            o_axi_arready <= 1'b1;
            o_axi_awready <= 1'b1;
            o_axi_rvalid  <= 1'b0;
            o_axi_rlast   <= 1'b0;
            o_axi_rdata   <= 32'b0;
            o_axi_wready  <= 1'b0;
            o_axi_bvalid  <= 1'b0;
            o_axi_bresp   <= 2'b00;
        end else begin
            case (state)

                // Accept AR (reads) or AW (writes); reads take priority.
                S_IDLE: begin
                    o_axi_arready <= 1'b1;
                    o_axi_awready <= 1'b1;
                    o_axi_wready  <= 1'b0;

                    if (i_axi_arvalid && o_axi_arready) begin
                        word_idx      <= (i_axi_araddr - `RAM_BASE) >> 2;
                        beats_left    <= i_axi_arlen;
                        o_axi_rdata   <= rams[(i_axi_araddr - `RAM_BASE) >> 2];
                        o_axi_rvalid  <= 1'b1;
                        o_axi_rlast   <= (i_axi_arlen == 8'd0);
                        o_axi_arready <= 1'b0;
                        o_axi_awready <= 1'b0;
                        state         <= S_READ;
                    end else if (i_axi_awvalid && o_axi_awready) begin
                        word_idx      <= (i_axi_awaddr - `RAM_BASE) >> 2;
                        o_axi_awready <= 1'b0;
                        o_axi_arready <= 1'b0;
                        o_axi_wready  <= 1'b1;
                        state         <= S_WRITE;
                    end
                end

                S_READ: begin
                    if (i_axi_rready && o_axi_rvalid) begin
                        if (o_axi_rlast) begin
                            o_axi_rvalid  <= 1'b0;
                            o_axi_rlast   <= 1'b0;
                            o_axi_arready <= 1'b1;
                            o_axi_awready <= 1'b1;
                            state         <= S_IDLE;
                        end else begin
                            word_idx    <= word_idx + 12'd1;
                            beats_left  <= beats_left - 8'd1;
                            o_axi_rdata <= rams[word_idx + 12'd1];
                            o_axi_rlast <= (beats_left - 8'd1 == 8'd0);
                        end
                    end
                end

                S_WRITE: begin
                    if (i_axi_wvalid && o_axi_wready) begin
                        if (i_axi_wstrb[0]) rams[word_idx][7:0]   <= i_axi_wdata[7:0];
                        if (i_axi_wstrb[1]) rams[word_idx][15:8]  <= i_axi_wdata[15:8];
                        if (i_axi_wstrb[2]) rams[word_idx][23:16] <= i_axi_wdata[23:16];
                        if (i_axi_wstrb[3]) rams[word_idx][31:24] <= i_axi_wdata[31:24];

                        if (i_axi_wlast) begin
                            o_axi_wready <= 1'b0;
                            o_axi_bvalid <= 1'b1;
                            o_axi_bresp  <= 2'b00;
                            state        <= S_BWAIT;
                        end else begin
                            word_idx <= word_idx + 12'd1;
                        end
                    end
                end

                S_BWAIT: begin
                    if (i_axi_bready && o_axi_bvalid) begin
                        o_axi_bvalid  <= 1'b0;
                        o_axi_arready <= 1'b1;
                        o_axi_awready <= 1'b1;
                        state         <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
