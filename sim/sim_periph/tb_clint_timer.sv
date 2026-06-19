`timescale 1ns/1ps

// tb_clint_timer.sv — CLINT timer interrupt testbench
//
// Checks:
//   1. reg_mtime is counting (two DUT-internal peeks 50 cycles apart).
//   2. regs[8] (s0) == NUM_TICKS — software copies mscratch counter to s0 at exit.
//   3. a0 == 0x00c0ffee (software exited the spin loop and wrote pass sentinel).
//
// TICK_CYCLES and NUM_TICKS must match #defines in clint_timer.S.

module tb_clint_timer;

    localparam CLK_PERIOD  = 20;
    localparam TICK_CYCLES = 200;   // must match .S
    localparam NUM_TICKS   = 3;     // must match .S
    // reset(3) + setup(~30) + NUM_TICKS*(TICK_CYCLES + ISR~40) + margin
    localparam WAIT_CYCLES = 1500;

    reg reg_Clk;
    reg reg_reset;

    soc_top dut (
        .i_Clk       (reg_Clk),
        .i_reset     (reg_reset),
        .i_rx_serial (1'b1),
        .o_tx_serial ()
    );

    initial reg_Clk = 0;
    always #(CLK_PERIOD / 2) reg_Clk = ~reg_Clk;

    task step;  @(posedge reg_Clk); #1; endtask
    task stepn; input integer n; integer i;
        for (i = 0; i < n; i++) step(); endtask

    integer checks_passed;
    reg [31:0] mtime_early, mtime_late;

    initial begin
        reg_reset = 1;
        checks_passed = 0;

        $readmemh("clint_timer_inst_rom.mem", dut.ROM_0.roms);
        $readmemh("clint_timer_data_ram.mem", dut.RAM_0.rams);

        stepn(3); reg_reset = 0;

        // ---- check 1: mtime is counting ----
        stepn(10);
        mtime_early = dut.CLINT_0.reg_mtime;
        stepn(50);
        mtime_late  = dut.CLINT_0.reg_mtime;

        if (mtime_late > mtime_early) begin
            $display("OK  mtime counting: %0d -> %0d", mtime_early, mtime_late);
            checks_passed = checks_passed + 1;
        end else
            $display("ERR mtime not counting: early=%0d late=%0d", mtime_early, mtime_late);

        // ---- wait for software to finish ----
        stepn(WAIT_CYCLES);

        // ---- check 2: int_count == NUM_TICKS ----
        // software stores final int_count in s0 (regs[8]) before halting
        if (dut.cpu_core_0.Regs_0.regs[8] === NUM_TICKS) begin
            $display("OK  int_count = %0d", dut.cpu_core_0.Regs_0.regs[8]);
            checks_passed = checks_passed + 1;
        end else
            $display("ERR int_count = %0d (expected %0d)", dut.cpu_core_0.Regs_0.regs[8], NUM_TICKS);

        // ---- check 3: pass sentinel ----
        if (dut.cpu_core_0.Regs_0.regs[10] === 32'h00c0ffee) begin
            $display("OK  a0 = 0x00c0ffee");
            checks_passed = checks_passed + 1;
        end else
            $display("ERR a0 = 0x%08h (expected 0x00c0ffee)",
                     dut.cpu_core_0.Regs_0.regs[10]);

        if (checks_passed === 3) $display("PASS: clint_timer");
        else $display("FAIL: clint_timer (%0d/3)", checks_passed);

        $finish;
    end

endmodule
