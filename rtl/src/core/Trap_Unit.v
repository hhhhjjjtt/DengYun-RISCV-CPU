`include "../defines.v"

module Trap_Unit (
    input wire                  i_Clk,
    input wire                  i_reset,

    // from ID_EX
    input wire[`InstAddrBus]    i_pc_addr,
    input wire[`TrapCauseBus]   i_trap_cause,

    // I/O with Regs_CSR, read (unused for now, reserved for future use)
    input wire[`DataBus]        i_trap_csr_rd_data,
    output reg[`DataAddrBus]    o_trap_csr_rd_addr,
    // I/O with Regs_CSR, write
    output reg                  o_trap_csr_wr_en,
    output reg[`DataAddrBus]    o_trap_csr_wr_addr,
    output reg[`DataBus]        o_trap_csr_wr_data,
    // from Regs_CSR
    input wire[`DataBus]        i_csr_mtvec,
    input wire[`DataBus]        i_csr_mepc,
    input wire[`DataBus]        i_csr_mie,
    input wire[`DataBus]        i_csr_mstatus,

    // external/timer interrupt
    input wire                  i_timer_int_pending,    // from CLINT, gate with mie[7],  cause=0x80000007
    input wire                  i_external_int_pending, // from PLIC,  gate with mie[11], cause=0x8000000B

    // to Ctrl_Unit
    output reg                  o_trap_jump_flag,
    output reg[`InstAddrBus]    o_trap_jump_addr,
    output reg                  o_trap_stall,
    output reg                  o_trap_is_interrupt,

    // from Ctrl_Unit (stall signals — interrupt must not fire while pipeline is stalled)
    input wire                  i_mem_stall,
    input wire                  i_if_stall
);

    // State machine states
    localparam S_IDLE         = 2'b00;
    localparam S_TRAP_MCAUSE  = 2'b01;  // cycle 1: write mcause, stall
    localparam S_TRAP_MSTATUS = 2'b10;  // cycle 2: write mstatus, stall

    // mstatus bit aliases
    wire mstatus_mie  = i_csr_mstatus[3];   // Machine Interrupt Enable
    wire mstatus_mpie = i_csr_mstatus[7];   // Machine Previous Interrupt Enable

    // trap condition wires
    wire pipeline_free   = !i_mem_stall && !i_if_stall;
    wire is_exception    = (i_trap_cause == `trap_ecall) || (i_trap_cause == `trap_ebreak);
    wire is_timer_int    = i_timer_int_pending    && i_csr_mie[7]  && mstatus_mie && pipeline_free;
    wire is_external_int = i_external_int_pending && i_csr_mie[11] && mstatus_mie && pipeline_free;
    wire is_interrupt    = is_timer_int || is_external_int;
    wire is_mret         = (i_trap_cause == `trap_mret);

    reg[1:0]      state;
    reg[1:0]      next_state;
    reg[`DataBus] r_mcause;  // latched mcause value for use in S_TRAP_MCAUSE

    // Sequential: state register and mcause latch
    always @(posedge i_Clk or posedge i_reset) begin
        if (i_reset) begin
            state    <= S_IDLE;
            r_mcause <= `ZeroWord;
        end else begin
            state <= next_state;
            // latch mcause when trap is first detected so it's stable in S_TRAP_MCAUSE
            if (state == S_IDLE && (is_exception || is_interrupt)) begin
                if (is_timer_int) begin
                    r_mcause <= 32'h80000007;
                end
                else if (is_external_int) begin
                    r_mcause <= 32'h8000000B;
                end
                else if (i_trap_cause  == `trap_ecall) begin
                    r_mcause <= 32'd11;
                end
                else begin // i_trap_cause == `trap_ebreak
                    r_mcause <= 32'd3;
                end
            end
        end
    end

    // Combinational: output logic
    //
    // Trap entry (3-cycle sequence):
    //   Cycle 0 (S_IDLE):         write mepc,   assert jump → mtvec, no stall
    //   Cycle 1 (S_TRAP_MCAUSE):  write mcause,                      stall
    //   Cycle 2 (S_TRAP_MSTATUS): write mstatus,                     stall
    //
    // mret (1-cycle):
    //   Cycle 0 (S_IDLE):  write mstatus, assert jump → mepc, no stall
    always @(*) begin
        o_trap_csr_rd_addr  = `ZeroWord;
        o_trap_csr_wr_en    = 1'b0;
        o_trap_csr_wr_addr  = `ZeroWord;
        o_trap_csr_wr_data  = `ZeroWord;
        o_trap_jump_flag    = 1'b0;
        o_trap_jump_addr    = `ZeroAddr;
        o_trap_stall        = 1'b0;
        o_trap_is_interrupt = 1'b0;
        next_state          = state;

        case (state)
            S_IDLE: begin
                if (is_exception || is_interrupt) begin
                    // Cycle 0: save PC to mepc, redirect to mtvec
                    o_trap_csr_wr_en    = 1'b1;
                    o_trap_csr_wr_addr  = `CSR_MEPC;
                    o_trap_csr_wr_data  = i_pc_addr;
                    o_trap_jump_flag    = 1'b1;
                    o_trap_is_interrupt = is_interrupt;
                    o_trap_jump_addr   = i_csr_mtvec;
                    next_state         = S_TRAP_MCAUSE;
                end else if (is_mret) begin
                    // Restore mstatus: MIE←MPIE, MPIE←1, MPP←M(11)
                    o_trap_csr_wr_en   = 1'b1;
                    o_trap_csr_wr_addr = `CSR_MSTATUS;
                    o_trap_csr_wr_data = (i_csr_mstatus & ~`MSTATUS_CLEAR) |
                                         (mstatus_mpie ? `MSTATUS_MIE : 32'h0)     |
                                         `MSTATUS_MPIE                      |
                                         `MSTATUS_MPP;
                    o_trap_jump_flag   = 1'b1;
                    o_trap_jump_addr   = i_csr_mepc;
                    next_state         = S_IDLE;
                end
            end

            S_TRAP_MCAUSE: begin
                // Cycle 1: write mcause, hold pipeline front-end
                o_trap_stall       = 1'b1;
                o_trap_csr_wr_en   = 1'b1;
                o_trap_csr_wr_addr = `CSR_MCAUSE;
                o_trap_csr_wr_data = r_mcause;
                next_state         = S_TRAP_MSTATUS;
            end

            S_TRAP_MSTATUS: begin
                // Cycle 2: write mstatus, clear MIE, save old MIE to MPIE
                // i_csr_mstatus is still the original value (nothing else wrote it)
                o_trap_stall       = 1'b1;
                o_trap_csr_wr_en   = 1'b1;
                o_trap_csr_wr_addr = `CSR_MSTATUS;
                o_trap_csr_wr_data = (i_csr_mstatus & ~`MSTATUS_CLEAR) |
                                     (mstatus_mie ? `MSTATUS_MPIE : 32'h0)     |
                                     `MSTATUS_MPP;
                next_state         = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

endmodule
