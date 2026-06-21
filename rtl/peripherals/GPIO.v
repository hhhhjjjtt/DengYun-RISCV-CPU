`include "../defines.v"

// 8-pin GPIO
module GPIO # (
    parameter N = 2         // number of GPIO pins
) (
    input wire                          i_Clk,
    input wire                          i_reset,

    // AXI slave — AR channel
    input wire[31:0]                    i_axi_araddr,
    input wire                          i_axi_arvalid,
    output reg                          o_axi_arready,
    input wire[7:0]                     i_axi_arlen,        // unused
    input wire[2:0]                     i_axi_arsize,       // unused
    input wire[1:0]                     i_axi_arburst,      // unused
    // AXI slave — R channel
    output reg[31:0]                    o_axi_rdata,
    output reg                          o_axi_rvalid,
    input wire                          i_axi_rready,
    output reg                          o_axi_rlast,
    // AXI slave — AW channel
    input wire[31:0]                    i_axi_awaddr,
    input wire                          i_axi_awvalid,
    output reg                          o_axi_awready,
    input wire[7:0]                     i_axi_awlen,        // unused
    input wire[2:0]                     i_axi_awsize,       // unused
    input wire[1:0]                     i_axi_awburst,      // unused
    // AXI slave — W channel
    input wire[31:0]                    i_axi_wdata,
    input wire                          i_axi_wvalid,
    output reg                          o_axi_wready,
    input wire                          i_axi_wlast,        // unused
    input wire[3:0]                     i_axi_wstrb,
    // AXI slave — B channel
    output reg[1:0]                     o_axi_bresp,
    output reg                          o_axi_bvalid,
    input wire                          i_axi_bready,

    output wire[N-1:0]                  o_gpio_out,
    output wire[N-1:0]                  o_gpio_out_en,      // 1 = driving, 0 = input/hi-z
    input wire[N-1:0]                   i_gpio_in,

    // to PLIC
    output wire                         o_gpio_interrupt
);

    localparam OFFSET_OUT_DATA  = 8'h00;
    localparam OFFSET_IN_DATA   = 8'h04;
    localparam OFFSET_DIR       = 8'h08;
    localparam OFFSET_INT_EN    = 8'h0C;
    localparam OFFSET_INT_STATE = 8'h10;

    reg[N-1:0] reg_out_data;
    reg[N-1:0] reg_in_data;
    reg[N-1:0] reg_dir;         // 1 = output, 0 = input
    reg[N-1:0] reg_int_en;
    reg[N-1:0] reg_int_state;   // Interrupt status, set by HW when triggered, write 1 to clear

    assign o_gpio_out    = reg_out_data;
    assign o_gpio_out_en = reg_dir;

    // eliminate metastability
    reg[N-1:0] in_data_s0, in_data_prev;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            in_data_s0   <= {N{1'b0}};
            reg_in_data  <= {N{1'b0}};
            in_data_prev <= {N{1'b0}};
        end
        else begin
            in_data_s0   <= i_gpio_in;
            reg_in_data  <= in_data_s0;
            in_data_prev <= reg_in_data;
        end
    end

    // falling edge detection
    wire[N-1:0] data_in_fall = in_data_prev & ~reg_in_data;
    // interrupt
    assign o_gpio_interrupt = |(reg_int_state & reg_int_en);

    // ---- AXI write path ----
    reg             aw_pending;
    reg[31:0]       aw_addr_latch;
    reg             w_pending;
    reg[`DataBus]   w_data_latch;
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_axi_awready   <= `Disable;
            o_axi_wready    <= `Disable;
            o_axi_bresp     <= 2'b00;
            o_axi_bvalid    <= `Disable;
            aw_pending      <= `Disable;
            w_pending       <= `Disable;

            reg_out_data    <= {N{1'b0}};
            reg_dir         <= {N{1'b0}};
            reg_int_en      <= {N{1'b0}};
            reg_int_state   <= {N{1'b0}};
        end
        else begin
            o_axi_awready   <= `Disable;
            o_axi_wready    <= `Disable;
            reg_int_state <= reg_int_state | (data_in_fall & ~reg_dir);
            // Accept AW
            if (i_axi_awvalid && !aw_pending) begin
                o_axi_awready   <= `Enable;
                aw_pending      <= `Enable;
                aw_addr_latch   <= i_axi_awaddr;
            end
            // Accept W
            if (i_axi_wvalid && !w_pending) begin
                o_axi_wready    <= `Enable;
                w_pending       <= `Enable;
                w_data_latch    <= i_axi_wdata;
            end
            // Perform write once both AW and W are latched
            if (aw_pending && w_pending && !o_axi_bvalid) begin
                aw_pending      <= `Disable;
                w_pending       <= `Disable;
                o_axi_bvalid    <= `Enable;
                o_axi_bresp     <= 2'b00;
                case (aw_addr_latch[4:0])
                    OFFSET_OUT_DATA: begin
                        reg_out_data <= w_data_latch[N-1:0];
                    end
                    OFFSET_DIR: begin
                        reg_dir <= w_data_latch[N-1:0];
                    end
                    OFFSET_INT_EN: begin
                        reg_int_en <= w_data_latch[N-1:0];
                    end
                    OFFSET_INT_STATE: begin
                        reg_int_state <= (reg_int_state | (data_in_fall & ~reg_dir))    // HW sets on edge
                                    & ~w_data_latch[N-1:0];                             // SW clears via W1C
                    end
                    default: ;
                endcase
            end
            if (o_axi_bvalid && i_axi_bready) begin
                o_axi_bvalid <= `Disable;
            end
        end
    end

    // ---- AXI read path ----
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            o_axi_arready   <= `Disable;
            o_axi_rdata     <= `ZeroWord;
            o_axi_rvalid    <= `Disable;
            o_axi_rlast     <= `Disable;
        end
        else begin
            o_axi_arready   <= `Disable;

            if (i_axi_arvalid && !o_axi_rvalid) begin
                o_axi_arready   <= `Enable;
                o_axi_rvalid    <= `Enable;
                o_axi_rlast     <= `Enable;

                case (i_axi_araddr[4:0])
                    OFFSET_OUT_DATA: begin
                        o_axi_rdata <= {{(32-N){1'b0}}, reg_out_data};
                    end
                    OFFSET_IN_DATA: begin
                        o_axi_rdata <= {{(32-N){1'b0}}, reg_in_data};
                    end
                    OFFSET_DIR: begin
                        o_axi_rdata <= {{(32-N){1'b0}}, reg_dir};
                    end
                    OFFSET_INT_EN: begin
                        o_axi_rdata <= {{(32-N){1'b0}}, reg_int_en};
                    end
                    OFFSET_INT_STATE: begin
                        o_axi_rdata <= {{(32-N){1'b0}}, reg_int_state};
                    end
                    default: begin
                        o_axi_rdata <= `ZeroWord;
                    end
                endcase
            end

            if (o_axi_rvalid && i_axi_rready) begin
                o_axi_rvalid <= `Disable;
                o_axi_rlast  <= `Disable;
            end
        end
    end

endmodule
