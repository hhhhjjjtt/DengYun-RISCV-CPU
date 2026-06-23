module pynq_top (
    input  wire        i_reset,
    output wire        o_tx_serial,
    input  wire        i_rx_serial,
    inout  wire [1:0]  gpio_pins
);

    wire Clk;

    // PS7 block design — provides FCLK_CLK0 at 50 MHz
    design_1_wrapper ps_wrapper (
        .FCLK_CLK0_0 (Clk)
    );

    soc_top #(
        .ROM_FILE ("rom.mem"),
        .RAM_FILE ("ram.mem")
    ) soc_top_0 (
        .i_Clk       (Clk),
        .i_reset     (i_reset),
        .o_tx_serial (o_tx_serial),
        .i_rx_serial (i_rx_serial),
        .gpio_pins   (gpio_pins)
    );

endmodule
