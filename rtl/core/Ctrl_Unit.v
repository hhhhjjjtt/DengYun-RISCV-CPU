`include "../defines.v"

module Ctrl_Unit (
    // from IF
    input wire                      i_if_stall,

    // from ID
    input wire                      i_id_load_use,
    
    // from EX
    input wire                      i_ex_branch,
    input wire                      i_ex_division_busy,
    input wire                      i_jump_flag,
    input wire[`InstAddrBus]        i_jump_addr,
    
    // from MEM
    input wire                      i_mem_stall,

    // from Trap_Unit
    input wire                      i_trap_jump_flag,
    input wire[`InstAddrBus]        i_trap_jump_addr,
    input wire                      i_trap_stall,
    input wire                      i_trap_is_interrupt,

    // to PC
    output reg[`CtrlTypeBus]        o_pc_ctrl,
    output reg                      o_jump_flag,
    output reg[`InstAddrBus]        o_jump_addr,
    
    // to pipeline registers
    output reg[`CtrlTypeBus]        o_if_id_ctrl,       // to IF_ID
    output reg[`CtrlTypeBus]        o_id_ex_ctrl,       // to ID_EX
    output reg[`CtrlTypeBus]        o_ex_mem_ctrl,      // to EX_MEM
    output reg[`CtrlTypeBus]        o_mem_wb_ctrl       // to MEM_WB
);
    
    always @(*) begin
        o_pc_ctrl       = `ctrl_none;
        o_if_id_ctrl    = `ctrl_none;
        o_id_ex_ctrl    = `ctrl_none;
        o_ex_mem_ctrl   = `ctrl_none;
        o_mem_wb_ctrl   = `ctrl_none;
        o_jump_flag     = i_jump_flag;
        o_jump_addr     = i_jump_addr;
        if (i_mem_stall || i_if_stall || i_trap_stall) begin   // full pipeline stall
            o_pc_ctrl       = `ctrl_stall;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_stall;
            o_ex_mem_ctrl   = `ctrl_stall;
            o_mem_wb_ctrl   = `ctrl_stall;
        end
        else if (i_trap_jump_flag) begin        // trap/mret: flush IF/ID, redirect PC
            o_pc_ctrl       = `ctrl_none;
            o_if_id_ctrl    = `ctrl_flush;
            o_id_ex_ctrl    = `ctrl_flush;
            // interrupts flush EX so mepc (=PC_EX) is the correct return address;
            // exceptions let EX complete (ecall/ebreak write nothing to rd)
            o_ex_mem_ctrl   = i_trap_is_interrupt ? `ctrl_flush : `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
            o_jump_flag     = i_trap_jump_flag;
            o_jump_addr     = i_trap_jump_addr;
        end
        else if (i_ex_division_busy) begin
            o_pc_ctrl       = `ctrl_stall;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_stall;
            o_ex_mem_ctrl   = `ctrl_flush;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else if (i_ex_branch) begin             // pipeline flush due to branch
            o_pc_ctrl       = `ctrl_none;
            o_if_id_ctrl    = `ctrl_flush;
            o_id_ex_ctrl    = `ctrl_flush;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else if (i_id_load_use) begin           // pipeline stall due to load instructions
            o_pc_ctrl       = `ctrl_stall;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_flush;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
    end

endmodule
