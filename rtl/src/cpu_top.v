`include "defines.v"

module cpu_top (
    input wire i_Clk,
    input wire i_reset
);

    // ctrl_0 outputs
    wire[`CtrlTypeBus]      ctrl_0_w_pc_ctrl;
    wire                    ctrl_0_w_jump_flag;
    wire[`InstAddrBus]      ctrl_0_w_jump_addr;
    wire[`CtrlTypeBus]      ctrl_0_w_if_id_ctrl;
    wire[`CtrlTypeBus]      ctrl_0_w_id_ex_ctrl;
    wire[`CtrlTypeBus]      ctrl_0_w_ex_mem_ctrl;
    wire[`CtrlTypeBus]      ctrl_0_w_mem_wb_ctrl;
    // PC_0 outputs
    wire[`InstAddrBus]      pc_0_w_pc_addr;
    // IF_0 outputs
    wire                    if_0_w_imem_req_valid;
    wire                    if_0_w_imem_resp_ready;
    wire                    if_0_w_imem_req_rd_en;
    wire[`InstAddrBus]      if_0_w_imem_req_rd_addr;
    wire                    if_0_w_if_stall;
    wire[`InstAddrBus]      if_0_w_pc_addr;
    wire[`DataBus]          if_0_w_inst_data;
    // rom_comb_0 outputs
    wire                    rom_comb_0_w_imem_req_ready;
    wire                    rom_comb_0_w_imem_resp_valid;
    wire[`DataBus]          rom_comb_0_w_imem_resp_rd_data;
    // IF_ID_0 outputs
    wire[`InstAddrBus]      if_id_0_w_pc_addr;
    wire[`DataBus]          if_id_0_w_inst_dat;
    // ID_0 outputs
    wire[`RegsAddrBus]      id_0_w_reg1_rd_addr;
    wire[`RegsAddrBus]      id_0_w_reg2_rd_addr;
    wire[`InstAddrBus]      id_0_w_pc_addr;
    wire[`DataBus]          id_0_w_inst_data;
    wire[`DataBus]          id_0_w_reg1_data;
    wire[`RegsAddrBus]      id_0_w_reg1_addr;
    wire[`DataBus]          id_0_w_reg2_data;
    wire[`RegsAddrBus]      id_0_w_reg2_addr;
    wire[`RegsAddrBus]      id_0_w_regd_addr;
    wire[`DataBus]          id_0_w_imm_data;
    wire[`CtrlBundleBus]    id_0_w_ctrl_bundle; 
    // regs_0 outputs
    wire[`DataBus]          regs_0_w_rd_data1;
    wire[`DataBus]          regs_0_w_rd_data2;
    // ID_EX_0 outputs
    wire[`InstAddrBus]      id_ex_0_w_pc_addr;
    wire[`DataBus]          id_ex_0_w_inst_data;
    wire[`DataBus]          id_ex_0_w_reg1_data;  
    wire[`RegsAddrBus]      id_ex_0_w_reg1_addr;
    wire[`DataBus]          id_ex_0_w_reg2_data;  
    wire[`RegsAddrBus]      id_ex_0_w_reg2_addr;
    wire[`RegsAddrBus]      id_ex_0_w_regd_addr;  
    wire[`DataBus]          id_ex_0_w_imm_data;  
    wire[`CtrlBundleBus]    id_ex_0_w_ctrl_bundle;
    // EX_0 outputs
    wire[`InstAddrBus]      ex_0_w_pc_addr;
    wire[`DataBus]          ex_0_w_inst_data;
    wire                    ex_0_w_wb_src;
    wire                    ex_0_w_regd_we;
    wire[`RegsAddrBus]      ex_0_w_regd_addr;
    wire[`DataBus]          ex_0_w_regd_data_alu;
    wire                    ex_0_w_mem_we;
    wire                    ex_0_w_mem_re;
    wire[`DataAddrBus]      ex_0_w_mem_addr;
    wire[`DataBus]          ex_0_w_mem_wr_data_raw;
    wire[`MemOpTypeBus]     ex_0_w_mem_op_type;
    wire                    ex_0_w_ex_branch;
    wire                    ex_0_w_ex_load_use;
    wire                    ex_0_w_jump_flag;
    wire[`InstAddrBus]      ex_0_w_jump_addr;
    // EX_MEM_0 outputs
    wire[`InstAddrBus]      ex_mem_0_w_pc_addr;
    wire[`DataBus]          ex_mem_0_w_inst_data;
    wire                    ex_mem_0_w_wb_src;
    wire                    ex_mem_0_w_regd_we;
    wire[`RegsAddrBus]      ex_mem_0_w_regd_addr;
    wire[`DataBus]          ex_mem_0_w_regd_data_alu;
    wire                    ex_mem_0_w_mem_we;
    wire                    ex_mem_0_w_mem_re;
    wire[`DataAddrBus]      ex_mem_0_w_mem_addr;
    wire[`DataBus]          ex_mem_0_w_mem_wr_data_raw;
    wire[`MemOpTypeBus]     ex_mem_0_w_mem_op_type;
    wire                    ex_mem_0_w_ex_mem_regd_we;
    wire[`RegsAddrBus]      ex_mem_0_w_ex_mem_regd_addr;
    wire[`DataBus]          ex_mem_0_w_ex_mem_regd_data;
    // MEM_0 outputs
    wire                    mem_0_w_dmem_req_valid;
    wire                    mem_0_w_dmem_resp_ready;
    wire                    mem_0_w_dmem_rd_en;
    wire[`DataAddrBus]      mem_0_w_dmem_rd_addr_raw;
    wire                    mem_0_w_dmem_wr_en;
    wire[`StrbBus]          mem_0_w_dmem_wr_strb;
    wire[`DataAddrBus]      mem_0_w_dmem_wr_addr_raw;
    wire[`DataBus]          mem_0_w_dmem_wr_data;
    wire                    mem_0_w_mem_stall;
    wire                    mem_0_w_regd_we;
    wire[`RegsAddrBus]      mem_0_w_regd_addr;
    wire[`DataBus]          mem_0_w_regd_data;
    // dmem_decoder_0 outputs
    wire[`DataAddrBus]      dmem_decoder_0_w_dmem_rd_addr;
    wire[`DataAddrBus]      dmem_decoder_0_w_dmem_wr_addr;
    // ram_comb_0 outputs
    wire                    ram_comb_0_w_dmem_req_ready;
    wire                    ram_comb_0_w_dmem_resp_valid;
    wire[`DataBus]          ram_comb_0_w_dmem_rd_data;
    // MEM_WB_0 outputs
    wire                    mem_wb_0_w_regd_we;
    wire[`RegsAddrBus]      mem_wb_0_w_regd_addr;
    wire[`DataBus]          mem_wb_0_w_regd_data;
    wire                    mem_wb_0_w_mem_wb_regd_we;
    wire[`RegsAddrBus]      mem_wb_0_w_mem_wb_regd_addr;
    wire[`DataBus]          mem_wb_0_w_mem_wb_regd_data;
    // WB_0 outputs
    wire                    wb_0_w_regd_we;
    wire[`RegsAddrBus]      wb_0_w_regd_addr;
    wire[`DataBus]          wb_0_w_regd_data;

    ctrl ctrl_0 (
        .i_if_stall             (if_0_w_if_stall),
        .i_ex_branch            (ex_0_w_ex_branch),
        .i_ex_load_use          (ex_0_w_ex_load_use),
        .i_jump_flag            (ex_0_w_jump_flag),
        .i_jump_addr            (ex_0_w_jump_addr),
        .i_mem_stall            (mem_0_w_mem_stall),
        .o_pc_ctrl              (ctrl_0_w_pc_ctrl),
        .o_jump_flag            (ctrl_0_w_jump_flag),
        .o_jump_addr            (ctrl_0_w_jump_addr),
        .o_if_id_ctrl           (ctrl_0_w_if_id_ctrl),
        .o_id_ex_ctrl           (ctrl_0_w_id_ex_ctrl), 
        .o_ex_mem_ctrl          (ctrl_0_w_ex_mem_ctrl),
        .o_mem_wb_ctrl          (ctrl_0_w_mem_wb_ctrl)
    );

    PC PC_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_pc_ctrl              (ctrl_0_w_pc_ctrl),  
        .i_jump_flag            (ctrl_0_w_jump_flag),
        .i_jump_addr            (ctrl_0_w_jump_addr),
        .o_pc_addr              (pc_0_w_pc_addr)
    );

    IF IF_0 (
        .i_pc_addr              (pc_0_w_pc_addr),
        .o_imem_req_valid       (if_0_w_imem_req_valid),
        .i_imem_req_ready       (rom_comb_0_w_imem_req_ready),
        .o_imem_resp_ready      (if_0_w_imem_resp_ready),
        .i_imem_resp_valid      (rom_comb_0_w_imem_resp_valid),
        .o_imem_req_rd_en       (if_0_w_imem_req_rd_en),
        .o_imem_req_rd_addr     (if_0_w_imem_req_rd_addr),
        .i_imem_resp_rd_data    (rom_comb_0_w_imem_resp_rd_data),
        .o_if_stall             (if_0_w_if_stall),
        .o_pc_addr              (if_0_w_pc_addr),
        .o_inst_data            (if_0_w_inst_data)
    );

    rom_comb rom_comb_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_imem_req_valid       (if_0_w_imem_req_valid),
        .o_imem_req_ready       (rom_comb_0_w_imem_req_ready), 
        .i_imem_resp_ready      (if_0_w_imem_resp_ready),
        .o_imem_resp_valid      (rom_comb_0_w_imem_resp_valid),
        .i_imem_req_rd_en       (if_0_w_imem_req_rd_en),
        .i_imem_req_rd_addr     (if_0_w_imem_req_rd_addr),
        .o_imem_resp_rd_data    (rom_comb_0_w_imem_resp_rd_data)
    );

    IF_ID IF_ID_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_pc_addr              (if_0_w_pc_addr),
        .i_inst_data            (if_0_w_inst_data),
        .i_ctrl_flag            (ctrl_0_w_if_id_ctrl),
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
        .o_pc_addr              (id_0_w_pc_addr),     
        .o_inst_data            (id_0_w_inst_data),   
        .o_reg1_data            (id_0_w_reg1_data),
        .o_reg1_addr            (id_0_w_reg1_addr),
        .o_reg2_data            (id_0_w_reg2_data),
        .o_reg2_addr            (id_0_w_reg2_addr),
        .o_regd_addr            (id_0_w_regd_addr),
        .o_imm_data             (id_0_w_imm_data),
        .o_ctrl_bundle          (id_0_w_ctrl_bundle)
    );

    regs regs_0 (
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
        .i_ctrl_bundle          (id_0_w_ctrl_bundle),
        .i_ctrl_flag            (ctrl_0_w_id_ex_ctrl),
        .o_pc_addr              (id_ex_0_w_pc_addr),    
        .o_inst_data            (id_ex_0_w_inst_data),  
        .o_reg1_data            (id_ex_0_w_reg1_data),  
        .o_reg1_addr            (id_ex_0_w_reg1_addr),
        .o_reg2_data            (id_ex_0_w_reg2_data),  
        .o_reg2_addr            (id_ex_0_w_reg2_addr),
        .o_regd_addr            (id_ex_0_w_regd_addr),  
        .o_imm_data             (id_ex_0_w_imm_data),   
        .o_ctrl_bundle          (id_ex_0_w_ctrl_bundle)
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
        .i_ctrl_bundle          (id_ex_0_w_ctrl_bundle),
        .i_ex_mem_regd_we       (ex_mem_0_w_ex_mem_regd_we),
        .i_ex_mem_regd_addr     (ex_mem_0_w_ex_mem_regd_addr),
        .i_ex_mem_regd_data     (ex_mem_0_w_ex_mem_regd_data),
        .i_mem_wb_regd_we       (mem_wb_0_w_mem_wb_regd_we),
        .i_mem_wb_regd_addr     (mem_wb_0_w_mem_wb_regd_addr),
        .i_mem_wb_regd_data     (mem_wb_0_w_mem_wb_regd_data),
        .o_pc_addr              (ex_0_w_pc_addr),
        .o_inst_data            (ex_0_w_inst_data),
        .o_wb_src               (ex_0_w_wb_src),
        .o_regd_we              (ex_0_w_regd_we),
        .o_regd_addr            (ex_0_w_regd_addr),
        .o_regd_data_alu        (ex_0_w_regd_data_alu),
        .o_mem_we               (ex_0_w_mem_we),
        .o_mem_re               (ex_0_w_mem_re),
        .o_mem_addr             (ex_0_w_mem_addr),
        .o_mem_wr_data_raw      (ex_0_w_mem_wr_data_raw),
        .o_mem_op_type          (ex_0_w_mem_op_type),
        .o_ex_branch            (ex_0_w_ex_branch),
        .o_ex_load_use          (ex_0_w_ex_load_use),
        .o_jump_flag            (ex_0_w_jump_flag),
        .o_jump_addr            (ex_0_w_jump_addr)
    );

    EX_MEM EX_MEM_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_pc_addr              (ex_0_w_pc_addr),
        .i_inst_data            (ex_0_w_inst_data),
        .i_wb_src               (ex_0_w_wb_src),
        .i_regd_we              (ex_0_w_regd_we),
        .i_regd_addr            (ex_0_w_regd_addr),
        .i_regd_data_alu        (ex_0_w_regd_data_alu),
        .i_mem_we               (ex_0_w_mem_we),
        .i_mem_re               (ex_0_w_mem_re),
        .i_mem_addr             (ex_0_w_mem_addr),
        .i_mem_wr_data_raw      (ex_0_w_mem_wr_data_raw),
        .i_mem_op_type          (ex_0_w_mem_op_type),
        .i_ctrl_flag            (ctrl_0_w_ex_mem_ctrl),
        .o_pc_addr              (ex_mem_0_w_pc_addr),
        .o_inst_data            (ex_mem_0_w_inst_data),
        .o_wb_src               (ex_mem_0_w_wb_src),
        .o_regd_we              (ex_mem_0_w_regd_we),
        .o_regd_addr            (ex_mem_0_w_regd_addr),
        .o_regd_data_alu        (ex_mem_0_w_regd_data_alu),
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
        .i_regd_data_alu        (ex_mem_0_w_regd_data_alu),
        .i_mem_we               (ex_mem_0_w_mem_we),
        .i_mem_re               (ex_mem_0_w_mem_re),
        .i_mem_addr             (ex_mem_0_w_mem_addr),
        .i_mem_wr_data_raw      (ex_mem_0_w_mem_wr_data_raw),
        .i_mem_op_type          (ex_mem_0_w_mem_op_type),
        .o_dmem_req_valid       (mem_0_w_dmem_req_valid),
        .i_dmem_req_ready       (ram_comb_0_w_dmem_req_ready),
        .o_dmem_resp_ready      (mem_0_w_dmem_resp_ready),
        .i_dmem_resp_valid      (ram_comb_0_w_dmem_resp_valid),
        .o_dmem_rd_en           (mem_0_w_dmem_rd_en),
        .o_dmem_rd_addr_raw     (mem_0_w_dmem_rd_addr_raw),
        .i_dmem_rd_data         (ram_comb_0_w_dmem_rd_data),
        .o_dmem_wr_en           (mem_0_w_dmem_wr_en),
        .o_dmem_wr_strb         (mem_0_w_dmem_wr_strb),
        .o_dmem_wr_addr_raw     (mem_0_w_dmem_wr_addr_raw),
        .o_dmem_wr_data         (mem_0_w_dmem_wr_data),
        .o_mem_stall            (mem_0_w_mem_stall),
        .o_regd_we              (mem_0_w_regd_we),
        .o_regd_addr            (mem_0_w_regd_addr),
        .o_regd_data            (mem_0_w_regd_data)
    );

    dmem_decoder dmem_decoder_0 (
        .i_dmem_rd_addr_raw(mem_0_w_dmem_rd_addr_raw),
        .o_dmem_rd_addr(dmem_decoder_0_w_dmem_rd_addr),
        .i_dmem_wr_addr_raw(mem_0_w_dmem_wr_addr_raw),
        .o_dmem_wr_addr(dmem_decoder_0_w_dmem_wr_addr)
    );

    ram_comb ram_comb_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_dmem_req_valid       (mem_0_w_dmem_req_valid),
        .o_dmem_req_ready       (ram_comb_0_w_dmem_req_ready), 
        .i_dmem_resp_ready      (mem_0_w_dmem_resp_ready),
        .o_dmem_resp_valid      (ram_comb_0_w_dmem_resp_valid),
        .i_dmem_rd_en           (mem_0_w_dmem_rd_en),
        .i_dmem_rd_addr         (dmem_decoder_0_w_dmem_rd_addr),
        .o_dmem_rd_data         (ram_comb_0_w_dmem_rd_data),
        .i_dmem_wr_en           (mem_0_w_dmem_wr_en),
        .i_dmem_wr_strb         (mem_0_w_dmem_wr_strb),
        .i_dmem_wr_addr         (dmem_decoder_0_w_dmem_wr_addr),
        .i_dmem_wr_data         (mem_0_w_dmem_wr_data)
    );

    MEM_WB MEM_WB_0 (
        .i_Clk                  (i_Clk),
        .i_reset                (i_reset),
        .i_regd_we              (mem_0_w_regd_we),
        .i_regd_addr            (mem_0_w_regd_addr),
        .i_regd_data            (mem_0_w_regd_data),
        .i_mem_wb_ctrl          (ctrl_0_w_mem_wb_ctrl),
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

endmodule
