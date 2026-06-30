module pynq_top (
    input  wire         i_Clk,
    input  wire         i_reset,

    input wire          i_debug_en_n,
    input wire          i_debug_rx,
    output wire         o_debug_tx,

    input  wire         i_rx_serial,
    output wire         o_tx_serial,
    
    inout  wire [1:0]   gpio_pins
    
    // output wire        test_hi_lo,
    // output wire        test_locked
);

    wire Clk;
    wire locked;
// PS7 block design — provides FCLK_CLK0 at 50 MHz
//    design_1_wrapper ps_wrapper (
//        .FCLK_CLK0 (Clk)
//    );

    clk_wiz_0 clk_wiz_0 (
        .clk_out1    (Clk),
        .reset       (i_reset),
        .locked      (locked),
        .clk_in1     (i_Clk)
    );
    
    // reg[25:0] Clk_cnt;
    // reg hi_lo;
    // always @(posedge Clk or posedge i_reset) begin
    //     if (i_reset) begin
    //         hi_lo <= 1'b0;
    //         Clk_cnt <= 26'd0;
    //     end
    //     else begin
    //         if (Clk_cnt == 26'd49_999_999) begin
    //             hi_lo   <= ~hi_lo;
    //             Clk_cnt <= 26'd0;
    //         end else begin
    //             Clk_cnt <= Clk_cnt + 1'b1;
    //         end
    //     end
    // end

// assign test_hi_lo = hi_lo;
// assign test_locked = locked;

    wire reset;
    assign reset = i_reset | ~locked;
    
    soc_top #(
        .ROM_FILE ("rom.mem"),
        .RAM_FILE ("ram.mem")
    ) soc_top_0 (
        .i_Clk          (Clk),
        .i_reset        (reset),
        .i_debug_en_n   (i_debug_en_n),
        .i_debug_rx     (i_debug_rx),
        .o_debug_tx     (o_debug_tx),
        .o_tx_serial    (o_tx_serial),
        .i_rx_serial    (i_rx_serial),
        .gpio_pins      (gpio_pins)
    );

endmodule
