`include "defines.v"

module ctrl (
    // from if
    input wire                      i_if_stall,

    // from id
    input wire                      i_id_load_use,
    
    // from ex
    input wire                      i_ex_branch,
    input wire                      i_ex_division_busy,
    input wire                      i_jump_flag,
    input wire[`InstAddrBus]        i_jump_addr,
    
    // from mem
    input wire                      i_mem_stall,

    // to pc
    output reg[`CtrlTypeBus]        o_pc_ctrl,
    output reg                      o_jump_flag,
    output reg[`InstAddrBus]        o_jump_addr,
    
    // to pipeline registers
    output reg[`CtrlTypeBus]        o_if_id_ctrl,       // to if_id
    output reg[`CtrlTypeBus]        o_id_ex_ctrl,       // to id_ex
    output reg[`CtrlTypeBus]        o_ex_mem_ctrl,      // to ex_mem
    output reg[`CtrlTypeBus]        o_mem_wb_ctrl       // to mem_wb
);
    
    always @(*) begin
        o_pc_ctrl       = `ctrl_none;
        o_if_id_ctrl    = `ctrl_none;
        o_id_ex_ctrl    = `ctrl_none;
        o_ex_mem_ctrl   = `ctrl_none;
        o_mem_wb_ctrl   = `ctrl_none;
        o_jump_flag     = `JumpDisable;
        o_jump_addr     = `ZeroAddr;
        if (i_mem_stall) begin              // pipeline stall due to data memory access
            o_pc_ctrl       = `ctrl_stall;
            o_jump_flag     = `JumpDisable;
            o_jump_addr     = `ZeroAddr;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_stall;
            o_ex_mem_ctrl   = `ctrl_stall;
            o_mem_wb_ctrl   = `ctrl_flush;
        end
        else if (i_ex_division_busy) begin
            o_pc_ctrl       = `ctrl_stall;
            o_jump_flag     = `JumpDisable;
            o_jump_addr     = `ZeroAddr;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_stall;
            o_ex_mem_ctrl   = `ctrl_flush;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else if (i_ex_branch) begin         // pipeline flush due to branch
            o_pc_ctrl       = `ctrl_none;
            o_jump_flag     = i_jump_flag;
            o_jump_addr     = i_jump_addr;
            o_if_id_ctrl    = `ctrl_flush;
            o_id_ex_ctrl    = `ctrl_flush;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else if (i_id_load_use) begin       // pipeline stall due to load instructions
            o_pc_ctrl       = `ctrl_stall;
            o_jump_flag     = `JumpDisable;
            o_jump_addr     = `ZeroAddr;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_flush;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else if (i_if_stall) begin          // pipeline stall due to instruction memory access
            o_pc_ctrl       = `ctrl_stall;
            o_jump_flag     = `JumpDisable;
            o_jump_addr     = `ZeroAddr;
            o_if_id_ctrl    = `ctrl_stall;
            o_id_ex_ctrl    = `ctrl_flush;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
        else begin
            o_pc_ctrl       = `ctrl_none;
            o_jump_flag     = `JumpDisable;
            o_jump_addr     = `ZeroAddr;
            o_if_id_ctrl    = `ctrl_none;
            o_id_ex_ctrl    = `ctrl_none;
            o_ex_mem_ctrl   = `ctrl_none;
            o_mem_wb_ctrl   = `ctrl_none;
        end
    end

endmodule
