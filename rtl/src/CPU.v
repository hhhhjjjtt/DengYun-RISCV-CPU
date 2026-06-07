`include "defines.v"

module CPU (
    input wire                  i_Clk,
    input wire                  i_reset,

    input wire                  i_timer_int_pending,
    input wire                  i_external_int_pending,

    // to I_Cache
    output wire                 o_imem_valid,
    input wire                  i_imem_ready,
    output wire[`InstAddrBus]   o_imem_rd_addr,
    input wire[`DataBus]        i_imem_rd_data,
    
    // to D_Cache
    output wire                 o_dcache_en,
    output wire                 o_mmio_en,
    output wire                 o_dmem_valid,
    input wire                  i_dmem_ready,
    output wire                 o_dmem_rd_en,
    output wire[`DataAddrBus]   o_dmem_rd_addr,
    input wire[`DataBus]        i_dmem_rd_data,
    output wire                 o_dmem_wr_en,
    output wire[`StrbBus]       o_dmem_wr_strb,
    output wire[`DataAddrBus]   o_dmem_wr_addr,
    output wire[`DataBus]       o_dmem_wr_data
);

    // ---- Ctrl_Unit_0 outputs ---- 
    wire[`CtrlTypeBus]      ctrl_unit_0_w_pc_ctrl;
    wire                    ctrl_unit_0_w_jump_flag;
    wire[`InstAddrBus]      ctrl_unit_0_w_jump_addr;
    
    wire[`CtrlTypeBus]      ctrl_unit_0_w_if_id_ctrl;
    wire[`CtrlTypeBus]      ctrl_unit_0_w_id_ex_ctrl;
    wire[`CtrlTypeBus]      ctrl_unit_0_w_ex_mem_ctrl;
    wire[`CtrlTypeBus]      ctrl_unit_0_w_mem_wb_ctrl;
    
    // ---- PC_0 outputs ---- 
    wire[`InstAddrBus]      pc_0_w_pc_addr;
    
    // ---- IF_0 outputs ----     
    wire                    if_0_w_if_stall;
    
    wire[`InstAddrBus]      if_0_w_pc_addr;
    wire[`DataBus]          if_0_w_inst_data;
    
    // ---- IF_ID_0 outputs ---- 
    wire[`InstAddrBus]      if_id_0_w_pc_addr;
    wire[`DataBus]          if_id_0_w_inst_dat;
    
    // ---- ID_0 outputs ---- 
    wire[`RegsAddrBus]      id_0_w_reg1_rd_addr;
    wire[`RegsAddrBus]      id_0_w_reg2_rd_addr;

    wire[`CSRAddrBus]       id_0_w_csr_rd_addr;

    wire[`InstAddrBus]      id_0_w_pc_addr;
    wire[`DataBus]          id_0_w_inst_data;
    wire[`DataBus]          id_0_w_reg1_data;
    wire[`RegsAddrBus]      id_0_w_reg1_addr;
    wire[`DataBus]          id_0_w_reg2_data;
    wire[`RegsAddrBus]      id_0_w_reg2_addr;
    wire[`RegsAddrBus]      id_0_w_regd_addr;
    wire[`DataBus]          id_0_w_imm_data;

    wire                    id_0_w_Reg_we;
    wire                    id_0_w_ALU_src_A;
    wire[1:0]               id_0_w_ALU_src_B;
    wire[4:0]               id_0_w_ALU_op;
    wire[2:0]               id_0_w_Branch;
    wire                    id_0_w_MemtoReg_src;
    wire                    id_0_w_Mem_we;
    wire                    id_0_w_Mem_re;
    wire[2:0]               id_0_w_Mem_op;

    wire[2:0]               id_0_w_csr_op;
    wire                    id_0_w_csr_wr_en;
    wire[`CSRAddrBus]       id_0_w_csr_wr_addr;
    wire[`DataBus]          id_0_w_csr_data;
    wire[`DataBus]          id_0_w_csr_zimm_data;

    wire                    id_0_w_id_load_use;
    wire[`TrapCauseBus]     id_0_w_trap_cause;

    // ---- Regs_0 outputs ----
    wire[`DataBus]          regs_0_w_rd_data1;
    wire[`DataBus]          regs_0_w_rd_data2;

    // ---- Regs_CSR_0 outputs ----
    wire[`DataBus]          regs_csr_0_w_id_csr_rd_data;

	wire[`DataBus]          regs_csr_0_w_trap_csr_rd_data;
    
	wire[`DataBus]          regs_csr_0_w_csr_mtvec;
    wire[`DataBus]          regs_csr_0_w_csr_mepc;
    wire[`DataBus]          regs_csr_0_w_csr_mie;
    wire[`DataBus]          regs_csr_0_w_csr_mstatus;
	wire                    regs_csr_0_w_global_int_en;
    
    // ---- ID_EX_0 outputs ---- 
    wire[`InstAddrBus]      id_ex_0_w_pc_addr;
    wire[`DataBus]          id_ex_0_w_inst_data;
    wire[`DataBus]          id_ex_0_w_reg1_data;  
    wire[`RegsAddrBus]      id_ex_0_w_reg1_addr;
    wire[`DataBus]          id_ex_0_w_reg2_data;  
    wire[`RegsAddrBus]      id_ex_0_w_reg2_addr;
    wire[`RegsAddrBus]      id_ex_0_w_regd_addr;  
    wire[`DataBus]          id_ex_0_w_imm_data;  
    
    wire                    id_ex_0_w_Reg_we;
    wire                    id_ex_0_w_ALU_src_A;
    wire[1:0]               id_ex_0_w_ALU_src_B;
    wire[4:0]               id_ex_0_w_ALU_op;
    wire[2:0]               id_ex_0_w_Branch;
    wire                    id_ex_0_w_MemtoReg_src;
    wire                    id_ex_0_w_Mem_we;
    wire                    id_ex_0_w_Mem_re;
    wire[2:0]               id_ex_0_w_Mem_op;

    wire[2:0]               id_ex_0_csr_op;
    wire                    id_ex_0_csr_wr_en;
	wire[`CSRAddrBus]       id_ex_0_csr_wr_addr;
    wire[`DataBus]          id_ex_0_csr_data;
    wire[`DataBus]          id_ex_0_csr_zimm_data;

    wire                    id_ex_0_w_id_ex_Mem_re;
    wire                    id_ex_0_w_id_ex_Reg_we;
    wire[`RegsAddrBus]      id_ex_0_w_id_ex_regd_addr;
    wire[`TrapCauseBus]     id_ex_0_w_trap_cause;

    // ---- Trap_Unit_0 outputs ----
    wire                    trap_unit_0_w_trap_jump_flag;
    wire[`InstAddrBus]      trap_unit_0_w_trap_jump_addr;
    wire                    trap_unit_0_w_trap_stall;
    wire[`DataAddrBus]      trap_unit_0_w_trap_csr_rd_addr;
    wire                    trap_unit_0_w_trap_csr_wr_en;
    wire[`DataAddrBus]      trap_unit_0_w_trap_csr_wr_addr;
    wire[`DataBus]          trap_unit_0_w_trap_csr_wr_data;

    // ---- EX_0 outputs ----
    wire[`DataBus]          ex_0_w_dividend_data;
    wire[`DataBus]          ex_0_w_divisor_data;
    wire                    ex_0_w_div_valid;
    wire                    ex_0_w_div_signed;

    wire                    ex_0_w_csr_wr_en;
	wire[`CSRAddrBus]       ex_0_w_csr_wr_addr;
	wire[`DataBus]          ex_0_w_csr_wr_data;

    wire[`InstAddrBus]      ex_0_w_pc_addr;
    wire[`DataBus]          ex_0_w_inst_data;
    wire                    ex_0_w_wb_src;
    wire                    ex_0_w_regd_we;
    wire[`RegsAddrBus]      ex_0_w_regd_addr;
    wire[`DataBus]          ex_0_w_regd_data;
    wire                    ex_0_w_mem_we;
    wire                    ex_0_w_mem_re;
    wire[`DataAddrBus]      ex_0_w_mem_addr;
    wire[`DataBus]          ex_0_w_mem_wr_data_raw;
    wire[`MemOpTypeBus]     ex_0_w_mem_op_type;

    wire                    ex_0_w_ex_branch;
    wire                    ex_0_w_ex_division_busy;
    wire                    ex_0_w_jump_flag;
    wire[`InstAddrBus]      ex_0_w_jump_addr;
    
    // ---- Divider_0 outputs ----
    wire[`DataBus]          divider_0_w_quotient_data;
    wire[`DataBus]          divider_0_w_remainder_data;
    wire                    divider_0_w_div_ready;
    
    // ---- EX_MEM_0 outputs ----
    wire[`InstAddrBus]      ex_mem_0_w_pc_addr;
    wire[`DataBus]          ex_mem_0_w_inst_data;
    wire                    ex_mem_0_w_wb_src;
    wire                    ex_mem_0_w_regd_we;
    wire[`RegsAddrBus]      ex_mem_0_w_regd_addr;
    wire[`DataBus]          ex_mem_0_w_regd_data;
    wire                    ex_mem_0_w_mem_we;
    wire                    ex_mem_0_w_mem_re;
    wire[`DataAddrBus]      ex_mem_0_w_mem_addr;
    wire[`DataBus]          ex_mem_0_w_mem_wr_data_raw;
    wire[`MemOpTypeBus]     ex_mem_0_w_mem_op_type;
    
    wire                    ex_mem_0_w_ex_mem_regd_we;
    wire[`RegsAddrBus]      ex_mem_0_w_ex_mem_regd_addr;
    wire[`DataBus]          ex_mem_0_w_ex_mem_regd_data;
    
    // ---- MEM_0 outputs ----
    wire                    mem_0_w_mem_stall;
    
    wire                    mem_0_w_regd_we;
    wire[`RegsAddrBus]      mem_0_w_regd_addr;
    wire[`DataBus]          mem_0_w_regd_data;
    
    // ---- MEM_WB_0 outputs ----
    wire                    mem_wb_0_w_regd_we;
    wire[`RegsAddrBus]      mem_wb_0_w_regd_addr;
    wire[`DataBus]          mem_wb_0_w_regd_data;
    
    wire                    mem_wb_0_w_mem_wb_regd_we;
    wire[`RegsAddrBus]      mem_wb_0_w_mem_wb_regd_addr;
    wire[`DataBus]          mem_wb_0_w_mem_wb_regd_data;
    
    // ---- WB_0 outputs ----
    wire                    wb_0_w_regd_we;
    wire[`RegsAddrBus]      wb_0_w_regd_addr;
    wire[`DataBus]          wb_0_w_regd_data;

    // ---- extra control for Divider ----
    wire                    div_result_accept;
    assign div_result_accept = divider_0_w_div_ready &&
                            (ctrl_unit_0_w_ex_mem_ctrl != `ctrl_stall);

    Ctrl_Unit Ctrl_Unit_0 (
        .i_if_stall             (if_0_w_if_stall),
        
        .i_id_load_use          (id_0_w_id_load_use),
        
        .i_ex_branch            (ex_0_w_ex_branch),
        .i_ex_division_busy     (ex_0_w_ex_division_busy),
        .i_jump_flag            (ex_0_w_jump_flag),
        .i_jump_addr            (ex_0_w_jump_addr),
        
        .i_mem_stall            (mem_0_w_mem_stall),

        .i_trap_jump_flag       (trap_unit_0_w_trap_jump_flag),
        .i_trap_jump_addr       (trap_unit_0_w_trap_jump_addr),
        .i_trap_stall           (trap_unit_0_w_trap_stall),

        .o_pc_ctrl              (ctrl_unit_0_w_pc_ctrl),
        .o_jump_flag            (ctrl_unit_0_w_jump_flag),
        .o_jump_addr            (ctrl_unit_0_w_jump_addr),
        
        .o_if_id_ctrl           (ctrl_unit_0_w_if_id_ctrl),
        .o_id_ex_ctrl           (ctrl_unit_0_w_id_ex_ctrl), 
        .o_ex_mem_ctrl          (ctrl_unit_0_w_ex_mem_ctrl),
        .o_mem_wb_ctrl          (ctrl_unit_0_w_mem_wb_ctrl)
    );

    PC PC_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_pc_ctrl              (ctrl_unit_0_w_pc_ctrl),  
        .i_jump_flag            (ctrl_unit_0_w_jump_flag),
        .i_jump_addr            (ctrl_unit_0_w_jump_addr),
        
        .o_pc_addr              (pc_0_w_pc_addr)
    );

    IF IF_0 (
        .i_pc_addr              (pc_0_w_pc_addr),

        .o_imem_valid           (o_imem_valid),
        .i_imem_ready           (i_imem_ready),
        .o_imem_rd_addr         (o_imem_rd_addr),
        .i_imem_rd_data         (i_imem_rd_data),
        
        .o_if_stall             (if_0_w_if_stall),
        
        .o_pc_addr              (if_0_w_pc_addr),
        .o_inst_data            (if_0_w_inst_data)
    );

    IF_ID IF_ID_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_pc_addr              (if_0_w_pc_addr),
        .i_inst_data            (if_0_w_inst_data),
        
        .i_ctrl_flag            (ctrl_unit_0_w_if_id_ctrl),
        
        .o_pc_addr              (if_id_0_w_pc_addr),
        .o_inst_data            (if_id_0_w_inst_dat)
    );

    ID ID_0 (
        .i_pc_addr              (if_id_0_w_pc_addr),
        .i_inst_data            (if_id_0_w_inst_dat),
        
        .i_reg1_rd_data         (regs_0_w_rd_data1), 
        .i_reg2_rd_data         (regs_0_w_rd_data2), 
        .o_reg1_rd_addr         (id_0_w_reg1_rd_addr), 
        .o_reg2_rd_addr         (id_0_w_reg2_rd_addr), 
        
        .i_csr_rd_data          (regs_csr_0_w_id_csr_rd_data),
        .o_csr_rd_addr          (id_0_w_csr_rd_addr),
        
        .i_id_ex_Mem_re         (id_ex_0_w_id_ex_Mem_re),
        .i_id_ex_Reg_we         (id_ex_0_w_id_ex_Reg_we),
        .i_id_ex_regd_addr      (id_ex_0_w_id_ex_regd_addr),
        
        .o_pc_addr              (id_0_w_pc_addr),     
        .o_inst_data            (id_0_w_inst_data),   
        .o_reg1_data            (id_0_w_reg1_data),
        .o_reg1_addr            (id_0_w_reg1_addr),
        .o_reg2_data            (id_0_w_reg2_data),
        .o_reg2_addr            (id_0_w_reg2_addr),
        .o_regd_addr            (id_0_w_regd_addr),
        .o_imm_data             (id_0_w_imm_data),
        
        .o_Reg_we               (id_0_w_Reg_we),
        .o_ALU_src_A            (id_0_w_ALU_src_A),
        .o_ALU_src_B            (id_0_w_ALU_src_B),
        .o_ALU_op               (id_0_w_ALU_op),
        .o_Branch               (id_0_w_Branch),
        .o_MemtoReg_src         (id_0_w_MemtoReg_src),
        .o_Mem_we               (id_0_w_Mem_we),
        .o_Mem_re               (id_0_w_Mem_re),
        .o_Mem_op               (id_0_w_Mem_op),
        
        .o_csr_op               (id_0_w_csr_op),
        .o_csr_wr_en            (id_0_w_csr_wr_en),
        .o_csr_wr_addr          (id_0_w_csr_wr_addr),
        .o_csr_data             (id_0_w_csr_data),
        .o_csr_zimm_data        (id_0_w_csr_zimm_data),
        
        .o_id_load_use          (id_0_w_id_load_use),
        .o_trap_cause           (id_0_w_trap_cause)
    );

    Regs Regs_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_wr_en                (wb_0_w_regd_we),
        .i_wr_addr              (wb_0_w_regd_addr), 
        .i_wr_data              (wb_0_w_regd_data), 
        
        .i_rd_addr1             (id_0_w_reg1_rd_addr),
        .i_rd_addr2             (id_0_w_reg2_rd_addr),
        
        .o_rd_data1             (regs_0_w_rd_data1),
        .o_rd_data2             (regs_0_w_rd_data2)
    );

    Regs_CSR Regs_CSR_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_ex_csr_wr_en         (ex_0_w_csr_wr_en),
        .i_ex_csr_wr_addr       (ex_0_w_csr_wr_addr),
        .i_ex_csr_wr_data       (ex_0_w_csr_wr_data),
        
        .i_id_csr_rd_addr       (id_0_w_csr_rd_addr),
        .o_id_csr_rd_data       (regs_csr_0_w_id_csr_rd_data),
        
        .i_trap_csr_rd_addr     (trap_unit_0_w_trap_csr_rd_addr),
        .o_trap_csr_rd_data     (regs_csr_0_w_trap_csr_rd_data),

        .i_trap_csr_wr_en       (trap_unit_0_w_trap_csr_wr_en),
        .i_trap_csr_wr_addr     (trap_unit_0_w_trap_csr_wr_addr),
        .i_trap_csr_wr_data     (trap_unit_0_w_trap_csr_wr_data),
        
        .o_csr_mtvec            (regs_csr_0_w_csr_mtvec),
        .o_csr_mepc             (regs_csr_0_w_csr_mepc),
        .o_csr_mie              (regs_csr_0_w_csr_mie),
        .o_csr_mstatus          (regs_csr_0_w_csr_mstatus),
        .o_global_int_en        (regs_csr_0_w_global_int_en)
    );

    ID_EX ID_EX_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_pc_addr              (id_0_w_pc_addr),
        .i_inst_data            (id_0_w_inst_data),  
        .i_reg1_data            (id_0_w_reg1_data),  
        .i_reg1_addr            (id_0_w_reg1_addr),
        .i_reg2_data            (id_0_w_reg2_data), 
        .i_reg2_addr            (id_0_w_reg2_addr), 
        .i_regd_addr            (id_0_w_regd_addr),  
        .i_imm_data             (id_0_w_imm_data),   
        
        .i_Reg_we               (id_0_w_Reg_we),
        .i_ALU_src_A            (id_0_w_ALU_src_A),
        .i_ALU_src_B            (id_0_w_ALU_src_B),
        .i_ALU_op               (id_0_w_ALU_op),
        .i_Branch               (id_0_w_Branch),
        .i_MemtoReg_src         (id_0_w_MemtoReg_src),
        .i_Mem_we               (id_0_w_Mem_we),
        .i_Mem_re               (id_0_w_Mem_re),
        .i_Mem_op               (id_0_w_Mem_op),
        
        .i_csr_op               (id_0_w_csr_op),
        .i_csr_wr_en            (id_0_w_csr_wr_en),
	    .i_csr_wr_addr          (id_0_w_csr_wr_addr),
        .i_csr_data             (id_0_w_csr_data),
        .i_csr_zimm_data        (id_0_w_csr_zimm_data),
        .i_trap_cause           (id_0_w_trap_cause),

        .i_ctrl_flag            (ctrl_unit_0_w_id_ex_ctrl),
        
        .o_pc_addr              (id_ex_0_w_pc_addr),    
        .o_inst_data            (id_ex_0_w_inst_data),  
        .o_reg1_data            (id_ex_0_w_reg1_data),  
        .o_reg1_addr            (id_ex_0_w_reg1_addr),
        .o_reg2_data            (id_ex_0_w_reg2_data),  
        .o_reg2_addr            (id_ex_0_w_reg2_addr),
        .o_regd_addr            (id_ex_0_w_regd_addr),  
        .o_imm_data             (id_ex_0_w_imm_data),   
        
        .o_Reg_we               (id_ex_0_w_Reg_we),
        .o_ALU_src_A            (id_ex_0_w_ALU_src_A),
        .o_ALU_src_B            (id_ex_0_w_ALU_src_B),
        .o_ALU_op               (id_ex_0_w_ALU_op),
        .o_Branch               (id_ex_0_w_Branch),
        .o_MemtoReg_src         (id_ex_0_w_MemtoReg_src),
        .o_Mem_we               (id_ex_0_w_Mem_we),
        .o_Mem_re               (id_ex_0_w_Mem_re),
        .o_Mem_op               (id_ex_0_w_Mem_op),
        
        .o_csr_op               (id_ex_0_csr_op),
        .o_csr_wr_en            (id_ex_0_csr_wr_en),
	    .o_csr_wr_addr          (id_ex_0_csr_wr_addr),
        .o_csr_data             (id_ex_0_csr_data),
        .o_csr_zimm_data        (id_ex_0_csr_zimm_data),

        .o_id_ex_Mem_re         (id_ex_0_w_id_ex_Mem_re),
        .o_id_ex_Reg_we         (id_ex_0_w_id_ex_Reg_we),
        .o_id_ex_regd_addr      (id_ex_0_w_id_ex_regd_addr),
        .o_trap_cause           (id_ex_0_w_trap_cause)
    );

    EX EX_0 (
        .i_pc_addr              (id_ex_0_w_pc_addr),
        .i_inst_data            (id_ex_0_w_inst_data),
        .i_reg1_data            (id_ex_0_w_reg1_data),
        .i_reg1_addr            (id_ex_0_w_reg1_addr),
        .i_reg2_data            (id_ex_0_w_reg2_data),
        .i_reg2_addr            (id_ex_0_w_reg2_addr),
        .i_regd_addr            (id_ex_0_w_regd_addr),
        .i_imm_data             (id_ex_0_w_imm_data),
        
        .i_Reg_we               (id_ex_0_w_Reg_we),
        .i_ALU_src_A            (id_ex_0_w_ALU_src_A),
        .i_ALU_src_B            (id_ex_0_w_ALU_src_B),
        .i_ALU_op               (id_ex_0_w_ALU_op),
        .i_Branch               (id_ex_0_w_Branch),
        .i_MemtoReg_src         (id_ex_0_w_MemtoReg_src),
        .i_Mem_we               (id_ex_0_w_Mem_we),
        .i_Mem_re               (id_ex_0_w_Mem_re),
        .i_Mem_op               (id_ex_0_w_Mem_op),
        
        .i_csr_op               (id_ex_0_csr_op),
        .i_csr_wr_en            (id_ex_0_csr_wr_en),
        .i_csr_wr_addr          (id_ex_0_csr_wr_addr),
        .i_csr_data             (id_ex_0_csr_data),
        .i_csr_zimm_data        (id_ex_0_csr_zimm_data),
        
        .i_ex_mem_regd_we       (ex_mem_0_w_ex_mem_regd_we),
        .i_ex_mem_regd_addr     (ex_mem_0_w_ex_mem_regd_addr),
        .i_ex_mem_regd_data     (ex_mem_0_w_ex_mem_regd_data),
        
        .i_mem_wb_regd_we       (mem_wb_0_w_mem_wb_regd_we),
        .i_mem_wb_regd_addr     (mem_wb_0_w_mem_wb_regd_addr),
        .i_mem_wb_regd_data     (mem_wb_0_w_mem_wb_regd_data),
        
        .i_quotient_data        (divider_0_w_quotient_data),
        .i_remainder_data       (divider_0_w_remainder_data),
        .i_div_ready            (divider_0_w_div_ready),
        .o_dividend_data        (ex_0_w_dividend_data),
        .o_divisor_data         (ex_0_w_divisor_data),
        .o_div_valid            (ex_0_w_div_valid),
        .o_div_signed           (ex_0_w_div_signed),
        
        .o_csr_wr_en            (ex_0_w_csr_wr_en),
        .o_csr_wr_addr          (ex_0_w_csr_wr_addr),
        .o_csr_wr_data          (ex_0_w_csr_wr_data),
        
        .o_pc_addr              (ex_0_w_pc_addr),
        .o_inst_data            (ex_0_w_inst_data),
        .o_wb_src               (ex_0_w_wb_src),
        .o_regd_we              (ex_0_w_regd_we),
        .o_regd_addr            (ex_0_w_regd_addr),
        .o_regd_data            (ex_0_w_regd_data),
        .o_mem_we               (ex_0_w_mem_we),
        .o_mem_re               (ex_0_w_mem_re),
        .o_mem_addr             (ex_0_w_mem_addr),
        .o_mem_wr_data_raw      (ex_0_w_mem_wr_data_raw),
        .o_mem_op_type          (ex_0_w_mem_op_type),
        
        .o_ex_branch            (ex_0_w_ex_branch),
        .o_ex_division_busy     (ex_0_w_ex_division_busy),
        .o_jump_flag            (ex_0_w_jump_flag),
        .o_jump_addr            (ex_0_w_jump_addr)
    );

    Divider Divider_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_div_result_accept    (div_result_accept),
        
        .i_dividend_data        (ex_0_w_dividend_data),
        .i_divisor_data         (ex_0_w_divisor_data),
        .i_div_valid            (ex_0_w_div_valid),
        .i_div_signed           (ex_0_w_div_signed),
        .o_quotient_data        (divider_0_w_quotient_data),
        .o_remainder_data       (divider_0_w_remainder_data),
        .o_div_ready            (divider_0_w_div_ready)
    );

    EX_MEM EX_MEM_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_pc_addr              (ex_0_w_pc_addr),
        .i_inst_data            (ex_0_w_inst_data),
        .i_wb_src               (ex_0_w_wb_src),
        .i_regd_we              (ex_0_w_regd_we),
        .i_regd_addr            (ex_0_w_regd_addr),
        .i_regd_data            (ex_0_w_regd_data),
        .i_mem_we               (ex_0_w_mem_we),
        .i_mem_re               (ex_0_w_mem_re),
        .i_mem_addr             (ex_0_w_mem_addr),
        .i_mem_wr_data_raw      (ex_0_w_mem_wr_data_raw),
        .i_mem_op_type          (ex_0_w_mem_op_type),
        
        .i_ctrl_flag            (ctrl_unit_0_w_ex_mem_ctrl),
        
        .o_pc_addr              (ex_mem_0_w_pc_addr),
        .o_inst_data            (ex_mem_0_w_inst_data),
        .o_wb_src               (ex_mem_0_w_wb_src),
        .o_regd_we              (ex_mem_0_w_regd_we),
        .o_regd_addr            (ex_mem_0_w_regd_addr),
        .o_regd_data            (ex_mem_0_w_regd_data),
        .o_mem_we               (ex_mem_0_w_mem_we),
        .o_mem_re               (ex_mem_0_w_mem_re),
        .o_mem_addr             (ex_mem_0_w_mem_addr),
        .o_mem_wr_data_raw      (ex_mem_0_w_mem_wr_data_raw),
        .o_mem_op_type          (ex_mem_0_w_mem_op_type),
        
        .o_ex_mem_regd_we       (ex_mem_0_w_ex_mem_regd_we),
        .o_ex_mem_regd_addr     (ex_mem_0_w_ex_mem_regd_addr),
        .o_ex_mem_regd_data     (ex_mem_0_w_ex_mem_regd_data)
    );

    MEM MEM_0 (
        .i_pc_addr              (ex_mem_0_w_pc_addr),
        .i_inst_data            (ex_mem_0_w_inst_data),
        .i_wb_src               (ex_mem_0_w_wb_src),
        .i_regd_we              (ex_mem_0_w_regd_we),
        .i_regd_addr            (ex_mem_0_w_regd_addr),
        .i_regd_data            (ex_mem_0_w_regd_data),
        .i_mem_we               (ex_mem_0_w_mem_we),
        .i_mem_re               (ex_mem_0_w_mem_re),
        .i_mem_addr             (ex_mem_0_w_mem_addr),
        .i_mem_wr_data_raw      (ex_mem_0_w_mem_wr_data_raw),
        .i_mem_op_type          (ex_mem_0_w_mem_op_type),
        
        .o_dcache_en            (o_dcache_en),
        .o_mmio_en              (o_mmio_en),
        .o_dmem_valid           (o_dmem_valid),
        .i_dmem_ready           (i_dmem_ready),
        .o_dmem_rd_en           (o_dmem_rd_en),
        .o_dmem_rd_addr         (o_dmem_rd_addr),
        .i_dmem_rd_data         (i_dmem_rd_data),
        .o_dmem_wr_en           (o_dmem_wr_en),
        .o_dmem_wr_strb         (o_dmem_wr_strb),
        .o_dmem_wr_addr         (o_dmem_wr_addr),
        .o_dmem_wr_data         (o_dmem_wr_data),
        
        .o_mem_stall            (mem_0_w_mem_stall),
        
        .o_regd_we              (mem_0_w_regd_we),
        .o_regd_addr            (mem_0_w_regd_addr),
        .o_regd_data            (mem_0_w_regd_data)
    );

    MEM_WB MEM_WB_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        
        .i_regd_we              (mem_0_w_regd_we),
        .i_regd_addr            (mem_0_w_regd_addr),
        .i_regd_data            (mem_0_w_regd_data),
        
        .i_mem_wb_ctrl          (ctrl_unit_0_w_mem_wb_ctrl),
        
        .o_regd_we              (mem_wb_0_w_regd_we),
        .o_regd_addr            (mem_wb_0_w_regd_addr),
        .o_regd_data            (mem_wb_0_w_regd_data),
        
        .o_mem_wb_regd_we       (mem_wb_0_w_mem_wb_regd_we),
        .o_mem_wb_regd_addr     (mem_wb_0_w_mem_wb_regd_addr),
        .o_mem_wb_regd_data     (mem_wb_0_w_mem_wb_regd_data)
    );

    WB WB_0 (
        .i_regd_we              (mem_wb_0_w_regd_we),
        .i_regd_addr            (mem_wb_0_w_regd_addr),
        .i_regd_data            (mem_wb_0_w_regd_data),

        .o_regd_we              (wb_0_w_regd_we),
        .o_regd_addr            (wb_0_w_regd_addr),
        .o_regd_data            (wb_0_w_regd_data)
    );

    Trap_Unit Trap_Unit_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),

        .i_pc_addr              (id_ex_0_w_pc_addr),
        .i_trap_cause           (id_ex_0_w_trap_cause),

        .i_trap_csr_rd_data     (regs_csr_0_w_trap_csr_rd_data),
        .o_trap_csr_rd_addr     (trap_unit_0_w_trap_csr_rd_addr),

        .o_trap_csr_wr_en       (trap_unit_0_w_trap_csr_wr_en),
        .o_trap_csr_wr_addr     (trap_unit_0_w_trap_csr_wr_addr),
        .o_trap_csr_wr_data     (trap_unit_0_w_trap_csr_wr_data),

        .i_csr_mtvec            (regs_csr_0_w_csr_mtvec),
        .i_csr_mepc             (regs_csr_0_w_csr_mepc),
        .i_csr_mie              (regs_csr_0_w_csr_mie),
        .i_csr_mstatus          (regs_csr_0_w_csr_mstatus),

        .i_timer_int_pending    (i_timer_int_pending),   
        .i_external_int_pending (i_external_int_pending),

        .o_trap_jump_flag       (trap_unit_0_w_trap_jump_flag),
        .o_trap_jump_addr       (trap_unit_0_w_trap_jump_addr),
        .o_trap_stall           (trap_unit_0_w_trap_stall)
    );

endmodule
