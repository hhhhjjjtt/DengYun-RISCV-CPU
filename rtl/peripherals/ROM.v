`include "../defines.v"

// ---- ROM AXI Slave ----
// Read-only, AR+R channels only.
// Burst support: returns ARLEN+1 beats starting at ARADDR (INCR).
// Load program with MEM_FILE parameter (hex, one 32-bit word per line).

module ROM #(
    parameter MEM_FILE = "rom.mem"
) (
    input  wire         i_Clk,
    input  wire         i_reset,

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
    output reg          o_axi_rlast
);

    (* ram_style = "block" *) reg [`DataBus] roms [0:`InstAddrDepth-1];

    integer i;
    initial begin
        for (i = 0; i < `InstAddrDepth; i = i + 1) begin
            roms[i] = `NOP;
        end
        $readmemh(MEM_FILE, roms);
    end

    localparam S_IDLE  = 1'b0;
    localparam S_BURST = 1'b1;

    reg        state;
    reg [11:0] word_idx;    // index of beat currently on the R channel
    reg [7:0]  beats_left;  // beats remaining after the current one

    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state         <= S_IDLE;
            o_axi_arready <= 1'b1;
            o_axi_rvalid  <= 1'b0;
            o_axi_rlast   <= 1'b0;
            o_axi_rdata   <= 32'b0;
        end else begin
            case (state)

                S_IDLE: begin
                    o_axi_arready <= 1'b1;
                    if (i_axi_arvalid && o_axi_arready) begin
                        word_idx      <= i_axi_araddr[13:2];
                        beats_left    <= i_axi_arlen;
                        o_axi_rdata   <= roms[i_axi_araddr[13:2]];
                        o_axi_rvalid  <= 1'b1;
                        o_axi_rlast   <= (i_axi_arlen == 8'd0);
                        o_axi_arready <= 1'b0;
                        state         <= S_BURST;
                    end
                end

                // Drive RVALID continuously; advance on each RREADY.
                // beats_left counts beats after the current one; RLAST fires when
                // we just prepared the last beat (beats_left-1 == 0).
                S_BURST: begin
                    if (i_axi_rready && o_axi_rvalid) begin
                        if (o_axi_rlast) begin
                            o_axi_rvalid  <= 1'b0;
                            o_axi_rlast   <= 1'b0;
                            o_axi_arready <= 1'b1;
                            state         <= S_IDLE;
                        end else begin
                            word_idx    <= word_idx + 12'd1;
                            beats_left  <= beats_left - 8'd1;
                            o_axi_rdata <= roms[word_idx + 12'd1];
                            o_axi_rlast <= (beats_left - 8'd1 == 8'd0);
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
