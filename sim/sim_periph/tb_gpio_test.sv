`timescale 1ns/1ps

// tb_gpio_test.sv — GPIO output drive and falling-edge interrupt testbench
//
// Checks (5 total):
//   1. gpio_pins[0] === 1 after setup  (DUT drives output pin high)
//   2. regs[8]  (s0) === 1             (int_count: ISR increments s0 directly)
//   3. regs[9]  (s1) === 0x2           (isr_int_state: ISR writes s1 directly; bit1 = pin1 fell)
//   4. regs[18] (s2) === 0x2           (isr_claim_id: ISR writes s2 directly; source 2 = GPIO)
//   5. regs[10] (a0) === 0x00c0ffee    (pass sentinel)
//
// ISR result registers (s0/s1/s2) are written directly by the ISR with no intervening
// memory store/load, eliminating any D-cache stale-read risk.
//
// Pin assignment:
//   gpio_pins[0] — DUT output (DIR[0]=1); TB leaves as Z, reads the driven value.
//   gpio_pins[1] — DUT input  (DIR[1]=0); TB drives; toggled 1->0 to trigger ISR.
//
// PLIC source mapping (from soc_top PLIC_int_src = {GPIO_interrupt, UART_tx_done, UART_rx_valid}):
//   src[0] = UART_rx_valid   -> source ID 0 (highest priority)
//   src[1] = UART_tx_done    -> source ID 1
//   src[2] = GPIO_interrupt  -> source ID 2

module tb_gpio_test;

    localparam CLK_PERIOD  = 20;    // 50 MHz for sim convenience
    localparam INIT_WAIT   = 200;   // cycles for CPU to finish setup
    localparam WAIT_CYCLES = 300;   // cycles after falling edge for ISR + main to complete

    reg  reg_Clk;
    reg  reg_reset;
    reg  reg_gpio1;                 // TB drives gpio_pins[1]

    // gpio_pins[0]: DUT drives (TB = Z); gpio_pins[1]: TB drives
    wire [1:0] gpio_pins;
    assign gpio_pins = {reg_gpio1, 1'bz};

    soc_top dut (
        .i_Clk       (reg_Clk),
        .i_reset     (reg_reset),
        .i_rx_serial (1'b1),
        .o_tx_serial (),
        .gpio_pins   (gpio_pins)
    );

    initial reg_Clk = 0;
    always #(CLK_PERIOD / 2) reg_Clk = ~reg_Clk;

    task step;  @(posedge reg_Clk); #1; endtask
    task stepn; input integer n; integer i;
        for (i = 0; i < n; i++) step(); endtask

    integer checks_passed;

    initial begin
        reg_reset     = 1;
        reg_gpio1     = 1'b1;       // idle high; falling edge will be driven later
        checks_passed = 0;

        $readmemh("gpio_test_inst_rom.mem", dut.ROM_0.roms);
        $readmemh("gpio_test_data_ram.mem", dut.RAM_0.rams);

        stepn(3); reg_reset = 0;

        // wait for CPU to finish: mtvec, GPIO DIR/OUT_DATA/INT_EN, PLIC, MIE, setup_done
        stepn(INIT_WAIT);

        // ---- check 1: DUT is driving gpio_pins[0] high ----
        if (gpio_pins[0] === 1'b1) begin
            $display("OK  gpio_pins[0] = 1 (output driven high)");
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR gpio_pins[0] = %b (expected 1)", gpio_pins[0]);
        end

        // ---- trigger: drive falling edge on pin 1 ----
        $display("[%0t] Driving falling edge on gpio_pins[1]", $time);
        reg_gpio1 = 1'b0;
        stepn(5);           // hold low for a few cycles
        reg_gpio1 = 1'b1;   // return to idle

        // wait for ISR to fire and main loop to copy results to registers
        stepn(WAIT_CYCLES);

        // ---- check 2: int_count == 1 (in s0 = regs[8]) ----
        if (dut.cpu_core_0.Regs_0.regs[8] === 32'h1) begin
            $display("OK  int_count = 1 (ISR fired)");
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR int_count = %0d (expected 1)", dut.cpu_core_0.Regs_0.regs[8]);
        end

        // ---- check 3: isr_int_state has bit1 set (in s1 = regs[9]) ----
        if (dut.cpu_core_0.Regs_0.regs[9] === 32'h2) begin
            $display("OK  isr_int_state = 0x%08h (bit1: pin1 fell)", dut.cpu_core_0.Regs_0.regs[9]);
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR isr_int_state = 0x%08h (expected 0x00000002)", dut.cpu_core_0.Regs_0.regs[9]);
        end

        // ---- check 4: claim ID was 2 (GPIO source) (in s2 = regs[18]) ----
        if (dut.cpu_core_0.Regs_0.regs[18] === 32'h2) begin
            $display("OK  isr_claim_id = 2 (GPIO source)");
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR isr_claim_id = %0d (expected 2)", dut.cpu_core_0.Regs_0.regs[18]);
        end

        // ---- check 5: pass sentinel ----
        if (dut.cpu_core_0.Regs_0.regs[10] === 32'h00c0ffee) begin
            $display("OK  a0 = 0x00c0ffee (software pass)");
            checks_passed = checks_passed + 1;
        end else begin
            $display("ERR a0 = 0x%08h (expected 0x00c0ffee)", dut.cpu_core_0.Regs_0.regs[10]);
        end

        // ---- result ----
        if (checks_passed === 5)
            $display("PASS: gpio_test");
        else
            $display("FAIL: gpio_test (%0d/5 checks passed)", checks_passed);

        $finish;
    end

endmodule
