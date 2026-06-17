`timescale 1ns/1ps

module cpu_top_tb_simple ();

    localparam CLK_PERIOD       = 20;
    localparam SIMULATION_END   = 20000;

    reg r_Clk;
    reg r_reset;

    cpu_top cpu_top_0 (
        .i_Clk  (r_Clk),
        .i_reset(r_reset)
    );

    initial begin
        r_Clk = 0;
        forever #(CLK_PERIOD/2) r_Clk = ~r_Clk;
    end

    initial begin
        r_reset = 1;
        # 10;
        
        $readmemh("riscvtest.mem", cpu_top_0.Rom_0.roms);
        r_reset = 0;

        #(SIMULATION_END);

        $display("Failed, end time = %0dns", $time);
        print_reg_status();

        $finish(0);
    end

    initial begin
        wait (
            cpu_top_0.Regs_0.regs[0]  == 32'h00000000 &&
            cpu_top_0.Regs_0.regs[1]  == 32'h0000040c &&
            cpu_top_0.Regs_0.regs[2]  == 32'h00000002 &&
            cpu_top_0.Regs_0.regs[3]  == 32'h00000003 &&
            cpu_top_0.Regs_0.regs[4]  == 32'h00000004 &&
            cpu_top_0.Regs_0.regs[5]  == 32'h00000005 &&
            cpu_top_0.Regs_0.regs[6]  == 32'h00000006 &&
            cpu_top_0.Regs_0.regs[7]  == 32'h00000007 &&
            cpu_top_0.Regs_0.regs[8]  == 32'h00000008 &&
            cpu_top_0.Regs_0.regs[9]  == 32'h00000009 &&
            cpu_top_0.Regs_0.regs[10] == 32'h0000000A &&
            cpu_top_0.Regs_0.regs[11] == 32'h0000000B &&
            cpu_top_0.Regs_0.regs[12] == 32'h0000000C &&
            cpu_top_0.Regs_0.regs[13] == 32'h0000000D &&
            cpu_top_0.Regs_0.regs[14] == 32'h0000000E &&
            cpu_top_0.Regs_0.regs[15] == 32'h0000000F &&
            cpu_top_0.Regs_0.regs[16] == 32'h00000010 &&
            cpu_top_0.Regs_0.regs[17] == 32'h00000011 &&
            cpu_top_0.Regs_0.regs[18] == 32'h00000012 &&
            cpu_top_0.Regs_0.regs[19] == 32'h00000013 &&
            cpu_top_0.Regs_0.regs[20] == 32'h00000014 &&
            cpu_top_0.Regs_0.regs[21] == 32'h00000015 &&
            cpu_top_0.Regs_0.regs[22] == 32'h00000016 &&
            cpu_top_0.Regs_0.regs[23] == 32'h00000017 &&
            cpu_top_0.Regs_0.regs[24] == 32'h00000018 &&
            cpu_top_0.Regs_0.regs[25] == 32'h00000019 &&
            cpu_top_0.Regs_0.regs[26] == 32'h0000001A &&
            cpu_top_0.Regs_0.regs[27] == 32'h0000001B &&
            cpu_top_0.Regs_0.regs[28] == 32'h0000001C &&
            cpu_top_0.Regs_0.regs[29] == 32'h0000001D &&
            cpu_top_0.Regs_0.regs[30] == 32'h0000001E &&
            cpu_top_0.Regs_0.regs[31] == 32'h00002000
        );
        $display("Success, end time = %0dns", $time);
        print_reg_status();

        $finish(0);
    end

    task automatic print_reg_status();
        $display("reg0  = 0x%08h", cpu_top_0.Regs_0.regs[0]);
        $display("reg1  = 0x%08h", cpu_top_0.Regs_0.regs[1]);
        $display("reg2  = 0x%08h", cpu_top_0.Regs_0.regs[2]);
        $display("reg3  = 0x%08h", cpu_top_0.Regs_0.regs[3]);
        $display("reg4  = 0x%08h", cpu_top_0.Regs_0.regs[4]);
        $display("reg5  = 0x%08h", cpu_top_0.Regs_0.regs[5]);
        $display("reg6  = 0x%08h", cpu_top_0.Regs_0.regs[6]);
        $display("reg7  = 0x%08h", cpu_top_0.Regs_0.regs[7]);
        $display("reg8  = 0x%08h", cpu_top_0.Regs_0.regs[8]);
        $display("reg9  = 0x%08h", cpu_top_0.Regs_0.regs[9]);
        $display("reg10 = 0x%08h", cpu_top_0.Regs_0.regs[10]);
        $display("reg11 = 0x%08h", cpu_top_0.Regs_0.regs[11]);
        $display("reg12 = 0x%08h", cpu_top_0.Regs_0.regs[12]);
        $display("reg13 = 0x%08h", cpu_top_0.Regs_0.regs[13]);
        $display("reg14 = 0x%08h", cpu_top_0.Regs_0.regs[14]);
        $display("reg15 = 0x%08h", cpu_top_0.Regs_0.regs[15]);
        $display("reg16 = 0x%08h", cpu_top_0.Regs_0.regs[16]);
        $display("reg17 = 0x%08h", cpu_top_0.Regs_0.regs[17]);
        $display("reg18 = 0x%08h", cpu_top_0.Regs_0.regs[18]);
        $display("reg19 = 0x%08h", cpu_top_0.Regs_0.regs[19]);
        $display("reg20 = 0x%08h", cpu_top_0.Regs_0.regs[20]);
        $display("reg21 = 0x%08h", cpu_top_0.Regs_0.regs[21]);
        $display("reg22 = 0x%08h", cpu_top_0.Regs_0.regs[22]);
        $display("reg23 = 0x%08h", cpu_top_0.Regs_0.regs[23]);
        $display("reg24 = 0x%08h", cpu_top_0.Regs_0.regs[24]);
        $display("reg25 = 0x%08h", cpu_top_0.Regs_0.regs[25]);
        $display("reg26 = 0x%08h", cpu_top_0.Regs_0.regs[26]);
        $display("reg27 = 0x%08h", cpu_top_0.Regs_0.regs[27]);
        $display("reg28 = 0x%08h", cpu_top_0.Regs_0.regs[28]);
        $display("reg29 = 0x%08h", cpu_top_0.Regs_0.regs[29]);
        $display("reg30 = 0x%08h", cpu_top_0.Regs_0.regs[30]);
        $display("reg31 = 0x%08h", cpu_top_0.Regs_0.regs[31]);
    endtask

endmodule
