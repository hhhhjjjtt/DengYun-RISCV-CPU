`timescale 1ns/1ps

module tb_uart_loop_multi;

    localparam CLK_PERIOD = 20;
    localparam BAUD_DIV   = 10;
    localparam TEST_BYTE  = 8'h42;
    localparam INIT_WAIT  = 200;

    reg  reg_Clk, reg_reset;
    reg  reg_rx;                      // driven by TB → i_rx_serial
    wire wire_tx;                     // monitored by TB ← o_tx_serial

    soc_top dut (
        .i_Clk               (reg_Clk),
        .i_reset             (reg_reset),
        .i_rx_serial         (reg_rx),
        .o_tx_serial         (wire_tx)
    );

    // ---- clock ----
    initial reg_Clk = 0;
    always #(CLK_PERIOD / 2) reg_Clk = ~reg_Clk;

    // ---- helpers ----
    task step;
        @(posedge reg_Clk); #1;
    endtask

    task stepn;
        input integer n;
        integer i;
        for (i = 0; i < n; i++) step();
    endtask

    // ---- uart_send: drive reg_rx with one UART frame (LSB first) ----
    task uart_send;
        input [7:0] data;
        integer i;
        begin
            reg_rx = 0;                     // start bit
            stepn(BAUD_DIV);
            for (i = 0; i < 8; i++) begin
                reg_rx = data[i];
                stepn(BAUD_DIV);
            end
            reg_rx = 1;                     // stop bit
            stepn(BAUD_DIV);
        end
    endtask

    initial begin
        reg_Clk         = 0;
        reg_reset       = 1;
        reg_rx          = 1;           // UART idle line = high

        $readmemh("uart_loop_multi_inst_rom.mem", dut.ROM_0.roms);
        $readmemh("uart_loop_multi_data_ram.mem", dut.RAM_0.rams);

        stepn(3);
        reg_reset = 0;

        // wait for CPU to finish: mtvec, UART BAUD_DIV, PLIC ENABLE, mstatus
        stepn(INIT_WAIT);

        // ---- step 1: send TEST_BYTE to CPU via RX pin ----
        uart_send(8'h42);
        stepn(300);
        uart_send(8'hAA);
        stepn(300);
        uart_send(8'h55);
        stepn(300);
        uart_send(8'h11);

        stepn(300);

        $finish;
    end

endmodule
