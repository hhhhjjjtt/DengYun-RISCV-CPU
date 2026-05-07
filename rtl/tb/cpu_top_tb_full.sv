`timescale 1ns/1ps

module cpu_top_tb_02 ();

    localparam CLK_PERIOD       = 20;
    localparam SIMULATION_END   = 10000;

    reg r_Clk;
    reg r_reset;

    cpu_top cpu_top_0 (
        .i_Clk  (r_Clk),
        .i_reset(r_reset)
    );

    string  testcase;
    integer numcycles;

    // sim
    initial begin
        testcase = "add";
        run_riscv_test();
        testcase = "addi";
        run_riscv_test();
        testcase = "and";
        run_riscv_test();
        testcase = "andi";
        run_riscv_test();
        testcase = "auipc";
        run_riscv_test();
        testcase = "beq";
        run_riscv_test();
        testcase = "bge";
        run_riscv_test();
        testcase = "bgeu";
        run_riscv_test();
        testcase = "blt";
        run_riscv_test();
        testcase = "bltu";
        run_riscv_test();
        testcase = "bne";
        run_riscv_test();
        testcase = "jal";
        run_riscv_test();
        testcase = "jalr";
        run_riscv_test();
        testcase = "lb";
        run_riscv_test();
        testcase = "lbu";
        run_riscv_test();
        testcase = "lh";
        run_riscv_test();
        testcase = "lhu";
        run_riscv_test();
        testcase = "lui";
        run_riscv_test();
        testcase = "lw";
        run_riscv_test();
        testcase = "or";
        run_riscv_test();
        testcase = "ori";
        run_riscv_test();
        testcase = "sb";
        run_riscv_test();
        testcase = "sh";
        run_riscv_test();
        testcase = "sll";
        run_riscv_test();
        testcase = "slli";
        run_riscv_test();
        testcase = "slt";
        run_riscv_test();
        testcase = "slti";
        run_riscv_test();
        testcase = "sra";
        run_riscv_test();
        testcase = "srai";
        run_riscv_test();
        testcase = "srl";
        run_riscv_test();
        testcase = "srli";
        run_riscv_test();
        testcase = "sub";
        run_riscv_test();
        testcase = "sw";
        run_riscv_test();
        testcase = "xor";
        run_riscv_test();
        testcase = "xori";
        run_riscv_test();
    end

    task step;
        begin
            #(CLK_PERIOD/2 - 1) r_Clk = 1'b0;
            #(CLK_PERIOD/2)     r_Clk = 1'b1;
            numcycles = numcycles + 1;
            #1 ;
        end
    endtask

    task stepn; // step n cycles
        input integer n;
        integer i;
        begin
            for (i = 0; i < n ; i = i + 1)
            step();
        end
    endtask

    task resetcpu;  // reset the CPU and the test
        begin
            r_reset = 1'b1;
            step();
            #5 r_reset = 1'b0;
            numcycles = 0;
        end
    endtask

    task loadtestcase;  // load intstructions to inst_rom; data to data_ram
        begin
            $readmemh({testcase, "_inst_rom.mem"},cpu_top_0.Rom_0.roms);
            $readmemh({testcase, "_data_ram.mem"},cpu_top_0.Ram_0.rams);
            $display("---Begin test case %s-----", testcase);
        end
    endtask

    task run;
        integer i;
        begin
            i = 0;
            while((cpu_top_0.Regs_0.regs[10] != 32'h00c0ffee) && (i < SIMULATION_END)) begin
                step();
                i = i+1;
            end
        end
    endtask

    task checkmagnum;   // check upon a halt
        begin
            if(numcycles > SIMULATION_END) begin
                $display("!!!Error:test case %s does not terminate!", testcase);
            end
            else if(cpu_top_0.Regs_0.regs[10] == 32'h00c0ffee) begin
                $display("OK:test case %s finshed OK at cycle %d.",
                        testcase, numcycles - 1);
            end
            else if(cpu_top_0.Regs_0.regs[10] == 32'hdeaddead) begin
                $display("!!!ERROR:test case %s finshed with error in cycle %d.",
                        testcase, numcycles - 1);
            end
            else begin
                $display("!!!ERROR:test case %s unknown error in cycle %d.",
                        testcase, numcycles - 1);
            end
        end
    endtask

    task run_riscv_test;
        begin
            loadtestcase();
            resetcpu();
            run();
            checkmagnum();
        end
    endtask

endmodule
