`timescale 1ns/1ps

// uart_loop_tb.sv — UART loopback testbench
//
// Checks:
//   1. CPU receives TEST_BYTE via RX interrupt and validates it (software check).
//   2. CPU echoes the byte back via TX; testbench captures and checks it.
//   3. Software writes 0x00c0ffee to a0 on success; testbench checks a0.
//
// BAUD_DIV must match the #define BAUD_DIV_SIM in uart_loop.S.

module uart_loop_tb;

    localparam CLK_PERIOD = 20;       // 100 MHz → 20 ns
    localparam BAUD_DIV   = 10;       // cycles per UART bit (must match .S)
    localparam TEST_BYTE  = 8'h42;    // 'B'  (must match .S)
    localparam INIT_WAIT  = 200;      // cycles for CPU to finish setup

    reg  clk, reset;
    reg  reg_rx;                      // driven by TB → i_rx_serial
    wire wire_tx;                     // monitored by TB ← o_tx_serial

    soc_top dut (
        .i_Clk               (clk),
        .i_reset             (reset),
        .i_rx_serial         (reg_rx),
        .o_tx_serial         (wire_tx),
        .i_timer_int_pending (1'b0)
    );

    // ---- clock ----
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ---- helpers ----
    task step;
        @(posedge clk); #1;
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

    // ---- uart_recv: capture one UART frame from wire_tx ----
    // Waits up to 2000 cycles for the start bit; returns 8'hFF on timeout.
    task uart_recv;
        output [7:0] data;
        integer i, cnt;
        begin
            data = 8'hFF;

            // wait for start bit (wire_tx falls to 0)
            cnt = 0;
            while (wire_tx !== 1'b0 && cnt < 2000) begin
                @(posedge clk); #1;
                cnt = cnt + 1;
            end
            if (cnt >= 2000) begin
                $display("ERROR uart_recv: timeout, no TX start bit after 2000 cycles");
                return;
            end

            // advance to mid-start-bit, then one full baud period per data bit
            stepn(BAUD_DIV / 2);
            for (i = 0; i < 8; i++) begin
                stepn(BAUD_DIV);
                data[i] = wire_tx;
            end
            stepn(BAUD_DIV);                // consume stop bit
        end
    endtask

    // ---- test body ----
    reg [7:0] rx_byte;
    integer   checks_passed;

    initial begin
        clk    = 0;
        reset  = 1;
        reg_rx = 1;           // UART idle line = high
        checks_passed = 0;

        $readmemh("uart_loop_inst_rom.mem", dut.ROM_0.roms);
        $readmemh("uart_loop_data_ram.mem", dut.RAM_0.rams);

        stepn(3);
        reset = 0;

        // wait for CPU to finish: mtvec, UART BAUD_DIV, PLIC ENABLE, mstatus
        stepn(INIT_WAIT);

        // ---- step 1: send TEST_BYTE to CPU via RX pin ----
        $display("[%0t] Sending 0x%02h to CPU RX", $time, TEST_BYTE);
        uart_send(TEST_BYTE);

        // ---- step 2: receive echo from CPU TX pin ----
        $display("[%0t] Waiting for TX echo...", $time);
        uart_recv(rx_byte);

        if (rx_byte === TEST_BYTE) begin
            $display("OK  TX echo: got 0x%02h (expected 0x%02h)", rx_byte, TEST_BYTE);
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR TX echo: got 0x%02h (expected 0x%02h)", rx_byte, TEST_BYTE);
        end

        // ---- step 3: give CPU time to write a0, then check it ----
        stepn(100);

        if (dut.CPU_0.Regs_0.regs[10] === 32'h00c0ffee) begin
            $display("OK  a0 = 0x00c0ffee (software pass)");
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR a0 = 0x%08h (expected 0x00c0ffee)", dut.CPU_0.Regs_0.regs[10]);
        end

        // ---- result ----
        if (checks_passed === 2)
            $display("PASS: uart_loop");
        else
            $display("FAIL: uart_loop (%0d/2 checks passed)", checks_passed);

        $finish;
    end

endmodule
